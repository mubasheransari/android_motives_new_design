import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';

import 'Models/login_model.dart';

// meezan_tea_catalog.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

// ===== THEME =====
const kOrange = Color(0xFFEA7A3B);
const kText = Color(0xFF1E1E1E);
const kMuted = Color(0xFF707883);
const kField = Color(0xFFF2F3F5);
const kCard = Colors.white;
const kShadow = Color(0x14000000);

// ===== LIGHT UI MODEL (built from your LoginModel.items) =====
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

/// Convert your List<Item> → List<TeaItem>
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
  final String key; // client fallback (composite)

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

/// Build the request payload from cart
Map<String, dynamic> buildCartRequest({
  required List<TeaItem> allItems,
  required Map<String, int> cart,
  String? userId,
  String? distributorId,
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
    "userId": userId, // optional – use if needed by backend
    "distributorId": distributorId, // optional – use if needed
    "totalQty": totalQty,
    "items": lines.map((e) => e.toJson()).toList(),
  };
}

/// Example sender (adjust endpoint/headers as needed)
Future<void> sendCartToApi(
  Map<String, dynamic> payload, {
  String endpoint =
      'https://your.api/orders', // TODO: replace with real endpoint
  Map<String, String>? extraHeaders,
}) async {
  final uri = Uri.parse(endpoint);
  final res = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer <token>',
      ...?extraHeaders,
    },
    body: jsonEncode(payload),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('API error ${res.statusCode}: ${res.body}');
  }
  // Optionally parse: final data = jsonDecode(res.body);
}

// ===== MAIN CATALOG SCREEN =====
class MeezanTeaCatalog extends StatefulWidget {
  const MeezanTeaCatalog({super.key});
  @override
  State<MeezanTeaCatalog> createState() => _MeezanTeaCatalogState();
}

class _MeezanTeaCatalogState extends State<MeezanTeaCatalog> {
  final _search = TextEditingController();
  String _selectedLine = "All";

  // simple in-memory cart: key => qty
  final Map<String, int> _cart = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    // ── Read your LoginModel from GlobalBloc ──
    final login = context.read<GlobalBloc>().state.loginModel;
    final userId = login?.userinfo?.userId; // optional metadata if needed
    final distributorId = login?.distributors.isNotEmpty == true
        ? login!.distributors.first.id
        : null;

    final List<Item> rawItems = login?.items ?? const <Item>[];
    final List<TeaItem> items = mapItemsToTea(rawItems);

    // Brands for chips
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

    int getQty(String key) => _cart[key] ?? 0;
    void inc(TeaItem item) =>
        setState(() => _cart[item.key] = getQty(item.key) + 1);
    void dec(TeaItem item) => setState(() {
          final q = getQty(item.key);
          if (q > 1)
            _cart[item.key] = q - 1;
          else
            _cart.remove(item.key);
        });

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
                    final Tuple2<String?, String?> Function()? getPayloadMeta;
                    // Open My List and optionally receive a payload if user submitted there
                    final payload =
                        await Navigator.of(context).push<Map<String, dynamic>>(
                      MaterialPageRoute(
                        builder: (_) => _MyListView(
                          allItems: items,
                          cart: _cart,
                          onIncrement: inc,
                          onDecrement: dec,
                          // Provide identity (optional)
                          getPayloadMeta: () => Tuple2(userId, distributorId),
                        ),
                      ),
                    );

                    if (payload != null) {
                      // Option 1: Send here if you prefer centralizing API calls
                      try {
                        await sendCartToApi(
                          payload,
                          endpoint: 'https://your.api/orders', // TODO: change
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Order submitted successfully')),
                          );
                        }
                        setState(() {
                          _cart.clear(); // clear after success (optional)
                        });
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Submit failed: $e')),
                          );
                        }
                      }
                    } else {
                      setState(
                          () {}); // refresh badge/count if user adjusted list only
                    }
                  },
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
                  BoxShadow(
                      color: kShadow, blurRadius: 12, offset: Offset(0, 6))
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
                        hintText:
                            'Search products (e.g. Gold, Green Tea, 475g)',
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
                  onIncrement: () => inc(item),
                  onDecrement: () => dec(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===== PRODUCT CARD WITH +/– =====
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
  });

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
  const _TagPill({required this.text});
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
      {required this.qty, required this.onInc, required this.onDec});

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

