import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location/location.dart' as loc;
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Models/order_storage.dart';
import 'package:motives_new_ui_conversion/Models/order_sumbitted_model.dart';
import 'package:motives_new_ui_conversion/records_history_screen.dart';
import 'Models/lagecy_payload.dart';
import 'Models/login_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

// ===== COLORS =====
const kOrange = Color(0xFFEA7A3B);
const kText = Color(0xFF1E1E1E);
const kMuted = Color(0xFF707883);
const kField = Color(0xFFF2F3F5);
const kCard = Colors.white;
const kShadow = Color(0x14000000);

// ===== MODELS =====
class TeaItem {
  final String key; // UI-stable key (Item.id or composite fallback)
  final String? itemId; // server id (nullable if backend didn’t send)
  final String name;
  final String desc;
  final String brand;

  TeaItem({
    required this.key,
    required this.itemId,
    required this.name,
    required this.desc,
    required this.brand,
  });
}


List<TeaItem> mapItemsToTea(List<Item> raw) {
  return raw.asMap().entries.map((entry) {
    final i = entry.value;
    final idx = entry.key;

    final id = (i.id ?? '').trim();
    final name = (i.itemName ?? i.name ?? 'Unknown Product').trim();
    final desc = (i.itemDesc ?? '').trim();
    final brand =
        (i.brand ?? '').trim().isNotEmpty ? i.brand!.trim() : 'Meezan';

    final key = id.isNotEmpty ? id : '$name|$brand|$idx';
    return TeaItem(
      key: key,
      itemId: id.isNotEmpty ? id : null,
      name: name,
      desc: desc,
      brand: brand,
    );
  }).toList();
}

class CartLineDto {
  final String? itemId;
  final String name;
  final String brand;
  final int qty;
  final String key;

  CartLineDto({
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
  String? shopId, // include if backend wants it
}) {
  final lines = <CartLineDto>[];

  cart.forEach((key, qty) {
    final item = allItems.firstWhere(
      (t) => t.key == key,
      orElse: () => TeaItem(
          key: key, itemId: null, name: 'Unknown', desc: '', brand: 'Meezan'),
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
    "shopId": shopId, // optional if needed
    "totalQty": totalQty,
    "items": lines.map((e) => e.toJson()).toList(),
  };
}


Future<OrderSubmitResult> sendCartToApi({
  required BuildContext context,
  required Map<String, dynamic> legacyPayload, // the ORDER payload
  required String endpoint,
  required String userId,
  required String distId,
  Map<String, String>? extraHeaders,          // optional: auth, accept, etc.
  String requestField = 'request',             // {"request":"<json>"}
  bool navigateToRecordsOnSuccess = true,
}) async {
  final uri = Uri.parse(endpoint);

  // enforce form encoding
  final headers = {...?extraHeaders};
  headers.removeWhere((k, _) => k.toLowerCase() == 'content-type');
  headers['Content-Type'] = 'application/x-www-form-urlencoded';

  // {"request":"<json>"}
  final Map<String, String> body = { requestField: jsonEncode(legacyPayload) };

  debugPrint('➡️ /order body: $body');
  final res = await http.post(uri, headers: headers, body: body);
  debugPrint('⬅️ /order ${res.statusCode}: ${res.body}');

  Map<String, dynamic>? parsed;
  String? message;
  bool ok = res.statusCode >= 200 && res.statusCode < 300;

  try {
    final d = jsonDecode(res.body);
    if (d is Map<String, dynamic>) {
      parsed = d;
      // common message fields your API might use
      message = (d['message'] ?? d['msg'] ?? d['error'] ?? d['status'] ?? '').toString();
      if (d.containsKey('isSuccess')) ok = ok && (d['isSuccess'] == true);
      // if your API returns success flags differently, add here
      if (d.containsKey('success') && d['success'] is bool) ok = ok && d['success'] == true;
    }
  } catch (_) {
    // leave parsed=null, ok stays as HTTP success
  }

  // Persist on success
  if (ok) {
    final rec = OrderRecord(
      id: (legacyPayload['unique'] ?? '').toString(),
      userId: userId,
      distId: distId,
      dateStr: (legacyPayload['date'] ?? '').toString(),
      status: 'Success',
      payload: legacyPayload,
      httpStatus: res.statusCode,
      serverBody: res.body,
      createdAt: DateTime.now(),
    );
    await OrdersStorage().addOrder(userId, rec);

    if (navigateToRecordsOnSuccess && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RecordsScreen()),
      );
    }
  }

  return OrderSubmitResult(
    success: ok,
    statusCode: res.statusCode,
    rawBody: res.body,
    json: parsed,
    serverMessage: (message?.isEmpty ?? true) ? null : message,
  );
}


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

