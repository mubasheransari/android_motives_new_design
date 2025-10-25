import 'dart:convert';

/// Item row as per legacy JSON (kept as strings to match your API)
class LegacyOrderLine {
  final String orderType;      // "or"
  final String itemId;         // "110001"
  final String itemQtySku;     // "20"
  final String itemQtyCtn;     // "0"
  final String itemTotalQty;   // "20.0"

  const LegacyOrderLine({
    required this.orderType,
    required this.itemId,
    required this.itemQtySku,
    required this.itemQtyCtn,
    required this.itemTotalQty,
  });

  factory LegacyOrderLine.fromJson(Map<String, dynamic> j) => LegacyOrderLine(
        orderType: (j['order_type'] ?? '').toString(),
        itemId: (j['item_id'] ?? '').toString(),
        itemQtySku: (j['item_qty_sku'] ?? '').toString(),
        itemQtyCtn: (j['item_qty_ctn'] ?? '').toString(),
        itemTotalQty: (j['item_total_qty'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'order_type': orderType,
        'item_id': itemId,
        'item_qty_sku': itemQtySku,
        'item_qty_ctn': itemQtyCtn,
        'item_total_qty': itemTotalQty,
      };

  int get skuQtyInt => int.tryParse(itemQtySku) ?? 0;
  int get ctnQtyInt => int.tryParse(itemQtyCtn) ?? 0;
  double get totalQty => double.tryParse(itemTotalQty) ?? (skuQtyInt + ctnQtyInt).toDouble();
}

/// Entire order record (header + lines)
class OrderRecord {
  final String unique;         // uuid
  final String userId;
  final String dateStr;        // "14-jan-19"
  final String accCode;
  final String segmentId;
  final String compId;
  final String orderBookerId;
  final String paymentType;    // "CR"
  final String orderType;      // "OR"
  final String orderStatus;    // "N"
  final String distId;
  final List<LegacyOrderLine> lines;

  /// Extra client metadata
  final String? shopId;        // optional scoping
  final String createdAtIso;   // client timestamp when saved (ISO-8601)

  const OrderRecord({
    required this.unique,
    required this.userId,
    required this.dateStr,
    required this.accCode,
    required this.segmentId,
    required this.compId,
    required this.orderBookerId,
    required this.paymentType,
    required this.orderType,
    required this.orderStatus,
    required this.distId,
    required this.lines,
    required this.createdAtIso,
    this.shopId,
  });

  factory OrderRecord.fromLegacyJson(
    Map<String, dynamic> j, {
    String? shopId,
    DateTime? createdAt,
  }) {
    final list = (j['order'] as List? ?? const [])
        .map((e) => LegacyOrderLine.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return OrderRecord(
      unique: (j['unique'] ?? '').toString(),
      userId: (j['user_id'] ?? '').toString(),
      dateStr: (j['date'] ?? '').toString(),
      accCode: (j['acc_code'] ?? '').toString(),
      segmentId: (j['segment_id'] ?? '').toString(),
      compId: (j['compid'] ?? '').toString(),
      orderBookerId: (j['order_booker_id'] ?? '').toString(),
      paymentType: (j['payment_type'] ?? '').toString(),
      orderType: (j['order_type'] ?? '').toString(),
      orderStatus: (j['order_status'] ?? '').toString(),
      distId: (j['dist_id'] ?? '').toString(),
      lines: list,
      shopId: shopId,
      createdAtIso: (createdAt ?? DateTime.now()).toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'unique': unique,
        'user_id': userId,
        'date': dateStr,
        'acc_code': accCode,
        'segment_id': segmentId,
        'compid': compId,
        'order_booker_id': orderBookerId,
        'payment_type': paymentType,
        'order_type': orderType,
        'order_status': orderStatus,
        'dist_id': distId,
        'order': lines.map((e) => e.toJson()).toList(),
        // client meta
        '_client_created_at': createdAtIso,
        '_client_shop_id': shopId,
      };

  int get totalLines => lines.length;
  double get totalQty => lines.fold(0.0, (a, b) => a + b.totalQty);

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}
