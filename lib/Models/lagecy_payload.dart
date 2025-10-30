import 'dart:math';

import 'package:motives_new_ui_conversion/products_items_screen.dart'; // 👈 needed for Random.secure()

String _uuidv4() {
  final r = Random.secure();
  String h(int n) => n.toRadixString(16).padLeft(2, '0');
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant
  return '${h(b[0])}${h(b[1])}${h(b[2])}${h(b[3])}-'
      '${h(b[4])}${h(b[5])}-'
      '${h(b[6])}${h(b[7])}-'
      '${h(b[8])}${h(b[9])}-'
      '${h(b[10])}${h(b[11])}${h(b[12])}${h(b[13])}${h(b[14])}${h(b[15])}';
}

/// 14-jan-19 format (dd-mmm-yy, month lowercase)
String _ddMmmYyLower(DateTime dt) {
  const m = [
    'jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'
  ];
  final dd = dt.day.toString().padLeft(2, '0');
  final mon = m[dt.month - 1];
  final yy = (dt.year % 100).toString().padLeft(2, '0');
  return '$dd-$mon-$yy';
}

/// Build legacy order payload (NO hardcoded business fields).
///
/// You MUST pass all header fields yourself from Bloc / login:
///
/// - userId         → login.userinfo.userId
/// - distId         → login.distributors.first.id
/// - accCode        → selected customer / journey plan accode
/// - segmentId      → distributor.segment OR userinfo.segment
/// - compId         → distributor.compid OR userinfo.compid
/// - orderBookerId  → login.userinfo.obid
/// - paymentType    → usually "CR"
/// - headerOrderType→ usually "OR"
/// - orderStatus    → usually "N"
///
/// The only things auto-generated here:
///   - unique (if you don’t pass it)
///   - date   (today, in dd-mmm-yy)
Map<String, dynamic> buildLegacyOrderPayloadFromTea({
  // catalog + cart
  required List<TeaItem> allItems,
  required Map<String, int> cart,

  // HEADER (all required — no hardcode)
  required String userId,
  required String distId,
  required String accCode,
  required String segmentId,
  required String compId,
  required String orderBookerId,
  required String paymentType,
  required String headerOrderType, // e.g. "OR"
  required String orderStatus,     // e.g. "N"

  // optional
  DateTime? date,
  String? unique,

  // optional extras
  String? appSource,
  String? deviceId,
}) {
  final orderLines = <Map<String, dynamic>>[];

  cart.forEach((key, qtySku) {
    final it = allItems.firstWhere(
      (e) => e.key == key,
      orElse: () => TeaItem(
        key: key,
        itemId: null,
        name: 'Unknown',
        desc: '',
        brand: 'Meezan',
      ),
    );

    final id = (it.itemId ?? '').trim();
    if (id.isEmpty) return; // skip if item_id missing

    const int qtyCtn = 0;

    // 👇 make it double so we can send "20.0"
    final double total = (qtySku + qtyCtn).toDouble();

    orderLines.add({
      "order_type": "or",                 // line-level must be lower
      "item_id": id,
      "item_qty_sku": "$qtySku",
      "item_qty_ctn": "$qtyCtn",
      "item_total_qty": total.toStringAsFixed(1), // → "20.0"
    });
  });

  final payload = <String, dynamic>{
    "unique": unique ?? _uuidv4(),
    "user_id": userId,
    "date": _ddMmmYyLower(date ?? DateTime.now()),
    "acc_code": accCode,
    "segment_id": segmentId,
    "compid": compId,
    "order_booker_id": orderBookerId,
    "payment_type": paymentType,
    "order_type": headerOrderType,   // header stays "OR"
    "order_status": orderStatus,
    "dist_id": distId,
    "order": orderLines,
  };

  if (appSource != null && appSource.isNotEmpty) {
    payload["appSource"] = appSource;
  }
  if (deviceId != null && deviceId.isNotEmpty) {
    payload["deviceId"] = deviceId;
  }

  return payload;
}