  Future<void> save(
      Map<String, int> cart, String? userId, String? shopId) async {
    final clean = Map.of(cart)..removeWhere((_, q) => q <= 0);
    await _box.write(_key(userId, shopId), jsonEncode(clean));
  }

  Future<void> clear(String? userId, String? shopId) async {
    await _box.remove(_key(userId, shopId));
  }
}

// ===== MAIN CATALOG SCREEN (scoped by shopId) =====
class MeezanTeaCatalog extends StatefulWidget {
  /// Pass the unique shop/store id here.
  /// If you don’t have a separate shop id, pass distributorId (or similar).
  final String shopId;

  const MeezanTeaCatalog({super.key, required this.shopId});

  @override
  State<MeezanTeaCatalog> createState() => _MeezanTeaCatalogState();
}

class _MeezanTeaCatalogState extends State<MeezanTeaCatalog> {
  final _search = TextEditingController();
  String _selectedLine = "All";

  final Map<String, int> _cart = {};
  final _storage = CartStorage();
  String? _activeUserId;
  String? _activeDistributorId;
  String? _activeShopId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final login = context.read<GlobalBloc>().state.loginModel;
      _activeUserId = login?.userinfo?.userId;

      _activeDistributorId = login?.distributors.isNotEmpty == true
          ? login!.distributors.first.id
          : null;

      _activeShopId = widget.shopId; // per-shop scope

      final saved = _storage.load(_activeUserId, _activeShopId);
      setState(() {
        _cart
          ..clear()
          ..addAll(saved);
      });
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _persist() =>
      _storage.save(_cart, _activeUserId, _activeShopId);

  int _getQty(String key) => _cart[key] ?? 0;

  void _inc(TeaItem item) {
    setState(() => _cart[item.key] = _getQty(item.key) + 1);
    _persist();
  }

