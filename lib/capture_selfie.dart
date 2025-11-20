import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:location/location.dart' as loc;
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';
import 'package:motives_new_ui_conversion/home_screen.dart';


class SelfieCaptureScreen extends StatefulWidget {
  const SelfieCaptureScreen({super.key});

  @override
  State<SelfieCaptureScreen> createState() => _SelfieCaptureScreenState();
}

class _SelfieCaptureScreenState extends State<SelfieCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  late Future<void> _ready;
  XFile? _lastShot;
  bool _analyzing = false;
  SelfieReport? _report;

  // ---- INTERNAL FIXES ----
  bool _initInFlight = false; // prevent double init
  List<CameraDescription>? _cachedCams; // cache cameras
  bool _working = false; // prevent double capture/analysis

  final loc.Location location = loc.Location();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ready = _initCamera();

    // your tracking
    context.read<GlobalBloc>().add(Activity(activity: 'Capture Selfie'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final c = _controller;
    _controller = null;
    c?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      try {
        await _controller?.dispose();
      } catch (_) {}
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      await Future.delayed(const Duration(milliseconds: 200));
      _ready = _initCamera();
      if (mounted) setState(() {});
    }
  }

  Future<void> _initCamera() async {
    if (_initInFlight) return;
    _initInFlight = true;
    try {
      _cachedCams ??= await availableCameras();
      final cams = _cachedCams!;
      if (cams.isEmpty) throw 'No cameras available';

      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );

      try {
        await _controller?.dispose();
      } catch (_) {}

      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _controller = controller;

      Future<void> _doInit() =>
          controller.initialize().timeout(const Duration(seconds: 8));
      try {
        await _doInit();
      } on TimeoutException {
        await _doInit();
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {});
    } on CameraException catch (e) {
      String msg;
      if (e.code == 'CameraAccessDenied' || e.code == 'cameraPermission') {
        msg = 'Camera permission denied';
      } else if (e.code == 'CameraAccessDeniedWithoutPrompt') {
        msg = 'Camera permission disabled in Settings';
      } else {
        msg = e.description ?? e.code;
      }
      debugPrint("Camera init error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Camera init error: $msg')));
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Camera init error: $e')));
      }
    } finally {
      _initInFlight = false;
    }
  }

  Future<void> _pausePreviewSafe() async {
    try {
      final c = _controller;
      if (c != null &&
          c.value.isInitialized &&
          !c.value.isPreviewPaused &&
          !c.value.isTakingPicture) {
        await c.pausePreview();
      }
    } catch (_) {}
  }

  // UPDATED to re-init if controller is gone
  Future<void> _resumePreviewSafe() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      _ready = _initCamera();
      await _ready;
      return;
    }
    if (c.value.isPreviewPaused && !c.value.isTakingPicture) {
      try {
        await c.resumePreview();
      } catch (_) {
        _ready = _initCamera();
        await _ready;
      }
    }
  }

  // NEW helper → called on "Retake"
  Future<void> _prepareForRetake() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      _ready = _initCamera();
      await _ready;
      return;
    }

    final c = _controller!;
    if (c.value.isPreviewPaused && !c.value.isTakingPicture) {
      try {
        await c.resumePreview();
      } catch (_) {
        _ready = _initCamera();
        await _ready;
      }
    }
  }

  Future<void> _capture() async {
    if (_working) return;
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) return;

    HapticFeedback.mediumImpact();
    _working = true;
    try {
      await _pausePreviewSafe();

      final shot = await c.takePicture();
      setState(() {
        _lastShot = shot;
        _analyzing = true;
        _report = null;
      });

      final rep = await _analyze(shot.path);
      if (!mounted) return;
      setState(() {
        _report = rep;
        _analyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
      await _resumePreviewSafe();
    } finally {
      _working = false;
    }
  }

  Future<SelfieReport> _analyze(String path) async {
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableClassification: true,
      minFaceSize: 0.1,
    );
    final faceDetector = FaceDetector(options: options);
    final inputImage = InputImage.fromFilePath(path);
    final faces = await faceDetector.processImage(inputImage);
    await faceDetector.close();

    final bytes = await File(path).readAsBytes();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return SelfieReport.error('Could not decode image');
    }

    final brightness = _avgLuma(decoded);
    final sharpness = _varianceOfLaplacian(decoded);

    final hasSingleFace = faces.length == 1;
    Rect? faceBox;
    double faceCoverage = 0;
    double centerOffsetRatio = 1;

    if (hasSingleFace) {
      final f = faces.first.boundingBox;
      faceBox = Rect.fromLTWH(
        f.left.toDouble(),
        f.top.toDouble(),
        f.width.toDouble(),
        f.height.toDouble(),
      );
      faceCoverage =
          (faceBox.width * faceBox.height) / (decoded.width * decoded.height);

      final faceCenter = Offset(faceBox.center.dx, faceBox.center.dy);
      final imgCenter = Offset(decoded.width / 2, decoded.height / 2);
      final dx = (faceCenter.dx - imgCenter.dx).abs() / decoded.width;
      final dy = (faceCenter.dy - imgCenter.dy).abs() / decoded.height;
      centerOffsetRatio = math.sqrt(dx * dx + dy * dy);
    }

    const minBrightness = 0.35;
    const minSharpness = 25.0;
    const minFaceCoverage = 0.06;
    const maxCenterOffset = 0.18;

    final pass = [
      hasSingleFace,
      brightness >= minBrightness,
      sharpness >= minSharpness,
      hasSingleFace && faceCoverage >= minFaceCoverage,
      hasSingleFace && centerOffsetRatio <= maxCenterOffset,
    ].every((e) => e);

    return SelfieReport(
      pass: pass,
      faces: faces.length,
      brightness: brightness,
      sharpness: sharpness,
      faceCoverage: faceCoverage,
      centerOffsetRatio: centerOffsetRatio,
      filePath: path,
    );
  }

  double _avgLuma(img.Image im) {
    double sum = 0.0;
    int samples = 0;
    for (int y = 0; y < im.height; y += 4) {
      for (int x = 0; x < im.width; x += 4) {
        final px = im.getPixel(x, y);
        sum += 0.2126 * px.r + 0.7152 * px.g + 0.0722 * px.b;
        samples++;
      }
    }
    if (samples == 0) return 0.0;
    return (sum / 255.0) / samples;
  }

  double _varianceOfLaplacian(img.Image im) {
    final small = img.copyResize(im, width: 320);
    final gray = img.grayscale(small);
    final w = gray.width, h = gray.height;

    final lum = List<int>.filled(w * h, 0, growable: false);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        lum[y * w + x] = gray.getPixel(x, y).luminance.toInt();
      }
    }

    final laps = <double>[];
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final c = lum[y * w + x].toDouble();
        final up = lum[(y - 1) * w + x].toDouble();
        final dn = lum[(y + 1) * w + x].toDouble();
        final le = lum[y * w + (x - 1)].toDouble();
        final ri = lum[y * w + (x + 1)].toDouble();
        final lap = (up + dn + le + ri) - 4.0 * c;
        laps.add(lap);
      }
    }
    if (laps.isEmpty) return 0.0;

    final mean = laps.reduce((a, b) => a + b) / laps.length;
    double varSum = 0;
    for (final v in laps) {
      final d = v - mean;
      varSum += d * d;
    }
    return varSum / (laps.length - 1);
  }

  void showCenteredToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          ignoring: true,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xE6000000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2)).then((_) => entry.remove());
  }

  void _onUse() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      if (_report?.pass != true) {
        if (!mounted) return;
        showCenteredToast(context, 'Please retake a clearer selfie');
        return;
      }

      final current = await location.getLocation();
      final lat = current.latitude;
      final lng = current.longitude;
      if (lat == null || lng == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get your location')),
        );
        return;
      }

      final bloc = context.read<GlobalBloc>();
      final userId = bloc.state.loginModel?.userinfo?.userId?.toString();
      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User session missing')),
        );
        return;
      }

      bloc.add(MarkAttendanceEvent(
        action: 'IN',
        lat: lat.toString(),
        lng: lng.toString(),
        type: '1',
        userId: userId,
      ));

      final attendStatus = await bloc.stream
          .map((s) => s.markAttendanceStatus)
          .distinct()
          .firstWhere((st) =>
              st == MarkAttendanceStatus.success ||
              st == MarkAttendanceStatus.failure);

      if (attendStatus != MarkAttendanceStatus.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance failed')),
        );
        return;
      }

      final box = GetStorage();
      final email = box.read<String>("email");
      final password = box.read<String>("password");
      if (email != null && password != null) {
        bloc.add(LoginEvent(email: email, password: password));
        final loginStatus = await bloc.stream
            .map((s) => s.status)
            .distinct()
            .firstWhere(
                (st) => st == LoginStatus.success || st == LoginStatus.failure);

        if (loginStatus != LoginStatus.success) {
          if (!mounted) return;
          final msg = bloc.state.loginModel?.message ?? 'Login refresh failed';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
          return;
        }
      }

      if (!mounted) return;

      showCenteredToast(context, 'Attendance Marked Successfully');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Attendance marked successfully')),
      // );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeUpdated()),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _ready,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          if (_lastShot != null) {
            return _ResultView(
              report: _report,
              analyzing: _analyzing,
              filePath: _lastShot!.path,
              onRetake: () async {
                setState(() {
                  _lastShot = null;
                  _report = null;
                });
                await _prepareForRetake();
                if (mounted) setState(() {});
              },
              onUse: _busy ? null : _onUse,
            );
          }

          if (_controller == null || !_controller!.value.isInitialized) {
            if (!_initInFlight) {
              _ready = _initCamera();
            }
            return const Center(
              child: Text(
                "Camera not ready",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
                child: CameraPreview(_controller!),
              ),
              const _CircularMask(),
              SafeArea(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.28),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          InkResponse(
                            onTap: () => Navigator.pop(context),
                            radius: 24,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(.22),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Selfie Verification',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                                letterSpacing: .2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const _HeaderBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: 120 + MediaQuery.of(context).padding.bottom,
                    left: 20,
                    right: 20,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Center your face in the circle. Good light. Hold steady.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: 30 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: _ShutterButton(onTap: _capture),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===== UI WIDGETS =====

class _CircularMask extends StatelessWidget {
  const _CircularMask();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CircleMaskPainter(), size: Size.infinite);
  }
}

class _CircleMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) * 0.36;
    final center = Offset(size.width / 2, size.height / 2 - 20);
    final overlay = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final mask = Path.combine(PathOperation.difference, overlay, hole);

    canvas.drawPath(mask, Paint()..color = Colors.black.withOpacity(.45));

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = Colors.orange;
    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        height: 78,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFEA7A3B),
          boxShadow: [
            BoxShadow(
              color: Color(0x338B59C6),
              blurRadius: 20,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEA7A3B),
      ),
      child: const Center(
        child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.report,
    required this.analyzing,
    required this.filePath,
    required this.onRetake,
    this.onUse,
  });

  final SelfieReport? report;
  final bool analyzing;
  final String filePath;
  final VoidCallback onRetake;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(filePath), fit: BoxFit.cover),
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 56),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 16,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: analyzing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Analyzing selfie…',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ScoreRow(
                        label: 'Single face detected',
                        pass: (report?.faces ?? 0) == 1,
                      ),
                      _ScoreRow(
                        label: 'Brightness',
                        pass: (report?.brightness ?? 0) >= 0.35,
                      ),
                      _ScoreRow(
                        label: 'Sharpness',
                        pass: (report?.sharpness ?? 0) >= 25,
                      ),
                      _ScoreRow(
                        label: 'Face size & centered',
                        pass: (report?.faceCoverage ?? 0) >= 0.06 &&
                            (report?.centerOffsetRatio ?? 1) <= 0.18,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onRetake,
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFFEA7A3B)),
                                foregroundColor: const Color(0xFFEA7A3B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Retake'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: onUse,
                              style: FilledButton.styleFrom(
                                backgroundColor: (report?.pass ?? false)
                                    ? const Color(0xFFEA7A3B)
                                    : Colors.grey.shade300,
                                foregroundColor: (report?.pass ?? false)
                                    ? Colors.white
                                    : Colors.black54,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Use photo'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.pass, this.detail});

  final String label;
  final bool pass;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            pass ? Icons.check_circle : Icons.cancel,
            color: pass ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (detail != null)
            Text(
              detail!,
              style: TextStyle(
                color: Colors.black.withOpacity(.55),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

// ===== MODEL =====

class SelfieReport {
  final bool pass;
  final int faces;
  final double brightness;
  final double sharpness;
  final double faceCoverage;
  final double centerOffsetRatio;
  final String filePath;
  final String? error;

  SelfieReport({
    required this.pass,
    required this.faces,
    required this.brightness,
    required this.sharpness,
    required this.faceCoverage,
    required this.centerOffsetRatio,
    required this.filePath,
    this.error,
  });

  factory SelfieReport.error(String msg) => SelfieReport(
        pass: false,
        faces: 0,
        brightness: 0,
        sharpness: 0,
        faceCoverage: 0,
        centerOffsetRatio: 1,
        filePath: '',
        error: msg,
      );
}

