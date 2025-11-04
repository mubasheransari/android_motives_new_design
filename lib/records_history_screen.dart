import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Models/login_model.dart' show Item;
import 'package:motives_new_ui_conversion/record_details_screen.dart';
import '../../Bloc/global_bloc.dart';
import 'Models/order_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:motives_new_ui_conversion/record_details_screen.dart';
import '../../Bloc/global_bloc.dart';
import 'Models/order_storage.dart';

// Reuse the same look & feel as your catalog file
const kOrange = Color(0xFFEA7A3B);
const kText   = Color(0xFF1E1E1E);
const kMuted  = Color(0xFF707883);
const kField  = Color(0xFFF2F3F5);
const kCard   = Colors.white;
const kShadow = Color(0x14000000);

  class _ProductLine {
    final String name;
    final int sku;
    final int ctn;
    _ProductLine(this.name, this.sku, this.ctn);
  }


class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _storage = OrdersStorage();
  List<OrderRecord> _records = [];
  String? _userId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
            context.read<GlobalBloc>().add(Activity(activity:  'Order Details'));

    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final login = context.read<GlobalBloc>().state.loginModel;
    _userId = login?.userinfo?.userId;

    if (_userId == null || _userId!.isEmpty) {
      setState(() { _loading = false; _records = []; });
      return;
    }

    final list = await _storage.listOrders(_userId!);
    setState(() { _records = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: kText),
        title: Text(
          'Orders',
          style: t.titleLarge?.copyWith(color: kText, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_userId == null
              ? Center(child: Text('No user logged in', style: t.bodyMedium))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _records.isEmpty
                      ? ListView(
                          children: [
        SizedBox(height: MediaQuery.of(context).size.height *0.30),                          
          Icon(Icons.local_grocery_store_outlined, size: 56, color: Color(0xFFEA7A3B)),
                     SizedBox(height: 4),
                            Center(
                              child: Text('No orders found yet!',
                                  style: t.titleMedium?.copyWith(color: Colors.black45,fontWeight: FontWeight.w400,fontStyle: FontStyle.italic)),
                            ),
                            // const SizedBox(height: 4),
                            // Center(
                            //   child: Text('Submit an order to see it here.',
                            //       style: t.bodySmall?.copyWith(color: kMuted)),
                            // ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _records.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final r = _records[i];
                            final totals  = OrderTotals.fromPayload(r.payload);
                            final created = DateFormat('dd MMM yyyy, hh:mm a').format(r.createdAt);

                            // --- NEW: derive shop + products with per-line quantities
                            final shopName    = _shopName(r);
                            final shopAddress = _shopAddress(r);
                            final lines       = _extractProductLines(r); // <— all products with sku/ctn

                            return InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecordDetailScreen(record: r),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: kCard,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: const [
                                    BoxShadow(color: kShadow, blurRadius: 10, offset: Offset(0, 6)),
                                  ],
                                  border: Border.all(color: const Color(0xFFEDEFF2)),
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: kField,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.receipt_long_rounded, color: kOrange),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Order ${r.status}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: t.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: kText,
                                            ),
                                          ),
                                          const SizedBox(height: 6),

                                          if (shopName.isNotEmpty)
                                            Text(
                                              shopName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: t.bodyMedium?.copyWith(
                                                color: kText,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          if (shopAddress.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text(
                                                shopAddress,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: t.bodySmall?.copyWith(color: kMuted),
                                              ),
                                            ),

                                          // --- NEW: render ALL product lines with quantities
                                          if (lines.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text('Products (${lines.length})',
                                                style: t.bodySmall?.copyWith(
                                                  color: kMuted,
                                                  fontWeight: FontWeight.w700,
                                                )),
                                            const SizedBox(height: 4),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                for (final pl in lines)
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                                    child: Text(
                                                      '• ${pl.name}  —  SKU ${pl.sku}   CTN ${pl.ctn}',
                                                      style: t.bodySmall?.copyWith(color: kText),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],

                                          const SizedBox(height: 8),
                                          Text(
                                            'Total Qty: ${_trimQty(totals.totalQty)}',
                                            style: t.bodySmall?.copyWith(color: kMuted),
                                          ),
                                          Text(
                                            'Submitted: $created',
                                            style: t.bodySmall?.copyWith(color: kMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right_rounded, color: kMuted),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                )),
    );
  }

  // ------- helpers to read display fields from OrderRecord/payload -------

  String _shopName(OrderRecord r) {
    final v = (r.shopName ?? '').trim();
    if (v.isNotEmpty) return v;
    final p = r.payload;
    return (p['_client_shop_name'] ?? p['party_name'] ?? '').toString().trim();
  }

  String _shopAddress(OrderRecord r) {
    final v = (r.shopAddress ?? '').trim();
    if (v.isNotEmpty) return v;
    final p = r.payload;
    return (p['_client_shop_address'] ?? p['cust_address'] ?? '').toString().trim();
  }

  /// NEW: Model for one product line with quantities

  /// NEW: Extract ALL products from payload['order'] with SKU/CTN
  List<_ProductLine> _extractProductLines(OrderRecord r) {
    final out = <_ProductLine>[];

    final List list = (r.payload['order'] as List?) ?? const [];
    for (final o in list) {
      if (o is! Map) continue;

      final sku = int.tryParse((o['item_qty_sku'] ?? '0').toString()) ?? 0;
      final ctn = int.tryParse((o['item_qty_ctn'] ?? '0').toString()) ?? 0;
      if (sku == 0 && ctn == 0) continue; // skip zero-qty lines

      String name = (o['_client_item_name'] ?? '').toString().trim();
      if (name.isEmpty) {
        final id = (o['item_id'] ?? '').toString();
        final login = context.read<GlobalBloc>().state.loginModel;
        final item = _findItemById(login?.items ?? const [], id);
        name = ((item?.itemName ?? item?.name) ?? '').toString().trim();
        if (name.isEmpty) name = 'Unknown';
      }

      out.add(_ProductLine(name, sku, ctn));
    }

    // If nothing parsed (older saved records), fallback to r.itemNames without qty (0/0)
    if (out.isEmpty && r.itemNames.isNotEmpty) {
      for (final n in r.itemNames) {
        final name = n.trim();
        if (name.isNotEmpty) out.add(_ProductLine(name, 0, 0));
      }
    }

    return out;
  }

  // Lookup helper without external packages
  Item? _findItemById(List<Item> items, String id) {
    for (final it in items) {
      if ((it.id ?? '').toString() == id) return it;
    }
    return null;
  }

  String _trimQty(double q) {
    final s = q.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}

/// Small helper to compute lines and total qty from the legacy payload
class OrderTotals {
  final int lines;
  final double totalQty;

  const OrderTotals({required this.lines, required this.totalQty});

  static OrderTotals fromPayload(Map<String, dynamic> payload) {
    try {
      final List list = (payload['order'] as List?) ?? const [];
      double sum = 0;
      for (final o in list) {
        if (o is Map) {
          final v = o['item_total_qty'];
          if (v != null) {
            sum += double.tryParse(v.toString()) ?? 0;
          }
        }
      }
      return OrderTotals(lines: list.length, totalQty: sum);
    } catch (_) {
      return const OrderTotals(lines: 0, totalQty: 0);
    }
  }
}

/*

// Reuse the same look & feel as your catalog file
const kOrange = Color(0xFFEA7A3B);
const kText   = Color(0xFF1E1E1E);
const kMuted  = Color(0xFF707883);
const kField  = Color(0xFFF2F3F5);
const kCard   = Colors.white;
const kShadow = Color(0x14000000);





class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _storage = OrdersStorage();
  List<OrderRecord> _records = [];
  String? _userId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final login = context.read<GlobalBloc>().state.loginModel;
    _userId = login?.userinfo?.userId;

    if (_userId == null || _userId!.isEmpty) {
      setState(() { _loading = false; _records = []; });
      return;
    }

    final list = await _storage.listOrders(_userId!);
    setState(() { _records = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: kText),
        title: Text(
          'Orders',
          style: t.titleLarge?.copyWith(color: kText, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_userId == null
              ? Center(child: Text('No user logged in', style: t.bodyMedium))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _records.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Icon(Icons.history_toggle_off, size: 56, color: kMuted),
                            const SizedBox(height: 8),
                            Center(
                              child: Text('No successful orders yet',
                                  style: t.titleMedium?.copyWith(color: kText)),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text('Submit an order to see it here.',
                                  style: t.bodySmall?.copyWith(color: kMuted)),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _records.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final r = _records[i];
                            final totals  = OrderTotals.fromPayload(r.payload);
                            final created = DateFormat('dd MMM yyyy, hh:mm a').format(r.createdAt);

                            // Derive display fields
                            final shopName    = _shopName(r);
                            final shopAddress = _shopAddress(r);
                            final names       = _extractProductNames(r); // <- FIX
                            final preview     = _previewNames(names, maxItems: 5);

                            return InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecordDetailScreen(record: r),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: kCard,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: const [
                                    BoxShadow(color: kShadow, blurRadius: 10, offset: Offset(0, 6)),
                                  ],
                                  border: Border.all(color: const Color(0xFFEDEFF2)),
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 86,
                                      decoration: BoxDecoration(
                                        color: kField,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.receipt_long_rounded, color: kOrange),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Order ${r.status}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: t.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: kText,
                                            ),
                                          ),
                                          const SizedBox(height: 6),

                                          if (shopName.isNotEmpty)
                                            Text(
                                              shopName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: t.bodyMedium?.copyWith(
                                                color: kText,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          if (shopAddress.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text(
                                                shopAddress,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: t.bodySmall?.copyWith(color: kMuted),
                                              ),
                                            ),

                                          if (names.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 6),
                                              child: Text(
                                                'Products (${names.length}): $preview',
                                                maxLines: 3,
                                             //   overflow: TextOverflow.ellipsis,
                                                style: t.bodySmall?.copyWith(color: kText),
                                              ),
                                            ),

                                          const SizedBox(height: 6),
                                          Text(
                                            'Total Qty: ${_trimQty(totals.totalQty)}',
                                            style: t.bodySmall?.copyWith(color: kMuted),
                                          ),
                                          Text(
                                            'Submitted: $created',
                                            style: t.bodySmall?.copyWith(color: kMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right_rounded, color: kMuted),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                )),
    );
  }

  // ------- helpers to read display fields from OrderRecord/payload -------

  String _shopName(OrderRecord r) {
    final v = (r.shopName ?? '').trim();
    if (v.isNotEmpty) return v;
    final p = r.payload;
    return (p['_client_shop_name'] ?? p['party_name'] ?? '').toString().trim();
  }

  String _shopAddress(OrderRecord r) {
    final v = (r.shopAddress ?? '').trim();
    if (v.isNotEmpty) return v;
    final p = r.payload;
    return (p['_client_shop_address'] ?? p['cust_address'] ?? '').toString().trim();
  }

  /// Extract product names from payload['order'] (preferred), fallback to r.itemNames.
  /// We also skip zero-qty lines and dedupe names while preserving order.
  List<String> _extractProductNames(OrderRecord r) {
    final out = <String>[];

    // 1) From payload lines
    final List list = (r.payload['order'] as List?) ?? const [];
    for (final o in list) {
      if (o is! Map) continue;

      // Skip empty lines
      final sku = int.tryParse((o['item_qty_sku'] ?? '0').toString()) ?? 0;
      final ctn = int.tryParse((o['item_qty_ctn'] ?? '0').toString()) ?? 0;
      if ((sku + ctn) <= 0) continue;

      // Prefer client-echoed name
      String name = (o['_client_item_name'] ?? '').toString().trim();

      // Fallback: resolve by item_id from login items if needed
      if (name.isEmpty) {
        final id = (o['item_id'] ?? '').toString();
        final login = context.read<GlobalBloc>().state.loginModel;
        final item = _findItemById(login?.items ?? const [], id);
        name = ((item?.itemName ?? item?.name) ?? '').toString().trim();
      }

      if (name.isNotEmpty) out.add(name);
    }

    // 2) Fallback to saved list (older records)
    if (out.isEmpty && r.itemNames.isNotEmpty) {
      out.addAll(r.itemNames.where((e) => e.trim().isNotEmpty));
    }

    // Dedupe, keep order
    final seen = <String>{};
    return out.where((e) => seen.add(e)).toList();
  }

  // Lookup helper without external packages
  Item? _findItemById(List<Item> items, String id) {
    for (final it in items) {
      if ((it.id ?? '').toString() == id) return it;
    }
    return null;
  }

  String _previewNames(List<String> names, {int maxItems = 5}) {
    if (names.isEmpty) return '';
    final take = names.take(maxItems).toList();
    final more = names.length - take.length;
    final head = take.join(', ');
    return more > 0 ? '$head, +$more more' : head;
  }

  String _trimQty(double q) {
    final s = q.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}

/// Small helper to compute lines and total qty from the legacy payload
class OrderTotals {
  final int lines;
  final double totalQty;

  const OrderTotals({required this.lines, required this.totalQty});

  static OrderTotals fromPayload(Map<String, dynamic> payload) {
    try {
      final List list = (payload['order'] as List?) ?? const [];
      double sum = 0;
      for (final o in list) {
        if (o is Map) {
          final v = o['item_total_qty'];
          if (v != null) {
            sum += double.tryParse(v.toString()) ?? 0;
          }
        }
      }
      return OrderTotals(lines: list.length, totalQty: sum);
    } catch (_) {
      return const OrderTotals(lines: 0, totalQty: 0);
    }
  }
}


*/


// class RecordsScreen extends StatefulWidget {
//   const RecordsScreen({super.key});

//   @override
//   State<RecordsScreen> createState() => _RecordsScreenState();
// }

// class _RecordsScreenState extends State<RecordsScreen> {
//   final _storage = OrdersStorage();
//   List<OrderRecord> _records = [];
//   String? _userId;
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) => _load());
//   }