  void _dec(TeaItem item) {
    setState(() {
      final q = _getQty(item.key);
      if (q > 1) {
        _cart[item.key] = q - 1;
      } else {
        _cart.remove(item.key);
      }
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {



    final t = Theme.of(context).textTheme;

    final login = context.read<GlobalBloc>().state.loginModel; // ← your bloc
    final userId = login?.userinfo?.userId;
    final distributorId = login?.distributors.isNotEmpty == true
        ? login!.distributors.first.id
        : null;

    final List<Item> rawItems = login?.items ?? const <Item>[]; // ← your model
    final List<TeaItem> items = mapItemsToTea(rawItems);

    // Brands (chips)
    final List<String> lines = [
      "All",
      ...{for (var i in items) i.brand}.where((line) => line.isNotEmpty),
    ];

    // Filter
    final query = _search.text.trim().toLowerCase();
    final filteredItems = items.where((e) {
      final lineOk = _selectedLine == "All" || e.brand == _selectedLine;
      final searchOk = query.isEmpty ||
          e.name.toLowerCase().contains(query) ||
          e.desc.toLowerCase().contains(query);
      return lineOk && searchOk;
    }).toList();

    final totalItems = _cart.values.fold<int>(0, (a, b) => a + b);


    

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text("Products",
            style: t.titleLarge
                ?.copyWith(color: kText, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Badge + My List
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
        shopId: _activeShopId ?? widget.shopId, // ⬅️ pass shop id
        allItems: items,
        cart: _cart,
        onIncrement: _inc,
        onDecrement: _dec,
        getPayloadMeta: () => Tuple2(userId, distributorId),
      ),
    ),
  );

  if (result?['submitted'] == true) {
    setState(() => _cart.clear());
    await _storage.clear(_activeUserId, _activeShopId);
    // ⬅️ bubble up to OrderMenuScreen
    if (mounted) Navigator.pop(context, result);
  } else {
    setState(() {}); 
  }
},


                 /* onPressed: () async {
  final result = await Navigator.of(context).push<Map<String, dynamic>>(
    MaterialPageRoute(
      builder: (_) => _MyListView(
        shopId: widget.shopId,
        allItems: items,
        cart: _cart,
        onIncrement: _inc,
        onDecrement: _dec,
        getPayloadMeta: () => Tuple2(userId, distributorId),
      ),
    ),
  );

  // ✅ No API calls here. Only react to the result.
  if (result?['submitted'] == true) {
    setState(() => _cart.clear());
    await _storage.clear(_activeUserId, _activeShopId);
  } else {
    setState(() {}); 
  }
},*/
                ),
                if (totalItems > 0)
                  Positioned(
                    right: 6,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: kOrange,
                          borderRadius: BorderRadius.circular(999)),
                      child: Text('$totalItems',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
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
                boxShadow: const [
                  BoxShadow(color: kShadow, blurRadius: 12, offset: Offset(0, 6))
                ],
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
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
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
              scrollDirection: Axis.horizontal, // ✅ fixed
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
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : kText,
                      fontWeight: FontWeight.w600),
                  backgroundColor: Colors.white,
                  shape: StadiumBorder(
                      side: BorderSide(
                          color: selected
                              ? Colors.transparent
                              : const Color(0xFFEDEFF2))),
                  elevation: selected ? 2 : 0,
                );
              },
            ),
          ),

          // Counts
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text('${filteredItems.length} products',
                    style: t.bodySmall?.copyWith(color: kMuted)),
                const Spacer(),
                if (totalItems > 0)
                  Text('In list: $totalItems',
                      style: t.bodySmall?.copyWith(
                          color: kOrange, fontWeight: FontWeight.w700)),
              ],
            ),
          ),

          // Product list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              itemCount: filteredItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final item = filteredItems[i];
                return _ProductCard(
                  name: item.name,
                  desc: item.desc,
                  brand: item.brand,
                  qty: _cart[item.key] ?? 0,
                  onIncrement: () => _inc(item),
                  onDecrement: () => _dec(item),
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
  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ProductCard({
    required this.name,
    required this.desc,
    required this.brand,
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kOrange, Color(0xFFFFB07A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          margin: const EdgeInsets.all(1.6),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14.4),
            boxShadow: const [
              BoxShadow(color: kShadow, blurRadius: 14, offset: Offset(0, 8))
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: kField, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.local_cafe_rounded, color: kOrange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TagPill(text: brand),
                    const SizedBox(height: 6),
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleMedium?.copyWith(
                            color: kText, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(color: kMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _QtyControls(qty: qty, onInc: onIncrement, onDec: onDecrement),
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
      child: Text(text,
          style: const TextStyle(
              color: kText, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _QtyControls extends StatelessWidget {
  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;
  const _QtyControls(
      {required this.qty, required this.onInc, required this.onDec, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (qty <= 0) {
      return TextButton(
        style: TextButton.styleFrom(
          backgroundColor: kOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onInc,
        child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
      );
    }
    return Container(
      decoration:
          BoxDecoration(color: kField, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onDec,
              icon: const Icon(Icons.remove_rounded, size: 20, color: kText)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('$qty',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, color: kText)),
          ),
          IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onInc,
              icon: const Icon(Icons.add_rounded, size: 20, color: kText)),
        ],
      ),
    );
  }
}


class _MyListView extends StatefulWidget {
  final List<TeaItem> allItems;
  final Map<String, int> cart; // live reference to parent cart
  final void Function(TeaItem) onIncrement;
  final void Function(TeaItem) onDecrement;
  final Tuple2<String?, String?> Function()? getPayloadMeta;

  // ✅ NEW: needed to persist reason and send events
  final String shopId; // miscid

  const _MyListView({
    required this.allItems,
    required this.cart,
    required this.onIncrement,
    required this.onDecrement,
    this.getPayloadMeta,
    required this.shopId,
    Key? key,
  }) : super(key: key);

  @override
  State<_MyListView> createState() => _MyListViewState();
}

class _MyListViewState extends State<_MyListView> {
  List<_CartRow> get _rows {
    final rows = <_CartRow>[];
    widget.cart.forEach((key, qty) {
      final item = widget.allItems.firstWhere(
        (e) => e.key == key,
        orElse: () => TeaItem(
          key: key, itemId: null, name: 'Unknown', desc: '', brand: 'Meezan'),
      );
      rows.add(_CartRow(item: item, qty: qty));
    });
    rows.sort((a, b) => a.item.name.compareTo(b.item.name));
    return rows;
  }

  int get _totalQty => widget.cart.values.fold(0, (a, b) => a + b);

  Future<void> _submitOrder() async {
    final login = context.read<GlobalBloc>().state.loginModel;

    final userId = (login?.userinfo?.userId ?? '').trim();
    final distId = (login?.distributors.isNotEmpty == true
        ? (login!.distributors.first.id ?? '')
        : '').trim();

    if (userId.isEmpty || distId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User or Distributor not found')),
      );
      return;
    }

    // ⚠️ Keep your existing payload builder as-is
    final orderPayload = buildLegacyOrderPayloadFromTea(
      allItems: widget.allItems,
      cart: widget.cart,
      userId: userId,
      distId: distId,
    );

    debugPrint('🧾 ORDER payload:\n${const JsonEncoder.withIndent("  ").convert(orderPayload)}');

    final result = await sendCartToApi(
      context: context,
      legacyPayload: orderPayload,
      endpoint: 'http://services.zankgroup.com/motivesteang/index.php?route=api/user/transaction',
      userId: userId,
      distId: distId,
      requestField: 'request',
      navigateToRecordsOnSuccess: false,
    );

    debugPrint('✅ success=${result.success}  status=${result.statusCode}');
    if (result.json != null) {
      debugPrint('🧩 response JSON:\n${const JsonEncoder.withIndent("  ").convert(result.json)}');
    } else {
      debugPrint('🧩 response (raw): ${result.rawBody}');
    }

   final msg = result.success
    ? (result.serverMessage ?? 'Order submitted successfully')
    : (result.serverMessage ?? 'Order submit failed');

if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

if (result.success) {
  widget.cart.clear();
  // ⬅️ propagate to parent screens with the shop id and status
  Navigator.pop<Map<String, dynamic>>(context, {
    'submitted': true,
    'miscid': widget.shopId,
    'reason': 'Order placed',
  });
}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

    if (!result.success) return;

    // ─────────────────────────────────────────────────────────────────────
    // ✅ On success: fire ORDER (type 7) + CHECKOUT (type 6) and persist reason
    // ─────────────────────────────────────────────────────────────────────
    final gb = context.read<GlobalBloc>();

    String lat = '0', lng = '0';
    try {
      final l = await loc.Location().getLocation();
      lat = (l.latitude ?? 0).toString();
      lng = (l.longitude ?? 0).toString();
    } catch (_) {/* ignore location failure */}

    // Optional ORDER record (reason trail)
    gb.add(CheckinCheckoutEvent(
      type: '7', // ORDER reason
      userId: userId,
      lat: lat,
      lng: lng,
      act_type: 'ORDER',
      action: 'Order placed',
      misc: widget.shopId,    // miscid
      dist_id: distId,
    ));

    // Mandatory CHECKOUT
    gb.add(CheckinCheckoutEvent(
      type: '6', // CHECK OUT
      userId: userId,
      lat: lat,
      lng: lng,
      act_type: 'SHOP_CHECK',
      action: 'OUT',
      misc: widget.shopId,
      dist_id: distId,
    ));

    // Persist "Order placed" against this shop id
    final box = GetStorage();
    final raw = box.read('journey_reasons');
    final reasons = <String, String>{};
    if (raw is Map) {
      raw.forEach((k, v) => reasons[k.toString()] = v.toString());
    }
    reasons[widget.shopId] = 'Order placed';
    await box.write('journey_reasons', reasons);

    // optional (keep status consistent)
    final stRaw = box.read('journey_status');
    final st = (stRaw is Map) ? Map<String, dynamic>.from(stRaw) : <String, dynamic>{};
    st[widget.shopId] = {'checkedIn': false, 'last': 'none', 'holdUI': false};
    await box.write('journey_status', st);

    // Clear live cart and bubble result up
    widget.cart.clear();
    if (!mounted) return;
    Navigator.pop<Map<String, dynamic>>(context, {
      'submitted': true,
      'miscid': widget.shopId,
      'reason': 'Order placed',
    });
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
        title: Text('My List',
            style: t.titleLarge?.copyWith(color: kText, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kOrange, Color(0xFFFFB07A)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: kShadow, blurRadius: 14, offset: Offset(0, 8))],
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Items in your list: $_totalQty',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                              color: kField, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.local_cafe_rounded, color: kOrange),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TagPill(text: row.item.brand),
                              const SizedBox(height: 6),
                              Text(row.item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.titleMedium?.copyWith(
                                      color: kText, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(row.item.desc,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.bodySmall?.copyWith(color: kMuted)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _QtyControls(
                          qty: row.qty,
                          onInc: () { widget.onIncrement(row.item); setState(() {}); },
                          onDec: () { widget.onDecrement(row.item); setState(() {}); },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 52),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _rows.isEmpty ? null : _submitOrder,
                child: const Text('Confirm & Send',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartRow {
  final TeaItem item;
  final int qty;
  _CartRow({required this.item, required this.qty});
}


/*class _MyListView extends StatefulWidget {
  final List<TeaItem> allItems;
  final Map<String, int> cart; // live reference to parent cart
  final void Function(TeaItem) onIncrement;
  final void Function(TeaItem) onDecrement;
  final Tuple2<String?, String?> Function()? getPayloadMeta;

  const _MyListView({
    required this.allItems,
    required this.cart,
    required this.onIncrement,
    required this.onDecrement,
    this.getPayloadMeta,
    Key? key,
  }) : super(key: key);

  @override
  State<_MyListView> createState() => _MyListViewState();
}

class _MyListViewState extends State<_MyListView> {
  List<_CartRow> get _rows {
    final rows = <_CartRow>[];
    widget.cart.forEach((key, qty) {
      final item = widget.allItems.firstWhere(
        (e) => e.key == key,
        orElse: () => TeaItem(
          key: key, itemId: null, name: 'Unknown', desc: '', brand: 'Meezan'),
      );
      rows.add(_CartRow(item: item, qty: qty));
    });
    rows.sort((a, b) => a.item.name.compareTo(b.item.name));
    return rows;
  }

  int get _totalQty => widget.cart.values.fold(0, (a, b) => a + b);

Future<void> _submitOrder() async {
  final login = context.read<GlobalBloc>().state.loginModel;

  final userId = (login?.userinfo?.userId ?? '').trim();
  final distId = (login?.distributors.isNotEmpty == true ? (login!.distributors.first.id ?? '') : '').trim();
  if (userId.isEmpty || distId.isEmpty) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User or Distributor not found')),
    );
    return;
  }

  final orderPayload = buildLegacyOrderPayloadFromTea(
    allItems: widget.allItems,
    cart: widget.cart,
    userId: userId,
    distId: distId,
    // override header fields if you have dynamic values
  );

  // Optional: pretty-print the outgoing payload
  debugPrint('🧾 ORDER payload:\n${const JsonEncoder.withIndent("  ").convert(orderPayload)}');

  final result = await sendCartToApi(
    context: context,
    legacyPayload: orderPayload,
    endpoint: 'http://services.zankgroup.com/motivesteang/index.php?route=api/user/transaction',   // your order URL
    userId: userId,
    distId: distId,
    // extraHeaders: {'Accept': 'application/json'}, // optional
    requestField: 'request',
    navigateToRecordsOnSuccess: true,
  );

  // 🔊 Print/log outcome
  debugPrint('✅ success=${result.success}  status=${result.statusCode}');
  if (result.json != null) {
    debugPrint('🧩 response JSON:\n${const JsonEncoder.withIndent("  ").convert(result.json)}');
  } else {
    debugPrint('🧩 response (raw): ${result.rawBody}');
  }

  // Show a user-facing message
  final msg = result.success
      ? (result.serverMessage ?? 'Order submitted successfully')
      : (result.serverMessage ?? 'Order submit failed');
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  if (result.success) {
    // Clear live cart and notify parent so it clears persisted cart too
    widget.cart.clear();
    Navigator.pop<Map<String, dynamic>>(context, {'submitted': true});
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
        title: Text('My List',
            style: t.titleLarge?.copyWith(color: kText, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kOrange, Color(0xFFFFB07A)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: kShadow, blurRadius: 14, offset: Offset(0, 8))],
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Items in your list: $_totalQty',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                              color: kField, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.local_cafe_rounded, color: kOrange),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TagPill(text: row.item.brand),
                              const SizedBox(height: 6),
                              Text(row.item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.titleMedium?.copyWith(
                                      color: kText, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(row.item.desc,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.bodySmall?.copyWith(color: kMuted)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _QtyControls(
                          qty: row.qty,
                          onInc: () {
                            widget.onIncrement(row.item);
                            setState(() {});
                          },
                          onDec: () {
                            widget.onDecrement(row.item);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // ✅ Button now calls _submitOrder (not _returnPayload)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 52),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _rows.isEmpty ? null : _submitOrder,
                child: const Text('Confirm & Send',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/

// class _CartRow {
//   final TeaItem item;
//   final int qty;
//   _CartRow({required this.item, required this.qty});
// }

// Tiny Tuple helper
class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;
  const Tuple2(this.item1, this.item2);
}
