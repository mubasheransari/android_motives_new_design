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