// ===== NEW ORANGE/WHITE "MY LIST" VIEW =====
class _MyListView extends StatefulWidget {
  final List<TeaItem> allItems;
  final Map<String, int> cart; // live reference to parent cart
  final void Function(TeaItem) onIncrement;
  final void Function(TeaItem) onDecrement;

  // pass a getter to fetch (userId, distributorId)
  final Tuple2<String?, String?> Function()? getPayloadMeta;

  const _MyListView({
    required this.allItems,
    required this.cart,
    required this.onIncrement,
    required this.onDecrement,
    this.getPayloadMeta,
  });

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

  Future<void> _confirmAndSend() async {
    final meta = widget.getPayloadMeta?.call();
    final userId = meta?.item1;
    final distributorId = meta?.item2;

    final payload = buildCartRequest(
      allItems: widget.allItems,
      cart: widget.cart,
      userId: userId,
      distributorId: distributorId,
    );

    // Option A: Submit here and pop null/ payload as you like
    try {
      await sendCartToApi(
        payload,
        endpoint: 'https://your.api/orders', // TODO: replace
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order submitted successfully')),
      );
      // return payload to previous screen for any follow-up
      Navigator.pop<Map<String, dynamic>>(context, payload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed: $e')),
      );
    }

    // Option B: If you want to submit in the caller screen instead:
    // Navigator.pop(context, payload);
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
            style: t.titleLarge
                ?.copyWith(color: kText, fontWeight: FontWeight.w700)),
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
              boxShadow: const [
                BoxShadow(color: kShadow, blurRadius: 14, offset: Offset(0, 8))
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Items in your list: $_totalQty',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),

          if (_rows.isEmpty)
            Expanded(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.local_grocery_store_outlined,
                      size: 56, color: kMuted),
                  const SizedBox(height: 8),
                  Text('Your list is empty',
                      style: t.titleMedium?.copyWith(color: kText)),
                  const SizedBox(height: 4),
                  Text('Add products from the catalog.',
                      style: t.bodySmall?.copyWith(color: kMuted)),
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
                      boxShadow: const [
                        BoxShadow(
                            color: kShadow,
                            blurRadius: 12,
                            offset: Offset(0, 6))
                      ],
                      border: Border.all(color: const Color(0xFFEDEFF2)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                              color: kField,
                              borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.local_cafe_rounded,
                              color: kOrange),
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
                                      color: kText,
                                      fontWeight: FontWeight.w700)),
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

          // Confirm & Send button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _rows.isEmpty ? null : _confirmAndSend,
                child: const Text('Confirm & Send',
                    style: TextStyle(fontWeight: FontWeight.w700)),
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

// ===== Tiny Tuple helper (avoid extra package) =====
class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;
  const Tuple2(this.item1, this.item2);
}

