import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:motives_new_ui_conversion/Models/order_payload.dart';
import 'package:motives_new_ui_conversion/record_details_screen.dart';
import '../../Bloc/global_bloc.dart';
import 'Models/order_storage.dart';


const _kMuted = Color(0xFF707883);
const _kShadow = Color(0x14000000);

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
      appBar: AppBar(title: const Text('Order Records')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_userId == null
              ? Center(child: Text('No user logged in', style: t.bodyMedium))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _records.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 120),
                          Icon(Icons.history_toggle_off, size: 56, color: _kMuted),
                          const SizedBox(height: 8),
                          Center(child: Text('No successful orders yet', style: t.titleMedium)),
                        ])
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (_, i) {
                            final r = _records[i];
                            final totals = OrderTotals.fromPayload(r.payload);
                            final created = DateFormat('dd MMM yyyy, hh:mm a').format(r.createdAt);
                            return InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => RecordDetailScreen(record: r)),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 10, offset: Offset(0,6))],
                                  border: Border.all(color: const Color(0xFFEDEFF2)),
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46, height: 46,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF2F3F5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.receipt_long_rounded),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Order ${r.id.substring(0, 8)} • ${r.status}',
                                              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 4),
                                          Text('Date: ${r.dateStr} • Lines: ${totals.lines} • Total Qty: ${totals.totalQty}',
                                              style: t.bodySmall?.copyWith(color: _kMuted)),
                                          Text('Submitted: $created', style: t.bodySmall?.copyWith(color: _kMuted)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right_rounded),
                                  ],
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemCount: _records.length,
                        ),
                )),
    );
  }
}
