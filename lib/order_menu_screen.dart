import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:location/location.dart' as loc;
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';
import 'package:motives_new_ui_conversion/invoices_screen.dart';
import 'package:motives_new_ui_conversion/products_items_screen.dart';
import 'package:motives_new_ui_conversion/sales_history_screen.dart';

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
  bool get _isOrderPlaced => _statusForShop().ordered;

  bool get _allowCheckInAgain =>
      !_isLockedNoVisit && !_isOrderPlaced; // 👈 block when ordered

  final box = GetStorage();
  final loc.Location location = loc.Location();

  String checkInText = "Check In";
  bool _hasReasonSelected = false;
  bool _holdToggleVisual = false;

  String lat = "0", lng = "0";

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

  Map<String, dynamic> _loadStatusMap() {
    final raw = box.read('journey_status');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Future<void> _saveStatus({
    required bool checkedIn,
    required VisitLast last,
    bool? holdUi,
    bool? ordered,
  }) async {
    final map = _loadStatusMap();
    map[widget.miscid] = {
      'checkedIn': checkedIn,
      'last': last == VisitLast.hold
          ? 'hold'
          : (last == VisitLast.noVisit ? 'no_visit' : 'none'),
      'holdUI': holdUi ?? _holdToggleVisual,
      'ordered': ordered ?? _statusForShop().ordered, // 👈 keep previous
    };
    await box.write('journey_status', map);
  }

  // Future<void> _saveStatus({
  //   required bool checkedIn,
  //   required VisitLast last,
  //   bool? holdUi,
  // }) async {
  //   final map = _loadStatusMap();
  //   map[widget.miscid] = {
  //     'checkedIn': checkedIn,
  //     'last': last == VisitLast.hold
  //         ? 'hold'
  //         : (last == VisitLast.noVisit ? 'no_visit' : 'none'),
  //     'holdUI': holdUi ?? _holdToggleVisual,
  //   };
  //   await box.write('journey_status', map);
  // }

  // ({bool checkedIn, VisitLast last, bool holdUi}) _statusForShop() {
  //   final map = _loadStatusMap();
  //   final s = map[widget.miscid];
  //   if (s is Map) {
  //     return (
  //       checkedIn: (s['checkedIn'] == true),
  //       last: _parseLast(s['last'] as String?),
  //       holdUi: (s['holdUI'] == true),
  //     );
  //   }
  //   return (checkedIn: false, last: VisitLast.none, holdUi: false);
  // }

  ({bool checkedIn, VisitLast last, bool holdUi, bool ordered})
  _statusForShop() {
    final map = _loadStatusMap();
    final s = map[widget.miscid];
    if (s is Map) {
      return (
        checkedIn: (s['checkedIn'] == true),
        last: _parseLast(s['last'] as String?),
        holdUi: (s['holdUI'] == true),
        ordered: (s['ordered'] == true), // 👈 new
      );
    }
    return (
      checkedIn: false,
      last: VisitLast.none,
      holdUi: false,
      ordered: false,
    );
  }

  Map<String, String> _loadReasonMap() {
    final raw = box.read('journey_reasons');
    if (raw is Map) {
      return raw.map<String, String>(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
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
  // bool get _allowCheckInAgain => !_isLockedNoVisit;

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
    } catch (_) {
      /* ignore */
    }
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
              Text(
                message,
                style: Theme.of(
                  parentCtx,
                ).textTheme.bodyMedium?.copyWith(color: kText),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(button),
                ),
              ),
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
              Text(
                message,
                style: Theme.of(
                  parentCtx,
                ).textTheme.bodyMedium?.copyWith(color: kText),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kMuted,
                        side: BorderSide(color: kMuted.withOpacity(.35)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                      title: Text(
                        options[i],
                        style: t.bodyMedium?.copyWith(color: kText),
                      ),
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
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                              borderRadius: BorderRadius.circular(12),
                            ),
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
        message: 'Unhold first to continue.',
      );
      return;
    }
    if (!_isCheckedIn) {
      _showThemedInfo(
        parentCtx: context,
        title: 'Check-In Required',
        message: 'Please check in first.',
      );
      return;
    }
    action();
  }

  @override
  void initState() {
    super.initState();

    // // your debug prints
    // print('CHECK CREDIT LIMIT ${widget.checkCredit}');
    // print('CHECK CREDIT LIMIT ${widget.checkCredit}');
    // print('CHECK CREDIT LIMIT ${widget.checkCredit}');
    // print('CHECK CREDIT LIMIT ${widget.checkCredit}');

    // // activity log
    context.read<GlobalBloc>().add(
      Activity(activity: 'Visited Shop ${widget.shopname}'),
    );

    // your existing status logic
    final st = _statusForShop();
    final effectiveCheckedIn = st.last == VisitLast.hold ? true : st.checkedIn;
    checkInText = effectiveCheckedIn ? "Check Out" : "Check In";
    _holdToggleVisual = st.holdUi || st.last == VisitLast.hold;
    _hasReasonSelected = !effectiveCheckedIn || st.last != VisitLast.none;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // location
      if (_markLocationOn) await _getLocation();

      // 🔽 Invoices: fire once only if not already loaded
      final bloc = context.read<GlobalBloc>();
      final state = bloc.state;

      // Using shop id (miscid) as acode; adjust if your plan object has a dedicated acode
      final acode = (widget.miscid).trim();
      final disid = (state.loginModel?.userinfo?.disid?.toString() ?? '')
          .trim();

      final alreadyLoaded =
          state.invoicesStatus == InvoicesStatus.success &&
          state.invoices.isNotEmpty;

      if (!alreadyLoaded && acode.isNotEmpty && disid.isNotEmpty) {
        debugPrint('➡️ Loading invoices for acode=$acode, disid=$disid');
        bloc.add(LoadShopInvoicesRequested(acode: acode, disid: disid));
      } else {
        debugPrint(
          '✅ Invoices already loaded or missing params. Skipping fetch.',
        );
      }
    });
  }

  //   @override
  //   void initState() {
  //     super.initState();
  // print('CHECK CREDIT LIMIT ${widget.checkCredit}');
  // print('CHECK CREDIT LIMIT ${widget.checkCredit}');
  // print('CHECK CREDIT LIMIT ${widget.checkCredit}');
  // print('CHECK CREDIT LIMIT ${widget.checkCredit}');
  //     context
  //         .read<GlobalBloc>()
  //         .add(Activity(activity: 'Visited Shop ${widget.shopname}'));
  //     final st = _statusForShop();
  //     final effectiveCheckedIn = st.last == VisitLast.hold ? true : st.checkedIn;
  //     checkInText = effectiveCheckedIn ? "Check Out" : "Check In";
  //     _holdToggleVisual = st.holdUi || st.last == VisitLast.hold;
  //     _hasReasonSelected = !effectiveCheckedIn || st.last != VisitLast.none;

  //     WidgetsBinding.instance.addPostFrameCallback((_) async {
  //       if (_markLocationOn) await _getLocation();
  //     });
  //   }

  Future<void> _pickHold() async {
    final parentCtx = context;

    // need location first if rights say so
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

    // ───────── PLACE ON HOLD ─────────
    if (!shopStatusIsHold) {
      // load HOLD reasons from API/login
      final options = _reasonsOfType("HOLD");
      if (options.isEmpty) {
        await _showThemedInfo(
          parentCtx: parentCtx,
          title: 'No Options',
          message: 'No HOLD reasons available.',
        );
        return;
      }

      // user picks a reason
      final chosen = await _showThemedReasonPicker(
        parentCtx: parentCtx,
        dialogTitle: "Select Hold Reason",
        options: options,
      );
      if (chosen == null) return;

      // confirm hold
      await _showThemedConfirm(
        parentCtx: parentCtx,
        title: 'Confirm Hold',
        message: 'Place this shop on HOLD for reason "$chosen"?',
        onYes: () async {
          await _getLocation();

          // 1) send HOLD = type:9
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

          // 2) save selected reason locally
          await _saveReason(chosen);

          // 3) store status as "last = hold" and checked-out
          _holdToggleVisual = false;
          checkInText = "Check In";
          _hasReasonSelected = true; // ✅ at this point user DID select a reason
          await _saveStatus(
            checkedIn: false,
            last: VisitLast.hold,
            holdUi: false,
          );

          if (mounted) setState(() {});
          if (mounted) {
            Navigator.of(
              parentCtx,
            ).pop({'miscid': widget.miscid, 'kind': 'hold', 'reason': chosen});
          }
        },
      );

      return;
    }

    // ───────── UNHOLD ─────────
    await _showThemedConfirm(
      parentCtx: parentCtx,
      title: 'Unhold Shop',
      message: 'Remove HOLD and continue?',
      onYes: () async {
        await _getLocation();

        // send UNHOLD = type:10
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

        // 🔴 now user is back inside the shop, so FORCE an action
        _holdToggleVisual = false;
        checkInText = "Check Out"; // user is considered inside
        _hasReasonSelected =
            false; // ✅ so back button will show "Action Required"

        await _saveStatus(checkedIn: true, last: VisitLast.none, holdUi: false);

        if (mounted) setState(() {});
      },
    );
  }

  /*  Future<void> _pickHold() async {
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
  }*/

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
        message: 'No NO-VISIT reasons available.',
      );
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
        context.read<GlobalBloc>().add(
          CheckinCheckoutEvent(
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
          ),
        );
        // CHECK OUT (type 6)
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

        await _saveReason(chosen);
        await _saveStatus(
          checkedIn: false,
          last: VisitLast.noVisit,
          holdUi: false,
        );
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
            ScaffoldMessenger.of(
              ctx,
            ).showSnackBar(const SnackBar(content: Text('Synced ✅')));
            break;

          case CheckinCheckoutStatus.queued: // ← NEW
            _hideBlockingLoader(ctx);
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('Saved offline. Will sync when online 🔄'),
              ),
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
                                      color: Colors.white,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.store_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.shopname,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.titleMedium?.copyWith(
                                          color: Colors.white.withOpacity(.97),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.place_rounded,
                                            size: 16,
                                            color: Colors.white.withOpacity(.9),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              widget.address,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: t.bodySmall?.copyWith(
                                                color: Colors.white.withOpacity(
                                                  .95,
                                                ),
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
                            message: 'Unhold first to continue.',
                          );
                          return;
                        }
                        // Lock checkout until a reason is selected
                        if (checkInText == "Check In" && !_allowCheckInAgain) {
                          await _showThemedInfo(
                            parentCtx: context,
                            title: 'Not Allowed',
                            message: _isOrderPlaced
                                ? 'Re-check in is not allowed (order already placed).'
                                : 'Re-check in is not allowed (No Visit selected earlier).',
                          );
                          return;
                        }
                        // if (checkInText == "Check Out" && _checkoutLocked) {
                        //   await _showThemedInfo(
                        //     parentCtx: context,
                        //     title: 'Reason Required',
                        //     message:
                        //         'Select a reason (Hold / No Visit) before checking out.',
                        //   );
                        //   return;
                        // }
                        if (checkInText == "Check In" && !_allowCheckInAgain) {
                          await _showThemedInfo(
                            parentCtx: context,
                            title: 'Not Allowed',
                            message:
                                'Re-check in is not allowed (No Visit selected earlier).',
                          );
                          return;
                        }
                        if (_markLocationOn && (lat == "0" || lng == "0")) {
                          await _showThemedInfo(
                            parentCtx: context,
                            title: 'Location',
                            message:
                                "Can't get location. Please open Google Maps blue dot.",
                          );
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
                                holdUi: _holdToggleVisual,
                              );
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
                                holdUi: _holdToggleVisual,
                              );
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

                    _TapScale(
                      onTap: () => _guardRequireCheckIn(() async {
                        final res = await Navigator.push<Map<String, dynamic>>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MeezanTeaCatalog(
                              shopId: widget.miscid,
                              creditBoolean: widget.checkCredit.toString(),
                            ),
                          ),
                        );

                        if (res is Map &&
                            res!['miscid'] == widget.miscid &&
                            (res['reason'] ?? '') == 'ORDER PLACED') {
                          await _saveReason('ORDER PLACED');
                          await _saveStatus(
                            checkedIn: false,
                            last: VisitLast.none,
                            holdUi: false,
                            ordered: true, // 👈 mark shop as ordered
                          );
                          setState(() {
                            checkInText = 'Check In';
                            _hasReasonSelected = true;
                          });
                          if (mounted) Navigator.pop(context, res);
                        }

                        // final res = await Navigator.push<Map<String, dynamic>>(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (_) => MeezanTeaCatalog(shopId: widget.miscid,creditBoolean: widget.checkCredit.toString()),
                        //   ),
                        // );

                        // if (res is Map &&
                        //     res!['miscid'] == widget.miscid &&
                        //     (res['reason'] ?? '') == 'ORDER PLACED') {
                        //   // update local UI + storage
                        //   await _saveReason('ORDER PLACED');
                        //   await _saveStatus(
                        //     checkedIn: false,
                        //     last: VisitLast.none,
                        //     holdUi: false,
                        //   );
                        //   setState(() {
                        //     checkInText = 'Check In';
                        //     _hasReasonSelected = true;
                        //   });

                        //   // ⬅️ that's it – events are sent from the order screen (where we have order_id)
                        //   if (mounted) {
                        //     Navigator.pop(context, res);
                        //   }
                        // }
                      }),
                      child: const _CategoryCard(
                        icon: Icons.playlist_add_check_rounded,
                        title: 'Take Order',
                        subtitle: 'Orders',
                      ),
                    ),

                    _TapScale(
                      onTap: () {
                        if (!_isCheckedIn) {
                          _showThemedInfo(
                            parentCtx: context,
                            title: 'Check-In Required',
                            message: 'Please check in first.',
                          );
                          return;
                        }
                        _pickHold();
                      },
                      child: _CategoryCard(
                        icon: _holdToggleVisual
                            ? Icons.play_circle_outline
                            : Icons.pause_rounded,
                        title: _holdToggleVisual ? 'Unhold' : 'Hold',
                        subtitle: _holdToggleVisual
                            ? 'Tap to Unhold'
                            : 'Hold Reason',
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InvoicesScreen(
                              acode: widget.miscid,
                              disid: context
                                  .read<GlobalBloc>()
                                  .state
                                  .loginModel!
                                  .userinfo!
                                  .disid
                                  .toString(),
                            ),
                          ),
                        );
                      },
                      // onTap: () => _guardRequireCheckIn(() async {
                      //   if (!_markInvoicesOn) {
                      //     await _showThemedInfo(
                      //         parentCtx: context,
                      //         title: 'Not Allowed',
                      //         message:
                      //             "You don't have rights to view invoices!");
                      //     return;
                      //   }
                      //   _toast('Invoices tapped'); // TODO: Navigate
                      // }),
                      child: const _CategoryCard(
                        icon: Icons.payments_rounded,
                        title: 'Collect Payment',
                        subtitle: 'Invoices',
                      ),
                    ),

                    // Sale History
                    _TapScale(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SalesHistoryScreen(
                              acode: widget.miscid,
                              disid: context
                                  .read<GlobalBloc>()
                                  .state
                                  .loginModel!
                                  .userinfo!
                                  .disid
                                  .toString(),
                            ),
                          ),
                        );
                      },
                      // onTap: () => _guardRequireCheckIn(() {
                      //   _toast('History tapped'); // TODO: Navigate
                      // }),
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
      ),
    );
  }
}

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
              BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10)),
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
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: kText,
                  ),
                ),
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
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
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
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.8),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14.2),
          boxShadow: const [
            BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10)),
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
