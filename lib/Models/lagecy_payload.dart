import 'dart:math';

import 'package:motives_new_ui_conversion/products_items_screen.dart';

String _uuidv4() {
  final r = Random.secure();
  String h(int n) => n.toRadixString(16).padLeft(2, '0');
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  return '${h(b[0])}${h(b[1])}${h(b[2])}${h(b[3])}-'
         '${h(b[4])}${h(b[5])}-'
         '${h(b[6])}${h(b[7])}-'
         '${h(b[8])}${h(b[9])}-'
         '${h(b[10])}${h(b[11])}${h(b[12])}${h(b[13])}${h(b[14])}${h(b[15])}';
}

String _ddMmmYyLower(DateTime dt) {
  const m = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'];
  final dd = dt.day.toString().padLeft(2, '0');
  final mon = m[dt.month - 1];
  final yy = (dt.year % 100).toString().padLeft(2, '0');
  return '$dd-$mon-$yy';
}

/// Build EXACT legacy JSON using your TeaItem/cart types.
Map<String, dynamic> buildLegacyOrderPayloadFromTea({
  required List<TeaItem> allItems,
  required Map<String, int> cart,       // key -> qty (SKU)
  required String userId,
  required String distId,
  // You can override any of these dynamically from Bloc/UI:
  String accCode = '500001',
  String segmentId = '11002',
  String compId = '11',
  String orderBookerId = '1001',
  String paymentType = 'CR',
  String headerOrderType = 'OR',  // header UPPER
  String orderStatus = 'N',
  DateTime? date,
  String? unique,
}) {
  final orderLines = <Map<String, dynamic>>[];

  cart.forEach((key, qtySku) {
    final it = allItems.firstWhere(
      (e) => e.key == key,
      orElse: () => TeaItem(
        key: key, itemId: null, name: 'Unknown', desc: '', brand: 'Meezan'),
    );
    final id = (it.itemId ?? '').trim();
    if (id.isEmpty) return; // skip lines without item_id

    const int qtyCtn = 0;
    final total = qtySku + qtyCtn;

    orderLines.add({
      "order_type": "or",                       // line lower-case
      "item_id": id,
      "item_qty_sku": "$qtySku",                // string
      "item_qty_ctn": "$qtyCtn",                // string
      "item_total_qty": "${total.toStringAsFixed(1)}", // "20.0"
    });
  });

  return {
    "unique": unique ?? _uuidv4(),
    "user_id": userId,
    "date": _ddMmmYyLower(date ?? DateTime.now()),
    "acc_code": accCode,
    "segment_id": segmentId,
    "compid": compId,
    "order_booker_id": orderBookerId,
    "payment_type": paymentType,
    "order_type": headerOrderType,         // header UPPER
    "order_status": orderStatus,
    "dist_id": distId,
    "order": orderLines,
  };
}
