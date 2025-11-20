import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location/location.dart' as loc;
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Models/cart_qty.dart';
import 'package:motives_new_ui_conversion/Models/order_storage.dart';
import 'package:motives_new_ui_conversion/Models/order_sumbitted_model.dart';
import 'package:motives_new_ui_conversion/Offline/sync_service.dart';
import 'package:motives_new_ui_conversion/records_history_screen.dart';
import 'package:uuid/uuid.dart';
import 'Models/lagecy_payload.dart';
import 'Models/login_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'dart:io' show Platform;

// meezan_tea_catalog.dart
import 'dart:convert';
import 'dart:io';



// ---------- imports ----------
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as loc;
import 'package:uuid/uuid.dart';

// If your Item/JourneyPlan/GlobalBloc/RecordsScreen/SyncService live
// in other files, keep their imports as you already have them.

// ---------- theme ----------
const kOrange = Color(0xFFEA7A3B);
const kText = Color(0xFF1E1E1E);
const kMuted = Color(0xFF707883);
const kField = Color(0xFFF2F3F5);
const kCard = Colors.white;
const kShadow = Color(0x14000000);

// ===== DATA MODELS =====
class TeaItem {
  final String key;
  final String? itemId;
  final String name;
  final String desc;
  final String brand;
  final int ctnSize; // packs per carton (best-effort)

  const TeaItem({
    required this.key,
    required this.itemId,
    required this.name,
    required this.desc,
    required this.brand,
    this.ctnSize = 0,
  });
}

enum QtyMode { sku, ctn, both }

