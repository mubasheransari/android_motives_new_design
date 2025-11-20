
import 'package:motives_new_ui_conversion/products_items_screen.dart';

import '../Models/cart_qty.dart';   
import 'order_meta.dart';                  

String _uuidv4() => generateUuidV4();
String _ddMmmYyLower(DateTime dt) => formatDdMmmYyLower(dt);

Map<String, dynamic> buildLegacyOrderPayload({
  required List<SimpleItemRef> allItems,
  required Map<String, CartQty> cart,  
  required OrderMeta meta,
  required QtyMode qtyMode,            
  String? shopName,         
}) {
  final orderLines = <Map<String, dynamic>>[];

  cart.forEach((key, qty) {
    final ref = allItems.firstWhere(
      (e) => e.key == key,
      orElse: () => const SimpleItemRef(key: 'unknown', itemId: null, name: 'Unknown'),
    );

    final id = (ref.itemId ?? '').trim();
    if (id.isEmpty) return;

    final int sku = (qtyMode == QtyMode.ctn) ? 0 : (qty.sku);
    final int ctn = (qtyMode == QtyMode.sku) ? 0 : (qty.ctn);
    final double total = (sku + ctn).toDouble();

    orderLines.add({
      "order_type": "or",          
      "item_id": id,
      "item_qty_sku": "$sku",
      "item_qty_ctn": "$ctn",
      "item_total_qty": total.toStringAsFixed(1),
      "_client_item_name": ref.name,
    });
  });

  final payload = <String, dynamic>{
    "unique": meta.unique ?? _uuidv4(),
    "user_id": meta.userId,
    "date": _ddMmmYyLower(meta.date),
    "acc_code": meta.accCode,
    "segment_id": meta.segmentId,
    "compid": meta.compId,
    "order_booker_id": meta.orderBookerId,
    "payment_type": meta.paymentType,
    "order_type": meta.orderType,     
    "order_status": meta.orderStatus,
    "dist_id": meta.distId,
    "order": orderLines,

    if (shopName != null && shopName.isNotEmpty) "_client_shop_name": shopName,
  };

  return payload;
}