//   Future<void> _load() async {
//     final login = context.read<GlobalBloc>().state.loginModel;
//     _userId = login?.userinfo?.userId;

//     if (_userId == null || _userId!.isEmpty) {
//       setState(() { _loading = false; _records = []; });
//       return;
//     }

//     final list = await _storage.listOrders(_userId!);
//     setState(() { _records = list; _loading = false; });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         iconTheme: const IconThemeData(color: kText),
//         title: Text(
//           'Orders',
//           style: t.titleLarge?.copyWith(color: kText, fontWeight: FontWeight.w700),
//         ),
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : (_userId == null
//               ? Center(child: Text('No user logged in', style: t.bodyMedium))
//               : RefreshIndicator(
//                   onRefresh: _load,
//                   child: _records.isEmpty
//                       ? ListView(
//                           children: [
//                             const SizedBox(height: 120),
//                             Icon(Icons.history_toggle_off, size: 56, color: kMuted),
//                             const SizedBox(height: 8),
//                             Center(
//                               child: Text('No successful orders yet',
//                                   style: t.titleMedium?.copyWith(color: kText)),
//                             ),
//                             const SizedBox(height: 4),
//                             Center(
//                               child: Text('Submit an order to see it here.',
//                                   style: t.bodySmall?.copyWith(color: kMuted)),
//                             ),
//                           ],
//                         )
//                       : ListView.separated(
//                           padding: const EdgeInsets.all(16),
//                           itemCount: _records.length,
//                           separatorBuilder: (_, __) => const SizedBox(height: 12),
//                           itemBuilder: (_, i) {
//                             final r = _records[i];
//                             final totals  = OrderTotals.fromPayload(r.payload);
//                             final created = DateFormat('dd MMM yyyy, hh:mm a').format(r.createdAt);

//                             // NEW: derive display fields
//                             final shopName    = _shopName(r);
//                             final shopAddress = _shopAddress(r);
//                             final products    = _productPreview(r, maxItems: 3);

//                             return InkWell(
//                               onTap: () => Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => RecordDetailScreen(record: r),
//                                 ),
//                               ),
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   color: kCard,
//                                   borderRadius: BorderRadius.circular(14),
//                                   boxShadow: const [
//                                     BoxShadow(color: kShadow, blurRadius: 10, offset: Offset(0, 6)),
//                                   ],
//                                   border: Border.all(color: const Color(0xFFEDEFF2)),
//                                 ),
//                                 padding: const EdgeInsets.all(14),
//                                 child: Row(
//                                   children: [
//                                     Container(
//                                       width: 46,
//                                       height: 46,
//                                       decoration: BoxDecoration(
//                                         color: kField,
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                       child: const Icon(Icons.receipt_long_rounded, color: kOrange),
//                                     ),
//                                     const SizedBox(width: 12),
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           // Status
//                                           Text(
//                                             'Order ${r.status}',
//                                             maxLines: 1,
//                                             overflow: TextOverflow.ellipsis,
//                                             style: t.titleMedium?.copyWith(
//                                               fontWeight: FontWeight.w700,
//                                               color: kText,
//                                             ),
//                                           ),

//                                           const SizedBox(height: 3),

//                                           // NEW: Shop Name (party_name)
//                                           if (shopName.isNotEmpty)
//                                             Text(
//                                               shopName,
//                                               maxLines: 1,
//                                               overflow: TextOverflow.ellipsis,
//                                               style: t.bodyMedium?.copyWith(
//                                                 color: kText,
//                                                 fontWeight: FontWeight.w700,
//                                               ),
//                                             ),

//                                           // NEW: Shop Address (cust_address)
//                                           if (shopAddress.isNotEmpty)
//                                             Padding(
//                                               padding: const EdgeInsets.only(top: 2),
//                                               child: Text(
//                                                 shopAddress,
//                                                 maxLines: 1,
//                                                 overflow: TextOverflow.ellipsis,
//                                                 style: t.bodySmall?.copyWith(color: kMuted),
//                                               ),
//                                             ),

//                                           // NEW: Products preview
//                                           if (products.isNotEmpty)
//                                             Padding(
//                                               padding: const EdgeInsets.only(top: 6),
//                                               child: Text(
//                                                 'Products: $products',
//                                                 maxLines: 2,
//                                                // overflow: TextOverflow.ellipsis,
//                                                 style: t.bodySmall?.copyWith(color: kText),
//                                               ),
//                                             ),

//                                           const SizedBox(height: 6),

//                                           // Totals & Submitted time
//                                           Text(
//                                             'Total Qty: ${_trimQty(totals.totalQty)}',
//                                             style: t.bodySmall?.copyWith(color: kMuted),
//                                           ),
//                                           Text(
//                                             'Submitted: $created',
//                                             style: t.bodySmall?.copyWith(color: kMuted),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                     const SizedBox(width: 8),
//                                     const Icon(Icons.chevron_right_rounded, color: kMuted),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                 )),
//     );
//   }

//   // ------- helpers to read display fields from OrderRecord/payload -------

//   /// Prefer new fields (OrderRecord.shopName), fallback to payload['_client_shop_name']
//   String _shopName(OrderRecord r) {
//     final v = (r.shopName ?? '').trim();
//     if (v.isNotEmpty) return v;
//     final p = r.payload;
//     final s = (p['_client_shop_name'] ?? p['party_name'] ?? '').toString().trim();
//     return s;
//   }

//   /// Prefer new fields (OrderRecord.shopAddress), fallback to payload['_client_shop_address']
//   String _shopAddress(OrderRecord r) {
//     final v = (r.shopAddress ?? '').trim();
//     if (v.isNotEmpty) return v;
//     final p = r.payload;
//     final s = (p['_client_shop_address'] ?? p['cust_address'] ?? '').toString().trim();
//     return s;
//   }

//   /// Build a short "name1, name2, +N more" preview.
//   String _productPreview(OrderRecord r, {int maxItems = 3}) {
//     final names = _extractProductNames(r);
//     if (names.isEmpty) return '';
//     final take = names.take(maxItems).toList();
//     final more = names.length - take.length;
//     final head = take.join(', ');
//     return more > 0 ? '$head, +$more more' : head;
//     }

//   /// Extract product names from OrderRecord.itemNames or payload['order'][i]['_client_item_name'].
//   List<String> _extractProductNames(OrderRecord r) {
//     if (r.itemNames.isNotEmpty) {
//       // Already persisted in storage
//       return r.itemNames.where((e) => e.trim().isNotEmpty).toList();
//     }
//     final p = r.payload;
//     final List list = (p['order'] as List?) ?? const [];
//     final out = <String>[];
//     for (final o in list) {
//       if (o is Map) {
//         final n = (o['_client_item_name'] ?? o['name'] ?? '').toString().trim();
//         if (n.isNotEmpty) out.add(n);
//       }
//     }
//     return out;
//   }

//   String _trimQty(double q) {
//     final s = q.toStringAsFixed(1);
//     return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
//   }
// }

// /// Small helper to compute lines and total qty from the legacy payload
// class OrderTotals {
//   final int lines;
//   final double totalQty;

//   const OrderTotals({required this.lines, required this.totalQty});

//   static OrderTotals fromPayload(Map<String, dynamic> payload) {
//     try {
//       final List list = (payload['order'] as List?) ?? const [];
//       double sum = 0;
//       for (final o in list) {
//         if (o is Map) {
//           final v = o['item_total_qty'];
//           if (v != null) {
//             sum += double.tryParse(v.toString()) ?? 0;
//           }
//         }
//       }
//       return OrderTotals(lines: list.length, totalQty: sum);
//     } catch (_) {
//       return const OrderTotals(lines: 0, totalQty: 0);
//     }
//   }
// }

/*
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _storage = OrdersStorage();
  List<OrderRecord> _records = [];
  String? _userId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final login = context.read<GlobalBloc>().state.loginModel;
    _userId = login?.userinfo?.userId;

    if (_userId == null || _userId!.isEmpty) {
      setState(() { _loading = false; _records = []; });
      return;
    }

    final list = await _storage.listOrders(_userId!);
    setState(() { _records = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: kText),
        title: Text('Orders',
          style: t.titleLarge?.copyWith(color: kText, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_userId == null
              ? Center(child: Text('No user logged in', style: t.bodyMedium))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _records.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Icon(Icons.history_toggle_off, size: 56, color: kMuted),
                            const SizedBox(height: 8),
                            Center(
                              child: Text('No successful orders yet',
                                  style: t.titleMedium?.copyWith(color: kText)),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text('Submit an order to see it here.',
                                  style: t.bodySmall?.copyWith(color: kMuted)),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _records.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final r = _records[i];
                            final totals = OrderTotals.fromPayload(r.payload);
                            final created = DateFormat('dd MMM yyyy, hh:mm a').format(r.createdAt);

                            return InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecordDetailScreen(record: r),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: kCard,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: const [
                                    BoxShadow(color: kShadow, blurRadius: 10, offset: Offset(0, 6)),
                                  ],
                                  border: Border.all(color: const Color(0xFFEDEFF2)),
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: kField,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.receipt_long_rounded, color: kOrange),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Order ${r.status}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: t.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: kText,
                                            ),
                                          ),
                                        
                                          const SizedBox(height: 4),
                                          // Text(
                                          //   'Date: ${r.dateStr}'.toUpperCase(),
                                          //   style: t.bodySmall?.copyWith(color: kMuted),
                                          // ),
                                               Text(
                                            'Total Qty: ${_trimQty(totals.totalQty)}',
                                            style: t.bodySmall?.copyWith(color: kMuted),
                                          ),
                                          Text(
                                            'Submitted: $created',
                                            style: t.bodySmall?.copyWith(color: kMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right_rounded, color: kMuted),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                )),
    );
  }

  String _shortId(String id) {
    if (id.isEmpty) return '—';
    return id.length <= 8 ? id : id.substring(0, 8);
  }

  String _trimQty(double q) {
    // show "20" instead of "20.0"
    final s = q.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}

/// Small helper to compute lines and total qty from the legacy payload
class OrderTotals {
  final int lines;
  final double totalQty;

  const OrderTotals({required this.lines, required this.totalQty});

  static OrderTotals fromPayload(Map<String, dynamic> payload) {
    try {
      final List list = (payload['order'] as List?) ?? const [];
      double sum = 0;
      for (final o in list) {
        if (o is Map) {
          final v = o['item_total_qty'];
          if (v != null) {
            // server sends numbers as strings like "20.0"
            sum += double.tryParse(v.toString()) ?? 0;
          }
        }
      }
      return OrderTotals(lines: list.length, totalQty: sum);
    } catch (_) {
      return const OrderTotals(lines: 0, totalQty: 0);
    }
  }
}

*/

// const _kMuted = Color(0xFF707883);
// const _kShadow = Color(0x14000000);

// class RecordsScreen extends StatefulWidget {
//   const RecordsScreen({super.key});

//   @override
//   State<RecordsScreen> createState() => _RecordsScreenState();
// }

// class _RecordsScreenState extends State<RecordsScreen> {
//   final _storage = OrdersStorage();
//   List<OrderRecord> _records = [];
//   String? _userId;
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) => _load());
//   }