List<TeaItem> mapItemsToTea(List<Item> raw) {
  return raw.asMap().entries.map((entry) {
    final i = entry.value;
    final idx = entry.key;

    final id = (i.id ?? '').toString().trim();
    final name = (i.itemName ?? i.name ?? 'Unknown Product').toString().trim();
    final desc = (i.itemDesc ?? '').toString().trim();
    final brandRaw = (i.brand ?? '').toString().trim();
    final brand = brandRaw.isNotEmpty ? brandRaw : 'Meezan';

    final ctnSize = int.tryParse(
          ((i.packQty ?? i.ctnQty ?? '').toString())
              .replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    final key = id.isNotEmpty ? id : '$name|$brand|$idx';
    return TeaItem(
      key: key,
      itemId: id.isNotEmpty ? id : null,
      name: name,
      desc: desc,
      brand: brand,
      ctnSize: ctnSize,
    );
  }).toList();
}

// ===== OPTIONAL SIMPLE CART REQUEST =====
class CartLineDto {
  final String? itemId;
  final String name;
  final String brand;
  final int qty;
  final String key;

  const CartLineDto({
    required this.itemId,
    required this.name,
    required this.brand,
    required this.qty,
    required this.key,
  });

  Map<String, dynamic> toJson() => {
        "itemId": itemId,
        "name": name,
        "brand": brand,
        "qty": qty,
        "clientKey": key,
      };
}

Map<String, dynamic> buildCartRequest({
  required List<TeaItem> allItems,
  required Map<String, int> cart,
  String? userId,
  String? distributorId,
  String? shopId,
}) {
  final lines = <CartLineDto>[];
  cart.forEach((key, qty) {
    final item = allItems.firstWhere(
      (t) => t.key == key,
      orElse: () => TeaItem(
        key: key,
        itemId: null,
        name: 'Unknown',
        desc: '',
        brand: 'Meezan',
      ),
    );
    lines.add(CartLineDto(
      itemId: item.itemId,
      name: item.name,
      brand: item.brand,
      qty: qty,
      key: item.key,
    ));
  });

  final totalQty = lines.fold<int>(0, (a, l) => a + l.qty);

  return {
    "userId": userId,
    "distributorId": distributorId,
    "shopId": shopId,
    "totalQty": totalQty,
    "items": lines.map((e) => e.toJson()).toList(),
  };
}

// ===== ORDERS STORAGE (adds shop & product names) =====
class OrderRecord {
  final String id;
  final String userId;
  final String distId;
  final String dateStr;
  final String status;
  final Map<String, dynamic> payload;
  final int httpStatus;
  final String? serverBody;
  final DateTime createdAt;

  // NEW fields for UI
  final String? shopName;     // party_name
  final String? shopAddress;  // cust_address
  final List<String> itemNames;

  OrderRecord({
    required this.id,
    required this.userId,
    required this.distId,
    required this.dateStr,
    required this.status,
    required this.payload,
    required this.httpStatus,
    this.serverBody,
    required this.createdAt,
    this.shopName,
    this.shopAddress,
    this.itemNames = const [],
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "userId": userId,
        "distId": distId,
        "dateStr": dateStr,
        "status": status,
        "payload": payload,
        "httpStatus": httpStatus,
        "serverBody": serverBody,
        "createdAt": createdAt.toIso8601String(),
        "shopName": shopName,
        "shopAddress": shopAddress,
        "itemNames": itemNames,
      };

  static OrderRecord fromJson(Map<String, dynamic> j) => OrderRecord(
        id: j["id"] ?? "",
        userId: j["userId"] ?? "",
        distId: j["distId"] ?? "",
        dateStr: j["dateStr"] ?? "",
        status: j["status"] ?? "Success",
        payload:
            (j["payload"] is Map) ? (j["payload"] as Map).cast<String, dynamic>() : <String, dynamic>{},
        httpStatus: j["httpStatus"] ?? 200,
        serverBody: j["serverBody"],
        createdAt: DateTime.tryParse(j["createdAt"] ?? "") ?? DateTime.now(),
        shopName: j["shopName"],
        shopAddress: j["shopAddress"],
        itemNames: (j["itemNames"] is List)
            ? (j["itemNames"] as List).map((e) => e.toString()).toList()
            : const <String>[],
      );
}

class OrdersStorage {
  final _box = GetStorage();
  String _key(String userId) => 'orders_$userId';

  Future<void> addOrder(String userId, OrderRecord record) async {
    final list = await listOrders(userId);
    list.removeWhere((e) => e.id == record.id);
    list.insert(0, record);
    await _box.write(_key(userId), jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<List<OrderRecord>> listOrders(String userId) async {
    final raw = _box.read(_key(userId));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => OrderRecord.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clear(String userId) => _box.remove(_key(userId));
}

// ===== OFFLINE/ONLINE SUBMIT =====
class OrderSubmitResult {
  final bool success;
  final int statusCode;
  final String rawBody;
  final Map<String, dynamic>? json;
  final String? serverMessage;

  const OrderSubmitResult({
    required this.success,
    required this.statusCode,
    required this.rawBody,
    required this.json,
    required this.serverMessage,
  });
}

Future<OrderSubmitResult> sendCartToApi({
  required BuildContext context,
  required Map<String, dynamic> legacyPayload,
  required String endpoint,
  required String userId,
  required String distId,
  Map<String, String>? extraHeaders,
  String requestField = 'request',
  bool navigateToRecordsOnSuccess = true,
  bool sendAsJson = false,

  // NEW (for Records UI):
  String? shopName,
  String? shopAddress,
  List<String>? itemNames,
}) async {
  final String orderId =
      (legacyPayload['unique']?.toString().trim().isNotEmpty ?? false)
          ? legacyPayload['unique'].toString()
          : const Uuid().v4();

  Future<OrderSubmitResult> _returnQueued(String msg) async {
    final rec = OrderRecord(
      id: orderId,
      userId: userId,
      distId: distId,
      dateStr: (legacyPayload['date'] ?? '').toString(),
      status: 'Queued (Offline)',
      payload: legacyPayload,
      httpStatus: 0,
      serverBody: '',
      createdAt: DateTime.now(),
      shopName: shopName,
      shopAddress: shopAddress,
      itemNames: (itemNames ?? const <String>[]),
    );
    await OrdersStorage().addOrder(userId, rec);

    if (navigateToRecordsOnSuccess && context.mounted) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordsScreen()));
    }

    return const OrderSubmitResult(
      success: true,
      statusCode: 0,
      rawBody: '',
      json: {'queued': true},
      serverMessage: 'Saved offline.',
    );
  }

  // Check connectivity via your SyncService
  final online = await SyncService.instance.isOnlineNow();
  if (!online) {
    await SyncService.instance.enqueueOrder(
      endpoint: endpoint,
      payload: legacyPayload,
      requestField: requestField,
      headers: extraHeaders,
      userId: userId,
      distId: distId,
      orderId: orderId,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved offline. Will sync when online 🔄')),
      );
    }
    return _returnQueued('Saved offline. Will sync when online.');
  }

  // Online: fire the request
  final uri = Uri.parse(endpoint);
  final headers = {...?extraHeaders};
  http.Response res;

  try {
    if (sendAsJson) {
      headers['Content-Type'] = 'application/json';
      final body = jsonEncode(legacyPayload);
      debugPrint('➡️ headers: $headers');
      debugPrint('➡️ json body: $body');
      res = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 45));
    } else {
      headers.removeWhere((k, _) => k.toLowerCase() == 'content-type');
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
      final body = {requestField: jsonEncode(legacyPayload)};
      debugPrint('➡️ headers: $headers');
      debugPrint('➡️ form body: $body');
      res = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 45));
    }
  } catch (e) {
    await SyncService.instance.enqueueOrder(
      endpoint: endpoint,
      payload: legacyPayload,
      requestField: requestField,
      headers: extraHeaders,
      userId: userId,
      distId: distId,
      orderId: orderId,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved offline (network). Will sync later 🔄')),
      );
    }
    return _returnQueued('Saved offline (network). Will sync later.');
  }

  debugPrint('⬅️ status ${res.statusCode}');
  debugPrint('⬅️ body   ${res.body}');

  Map<String, dynamic>? parsed;
  String? message;
  bool ok = res.statusCode >= 200 && res.statusCode < 300;

  try {
    final d = jsonDecode(res.body);
    if (d is Map<String, dynamic>) {
      parsed = d;
      message = (d['message'] ?? d['msg'] ?? d['status'] ?? '').toString();
      if (d.containsKey('isSuccess')) ok = ok && (d['isSuccess'] == true);
      if (d.containsKey('success') && d['success'] is bool) {
        ok = ok && d['success'] == true;
      }
    }
  } catch (_) {}

  if (!ok) {
    await SyncService.instance.enqueueOrder(
      endpoint: endpoint,
      payload: legacyPayload,
      requestField: requestField,
      headers: extraHeaders,
      userId: userId,
      distId: distId,
      orderId: orderId,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message?.isNotEmpty == true ? 'Saved offline: $message' : 'Saved offline. Will retry.')),
      );
    }
    return _returnQueued(message?.isNotEmpty == true ? 'Saved offline: $message' : 'Saved offline. Will retry.');
  }

  // SUCCESS path — persist with shop + products
  final rec = OrderRecord(
    id: orderId,
    userId: userId,
    distId: distId,
    dateStr: (legacyPayload['date'] ?? '').toString(),
    status: 'Success',
    payload: legacyPayload,
    httpStatus: res.statusCode,
    serverBody: res.body,
    createdAt: DateTime.now(),
    shopName: shopName,
    shopAddress: shopAddress,
    itemNames: (itemNames ?? const <String>[]),
  );
  await OrdersStorage().addOrder(userId, rec);

  if (navigateToRecordsOnSuccess && context.mounted) {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordsScreen()));
  }

  return OrderSubmitResult(
    success: true,
    statusCode: res.statusCode,
    rawBody: res.body,
    json: parsed,
    serverMessage: (message?.isEmpty ?? true) ? null : message,
  );
}

