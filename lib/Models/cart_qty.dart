// Add this new tiny model
class CartQty {
  final int sku;
  final int ctn;
  const CartQty({this.sku = 0, this.ctn = 0});

  CartQty copyWith({int? sku, int? ctn}) => CartQty(sku: sku ?? this.sku, ctn: ctn ?? this.ctn);

  Map<String, dynamic> toJson() => {"sku": sku, "ctn": ctn};
  static CartQty fromAny(dynamic v) {
    if (v is int) return CartQty(sku: v, ctn: 0); // backward compatible
    if (v is Map) {
      final s = (v['sku'] is int) ? v['sku'] as int : int.tryParse('${v['sku'] ?? 0}') ?? 0;
      final c = (v['ctn'] is int) ? v['ctn'] as int : int.tryParse('${v['ctn'] ?? 0}') ?? 0;
      return CartQty(sku: s, ctn: c);
    }
    return const CartQty();
  }
}
