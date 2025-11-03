// invoices_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';


class InvoicesScreen extends StatefulWidget {
  final String? acode; 
  final String? disid;

  const InvoicesScreen({
    super.key,
    required this.acode,
    required this.disid,
  });

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    print("ACODE ${widget.acode}");
    print("DISID ${widget.disid}");

    // Fire once after first frame using ONLY widget params
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<GlobalBloc>();
      final s = bloc.state;

      final acode = (widget.acode ?? '').trim();
      final disid = (widget.disid ?? '').trim();

      final alreadyLoaded =
          s.invoicesStatus == InvoicesStatus.success && s.invoices.isNotEmpty;

      debugPrint('[InvoicesScreen:init] acode=$acode disid=$disid loaded=$alreadyLoaded');

      if (!alreadyLoaded && acode.isNotEmpty && disid.isNotEmpty) {
        bloc.add(LoadShopInvoicesRequested(acode: acode, disid: disid));
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // helpers
  double _num(String? s) => double.tryParse((s ?? '').replaceAll(',', '')) ?? 0.0;

  String _fmtDate(String? s) {
    if (s == null || s.isEmpty) return '';
    try {
      final d = DateFormat('dd-MMM-yy').parse(s.toUpperCase());
      return DateFormat('dd MMM yyyy').format(d);
    } catch (_) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    // lock-in the params for this build
    final acodeParam = (widget.acode ?? '').trim();
    final disidParam = (widget.disid ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: BlocSelector<GlobalBloc, GlobalState, int>(
          selector: (s) => s.invoices.length,
          builder: (_, count) => Text('Invoices ($count)'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search by Invoice # or A/C code',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: BlocBuilder<GlobalBloc, GlobalState>(
              buildWhen: (p, c) =>
                  p.invoicesStatus != c.invoicesStatus ||
                  p.invoices != c.invoices ||
                  p.invoicesError != c.invoicesError,
              builder: (context, state) {
                // Loading
                if (state.invoicesStatus == InvoicesStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Failure
                if (state.invoicesStatus == InvoicesStatus.failure) {
                  return _ErrorView(
                    message: state.invoicesError ?? 'Failed to load invoices',
                    onRetry: () {
                      if (acodeParam.isNotEmpty && disidParam.isNotEmpty) {
                        context.read<GlobalBloc>().add(
                              LoadShopInvoicesRequested(
                                acode: acodeParam,
                                disid: disidParam,
                              ),
                            );
                      }
                    },
                  );
                }

                // Filter the list locally
                final q = _search.text.trim().toLowerCase();
                final all = state.invoices;
                final data = q.isEmpty
                    ? all
                    : all.where((m) {
                        final inv = (m.invno ?? m.invid ?? '').toLowerCase();
                        final ac = (m.acode ?? '').toLowerCase();
                        return inv.contains(q) || ac.contains(q);
                      }).toList();

                if (state.invoicesStatus == InvoicesStatus.initial) {
                  return const _EmptyView(text: 'No invoices yet.');
                }
                if (state.invoicesStatus == InvoicesStatus.success && data.isEmpty) {
                  return const _EmptyView(text: 'No invoices match your search.');
                }

                // List
                return RefreshIndicator(
                  onRefresh: () async {
                    if (acodeParam.isNotEmpty && disidParam.isNotEmpty) {
                      context.read<GlobalBloc>().add(
                            LoadShopInvoicesRequested(
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

                      final invAmt = _num(m.invAmount);
                      final ledAmt = _num(m.ledAmount);
                      final balAmt = _num(m.balAmount);

                      return Card(
                        elevation: 0.5,
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text((m.cashCredit ?? 'CR').toUpperCase().trim()),
                          ),
                          title: Text('Invoice #${m.invno ?? m.invid ?? '-'}'),
                          subtitle: Text(
                            [
                              if ((m.invDate ?? '').isNotEmpty) _fmtDate(m.invDate),
                              if ((m.acode ?? '').isNotEmpty) 'A/C ${m.acode}',
                            ].where((x) => x.isNotEmpty).join('   •   '),
                          ),
                          trailing: (m.invAmount == null &&
                                  m.ledAmount == null &&
                                  m.balAmount == null)
                              ? const SizedBox.shrink()
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (m.invAmount != null)
                                      Text('Amount: ${invAmt.toStringAsFixed(2)}'),
                                    if (m.ledAmount != null)
                                      Text('Ledger: ${ledAmt.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 12)),
                                    if (m.balAmount != null)
                                      Text('Balance: ${balAmt.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                          onTap: () {},
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
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

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

class _EmptyView extends StatelessWidget {
  final String text;
  const _EmptyView({this.text = 'No invoices to show'});

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