// ===== SKU STORAGE =====
class CartStorage {
  final _box = GetStorage();

  String _key(String? userId, String? shopId) =>
      'meezan_cart_${userId ?? "guest"}_${shopId ?? "defaultShop"}';

  Map<String, int> load(String? userId, String? shopId) {
    final raw = _box.read(_key(userId, shopId));
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

  Future<void> save(Map<String, int> cart, String? userId, String? shopId) async =>
      _box.write(_key(userId, shopId), jsonEncode(Map.of(cart)..removeWhere((_, q) => q <= 0)));

  Future<void> clear(String? userId, String? shopId) async => _box.remove(_key(userId, shopId));
}

// ===== Helpers for building legacy payload =====
String _uuidv4() => const Uuid().v4();
String _ddMmmYyLower(DateTime dt) {
  const m = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'];
  final dd = dt.day.toString().padLeft(2, '0');
  final mon = m[dt.month - 1];
  final yy = (dt.year % 100).toString().padLeft(2, '0');
  return '$dd-$mon-$yy';
}

/// Build payload from separate SKU / CTN carts, persisting client-only fields.
/// Each line adds: _client_item_name, _client_ctn_size (if > 0).
/// Header adds: _client_shop_name and _client_shop_address (if provided).
Map<String, dynamic> buildLegacyOrderPayloadFromTea({
  required List<TeaItem> allItems,
  required Map<String, int> cartSku,
  required Map<String, int> cartCtn,
  required String userId,
  required String distId,
  required String accCode,
  required String segmentId,
  required String compId,
  required String orderBookerId,
  required String paymentType,
  String headerOrderType = 'OR',
  String orderStatus = 'N',
  String? shopName,
  String? shopAddress,
  DateTime? date,
  String? unique,
  String? appSource,
  String? deviceId,
}) {
  final keys = <String>{...cartSku.keys, ...cartCtn.keys}.toList()..sort();
  final orderLines = <Map<String, dynamic>>[];

  for (final k in keys) {
    final item = allItems.firstWhere(
      (e) => e.key == k,
      orElse: () => const TeaItem(key: 'missing', itemId: null, name: 'Unknown', desc: '', brand: 'Meezan'),
    );
    final id = (item.itemId ?? '').trim();
    if (id.isEmpty) continue;

    final sku = cartSku[k] ?? 0;
    final ctn = cartCtn[k] ?? 0;
    final total = (sku + ctn).toDouble();

    orderLines.add({
      "order_type": "or",
      "item_id": id,
      "item_qty_sku": "$sku",
      "item_qty_ctn": "$ctn",
      "item_total_qty": total.toStringAsFixed(1),

      // client-only fields:
      "_client_item_name": item.name,
      if (item.ctnSize > 0) "_client_ctn_size": item.ctnSize,
    });
  }

  final payload = <String, dynamic>{
    "unique": unique ?? _uuidv4(),
    "user_id": userId,
    "date": _ddMmmYyLower(date ?? DateTime.now()),
    "acc_code": accCode,
    "segment_id": segmentId,
    "compid": compId,
    "order_booker_id": orderBookerId,
    "payment_type": paymentType,
    "order_type": headerOrderType,
    "order_status": orderStatus,
    "dist_id": distId,
    "order": orderLines,

    // client header meta
    if (shopName != null && shopName.isNotEmpty) "_client_shop_name": shopName,
    if (shopAddress != null && shopAddress.isNotEmpty) "_client_shop_address": shopAddress,
  };

  if (appSource != null && appSource.isNotEmpty) payload["appSource"] = appSource;
  if (deviceId != null && deviceId.isNotEmpty) payload["deviceId"] = deviceId;

  return payload;
}

// ===== MAIN CATALOG (supports QtyMode + dual carts) =====
class MeezanTeaCatalog extends StatefulWidget {
  final String shopId, creditBoolean; // creditBoolean: "0" or "1"

