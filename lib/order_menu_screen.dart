import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:location/location.dart' as loc;
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';
import 'package:motives_new_ui_conversion/products_items_screen.dart';

// order_menu_screen.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:location/location.dart' as loc;


const kOrange = Color(0xFFFF7A3D);
const kOrangeLite = Color(0xFFFFB07A);
const kText = Color(0xFF0E1631);
const kMuted = Color(0xFF738096);
const kField = Color(0xFFF4F6FA);
const kCard = Colors.white;
const kShadow = Color(0x1A0E1631);

enum VisitLast { none, hold, noVisit }
VisitLast _parseLast(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'hold':
      return VisitLast.hold;
    case 'no_visit':
      return VisitLast.noVisit;
    default:
      return VisitLast.none;
  }
}

class OrderMenuScreen extends StatefulWidget {
  final String shopname, miscid, address;
  final String? segId;
  final String? checkCredit; // "0" or "1"
  final String? orderStatus; // "1" allowed to order

  const OrderMenuScreen({
    super.key,
    required this.shopname,
    required this.miscid,
    required this.address,
    this.segId,
    this.checkCredit,
    this.orderStatus,
  });

  @override
  State<OrderMenuScreen> createState() => _OrderMenuScreenState();
}

class _OrderMenuScreenState extends State<OrderMenuScreen> {
  final box = GetStorage();
  final loc.Location location = loc.Location();

  String checkInText = "Check In";
  bool _hasReasonSelected = false;
  bool _holdToggleVisual = false;

  String lat = "0", lng = "0";

  // ── Loader helpers (no setState -> no build-phase errors) ───────────────────
  bool _loaderShown = false;