/*

// ===== THEME =====
const kOrange = Color(0xFFEA7A3B);
const kText   = Color(0xFF1E1E1E);
const kMuted  = Color(0xFF707883);
const kField  = Color(0xFFF2F3F5);
const kCard   = Colors.white;
const kShadow = Color(0x14000000);

// ===== YOUR LIGHT UI MODEL (from LoginModel.items) =====
class TeaItem {
  final String key;      // stable key based on Item.id or fallback
  final String name;
  final String desc;
  final String brand;

  TeaItem({
    required this.key,
    required this.name,
    required this.desc,
    required this.brand,
  });
}

// Convert your List<Item> → List<TeaItem>
List<TeaItem> mapItemsToTea(List<Item> raw) {
  return raw.asMap().entries.map((entry) {
    final i   = entry.value;
    final idx = entry.key;

    final id    = (i.id ?? '').trim();
    final name  = (i.itemName ?? i.name ?? 'Unknown Product').trim();
    final desc  = (i.itemDesc ?? '').trim();
    final brand = (i.brand ?? '').trim().isNotEmpty ? i.brand!.trim() : 'Meezan';

    final key = id.isNotEmpty ? id : '$name|$brand|$idx';
    return TeaItem(key: key, name: name, desc: desc, brand: brand);
  }).toList();
}

// ===== MAIN CATALOG SCREEN =====
class MeezanTeaCatalog extends StatefulWidget {
  const MeezanTeaCatalog({super.key});
  @override
  State<MeezanTeaCatalog> createState() => _MeezanTeaCatalogState();
}

class _MeezanTeaCatalogState extends State<MeezanTeaCatalog> {
  final _search = TextEditingController();
  String _selectedLine = "All";

  // simple in-memory cart: key => qty
  final Map<String, int> _cart = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    // 1) Read your LoginModel from GlobalBloc
    final login = context.read<GlobalBloc>().state.loginModel;
    final List<Item> rawItems = login?.items ?? const <Item>[];

    // 2) Map to UI model
    final List<TeaItem> items = mapItemsToTea(rawItems);

    // 3) Build unique brand lines
    final List<String> lines = [
      "All",
      ...{for (var i in items) i.brand}.where((line) => line.isNotEmpty),
    ];

    // 4) Filter by brand + search
    final query = _search.text.trim().toLowerCase();
    final filteredItems = items.where((e) {
      final lineOk = _selectedLine == "All" || e.brand == _selectedLine;
      final searchOk = query.isEmpty ||
          e.name.toLowerCase().contains(query) ||
          e.desc.toLowerCase().contains(query);
      return lineOk && searchOk;
    }).toList();

    int getQty(String key) => _cart[key] ?? 0;
    void inc(TeaItem item) => setState(() => _cart[item.key] = getQty(item.key) + 1);
    void dec(TeaItem item) => setState(() {
      final q = getQty(item.key);
      if (q > 1) _cart[item.key] = q - 1; else _cart.remove(item.key);
    });

    final totalItems = _cart.values.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text("Products", style: t.titleLarge?.copyWith(color: kText, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // My List button with badge
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, color: kText),
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => _MyListView(
                        allItems: items,
                        cart: _cart,
                        onIncrement: inc,
                        onDecrement: dec,
                      ),
                    ));
                    setState(() {}); // refresh badge on return
                  },
                ),
                if (totalItems > 0)
                  Positioned(
                    right: 6, top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(999)),
                      child: Text('$totalItems', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
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

          // Counts
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text('${filteredItems.length} products', style: t.bodySmall?.copyWith(color: kMuted)),
                const Spacer(),
                if (totalItems > 0)
                  Text('In list: $totalItems', style: t.bodySmall?.copyWith(color: kOrange, fontWeight: FontWeight.w700)),
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
                  onIncrement: () => inc(item),
                  onDecrement: () => dec(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
  });

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
            boxShadow: const [BoxShadow(color: kShadow, blurRadius: 14, offset: Offset(0, 8))],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TagPill(text: brand),
                    const SizedBox(height: 6),
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: t.titleMedium?.copyWith(color: kText, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis,
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
  const _TagPill({required this.text});
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

class _QtyControls extends StatelessWidget {
  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;
  const _QtyControls({required this.qty, required this.onInc, required this.onDec});

  @override
  Widget build(BuildContext context) {
    if (qty <= 0) {
      return TextButton(
        style: TextButton.styleFrom(
          backgroundColor: kOrange, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onInc,
        child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
      );
    }
    return Container(
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
    );
  }
}

// ===== NEW ORANGE/WHITE "MY LIST" VIEW =====
class _MyListView extends StatefulWidget {
  final List<TeaItem> allItems;
  final Map<String, int> cart; // live reference
  final void Function(TeaItem) onIncrement;
  final void Function(TeaItem) onDecrement;

  const _MyListView({
    required this.allItems,
    required this.cart,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  State<_MyListView> createState() => _MyListViewState();
}

class _MyListViewState extends State<_MyListView> {
  List<_CartRow> get _rows {
    final rows = <_CartRow>[];
    widget.cart.forEach((key, qty) {
      final item = widget.allItems.firstWhere(
        (e) => e.key == key,
        orElse: () => TeaItem(key: key, name: 'Unknown', desc: '', brand: 'Meezan'),
      );
      rows.add(_CartRow(item: item, qty: qty));
    });
    rows.sort((a, b) => a.item.name.compareTo(b.item.name));
    return rows;
  }

  int get _totalQty => widget.cart.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
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
              gradient: const LinearGradient(
                colors: [kOrange, Color(0xFFFFB07A)],
                begin: Alignment.centerLeft, end: Alignment.centerRight,
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
                          width: 52, height: 52,
                          decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.local_cafe_rounded, color: kOrange),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TagPill(text: row.item.brand),
                              const SizedBox(height: 6),
                              Text(row.item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: t.titleMedium?.copyWith(color: kText, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(row.item.desc, maxLines: 2, overflow: TextOverflow.ellipsis,
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
*/