  const MeezanTeaCatalog({
    super.key,
    required this.shopId,
    required this.creditBoolean,
  });

  @override
  State<MeezanTeaCatalog> createState() => _MeezanTeaCatalogState();
}

class _MeezanTeaCatalogState extends State<MeezanTeaCatalog> {
  final _search = TextEditingController();
  String _selectedLine = "All";

  final Map<String, int> _cartSku = {};
  final Map<String, int> _cartCtn = {};

  final _skuStorage = CartStorage();
  final _box = GetStorage();

  String? _activeUserId;
  String? _activeDistributorId;
  String? _activeShopId;

  QtyMode _qtyMode = QtyMode.sku;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final login = context.read<GlobalBloc>().state.loginModel;
      _activeUserId = login?.userinfo?.userId;
      _activeDistributorId = (login?.distributors.isNotEmpty ?? false) ? login!.distributors.first.id : null;
      _activeShopId = widget.shopId;

      final savedSku = _skuStorage.load(_activeUserId, _activeShopId);
      _cartSku..clear()..addAll(savedSku);

      final savedCtn = _loadCtnMap();
      _cartCtn..clear()..addAll(savedCtn);

      setState(() {});
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _ctnKey([String? userId, String? shopId]) =>
      'meezan_cart_ctn_${userId ?? _activeUserId ?? "guest"}_${shopId ?? _activeShopId ?? "defaultShop"}';