  void _showBlockingLoader(BuildContext ctx) {
    if (_loaderShown) return;
    _loaderShown = true;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _hideBlockingLoader(BuildContext ctx) {
    if (!_loaderShown) return;
    _loaderShown = false;
    if (Navigator.of(ctx).canPop()) {
      Navigator.of(ctx).pop();
    }
  }

  // ===== persisted per shop =====
  Map<String, dynamic> _loadStatusMap() {
    final raw = box.read('journey_status');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Future<void> _saveStatus({
    required bool checkedIn,
    required VisitLast last,
    bool? holdUi,
  }) async {
    final map = _loadStatusMap();
    map[widget.miscid] = {
      'checkedIn': checkedIn,
      'last': last == VisitLast.hold
          ? 'hold'
          : (last == VisitLast.noVisit ? 'no_visit' : 'none'),
      'holdUI': holdUi ?? _holdToggleVisual,
    };
    await box.write('journey_status', map);
  }

  ({bool checkedIn, VisitLast last, bool holdUi}) _statusForShop() {
    final map = _loadStatusMap();
    final s = map[widget.miscid];
    if (s is Map) {
      return (
        checkedIn: (s['checkedIn'] == true),
        last: _parseLast(s['last'] as String?),
        holdUi: (s['holdUI'] == true),
      );
    }
    return (checkedIn: false, last: VisitLast.none, holdUi: false);
  }

  Map<String, String> _loadReasonMap() {
    final raw = box.read('journey_reasons');
    if (raw is Map) {
      return raw.map<String, String>(
          (k, v) => MapEntry(k.toString(), v.toString()));
    }
    return {};
  }

  Future<void> _saveReason(String reason) async {
    final map = _loadReasonMap();
    map[widget.miscid] = reason;
    await box.write('journey_reasons', map);
  }

  // ===== helpers =====
  String get _orderStatus {
    final s = context.read<GlobalBloc>().state;
    return widget.orderStatus ?? (s.loginModel?.log?.orderStatus ?? "1");
  }

  bool get _markLocationOn {
    final rights = context.read<GlobalBloc>().state.loginModel?.userRights;
    return (rights?.markLocation ?? "0") == "1";
  }

  bool get _markInvoicesOn {
    final rights = context.read<GlobalBloc>().state.loginModel?.userRights;
    return (rights?.markInvoices ?? "0") == "1";
  }

  bool get _isCheckedIn => checkInText == "Check Out";
  bool get _isLockedNoVisit => _statusForShop().last == VisitLast.noVisit;
  bool get _isHoldActive =>
      _statusForShop().last == VisitLast.hold || _holdToggleVisual;
  bool get _allowCheckInAgain => !_isLockedNoVisit;

  // Lock checkout until a reason is selected
  bool get _checkoutLocked => _isCheckedIn && !_hasReasonSelected;

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _getLocation() async {
    try {
      final hasPerm = await location.hasPermission();
      if (hasPerm == loc.PermissionStatus.denied ||
          hasPerm == loc.PermissionStatus.deniedForever) {
        final req = await location.requestPermission();
        if (req != loc.PermissionStatus.granted) return;
      }
      var en = await location.serviceEnabled();
      if (!en) {
        final ok = await location.requestService();
        if (!ok) return;
      }
      final current = await location.getLocation();
      lat = (current.latitude ?? 0).toString();
      lng = (current.longitude ?? 0).toString();
    } catch (_) {/* ignore */}
  }

  final GetStorage _local = GetStorage();

  String _cartKey(String? userId, String shopId) =>
      'meezan_cart_${userId ?? "guest"}_${shopId}';

  Map<String, int> _readPendingCart() {
    final login = context.read<GlobalBloc>().state.loginModel;
    final userId = login?.userinfo?.userId;

    final raw = _local.read(_cartKey(userId, widget.miscid));
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final map = <String, int>{};
      decoded.forEach((k, v) {
        if (k is String) map[k] = (v is int) ? v : int.tryParse('$v') ?? 0;
      });
      map.removeWhere((_, q) => q <= 0);
      return map;
    } catch (_) {
      return {};
    }
  }

  bool _hasPendingOrder() => _readPendingCart().isNotEmpty;

  Future<void> _showThemedInfo({
    required BuildContext parentCtx,
    required String title,
    required String message,
    String button = 'OK',
  }) async {
    await showDialog(
      context: parentCtx,
      barrierDismissible: true,
      builder: (dialogCtx) => _GlassDialog(
        title: title,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message,
                  style: Theme.of(parentCtx)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: kText)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(button),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showThemedConfirm({
    required BuildContext parentCtx,
    required String title,
    required String message,
    String yesText = 'Yes',
    String noText = 'No',
    required VoidCallback onYes,
  }) async {
    await showDialog(
      context: parentCtx,
      barrierDismissible: false,
      builder: (dialogCtx) => _GlassDialog(
        title: title,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message,
                  style: Theme.of(parentCtx)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: kText)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kMuted,
                        side: BorderSide(color: kMuted.withOpacity(.35)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: Text(noText),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        onYes();
                      },
                      child: Text(yesText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showThemedReasonPicker({
    required BuildContext parentCtx,
    required String dialogTitle,
    required List<String> options,
  }) async {
    int selectedIndex = -1;
    String? chosen;
    await showDialog(
      context: parentCtx,
      barrierDismissible: true,
      builder: (dialogCtx) {
        final t = Theme.of(parentCtx).textTheme;
        return _GlassDialog(
          title: dialogTitle,
          child: StatefulBuilder(
            builder: (ctx, setSB) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (_, i) => RadioListTile<int>(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                      activeColor: kOrange,
                      title:
                          Text(options[i], style: t.bodyMedium?.copyWith(color: kText)),
                      value: i,
                      groupValue: selectedIndex,
                      onChanged: (v) => setSB(() => selectedIndex = v ?? -1),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kMuted,
                            side: BorderSide(color: kMuted.withOpacity(.35)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: selectedIndex == -1
                              ? null
                              : () {
                                  chosen = options[selectedIndex];
                                  Navigator.of(dialogCtx).pop();
                                },
                          child: const Text("Select Reason"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return chosen;
  }

  List<String> _reasonsOfType(String type) {
    final reasons =
        context.read<GlobalBloc>().state.loginModel?.reasons ?? const [];
    return reasons
        .where((r) => (r.type ?? "").toUpperCase() == type.toUpperCase())
        .map((r) => r.name ?? "")
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  // ===== Logic =====
  void _guardRequireCheckIn(VoidCallback action) {
    if (_isHoldActive) {
      _showThemedInfo(
          parentCtx: context,
          title: 'Unhold Required',
          message: 'Unhold first to continue.');
      return;
    }
    if (!_isCheckedIn) {
      _showThemedInfo(
          parentCtx: context,
          title: 'Check-In Required',
          message: 'Please check in first.');
      return;
    }
    action();
  }

  @override
  void initState() {
    super.initState();

    context
        .read<GlobalBloc>()
        .add(Activity(activity: 'Visited Shop ${widget.shopname}'));
    final st = _statusForShop();
    final effectiveCheckedIn = st.last == VisitLast.hold ? true : st.checkedIn;
    checkInText = effectiveCheckedIn ? "Check Out" : "Check In";
    _holdToggleVisual = st.holdUi || st.last == VisitLast.hold;
    _hasReasonSelected = !effectiveCheckedIn || st.last != VisitLast.none;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_markLocationOn) await _getLocation();
    });
  }

  Future<void> _pickHold() async {
    final parentCtx = context;

    if (_markLocationOn && (lat == "0" || lng == "0")) {
      await _showThemedInfo(
        parentCtx: parentCtx,
        title: 'Location',
        message:
            "Can't get location. Please open Google Maps blue dot and try again.",
      );
      return;
    }

    final shopStatusIsHold = _isHoldActive;

    if (!shopStatusIsHold) {
      // pick reason
      final options = _reasonsOfType("HOLD");
      if (options.isEmpty) {
        await _showThemedInfo(
            parentCtx: parentCtx,
            title: 'No Options',
            message: 'No HOLD reasons available.');
        return;
      }
      final chosen = await _showThemedReasonPicker(
        parentCtx: parentCtx,
        dialogTitle: "Select Hold Reason",
        options: options,
      );
      if (chosen == null) return;

      await _showThemedConfirm(
        parentCtx: parentCtx,
        title: 'Confirm Hold',
        message: 'Place this shop on HOLD for reason "$chosen"?',
        onYes: () async {
          await _getLocation();

          // 1) Send HOLD (type 9)
          context.read<GlobalBloc>().add(
                CheckinCheckoutEvent(
                  type: '9',
                  userId: context
                      .read<GlobalBloc>()
                      .state
                      .loginModel!
                      .userinfo!
                      .userId
                      .toString(),
                  lat: lat,
                  lng: lng,
                  act_type: "ORDER_HOLD",
                  action: chosen,
                  misc: widget.miscid,
                  dist_id: context
                      .read<GlobalBloc>()
                      .state
                      .loginModel!
                      .userinfo!
                      .disid
                      .toString(),
                ),
              );

          await _saveReason(chosen);

          // 2) AUTO CHECK-OUT after choosing ANY reason (type 6)
          context.read<GlobalBloc>().add(
                CheckinCheckoutEvent(
                  type: '6',
                  userId: context
                      .read<GlobalBloc>()
                      .state
                      .loginModel!
                      .userinfo!
                      .userId
                      .toString(),
                  lat: lat,
                  lng: lng,
                  act_type: "SHOP_CHECK",
                  action: "OUT",
                  misc: widget.miscid,
                  dist_id: context
                      .read<GlobalBloc>()
                      .state
                      .loginModel!
                      .userinfo!
                      .disid
                      .toString(),
                ),
              );

          // 3) Update local state as checked-out with last=hold
          _holdToggleVisual = false;
          checkInText = "Check In";
          _hasReasonSelected = true;
          await _saveStatus(
              checkedIn: false, last: VisitLast.hold, holdUi: false);

          if (mounted) setState(() {});
          if (mounted)
            Navigator.of(parentCtx).pop({
              'miscid': widget.miscid,
              'kind': 'hold',
              'reason': chosen,
            });
        },
      );
    } else {
      // Unhold
      await _showThemedConfirm(
        parentCtx: parentCtx,
        title: 'Unhold Shop',
        message: 'Remove HOLD and continue?',
        onYes: () async {
          await _getLocation();
          context.read<GlobalBloc>().add(
                CheckinCheckoutEvent(
                  type: '10',
                  userId: context
                      .read<GlobalBloc>()
                      .state
                      .loginModel!
                      .userinfo!
                      .userId
                      .toString(),
                  lat: lat,
                  lng: lng,
                  act_type: "ORDER_HOLD",
                  action: "UNHOLD",
                  misc: widget.miscid,
                  dist_id: context
                      .read<GlobalBloc>()
                      .state
                      .loginModel!
                      .userinfo!
                      .disid
                      .toString(),
                ),
              );
          _holdToggleVisual = false;
          checkInText = "Check Out"; // still checked-in after unhold
          await _saveStatus(
              checkedIn: true, last: VisitLast.none, holdUi: false);
          if (mounted) setState(() {});
        },
      );
    }
  }

  Future<void> _pickNoVisit() async {
    if (_hasPendingOrder()) {
      await _showThemedInfo(
        parentCtx: context,
        title: 'Action Not Allowed',
        message:
            'You have already added items for this shop. Please submit or clear the order before selecting a No Visit reason.',
      );
      return;
    }

    final parentCtx = context;
    final options = _reasonsOfType("NOVISIT");
    if (options.isEmpty) {
      await _showThemedInfo(
          parentCtx: parentCtx,
          title: 'No Options',
          message: 'No NO-VISIT reasons available.');
      return;
    }
    final chosen = await _showThemedReasonPicker(
      parentCtx: parentCtx,
      dialogTitle: "Select No Visit Reason",
      options: options,
    );
    if (chosen == null) return;

    await _showThemedConfirm(
      parentCtx: parentCtx,
      title: 'Confirm No Visit',
      message: 'Confirm NO VISIT for reason "$chosen"?',
      onYes: () async {
        await _getLocation();

        // ORDER reason (type 7)
        context.read<GlobalBloc>().add(CheckinCheckoutEvent(
              type: '7',
              userId: context
                  .read<GlobalBloc>()
                  .state
                  .loginModel!
                  .userinfo!
                  .userId
                  .toString(),
              lat: lat,
              lng: lng,
              act_type: "ORDER",
              action: chosen,
              misc: widget.miscid,
              dist_id: context
                  .read<GlobalBloc>()
                  .state
                  .loginModel!
                  .userinfo!
                  .disid
                  .toString(),
            ));
        // CHECK OUT (type 6)
        context.read<GlobalBloc>().add(CheckinCheckoutEvent(
              type: '6',
              userId: context
                  .read<GlobalBloc>()
                  .state
                  .loginModel!
                  .userinfo!
                  .userId
                  .toString(),
              lat: lat,
              lng: lng,
              act_type: "SHOP_CHECK",
              action: "OUT",
              misc: widget.miscid,
              dist_id: context
                  .read<GlobalBloc>()
                  .state
                  .loginModel!
                  .userinfo!
                  .disid
                  .toString(),
            ));

        await _saveReason(chosen);
        await _saveStatus(
            checkedIn: false, last: VisitLast.noVisit, holdUi: false);
        checkInText = "Check In";
        _hasReasonSelected = true;
        if (mounted) setState(() {});
        if (mounted)
          Navigator.of(parentCtx).pop({
            'miscid': widget.miscid,
            'kind': 'no_order',
            'reason': chosen,
          });
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (_isCheckedIn && !_hasReasonSelected) {
      await _showThemedInfo(
        parentCtx: context,
        title: 'Action Required',
        message: 'Please select a reason (Hold / No Visit) before leaving.',
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return BlocListener<GlobalBloc, GlobalState>(
      listenWhen: (prev, curr) =>
          prev.checkinCheckoutStatus != curr.checkinCheckoutStatus,
          listener: (ctx, state) {
  switch (state.checkinCheckoutStatus) {
    case CheckinCheckoutStatus.loading:
      // _showBlockingLoader(ctx);
      break;

    case CheckinCheckoutStatus.success:
      _hideBlockingLoader(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Synced ✅')),
      );
      break;

    case CheckinCheckoutStatus.queued: // ← NEW
      _hideBlockingLoader(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Saved offline. Will sync when online 🔄')),
      );
      break;

    case CheckinCheckoutStatus.failure:
      _hideBlockingLoader(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
      break;

    case CheckinCheckoutStatus.initial:
    default:
      break;
  }
},

      // listener: (ctx, state) {
      //   switch (state.checkinCheckoutStatus) {
      //     case CheckinCheckoutStatus.loading:
      //       // _showBlockingLoader(ctx);
      //       break;
      //     case CheckinCheckoutStatus.success:
      //       _hideBlockingLoader(ctx);
      //       ScaffoldMessenger.of(ctx).showSnackBar(
      //         const SnackBar(content: Text('Synced ✅')),
      //       );
      //       break;
      //     case CheckinCheckoutStatus.failure:
      //       _hideBlockingLoader(ctx);
      //       ScaffoldMessenger.of(ctx).showSnackBar(
      //         const SnackBar(content: Text('Something went wrong')),
      //       );
      //       break;
      //     case CheckinCheckoutStatus.initial:
      //     default:
      //       break;
      //   }
      // },
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Container(
                      height: 179,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kOrange, kOrangeLite],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 45, 16, 0),
                      child: _GlassHeader(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(.20),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 1.2),
                                  ),
                                  child: const Icon(Icons.store_rounded,
                                      color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(widget.shopname,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: t.titleMedium?.copyWith(
                                            color:
                                                Colors.white.withOpacity(.97),
                                            fontWeight: FontWeight.w700,
                                          )),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.place_rounded,
                                              size: 16,
                                              color: Colors.white
                                                  .withOpacity(.9)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              widget.address,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: t.bodySmall?.copyWith(
                                                color: Colors.white
                                                    .withOpacity(.95),
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _Chip(
                                  label: _isCheckedIn
                                      ? "Checked-In"
                                      : "Not Checked-In",
                                  icon: _isCheckedIn
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: Colors.white.withOpacity(.18),
                                  textColor: Colors.white,
                                  borderColor: Colors.white.withOpacity(.45),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // GRID
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.05,
                  ),
                  delegate: SliverChildListDelegate.fixed([
                    // CHECK-IN / OUT
                    _TapScale(
                      onTap: () async {
                        if (_isHoldActive) {
                          await _showThemedInfo(
                              parentCtx: context,
                              title: 'Unhold Required',
                              message: 'Unhold first to continue.');
                          return;
                        }
                        // Lock checkout until a reason is selected
                        if (checkInText == "Check Out" && _checkoutLocked) {
                          await _showThemedInfo(
                            parentCtx: context,
                            title: 'Reason Required',
                            message:
                                'Select a reason (Hold / No Visit) before checking out.',
                          );
                          return;
                        }
                        if (checkInText == "Check In" && !_allowCheckInAgain) {
                          await _showThemedInfo(
                              parentCtx: context,
                              title: 'Not Allowed',
                              message:
                                  'Re-check in is not allowed (No Visit selected earlier).');
                          return;
                        }
                        if (_markLocationOn && (lat == "0" || lng == "0")) {
                          await _showThemedInfo(
                              parentCtx: context,
                              title: 'Location',
                              message:
                                  "Can't get location. Please open Google Maps blue dot.");
                          return;
                        }
                        await _getLocation();

                        if (checkInText == "Check In") {
                          await _showThemedConfirm(
                            parentCtx: context,
                            title: 'Shop Check-In',
                            message: 'Do you want to Check-In?',
                            onYes: () async {
                              context.read<GlobalBloc>().add(
                                    CheckinCheckoutEvent(
                                      type: '5',
                                      userId: context
                                          .read<GlobalBloc>()
                                          .state
                                          .loginModel!
                                          .userinfo!
                                          .userId
                                          .toString(),
                                      lat: lat,
                                      lng: lng,
                                      act_type: "SHOP_CHECK",
                                      action: "IN",
                                      misc: widget.miscid,
                                      dist_id: context
                                          .read<GlobalBloc>()
                                          .state
                                          .loginModel!
                                          .userinfo!
                                          .disid
                                          .toString(),
                                    ),
                                  );
                              setState(() {
                                checkInText = "Check Out";
                                _hasReasonSelected =
                                    false; // must choose a reason before checkout
                              });
                              final st = _statusForShop();
                              await _saveStatus(
                                  checkedIn: true,
                                  last: st.last,
                                  holdUi: _holdToggleVisual);
                            },
                          );
                        } else {
                          // Normal checkout (when not locked)
                          await _showThemedConfirm(
                            parentCtx: context,
                            title: 'Shop Check-Out',
                            message: 'Do you want to Check-Out?',
                            onYes: () async {
                              context.read<GlobalBloc>().add(
                                    CheckinCheckoutEvent(
                                      type: '6',
                                      userId: context
                                          .read<GlobalBloc>()
                                          .state
                                          .loginModel!
                                          .userinfo!
                                          .userId
                                          .toString(),
                                      lat: lat,
                                      lng: lng,
                                      act_type: "SHOP_CHECK",
                                      action: "OUT",
                                      misc: widget.miscid,
                                      dist_id: context
                                          .read<GlobalBloc>()
                                          .state
                                          .loginModel!
                                          .userinfo!
                                          .disid
                                          .toString(),
                                    ),
                                  );
                              setState(() {
                                checkInText = "Check In";
                                _hasReasonSelected = true;
                              });
                              final st = _statusForShop();
                              await _saveStatus(
                                  checkedIn: false,
                                  last: st.last,
                                  holdUi: _holdToggleVisual);
                              if (mounted) Navigator.pop(context);
                            },
                          );
                        }
                      },
                      child: _CategoryCard(
                        icon: Icons.access_time,
                        title: checkInText,
                        subtitle:
                            'Shop ${checkInText == "Check In" ? "Checkin" : "Checkout"}',
                      ),
                    ),

                 /*   _TapScale(
  onTap: () => _guardRequireCheckIn(() async {
    final res = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => MeezanTeaCatalog(shopId: widget.miscid)),
    );

    if (res is Map &&
        res!['miscid'] == widget.miscid &&
        (res['reason'] ?? '') == 'ORDER PLACED') {
      // mark reason locally
      await _saveReason('ORDER PLACED');
      await _saveStatus(checkedIn: false, last: VisitLast.none, holdUi: false);
      checkInText = "Check In";
      _hasReasonSelected = true;

      // 🔑 get ids from same place as other events on THIS screen
      final gb = context.read<GlobalBloc>();
      final login = gb.state.loginModel!;
      final uid  = login.userinfo!.userId.toString();
      final did  = login.userinfo!.disid.toString();

      await _getLocation();

      // ✅ 1) ORDER event
      gb.add(CheckinCheckoutEvent(
        type: '7',
        userId: uid,
        lat: lat,
        lng: lng,
        act_type: 'ORDER',
        action: 'ORDER PLACED',
        misc: widget.miscid,
        dist_id: did,
      ));

      // ✅ 2) CHECKOUT event
      gb.add(CheckinCheckoutEvent(
        type: '6',
        userId: uid,
        lat: lat,
        lng: lng,
        act_type: 'SHOP_CHECK',
        action: 'OUT',
        misc: widget.miscid,
        dist_id: did,
      ));

      if (mounted) {
        Navigator.pop(context, res);
      }
    }
  }),
  child: const _CategoryCard(
    icon: Icons.playlist_add_check_rounded,
    title: 'Take Order',
    subtitle: 'Orders',
  ),
),*/

_TapScale(
  onTap: () => _guardRequireCheckIn(() async {
    final res = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MeezanTeaCatalog(shopId: widget.miscid),
      ),
    );

    if (res is Map &&
        res!['miscid'] == widget.miscid &&
        (res['reason'] ?? '') == 'ORDER PLACED') {
      // update local UI + storage
      await _saveReason('ORDER PLACED');
      await _saveStatus(
        checkedIn: false,
        last: VisitLast.none,
        holdUi: false,
      );
      setState(() {
        checkInText = 'Check In';
        _hasReasonSelected = true;
      });

      // ⬅️ that's it – events are sent from the order screen (where we have order_id)
      if (mounted) {
        Navigator.pop(context, res);
      }
    }
  }),
  child: const _CategoryCard(
    icon: Icons.playlist_add_check_rounded,
    title: 'Take Order',
    subtitle: 'Orders',
  ),
),

//                     _TapScale(
//   onTap: () => _guardRequireCheckIn(() async {
//     final res = await Navigator.push<Map<String, dynamic>>(
//       context,
//       MaterialPageRoute(builder: (_) => MeezanTeaCatalog(shopId: widget.miscid)),
//     );

//     if (res is Map &&
//         res!['miscid'] == widget.miscid &&
//         (res['reason'] ?? '') == 'ORDER PLACED') {
//       // mark reason locally
//       await _saveReason('ORDER PLACED');
//       await _saveStatus(checkedIn: false, last: VisitLast.none, holdUi: false);
//       checkInText = "Check In";
//       _hasReasonSelected = true;

//       // ✅ also fire Shop CHECK-OUT (type 6) here, then go back to Journey Plan
//       await _getLocation();
//       context.read<GlobalBloc>().add(
//         CheckinCheckoutEvent(
//           type: '6',
//           userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
//           lat: lat,
//           lng: lng,
//           act_type: "SHOP_CHECK",
//           action: "OUT",
//           misc: widget.miscid,
//           dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
//         ),
//       );

//       if (mounted) {
//         Navigator.pop(context, res); // ⬅️ back to Journey Plan with status
//       }
//     }
//   }),
//   child: const _CategoryCard(
//     icon: Icons.playlist_add_check_rounded,
//     title: 'Take Order',
//     subtitle: 'Orders',
//   ),
// ),


                    // TAKE ORDER
                    // _TapScale(
                    //   onTap: () => _guardRequireCheckIn(() async {
                    //     if (_orderStatus != "1") {
                    //       Navigator.push(
                    //           context,
                    //           MaterialPageRoute(
                    //               builder: (_) =>
                    //                   MeezanTeaCatalog(shopId: widget.miscid)));
                    //       return;
                    //     }
                    //     _toast('Take Order tapped'); // TODO: Navigate
                    //   }),
                    //   child: const _CategoryCard(
                    //     icon: Icons.playlist_add_check_rounded,
                    //     title: 'Take Order',
                    //     subtitle: 'Orders',
                    //   ),
                    // ),

                    // HOLD / UNHOLD
                    _TapScale(
                      onTap: () {
                        if (!_isCheckedIn) {
                          _showThemedInfo(
                              parentCtx: context,
                              title: 'Check-In Required',
                              message: 'Please check in first.');
                          return;
                        }
                        _pickHold();
                      },
                      child: _CategoryCard(
                        icon: _holdToggleVisual
                            ? Icons.play_circle_outline
                            : Icons.pause_rounded,
                        title: _holdToggleVisual ? 'Unhold' : 'Hold',
                        subtitle:
                            _holdToggleVisual ? 'Tap to Unhold' : 'Hold Reason',
                      ),
                    ),

                    // NO VISIT
                    _TapScale(
                      onTap: () => _guardRequireCheckIn(_pickNoVisit),
                      child: const _CategoryCard(
                        icon: Icons.visibility_off_rounded,
                        title: 'No Visit',
                        subtitle: 'Select Reason',
                      ),
                    ),

                    // Collect Payment
                    // _TapScale(
                    //   onTap: () => _guardRequireCheckIn(() async {
                    //     if (!_markInvoicesOn) {
                    //       await _showThemedInfo(
                    //           parentCtx: context,
                    //           title: 'Not Allowed',
                    //           message:
                    //               "You don't have rights to view invoices!");
                    //       return;
                    //     }
                    //     _toast('Invoices tapped'); // TODO: Navigate
                    //   }),
                    //   child: const _CategoryCard(
                    //     icon: Icons.payments_rounded,
                    //     title: 'Collect Payment',
                    //     subtitle: 'Invoices',
                    //   ),
                    // ),

                    // // Sale History
                    // _TapScale(
                    //   onTap: () => _guardRequireCheckIn(() {
                    //     _toast('History tapped'); // TODO: Navigate
                    //   }),
                    //   child: const _CategoryCard(
                    //     icon: Icons.history_rounded,
                    //     title: 'Sale History',
                    //     subtitle: 'History',
                    //   ),
                    // ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared visual widgets ─────────────────────────────────────────────────────
class _GlassHeader extends StatelessWidget {
  const _GlassHeader({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassDialog extends StatelessWidget {
  final String title;
  final Widget child;
  const _GlassDialog({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kOrange, kOrangeLite],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Container(
          margin: const EdgeInsets.all(1.8),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: const BoxDecoration(
                  color: kField,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Text(title,
                    textAlign: TextAlign.center,
                    style: t.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800, color: kText)),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color borderColor;

  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [kOrange, kOrangeLite],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.8),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14.2),
          boxShadow: const [
            BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10))
          ],
          border: Border.all(color: Color(0xFFEDEFF2)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
                color: kField,
                shape: const CircleBorder(),
                child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(icon, color: kOrange))),
            const Spacer(),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.titleSmall?.copyWith(
                    color: kText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .2)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(color: kMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _TapScale extends StatefulWidget {
  const _TapScale({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  void _down(TapDownDetails _) => setState(() => _scale = .98);
  void _up([_]) => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapCancel: _up,
      onTapUp: _up,
      onTap: widget.onTap,
      child: AnimatedScale(
          duration: const Duration(milliseconds: 90),
          scale: _scale,
          child: widget.child),
    );
  }
}




// const kOrange = Color(0xFFFF7A3D);
// const kOrangeLite = Color(0xFFFFB07A);
// const kText = Color(0xFF0E1631);
// const kMuted = Color(0xFF738096);
// const kField = Color(0xFFF4F6FA);
// const kCard = Colors.white;
// const kShadow = Color(0x1A0E1631);

// enum VisitLast { none, hold, noVisit }
// VisitLast _parseLast(String? s) {
//   switch ((s ?? '').toLowerCase()) {
//     case 'hold':
//       return VisitLast.hold;
//     case 'no_visit':
//       return VisitLast.noVisit;
//     default:
//       return VisitLast.none;
//   }
// }

// class OrderMenuScreen extends StatefulWidget {
//   final String shopname, miscid, address;
//   final String? segId;
//   final String? checkCredit; // "0" or "1"
//   final String? orderStatus; // "1" allowed to order

//   const OrderMenuScreen({
//     super.key,
//     required this.shopname,
//     required this.miscid,
//     required this.address,
//     this.segId,
//     this.checkCredit,
//     this.orderStatus,
//   });

//   @override
//   State<OrderMenuScreen> createState() => _OrderMenuScreenState();
// }

// class _OrderMenuScreenState extends State<OrderMenuScreen> {
//   final box = GetStorage();
//   final loc.Location location = loc.Location();

//   String checkInText = "Check In";
//   bool _hasReasonSelected = false;
//   bool _holdToggleVisual = false;

//   String lat = "0", lng = "0";

//   // ===== persisted per shop =====
//   Map<String, dynamic> _loadStatusMap() {
//     final raw = box.read('journey_status');
//     if (raw is Map) return Map<String, dynamic>.from(raw);
//     return {};
//   }

//   Future<void> _saveStatus({
//     required bool checkedIn,
//     required VisitLast last,
//     bool? holdUi,
//   }) async {
//     final map = _loadStatusMap();
//     map[widget.miscid] = {
//       'checkedIn': checkedIn,
//       'last': last == VisitLast.hold
//           ? 'hold'
//           : (last == VisitLast.noVisit ? 'no_visit' : 'none'),
//       'holdUI': holdUi ?? _holdToggleVisual,
//     };
//     await box.write('journey_status', map);
//   }

//   ({bool checkedIn, VisitLast last, bool holdUi}) _statusForShop() {
//     final map = _loadStatusMap();
//     final s = map[widget.miscid];
//     if (s is Map) {
//       return (
//         checkedIn: (s['checkedIn'] == true),
//         last: _parseLast(s['last'] as String?),
//         holdUi: (s['holdUI'] == true),
//       );
//     }
//     return (checkedIn: false, last: VisitLast.none, holdUi: false);
//   }

//   Map<String, String> _loadReasonMap() {
//     final raw = box.read('journey_reasons');
//     if (raw is Map) {
//       return raw.map<String, String>(
//           (k, v) => MapEntry(k.toString(), v.toString()));
//     }
//     return {};
//   }

//   Future<void> _saveReason(String reason) async {
//     final map = _loadReasonMap();
//     map[widget.miscid] = reason;
//     await box.write('journey_reasons', map);
//   }

//   // ===== helpers =====
//   String get _orderStatus {
//     final s = context.read<GlobalBloc>().state;
//     return widget.orderStatus ?? (s.loginModel?.log?.orderStatus ?? "1");
//   }

//   bool get _markLocationOn {
//     final rights = context.read<GlobalBloc>().state.loginModel?.userRights;
//     return (rights?.markLocation ?? "0") == "1";
//   }

//   bool get _markInvoicesOn {
//     final rights = context.read<GlobalBloc>().state.loginModel?.userRights;
//     return (rights?.markInvoices ?? "0") == "1";
//   }

//   bool get _isCheckedIn => checkInText == "Check Out";
//   bool get _isLockedNoVisit => _statusForShop().last == VisitLast.noVisit;
//   bool get _isHoldActive =>
//       _statusForShop().last == VisitLast.hold || _holdToggleVisual;
//   bool get _allowCheckInAgain => !_isLockedNoVisit;

//   // NEW: lock checkout until a reason is selected
//   bool get _checkoutLocked => _isCheckedIn && !_hasReasonSelected;

//   void _toast(String msg) => ScaffoldMessenger.of(context)
//       .showSnackBar(SnackBar(content: Text(msg)));

//   Future<void> _getLocation() async {
//     try {
//       final hasPerm = await location.hasPermission();
//       if (hasPerm == loc.PermissionStatus.denied ||
//           hasPerm == loc.PermissionStatus.deniedForever) {
//         final req = await location.requestPermission();
//         if (req != loc.PermissionStatus.granted) return;
//       }
//       var en = await location.serviceEnabled();
//       if (!en) {
//         final ok = await location.requestService();
//         if (!ok) return;
//       }
//       final current = await location.getLocation();
//       lat = (current.latitude ?? 0).toString();
//       lng = (current.longitude ?? 0).toString();
//     } catch (_) {/* ignore */}
//   }

//   final GetStorage _local = GetStorage();

//   String _cartKey(String? userId, String shopId) =>
//       'meezan_cart_${userId ?? "guest"}_${shopId}';

//   Map<String, int> _readPendingCart() {
//     final login = context.read<GlobalBloc>().state.loginModel;
//     final userId = login?.userinfo?.userId;

//     final raw = _local.read(_cartKey(userId, widget.miscid));
//     if (raw == null) return {};
//     try {
//       final decoded = jsonDecode(raw);
//       if (decoded is! Map) return {};
//       final map = <String, int>{};
//       decoded.forEach((k, v) {
//         if (k is String) map[k] = (v is int) ? v : int.tryParse('$v') ?? 0;
//       });
//       map.removeWhere((_, q) => q <= 0);
//       return map;
//     } catch (_) {
//       return {};
//     }
//   }

//   bool _hasPendingOrder() => _readPendingCart().isNotEmpty;

//   Future<void> _showThemedInfo({
//     required BuildContext parentCtx,
//     required String title,
//     required String message,
//     String button = 'OK',
//   }) async {
//     await showDialog(
//       context: parentCtx,
//       barrierDismissible: true,
//       builder: (dialogCtx) => _GlassDialog(
//         title: title,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(message,
//                   style: Theme.of(parentCtx)
//                       .textTheme
//                       .bodyMedium
//                       ?.copyWith(color: kText)),
//               const SizedBox(height: 14),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: kOrange,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12)),
//                     elevation: 0,
//                   ),
//                   onPressed: () => Navigator.of(dialogCtx).pop(),
//                   child: Text(button),
//                 ),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _showThemedConfirm({
//     required BuildContext parentCtx,
//     required String title,
//     required String message,
//     String yesText = 'Yes',
//     String noText = 'No',
//     required VoidCallback onYes,
//   }) async {
//     await showDialog(
//       context: parentCtx,
//       barrierDismissible: false,
//       builder: (dialogCtx) => _GlassDialog(
//         title: title,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(message,
//                   style: Theme.of(parentCtx)
//                       .textTheme
//                       .bodyMedium
//                       ?.copyWith(color: kText)),
//               const SizedBox(height: 14),
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: kMuted,
//                         side: BorderSide(color: kMuted.withOpacity(.35)),
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12)),
//                       ),
//                       onPressed: () => Navigator.of(dialogCtx).pop(),
//                       child: Text(noText),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: kOrange,
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12)),
//                         elevation: 0,
//                       ),
//                       onPressed: () {
//                         Navigator.of(dialogCtx).pop();
//                         onYes();
//                       },
//                       child: Text(yesText),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<String?> _showThemedReasonPicker({
//     required BuildContext parentCtx,
//     required String dialogTitle,
//     required List<String> options,
//   }) async {
//     int selectedIndex = -1;
//     String? chosen;
//     await showDialog(
//       context: parentCtx,
//       barrierDismissible: true,
//       builder: (dialogCtx) {
//         final t = Theme.of(parentCtx).textTheme;
//         return _GlassDialog(
//           title: dialogTitle,
//           child: StatefulBuilder(
//             builder: (ctx, setSB) => Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Flexible(
//                   child: ListView.separated(
//                     shrinkWrap: true,
//                     padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
//                     itemCount: options.length,
//                     separatorBuilder: (_, __) => const SizedBox(height: 2),
//                     itemBuilder: (_, i) => RadioListTile<int>(
//                       dense: true,
//                       contentPadding:
//                           const EdgeInsets.symmetric(horizontal: 6),
//                       visualDensity: VisualDensity.compact,
//                       activeColor: kOrange,
//                       title: Text(options[i],
//                           style:
//                               t.bodyMedium?.copyWith(color: kText)),
//                       value: i,
//                       groupValue: selectedIndex,
//                       onChanged: (v) => setSB(() => selectedIndex = v ?? -1),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           style: OutlinedButton.styleFrom(
//                             foregroundColor: kMuted,
//                             side: BorderSide(color: kMuted.withOpacity(.35)),
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12)),
//                           ),
//                           onPressed: () => Navigator.of(dialogCtx).pop(),
//                           child: const Text("Cancel"),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: kOrange,
//                             foregroundColor: Colors.white,
//                             elevation: 0,
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12)),
//                           ),
//                           onPressed: selectedIndex == -1
//                               ? null
//                               : () {
//                                   chosen = options[selectedIndex];
//                                   Navigator.of(dialogCtx).pop();
//                                 },
//                           child: const Text("Select Reason"),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//     return chosen;
//   }

//   List<String> _reasonsOfType(String type) {
//     final reasons =
//         context.read<GlobalBloc>().state.loginModel?.reasons ?? const [];
//     return reasons
//         .where((r) => (r.type ?? "").toUpperCase() == type.toUpperCase())
//         .map((r) => r.name ?? "")
//         .where((s) => s.trim().isNotEmpty)
//         .toList();
//   }

//   // ===== Logic =====
//   void _guardRequireCheckIn(VoidCallback action) {
//     if (_isHoldActive) {
//       _showThemedInfo(
//           parentCtx: context,
//           title: 'Unhold Required',
//           message: 'Unhold first to continue.');
//       return;
//     }
//     if (!_isCheckedIn) {
//       _showThemedInfo(
//           parentCtx: context,
//           title: 'Check-In Required',
//           message: 'Please check in first.');
//       return;
//     }
//     action();
//   }

//   @override
//   void initState() {
//     super.initState();

//        context.read<GlobalBloc>().add(Activity(activity: 'Visited Shop ${widget.shopname}'));
//     final st = _statusForShop();
//     final effectiveCheckedIn = st.last == VisitLast.hold ? true : st.checkedIn;
//     checkInText = effectiveCheckedIn ? "Check Out" : "Check In";
//     _holdToggleVisual = st.holdUi || st.last == VisitLast.hold;
//     _hasReasonSelected = !effectiveCheckedIn || st.last != VisitLast.none;

//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       if (_markLocationOn) await _getLocation();
//     });
//   }

//   Future<void> _pickHold() async {
//     final parentCtx = context;

//     if (_markLocationOn && (lat == "0" || lng == "0")) {
//       await _showThemedInfo(
//         parentCtx: parentCtx,
//         title: 'Location',
//         message:
//             "Can't get location. Please open Google Maps blue dot and try again.",
//       );
//       return;
//     }

//     final shopStatusIsHold = _isHoldActive;

//     if (!shopStatusIsHold) {
//       // pick reason
//       final options = _reasonsOfType("HOLD");
//       if (options.isEmpty) {
//         await _showThemedInfo(
//             parentCtx: parentCtx,
//             title: 'No Options',
//             message: 'No HOLD reasons available.');
//         return;
//       }
//       final chosen = await _showThemedReasonPicker(
//         parentCtx: parentCtx,
//         dialogTitle: "Select Hold Reason",
//         options: options,
//       );
//       if (chosen == null) return;

//       await _showThemedConfirm(
//         parentCtx: parentCtx,
//         title: 'Confirm Hold',
//         message: 'Place this shop on HOLD for reason "$chosen"?',
//         onYes: () async {
//           await _getLocation();

//           // 1) Send HOLD (type 9)
//           context.read<GlobalBloc>().add(
//                 CheckinCheckoutEvent(
//                   type: '9',
//                   userId: context
//                       .read<GlobalBloc>()
//                       .state
//                       .loginModel!
//                       .userinfo!
//                       .userId
//                       .toString(),
//                   lat: lat,
//                   lng: lng,
//                   act_type: "ORDER_HOLD",
//                   action: chosen,
//                   misc: widget.miscid,
//                   dist_id: context
//                       .read<GlobalBloc>()
//                       .state
//                       .loginModel!
//                       .userinfo!
//                       .disid
//                       .toString(),
//                 ),
//               );

//           await _saveReason(chosen);

//           // 2) AUTO CHECK-OUT immediately after choosing ANY reason (type 6)
//           context.read<GlobalBloc>().add(
//                 CheckinCheckoutEvent(
//                   type: '6',
//                   userId: context
//                       .read<GlobalBloc>()
//                       .state
//                       .loginModel!
//                       .userinfo!
//                       .userId
//                       .toString(),
//                   lat: lat,
//                   lng: lng,
//                   act_type: "SHOP_CHECK",
//                   action: "OUT",
//                   misc: widget.miscid,
//                   dist_id: context
//                       .read<GlobalBloc>()
//                       .state
//                       .loginModel!
//                       .userinfo!
//                       .disid
//                       .toString(),
//                 ),
//               );

//           // 3) Update local state as checked-out with last=hold
//           _holdToggleVisual = false; // not in-hold UI while checked-out
//           checkInText = "Check In";
//           _hasReasonSelected = true;
//           await _saveStatus(
//               checkedIn: false, last: VisitLast.hold, holdUi: false);

//           if (mounted) setState(() {});
//           if (mounted)
//             Navigator.of(parentCtx).pop({
//               'miscid': widget.miscid,
//               'kind': 'hold',
//               'reason': chosen,
//             });
//         },
//       );
//     } else {
//       // Unhold path (kept exactly as before)
//       await _showThemedConfirm(
//         parentCtx: parentCtx,
//         title: 'Unhold Shop',
//         message: 'Remove HOLD and continue?',
//         onYes: () async {
//           await _getLocation();
//           context.read<GlobalBloc>().add(
//                 CheckinCheckoutEvent(
//                   type: '10',
//                   userId: context
//                       .read<GlobalBloc>()
//                       .state
//                       .loginModel!
//                       .userinfo!
//                       .userId
//                       .toString(),
//                   lat: lat,
//                   lng: lng,
//                   act_type: "ORDER_HOLD",
//                   action: "UNHOLD",
//                   misc: widget.miscid,
//                   dist_id: context
//                       .read<GlobalBloc>()
//                       .state
//                       .loginModel!
//                       .userinfo!
//                       .disid
//                       .toString(),
//                 ),
//               );
//           _holdToggleVisual = false;
//           checkInText = "Check Out"; // still considered checked-in after unhold
//           await _saveStatus(
//               checkedIn: true, last: VisitLast.none, holdUi: false);
//           if (mounted) setState(() {});
//         },
//       );
//     }
//   }

//   Future<void> _pickNoVisit() async {
//     // Block if there is an in-progress order
//     if (_hasPendingOrder()) {
//       await _showThemedInfo(
//         parentCtx: context,
//         title: 'Action Not Allowed',
//         message:
//             'You have already added items for this shop. Please submit or clear the order before selecting a No Visit reason.',
//       );
//       return;
//     }

//     final parentCtx = context;
//     final options = _reasonsOfType("NOVISIT");
//     if (options.isEmpty) {
//       await _showThemedInfo(
//           parentCtx: parentCtx,
//           title: 'No Options',
//           message: 'No NO-VISIT reasons available.');
//       return;
//     }
//     final chosen = await _showThemedReasonPicker(
//       parentCtx: parentCtx,
//       dialogTitle: "Select No Visit Reason",
//       options: options,
//     );
//     if (chosen == null) return;

//     await _showThemedConfirm(
//       parentCtx: parentCtx,
//       title: 'Confirm No Visit',
//       message: 'Confirm NO VISIT for reason "$chosen"?',
//       onYes: () async {
//         await _getLocation();

//         // ORDER reason (type 7)
//         context.read<GlobalBloc>().add(CheckinCheckoutEvent(
//               type: '7',
//               userId: context
//                   .read<GlobalBloc>()
//                   .state
//                   .loginModel!
//                   .userinfo!
//                   .userId
//                   .toString(),
//               lat: lat,
//               lng: lng,
//               act_type: "ORDER",
//               action: chosen,
//               misc: widget.miscid,
//               dist_id: context
//                   .read<GlobalBloc>()
//                   .state
//                   .loginModel!
//                   .userinfo!
//                   .disid
//                   .toString(),
//             ));
//         // CHECK OUT (type 6)
//         context.read<GlobalBloc>().add(CheckinCheckoutEvent(
//               type: '6',
//               userId: context
//                   .read<GlobalBloc>()
//                   .state
//                   .loginModel!
//                   .userinfo!
//                   .userId
//                   .toString(),
//               lat: lat,
//               lng: lng,
//               act_type: "SHOP_CHECK",
//               action: "OUT",
//               misc: widget.miscid,
//               dist_id: context
//                   .read<GlobalBloc>()
//                   .state
//                   .loginModel!
//                   .userinfo!
//                   .disid
//                   .toString(),
//             ));

//         await _saveReason(chosen);
//         await _saveStatus(
//             checkedIn: false, last: VisitLast.noVisit, holdUi: false);
//         checkInText = "Check In";
//         _hasReasonSelected = true;
//         if (mounted) setState(() {});
//         if (mounted)
//           Navigator.of(parentCtx).pop({
//             'miscid': widget.miscid,
//             'kind': 'no_order',
//             'reason': chosen,
//           });
//       },
//     );
//   }

//   Future<bool> _onWillPop() async {
//     if (_isCheckedIn && !_hasReasonSelected) {
//       await _showThemedInfo(
//         parentCtx: context,
//         title: 'Action Required',
//         message: 'Please select a reason (Hold / No Visit) before leaving.',
//       );
//       return false;
//     }
//     return true;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: CustomScrollView(
//           physics: const BouncingScrollPhysics(),
//           slivers: [
//             SliverToBoxAdapter(
//               child: Stack(
//                 children: [
//                   Container(
//                     height: 179,
//                     decoration: const BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [kOrange, kOrangeLite],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 45, 16, 0),
//                     child: _GlassHeader(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Container(
//                                 width: 46,
//                                 height: 46,
//                                 decoration: BoxDecoration(
//                                   color: Colors.white.withOpacity(.20),
//                                   shape: BoxShape.circle,
//                                   border: Border.all(
//                                       color: Colors.white, width: 1.2),
//                                 ),
//                                 child: const Icon(Icons.store_rounded,
//                                     color: Colors.white, size: 22),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(widget.shopname,
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                         style: t.titleMedium?.copyWith(
//                                           color: Colors.white.withOpacity(.97),
//                                           fontWeight: FontWeight.w700,
//                                         )),
//                                     const SizedBox(height: 4),
//                                     Row(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Icon(Icons.place_rounded,
//                                             size: 16,
//                                             color:
//                                                 Colors.white.withOpacity(.9)),
//                                         const SizedBox(width: 4),
//                                         Expanded(
//                                           child: Text(
//                                             widget.address,
//                                             maxLines: 2,
//                                             overflow: TextOverflow.ellipsis,
//                                             style: t.bodySmall?.copyWith(
//                                               color:
//                                                   Colors.white.withOpacity(.95),
//                                               height: 1.2,
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 10),
//                           Row(
//                             children: [
//                               _Chip(
//                                 label: _isCheckedIn
//                                     ? "Checked-In"
//                                     : "Not Checked-In",
//                                 icon: _isCheckedIn
//                                     ? Icons.check_circle
//                                     : Icons.radio_button_unchecked,
//                                 color: Colors.white.withOpacity(.18),
//                                 textColor: Colors.white,
//                                 borderColor: Colors.white.withOpacity(.45),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // GRID
//             SliverPadding(
//               padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
//               sliver: SliverGrid(
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 2,
//                   crossAxisSpacing: 14,
//                   mainAxisSpacing: 14,
//                   childAspectRatio: 1.05,
//                 ),
//                 delegate: SliverChildListDelegate.fixed([
//                   // CHECK-IN / OUT
//                   _TapScale(
//                     onTap: () async {
//                       if (_isHoldActive) {
//                         await _showThemedInfo(
//                             parentCtx: context,
//                             title: 'Unhold Required',
//                             message: 'Unhold first to continue.');
//                         return;
//                       }
//                       // Lock checkout until a reason is selected (no UI change)
//                       if (checkInText == "Check Out" && _checkoutLocked) {
//                         await _showThemedInfo(
//                           parentCtx: context,
//                           title: 'Reason Required',
//                           message:
//                               'Select a reason (Hold / No Visit) before checking out.',
//                         );
//                         return;
//                       }
//                       if (checkInText == "Check In" && !_allowCheckInAgain) {
//                         await _showThemedInfo(
//                             parentCtx: context,
//                             title: 'Not Allowed',
//                             message:
//                                 'Re-check in is not allowed (No Visit selected earlier).');
//                         return;
//                       }
//                       if (_markLocationOn && (lat == "0" || lng == "0")) {
//                         await _showThemedInfo(
//                             parentCtx: context,
//                             title: 'Location',
//                             message:
//                                 "Can't get location. Please open Google Maps blue dot.");
//                         return;
//                       }
//                       await _getLocation();

//                       if (checkInText == "Check In") {
//                         await _showThemedConfirm(
//                           parentCtx: context,
//                           title: 'Shop Check-In',
//                           message: 'Do you want to Check-In?',
//                           onYes: () async {
//                             context.read<GlobalBloc>().add(
//                                   CheckinCheckoutEvent(
//                                     type: '5',
//                                     userId: context
//                                         .read<GlobalBloc>()
//                                         .state
//                                         .loginModel!
//                                         .userinfo!
//                                         .userId
//                                         .toString(),
//                                     lat: lat,
//                                     lng: lng,
//                                     act_type: "SHOP_CHECK",
//                                     action: "IN",
//                                     misc: widget.miscid,
//                                     dist_id: context
//                                         .read<GlobalBloc>()
//                                         .state
//                                         .loginModel!
//                                         .userinfo!
//                                         .disid
//                                         .toString(),
//                                   ),
//                                 );
//                             setState(() {
//                               checkInText = "Check Out";
//                               _hasReasonSelected =
//                                   false; // must choose a reason before checkout
//                             });
//                             final st = _statusForShop();
//                             await _saveStatus(
//                                 checkedIn: true,
//                                 last: st.last,
//                                 holdUi: _holdToggleVisual);
//                           },
//                         );
//                       } else {
//                         // Normal checkout path when not locked
//                         await _showThemedConfirm(
//                           parentCtx: context,
//                           title: 'Shop Check-Out',
//                           message: 'Do you want to Check-Out?',
//                           onYes: () async {
//                             context.read<GlobalBloc>().add(
//                                   CheckinCheckoutEvent(
//                                     type: '6',
//                                     userId: context
//                                         .read<GlobalBloc>()
//                                         .state
//                                         .loginModel!
//                                         .userinfo!
//                                         .userId
//                                         .toString(),
//                                     lat: lat,
//                                     lng: lng,
//                                     act_type: "SHOP_CHECK",
//                                     action: "OUT",
//                                     misc: widget.miscid,
//                                     dist_id: context
//                                         .read<GlobalBloc>()
//                                         .state
//                                         .loginModel!
//                                         .userinfo!
//                                         .disid
//                                         .toString(),
//                                   ),
//                                 );
//                             setState(() {
//                               checkInText = "Check In";
//                               _hasReasonSelected = true;
//                             });
//                             final st = _statusForShop();
//                             await _saveStatus(
//                                 checkedIn: false,
//                                 last: st.last,
//                                 holdUi: _holdToggleVisual);
//                             if (mounted) Navigator.pop(context);
//                           },
//                         );
//                       }
//                     },
//                     child: _CategoryCard(
//                       icon: Icons.access_time,
//                       title: checkInText,
//                       // subtitle unchanged (no UI change)
//                       subtitle:
//                           'Shop ${checkInText == "Check In" ? "Checkin" : "Checkout"}',
//                     ),
//                   ),

//                   // TAKE ORDER
//                   _TapScale(
//                     onTap: () => _guardRequireCheckIn(() async {
//                       if (_orderStatus != "1") {
//                         Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (_) =>
//                                     MeezanTeaCatalog(shopId: widget.miscid)));
//                         return;
//                       }
//                       _toast('Take Order tapped'); // TODO: Navigate
//                     }),
//                     child: const _CategoryCard(
//                       icon: Icons.playlist_add_check_rounded,
//                       title: 'Take Order',
//                       subtitle: 'Orders',
//                     ),
//                   ),

//                   // HOLD / UNHOLD
//                   _TapScale(
//                     onTap: () {
//                       if (!_isCheckedIn) {
//                         _showThemedInfo(
//                             parentCtx: context,
//                             title: 'Check-In Required',
//                             message: 'Please check in first.');
//                         return;
//                       }
//                       _pickHold();
//                     },
//                     child: _CategoryCard(
//                       icon: _holdToggleVisual
//                           ? Icons.play_circle_outline
//                           : Icons.pause_rounded,
//                       title: _holdToggleVisual ? 'Unhold' : 'Hold',
//                       subtitle:
//                           _holdToggleVisual ? 'Tap to Unhold' : 'Hold Reason',
//                     ),
//                   ),

//                   // NO VISIT
//                   _TapScale(
//                     onTap: () => _guardRequireCheckIn(_pickNoVisit),
//                     child: const _CategoryCard(
//                       icon: Icons.visibility_off_rounded,
//                       title: 'No Visit',
//                       subtitle: 'Select Reason',
//                     ),
//                   ),

//                   // Collect Payment
//                   _TapScale(
//                     onTap: () => _guardRequireCheckIn(() async {
//                       if (!_markInvoicesOn) {
//                         await _showThemedInfo(
//                             parentCtx: context,
//                             title: 'Not Allowed',
//                             message:
//                                 "You don't have rights to view invoices!");
//                         return;
//                       }
//                       _toast('Invoices tapped'); // TODO: Navigate
//                     }),
//                     child: const _CategoryCard(
//                       icon: Icons.payments_rounded,
//                       title: 'Collect Payment',
//                       subtitle: 'Invoices',
//                     ),
//                   ),

//                   // Sale History
//                   _TapScale(
//                     onTap: () => _guardRequireCheckIn(() {
//                       _toast('History tapped'); // TODO: Navigate
//                     }),
//                     child: const _CategoryCard(
//                       icon: Icons.history_rounded,
//                       title: 'Sale History',
//                       subtitle: 'History',
//                     ),
//                   ),
//                 ]),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Shared visual widgets ─────────────────────────────────────────────────────
// class _GlassHeader extends StatelessWidget {
//   const _GlassHeader({required this.child});
//   final Widget child;
//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(18),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(.18),
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }
// }

// class _GlassDialog extends StatelessWidget {
//   final String title;
//   final Widget child;
//   const _GlassDialog({required this.title, required this.child});

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return Dialog(
//       insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//       backgroundColor: Colors.transparent,
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: [kOrange, kOrangeLite],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(18),
//         ),
//         child: Container(
//           margin: const EdgeInsets.all(1.8),
//           decoration: BoxDecoration(
//             color: kCard,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: const [
//               BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10))
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
//                 decoration: const BoxDecoration(
//                   color: kField,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//                 ),
//                 child: Text(title,
//                     textAlign: TextAlign.center,
//                     style: t.titleMedium
//                         ?.copyWith(fontWeight: FontWeight.w800, color: kText)),
//               ),
//               child,
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _Chip extends StatelessWidget {
//   final String label;
//   final IconData icon;
//   final Color color;
//   final Color textColor;
//   final Color borderColor;

//   const _Chip({
//     required this.label,
//     required this.icon,
//     required this.color,
//     required this.textColor,
//     required this.borderColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: borderColor),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 16, color: textColor),
//           const SizedBox(width: 6),
//           Text(label,
//               style: TextStyle(
//                   color: textColor, fontWeight: FontWeight.w700, fontSize: 12)),
//         ],
//       ),
//     );
//   }
// }

// class _CategoryCard extends StatelessWidget {
//   const _CategoryCard({required this.icon, required this.title, this.subtitle});
//   final IconData icon;
//   final String title;
//   final String? subtitle;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return DecoratedBox(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//             colors: [kOrange, kOrangeLite],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight),
//         borderRadius: BorderRadius.all(Radius.circular(16)),
//       ),
//       child: Container(
//         margin: const EdgeInsets.all(1.8),
//         decoration: BoxDecoration(
//           color: kCard,
//           borderRadius: BorderRadius.circular(14.2),
//           boxShadow: const [
//             BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10))
//           ],
//           border: Border.all(color: Color(0xFFEDEFF2)),
//         ),
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Material(
//                 color: kField,
//                 shape: const CircleBorder(),
//                 child: SizedBox(
//                     width: 48,
//                     height: 48,
//                     child: Icon(icon, color: kOrange))),
//             const Spacer(),
//             Text(title,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: t.titleSmall?.copyWith(
//                     color: kText, fontWeight: FontWeight.w700, letterSpacing: .2)),
//             if (subtitle != null) ...[
//               const SizedBox(height: 2),
//               Text(subtitle!,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: t.bodySmall?.copyWith(color: kMuted)),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _TapScale extends StatefulWidget {
//   const _TapScale({super.key, required this.child, required this.onTap});
//   final Widget child;
//   final VoidCallback onTap;

//   @override
//   State<_TapScale> createState() => _TapScaleState();
// }

// class _TapScaleState extends State<_TapScale>
//     with SingleTickerProviderStateMixin {
//   double _scale = 1.0;
//   void _down(TapDownDetails _) => setState(() => _scale = .98);
//   void _up([_]) => setState(() => _scale = 1.0);

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTapDown: _down,
//       onTapCancel: _up,
//       onTapUp: _up,
//       onTap: widget.onTap,
//       child: AnimatedScale(
//           duration: const Duration(milliseconds: 90),
//           scale: _scale,
//           child: widget.child),
//     );
//   }
// }




// === existing imports you already have ===
// import 'package:flutter/material.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:location/location.dart' as loc;
// import 'package:flutter/rendering.dart'; // etc...
/*CURRENT/recent
const kOrange = Color(0xFFFF7A3D);
const kOrangeLite = Color(0xFFFFB07A);
const kText = Color(0xFF0E1631);
const kMuted = Color(0xFF738096);
const kField = Color(0xFFF4F6FA);
const kCard = Colors.white;
const kShadow = Color(0x1A0E1631);

enum VisitLast { none, hold, noVisit }
VisitLast _parseLast(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'hold': return VisitLast.hold;
    case 'no_visit': return VisitLast.noVisit;
    default: return VisitLast.none;
  }
}

class OrderMenuScreen extends StatefulWidget {
  final String shopname, miscid, address;
  final String? segId;
  final String? checkCredit; // "0" or "1"
  final String? orderStatus; // "1" allowed to order

  const OrderMenuScreen({
    super.key,
    required this.shopname,
    required this.miscid,
    required this.address,
    this.segId,
    this.checkCredit,
    this.orderStatus,
  });

  @override
  State<OrderMenuScreen> createState() => _OrderMenuScreenState();
}

class _OrderMenuScreenState extends State<OrderMenuScreen> {
  final box = GetStorage();
  final loc.Location location = loc.Location();

  String checkInText = "Check In";
  bool _hasReasonSelected = false;
  bool _holdToggleVisual = false;

  String lat = "0", lng = "0";

  // ===== persisted per shop =====
  Map<String, dynamic> _loadStatusMap() {
    final raw = box.read('journey_status');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Future<void> _saveStatus({
    required bool checkedIn,
    required VisitLast last,
    bool? holdUi,
  }) async {
    final map = _loadStatusMap();
    map[widget.miscid] = {
      'checkedIn': checkedIn,
      'last': last == VisitLast.hold
          ? 'hold'
          : (last == VisitLast.noVisit ? 'no_visit' : 'none'),
      'holdUI': holdUi ?? _holdToggleVisual,
    };
    await box.write('journey_status', map);
  }

  ({bool checkedIn, VisitLast last, bool holdUi}) _statusForShop() {
    final map = _loadStatusMap();
    final s = map[widget.miscid];
    if (s is Map) {
      return (
        checkedIn: (s['checkedIn'] == true),
        last: _parseLast(s['last'] as String?),
        holdUi: (s['holdUI'] == true),
      );
    }
    return (checkedIn: false, last: VisitLast.none, holdUi: false);
  }

  Map<String, String> _loadReasonMap() {
    final raw = box.read('journey_reasons');
    if (raw is Map) {
      return raw.map<String, String>((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return {};
  }

  Future<void> _saveReason(String reason) async {
    final map = _loadReasonMap();
    map[widget.miscid] = reason;
    await box.write('journey_reasons', map);
  }

  // ===== helpers =====
  String get _orderStatus {
    final s = context.read<GlobalBloc>().state;
    return widget.orderStatus ?? (s.loginModel?.log?.orderStatus ?? "1");
  }

  bool get _markLocationOn {
    final rights = context.read<GlobalBloc>().state.loginModel?.userRights;
    return (rights?.markLocation ?? "0") == "1";
  }

  bool get _markInvoicesOn {
    final rights = context.read<GlobalBloc>().state.loginModel?.userRights;
    return (rights?.markInvoices ?? "0") == "1";
  }

  bool get _isCheckedIn => checkInText == "Check Out";
  bool get _isLockedNoVisit => _statusForShop().last == VisitLast.noVisit;
  bool get _isHoldActive => _statusForShop().last == VisitLast.hold || _holdToggleVisual;
  bool get _allowCheckInAgain => !_isLockedNoVisit;

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _getLocation() async {
    try {
      final hasPerm = await location.hasPermission();
      if (hasPerm == loc.PermissionStatus.denied || hasPerm == loc.PermissionStatus.deniedForever) {
        final req = await location.requestPermission();
        if (req != loc.PermissionStatus.granted) return;
      }
      var en = await location.serviceEnabled();
      if (!en) {
        final ok = await location.requestService();
        if (!ok) return;
      }
      final current = await location.getLocation();
      lat = (current.latitude ?? 0).toString();
      lng = (current.longitude ?? 0).toString();
    } catch (_) {/* ignore */ }
  }

  // ===== NEW: read cart from local storage (per user + per shop) and block NO VISIT if not empty =====
  final GetStorage _local = GetStorage();

  String _cartKey(String? userId, String shopId) =>
      'meezan_cart_${userId ?? "guest"}_${shopId}';

  Map<String, int> _readPendingCart() {
    final login = context.read<GlobalBloc>().state.loginModel;
    final userId = login?.userinfo?.userId;

    final raw = _local.read(_cartKey(userId, widget.miscid));
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final map = <String, int>{};
      decoded.forEach((k, v) {
        if (k is String) map[k] = (v is int) ? v : int.tryParse('$v') ?? 0;
      });
      map.removeWhere((_, q) => q <= 0);
      return map;
    } catch (_) {
      return {};
    }
  }

  bool _hasPendingOrder() => _readPendingCart().isNotEmpty;
  // ===== END NEW =====

  // ===== Dialog styling: shared builders =====
  Future<void> _showThemedInfo({ 
    required BuildContext parentCtx,
    required String title,
    required String message,
    String button = 'OK',
  }) async {
    await showDialog(
      context: parentCtx,
      barrierDismissible: true,
      builder: (dialogCtx) => _GlassDialog(
        title: title,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: Theme.of(parentCtx).textTheme.bodyMedium?.copyWith(color: kText)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(button),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showThemedConfirm({
    required BuildContext parentCtx,
    required String title,
    required String message,
    String yesText = 'Yes',
    String noText = 'No',
    required VoidCallback onYes,
  }) async {
    await showDialog(
      context: parentCtx,
      barrierDismissible: false,
      builder: (dialogCtx) => _GlassDialog(
        title: title,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: Theme.of(parentCtx).textTheme.bodyMedium?.copyWith(color: kText)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kMuted,
                        side: BorderSide(color: kMuted.withOpacity(.35)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: Text(noText),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        onYes();
                      },
                      child: Text(yesText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showThemedReasonPicker({
    required BuildContext parentCtx,
    required String dialogTitle,
    required List<String> options,
  }) async {
    int selectedIndex = -1;
    String? chosen;
    await showDialog(
      context: parentCtx,
      barrierDismissible: true,
      builder: (dialogCtx) {
        final t = Theme.of(parentCtx).textTheme;
        return _GlassDialog(
          title: dialogTitle,
          child: StatefulBuilder(
            builder: (ctx, setSB) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (_, i) => RadioListTile<int>(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                      activeColor: kOrange,
                      title: Text(options[i], style: t.bodyMedium?.copyWith(color: kText)),
                      value: i,
                      groupValue: selectedIndex,
                      onChanged: (v) => setSB(() => selectedIndex = v ?? -1),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kMuted,
                            side: BorderSide(color: kMuted.withOpacity(.35)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: selectedIndex == -1
                              ? null
                              : () {
                                  chosen = options[selectedIndex];
                                  Navigator.of(dialogCtx).pop();
                                },
                          child: const Text("Select Reason"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return chosen;
  }

  List<String> _reasonsOfType(String type) {
    final reasons = context.read<GlobalBloc>().state.loginModel?.reasons ?? const [];
    return reasons
        .where((r) => (r.type ?? "").toUpperCase() == type.toUpperCase())
        .map((r) => r.name ?? "")
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  // ===== Logic =====
  void _guardRequireCheckIn(VoidCallback action) {
    if (_isHoldActive) {
      _showThemedInfo(parentCtx: context, title: 'Unhold Required', message: 'Unhold first to continue.');
      return;
    }
    if (!_isCheckedIn) {
      _showThemedInfo(parentCtx: context, title: 'Check-In Required', message: 'Please check in first.');
      return;
    }
    action();
  }

  @override
  void initState() {
    super.initState();
    final st = _statusForShop();
    final effectiveCheckedIn = st.last == VisitLast.hold ? true : st.checkedIn;
    checkInText = effectiveCheckedIn ? "Check Out" : "Check In";
    _holdToggleVisual = st.holdUi || st.last == VisitLast.hold;
    _hasReasonSelected = !effectiveCheckedIn || st.last != VisitLast.none;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_markLocationOn) await _getLocation();
    });
  }

  Future<void> _pickHold() async {
    final parentCtx = context;

    if (_markLocationOn && (lat == "0" || lng == "0")) {
      await _showThemedInfo(
        parentCtx: parentCtx,
        title: 'Location',
        message: "Can't get location. Please open Google Maps blue dot and try again.",
      );
      return;
    }

    final shopStatusIsHold = _isHoldActive;

    if (!shopStatusIsHold) {
      // pick reason (styled)
      final options = _reasonsOfType("HOLD");
      if (options.isEmpty) {
        await _showThemedInfo(parentCtx: parentCtx, title: 'No Options', message: 'No HOLD reasons available.');
        return;
      }
      final chosen = await _showThemedReasonPicker(
        parentCtx: parentCtx,
        dialogTitle: "Select Hold Reason",
        options: options,
      );
      if (chosen == null) return;

      await _showThemedConfirm(
        parentCtx: parentCtx,
        title: 'Confirm Hold',
        message: 'Place this shop on HOLD for reason "$chosen"?',
        onYes: () async {
          await _getLocation();
          context.read<GlobalBloc>().add(
                CheckinCheckoutEvent(
                  type: '9',
                  userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
                  lat: lat,
                  lng: lng,
                  act_type: "ORDER_HOLD",
                  action: chosen,
                  misc: widget.miscid,
                  dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
                ),
              );

          _holdToggleVisual = true;
          checkInText = "Check Out";
          _hasReasonSelected = true;
          await _saveReason(chosen);
          await _saveStatus(checkedIn: true, last: VisitLast.hold, holdUi: true);
          if (mounted) setState(() {});
          if (mounted) Navigator.of(parentCtx).pop({
            'miscid': widget.miscid,
            'kind': 'hold',
            'reason': chosen,
          });
        },
      );
    } else {
      await _showThemedConfirm(
        parentCtx: parentCtx,
        title: 'Unhold Shop',
        message: 'Remove HOLD and continue?',
        onYes: () async {
          await _getLocation();
          context.read<GlobalBloc>().add(
                CheckinCheckoutEvent(
                  type: '10',
                  userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
                  lat: lat,
                  lng: lng,
                  act_type: "ORDER_HOLD",
                  action: "UNHOLD",
                  misc: widget.miscid,
                  dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
                ),
              );
          _holdToggleVisual = false;
          checkInText = "Check Out"; // still considered checked-in after unhold
          await _saveStatus(checkedIn: true, last: VisitLast.none, holdUi: false);
          if (mounted) setState(() {});
        },
      );
    }
  }

  Future<void> _pickNoVisit() async {
    // NEW: Block if there is an in-progress order (cart not empty for this shop)
    if (_hasPendingOrder()) {
      await _showThemedInfo(
        parentCtx: context,
        title: 'Action Not Allowed',
        message:
            'You have already added items for this shop. Please submit or clear the order before selecting a No Visit reason.',
      );
      return;
    }

    final parentCtx = context;
    final options = _reasonsOfType("NOVISIT");
    if (options.isEmpty) {
      await _showThemedInfo(parentCtx: parentCtx, title: 'No Options', message: 'No NO-VISIT reasons available.');
      return;
    }
    final chosen = await _showThemedReasonPicker(
      parentCtx: parentCtx,
      dialogTitle: "Select No Visit Reason",
      options: options,
    );
    if (chosen == null) return;

    await _showThemedConfirm(
      parentCtx: parentCtx,
      title: 'Confirm No Visit',
      message: 'Confirm NO VISIT for reason "$chosen"?',
      onYes: () async {
        await _getLocation();

        // ORDER reason (type 7)
        context.read<GlobalBloc>().add(CheckinCheckoutEvent(
              type: '7',
              userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
              lat: lat,
              lng: lng,
              act_type: "ORDER",
              action: chosen,
              misc: widget.miscid,
              dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
            ));
        // CHECK OUT (type 6)
        context.read<GlobalBloc>().add(CheckinCheckoutEvent(
              type: '6',
              userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
              lat: lat,
              lng: lng,
              act_type: "SHOP_CHECK",
              action: "OUT",
              misc: widget.miscid,
              dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
            ));

        await _saveReason(chosen);
        await _saveStatus(checkedIn: false, last: VisitLast.noVisit, holdUi: false);
        checkInText = "Check In";
        _hasReasonSelected = true;
        if (mounted) setState(() {});
        if (mounted) Navigator.of(parentCtx).pop({
          'miscid': widget.miscid,
          'kind': 'no_order',
          'reason': chosen,
        });
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (_isCheckedIn && !_hasReasonSelected) {
      await _showThemedInfo(
        parentCtx: context,
        title: 'Action Required',
        message: 'Please select a reason (Hold / No Visit) before leaving.',
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Container(
                    height: 179,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kOrange, kOrangeLite],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 45, 16, 0),
                    child: _GlassHeader(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.20),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.2),
                                ),
                                child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.shopname,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.titleMedium?.copyWith(
                                          color: Colors.white.withOpacity(.97),
                                          fontWeight: FontWeight.w700,
                                        )),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.place_rounded, size: 16, color: Colors.white.withOpacity(.9)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            widget.address,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: t.bodySmall?.copyWith(
                                              color: Colors.white.withOpacity(.95),
                                              height: 1.2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _Chip(
                                label: _isCheckedIn ? "Checked-In" : "Not Checked-In",
                                icon: _isCheckedIn ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: Colors.white.withOpacity(.18),
                                textColor: Colors.white,
                                borderColor: Colors.white.withOpacity(.45),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // GRID
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildListDelegate.fixed([
                  // CHECK-IN / OUT
                  _TapScale(
                    onTap: () async {
                      if (_isHoldActive) {
                        await _showThemedInfo(parentCtx: context, title: 'Unhold Required', message: 'Unhold first to continue.');
                        return;
                      }
                      if (checkInText == "Check In" && !_allowCheckInAgain) {
                        await _showThemedInfo(parentCtx: context, title: 'Not Allowed', message: 'Re-check in is not allowed (No Visit selected earlier).');
                        return;
                      }
                      if (checkInText == "Check Out" && !_hasReasonSelected && _orderStatus == "1") {
                        await _showThemedInfo(parentCtx: context, title: 'Reason Required', message: 'Select a reason (Hold / No Visit) before checking out.');
                        return;
                      }
                      if (_markLocationOn && (lat == "0" || lng == "0")) {
                        await _showThemedInfo(parentCtx: context, title: 'Location', message: "Can't get location. Please open Google Maps blue dot.");
                        return;
                      }
                      await _getLocation();

                      if (checkInText == "Check In") {
                        await _showThemedConfirm(
                          parentCtx: context,
                          title: 'Shop Check-In',
                          message: 'Do you want to Check-In?',
                          onYes: () async {
                            context.read<GlobalBloc>().add(
                                  CheckinCheckoutEvent(
                                    type: '5',
                                    userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
                                    lat: lat,
                                    lng: lng,
                                    act_type: "SHOP_CHECK",
                                    action: "IN",
                                    misc: widget.miscid,
                                    dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
                                  ),
                                );
                            setState(() {
                              checkInText = "Check Out";
                              _hasReasonSelected = false;
                            });
                            final st = _statusForShop();
                            await _saveStatus(checkedIn: true, last: st.last, holdUi: _holdToggleVisual);
                          },
                        );
                      } else {
                        await _showThemedConfirm(
                          parentCtx: context,
                          title: 'Shop Check-Out',
                          message: 'Do you want to Check-Out?',
                          onYes: () async {
                            context.read<GlobalBloc>().add(
                                  CheckinCheckoutEvent(
                                    type: '6',
                                    userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
                                    lat: lat,
                                    lng: lng,
                                    act_type: "SHOP_CHECK",
                                    action: "OUT",
                                    misc: widget.miscid,
                                    dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
                                  ),
                                );
                            setState(() {
                              checkInText = "Check In";
                              _hasReasonSelected = true;
                            });
                            final st = _statusForShop();
                            await _saveStatus(checkedIn: false, last: st.last, holdUi: _holdToggleVisual);
                            if (mounted) Navigator.pop(context);
                          },
                        );
                      }
                    },
                    child: _CategoryCard(
                      icon: Icons.access_time,
                      title: checkInText,
                      subtitle: _isHoldActive ? 'Unhold to enable' : 'Shop ${checkInText == "Check In" ? "Checkin" : "Checkout"}',
                    ),
                  ),

                  // TAKE ORDER
                  _TapScale(
                    onTap: () => _guardRequireCheckIn(() async {
                      if (_orderStatus != "1") {
                        Navigator.push(context, MaterialPageRoute(builder: (_) =>  MeezanTeaCatalog(shopId: widget.miscid)));
                        return;
                      }
                      _toast('Take Order tapped'); // TODO: Navigate
                    }),
                    child: const _CategoryCard(
                      icon: Icons.playlist_add_check_rounded,
                      title: 'Take Order',
                      subtitle: 'Orders',
                    ),
                  ),

                  // HOLD / UNHOLD
                  _TapScale(
                    onTap: () {
                      if (!_isCheckedIn) {
                        _showThemedInfo(parentCtx: context, title: 'Check-In Required', message: 'Please check in first.');
                        return;
                      }
                      _pickHold();
                    },
                    child: _CategoryCard(
                      icon: _holdToggleVisual ? Icons.play_circle_outline : Icons.pause_rounded,
                      title: _holdToggleVisual ? 'Unhold' : 'Hold',
                      subtitle: _holdToggleVisual ? 'Tap to Unhold' : 'Hold Reason',
                    ),
                  ),

                  // NO VISIT
                  _TapScale(
                    onTap: () => _guardRequireCheckIn(_pickNoVisit),
                    child: const _CategoryCard(
                      icon: Icons.visibility_off_rounded,
                      title: 'No Visit',
                      subtitle: 'Select Reason',
                    ),
                  ),

                  // Collect Payment
                  _TapScale(
                    onTap: () => _guardRequireCheckIn(() async {
                      if (!_markInvoicesOn) {
                        await _showThemedInfo(parentCtx: context, title: 'Not Allowed', message: "You don't have rights to view invoices!");
                        return;
                      }
                      _toast('Invoices tapped'); // TODO: Navigate
                    }),
                    child: const _CategoryCard(
                      icon: Icons.payments_rounded,
                      title: 'Collect Payment',
                      subtitle: 'Invoices',
                    ),
                  ),

                  // Sale History
                  _TapScale(
                    onTap: () => _guardRequireCheckIn(() {
                      _toast('History tapped'); // TODO: Navigate
                    }),
                    child: const _CategoryCard(
                      icon: Icons.history_rounded,
                      title: 'Sale History',
                      subtitle: 'History',
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared visual widgets ─────────────────────────────────────────────────────
class _GlassHeader extends StatelessWidget {
  const _GlassHeader({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassDialog extends StatelessWidget {
  final String title;
  final Widget child;
  const _GlassDialog({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kOrange, kOrangeLite],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Container(
          margin: const EdgeInsets.all(1.8),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: const BoxDecoration(
                  color: kField,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Text(title, textAlign: TextAlign.center,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: kText)),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color borderColor;

  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [kOrange, kOrangeLite], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.8),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14.2),
          boxShadow: const [BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10))],
          border: Border.all(color: Color(0xFFEDEFF2)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(color: kField, shape: const CircleBorder(),
                child: SizedBox(width: 48, height: 48, child: Icon(icon, color: kOrange))),
            const Spacer(),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: t.titleSmall?.copyWith(color: kText, fontWeight: FontWeight.w700, letterSpacing: .2)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: kMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _TapScale extends StatefulWidget {
  const _TapScale({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  void _down(TapDownDetails _) => setState(() => _scale = .98);
  void _up([_]) => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down, onTapCancel: _up, onTapUp: _up, onTap: widget.onTap,
      child: AnimatedScale(duration: const Duration(milliseconds: 90), scale: _scale, child: widget.child),
    );
  }
}

*/


/*class OrderMenuScreen extends StatefulWidget {
  final String shopname, miscid, address;
  final String? segId;
  final String? checkCredit; // "0" or "1"
  final String? orderStatus; // "1" allowed to order 

  const OrderMenuScreen({
    super.key,
    required this.shopname,
    required this.miscid,
    required this.address,
    this.segId,
    this.checkCredit,
    this.orderStatus,
  });

  @override
  State<OrderMenuScreen> createState() => _OrderMenuScreenState();
}

class _OrderMenuScreenState extends State<OrderMenuScreen> {
  final box = GetStorage();
  final loc.Location location = loc.Location();

  String checkInText = "Check In";
  bool _hasReasonSelected = false;
  bool _holdToggleVisual = false;

  String lat = "0", lng = "0";

  // ===== persisted per shop =====
  Map<String, dynamic> _loadStatusMap() {
    final raw = box.read('journey_status');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Future<void> _saveStatus({
    required bool checkedIn,
    required VisitLast last,
    bool? holdUi,
  }) async {
    final map = _loadStatusMap();
    map[widget.miscid] = {
      'checkedIn': checkedIn,
      'last': last == VisitLast.hold
          ? 'hold'
          : (last == VisitLast.noVisit ? 'no_visit' : 'none'),
      'holdUI': holdUi ?? _holdToggleVisual,
    };
    await box.write('journey_status', map);
  }

  ({bool checkedIn, VisitLast last, bool holdUi}) _statusForShop() {
    final map = _loadStatusMap();
    final s = map[widget.miscid];
    if (s is Map) {
      return (
        checkedIn: (s['checkedIn'] == true),
        last: _parseLast(s['last'] as String?),
        holdUi: (s['holdUI'] == true),
      );
    }
    return (checkedIn: false, last: VisitLast.none, holdUi: false);
  }

  Map<String, String> _loadReasonMap() {
    final raw = box.read('journey_reasons');
    if (raw is Map) {
      return raw.map<String, String>((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return {};
  }

  Future<void> _saveReason(String reason) async {
    final map = _loadReasonMap();
    map[widget.miscid] = reason;
    await box.write('journey_reasons', map);
  }

  // ===== helpers =====
  String get _orderStatus {
    final s = context.read<GlobalBloc>().state;
    return widget.orderStatus ?? (s.loginModel?.log?.orderStatus ?? "1");
  }

  bool get _markLocationOn {
    final rights = context.read<GlobalBloc>().state.loginModel?.userRights;
    return (rights?.markLocation ?? "0") == "1";
  }

  bool get _markInvoicesOn {
    final rights = context.read<GlobalBloc>().state.loginModel?.userRights;
    return (rights?.markInvoices ?? "0") == "1";
  }

  bool get _isCheckedIn => checkInText == "Check Out";
  bool get _isLockedNoVisit => _statusForShop().last == VisitLast.noVisit;
  bool get _isHoldActive => _statusForShop().last == VisitLast.hold || _holdToggleVisual;
  bool get _allowCheckInAgain => !_isLockedNoVisit;

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _getLocation() async {
    try {
      final hasPerm = await location.hasPermission();
      if (hasPerm == loc.PermissionStatus.denied || hasPerm == loc.PermissionStatus.deniedForever) {
        final req = await location.requestPermission();
        if (req != loc.PermissionStatus.granted) return;
      }
      var en = await location.serviceEnabled();
      if (!en) {
        final ok = await location.requestService();
        if (!ok) return;
      }
      final current = await location.getLocation();
      lat = (current.latitude ?? 0).toString();
      lng = (current.longitude ?? 0).toString();
    } catch (_) {/* ignore */ }
  }

  // ===== Dialog styling: shared builders =====
  Future<void> _showThemedInfo({ 
    required BuildContext parentCtx,
    required String title,
    required String message,
    String button = 'OK',
  }) async {
    await showDialog(
      context: parentCtx,
      barrierDismissible: true,
      builder: (dialogCtx) => _GlassDialog(
        title: title,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: Theme.of(parentCtx).textTheme.bodyMedium?.copyWith(color: kText)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(button),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showThemedConfirm({
    required BuildContext parentCtx,
    required String title,
    required String message,
    String yesText = 'Yes',
    String noText = 'No',
    required VoidCallback onYes,
  }) async {
    await showDialog(
      context: parentCtx,
      barrierDismissible: false,
      builder: (dialogCtx) => _GlassDialog(
        title: title,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: Theme.of(parentCtx).textTheme.bodyMedium?.copyWith(color: kText)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kMuted,
                        side: BorderSide(color: kMuted.withOpacity(.35)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: Text(noText),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        onYes();
                      },
                      child: Text(yesText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showThemedReasonPicker({
    required BuildContext parentCtx,
    required String dialogTitle,
    required List<String> options,
  }) async {
    int selectedIndex = -1;
    String? chosen;
    await showDialog(
      context: parentCtx,
      barrierDismissible: true,
      builder: (dialogCtx) {
        final t = Theme.of(parentCtx).textTheme;
        return _GlassDialog(
          title: dialogTitle,
          child: StatefulBuilder(
            builder: (ctx, setSB) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (_, i) => RadioListTile<int>(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                      activeColor: kOrange,
                      title: Text(options[i], style: t.bodyMedium?.copyWith(color: kText)),
                      value: i,
                      groupValue: selectedIndex,
                      onChanged: (v) => setSB(() => selectedIndex = v ?? -1),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kMuted,
                            side: BorderSide(color: kMuted.withOpacity(.35)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: selectedIndex == -1
                              ? null
                              : () {
                                  chosen = options[selectedIndex];
                                  Navigator.of(dialogCtx).pop();
                                },
                          child: const Text("Select Reason"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return chosen;
  }

  List<String> _reasonsOfType(String type) {
    final reasons = context.read<GlobalBloc>().state.loginModel?.reasons ?? const [];
    return reasons
        .where((r) => (r.type ?? "").toUpperCase() == type.toUpperCase())
        .map((r) => r.name ?? "")
        .where((s) => s.trim().isNotEmpty)
        .toList();

        
  }

  // ===== Logic =====
  void _guardRequireCheckIn(VoidCallback action) {
    if (_isHoldActive) {
      _showThemedInfo(parentCtx: context, title: 'Unhold Required', message: 'Unhold first to continue.');
      return;
    }
    if (!_isCheckedIn) {
      _showThemedInfo(parentCtx: context, title: 'Check-In Required', message: 'Please check in first.');
      return;
    }
    action();
  }

  @override
  void initState() {
    super.initState();
    final st = _statusForShop();
    final effectiveCheckedIn = st.last == VisitLast.hold ? true : st.checkedIn;
    checkInText = effectiveCheckedIn ? "Check Out" : "Check In";
    _holdToggleVisual = st.holdUi || st.last == VisitLast.hold;
    _hasReasonSelected = !effectiveCheckedIn || st.last != VisitLast.none;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_markLocationOn) await _getLocation();
    });
  }

  Future<void> _pickHold() async {
    final parentCtx = context;

    if (_markLocationOn && (lat == "0" || lng == "0")) {
      await _showThemedInfo(
        parentCtx: parentCtx,
        title: 'Location',
        message: "Can't get location. Please open Google Maps blue dot and try again.",
      );
      return;
    }

    final shopStatusIsHold = _isHoldActive;

    if (!shopStatusIsHold) {
      // pick reason (styled)
      final options = _reasonsOfType("HOLD");
      if (options.isEmpty) {
        await _showThemedInfo(parentCtx: parentCtx, title: 'No Options', message: 'No HOLD reasons available.');
        return;
      }
      final chosen = await _showThemedReasonPicker(
        parentCtx: parentCtx,
        dialogTitle: "Select Hold Reason",
        options: options,
      );
      if (chosen == null) return;

      await _showThemedConfirm(
        parentCtx: parentCtx,
        title: 'Confirm Hold',
        message: 'Place this shop on HOLD for reason "$chosen"?',
        onYes: () async {
          await _getLocation();
          context.read<GlobalBloc>().add(
                CheckinCheckoutEvent(
                  type: '9',
                  userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
                  lat: lat,
                  lng: lng,
                  act_type: "ORDER_HOLD",
                  action: chosen,
                  misc: widget.miscid,
                  dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
                ),
              );

          _holdToggleVisual = true;
          checkInText = "Check Out";
          _hasReasonSelected = true;
          await _saveReason(chosen);
          await _saveStatus(checkedIn: true, last: VisitLast.hold, holdUi: true);
          if (mounted) setState(() {});
          if (mounted) Navigator.of(parentCtx).pop({
            'miscid': widget.miscid,
            'kind': 'hold',
            'reason': chosen,
          });
        },
      );
    } else {
      await _showThemedConfirm(
        parentCtx: parentCtx,
        title: 'Unhold Shop',
        message: 'Remove HOLD and continue?',
        onYes: () async {
          await _getLocation();
          context.read<GlobalBloc>().add(
                CheckinCheckoutEvent(
                  type: '10',
                  userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
                  lat: lat,
                  lng: lng,
                  act_type: "ORDER_HOLD",
                  action: "UNHOLD",
                  misc: widget.miscid,
                  dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
                ),
              );
          _holdToggleVisual = false;
          checkInText = "Check Out"; // still considered checked-in after unhold
          await _saveStatus(checkedIn: true, last: VisitLast.none, holdUi: false);
          if (mounted) setState(() {});
        },
      );
    }
  }

  Future<void> _pickNoVisit() async {
    final parentCtx = context;
    final options = _reasonsOfType("NOVISIT");
    if (options.isEmpty) {
      await _showThemedInfo(parentCtx: parentCtx, title: 'No Options', message: 'No NO-VISIT reasons available.');
      return;
    }
    final chosen = await _showThemedReasonPicker(
      parentCtx: parentCtx,
      dialogTitle: "Select No Visit Reason",
      options: options,
    );
    if (chosen == null) return;

    await _showThemedConfirm(
      parentCtx: parentCtx,
      title: 'Confirm No Visit',
      message: 'Confirm NO VISIT for reason "$chosen"?',
      onYes: () async {
        await _getLocation();

        print('CHOOSEN REASON $chosen');

        // ORDER reason (type 7)
        context.read<GlobalBloc>().add(CheckinCheckoutEvent(
              type: '7',
              userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
              lat: lat,
              lng: lng,
              act_type: "ORDER",
              action: chosen,
              misc: widget.miscid,
              dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
            ));
        // CHECK OUT (type 6)
        context.read<GlobalBloc>().add(CheckinCheckoutEvent(
              type: '6',
              userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
              lat: lat,
              lng: lng,
              act_type: "SHOP_CHECK",
              action: "OUT",
              misc: widget.miscid,
              dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
            ));

        await _saveReason(chosen);
        await _saveStatus(checkedIn: false, last: VisitLast.noVisit, holdUi: false);
        checkInText = "Check In";
        _hasReasonSelected = true;
        if (mounted) setState(() {});
        if (mounted) Navigator.of(parentCtx).pop({
          'miscid': widget.miscid,
          'kind': 'no_order',
          'reason': chosen,
        });
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (_isCheckedIn && !_hasReasonSelected) {
      await _showThemedInfo(
        parentCtx: context,
        title: 'Action Required',
        message: 'Please select a reason (Hold / No Visit) before leaving.',
      );
      return false;
    }
    return true;
    }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Container(
                    height: 179,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kOrange, kOrangeLite],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 45, 16, 0),
                    child: _GlassHeader(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.20),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.2),
                                ),
                                child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.shopname,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.titleMedium?.copyWith(
                                          color: Colors.white.withOpacity(.97),
                                          fontWeight: FontWeight.w700,
                                        )),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.place_rounded, size: 16, color: Colors.white.withOpacity(.9)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            widget.address,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: t.bodySmall?.copyWith(
                                              color: Colors.white.withOpacity(.95),
                                              height: 1.2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _Chip(
                                label: _isCheckedIn ? "Checked-In" : "Not Checked-In",
                                icon: _isCheckedIn ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: Colors.white.withOpacity(.18),
                                textColor: Colors.white,
                                borderColor: Colors.white.withOpacity(.45),
                              ),
                              // const SizedBox(width: 8),
                              // _Chip(
                              //   label: "Shop ID: ${widget.miscid}",
                              //   icon: Icons.confirmation_number_outlined,
                              //   color: Colors.white.withOpacity(.14),
                              //   textColor: Colors.white,
                              //   borderColor: Colors.white.withOpacity(.45),
                              // ),
                              // const Spacer(),
                              // IconButton(
                              //   onPressed: () async {
                              //     if (_isCheckedIn && !_hasReasonSelected) {
                              //       await _showThemedInfo(
                              //         parentCtx: context,
                              //         title: 'Action Required',
                              //         message: 'Please perform an action (Hold / No Visit) first.',
                              //       );
                              //       return;
                              //     }
                              //     if (mounted) Navigator.pop(context);
                              //   },
                              //   icon: const Icon(Icons.close, color: Colors.white),
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // GRID
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildListDelegate.fixed([
                  // CHECK-IN / OUT
                  _TapScale(
                    onTap: () async {
                      if (_isHoldActive) {
                        await _showThemedInfo(parentCtx: context, title: 'Unhold Required', message: 'Unhold first to continue.');
                        return;
                      }
                      if (checkInText == "Check In" && !_allowCheckInAgain) {
                        await _showThemedInfo(parentCtx: context, title: 'Not Allowed', message: 'Re-check in is not allowed (No Visit selected earlier).');
                        return;
                      }
                      if (checkInText == "Check Out" && !_hasReasonSelected && _orderStatus == "1") {
                        await _showThemedInfo(parentCtx: context, title: 'Reason Required', message: 'Select a reason (Hold / No Visit) before checking out.');
                        return;
                      }
                      if (_markLocationOn && (lat == "0" || lng == "0")) {
                        await _showThemedInfo(parentCtx: context, title: 'Location', message: "Can't get location. Please open Google Maps blue dot.");
                        return;
                      }
                      await _getLocation();

                      if (checkInText == "Check In") {
                        await _showThemedConfirm(
                          parentCtx: context,
                          title: 'Shop Check-In',
                          message: 'Do you want to Check-In?',
                          onYes: () async {
                            print("user id${context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString()}");
                                                        print("LAT${lat}");
                            print("LNG ${lng}");
                            print("misc id${widget.miscid}");
                            print("Disc id${context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString()}");

                            context.read<GlobalBloc>().add(
                                  CheckinCheckoutEvent(
                                    type: '5',
                                    userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
                                    lat: lat,
                                    lng: lng,
                                    act_type: "SHOP_CHECK",
                                    action: "IN",
                                    misc: widget.miscid,
                                    dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
                                  ),
                                );
                            setState(() {
                              checkInText = "Check Out";
                              _hasReasonSelected = false;
                            });
                            final st = _statusForShop();
                            await _saveStatus(checkedIn: true, last: st.last, holdUi: _holdToggleVisual);
                          },
                        );
                      } else {
                        await _showThemedConfirm(
                          parentCtx: context,
                          title: 'Shop Check-Out',
                          message: 'Do you want to Check-Out?',
                          onYes: () async {
                            context.read<GlobalBloc>().add(
                                  CheckinCheckoutEvent(
                                    type: '6',
                                    userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
                                    lat: lat,
                                    lng: lng,
                                    act_type: "SHOP_CHECK",
                                    action: "OUT",
                                    misc: widget.miscid,
                                    dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
                                  ),
                                );
                            setState(() {
                              checkInText = "Check In";
                              _hasReasonSelected = true;
                            });
                            final st = _statusForShop();
                            await _saveStatus(checkedIn: false, last: st.last, holdUi: _holdToggleVisual);
                            if (mounted) Navigator.pop(context);
                          },
                        );
                      }
                    },
                    child: _CategoryCard(
                      icon: Icons.access_time,
                      title: checkInText,
                      subtitle: _isHoldActive ? 'Unhold to enable' : 'Shop ${checkInText == "Check In" ? "Checkin" : "Checkout"}',
                    ),
                  ),

                  // TAKE ORDER
                  _TapScale(
                    onTap: () => _guardRequireCheckIn(() async {
                      if (_orderStatus != "1") {
                        Navigator.push(context, MaterialPageRoute(builder: (_) =>  MeezanTeaCatalog(shopId: widget.miscid)));
                     //   await _showThemedInfo(parentCtx: context, title: 'Not Allowed', message: 'You are not allowed to take orders.');
                        return;
                      }
                      _toast('Take Order tapped'); // TODO: Navigate
                    }),
                    child: const _CategoryCard(
                      icon: Icons.playlist_add_check_rounded,
                      title: 'Take Order',
                      subtitle: 'Orders',
                    ),
                  ),

                  // HOLD / UNHOLD
                  _TapScale(
                    onTap: () {
                      if (!_isCheckedIn) {
                        _showThemedInfo(parentCtx: context, title: 'Check-In Required', message: 'Please check in first.');
                        return;
                      }
                      _pickHold();
                    },
                    child: _CategoryCard(
                      icon: _holdToggleVisual ? Icons.play_circle_outline : Icons.pause_rounded,
                      title: _holdToggleVisual ? 'Unhold' : 'Hold',
                      subtitle: _holdToggleVisual ? 'Tap to Unhold' : 'Hold Reason',
                    ),
                  ),

                  // NO VISIT
                  _TapScale(
                    onTap: () => _guardRequireCheckIn(_pickNoVisit),
                    child: const _CategoryCard(
                      icon: Icons.visibility_off_rounded,
                      title: 'No Visit',
                      subtitle: 'Select Reason',
                    ),
                  ),

                  // Collect Payment
                  _TapScale(
                    onTap: () => _guardRequireCheckIn(() async {
                      if (!_markInvoicesOn) {
                        await _showThemedInfo(parentCtx: context, title: 'Not Allowed', message: "You don't have rights to view invoices!");
                        return;
                      }
                      _toast('Invoices tapped'); // TODO: Navigate
                    }),
                    child: const _CategoryCard(
                      icon: Icons.payments_rounded,
                      title: 'Collect Payment',
                      subtitle: 'Invoices',
                    ),
                  ),

                  // Sale History
                  _TapScale(
                    onTap: () => _guardRequireCheckIn(() {
                      _toast('History tapped'); // TODO: Navigate
                    }),
                    child: const _CategoryCard(
                      icon: Icons.history_rounded,
                      title: 'Sale History',
                      subtitle: 'History',
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared visual widgets ─────────────────────────────────────────────────────
class _GlassHeader extends StatelessWidget {
  const _GlassHeader({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassDialog extends StatelessWidget {
  final String title;
  final Widget child;
  const _GlassDialog({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kOrange, kOrangeLite],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Container(
          margin: const EdgeInsets.all(1.8),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: const BoxDecoration(
                  color: kField,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Text(title, textAlign: TextAlign.center,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: kText)),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color borderColor;

  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [kOrange, kOrangeLite], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.8),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14.2),
          boxShadow: const [BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10))],
          border: Border.all(color: Color(0xFFEDEFF2)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(color: kField, shape: const CircleBorder(),
                child: SizedBox(width: 48, height: 48, child: Icon(icon, color: kOrange))),
            const Spacer(),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: t.titleSmall?.copyWith(color: kText, fontWeight: FontWeight.w700, letterSpacing: .2)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: kMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _TapScale extends StatefulWidget {
  const _TapScale({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  void _down(TapDownDetails _) => setState(() => _scale = .98);
  void _up([_]) => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down, onTapCancel: _up, onTapUp: _up, onTap: widget.onTap,
      child: AnimatedScale(duration: const Duration(milliseconds: 90), scale: _scale, child: widget.child),
    );
  }
}*/



// const kOrange = Color(0xFFFF7A3D);
// const kOrangeLite = Color(0xFFFFB07A);
// const kText = Color(0xFF0E1631);
// const kMuted = Color(0xFF738096);
// const kField = Color(0xFFF4F6FA);
// const kCard = Colors.white;
// const kShadow = Color(0x1A0E1631);

// enum VisitLast { none, hold, noVisit }

// VisitLast _parseLast(String? s) {
//   switch ((s ?? '').toLowerCase()) {
//     case 'hold':
//       return VisitLast.hold;
//     case 'no_visit':
//       return VisitLast.noVisit;
//     default:
//       return VisitLast.none;
//   }
// }

// class OrderMenuScreen extends StatefulWidget {
//   final String shopname, miscid, address;
//   final String? segId;
//   final String? checkCredit; // "0" or "1"
//   final String? orderStatus; // "1" allowed to order

//   const OrderMenuScreen({
//     super.key,
//     required this.shopname,
//     required this.miscid,
//     required this.address,
//     this.segId,
//     this.checkCredit,
//     this.orderStatus,
//   });

//   @override
//   State<OrderMenuScreen> createState() => _OrderMenuScreenState();
// }

// class _OrderMenuScreenState extends State<OrderMenuScreen> {
//   final box = GetStorage();
//   final loc.Location location = loc.Location();

//   String checkInText = "Check In"; // toggles to "Check Out"
//   bool _hasReasonSelected = false;  // blocks leaving if checked-in & no reason
//   bool _holdToggleVisual = false;   // UI shows Hold/Unhold

//   String lat = "0", lng = "0";
//   bool sendActionWasSuccess = false;

//   Map<String, dynamic> _loadStatusMap() {
//     final raw = box.read('journey_status');
//     if (raw is Map) return Map<String, dynamic>.from(raw);
//     return {};
//   }

//   Future<void> _saveStatus({
//     required bool checkedIn,
//     required VisitLast last,
//     bool? holdUi,
//   }) async {
//     final map = _loadStatusMap();
//     map[widget.miscid] = {
//       'checkedIn': checkedIn,
//       'last': last == VisitLast.hold
//           ? 'hold'
//           : (last == VisitLast.noVisit ? 'no_visit' : 'none'),
//       'holdUI': holdUi ?? _holdToggleVisual,
//     };
//     await box.write('journey_status', map);
//   }

//   ({bool checkedIn, VisitLast last, bool holdUi}) _statusForShop() {
//     final map = _loadStatusMap();
//     final s = map[widget.miscid];
//     if (s is Map) {
//       return (
//         checkedIn: (s['checkedIn'] == true),
//         last: _parseLast(s['last'] as String?),
//         holdUi: (s['holdUI'] == true),
//       );
//     }
//     return (checkedIn: false, last: VisitLast.none, holdUi: false);
//   }

//   Map<String, String> _loadReasonMap() {
//     final raw = box.read('journey_reasons');
//     if (raw is Map) {
//       return raw.map<String, String>(
//           (k, v) => MapEntry(k.toString(), v.toString()));
//     }
//     return {};
//   }

//   Future<void> _saveReason(String reason) async {
//     final map = _loadReasonMap();
//     map[widget.miscid] = reason;
//     await box.write('journey_reasons', map);
//   }

//   String get _orderStatus {
//     final s = context.read<GlobalBloc>().state;
//     return widget.orderStatus ?? (s.loginModel?.log?.orderStatus ?? "1");
//   }

//   bool get _markLocationOn {
//     final rights = context.read<GlobalBloc>().state.loginModel?.userRights;
//     return (rights?.markLocation ?? "0") == "1";
//   }

//   bool get _markInvoicesOn {
//     final rights = context.read<GlobalBloc>().state.loginModel?.userRights;
//     return (rights?.markInvoices ?? "0") == "1";
//   }

//   bool get _isCheckedIn => checkInText == "Check Out";
//   bool get _isLockedNoVisit => _statusForShop().last == VisitLast.noVisit;
//   bool get _isHoldActive =>
//       _statusForShop().last == VisitLast.hold || _holdToggleVisual;
//   bool get _allowCheckInAgain => !_isLockedNoVisit;

//   void _toast(String msg) =>
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

//   List<String> _reasonsOfType(String type) {
//     final reasons =
//         context.read<GlobalBloc>().state.loginModel?.reasons ?? const [];
//     return reasons
//         .where((r) => (r.type ?? "").toUpperCase() == type.toUpperCase())
//         .map((r) => r.name ?? "")
//         .where((s) => s.trim().isNotEmpty)
//         .toList();
//   }

//   void _guardRequireCheckIn(VoidCallback action) {
//     if (_isHoldActive) {
//       _toast('Unhold first to continue.');
//       return;
//     }
//     if (!_isCheckedIn) {
//       _toast('Please check in first.');
//       return;
//     }
//     action();
//   }

//   Future<void> _getLocation() async {
//     try {
//       final hasPerm = await location.hasPermission();
//       if (hasPerm == loc.PermissionStatus.denied ||
//           hasPerm == loc.PermissionStatus.deniedForever) {
//         final req = await location.requestPermission();
//         if (req != loc.PermissionStatus.granted) return;
//       }
//       var en = await location.serviceEnabled();
//       if (!en) {
//         final ok = await location.requestService();
//         if (!ok) return;
//       }
//       final current = await location.getLocation();
//       lat = (current.latitude ?? 0).toString();
//       lng = (current.longitude ?? 0).toString();
//     } catch (_) {/* ignore */}
//   }

//   @override
//   void initState() {
//     super.initState();
//     final st = _statusForShop();

//     // If last action was HOLD, we keep the user checked-in across sessions.
//     final effectiveCheckedIn =
//         st.last == VisitLast.hold ? true : st.checkedIn;

//     checkInText = effectiveCheckedIn ? "Check Out" : "Check In";
//     _holdToggleVisual = st.holdUi || st.last == VisitLast.hold;

//     // If we are checked-in and already chose a reason (Hold / No Visit), allow leaving.
//     _hasReasonSelected = !effectiveCheckedIn || st.last != VisitLast.none;

//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       if (_markLocationOn) await _getLocation();
//     });
//   }

//   // ===== Shared confirmation dialog (used for Check-In/Out, Hold, No Visit) =====
//   Future<void> _confirm({
//     required String title,
//     required String message,
//     required VoidCallback onYes,
//   }) async {
//     final name = context.read<GlobalBloc>().state.loginModel?.userinfo?.userName ?? '';
//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => AlertDialog(
//         title: Text('Hi, $name'),
//         content: Text(message),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
//           TextButton(onPressed: () { Navigator.pop(context); onYes(); }, child: const Text('Yes')),
//         ],
//       ),
//     );
//   }

//   // ===== Reason picker =====
//   Future<void> _pickReason({
//     required String dialogTitle,
//     required String reasonType, // "HOLD" | "NOVISIT"
//     required Future<void> Function(String chosen) onChosenAndConfirmed,
//     bool autoPopBackToJourney = true,
//   }) async {
//     final options = _reasonsOfType(reasonType);
//     if (options.isEmpty) {
//       _toast('No $reasonType reasons available.');
//       return;
//     }

//     int selectedIndex = -1;
//     String? chosen;

//     await showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (context) {
//         final t = Theme.of(context).textTheme;
//         return Dialog(
//           insetPadding:
//               const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//           backgroundColor: Colors.transparent,
//           child: Container(
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [kOrange, kOrangeLite],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(18),
//             ),
//             child: Container(
//               margin: const EdgeInsets.all(1.8),
//               decoration: BoxDecoration(
//                 color: kCard,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: const [
//                   BoxShadow(
//                       color: kShadow, blurRadius: 16, offset: Offset(0, 10))
//                 ],
//               ),
//               child: StatefulBuilder(
//                 builder: (context, setSB) {
//                   return Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         width: double.infinity,
//                         padding:
//                             const EdgeInsets.fromLTRB(16, 14, 16, 12),
//                         decoration: const BoxDecoration(
//                           color: kField,
//                           borderRadius: BorderRadius.vertical(
//                               top: Radius.circular(16)),
//                         ),
//                         child: Text(dialogTitle,
//                             textAlign: TextAlign.center,
//                             style: t.titleMedium?.copyWith(
//                                 fontWeight: FontWeight.w800, color: kText)),
//                       ),
//                       Flexible(
//                         child: ListView.separated(
//                           shrinkWrap: true,
//                           padding:
//                               const EdgeInsets.fromLTRB(12, 10, 12, 10),
//                           itemCount: options.length,
//                           separatorBuilder: (_, __) =>
//                               const SizedBox(height: 2),
//                           itemBuilder: (_, i) => RadioListTile<int>(
//                             dense: true,
//                             contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 6),
//                             visualDensity: VisualDensity.compact,
//                             activeColor: kOrange,
//                             title: Text(options[i],
//                                 style: t.bodyMedium
//                                     ?.copyWith(color: kText)),
//                             value: i,
//                             groupValue: selectedIndex,
//                             onChanged: (v) =>
//                                 setSB(() => selectedIndex = v ?? -1),
//                           ),
//                         ),
//                       ),
//                       Padding(
//                         padding:
//                             const EdgeInsets.fromLTRB(12, 0, 12, 12),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: OutlinedButton(
//                                 style: OutlinedButton.styleFrom(
//                                   foregroundColor: kMuted,
//                                   side: BorderSide(
//                                       color: kMuted.withOpacity(.35)),
//                                   shape: RoundedRectangleBorder(
//                                       borderRadius:
//                                           BorderRadius.circular(12)),
//                                 ),
//                                 onPressed: () =>
//                                     Navigator.of(context).pop(),
//                                 child: const Text("Cancel"),
//                               ),
//                             ),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: ElevatedButton(
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: kOrange,
//                                   foregroundColor: Colors.white,
//                                   elevation: 0,
//                                   shape: RoundedRectangleBorder(
//                                       borderRadius:
//                                           BorderRadius.circular(12)),
//                                 ),
//                                 onPressed: selectedIndex == -1
//                                     ? null
//                                     : () async {
//                                         chosen = options[selectedIndex];
//                                         Navigator.of(context).pop();
//                                         if (chosen == null) return;

//                                         // NEW: confirmation before sending
//                                         await _confirm(
//                                           title: dialogTitle,
//                                           message: reasonType.toUpperCase() ==
//                                                   'HOLD'
//                                               ? 'Confirm placing this shop on HOLD for reason "${chosen!}"?'
//                                               : 'Confirm NO VISIT for reason "${chosen!}"?',
//                                           onYes: () async {
//                                             await onChosenAndConfirmed(
//                                                 chosen!);
//                                             await _saveReason(chosen!);
//                                             _hasReasonSelected = true;

//                                             if (mounted &&
//                                                 autoPopBackToJourney) {
//                                               Navigator.of(context).pop({
//                                                 'miscid': widget.miscid,
//                                                 'kind': reasonType
//                                                             .toLowerCase() ==
//                                                         'hold'
//                                                     ? 'hold'
//                                                     : 'no_order',
//                                                 'reason': chosen!,
//                                               });
//                                             }
//                                           },
//                                         );
//                                       },
//                                 child: const Text("Select Reason"),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // ===== HOLD / UNHOLD =====
//   Future<void> _pickHold() async {
//     if (_markLocationOn && (lat == "0" || lng == "0")) {
//       await showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text('Location'),
//           content: const Text(
//               "Can't get location. Please open Google Maps blue dot and try again."),
//           actions: [
//             TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('OK')),
//           ],
//         ),
//       );
//       return;
//     }

//     final st = _statusForShop();
//     final shopStatusIsHold = _isHoldActive;

//     if (!shopStatusIsHold) {
//       // choose HOLD reason -> confirm -> send type 9
//       await _pickReason(
//         dialogTitle: "Select Hold Reason",
//         reasonType: "HOLD",
//         onChosenAndConfirmed: (chosen) async {
//           await _getLocation();
//           context.read<GlobalBloc>().add(
//                 CheckinCheckoutEvent(
//                   type: '9',
//                   userId: context
//                       .read<GlobalBloc>()
//                       .state
//                       .loginModel!
//                       .userinfo!
//                       .userId
//                       .toString(),
//                   lat: lat,
//                   lng: lng,
//                   act_type: "ORDER_HOLD",
//                   action: chosen,
//                   misc: widget.miscid,
//                   dist_id: context
//                       .read<GlobalBloc>()
//                       .state
//                       .loginModel!
//                       .userinfo!
//                       .disid
//                       .toString(),
//                 ),
//               );

//           // NEW: keep user considered checked-in across sessions during HOLD
//           _holdToggleVisual = true;
//           checkInText = "Check Out";
//           _hasReasonSelected = true; // can leave screen
//           await _saveStatus(
//             checkedIn: true,
//             last: VisitLast.hold,
//             holdUi: true,
//           );
//           setState(() {});
//         },
//       );
//     } else {
//       // UNHOLD (confirm, then type 10)
//       await _confirm(
//         title: 'Unhold Shop',
//         message: 'Remove HOLD and continue?',
//         onYes: () async {
//           await _getLocation();
//           context.read<GlobalBloc>().add(
//                 CheckinCheckoutEvent(
//                   type: '10',
//                   userId: context
//                       .read<GlobalBloc>()
//                       .state
//                       .loginModel!
//                       .userinfo!
//                       .userId
//                       .toString(),
//                   lat: lat,
//                   lng: lng,
//                   act_type: "ORDER_HOLD",
//                   action: "UNHOLD",
//                   misc: widget.miscid,
//                   dist_id: context
//                       .read<GlobalBloc>()
//                       .state
//                       .loginModel!
//                       .userinfo!
//                       .disid
//                       .toString(),
//                 ),
//               );
//           _holdToggleVisual = false;

//           // After unhold: user still doesn't need to check-in again; keep as checked-in.
//           checkInText = "Check Out";
//           await _saveStatus(
//             checkedIn: true,
//             last: VisitLast.none,
//             holdUi: false,
//           );
//           setState(() {});
//         },
//       );
//     }
//   }

//   // ===== NO VISIT =====
//   Future<void> _pickNoVisit() async {
//     await _pickReason(
//       dialogTitle: "Select No Visit Reason",
//       reasonType: "NOVISIT",
//       onChosenAndConfirmed: (chosen) async {
//         await _getLocation();

//         // confirm already done in _pickReason; proceed:
//         // 1) ORDER reason type 7
//         context.read<GlobalBloc>().add(CheckinCheckoutEvent(
//               type: '7',
//               userId: context
//                   .read<GlobalBloc>()
//                   .state
//                   .loginModel!
//                   .userinfo!
//                   .userId
//                   .toString(),
//               lat: lat,
//               lng: lng,
//               act_type: "ORDER",
//               action: chosen,
//               misc: widget.miscid,
//               dist_id: context
//                   .read<GlobalBloc>()
//                   .state
//                   .loginModel!
//                   .userinfo!
//                   .disid
//                   .toString(),
//             ));

//         // 2) CHECK OUT type 6
//         context.read<GlobalBloc>().add(CheckinCheckoutEvent(
//               type: '6',
//               userId: context
//                   .read<GlobalBloc>()
//                   .state
//                   .loginModel!
//                   .userinfo!
//                   .userId
//                   .toString(),
//               lat: lat,
//               lng: lng,
//               act_type: "SHOP_CHECK",
//               action: "OUT",
//               misc: widget.miscid,
//               dist_id: context
//                   .read<GlobalBloc>()
//                   .state
//                   .loginModel!
//                   .userinfo!
//                   .disid
//                   .toString(),
//             ));

//         // Lock re-checkin for this shop
//         await _saveStatus(checkedIn: false, last: VisitLast.noVisit, holdUi: false);
//         checkInText = "Check In";
//         _hasReasonSelected = true;
//         setState(() {});
//       },
//     );
//   }

//   Future<bool> _onWillPop() async {
//     // If currently checked-in & no reason yet, block leaving
//     if (_isCheckedIn && !_hasReasonSelected) {
//       _toast('Please select a reason (Hold / No Visit) before leaving.');
//       return false;
//     }
//     return true;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: CustomScrollView(
//           physics: const BouncingScrollPhysics(),
//           slivers: [
//             SliverToBoxAdapter(
//               child: Stack(
//                 children: [
//                   Container(
//                     height: 179,
//                     decoration: const BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [kOrange, kOrangeLite],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 45, 16, 0),
//                     child: _GlassHeader(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Container(
//                                 width: 46,
//                                 height: 46,
//                                 decoration: BoxDecoration(
//                                   color: Colors.white.withOpacity(.20),
//                                   shape: BoxShape.circle,
//                                   border: Border.all(color: Colors.white, width: 1.2),
//                                 ),
//                                 child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(widget.shopname,
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                         style: t.titleMedium?.copyWith(
//                                           color: Colors.white.withOpacity(.97),
//                                           fontWeight: FontWeight.w700,
//                                         )),
//                                     const SizedBox(height: 4),
//                                     Row(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Icon(Icons.place_rounded, size: 16, color: Colors.white.withOpacity(.9)),
//                                         const SizedBox(width: 4),
//                                         Expanded(
//                                           child: Text(
//                                             widget.address,
//                                             maxLines: 2,
//                                             overflow: TextOverflow.ellipsis,
//                                             style: t.bodySmall?.copyWith(
//                                               color: Colors.white.withOpacity(.95),
//                                               height: 1.2,
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 10),
//                           Row(
//                             children: [
//                               _Chip(
//                                 label: _isCheckedIn ? "Checked-In" : "Not Checked-In",
//                                 icon: _isCheckedIn ? Icons.check_circle : Icons.radio_button_unchecked,
//                                 color: Colors.white.withOpacity(.18),
//                                 textColor: Colors.white,
//                                 borderColor: Colors.white.withOpacity(.45),
//                               ),
//                               const SizedBox(width: 8),
//                               _Chip(
//                                 label: "Shop ID: ${widget.miscid}",
//                                 icon: Icons.confirmation_number_outlined,
//                                 color: Colors.white.withOpacity(.14),
//                                 textColor: Colors.white,
//                                 borderColor: Colors.white.withOpacity(.45),
//                               ),
//                               const Spacer(),
//                               IconButton(
//                                 onPressed: () async {
//                                   if (_isCheckedIn && !_hasReasonSelected) {
//                                     _toast('Please perform an action (Hold / No Visit) first.');
//                                     return;
//                                   }
//                                   if (mounted) Navigator.pop(context);
//                                 },
//                                 icon: const Icon(Icons.close, color: Colors.white),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // GRID
//             SliverPadding(
//               padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
//               sliver: SliverGrid(
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 2,
//                   crossAxisSpacing: 14,
//                   mainAxisSpacing: 14,
//                   childAspectRatio: 1.05,
//                 ),
//                 delegate: SliverChildListDelegate.fixed([
//                   // CHECK-IN / OUT
//                   _TapScale(
//                     onTap: () async {
//                       final st = _statusForShop();

//                       if (_isHoldActive) {
//                         _toast('Unhold first to continue.');
//                         return;
//                       }

//                       if (checkInText == "Check In" && !_allowCheckInAgain) {
//                         _toast('Re-check in not allowed for this shop (No Visit selected earlier).');
//                         return;
//                       }

//                       if (checkInText == "Check Out" && !_hasReasonSelected && _orderStatus == "1") {
//                         _toast('Select a reason (Hold / No Visit) before checking out.');
//                         return;
//                       }

//                       if (_markLocationOn && (lat == "0" || lng == "0")) {
//                         _toast("Can't get location. Please open Google Maps blue dot.");
//                         return;
//                       }
//                       await _getLocation();

//                       if (checkInText == "Check In") {
//                         await _confirm(
//                           title: 'Shop Check-In',
//                           message: 'Do you want to Check-In?',
//                           onYes: () async {
//                             context.read<GlobalBloc>().add(
//                                   CheckinCheckoutEvent(
//                                     type: '5',
//                                     userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
//                                     lat: lat,
//                                     lng: lng,
//                                     act_type: "SHOP_CHECK",
//                                     action: "IN",
//                                     misc: widget.miscid,
//                                     dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
//                                   ),
//                                 );
//                             setState(() {
//                               checkInText = "Check Out";
//                               _hasReasonSelected = false;
//                             });
//                             await _saveStatus(checkedIn: true, last: st.last, holdUi: _holdToggleVisual);
//                           },
//                         );
//                       } else {
//                         await _confirm(
//                           title: 'Shop Check-Out',
//                           message: 'Do you want to Check-Out?',
//                           onYes: () async {
//                             context.read<GlobalBloc>().add(
//                                   CheckinCheckoutEvent(
//                                     type: '6',
//                                     userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
//                                     lat: lat,
//                                     lng: lng,
//                                     act_type: "SHOP_CHECK",
//                                     action: "OUT",
//                                     misc: widget.miscid,
//                                     dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
//                                   ),
//                                 );
//                             setState(() {
//                               checkInText = "Check In";
//                               _hasReasonSelected = true;
//                             });
//                             await _saveStatus(checkedIn: false, last: st.last, holdUi: _holdToggleVisual);
//                             if (mounted) Navigator.pop(context);
//                           },
//                         );
//                       }
//                     },
//                     child: _CategoryCard(
//                       icon: Icons.access_time,
//                       title: checkInText,
//                       subtitle: _isHoldActive ? 'Unhold to enable' : 'Shop ${checkInText == "Check In" ? "Checkin" : "Checkout"}',
//                     ),
//                   ),

//                   // TAKE ORDER
//                   _TapScale(
//                     onTap: () => _guardRequireCheckIn(() async {
//                       if (_orderStatus != "1") {
//                         _toast("Not allowed to take order.");
//                         return;
//                       }
//                       _toast('Take Order tapped');
//                       // TODO: Navigate to your TakeOrder screen
//                     }),
//                     child: const _CategoryCard(
//                       icon: Icons.playlist_add_check_rounded,
//                       title: 'Take Order',
//                       subtitle: 'Orders',
//                     ),
//                   ),

//                   // HOLD / UNHOLD
//                   _TapScale(
//                     onTap: () {
//                       if (!_isCheckedIn) {
//                         _toast('Please check in first.');
//                         return;
//                       }
//                       _pickHold();
//                     },
//                     child: _CategoryCard(
//                       icon: _holdToggleVisual ? Icons.play_circle_outline : Icons.pause_rounded,
//                       title: _holdToggleVisual ? 'Unhold' : 'Hold',
//                       subtitle: _holdToggleVisual ? 'Tap to Unhold' : 'Hold Reason',
//                     ),
//                   ),

//                   // NO VISIT
//                   _TapScale(
//                     onTap: () => _guardRequireCheckIn(_pickNoVisit),
//                     child: const _CategoryCard(
//                       icon: Icons.visibility_off_rounded,
//                       title: 'No Visit',
//                       subtitle: 'Select Reason',
//                     ),
//                   ),

//                   // Collect Payment
//                   _TapScale(
//                     onTap: () => _guardRequireCheckIn(() {
//                       if (!_markInvoicesOn) {
//                         _toast("You don't have rights to view invoices!");
//                         return;
//                       }
//                       _toast('Invoices tapped');
//                       // TODO: Navigate to invoices
//                     }),
//                     child: const _CategoryCard(
//                       icon: Icons.payments_rounded,
//                       title: 'Collect Payment',
//                       subtitle: 'Invoices',
//                     ),
//                   ),

//                   // Sale History
//                   _TapScale(
//                     onTap: () => _guardRequireCheckIn(() {
//                       _toast('History tapped');
//                       // TODO: Navigate to history
//                     }),
//                     child: const _CategoryCard(
//                       icon: Icons.history_rounded,
//                       title: 'Sale History',
//                       subtitle: 'History',
//                     ),
//                   ),
//                 ]),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── shared widgets ────────────────────────────────────────────────────────────
// class _GlassHeader extends StatelessWidget {
//   const _GlassHeader({required this.child});
//   final Widget child;
//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(18),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(.18),
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }
// }

// class _Chip extends StatelessWidget {
//   final String label;
//   final IconData icon;
//   final Color color;
//   final Color textColor;
//   final Color borderColor;

//   const _Chip({
//     required this.label,
//     required this.icon,
//     required this.color,
//     required this.textColor,
//     required this.borderColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: borderColor),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 16, color: textColor),
//           const SizedBox(width: 6),
//           Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 12)),
//         ],
//       ),
//     );
//   }
// }

// class _CategoryCard extends StatelessWidget {
//   const _CategoryCard({required this.icon, required this.title, this.subtitle});
//   final IconData icon;
//   final String title;
//   final String? subtitle;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return DecoratedBox(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(colors: [kOrange, kOrangeLite], begin: Alignment.topLeft, end: Alignment.bottomRight),
//         borderRadius: BorderRadius.all(Radius.circular(16)),
//       ),
//       child: Container(
//         margin: const EdgeInsets.all(1.8),
//         decoration: BoxDecoration(
//           color: kCard,
//           borderRadius: BorderRadius.circular(14.2),
//           boxShadow: const [BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10))],
//           border: Border.all(color: Color(0xFFEDEFF2)),
//         ),
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Material(color: kField, shape: const CircleBorder(),
//                 child: SizedBox(width: 48, height: 48, child: Icon(icon, color: kOrange))),
//             const Spacer(),
//             Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
//                 style: t.titleSmall?.copyWith(color: kText, fontWeight: FontWeight.w700, letterSpacing: .2)),
//             if (subtitle != null) ...[
//               const SizedBox(height: 2),
//               Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: kMuted)),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _TapScale extends StatefulWidget {
//   const _TapScale({super.key, required this.child, required this.onTap});
//   final Widget child;
//   final VoidCallback onTap;

//   @override
//   State<_TapScale> createState() => _TapScaleState();
// }

// class _TapScaleState extends State<_TapScale> with SingleTickerProviderStateMixin {
//   double _scale = 1.0;
//   void _down(TapDownDetails _) => setState(() => _scale = .98);
//   void _up([_]) => setState(() => _scale = 1.0);

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTapDown: _down, onTapCancel: _up, onTapUp: _up, onTap: widget.onTap,
//       child: AnimatedScale(duration: const Duration(milliseconds: 90), scale: _scale, child: widget.child),
//     );
//   }
// }


/*
// COLORS (staying with your palette)
const kOrange = Color(0xFFEA7A3B);
const kOrangeLite = Color(0xFFFFB07A);
const kText = Color(0xFF1E1E1E);
const kMuted = Color(0xFF707883);
const kCard = Colors.white;
const kField = Color(0xFFF2F3F5);
const kShadow = Color(0x14000000);




enum VisitLast { none, hold, noVisit }

VisitLast _parseLast(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'hold':
      return VisitLast.hold;
    case 'no_visit':
      return VisitLast.noVisit;
    default:
      return VisitLast.none;
  }
}

class OrderMenuScreen extends StatefulWidget {
  final String shopname, miscid, address;

  /// Optional parameters that were passed by Java via intent
  /// If you need them, pass from previous screen; safe defaults are used here.
  final String? segId;
  final String? checkCredit; // "0" or "1"
  final String? orderStatus; // "1" means can take/order, otherwise requires No Visit before checkout

  const OrderMenuScreen({
    super.key,
    required this.shopname,
    required this.miscid,
    required this.address,
    this.segId,
    this.checkCredit,
    this.orderStatus,
  });

  @override
  State<OrderMenuScreen> createState() => _OrderMenuScreenState();
}

class _OrderMenuScreenState extends State<OrderMenuScreen> {
  final box = GetStorage();
  final loc.Location location = loc.Location();

  // Visual toggle like Java icons/text
  String checkInText = "Check In"; // toggles to "Check Out"
  bool _hasReasonSelected = false;
  bool _holdToggleVisual = false; // mirrors hold/unhold button UI

  // GPS (string to match Java checks)
  String lat = "0", lng = "0";

  // Java flags
  bool sendActionWasSuccess = false; // sendAction == "1" after successful order

  // ===== persisted status =====
  Map<String, dynamic> _loadStatusMap() {
    final raw = box.read('journey_status');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Future<void> _saveStatus({
    required bool checkedIn,
    required VisitLast last,
  }) async {
    final map = _loadStatusMap();
    map[widget.miscid] = {
      'checkedIn': checkedIn,
      'last': last == VisitLast.hold
          ? 'hold'
          : (last == VisitLast.noVisit ? 'no_visit' : 'none'),
      'holdUI': _holdToggleVisual,
    };
    await box.write('journey_status', map);
  }

  ({bool checkedIn, VisitLast last, bool holdUi}) _statusForShop() {
    final map = _loadStatusMap();
    final s = map[widget.miscid];
    if (s is Map) {
      return (
        checkedIn: (s['checkedIn'] == true),
        last: _parseLast(s['last'] as String?),
        holdUi: (s['holdUI'] == true),
      );
    }
    return (checkedIn: false, last: VisitLast.none, holdUi: false);
  }

  // ===== reasons store (like your journey_reasons) =====
  Map<String, String> _loadReasonMap() {
    final raw = box.read('journey_reasons');
    if (raw is Map) {
      return raw.map<String, String>(
          (k, v) => MapEntry(k.toString(), v.toString()));
    }
    return {};
  }

  Future<void> _saveReason(String reason) async {
    final map = _loadReasonMap();
    map[widget.miscid] = reason;
    await box.write('journey_reasons', map);
  }

  // ===== derived values from Bloc =====
  String get _orderStatus {
    // Java had intent extra "order_status"
    // If not provided, try from state.log?.orderStatus; fallback "1"
    final s = context.read<GlobalBloc>().state;
    return widget.orderStatus ??
        (s.loginModel?.log?.orderStatus ?? "1"); // default allowed
  }

  bool get _markLocationOn {
    // SharedPreferences "markLocation": "1" allows/forces GPS
    final rights = context.read<GlobalBloc>().state.loginModel?.userRights;
    return (rights?.markLocation ?? "0") == "1";
  }

  bool get _markInvoicesOn {
    final rights = context.read<GlobalBloc>().state.loginModel?.userRights;
    return (rights?.markInvoices ?? "0") == "1";
  }

  bool get _isCheckedIn => checkInText == "Check Out";
  bool get _isLockedNoVisit => _statusForShop().last == VisitLast.noVisit;
  bool get _allowCheckInAgain => !_isLockedNoVisit;
  bool get _mustReasonBeforeExit => _isCheckedIn && !_hasReasonSelected;

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  List<String> _reasonsOfType(String type) {
    final reasons =
        context.read<GlobalBloc>().state.loginModel?.reasons ?? const [];
    return reasons
        .where((r) => (r.type ?? "").toUpperCase() == type.toUpperCase())
        .map((r) => r.name ?? "")
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  void _guardRequireCheckIn(VoidCallback action) {
    if (!_isCheckedIn) {
      _toast('Please check in first.');
      return;
    }
    action();
  }

  // ===== GPS =====
  Future<void> _getLocation() async {
    try {
      final hasPerm = await location.hasPermission();
      if (hasPerm == loc.PermissionStatus.denied ||
          hasPerm == loc.PermissionStatus.deniedForever) {
        final req = await location.requestPermission();
        if (req != loc.PermissionStatus.granted) return;
      }
      var en = await location.serviceEnabled();
      if (!en) {
        final ok = await location.requestService();
        if (!ok) return;
      }
      final current = await location.getLocation();
      lat = (current.latitude ?? 0).toString();
      lng = (current.longitude ?? 0).toString();
    } catch (_) {/* ignore */}
  }

  @override
  void initState() {
    super.initState();

    final st = _statusForShop();
    checkInText = st.checkedIn ? "Check Out" : "Check In";
    _hasReasonSelected = !st.checkedIn;
    _holdToggleVisual = st.holdUi;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_markLocationOn) await _getLocation();
    });
  }

  // ===== Reason dialog =====
  Future<void> _pickReason({
    required String dialogTitle,
    required String reasonType, // "HOLD" | "NOVISIT"
    required Future<void> Function(String chosen) onChosenSendApi,
    bool autoPopBackToJourney = true,
  }) async {
    final options = _reasonsOfType(reasonType);
    if (options.isEmpty) {
      _toast('No $reasonType reasons available.');
      return;
    }

    int selectedIndex = -1;
    String? chosen;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final t = Theme.of(context).textTheme;
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kOrange, kOrangeLite],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Container(
              margin: const EdgeInsets.all(1.8),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: kShadow, blurRadius: 16, offset: Offset(0, 10))
                ],
              ),
              child: StatefulBuilder(
                builder: (context, setSB) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        decoration: const BoxDecoration(
                          color: kField,
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16)),
                        ),
                        child: Text(dialogTitle,
                            textAlign: TextAlign.center,
                            style: t.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800, color: kText)),
                      ),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding:
                              const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          itemCount: options.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 2),
                          itemBuilder: (_, i) => RadioListTile<int>(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6),
                            visualDensity: VisualDensity.compact,
                            activeColor: kOrange,
                            title: Text(options[i],
                                style: t.bodyMedium
                                    ?.copyWith(color: kText)),
                            value: i,
                            groupValue: selectedIndex,
                            onChanged: (v) =>
                                setSB(() => selectedIndex = v ?? -1),
                          ),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kMuted,
                                  side: BorderSide(
                                      color: kMuted.withOpacity(.35)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pop(),
                                child: const Text("Cancel"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kOrange,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                onPressed: selectedIndex == -1
                                    ? null
                                    : () async {
                                        chosen = options[selectedIndex];
                                        Navigator.of(context).pop();
                                        if (chosen == null) return;

                                        await onChosenSendApi(chosen!);
                                        await _saveReason(chosen!);
                                        _hasReasonSelected = true;

                                        if (mounted &&
                                            autoPopBackToJourney) {
                                          Navigator.of(context).pop({
                                            'miscid': widget.miscid,
                                            'kind':
                                                reasonType.toLowerCase() ==
                                                        'hold'
                                                    ? 'hold'
                                                    : 'no_order',
                                            'reason': chosen!,
                                          });
                                        }
                                      },
                                child: const Text("Select Reason"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ===== Actions (HOLD / UNHOLD) =====
  Future<void> _pickHold() async {
    // GPS right checks like Java
    if (_markLocationOn && (lat == "0" || lng == "0")) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Location'),
          content: const Text(
              "Can't get location. Please open Google Maps blue dot and try again."),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Optionally open Maps (left as noop)
                },
                child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    final st = _statusForShop();
    final shopStatusIsHold =
        st.last == VisitLast.hold || _holdToggleVisual; // Java split[12] == "2"

    if (!shopStatusIsHold) {
      // choose HOLD reason (type 9)
      await _pickReason(
        dialogTitle: "Select Hold Reason",
        reasonType: "HOLD",
        onChosenSendApi: (chosen) async {
          await _getLocation();
          context.read<GlobalBloc>().add(
                CheckinCheckoutEvent(
                  type: '9',
                  userId: context
                      .read<GlobalBloc>()
                      .state
                      .loginModel!
                      .userinfo!
                      .userId
                      .toString(),
                  lat: lat,
                  lng: lng,
                  act_type: "ORDER_HOLD",
                  action: chosen,
                  misc: widget.miscid,
                  dist_id: context
                      .read<GlobalBloc>()
                      .state
                      .loginModel!
                      .userinfo!
                      .disid
                      .toString(),
                ),
              );
          _holdToggleVisual = true;
          await _saveStatus(checkedIn: false, last: VisitLast.hold);
          setState(() {});
        },
      );
    } else {
      // UNHOLD (type 10)
      await _getLocation();
      context.read<GlobalBloc>().add(
            CheckinCheckoutEvent(
              type: '10',
              userId: context
                  .read<GlobalBloc>()
                  .state
                  .loginModel!
                  .userinfo!
                  .userId
                  .toString(),
              lat: lat,
              lng: lng,
              act_type: "ORDER_HOLD",
              action: "UNHOLD",
              misc: widget.miscid,
              dist_id: context
                  .read<GlobalBloc>()
                  .state
                  .loginModel!
                  .userinfo!
                  .disid
                  .toString(),
            ),
          );
      _holdToggleVisual = false;
      await _saveStatus(checkedIn: _isCheckedIn, last: VisitLast.none);
      setState(() {});
    }
  }

  // ===== Actions (NO VISIT) =====
  Future<void> _pickNoVisit() async {
    await _pickReason(
      dialogTitle: "Select No Visit Reason",
      reasonType: "NOVISIT",
      onChosenSendApi: (chosen) async {
        await _getLocation();

        // 1) ORDER <reason> type 7
        context.read<GlobalBloc>().add(CheckinCheckoutEvent(
              type: '7',
              userId: context
                  .read<GlobalBloc>()
                  .state
                  .loginModel!
                  .userinfo!
                  .userId
                  .toString(),
              lat: lat,
              lng: lng,
              act_type: "ORDER",
              action: chosen,
              misc: widget.miscid,
              dist_id: context
                  .read<GlobalBloc>()
                  .state
                  .loginModel!
                  .userinfo!
                  .disid
                  .toString(),
            ));

        // 2) CHECK OUT type 6
        context.read<GlobalBloc>().add(CheckinCheckoutEvent(
              type: '6',
              userId: context
                  .read<GlobalBloc>()
                  .state
                  .loginModel!
                  .userinfo!
                  .userId
                  .toString(),
              lat: lat,
              lng: lng,
              act_type: "SHOP_CHECK",
              action: "OUT",
              misc: widget.miscid,
              dist_id: context
                  .read<GlobalBloc>()
                  .state
                  .loginModel!
                  .userinfo!
                  .disid
                  .toString(),
            ));

        // Lock re-checkin
        await _saveStatus(checkedIn: false, last: VisitLast.noVisit);
        checkInText = "Check In";
        _hasReasonSelected = true;
      },
    );
  }

  // ===== Confirm dialog (Check-In / Check-Out) =====
  Future<void> _confirmCheckInOut({
    required String title,
    required VoidCallback onYes,
  }) async {
    final name = context.read<GlobalBloc>().state.loginModel?.userinfo?.userName ?? '';
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Hi, $name'),
        content: Text(title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(onPressed: () { Navigator.pop(context); onYes(); }, child: const Text('Yes')),
        ],
      ),
    );
  }

  // ===== Back guards =====
  Future<bool> _onWillPop() async {
    if (_mustReasonBeforeExit) {
      _toast('Please select a reason (Hold / No Visit) before leaving.');
      return false;
    }
    return true;
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    // Listen to checkin/checkout API result (optional UI feedback)
    // You can add a BlocListener here if you want snackbars on success/failure.

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Container(
                    height: 179,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kOrange, kOrangeLite],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 45, 16, 0),
                    child: _GlassHeader(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.20),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.2),
                                ),
                                child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.shopname,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.titleMedium?.copyWith(
                                          color: Colors.white.withOpacity(.97),
                                          fontWeight: FontWeight.w700,
                                        )),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.place_rounded, size: 16, color: Colors.white.withOpacity(.9)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            widget.address,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: t.bodySmall?.copyWith(
                                              color: Colors.white.withOpacity(.95),
                                              height: 1.2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _Chip(
                                label: _isCheckedIn ? "Checked-In" : "Not Checked-In",
                                icon: _isCheckedIn ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: Colors.white.withOpacity(.18),
                                textColor: Colors.white,
                                borderColor: Colors.white.withOpacity(.45),
                              ),
                              const SizedBox(width: 8),
                              _Chip(
                                label: "Shop ID: ${widget.miscid}",
                                icon: Icons.confirmation_number_outlined,
                                color: Colors.white.withOpacity(.14),
                                textColor: Colors.white,
                                borderColor: Colors.white.withOpacity(.45),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () async {
                                  if (checkInText == "Check In") {
                                    if (mounted) Navigator.pop(context);
                                  } else {
                                    final hold = _statusForShop().last == VisitLast.hold || _holdToggleVisual;
                                    if (hold) {
                                      if (mounted) Navigator.pop(context);
                                    } else {
                                      _toast('Please perform an action (Hold / No Visit) first.');
                                    }
                                  }
                                },
                                icon: const Icon(Icons.close, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildListDelegate.fixed([
                  // CHECK-IN / OUT
                  _TapScale(
                    onTap: () async {
                      final st = _statusForShop();

                      // Re-check-in lock after NO VISIT
                      if (checkInText == "Check In" && !_allowCheckInAgain) {
                        _toast('Re-check in not allowed for this shop (No Visit selected earlier).');
                        return;
                      }

                      // if trying to check-out without reason (and you're allowed to order), block
                      if (checkInText == "Check Out" && !_hasReasonSelected && _orderStatus == "1") {
                        _toast('Select a reason (Hold / No Visit) before checking out.');
                        return;
                      }

                      if (_markLocationOn && (lat == "0" || lng == "0")) {
                        _toast("Can't get location. Please open Google Maps blue dot.");
                        return;
                      }
                      await _getLocation();

                      if (checkInText == "Check In") {
                        // CHECK-IN (type 5, action IN)
                        await _confirmCheckInOut(
                          title: "Shop Check-In",
                          onYes: () async {
                            context.read<GlobalBloc>().add(
                                  CheckinCheckoutEvent(
                                    type: '5',
                                    userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
                                    lat: lat,
                                    lng: lng,
                                    act_type: "SHOP_CHECK",
                                    action: "IN",
                                    misc: widget.miscid,
                                    dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
                                  ),
                                );
                            setState(() {
                              checkInText = "Check Out";
                              _hasReasonSelected = false; // must pick reason before leaving
                            });
                            await _saveStatus(checkedIn: true, last: st.last);
                          },
                        );
                      } else {
                        // CHECK-OUT (type 6, action OUT)
                        await _confirmCheckInOut(
                          title: "Shop Check-Out",
                          onYes: () async {
                            context.read<GlobalBloc>().add(
                                  CheckinCheckoutEvent(
                                    type: '6',
                                    userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
                                    lat: lat,
                                    lng: lng,
                                    act_type: "SHOP_CHECK",
                                    action: "OUT",
                                    misc: widget.miscid,
                                    dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
                                  ),
                                );
                            setState(() {
                              checkInText = "Check In";
                              _hasReasonSelected = true; // free to leave
                            });
                            await _saveStatus(checkedIn: false, last: st.last);
                            if (mounted) Navigator.pop(context); // back to Journey Plan
                          },
                        );
                      }
                    },
                    child: _CategoryCard(
                      icon: Icons.access_time,
                      title: checkInText,
                      subtitle: 'Shop ${checkInText == "Check In" ? "Checkin" : "Checkout"}',
                    ),
                  ),

                  // TAKE ORDER (follows Java guards)
                  _TapScale(
                    onTap: () => _guardRequireCheckIn(() async {
                      final st = _statusForShop();

                      if (_orderStatus != "1") {
                        _toast("Not allowed to take order.");
                        return;
                      }
                      if (st.last == VisitLast.hold || _holdToggleVisual) {
                        _toast('Unhold first.');
                        return;
                      }

                      // TODO: Navigate to Take Order screen with extras as needed
                      _toast('Take Order tapped');
                    }),
                    child: const _CategoryCard(
                      icon: Icons.playlist_add_check_rounded,
                      title: 'Take Order',
                      subtitle: 'Orders',
                    ),
                  ),

                  // HOLD / UNHOLD
                  _TapScale(
                    onTap: () => _guardRequireCheckIn(_pickHold),
                    child: _CategoryCard(
                      icon: _holdToggleVisual ? Icons.play_circle_outline : Icons.pause_rounded,
                      title: _holdToggleVisual ? 'Unhold' : 'Hold',
                      subtitle: _holdToggleVisual ? 'Tap to Unhold' : 'Hold Reason',
                    ),
                  ),

                  // NO VISIT
                  _TapScale(
                    onTap: () => _guardRequireCheckIn(_pickNoVisit),
                    child: const _CategoryCard(
                      icon: Icons.visibility_off_rounded,
                      title: 'No Visit',
                      subtitle: 'Select Reason',
                    ),
                  ),

                  // Collect Payment
                  _TapScale(
                    onTap: () => _guardRequireCheckIn(() {
                      if (!_markInvoicesOn) {
                        _toast("You don't have rights to view invoices!");
                        return;
                      }
                      // TODO: Navigate to Invoices screen with shop id / dist id
                      _toast('Invoices tapped');
                    }),
                    child: const _CategoryCard(
                      icon: Icons.payments_rounded,
                      title: 'Collect Payment',
                      subtitle: 'Invoices',
                    ),
                  ),

                  // Sale History
                  _TapScale(
                    onTap: () => _guardRequireCheckIn(() {
                      // TODO: Navigate to History screen
                      _toast('History tapped');
                    }),
                    child: const _CategoryCard(
                      icon: Icons.history_rounded,
                      title: 'Sale History',
                      subtitle: 'History',
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── shared widgets ────────────────────────────────────────────────────────────
class _GlassHeader extends StatelessWidget {
  const _GlassHeader({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color borderColor;

  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [kOrange, kOrangeLite], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.8),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14.2),
          boxShadow: const [BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10))],
          border: Border.all(color: Color(0xFFEDEFF2)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(color: kField, shape: const CircleBorder(),
                child: SizedBox(width: 48, height: 48, child: Icon(icon, color: kOrange))),
            const Spacer(),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: t.titleSmall?.copyWith(color: kText, fontWeight: FontWeight.w700, letterSpacing: .2)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: kMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _TapScale extends StatefulWidget {
  const _TapScale({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  void _down(TapDownDetails _) => setState(() => _scale = .98);
  void _up([_]) => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down, onTapCancel: _up, onTapUp: _up, onTap: widget.onTap,
      child: AnimatedScale(duration: const Duration(milliseconds: 90), scale: _scale, child: widget.child),
    );
  }
}
*/



// class OrderMenuScreen extends StatefulWidget {
//   final String shopname, miscid, address;
//   const OrderMenuScreen({
//     super.key,
//     required this.shopname,
//     required this.miscid,
//     required this.address,
//   });

//   @override
//   State<OrderMenuScreen> createState() => _OrderMenuScreenState();
// }

// class _OrderMenuScreenState extends State<OrderMenuScreen> {
//   final box = GetStorage();
//   final loc.Location location = loc.Location();

//   String checkInText = "Check In"; // toggles to "Check Out"
//   bool _hasReasonSelected = false;

//   // theme shorthands
//   static const Color orange = kOrange;
//   static const Color text = kText;
//   static const Color muted = kMuted;
//   static const Color field = kField;
//   static const Color card = kCard;
//   static const Color _shadow = kShadow;

//   bool get _isCheckedIn => checkInText == "Check Out";

//   void _toggleCheckIn() {
//     setState(() {
//       checkInText = (checkInText == "Check In") ? "Check Out" : "Check In";
//       // when checking in we require a reason before leaving
//       _hasReasonSelected = !_isCheckedIn;
//     });
//   }

//   Map<String, String> _loadReasonMap() {
//     final raw = box.read('journey_reasons');
//     if (raw is Map) {
//       return raw.map<String, String>((k, v) => MapEntry(k.toString(), v.toString()));
//     }
//     return {};
//   }

//   Future<void> _saveReason(String reason) async {
//     final map = _loadReasonMap();
//     map[widget.miscid] = reason;
//     await box.write('journey_reasons', map);
//   }

//   List<String> _reasonsOfType(String type) {
//     final reasons =
//         context.read<GlobalBloc>().state.loginModel?.reasons ?? const [];
//     // Java used "HOLD" and "NOVISIT" reason types
//     return reasons
//         .where((r) => (r.type ?? "").toUpperCase() == type.toUpperCase())
//         .map((r) => r.name ?? "")
//         .where((s) => s.trim().isNotEmpty)
//         .toList();
//   }

//   Future<void> _pickReason({
//     required String dialogTitle,
//     required String reasonType, // "HOLD" | "NOVISIT"
//     required void Function(String chosen) onChosenSendApi,
//   }) async {
//     final options = _reasonsOfType(reasonType);
//     if (options.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('No $reasonType reasons available.')),
//       );
//       return;
//     }
//     int selectedIndex = -1;
//     String? chosen;

//     await showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (context) {
//         final t = Theme.of(context).textTheme;
//         return Dialog(
//           insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//           backgroundColor: Colors.transparent,
//           child: Container(
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [orange, Color(0xFFFFB07A)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(18),
//             ),
//             child: Container(
//               margin: const EdgeInsets.all(1.8),
//               decoration: BoxDecoration(
//                 color: card,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: const [BoxShadow(color: _shadow, blurRadius: 16, offset: Offset(0, 10))],
//               ),
//               child: StatefulBuilder(
//                 builder: (context, setStateSB) {
//                   return Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
//                         decoration: const BoxDecoration(
//                           color: field,
//                           borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//                         ),
//                         child: Text(
//                           dialogTitle,
//                           textAlign: TextAlign.center,
//                           style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: text),
//                         ),
//                       ),
//                       Flexible(
//                         child: ListView.separated(
//                           shrinkWrap: true,
//                           padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
//                           itemCount: options.length,
//                           separatorBuilder: (_, __) => const SizedBox(height: 2),
//                           itemBuilder: (_, i) => RadioListTile<int>(
//                             dense: true,
//                             contentPadding: const EdgeInsets.symmetric(horizontal: 6),
//                             visualDensity: VisualDensity.compact,
//                             activeColor: orange,
//                             title: Text(options[i], style: t.bodyMedium?.copyWith(color: text)),
//                             value: i,
//                             groupValue: selectedIndex,
//                             onChanged: (v) => setStateSB(() => selectedIndex = v ?? -1),
//                           ),
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: OutlinedButton(
//                                 style: OutlinedButton.styleFrom(
//                                   foregroundColor: muted,
//                                   side: BorderSide(color: muted.withOpacity(.35)),
//                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                                 ),
//                                 onPressed: () => Navigator.of(context).pop(),
//                                 child: const Text("Cancel"),
//                               ),
//                             ),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: ElevatedButton(
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: orange,
//                                   foregroundColor: Colors.white,
//                                   elevation: 0,
//                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                                 ),
//                                 onPressed: selectedIndex == -1
//                                     ? null
//                                     : () async {
//                                         chosen = options[selectedIndex];
//                                         Navigator.of(context).pop();
//                                         if (chosen == null) return;

//                                         onChosenSendApi(chosen!);
//                                         await _saveReason(chosen!);
//                                         _hasReasonSelected = true;

//                                         if (mounted) {
//                                           Navigator.of(context).pop({
//                                             'miscid': widget.miscid,
//                                             'kind': reasonType.toLowerCase() == 'hold' ? 'hold' : 'no_order',
//                                             'reason': chosen!,
//                                           });
//                                         }
//                                       },
//                                 child: const Text("Select Reason"),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Future<void> _pickHold() async {
//     await _pickReason(
//       dialogTitle: "Select Hold Reason",
//       reasonType: "HOLD",
//       onChosenSendApi: (chosen) async {
//         final currentLocation = await location.getLocation();
//         context.read<GlobalBloc>().add(
//               CheckinCheckoutEvent(
//                 type: '9',
//                 userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
//                 lat: (currentLocation.latitude ?? 0).toString(),
//                 lng: (currentLocation.longitude ?? 0).toString(),
//                 act_type: "ORDER_HOLD",
//                 action: chosen,
//                 misc: widget.miscid,
//                 dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
//               ),
//             );
//       },
//     );
//   }

//   Future<void> _pickNoVisit() async {
//     await _pickReason(
//       dialogTitle: "Select No Visit Reason",
//       reasonType: "NOVISIT",
//       onChosenSendApi: (chosen) async {
//         final currentLocation = await location.getLocation();

//         // 1) ORDER <reason>
//         context.read<GlobalBloc>().add(
//               CheckinCheckoutEvent(
//                 type: '7',
//                 userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
//                 lat: (currentLocation.latitude ?? 0).toString(),
//                 lng: (currentLocation.longitude ?? 0).toString(),
//                 act_type: "ORDER",
//                 action: chosen,
//                 misc: widget.miscid,
//                 dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
//               ),
//             );

//         // 2) CHECK OUT immediately
//         context.read<GlobalBloc>().add(
//               CheckinCheckoutEvent(
//                 type: '6',
//                 userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
//                 lat: (currentLocation.latitude ?? 0).toString(),
//                 lng: (currentLocation.longitude ?? 0).toString(),
//                 act_type: "SHOP_CHECK",
//                 action: "OUT",
//                 misc: widget.miscid,
//                 dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
//               ),
//             );
//       },
//     );
//   }

//   Future<bool> _onWillPop() async {
//     if (_isCheckedIn && !_hasReasonSelected) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a reason (Hold / No Visit) before leaving.')),
//       );
//       return false;
//     }
//     return true;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: CustomScrollView(
//           physics: const BouncingScrollPhysics(),
//           slivers: [
//             SliverToBoxAdapter(
//               child: Stack(
//                 children: [
//                   Container(
//                     height: 179,
//                     decoration: const BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [kOrange, kOrangeLite],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 45, 16, 0),
//                     child: _GlassHeader(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Container(
//                                 width: 46,
//                                 height: 46,
//                                 decoration: BoxDecoration(
//                                   color: Colors.white.withOpacity(.20),
//                                   shape: BoxShape.circle,
//                                   border: Border.all(color: Colors.white, width: 1.2),
//                                 ),
//                                 child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(widget.shopname,
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                         style: t.titleMedium?.copyWith(
//                                           color: Colors.white.withOpacity(.97),
//                                           fontWeight: FontWeight.w700,
//                                         )),
//                                     const SizedBox(height: 4),
//                                     Row(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Icon(Icons.place_rounded, size: 16, color: Colors.white.withOpacity(.9)),
//                                         const SizedBox(width: 4),
//                                         Expanded(
//                                           child: Text(
//                                             widget.address,
//                                             maxLines: 2,
//                                             overflow: TextOverflow.ellipsis,
//                                             style: t.bodySmall?.copyWith(
//                                               color: Colors.white.withOpacity(.95),
//                                               height: 1.2,
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 10),
//                           Row(
//                             children: [
//                               _Chip(
//                                 label: _isCheckedIn ? "Checked-In" : "Not Checked-In",
//                                 icon: _isCheckedIn ? Icons.check_circle : Icons.radio_button_unchecked,
//                                 color: Colors.white.withOpacity(.18),
//                                 textColor: Colors.white,
//                                 borderColor: Colors.white.withOpacity(.45),
//                               ),
//                               const SizedBox(width: 8),
//                               _Chip(
//                                 label: "Shop ID: ${widget.miscid}",
//                                 icon: Icons.confirmation_number_outlined,
//                                 color: Colors.white.withOpacity(.14),
//                                 textColor: Colors.white,
//                                 borderColor: Colors.white.withOpacity(.45),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             SliverPadding(
//               padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
//               sliver: SliverGrid(
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 2,
//                   crossAxisSpacing: 14,
//                   mainAxisSpacing: 14,
//                   childAspectRatio: 1.05,
//                 ),
//                 delegate: SliverChildListDelegate.fixed([
//                   // CHECK-IN / OUT
//                   _TapScale(
//                     onTap: () async {
//                       final currentLocation = await location.getLocation();
//                       _toggleCheckIn();
//                       context.read<GlobalBloc>().add(
//                             CheckinCheckoutEvent(
//                               type: '5',
//                               userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
//                               lat: (currentLocation.latitude ?? 0).toString(),
//                               lng: (currentLocation.longitude ?? 0).toString(),
//                               act_type: "SHOP_CHECK",
//                               action: checkInText == "Check Out" ? "IN" : "OUT",
//                               misc: widget.miscid,
//                               dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
//                             ),
//                           );
//                     },
//                     child: _CategoryCard(
//                       icon: Icons.access_time,
//                       title: checkInText,
//                       subtitle: 'Shop ${checkInText == "Check In" ? "Checkin" : "Checkout"}',
//                     ),
//                   ),

//                   // TAKE ORDER (placeholder)
//                   const _CategoryCard(
//                     icon: Icons.playlist_add_check_rounded,
//                     title: 'Take Order',
//                     subtitle: 'Orders',
//                   ),

//                   // HOLD
//                   _TapScale(
//                     onTap: _pickHold,
//                     child: const _CategoryCard(
//                       icon: Icons.pause_rounded,
//                       title: 'Hold',
//                       subtitle: 'Hold Reason',
//                     ),
//                   ),

//                   // NO VISIT (No Order Reason)
//                   _TapScale(
//                     onTap: _pickNoVisit,
//                     child: const _CategoryCard(
//                       icon: Icons.visibility_off_rounded,
//                       title: 'No Visit',
//                       subtitle: 'Select Reason',
//                     ),
//                   ),

//                   // Collect Payment (placeholder)
//                   const _CategoryCard(
//                     icon: Icons.payments_rounded,
//                     title: 'Collect Payment',
//                     subtitle: 'Place new order',
//                   ),

//                   // Sale History (placeholder)
//                   const _CategoryCard(
//                     icon: Icons.history_rounded,
//                     title: 'Sale History',
//                     subtitle: 'History',
//                   ),
//                 ]),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── shared widgets ────────────────────────────────────────────────────────────
// class _GlassHeader extends StatelessWidget {
//   const _GlassHeader({required this.child});
//   final Widget child;
//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(18),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(.18),
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }
// }

// class _Chip extends StatelessWidget {
//   final String label;
//   final IconData icon;
//   final Color color;
//   final Color textColor;
//   final Color borderColor;

//   const _Chip({
//     required this.label,
//     required this.icon,
//     required this.color,
//     required this.textColor,
//     required this.borderColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: borderColor),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 16, color: textColor),
//           const SizedBox(width: 6),
//           Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 12)),
//         ],
//       ),
//     );
//   }
// }

// class _CategoryCard extends StatelessWidget {
//   const _CategoryCard({required this.icon, required this.title, this.subtitle});
//   final IconData icon;
//   final String title;
//   final String? subtitle;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return DecoratedBox(
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [kOrange, kOrangeLite],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Container(
//         margin: const EdgeInsets.all(1.8),
//         decoration: BoxDecoration(
//           color: kCard,
//           borderRadius: BorderRadius.circular(14.2),
//           boxShadow: const [BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10))],
//           border: Border.all(color: const Color(0xFFEDEFF2)),
//         ),
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Material(color: kField, shape: const CircleBorder(), child: SizedBox(width: 48, height: 48, child: Icon(icon, color: kOrange))),
//             const Spacer(),
//             Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall?.copyWith(color: kText, fontWeight: FontWeight.w700, letterSpacing: .2)),
//             if (subtitle != null) ...[
//               const SizedBox(height: 2),
//               Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: kMuted)),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _TapScale extends StatefulWidget {
//   const _TapScale({super.key, required this.child, required this.onTap});
//   final Widget child;
//   final VoidCallback onTap;

//   @override
//   State<_TapScale> createState() => _TapScaleState();
// }

// class _TapScaleState extends State<_TapScale> with SingleTickerProviderStateMixin {
//   double _scale = 1.0;
//   void _down(TapDownDetails _) => setState(() => _scale = .98);
//   void _up([_]) => setState(() => _scale = 1.0);

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTapDown: _down,
//       onTapCancel: _up,
//       onTapUp: _up,
//       onTap: widget.onTap,
//       child: AnimatedScale(duration: const Duration(milliseconds: 90), scale: _scale, child: widget.child),
//     );
//   }
// }




/*class OrderMenuScreen extends StatefulWidget {
  final String shopname, miscid, address;
  const OrderMenuScreen({
    super.key,
    required this.shopname,
    required this.miscid,
    required this.address,
  });

  @override
  State<OrderMenuScreen> createState() => _OrderMenuScreenState();
}

class _OrderMenuScreenState extends State<OrderMenuScreen> {
  String checkInText = "Check In";
  final loc.Location location = loc.Location();

  // ── UI Helpers Colors ────────────────────────────────────────────────────────
  static const Color orange = kOrange;
  static const Color text = kText;
  static const Color muted = kMuted;
  static const Color field = kField;
  static const Color card = kCard;
  static const Color _shadow = kShadow;

  void _toggleCheckIn() {
    setState(() {
      checkInText = (checkInText == "Check In") ? "Check Out" : "Check In";
    });
  }

  // HOLD REASONS DIALOG – pops back to list with selection
  Future<String?> showHoldReasonDialog(BuildContext context) async {
    int selectedIndex = -1;
    final List<String> holdReasons = const [
      "Purchaser Not Available",
      "Tea Time",
      "Lunch Time",
    ];
    String? chosen;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final t = Theme.of(context).textTheme;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [orange, Color(0xFFFFB07A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Container(
              margin: const EdgeInsets.all(1.8),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: _shadow, blurRadius: 16, offset: Offset(0, 10)),
                ],
              ),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        decoration: const BoxDecoration(
                          color: field,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Text(
                          "Select Hold Reason",
                          textAlign: TextAlign.center,
                          style: t.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: text,
                          ),
                        ),
                      ),
                      Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          shrinkWrap: true,
                          itemCount: holdReasons.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 2),
                          itemBuilder: (_, index) {
                            return RadioListTile<int>(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                              visualDensity: VisualDensity.compact,
                              activeColor: orange,
                              title: Text(
                                holdReasons[index],
                                style: t.bodyMedium?.copyWith(
                                  color: text,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: index,
                              groupValue: selectedIndex,
                              onChanged: (v) => setState(() => selectedIndex = v ?? -1),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: muted,
                                  side: BorderSide(color: muted.withOpacity(.35)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text("Cancel"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orange,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: selectedIndex == -1
                                    ? null
                                    : () {
                                        chosen = holdReasons[selectedIndex];
                                        Navigator.of(context).pop(); // close dialog
                                        // return to JourneyPlan with payload
                                        Navigator.of(context).pop({
                                          'miscid': widget.miscid,
                                          'kind': 'hold',
                                          'reason': chosen,
                                        });
                                      },
                                child: const Text("Select Reason"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    return chosen;
  }

  // NO-ORDER REASONS – pops back with selection
  Future<String?> showNoOrderReasonDialog(BuildContext context) async {
    int selectedIndex = -1;
    final List<String> noOrder = const [
      "No Order",
      "Credit Not Alowed",
      "Shop Closed",
      "Stock Available",
      "No Order With Collection",
      "Visit For Collection",
    ];
    String? chosen;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final t = Theme.of(context).textTheme;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [orange, Color(0xFFFFB07A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Container(
              margin: const EdgeInsets.all(1.8),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: _shadow, blurRadius: 16, offset: Offset(0, 10)),
                ],
              ),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        decoration: const BoxDecoration(
                          color: field,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Text(
                          "Select No Order Reason",
                          textAlign: TextAlign.center,
                          style: t.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: text,
                          ),
                        ),
                      ),
                      Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          shrinkWrap: true,
                          itemCount: noOrder.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 2),
                          itemBuilder: (_, index) {
                            return RadioListTile<int>(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                              visualDensity: VisualDensity.compact,
                              activeColor: orange,
                              title: Text(
                                noOrder[index],
                                style: t.bodyMedium?.copyWith(
                                  color: text,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: index,
                              groupValue: selectedIndex,
                              onChanged: (v) => setState(() => selectedIndex = v ?? -1),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: muted,
                                  side: BorderSide(color: muted.withOpacity(.35)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text("Cancel"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orange,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: selectedIndex == -1
                                    ? null
                                    : () {
                                        chosen = noOrder[selectedIndex];
                                        Navigator.of(context).pop(); // close dialog
                                        // return to JourneyPlan with payload
                                        Navigator.of(context).pop({
                                          'miscid': widget.miscid,
                                          'kind': 'no_order',
                                          'reason': chosen,
                                        });
                                      },
                                child: const Text("Select Reason"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    return chosen;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  height: 179,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kOrange, kOrangeLite],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 45, 16, 0),
                  child: _GlassHeader(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.20),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.2),
                              ),
                              child: const Icon(Icons.store_rounded,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.shopname,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: t.titleMedium?.copyWith(
                                        color: Colors.white.withOpacity(.97),
                                        fontWeight: FontWeight.w700,
                                      )),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.place_rounded,
                                          size: 16, color: Colors.white.withOpacity(.9)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          widget.address,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: t.bodySmall?.copyWith(
                                            color: Colors.white.withOpacity(.95),
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _Chip(
                              label: checkInText == "Check In"
                                  ? "Not Checked-In"
                                  : "Checked-In",
                              icon: checkInText == "Check In"
                                  ? Icons.radio_button_unchecked
                                  : Icons.check_circle,
                              color: Colors.white.withOpacity(.18),
                              textColor: Colors.white,
                              borderColor: Colors.white.withOpacity(.45),
                            ),
                            const SizedBox(width: 8),
                            _Chip(
                              label: "Shop ID: ${widget.miscid}",
                              icon: Icons.confirmation_number_outlined,
                              color: Colors.white.withOpacity(.14),
                              textColor: Colors.white,
                              borderColor: Colors.white.withOpacity(.45),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              delegate: SliverChildListDelegate.fixed([
                // CHECK-IN tile
                _TapScale(
                  onTap: () async {
                    final currentLocation = await location.getLocation();
                    _toggleCheckIn();
                    context.read<GlobalBloc>().add(
                          CheckinCheckoutEvent(
                            type: '5',
                            userId: context
                                .read<GlobalBloc>()
                                .state
                                .loginModel!
                                .userinfo!
                                .userId
                                .toString(),
                            lat: currentLocation.latitude.toString(),
                            lng: currentLocation.longitude.toString(),
                            act_type: "SHOP_CHECK",
                            action: checkInText == "Check Out" ? "IN" : "OUT",
                            misc: widget.miscid,
                            dist_id: context
                                .read<GlobalBloc>()
                                .state
                                .loginModel!
                                .userinfo!
                                .disid
                                .toString(),
                          ),
                        );
                  },
                  child: _CategoryCard(
                    icon: Icons.access_time,
                    title: checkInText,
                    subtitle: 'Shop ${checkInText == "Check In" ? "Checkin" : "Checkout"}',
                  ),
                ),

                // TAKE ORDER (example navigation)
                _TapScale(
                  onTap: () {
                    // Navigator.push(... to catalog)
                  },
                  child: const _CategoryCard(
                    icon: Icons.playlist_add_check_rounded,
                    title: 'Take Order',
                    subtitle: 'Orders',
                  ),
                ),

                // HOLD → pick reason → return to list
                _TapScale(
                  onTap: () => showHoldReasonDialog(context),
                  child: const _CategoryCard(
                    icon: Icons.pause_rounded,
                    title: 'Hold',
                    subtitle: 'Hold Reason',
                  ),
                ),

                // NO ORDER → pick reason → return to list
                _TapScale(
                  onTap: () => showNoOrderReasonDialog(context),
                  child: const _CategoryCard(
                    icon: Icons.visibility_off_rounded,
                    title: 'No Order Reason',
                    subtitle: 'Select Reason',
                  ),
                ),

                _TapScale(
                  onTap: () {
                    // Collect Payment
                  },
                  child: const _CategoryCard(
                    icon: Icons.payments_rounded,
                    title: 'Collect Payment',
                    subtitle: 'Place new order',
                  ),
                ),

                _TapScale(
                  onTap: () {
                    // Sale History
                  },
                  child: const _CategoryCard(
                    icon: Icons.history_rounded,
                    title: 'Sale History',
                    subtitle: 'History',
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────
class _GlassHeader extends StatelessWidget {
  const _GlassHeader({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color borderColor;

  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              )),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kOrange, kOrangeLite],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.8),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14.2),
          boxShadow: const [
            BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10)),
          ],
          border: Border.all(color: const Color(0xFFEDEFF2)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: kField,
              shape: const CircleBorder(),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(icon, color: kOrange),
              ),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.titleSmall?.copyWith(
                color: kText,
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall?.copyWith(color: kMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TapScale extends StatefulWidget {
  const _TapScale({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _down(TapDownDetails _) => setState(() => _scale = .98);
  void _up([_]) => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapCancel: _up,
      onTapUp: _up,
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
*/


/*class OrderMenuScreen extends StatefulWidget {
  final String shopname, miscid, address;
  const OrderMenuScreen({
    super.key,
    required this.shopname,
    required this.miscid,
    required this.address,
  });

  @override
  State<OrderMenuScreen> createState() => _OrderMenuScreenState();
}

class _OrderMenuScreenState extends State<OrderMenuScreen> {
  // THEME (uses your existing app palette names)
  static const Color kOrange = Color(0xFFEA7A3B);
  static const Color kOrangeLite = Color(0xFFFFB07A);
  static const Color kText = Color(0xFF1E1E1E);
  static const Color kMuted = Color(0xFF707883);
  static const Color kField = Color(0xFFF5F5F7);
  static const Color kCard = Colors.white;
  static const Color kShadow = Color(0x14000000);

  final loc.Location location = loc.Location();

  // ---- State mirroring the Java logic ----
  bool isCheckedIn = false;         // checkInText == "Check-Out" in Java when true
  bool isHold = false;              // holdCheck in Java (true => Unhold state/button)
  bool hasOrder = false;            // set this to true when user has items/orders (via your order flow)
  String? holdReason;               // when shop put on hold (type 9)
  String? noOrderReason;            // when user selects no-visit/no-order reason

  // UI label (derived from isCheckedIn)
  String get checkInLabel => isCheckedIn ? "Check Out" : "Check In";

  Future<loc.LocationData> _getLoc() async => await location.getLocation();

  // ---- Guard: can the user leave? (back, close, etc.) ----
  bool get _canLeave {
    if (!isCheckedIn) return true;
    // User must choose a Hold reason OR a No-Order reason OR place an order before they can leave.
    // (Matches Java: onBackPressed allowed if holdCheck == true OR user not checked-in)
    return isHold || noOrderReason != null || hasOrder;
  }

  Future<bool> _onWillPop() async {
    if (_canLeave) return true;
    _blockLeavingDialog();
    return false;
  }

  void _blockLeavingDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Action Required"),
        content: const Text(
          "You’re checked-in. Please select a Hold/No-Order reason or place an order before leaving this screen.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ---- Events mapping (same as Java types/acts) ----
  Future<void> _checkIn() async {
    final pos = await _getLoc();
    context.read<GlobalBloc>().add(
          CheckinCheckoutEvent(
            type: '5',
            userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
            lat: (pos.latitude ?? 0).toString(),
            lng: (pos.longitude ?? 0).toString(),
            act_type: "SHOP_CHECK",
            action: "IN",
            misc: widget.miscid,
            dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
          ),
        );
    setState(() {
      isCheckedIn = true;
      // reset session state on new check-in
      isHold = false;
      holdReason = null;
      noOrderReason = null;
      hasOrder = false;
    });
  }

  Future<void> _checkOut() async {
    // Java: if on hold => "Unhold first"; else allow checkout if has order or no-order reason,
    // otherwise prompt no-order reasons.
    if (isHold) {
      toastWidget("Unhold first to Check-Out", Colors.red);
      return;
    }
    if (!(hasOrder || noOrderReason != null)) {
      // prompt no order reason (mirrors PopulateDialog(type no-visit))
      final reason = await _showNoOrderReasonDialog();
      if (reason == null) return; // user cancelled
      setState(() => noOrderReason = reason);
    }

    final pos = await _getLoc();
    context.read<GlobalBloc>().add(
          CheckinCheckoutEvent(
            type: '6',
            userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
            lat: (pos.latitude ?? 0).toString(),
            lng: (pos.longitude ?? 0).toString(),
            act_type: "SHOP_CHECK",
            action: "OUT",
            misc: widget.miscid,
            dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
          ),
        );

    setState(() {
      isCheckedIn = false;
      // session ends, keep local flags if you want; here we clear
      isHold = false;
      holdReason = null;
      // keep noOrderReason/hasOrder for history if you want
    });
    toastWidget("Checked-Out", Colors.green);
    if (!mounted) return;
    Navigator.pop(context); // leave after successful checkout
  }

  Future<void> _toggleHold() async {
    if (!isCheckedIn) {
      toastWidget("Please Check-In first", Colors.red);
      return;
    }

    // If already on hold -> UNHOLD (type 10)
    if (isHold) {
      final pos = await _getLoc();
      context.read<GlobalBloc>().add(
            CheckinCheckoutEvent(
              type: '10',
              userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
              lat: (pos.latitude ?? 0).toString(),
              lng: (pos.longitude ?? 0).toString(),
              act_type: "ORDER_HOLD",
              action: "UNHOLD",
              misc: widget.miscid,
              dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
            ),
          );
      setState(() {
        isHold = false;
        holdReason = null;
      });
      toastWidget("Unhold done", Colors.green);
      return;
    }

    // Not on hold -> ask reason (type 9)
    final reason = await _showHoldReasonDialog();
    if (reason == null) return;

    final pos = await _getLoc();
    context.read<GlobalBloc>().add(
          CheckinCheckoutEvent(
            type: '9',
            userId: context.read<GlobalBloc>().state.loginModel!.userinfo!.userId.toString(),
            lat: (pos.latitude ?? 0).toString(),
            lng: (pos.longitude ?? 0).toString(),
            act_type: "ORDER_HOLD",
            action: reason,
            misc: widget.miscid,
            dist_id: context.read<GlobalBloc>().state.loginModel!.userinfo!.disid.toString(),
          ),
        );

    setState(() {
      isHold = true;     
      holdReason = reason;
    });
    toastWidget("On Hold: $reason", Colors.orange);
  }

  Future<void> _pickNoOrderReason() async {
    if (!isCheckedIn) {
      toastWidget("Please Check-In first", Colors.red);
      return;
    }
    if (isHold) {
      toastWidget("Unhold first to proceed", Colors.red);
      return;
    }
    final reason = await _showNoOrderReasonDialog();
    if (reason == null) return;

    setState(() => noOrderReason = reason);
    toastWidget("No-Order: $reason", Colors.orange);
  }

  Future<void> _goTakeOrder() async {
    if (!isCheckedIn) {
      toastWidget("Please Check-In first", Colors.red);
      return;
    }
    if (isHold) {
      toastWidget("Unhold first to take order", Colors.red);
      return;
    }

    final before = hasOrder;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const MeezanTeaCatalog()));
    if (!mounted) return;
    if (!before) setState(() => hasOrder = true);
  }

  Future<String?> _showHoldReasonDialog() => showHoldReasonDialog(context);
  Future<String?> _showNoOrderReasonDialog() => showNoOrderReasonDialog(context);

  // ====== Your existing dialog UIs (unchanged) ======
  Future<String?> showHoldReasonDialog(BuildContext context) async {
    int selectedIndex = -1;
    final List<String> holdReasons = const [
      "Purchaser Not Available",
      "Tea Time",
      "Lunch Time",
    ];
    String? chosen;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final t = Theme.of(context).textTheme;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kOrange, kOrangeLite],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Container(
              margin: const EdgeInsets.all(1.8),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10))],
              ),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        decoration: const BoxDecoration(
                          color: kField,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Text("Select Hold Reason",
                            textAlign: TextAlign.center,
                            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: kText)),
                      ),
                      Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          shrinkWrap: true,
                          itemCount: holdReasons.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 2),
                          itemBuilder: (_, index) => RadioListTile<int>(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                            visualDensity: VisualDensity.compact,
                            activeColor: kOrange,
                            title: Text(holdReasons[index],
                                style: t.bodyMedium?.copyWith(color: kText, fontWeight: FontWeight.w500)),
                            value: index,
                            groupValue: selectedIndex,
                            onChanged: (v) => setState(() => selectedIndex = v ?? -1),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kMuted,
                                  side: BorderSide(color: kMuted.withOpacity(.35)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text("Cancel"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kOrange, foregroundColor: Colors.white,
                                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: selectedIndex == -1
                                    ? null
                                    : () {
                                        chosen = holdReasons[selectedIndex];
                                        Navigator.of(context).pop();
                                      },
                                child: const Text("Select Reason"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
    return chosen;
  }

  Future<String?> showNoOrderReasonDialog(BuildContext context) async {
    int selectedIndex = -1;
    final List<String> noOrder = const [
      "No Order",
      "Credit Not Allowed",
      "Shop Closed",
      "Stock Available",
      "No Order With Collection",
      "Visit For Collection",
    ];
    String? chosen;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final t = Theme.of(context).textTheme;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kOrange, kOrangeLite],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Container(
              margin: const EdgeInsets.all(1.8),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10))],
              ),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        decoration: const BoxDecoration(
                          color: kField,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Text("Select No Order Reason",
                            textAlign: TextAlign.center,
                            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: kText)),
                      ),
                      Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          shrinkWrap: true,
                          itemCount: noOrder.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 2),
                          itemBuilder: (_, index) => RadioListTile<int>(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                            visualDensity: VisualDensity.compact,
                            activeColor: kOrange,
                            title: Text(noOrder[index],
                                style: t.bodyMedium?.copyWith(color: kText, fontWeight: FontWeight.w500)),
                            value: index,
                            groupValue: selectedIndex,
                            onChanged: (v) => setState(() => selectedIndex = v ?? -1),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kMuted,
                                  side: BorderSide(color: kMuted.withOpacity(.35)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text("Cancel"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kOrange, foregroundColor: Colors.white,
                                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: selectedIndex == -1
                                    ? null
                                    : () {
                                        chosen = noOrder[selectedIndex];
                                        Navigator.of(context).pop();
                                      },
                                child: const Text("Select Reason"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
    return chosen;
  }
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Container(
                    height: 179,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kOrange, kOrangeLite],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 45, 16, 0),
                    child: _GlassHeader(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              width: 46, height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.20),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.2),
                              ),
                              child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(widget.shopname,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.titleMedium?.copyWith(
                                      color: Colors.white.withOpacity(.97),
                                      fontWeight: FontWeight.w700,
                                    )),
                                const SizedBox(height: 4),
                                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Icon(Icons.place_rounded, size: 16, color: Colors.white.withOpacity(.9)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.address,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: t.bodySmall?.copyWith(
                                        color: Colors.white.withOpacity(.95),
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ]),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            _Chip(
                              label: isCheckedIn ? "Checked-In" : "Not Checked-In",
                              icon: isCheckedIn ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: Colors.white.withOpacity(isCheckedIn ? .30 : .20),
                              textColor: Colors.white,
                              borderColor: Colors.white.withOpacity(.45),
                            ),
                            const SizedBox(width: 8),
                            _Chip(
                              label: "Shop ID: ${widget.miscid}",
                              icon: Icons.confirmation_number_outlined,
                              color: Colors.white.withOpacity(.14),
                              textColor: Colors.white,
                              borderColor: Colors.white.withOpacity(.45),
                            ),
                            const SizedBox(width: 8),
                            if (isHold)
                              _Chip(
                                label: "ON HOLD",
                                icon: Icons.pause_circle_filled_rounded,
                                color: Colors.white.withOpacity(.28),
                                textColor: Colors.white,
                                borderColor: Colors.white.withOpacity(.45),
                              ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // GRID
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.05,
                ),
                delegate: SliverChildListDelegate.fixed([
                  _TapScale(
                    onTap: () async {
                      if (!isCheckedIn) {
                        await _checkIn();
                      } else {
                        await _checkOut();
                      }
                      setState(() {}); // refresh labels/chips
                    },
                    child: _CategoryCard(
                      icon: Icons.access_time,
                      title: checkInLabel,
                      subtitle: 'Shop ${!isCheckedIn ? "Check-In" : "Check-Out"}',
                    ),
                  ),

                  // TAKE ORDER
                  _TapScale(
                    onTap: _goTakeOrder,
                    child: const _CategoryCard(
                      icon: Icons.playlist_add_check_rounded,
                      title: 'Take Order',
                      subtitle: 'Orders',
                    ),
                  ),

                  // HOLD / UNHOLD
                  _TapScale(
                    onTap: _toggleHold,
                    child: _CategoryCard(
                      icon: isHold ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      title: isHold ? 'Unhold' : 'Hold',
                      subtitle: isHold ? 'Tap to Unhold' : 'Hold Reason',
                    ),
                  ),

                  // NO ORDER REASON
                  _TapScale(
                    onTap: _pickNoOrderReason,
                    child: _CategoryCard(
                      icon: Icons.visibility_off_rounded,
                      title: 'No Order Reason',
                      subtitle: noOrderReason == null ? 'Select Reason' : noOrderReason!,
                    ),
                  ),

                  // COLLECT PAYMENT (enable only if checked-in & not on hold)
                  _TapScale(
                    onTap: () {
                      if (!isCheckedIn) {
                        toastWidget("Please Check-In first", Colors.red);
                        return;
                      }
                      if (isHold) {
                        toastWidget("Unhold first to collect payment", Colors.red);
                        return;
                      }
                      // TODO: Navigate to payment screen
                    },
                    child: const _CategoryCard(
                      icon: Icons.payments_rounded,
                      title: 'Collect Payment',
                      subtitle: 'Invoices',
                    ),
                  ),

                  // SALE HISTORY (allow only if checked-in or as you prefer)
                  _TapScale(
                    onTap: () {
                      if (!isCheckedIn) {
                        toastWidget("Please Check-In first", Colors.red);
                        return;
                      }
                      // TODO: navigate to sale history
                    },
                    child: const _CategoryCard(
                      icon: Icons.history_rounded,
                      title: 'Sale History',
                      subtitle: 'History',
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/

// ====== UI helpers (unchanged) =================================================




/*class OrderMenuScreen extends StatefulWidget {
  final String shopname, miscid, address;
  const OrderMenuScreen({
    super.key,
    required this.shopname,
    required this.miscid,
    required this.address,
  });

  @override
  State<OrderMenuScreen> createState() => _OrderMenuScreenState();
}

class _OrderMenuScreenState extends State<OrderMenuScreen> {

    static const Color orange = Color(0xFFEA7A3B);
  static const Color text = Color(0xFF1E1E1E);
  static const Color muted = Color(0xFF707883);
  static const Color field = Color(0xFFF5F5F7);
  static const Color card = Colors.white;
  static const Color accent = Color(0xFFE97C42);
  static const Color _shadow = Color(0x14000000);
  String checkInText = "Check In";
  String iconAsset = "assets/checkin_order.png";
  final loc.Location location = loc.Location();

  void _toggleCheckIn() {
    setState(() {
      if (checkInText == "Check In") {
        checkInText = "Check Out";
        iconAsset = "assets/checkout_order.png";
      } else {
        checkInText = "Check In";
        iconAsset = "assets/checkin_order.png";
      }
    });
  }

  String? selectedOption;

  Future<String?> showHoldReasonDialog(BuildContext context) async {
  int selectedIndex = -1; // none selected initially
  final List<String> holdReasons = const [
    "Purchaser Not Available",
    "Tea Time",
    "Lunch Time",
  ];

  String? chosen;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final t = Theme.of(context).textTheme;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: Colors.transparent, // for gradient frame
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [orange, Color(0xFFFFB07A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            margin: const EdgeInsets.all(1.8),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: _shadow,
                  blurRadius: 16,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      decoration: const BoxDecoration(
                        color: field,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Text(
                        "Select Hold Reason",
                        textAlign: TextAlign.center,
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: text,
                        ),
                      ),
                    ),

                    // Options
                    Flexible(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        shrinkWrap: true,
                        itemCount: holdReasons.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 2),
                        itemBuilder: (_, index) {
                          return RadioListTile<int>(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                            visualDensity: VisualDensity.compact,
                            activeColor: orange,
                            title: Text(
                              holdReasons[index],
                              style: t.bodyMedium?.copyWith(
                                color: text,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            value: index,
                            groupValue: selectedIndex,
                            onChanged: (v) => setState(() => selectedIndex = v ?? -1),
                          );
                        },
                      ),
                    ),

                    // Actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: muted,
                                side: BorderSide(color: muted.withOpacity(.35)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("Cancel"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: selectedIndex == -1
                                  ? null
                                  : () {
                                      chosen = holdReasons[selectedIndex];
                                      Navigator.of(context).pop();
                                    },
                              child: const Text("Select Reason"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );

  return chosen; 
}


  Future<String?> showNoOrderReasonDialog(BuildContext context) async {
  int selectedIndex = -1; 
  final List<String> noOrder = const [
    "No Order",
    "Credit Not Alowed",
    "Shop Closed",
    "Stock Available",
    "No Order With Collection",
    "Visit For Collection",
  ];

  String? chosen;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final t = Theme.of(context).textTheme;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: Colors.transparent, // gradient frame
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [orange, Color(0xFFFFB07A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            margin: const EdgeInsets.all(1.8),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: _shadow,
                  blurRadius: 16,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      decoration: const BoxDecoration(
                        color: field,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Text(
                        "Select No Order Reason",
                        textAlign: TextAlign.center,
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: text,
                        ),
                      ),
                    ),

                    // Reasons
                    Flexible(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        shrinkWrap: true,
                        itemCount: noOrder.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 2),
                        itemBuilder: (_, index) {
                          return RadioListTile<int>(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                            visualDensity: VisualDensity.compact,
                            activeColor: orange,
                            title: Text(
                              noOrder[index],
                              style: t.bodyMedium?.copyWith(
                                color: text,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            value: index,
                            groupValue: selectedIndex,
                            onChanged: (v) => setState(() => selectedIndex = v ?? -1),
                          );
                        },
                      ),
                    ),

                    // Actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: muted,
                                side: BorderSide(color: muted.withOpacity(.35)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("Cancel"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: selectedIndex == -1
                                  ? null
                                  : () {
                                      chosen = noOrder[selectedIndex];
                                      Navigator.of(context).pop();
                                    },
                              child: const Text("Select Reason"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );

  return chosen; 
}





  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  height: 179,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kOrange, kOrangeLite],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 45, 16, 0),
                  child: _GlassHeader(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.20),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 1.2),
                              ),
                              child: const Icon(Icons.store_rounded,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.shopname,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: t.titleMedium?.copyWith(
                                        color: Colors.white.withOpacity(.97),
                                        fontWeight: FontWeight.w700,
                                      )),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.place_rounded,
                                          size: 16,
                                          color: Colors.white.withOpacity(.9)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          widget.address,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: t.bodySmall?.copyWith(
                                            color:
                                                Colors.white.withOpacity(.95),
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // status chips
                        Row(
                          children: [
                            _Chip(
                              label: checkInText == "Check In"
                                  ? "Not Checked-In"
                                  : "Checked-In",
                              icon: checkInText == "Check In"
                                  ? Icons.radio_button_unchecked
                                  : Icons.check_circle,
                              color: checkInText == "Check In"
                                  ? Colors.white.withOpacity(.20)
                                  : Colors.white.withOpacity(.30),
                              textColor: Colors.white,
                              borderColor: Colors.white.withOpacity(.45),
                            ),
                            const SizedBox(width: 8),
                            _Chip(
                              label: "Shop ID: ${widget.miscid}",
                              icon: Icons.confirmation_number_outlined,
                              color: Colors.white.withOpacity(.14),
                              textColor: Colors.white,
                              borderColor: Colors.white.withOpacity(.45),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

/*          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.pause_circle_filled_rounded,
                      label: 'Hold',
                      onTap: () => showHoldReasonDialog(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.block_flipped,
                      label: 'No Order',
                      onTap: () => showNoOrderReasonDialog(context),
                    ),
                  ),
                ],
              ),
            ),
          ),*/

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              delegate: SliverChildListDelegate.fixed([
                // CHECK-IN tile
                _TapScale(
                  onTap: () async {
                    final currentLocation = await location.getLocation();
                    _toggleCheckIn();
                    context.read<GlobalBloc>().add(
                          CheckinCheckoutEvent(
                            type: '5',
                            userId: context
                                .read<GlobalBloc>()
                                .state
                                .loginModel!
                                .userinfo!
                                .userId
                                .toString(),
                            lat: currentLocation.latitude.toString(),
                            lng: currentLocation.longitude.toString(),
                            act_type: "SHOP_CHECK",
                            action: checkInText == "Check Out" ? "IN" : "OUT",
                            misc: widget.miscid,
                            dist_id: context
                                .read<GlobalBloc>()
                                .state
                                .loginModel!
                                .userinfo!
                                .disid
                                .toString(),
                          ),
                        );
                  },
                  child: _CategoryCard(
                    icon: Icons.access_time,
                    title: checkInText,
                    subtitle:
                        'Shop ${checkInText == "Check In" ? "Checkin" : "Checkout"}',
                  ),
                ),

                // TAKE ORDER
                _TapScale(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MeezanTeaCatalog()),
                    );
                  },
                  child: const _CategoryCard(
                    icon: Icons.playlist_add_check_rounded,
                    title: 'Take Order',
                    subtitle: 'Orders',
                  ),
                ),

                // HOLD
                _TapScale(
                  onTap: () => showHoldReasonDialog(context),
                  child: const _CategoryCard(
                    icon: Icons.pause_rounded,
                    title: 'Hold',
                    subtitle: 'Hold Reason',
                  ),
                ),

                // NO ORDER REASON
                _TapScale(
                  onTap: () => showNoOrderReasonDialog(context),
                  child: const _CategoryCard(
                    icon: Icons.visibility_off_rounded,
                    title: 'No Order Reason',
                    subtitle: 'Select Reason',
                  ),
                ),

                // COLLECT PAYMENT
                _TapScale(
                  onTap: () {
                    // TODO: implement
                  },
                  child: const _CategoryCard(
                    icon: Icons.payments_rounded,
                    title: 'Collect Payment',
                    subtitle: 'Place new order',
                  ),
                ),

                // SALE HISTORY
                _TapScale(
                  onTap: () {
                    // TODO: navigate to sale history
                  },
                  child: const _CategoryCard(
                    icon: Icons.history_rounded,
                    title: 'Sale History',
                    subtitle: 'History',
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────
// WIDGETS
// ───────────────────────────────────────────────────────────────────────────────

class _GlassHeader extends StatelessWidget {
  const _GlassHeader({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color borderColor;

  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              )),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kCard,
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEDEFF2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kOrange, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: kText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kOrange, kOrangeLite],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.8),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14.2),
          boxShadow: const [
            BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10)),
          ],
          border: Border.all(color: const Color(0xFFEDEFF2)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: kField,
              shape: const CircleBorder(),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(icon, color: kOrange),
              ),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.titleSmall?.copyWith(
                color: kText,
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall?.copyWith(color: kMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TapScale extends StatefulWidget {
  const _TapScale({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _down(TapDownDetails _) => setState(() => _scale = .98);
  void _up([_]) => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapCancel: _up,
      onTapUp: _up,
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
*/

// class OrderMenuScreen extends StatefulWidget {
//   String shopname, miscid,address;
//   OrderMenuScreen({super.key, required this.shopname, required this.miscid,required this.address});

//   @override
//   State<OrderMenuScreen> createState() => _OrderMenuScreenState();
// }

// class _OrderMenuScreenState extends State<OrderMenuScreen> {
//   String checkInText = "Check In";
//   String iconAsset = "assets/checkin_order.png";
//   final loc.Location location = loc.Location();

//   void _toggleCheckIn() {
//     setState(() {
//       if (checkInText == "Check In") {
//         checkInText = "Check Out";
//         iconAsset = "assets/checkout_order.png";
//       } else {
//         checkInText = "Check In";
//         iconAsset = "assets/checkin_order.png";
//       }
//     });
//   }

//   String? selectedOption; 

//   Future<void> showHoldDialog(BuildContext context) async {
//     int selectedValue = 0;

//     List<String> holdText = [
//       "Purchaser Not Available",
//       "Tea Time",
//       "Lunch Time",
//     ];

//     await showDialog(
//       context: context,
//       builder: (context) {
//         return Dialog(
//           backgroundColor: Colors.white, 
//           shape: const RoundedRectangleBorder(
//             borderRadius: BorderRadius.zero,
//           ),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 8,
//               vertical: 12,
//             ), 
//             child: StatefulBuilder(
//               builder: (context, setState) {
//                 return Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Center(child: Text("Select Hold Reason!")),
            
//                     const SizedBox(height: 8),
//                     ...List.generate(holdText.length, (index) {
//                       return RadioListTile<int>(
//                         dense: true, 
//                         contentPadding: EdgeInsets.zero,
//                         visualDensity: VisualDensity.compact, 
//                         title: Text(
//                           holdText[index],
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w300,
//                           ),
//                         ),
//                         value: index,
//                         groupValue: selectedValue,
//                         onChanged: (value) {
//                           setState(() {
//                             selectedValue = value!;
//                           });
//                           Navigator.of(context).pop();
//                         },
//                       );
//                     }),
                  
//                   ],
//                 );
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Future<void> noOrderReason(BuildContext context) async {
//     int selectedValue = 0;

//     List<String> noOrder = [
//       "No Order",
//       "Credit Not Alowed",
//       "Shop Closed",
//       "Stock Available",
//       "No Order With Collection",
//       "Visit For Collection",
//     ];

//     await showDialog(
//       context: context,
//       builder: (context) {
//         return Dialog(
//           backgroundColor: Colors.white, // White only
//           shape: const RoundedRectangleBorder(
//             borderRadius: BorderRadius.zero, // No rounded corners
//           ),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 8,
//               vertical: 12,
//             ), // Reduced padding
//             child: StatefulBuilder(
//               builder: (context, setState) {
//                 return Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Center(child: Text("Select No Order Reason!")),
//                     // const Text(
//                     //   "Choose an Option",
//                     //   style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//                     // ),
//                     const SizedBox(height: 8),
//                     ...List.generate(noOrder.length, (index) {
//                       return RadioListTile<int>(
//                         dense: true, // Compact style
//                         contentPadding: EdgeInsets.zero, // No extra padding
//                         visualDensity: VisualDensity.compact, // Reduce spacing
//                         title: Text(
//                           noOrder[index],
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w300,
//                           ),
//                         ),
//                         value: index,
//                         groupValue: selectedValue,
//                         onChanged: (value) {
//                           setState(() {
//                             selectedValue = value!;
//                           });
//                           Navigator.of(context).pop();
//                         },
//                       );
//                     }),
//                     // Align(
//                     //   alignment: Alignment.centerRight,
//                     //   child: TextButton(
//                     //     onPressed: () => Navigator.pop(context, selectedValue),
//                     //     child: const Text("OK"),
//                     //   ),
//                     // ),
//                   ],
//                 );
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }

  


//   @override
//   Widget build(BuildContext context) {
//     const kText = Color(0xFF1E1E1E);
//     final t = Theme.of(context).textTheme;
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         centerTitle: false,
//         title: Text(
//           'Order Menu',
//           style: t.titleLarge?.copyWith(
//             color: kText,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),

//       body: CustomScrollView(
//     physics: const BouncingScrollPhysics(),
//         slivers:[ 
//           SliverToBoxAdapter(
//                 child: Stack(
//                   children: [
//                     Container(
//                       height: 90,
//                      // width: MediaQuery.of(context).size.width*0.99,
//                       decoration: const BoxDecoration(
//                         gradient: LinearGradient(
//                         // colors: [Colors.grey,Colors.grey],
//                           colors: [Color(0xffFF7518), Color(0xFFFFB07A)],
//                           //  colors: [orange, Color(0xFFFFB07A)],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                       ),
//                     ),

//                     Padding(
//                       padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
//                       child: _GlassHeader(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Container(
//                                   width: 40,
//                                   height: 40,
//                                   decoration: BoxDecoration(
//                                     color: Colors.white.withOpacity(.20),
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: Colors.white,
//                                       width: 1.2,
//                                     ),
//                                   ),
//                                   child: const Icon(
//                                     Icons.shop_sharp,
//                                     color: Colors.white,
//                                     size: 20,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 14),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         widget.shopname,
//                                         style: t.titleMedium?.copyWith(
//                                           color: Colors.white.withOpacity(.95),
//                                           fontWeight: FontWeight.w600,
//                                           height: 1.1,
//                                         ),
//                                       ),
//                                             Text(
//                                         widget.address,
//                                         style: t.titleMedium?.copyWith(
//                                           color: Colors.white.withOpacity(.95),
//                                           fontWeight: FontWeight.w600,
//                                           height: 1.1,
//                                         ),
//                                       ),
                            
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
                          
//                           ],
//                         ),
//                       ),
//                     ),
              
//                   ],
//                 ),
//               ),

//           SliverPadding(
//                 padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
//                 sliver: SliverGrid(
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     crossAxisSpacing: 14,
//                     mainAxisSpacing: 14,
//                     childAspectRatio: 1.10,
//                   ),
//                   delegate: SliverChildListDelegate.fixed([

                      
//                     _TapScale(
//                                   onTap: () async {
//                                 final currentLocation = await location
//                                     .getLocation();
//                                 _toggleCheckIn();
//                                 context.read<GlobalBloc>().add(
//                                   CheckinCheckoutEvent(
//                                     type: '5',
//                                     userId: context
//                                         .read<GlobalBloc>()
//                                         .state
//                                         .loginModel!
//                                         .userinfo!
//                                         .userId
//                                         .toString(),
//                                     lat: currentLocation.latitude.toString(),
//                                     lng: currentLocation.longitude.toString(),
//                                     act_type: "SHOP_CHECK",
//                                     action: "IN",
//                                     misc: widget.miscid,
//                                     dist_id: context
//                                         .read<GlobalBloc>()
//                                         .state
//                                         .loginModel!
//                                         .userinfo!
//                                         .disid
//                                         .toString(),
//                                   ),
//                                 );
//                               },
//                       child: const _CategoryCard(
//                         icon: Icons.access_time,
//                         title: 'Checkin',
//                         subtitle: 'Shop Checkin',
//                       ),
//                     ),
//                     _TapScale(
//                       onTap: () {
//                Navigator.push(context, MaterialPageRoute(builder: (context)=> MeezanTeaCatalog()));
//                       },
//                       child: const _CategoryCard(
//                         icon: Icons.alt_route,
//                         title: 'Take Order',
//                         subtitle: 'Orders',
//                       ),
//                     ),
//                     _TapScale(
//                       onTap: () {
//                         showHoldDialog(context);
                  
//                       },
//                       child: const _CategoryCard(
//                         icon: Icons.shopping_cart,
//                         title: 'Hold',
//                         subtitle: 'Hold Reason',
//                       ),
//                     ),
//                     InkWell(
//                       onTap: () {
//                    noOrderReason(context);
//                       },
//                       child: const _CategoryCard(
//                         icon: Icons.insert_drive_file,
//                         title: 'No Order Reason',
//                         subtitle: 'Select Reason',
//                       ),
//                     ),

//                       _TapScale(
//                       onTap: () {
                   
//                       },
//                       child: const _CategoryCard(
//                         icon: Icons.shopping_cart,
//                         title: 'Collect Payment',
//                         subtitle: 'Place new order',
//                       ),
//                     ),
//                     InkWell(
//                       onTap: () {
                  
//                       },
//                       child: const _CategoryCard(
//                         icon: Icons.insert_drive_file,
//                         title: 'Sale History',
//                         subtitle: 'History',
//                       ),
//                     ),
//                   ]),
//                 ),
//               ),


//          ])
//     );
//   }

  

//   Widget _buildStatCard({
//     required String title,
//     required String iconName,
//     required Color color1,
//     required Color color2,
//     required double height,
//     required double width,
//   }) {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.15,
//       width: MediaQuery.of(context).size.width * 0.40,
//       //   padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [color1, color2],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: color1.withOpacity(0.4),
//             blurRadius: 6,
//             offset: const Offset(2, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Image.asset(iconName, height: height, width: width),
//           const SizedBox(height: 4),
//           Text(title, style: TextStyle(fontSize: 14, color: Colors.white)),
//         ],
//       ),
//     );
//   }
// }

// class _GlassHeader extends StatelessWidget {
//   const _GlassHeader({required this.child});
//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(18),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(.18),
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }
// }



// class _CategoryCard extends StatelessWidget {
//   const _CategoryCard({required this.icon, required this.title, this.subtitle});

//   final IconData icon;
//   final String title;
//   final String? subtitle;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//    const Color orange = Color(0xFFEA7A3B);
//    const Color text = Color(0xFF1E1E1E);
//    const Color muted = Color(0xFF707883);
//    const Color field = Color(0xFFF5F5F7);
//    const Color card = Colors.white;
//    const Color accent = Color(0xFFE97C42);
//    const Color _shadow = Color(0x14000000);

//     return DecoratedBox(
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [orange, Color(0xFFFFB07A)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Container(
//         margin: const EdgeInsets.all(1.8),
//         decoration: BoxDecoration(
//           color: card,
//           borderRadius: BorderRadius.circular(14.2),
//           boxShadow: const [
//             BoxShadow(
//               color: _shadow,
//               blurRadius: 16,
//               offset: Offset(0, 10),
//             ),
//           ],
//         ),
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Material(
//               color: field,
//               shape: const CircleBorder(),
//               child: SizedBox(
//                 width: 46,
//                 height: 46,
//                 child: Icon(icon, color: orange),
//               ),
//             ),
//             const Spacer(),
//             Text(
//               title,
//               style: t.titleSmall?.copyWith(
//                 color: text,
//                 fontWeight: FontWeight.w600,
//                 letterSpacing: .2,
//               ),
//             ),
//             // if (subtitle != null) ...[
//             //   const SizedBox(height: 2),
//             //   Text(
//             //     subtitle!,
//             //     maxLines: 1,
//             //     overflow: TextOverflow.ellipsis,
//             //     style: t.bodySmall?.copyWith(color:muted),
//             //   ),
//             // ],
//           ],
//         ),
//       ),
//     );
//   }
// }


// class _TapScale extends StatefulWidget {
//   const _TapScale({super.key, required this.child, required this.onTap});
//   final Widget child;
//   final VoidCallback onTap;

//   @override
//   State<_TapScale> createState() => _TapScaleState();
// }

// class _TapScaleState extends State<_TapScale>
//     with SingleTickerProviderStateMixin {
//   double _scale = 1.0;

//   void _down(TapDownDetails _) => setState(() => _scale = .98);
//   void _up([_]) => setState(() => _scale = 1.0);

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTapDown: _down,
//       onTapCancel: _up,
//       onTapUp: _up,
//       onTap: widget.onTap,
//       child: AnimatedScale(
//         duration: const Duration(milliseconds: 100),
//         scale: _scale,
//         child: widget.child,
//       ),
//     );
//   }
// }
