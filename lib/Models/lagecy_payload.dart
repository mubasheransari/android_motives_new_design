// utils/build_legacy_order_payload.dart
import 'dart:math';

import 'package:motives_new_ui_conversion/products_items_screen.dart';

import '../Models/cart_qty.dart';          // CartQty { int sku, int ctn, ... }
import 'order_meta.dart';                  // OrderMeta, SimpleItemRef, helpers

String _uuidv4() => generateUuidV4();
String _ddMmmYyLower(DateTime dt) => formatDdMmmYyLower(dt);

/// Generic builder (when you have only SimpleItemRef)
Map<String, dynamic> buildLegacyOrderPayload({
  required List<SimpleItemRef> allItems,
  required Map<String, CartQty> cart,   // key → qty sku/ctn
  required OrderMeta meta,
  required QtyMode qtyMode,             // sku | ctn | both
  String? shopName,                     // for Records UI
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
    final double total = (sku + ctn).toDouble(); // legacy "total"

    orderLines.add({
      "order_type": "or",                  // line-level lower
      "item_id": id,
      "item_qty_sku": "$sku",
      "item_qty_ctn": "$ctn",
      "item_total_qty": total.toStringAsFixed(1),

      // client-only fields for Records UI
      "_client_item_name": ref.name,
      // no ctn size here (SimpleItemRef doesn't know it)
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
    "order_type": meta.orderType,     // header stays upper "OR"
    "order_status": meta.orderStatus,
    "dist_id": meta.distId,
    "order": orderLines,

    // client-only header fields
    if (shopName != null && shopName.isNotEmpty) "_client_shop_name": shopName,
  };

  return payload;
}