  Map<String, int> _loadCtnMap() {
    final raw = _box.read(_ctnKey());
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

  Future<void> _saveCtnMap() async {
    final clean = Map.of(_cartCtn)..removeWhere((_, q) => q <= 0);
    await _box.write(_ctnKey(), jsonEncode(clean));
  }

  Future<void> _persistSku() => _skuStorage.save(_cartSku, _activeUserId, _activeShopId);

  int _getSku(String k) => _cartSku[k] ?? 0;
  int _getCtn(String k) => _cartCtn[k] ?? 0;

  void _incSku(TeaItem item) { setState(() => _cartSku[item.key] = _getSku(item.key) + 1); _persistSku(); }
  void _decSku(TeaItem item) {
    setState(() {
      final q = _getSku(item.key);
      if (q > 1) _cartSku[item.key] = q - 1; else _cartSku.remove(item.key);
    });
    _persistSku();
  }
  void _incCtn(TeaItem item) { setState(() => _cartCtn[item.key] = _getCtn(item.key) + 1); _saveCtnMap(); }
  void _decCtn(TeaItem item) {
    setState(() {
      final q = _getCtn(item.key);
      if (q > 1) _cartCtn[item.key] = q - 1; else _cartCtn.remove(item.key);
    });
    _saveCtnMap();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final login = context.read<GlobalBloc>().state.loginModel;
    final userId = login?.userinfo?.userId;
    final distributorId = (login?.distributors.isNotEmpty ?? false) ? login!.distributors.first.id : null;

    final List<Item> rawItems = login?.items ?? const <Item>[];
    final List<TeaItem> items = mapItemsToTea(rawItems);

    final lines = <String>["All", ...{for (final i in items) i.brand}.where((s) => s.isNotEmpty)];
    final q = _search.text.trim().toLowerCase();
    final filtered = items.where((e) {
      final lineOk = _selectedLine == "All" || e.brand == _selectedLine;
      final searchOk = q.isEmpty || e.name.toLowerCase().contains(q) || e.desc.toLowerCase().contains(q);
      return lineOk && searchOk;
    }).toList();

    final totalSku = _cartSku.values.fold(0, (a, b) => a + b);
    final totalCtn = _cartCtn.values.fold(0, (a, b) => a + b);
    final totalAll = totalSku + totalCtn;

    String qtyLabel() {
      if (totalSku > 0 && totalCtn > 0) return 'SKU: $totalSku • CTN: $totalCtn';
      if (totalCtn > 0) return 'CTN: $totalCtn';
      return 'SKU: $totalSku';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text("Products", style: t.titleLarge?.copyWith(color: kText, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, color: kText),
                  onPressed: () async {
                    final result = await Navigator.of(context).push<Map<String, dynamic>>(
                      MaterialPageRoute(
                        builder: (_) => _MyListView(
                          creditLimit: widget.creditBoolean,
                          shopId: _activeShopId ?? widget.shopId,
                          allItems: items,
                          cartSku: _cartSku,
                          cartCtn: _cartCtn,
                          onIncrementSku: _incSku,
                          onDecrementSku: _decSku,
                          onIncrementCtn: _incCtn,
                          onDecrementCtn: _decCtn,
                          getPayloadMeta: () => Tuple2(userId, distributorId),
                        ),
                      ),
                    );

                    if (result?['submitted'] == true) {
                      setState(() {
                        _cartSku.clear();
                        _cartCtn.clear();
                      });
                      await _skuStorage.clear(_activeUserId, _activeShopId);
                      await _box.remove(_ctnKey());
                      if (mounted) Navigator.pop(context, result);
                    } else {
                      setState(() {});
                    }
                  },
                ),
                if (totalAll > 0)
                  Positioned(
                    right: 6,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(999)),
                      child: Text('$totalAll',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: kShadow, blurRadius: 12, offset: Offset(0, 6))],
                border: Border.all(color: const Color(0xFFEDEFF2)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: kMuted.withOpacity(.9)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search products (e.g. Gold, Green Tea, 475g)',
                        hintStyle: TextStyle(color: kMuted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_search.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: kMuted),
                      onPressed: () { _search.clear(); setState(() {}); },
                    ),
                ],
              ),
            ),
          ),

          // Brand chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: lines.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final label = lines[i];
                final selected = _selectedLine == label;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedLine = label),
                  selectedColor: kOrange,
                  labelStyle: TextStyle(color: selected ? Colors.white : kText, fontWeight: FontWeight.w600),
                  backgroundColor: Colors.white,
                  shape: StadiumBorder(side: BorderSide(color: selected ? Colors.transparent : const Color(0xFFEDEFF2))),
                  elevation: selected ? 2 : 0,
                );
              },
            ),
          ),

          // Mode selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Expanded(child: _QtyModeTile(label: 'SKU',  selected: _qtyMode == QtyMode.sku,  onTap: () => setState(() => _qtyMode = QtyMode.sku))),
                const SizedBox(width: 8),
                Expanded(child: _QtyModeTile(label: 'CTN',  selected: _qtyMode == QtyMode.ctn,  onTap: () => setState(() => _qtyMode = QtyMode.ctn))),
                const SizedBox(width: 8),
                Expanded(child: _QtyModeTile(label: 'Both', selected: _qtyMode == QtyMode.both, onTap: () => setState(() => _qtyMode = QtyMode.both))),
              ],
            ),
          ),

          // Counts
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text('${filtered.length} products', style: t.bodySmall?.copyWith(color: kMuted)),
                const Spacer(),
                if (totalAll > 0)
                  Text('In list: ${qtyLabel()}', style: t.bodySmall?.copyWith(color: kOrange, fontWeight: FontWeight.w700)),
              ],
            ),
          ),

          // Product list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final item = filtered[i];
                return _ProductCard(
                  name: item.name,
                  desc: item.ctnSize > 0 ? '${item.desc} • ${item.ctnSize} per CTN' : item.desc,
                  brand: item.brand,
                  qtySku: _getSku(item.key),
                  qtyCtn: _getCtn(item.key),
                  mode: _qtyMode,
                  onIncSku: () => _incSku(item),
                  onDecSku: () => _decSku(item),
                  onIncCtn: () => _incCtn(item),
                  onDecCtn: () => _decCtn(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===== PRODUCT CARD =====
class _ProductCard extends StatelessWidget {
  final String name;
  final String desc;
  final String brand;

  final int qtySku;
  final int qtyCtn;
  final QtyMode mode;

  final VoidCallback onIncSku;
  final VoidCallback onDecSku;
  final VoidCallback onIncCtn;
  final VoidCallback onDecCtn;

  const _ProductCard({
    required this.name,
    required this.desc,
    required this.brand,
    required this.qtySku,
    required this.qtyCtn,
    required this.mode,
    required this.onIncSku,
    required this.onDecSku,
    required this.onIncCtn,
    required this.onDecCtn,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    Widget controls() {
      switch (mode) {
        case QtyMode.sku:
          return _QtyControlsSingle(label: 'SKU', qty: qtySku, onInc: onIncSku, onDec: onDecSku);
        case QtyMode.ctn:
          return _QtyControlsSingle(label: 'CTN', qty: qtyCtn, onInc: onIncCtn, onDec: onDecCtn);
        case QtyMode.both:
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QtyControlsSingle(label: 'SKU', qty: qtySku, onInc: onIncSku, onDec: onDecSku),
              const SizedBox(width: 8),
              _QtyControlsSingle(label: 'CTN', qty: qtyCtn, onInc: onIncCtn, onDec: onDecCtn),
            ],
          );
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [kOrange, Color(0xFFFFB07A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          margin: const EdgeInsets.all(1.6),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14.4),
            boxShadow: const [BoxShadow(color: kShadow, blurRadius: 14, offset: Offset(0, 8))],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Container(
              //   width: 52, height: 52,
              //   decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(14)),
              //   child: const Icon(Icons.local_cafe_rounded, color: kOrange),
              // ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _TagPill(text: brand),
                  const SizedBox(height: 6),
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: t.titleMedium?.copyWith(color: kText, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: kMuted)),
                ]),
              ),
              const SizedBox(width: 12),
              controls(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String text;
  const _TagPill({required this.text, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kOrange.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kOrange.withOpacity(.25)),
      ),
      child: Text(text, style: const TextStyle(color: kText, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _QtyControlsSingle extends StatelessWidget {
  final String label;
  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;

  const _QtyControlsSingle({
    required this.label,
    required this.qty,
    required this.onInc,
    required this.onDec,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (qty <= 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: kOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onInc,
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(visualDensity: VisualDensity.compact, onPressed: onDec,
                  icon: const Icon(Icons.remove_rounded, size: 20, color: kText)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700, color: kText)),
              ),
              IconButton(visualDensity: VisualDensity.compact, onPressed: onInc,
                  icon: const Icon(Icons.add_rounded, size: 20, color: kText)),
            ],
          ),
        ),
      ],
    );
  }
}

class _QtyModeTile extends StatelessWidget {
  const _QtyModeTile({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1E6) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? kOrange : const Color(0xFFE5E7EB)),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? kText : kMuted)),
      ),
    );
  }
}

