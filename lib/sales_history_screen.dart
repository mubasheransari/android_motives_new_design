import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';

class SalesHistoryScreen extends StatefulWidget {
  final String acode;
  final String disid;
  const SalesHistoryScreen({
    super.key,
    required this.acode,
    required this.disid,
  });

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    // fire once using only widget params; don’t re-hit if already loaded & non-empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<GlobalBloc>().state;
      final alreadyLoaded =
          s.salesHistoryStatus == SalesHistoryStatus.success &&
          s.salesHistory.isNotEmpty;

      if (!alreadyLoaded &&
          widget.acode.trim().isNotEmpty &&
          widget.disid.trim().isNotEmpty) {
        context.read<GlobalBloc>().add(
              LoadSalesHistoryRequested(
                acode: widget.acode.trim(),
                disid: widget.disid.trim(),
              ),
            );
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  double _num(String? s) => double.tryParse((s ?? '').replaceAll(',', '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final acodeParam = widget.acode.trim();
    final disidParam = widget.disid.trim();

    return Scaffold(
      appBar: AppBar(
        title: BlocSelector<GlobalBloc, GlobalState, int>(
          selector: (s) => s.salesHistory.length,
          builder: (_, count) => Text('Sales History ($count)'),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search by Order #, Item, or A/C code',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // List / States
          Expanded(
            child: BlocBuilder<GlobalBloc, GlobalState>(
              buildWhen: (p, c) =>
                  p.salesHistoryStatus != c.salesHistoryStatus ||
                  p.salesHistory != c.salesHistory ||
                  p.salesHistoryError != c.salesHistoryError,
              builder: (context, state) {
                // loading
                if (state.salesHistoryStatus == SalesHistoryStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // failure
                if (state.salesHistoryStatus == SalesHistoryStatus.failure) {
                  return _SHErrorView(
                    message:
                        state.salesHistoryError ?? 'Failed to load sales history',
                    onRetry: () {
                      if (acodeParam.isNotEmpty && disidParam.isNotEmpty) {
                        context.read<GlobalBloc>().add(
                              LoadSalesHistoryRequested(
                                acode: acodeParam,
                                disid: disidParam,
                              ),
                            );
                      }
                    },
                  );
                }

                final q = _search.text.trim().toLowerCase();
                final all = state.salesHistory;

                final data = q.isEmpty
                    ? all
                    : all.where((m) {
                        final ord = (m.ordNo ?? '').toLowerCase();
                        final ac = (m.acode ?? '').toLowerCase();
                        final desc = (m.itemDesc ?? '').toLowerCase();
                        return ord.contains(q) || ac.contains(q) || desc.contains(q);
                      }).toList();

                if (state.salesHistoryStatus == SalesHistoryStatus.initial) {
                  return const _SHEmptyView(text: 'No sales yet.');
                }
                if (state.salesHistoryStatus == SalesHistoryStatus.success &&
                    data.isEmpty) {
                  return const _SHEmptyView(text: 'No results match your search.');
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    if (acodeParam.isNotEmpty && disidParam.isNotEmpty) {
                      context.read<GlobalBloc>().add(
                            LoadSalesHistoryRequested(
                              acode: acodeParam,
                              disid: disidParam,
                            ),
                          );
                    }
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final m = data[i];

                      final qty = _num(m.qty);
                      final pcs = _num(m.pcsQty);
                      final ctn = _num(m.totCtnQty);

                      return Card(
                        elevation: 0.5,
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text((m.segmentId ?? '').isEmpty
                                ? 'OR'
                                : (m.segmentId!.length >= 2
                                    ? m.segmentId!.substring(m.segmentId!.length - 2)
                                    : m.segmentId!)),
                          ),
                          title: Text(m.ordNo ?? '-'), // Order #
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((m.itemDesc ?? '').isNotEmpty)
                                Text(
                                  m.itemDesc!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: -6,
                                children: [
                                  _chip('A/C ${m.acode ?? '-'}'),
                                  if ((m.partyName ?? '').isNotEmpty)
                                    _chip(m.partyName!),
                                  if ((m.itemid ?? '').isNotEmpty) _chip('#${m.itemid}'),
                                ],
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Qty: ${qty.toStringAsFixed(0)}'),
                              Text('Pcs: ${pcs.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 12)),
                              Text('Ctn: ${ctn.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          onTap: () {
                            // you can push a detail screen here if needed
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          s,
          style: const TextStyle(fontSize: 12, color: Color(0xFF1E1E1E)),
        ),
      );
}

class _SHErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _SHErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SHEmptyView extends StatelessWidget {
  final String text;
  const _SHEmptyView({this.text = 'No records to show'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text),
      ),
    );
  }
}