// 🔹 Theme constants
// const kOrange = Color(0xFFEA7A3B);
// const kText   = Color(0xFF1E1E1E);
// const kMuted  = Color(0xFF707883);
// const kField  = Color(0xFFF2F3F5);
// const kCard   = Colors.white;
// const kShadow = Color(0x14000000);

// class MeezanTeaCatalog extends StatefulWidget {
//   const MeezanTeaCatalog({super.key});

//   @override
//   State<MeezanTeaCatalog> createState() => _MeezanTeaCatalogState();
// }

// class _MeezanTeaCatalogState extends State<MeezanTeaCatalog> {
//   final _search = TextEditingController();
//   String _selectedLine = "All";

//   @override
//   void dispose() {
//     _search.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     // 🔹 Get items from bloc
//     final items = context.read<GlobalBloc>().state.loginModel?.items ?? [];

//     // 🔹 Build unique product lines dynamically
//     final List<String> lines = [
//       "All",
//       ...{for (var i in items) i.brand?.trim() ?? ""}
//           .where((line) => line.isNotEmpty),
//     ];

//     // 🔍 Filter items based on line & search
//     final filteredItems = items.where((e) {
//       final lineOk = _selectedLine == "All" || e.brand == _selectedLine;
//       final query = _search.text.trim().toLowerCase();
//       final searchOk = query.isEmpty ||
//           (e.itemName?.toLowerCase().contains(query) ?? false) ||
//           (e.itemDesc?.toLowerCase().contains(query) ?? false);
//       return lineOk && searchOk;
//     }).toList();

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         title: Text(
//           "Products",
//           style: t.titleLarge?.copyWith(
//             color: kText,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),
//       body: Column(
//         children: [
//           // 🔍 Search box
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: kCard,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: const [
//                   BoxShadow(
//                     color: kShadow,
//                     blurRadius: 12,
//                     offset: Offset(0, 6),
//                   ),
//                 ],
//                 border: Border.all(color: Color(0xFFEDEFF2)),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Row(
//                 children: [
//                   Icon(Icons.search_rounded, color: kMuted.withOpacity(.9)),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: TextField(
//                       controller: _search,
//                       onChanged: (_) => setState(() {}),
//                       decoration: const InputDecoration(
//                         hintText: 'Search products (e.g. Gold, Green Tea, 475g)',
//                         hintStyle: TextStyle(color: kMuted),
//                         border: InputBorder.none,
//                       ),
//                     ),
//                   ),
//                   if (_search.text.isNotEmpty)
//                     IconButton(
//                       onPressed: () {
//                         _search.clear();
//                         setState(() {});
//                       },
//                       icon: const Icon(Icons.close_rounded, color: kMuted),
//                     ),
//                 ],
//               ),
//             ),
//           ),

//           // 🔹 Line filter chips
//           SizedBox(
//             height: 44,
//             child: ListView.separated(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               scrollDirection: Axis.horizontal,
//               itemCount: lines.length,
//               separatorBuilder: (_, __) => const SizedBox(width: 8),
//               itemBuilder: (_, i) {
//                 final label = lines[i];
//                 final selected = _selectedLine == label;
//                 return ChoiceChip(
//                   label: Text(label),
//                   selected: selected,
//                   onSelected: (_) => setState(() => _selectedLine = label),
//                   selectedColor: kOrange,
//                   labelStyle: TextStyle(
//                     color: selected ? Colors.white : kText,
//                     fontWeight: FontWeight.w600,
//                   ),
//                   backgroundColor: Colors.white,
//                   shape: StadiumBorder(
//                     side: BorderSide(
//                       color: selected
//                           ? Colors.transparent
//                           : const Color(0xFFEDEFF2),
//                     ),
//                   ),
//                   elevation: selected ? 2 : 0,
//                 );
//               },
//             ),
//           ),

//           // 📊 Count of products
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
//             child: Row(
//               children: [
//                 Text(
//                   '${filteredItems.length} products',
//                   style: t.bodySmall?.copyWith(color: kMuted),
//                 ),
//               ],
//             ),
//           ),

//           // 📋 Product list
//           Expanded(
//             child: ListView.separated(
//               padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
//               itemCount: filteredItems.length,
//               separatorBuilder: (_, __) => const SizedBox(height: 12),
//               itemBuilder: (_, i) {
//                 final item = filteredItems[i];
//                 return _ProductCard(
//                   name: item.itemName ?? "Unknown Product",
//                   desc: item.itemDesc ?? "No description",
//                   brand: item.brand ?? "Meezan",
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // 🔹 Product card (UI same as your catalog design)
// class _ProductCard extends StatelessWidget {
//   final String name;
//   final String desc;
//   final String brand;

//   const _ProductCard({
//     required this.name,
//     required this.desc,
//     required this.brand,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return InkWell(
//       borderRadius: BorderRadius.circular(16),
//       onTap: () {},
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: [kOrange, Color(0xFFFFB07A)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Container(
//           margin: const EdgeInsets.all(1.6),
//           decoration: BoxDecoration(
//             color: kCard,
//             borderRadius: BorderRadius.circular(14.4),
//             boxShadow: const [
//               BoxShadow(
//                 color: kShadow,
//                 blurRadius: 14,
//                 offset: Offset(0, 8),
//               ),
//             ],
//           ),
//           padding: const EdgeInsets.all(14),
//           child: Row(
//             children: [
//               Container(
//                 width: 52,
//                 height: 52,
//                 decoration: BoxDecoration(
//                   color: kField,
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: const Icon(Icons.local_cafe_rounded, color: kOrange),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _TagPill(text: brand),
//                     const SizedBox(height: 6),
//                     Text(
//                       name,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: t.titleMedium?.copyWith(
//                         color: kText,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       desc,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: t.bodySmall?.copyWith(color: kMuted),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // 🔹 Pill widget for brand tag
// class _TagPill extends StatelessWidget {
//   final String text;
//   const _TagPill({required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: kOrange.withOpacity(.10),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: kOrange.withOpacity(.25)),
//       ),
//       child: Text(
//         text,
//         style: const TextStyle(
//           color: kText,
//           fontWeight: FontWeight.w600,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }
// }



/*const kOrange = Color(0xFFEA7A3B);
const kText   = Color(0xFF1E1E1E);
const kMuted  = Color(0xFF707883);
const kField  = Color(0xFFF2F3F5);
const kCard   = Colors.white;
const kShadow = Color(0x14000000);



class MeezanTeaCatalog extends StatefulWidget {
  const MeezanTeaCatalog({super.key});

  @override
  State<MeezanTeaCatalog> createState() => _MeezanTeaCatalogState();
}

class _MeezanTeaCatalogState extends State<MeezanTeaCatalog> {
  String _selectedLine = "All";

  @override
  Widget build(BuildContext context) {
    final items = context.read<GlobalBloc>().state.loginModel?.items ?? [];

    // build unique lines dynamically from items
    final List<String> lines = [
      "All",
      ...{for (var i in items) i.brand?.trim() ?? ""}
        .where((line) => line.isNotEmpty)
    ];

    final filteredItems = _selectedLine == "All"
        ? items
        : items.where((e) => e.brand == _selectedLine).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Products",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Horizontal scroll filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: lines.map((line) {
                final isSelected = _selectedLine == line;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(line),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedLine = line;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Grid view of products
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final item = filteredItems[index];

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Expanded(
                        //   child: Center(
                        //     child: Icon(
                        //       Icons.local_cafe,
                        //       size: 64,
                        //       color: Colors.brown[400],
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 8),
                        Text(
                          item.itemName ?? "Unknown Product",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.itemDesc ?? "No description",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}*/





/*class MeezanTeaCatalog extends StatefulWidget {
  const MeezanTeaCatalog({super.key});

  @override
  State<MeezanTeaCatalog> createState() => _MeezanTeaCatalogState();
}

class _MeezanTeaCatalogState extends State<MeezanTeaCatalog> {
  final _search = TextEditingController();

  static const List<String> _lines = [
    'All', 'Supreme', 'Gold', 'Danedar', 'Dust', 'Green Tea', 'Kahwa'
  ];
  String _selectedLine = 'All';


  final List<TeaProduct> _all = const [
    TeaProduct(
      brand: 'Meezan',
      line: 'Supreme',
      name: 'Meezan Supreme Tea',
      size: '95 g box',
      priceRs: 180,
      rating: 4.6,
    ),
    TeaProduct(
      brand: 'Meezan',
      line: 'Supreme',
      name: 'Meezan Supreme Tea',
      size: '190 g box',
      priceRs: 340,
      rating: 4.6,
    ),
    TeaProduct(
      brand: 'Meezan',
      line: 'Supreme',
      name: 'Meezan Supreme Tea',
      size: '475 g pack',
      priceRs: 780,
      rating: 4.6,
    ),
    TeaProduct(
      brand: 'Meezan',
      line: 'Gold',
      name: 'Meezan Gold Danedar',
      size: '95 g box',
      priceRs: 220,
      rating: 4.7,
    ),
    TeaProduct(
      brand: 'Meezan',
      line: 'Gold',
      name: 'Meezan Gold Danedar',
      size: '475 g pack',
      priceRs: 990,
      rating: 4.7,
    ),
    TeaProduct(
      brand: 'Meezan',
      line: 'Danedar',
      name: 'Meezan Original Danedar',
      size: '190 g box',
      priceRs: 360,
      rating: 4.5,
    ),
    TeaProduct(
      brand: 'Meezan',
      line: 'Danedar',
      name: 'Meezan Original Danedar',
      size: '950 g pack',
      priceRs: 1890,
      rating: 4.5,
    ),
    TeaProduct(
      brand: 'Meezan',
      line: 'Dust',
      name: 'Meezan Supreme Dust',
      size: '475 g pack',
      priceRs: 760,
      rating: 4.4,
    ),
    TeaProduct(
      brand: 'Meezan',
      line: 'Green Tea',
      name: 'Meezan Green Tea Bags',
      size: '25 bags',
      priceRs: 260,
      rating: 4.3,
    ),
    TeaProduct(
      brand: 'Meezan',
      line: 'Green Tea',
      name: 'Meezan Green Tea Lemon',
      size: '25 bags',
      priceRs: 280,
      rating: 4.2,
    ),
    TeaProduct(
      brand: 'Meezan',
      line: 'Kahwa',
      name: 'Meezan Kahwa (Suleimani)',
      size: '25 bags',
      priceRs: 300,
      rating: 4.1,
    ),
  ];

  List<TeaProduct> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _all.where((p) {
      final lineOk = _selectedLine == 'All' || p.line == _selectedLine;
      if (!lineOk) return false;
      if (q.isEmpty) return true;
      // Accept both "Meezan" and "Mezan" in search
      final txt = '${p.brand} ${p.line} ${p.name} ${p.size}'.toLowerCase();
      return txt.contains(q.replaceAll('mezan', 'meezan')) ||
             txt.contains(q.replaceAll('meezan', 'mezan'));
    }).toList();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Text('Products', style: t.titleLarge?.copyWith(color: kText, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // ---- Search ----
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
                        hintText: 'Search Meezan (e.g. Gold, Green Tea, 475g)',
                        hintStyle: TextStyle(color: kMuted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_search.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded, color: kMuted),
                    ),
                ],
              ),
            ),
          ),

          // ---- Chips (Meezan product lines) ----
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: context.read<GlobalBloc>().state.loginModel!.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final label = _lines[i];
                final selected = _selectedLine == label;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedLine = label),
                  selectedColor: kOrange,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : kText,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Colors.white,
                  shape: StadiumBorder(
                    side: BorderSide(color: selected ? Colors.transparent : const Color(0xFFEDEFF2)),
                  ),
                  elevation: selected ? 2 : 0,
                );
              },
            ),
          ),

          // ---- Result count ----
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text('${_filtered.length} products', style: t.bodySmall?.copyWith(color: kMuted)),
              ],
            ),
          ),

          // ---- Product list ----
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              itemBuilder: (_, i) => TeaCard(product: _filtered[i]),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: _filtered.length,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===== Model =====
class TeaProduct {
  const TeaProduct({
    required this.brand,
    required this.line,
    required this.name,
    required this.size,
    required this.priceRs,
    required this.rating,
  });

  final String brand;   // 'Meezan'
  final String line;    // 'Supreme', 'Gold', 'Danedar', 'Dust', 'Green Tea', 'Kahwa'
  final String name;    // full display name
  final String size;    // e.g., '475 g pack', '25 bags'
  final int priceRs;    // PKR
  final double rating;  // 0..5
}

/// ===== Card UI =====
class TeaCard extends StatelessWidget {
  const TeaCard({super.key, required this.product});
  final TeaProduct product;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected: ${product.name} • ${product.size}')),
        );
      },
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
            boxShadow: const [BoxShadow(color: kShadow, blurRadius: 14, offset: Offset(0, 8))],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon tile (you can swap with real asset later)
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.local_cafe_rounded, color: kOrange),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand + Line pill
                    Row(
                      children: [
                        _TagPill(text: product.brand),
                        const SizedBox(width: 6),
                        _TagPill(text: product.line),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Name + Price
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleMedium?.copyWith(
                              color: kText, fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          'Rs ${product.priceRs}',
                          style: t.titleMedium?.copyWith(
                            color: kOrange, fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Size + rating
                    Row(
                      children: [
                        Text(product.size, style: t.bodySmall?.copyWith(color: kMuted)),
                        const Spacer(),
                        _Stars(rating: product.rating),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kOrange.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kOrange.withOpacity(.25)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: kText, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    return Row(
      children: List.generate(5, (i) {
        if (i < full)   return const Icon(Icons.star_rounded,       color: kOrange, size: 18);
        if (i == full && half) return const Icon(Icons.star_half_rounded, color: kOrange, size: 18);
        return const Icon(Icons.star_border_rounded, color: kOrange, size: 18);
      }),
    );
  }
}
*/