// =====================
// _MyListView (Cart / Submit) — shows SKU + CTN and submits both
// =====================
class _MyListView extends StatefulWidget {
  final List<TeaItem> allItems;

  final Map<String, int> cartSku;
  final Map<String, int> cartCtn;

  final void Function(TeaItem) onIncrementSku;
  final void Function(TeaItem) onDecrementSku;
  final void Function(TeaItem) onIncrementCtn;
  final void Function(TeaItem) onDecrementCtn;

  final Tuple2<String?, String?> Function()? getPayloadMeta;

  final String shopId, creditLimit; // creditLimit: "0" or "1"

  const _MyListView({
    required this.allItems,
    required this.cartSku,
    required this.cartCtn,
    required this.onIncrementSku,
    required this.onDecrementSku,
    required this.onIncrementCtn,
    required this.onDecrementCtn,
    this.getPayloadMeta,
    required this.shopId,
    required this.creditLimit,
    Key? key,
  }) : super(key: key);

  @override
  State<_MyListView> createState() => _MyListViewState();
}

class _MyListViewState extends State<_MyListView> {
  bool _isSubmitting = false;
  String _paymentType = 'CR'; // CR=credit, CS=cash

  List<_CartRow> get _rows {
    final keys = <String>{...widget.cartSku.keys, ...widget.cartCtn.keys}.toList()..sort();
    final rows = <_CartRow>[];
    for (final k in keys) {
      final item = widget.allItems.firstWhere(
        (e) => e.key == k,
        orElse: () => const TeaItem(key: 'missing', itemId: null, name: 'Unknown', desc: '', brand: 'Meezan'),
      );
      rows.add(_CartRow(item: item, sku: widget.cartSku[k] ?? 0, ctn: widget.cartCtn[k] ?? 0));
    }
    rows.sort((a, b) => a.item.name.compareTo(b.item.name));
    return rows;
  }

  int get _totalSku => widget.cartSku.values.fold(0, (a, b) => a + b);
  int get _totalCtn => widget.cartCtn.values.fold(0, (a, b) => a + b);
  int get _totalAll => _totalSku + _totalCtn;

