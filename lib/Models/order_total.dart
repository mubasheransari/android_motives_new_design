// utils/order_totals.dart
class OrderTotals {
  final int lines;
  final int totalSku;
  final int totalCtn;

  const OrderTotals(this.lines, this.totalSku, this.totalCtn);

  static OrderTotals fromPayload(Map<String, dynamic> p) {
    final list = (p['order'] as List?) ?? const [];
    int sku = 0, ctn = 0;
    for (final e in list) {
      if (e is Map) {
        sku += int.tryParse((e['item_qty_sku'] ?? '0').toString()) ?? 0;
        ctn += int.tryParse((e['item_qty_ctn'] ?? '0').toString()) ?? 0;
      }
    }
    return OrderTotals(list.length, sku, ctn);
  }
}
