import 'dart:math';

String generateUuidV4() {
  final r = Random.secure();
  String h(int n) => n.toRadixString(16).padLeft(2, '0');
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // v4
  b[8] = (b[8] & 0x3f) | 0x80; // variant
  return '${h(b[0])}${h(b[1])}${h(b[2])}${h(b[3])}-'
         '${h(b[4])}${h(b[5])}-'
         '${h(b[6])}${h(b[7])}-'
         '${h(b[8])}${h(b[9])}-'
         '${h(b[10])}${h(b[11])}${h(b[12])}${h(b[13])}${h(b[14])}${h(b[15])}';
}

String formatDdMmmYyLower(DateTime dt) {
  const m = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'];
  final dd = dt.day.toString().padLeft(2, '0');
  final mon = m[dt.month - 1];
  final yy = (dt.year % 100).toString().padLeft(2, '0');
  return '$dd-$mon-$yy';
}

class OrderMeta {
  final String userId;
  final DateTime date;
  final String accCode;
  final String segmentId;
  final String compId;
  final String orderBookerId;
  final String paymentType;  // "CR"
  final String orderType;    // "OR"
  final String orderStatus;  // "N"
  final String distId;
  final String? unique;

  const OrderMeta({
    required this.userId,
    required this.date,
    required this.accCode,
    required this.segmentId,
    required this.compId,
    required this.orderBookerId,
    required this.paymentType,
    required this.orderType,
    required this.orderStatus,
    required this.distId,
    this.unique,
  });
}

class SimpleItemRef {
  final String key;
  final String? itemId;
  final String name;
  const SimpleItemRef({required this.key, required this.itemId, required this.name});
}

Map<String, dynamic> buildLegacyOrderPayload({
  required List<SimpleItemRef> allItems,
  required Map<String, int> cart, // key → qtySku
  required OrderMeta meta,
}) {
  final orderLines = <Map<String, dynamic>>[];

  cart.forEach((key, qtySku) {
    final ref = allItems.firstWhere(
      (e) => e.key == key,
      orElse: () => SimpleItemRef(key: key, itemId: null, name: 'Unknown'),
    );
    final id = (ref.itemId ?? '').trim();
    if (id.isEmpty) return; // skip if no item_id
    const qtyCtn = 0;
    final total = qtySku + qtyCtn;
    orderLines.add({
      "order_type": "or",
      "item_id": id,
      "item_qty_sku": "$qtySku",
      "item_qty_ctn": "$qtyCtn",
      "item_total_qty": "${total.toStringAsFixed(1)}",
    });
  });

  return {
    "unique": meta.unique ?? generateUuidV4(),
    "user_id": meta.userId,
    "date": formatDdMmmYyLower(meta.date),
    "acc_code": meta.accCode,
    "segment_id": meta.segmentId,
    "compid": meta.compId,
    "order_booker_id": meta.orderBookerId,
    "payment_type": meta.paymentType,
    "order_type": meta.orderType,
    "order_status": meta.orderStatus,
    "dist_id": meta.distId,
    "order": orderLines,
  };
}

/// Convenience for totals shown in UI
class OrderTotals {
  final int lines;
  final double totalQty;
  const OrderTotals(this.lines, this.totalQty);
  static OrderTotals fromPayload(Map<String, dynamic> p) {
    final list = (p['order'] as List?) ?? const [];
    double sum = 0;
    for (final e in list) {
      final s = (e['item_total_qty'] ?? '0').toString();
      sum += double.tryParse(s) ?? 0.0;
    }
    return OrderTotals(list.length, sum);
  }
}