//   Future<void> _load() async {
//     final login = context.read<GlobalBloc>().state.loginModel;
//     _userId = login?.userinfo?.userId;
//     if (_userId == null || _userId!.isEmpty) {
//       setState(() { _loading = false; _records = []; });
//       return;
//     }
//     final list = await _storage.listOrders(_userId!);
//     setState(() { _records = list; _loading = false; });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return Scaffold(
//       appBar: AppBar(title: const Text('Order Records')),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : (_userId == null
//               ? Center(child: Text('No user logged in', style: t.bodyMedium))
//               : RefreshIndicator(
//                   onRefresh: _load,
//                   child: _records.isEmpty
//                       ? ListView(children: [
//                           const SizedBox(height: 120),
//                           Icon(Icons.history_toggle_off, size: 56, color: _kMuted),
//                           const SizedBox(height: 8),
//                           Center(child: Text('No successful orders yet', style: t.titleMedium)),
//                         ])
//                       : ListView.separated(
//                           padding: const EdgeInsets.all(16),
//                           itemBuilder: (_, i) {
//                             final r = _records[i];
//                             final totals = OrderTotals.fromPayload(r.payload);
//                             final created = DateFormat('dd MMM yyyy, hh:mm a').format(r.createdAt);
//                             return InkWell(
//                               onTap: () => Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (_) => RecordDetailScreen(record: r)),
//                               ),
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(14),
//                                   boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 10, offset: Offset(0,6))],
//                                   border: Border.all(color: const Color(0xFFEDEFF2)),
//                                 ),
//                                 padding: const EdgeInsets.all(14),
//                                 child: Row(
//                                   children: [
//                                     Container(
//                                       width: 46, height: 46,
//                                       decoration: BoxDecoration(
//                                         color: const Color(0xFFF2F3F5),
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                       child: const Icon(Icons.receipt_long_rounded),
//                                     ),
//                                     const SizedBox(width: 12),
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           Text('Order ${r.id.substring(0, 8)} • ${r.status}',
//                                               style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
//                                           const SizedBox(height: 4),
//                                           Text('Date: ${r.dateStr} • Lines: ${totals.lines} • Total Qty: ${totals.totalQty}',
//                                               style: t.bodySmall?.copyWith(color: _kMuted)),
//                                           Text('Submitted: $created', style: t.bodySmall?.copyWith(color: _kMuted)),
//                                         ],
//                                       ),
//                                     ),
//                                     const SizedBox(width: 8),
//                                     const Icon(Icons.chevron_right_rounded),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                           separatorBuilder: (_, __) => const SizedBox(height: 12),
//                           itemCount: _records.length,
//                         ),
//                 )),
//     );
//   }
// }