  Future<void> _submitOrder() async {
    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      final login = context.read<GlobalBloc>().state.loginModel;

      final userId = (login?.userinfo?.userId ?? '').trim();
      final distId = (login?.userinfo?.disid ?? '').toString();
      final segmentId = (login?.distributors.isNotEmpty ?? false)
          ? (login!.distributors.first.segment ?? '')
          : (login?.userinfo?.segment ?? '');
      final compId = (login?.distributors.isNotEmpty ?? false)
          ? (login!.distributors.first.compid ?? '')
          : (login?.userinfo?.compid ?? '');
      final orderBookerId = (login?.userinfo?.obid ?? '').trim();
      final accCode = widget.shopId.trim();

      // find party_name & cust_address from JourneyPlan
      JourneyPlan? shop;
      try {
        shop = login?.journeyPlan.firstWhere((p) => p.accode == accCode);
      } catch (_) {
        shop = null;
      }
      final String? partyName = shop?.partyName;     // shop name
      final String? custAddress = shop?.custAddress; // shop address

      // collect product names from cart snapshot
      final keys = <String>{...widget.cartSku.keys, ...widget.cartCtn.keys}.toList()..sort();
      final names = <String>[];
      for (final k in keys) {
        final sku = widget.cartSku[k] ?? 0;
        final ctn = widget.cartCtn[k] ?? 0;
        if ((sku + ctn) <= 0) continue;
        final item = widget.allItems.firstWhere(
          (e) => e.key == k,
          orElse: () => const TeaItem(key: 'missing', itemId: null, name: 'Unknown', desc: '', brand: 'Meezan'),
        );
        if (item.name.isNotEmpty && item.name != 'Unknown') names.add(item.name);
      }

      if (userId.isEmpty || distId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User/Distributor not found ($userId/$distId)')),
        );
        return;
      }

      final payload = buildLegacyOrderPayloadFromTea(
        allItems: widget.allItems,
        cartSku: widget.cartSku,
        cartCtn: widget.cartCtn,
        userId: userId,
        distId: distId,
        accCode: accCode,
        segmentId: (segmentId).trim().isNotEmpty ? segmentId.trim() : '11002',
        compId: (compId).trim().isNotEmpty ? compId.trim() : '11',
        orderBookerId: orderBookerId.isNotEmpty ? orderBookerId : userId,
        paymentType: widget.creditLimit != "0" ? _paymentType : "CS",
        headerOrderType: 'OR',
        orderStatus: 'N',
        shopName: partyName,      // client-only for payload
        shopAddress: custAddress, // client-only for payload
        deviceId: Platform.isAndroid
            ? 'android-${DateTime.now().millisecondsSinceEpoch}'
            : 'ios-${DateTime.now().millisecondsSinceEpoch}',
        appSource: 'flutter.motives',
      );

      final result = await sendCartToApi(
        context: context,
        legacyPayload: payload,
        endpoint: 'http://services.zankgroup.com/motivesteang/index.php?route=api/user/transaction',
        userId: userId,
        distId: distId,
        requestField: 'request',
        navigateToRecordsOnSuccess: false,

        // Persist to OrderRecord for Records UI:
        shopName: partyName,
        shopAddress: custAddress,
        itemNames: names,
      );

      final msg = result.success
          ? (result.serverMessage ?? 'Order submitted successfully')
          : (result.serverMessage ?? 'Order submit failed');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

      if (!result.success) return;

      // Success: fire events, set journey flags, clear carts
      final gb = context.read<GlobalBloc>();
      String lat = '0', lng = '0';
      try {
        final l = await loc.Location().getLocation();
        lat = (l.latitude ?? 0).toString();
        lng = (l.longitude ?? 0).toString();
      } catch (_) {}

      gb.add(LoadShopInvoicesRequested(acode: widget.shopId, disid: distId));
      gb.add(CheckinCheckoutEvent(type: '7', userId: userId, lat: lat, lng: lng,
          act_type: 'ORDER', action: 'ORDER PLACED', misc: widget.shopId, dist_id: distId));
      gb.add(CheckinCheckoutEvent(type: '6', userId: userId, lat: lat, lng: lng,
          act_type: 'SHOP_CHECK', action: 'OUT', misc: widget.shopId, dist_id: distId));

      final box = GetStorage();
      final raw = box.read('journey_reasons');
      final reasons = <String, String>{};
      if (raw is Map) raw.forEach((k, v) => reasons[k.toString()] = v.toString());
      reasons[widget.shopId] = 'ORDER PLACED';
      await box.write('journey_reasons', reasons);

      final stRaw = box.read('journey_status');
      final st = (stRaw is Map) ? Map<String, dynamic>.from(stRaw) : <String, dynamic>{};
      st[widget.shopId] = {'checkedIn': false, 'last': 'none', 'holdUI': false};
      await box.write('journey_status', st);

      widget.cartSku.clear();
      widget.cartCtn.clear();
      await CartStorage().clear(userId, widget.shopId);
      await box.remove('meezan_cart_ctn_${userId}_${widget.shopId}');

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.pop<Map<String, dynamic>>(context, {'submitted': true, 'miscid': widget.shopId, 'reason': 'ORDER PLACED'});
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: kText),
        title: Text('My List', style: t.titleLarge?.copyWith(color: kText, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kOrange, Color(0xFFFFB07A)], begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: kShadow, blurRadius: 14, offset: Offset(0, 8))],
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Items in your list: SKU $_totalSku • CTN $_totalCtn (Total $_totalAll)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          if (_rows.isEmpty)
            Expanded(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.local_grocery_store_outlined, size: 56, color: kMuted),
                  const SizedBox(height: 8),
                  Text('Your list is empty', style: t.titleMedium?.copyWith(color: kText)),
                  const SizedBox(height: 4),
                  Text('Add products from the catalog.', style: t.bodySmall?.copyWith(color: kMuted)),
                ]),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                itemCount: _rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final row = _rows[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: kShadow, blurRadius: 12, offset: Offset(0, 6))],
                      border: Border.all(color: const Color(0xFFEDEFF2)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.local_cafe_rounded, color: kOrange),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _TagPill(text: row.item.brand),
                            const SizedBox(height: 6),
                            Text(row.item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: t.titleMedium?.copyWith(color: kText, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(row.item.desc, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: t.bodySmall?.copyWith(color: kMuted)),
                            const SizedBox(height: 8),
                            Row(children: [
                              _MiniBadge(label: 'SKU', value: row.sku),
                              const SizedBox(width: 8),
                              _MiniBadge(label: 'CTN', value: row.ctn),
                            ]),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _QtyControlsTiny(
                              label: 'SKU',
                              qty: row.sku,
                              onInc: () { widget.onIncrementSku(row.item); setState(() {}); },
                              onDec: () { widget.onDecrementSku(row.item); setState(() {}); },
                            ),
                            const SizedBox(height: 8),
                            _QtyControlsTiny(
                              label: 'CTN',
                              qty: row.ctn,
                              onInc: () { widget.onIncrementCtn(row.item); setState(() {}); },
                              onDec: () { widget.onDecrementCtn(row.item); setState(() {}); },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // payment + submit
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 52),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment type', style: TextStyle(fontWeight: FontWeight.w600, color: kText)),
                const SizedBox(height: 10),
                widget.creditLimit != "0"
                    ? Row(
                        children: [
                          Expanded(child: _PaymentChoiceTile(label: 'Credit', code: 'CR', selected: _paymentType == 'CR',
                              onTap: () => setState(() => _paymentType = 'CR'))),
                          const SizedBox(width: 12),
                          Expanded(child: _PaymentChoiceTile(label: 'Cash', code: 'CS', selected: _paymentType == 'CS',
                              onTap: () => setState(() => _paymentType = 'CS'))),
                        ],
                      )
                    : const SizedBox(),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _rows.isEmpty || _isSubmitting ? null : _submitOrder,
                    child: _isSubmitting
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : const Text('Confirm & Send', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- helpers for _MyListView ---
class _CartRow {
  final TeaItem item;
  final int sku;
  final int ctn;
  const _CartRow({required this.item, required this.sku, required this.ctn});
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final int value;
  const _MiniBadge({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kText)),
    );
  }
}

class _QtyControlsTiny extends StatelessWidget {
  final String label;
  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;
  const _QtyControlsTiny({required this.label, required this.qty, required this.onInc, required this.onDec});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: kMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(visualDensity: VisualDensity.compact, onPressed: onDec,
                  icon: const Icon(Icons.remove_rounded, size: 18, color: kText)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700, color: kText)),
              ),
              IconButton(visualDensity: VisualDensity.compact, onPressed: onInc,
                  icon: const Icon(Icons.add_rounded, size: 18, color: kText)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentChoiceTile extends StatelessWidget {
  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentChoiceTile({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? const Color(0xFFFFF1E6) : Colors.white,
          border: Border.all(color: selected ? kOrange : const Color(0xFFE5E7EB), width: selected ? 1.5 : 1),
          boxShadow: const [BoxShadow(color: kShadow, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) const Icon(Icons.check_circle, size: 18, color: kOrange)
            else const Icon(Icons.radio_button_unchecked, size: 18, color: kMuted),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? kText : kMuted)),
          ],
        ),
      ),
    );
  }
}

// Tiny Tuple helper
class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;
  const Tuple2(this.item1, this.item2);
}

