import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';

import 'dart:ui';


class _InvTheme {
  static const cBg = Color(0xFFEEEEEE);
  static const cSurface = Colors.white;
  static const cText = Color(0xFF1F2937);
  static const cMuted = Color(0xFF6B7280);
  static const cStroke = Color(0xFFE9E9EF);
  static const cPrimary = Color(0xFFEA7A3B);
  static const cPrimarySoft = Color(0xFFFFB07A);
  static const cShadow = Color(0x14000000);
}

class InvoicesScreen extends StatefulWidget {
  final String acode; // use only widget params
  final String disid;

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

    // Fire once after first frame using ONLY widget params
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<GlobalBloc>();
      final s = bloc.state;

      // If we don't already have invoices (or they don't match this acode), fetch.
      final alreadyLoadedForThisAcode = s.invoices.isNotEmpty &&
          (s.invoices.first.acode ?? '').trim().toLowerCase() ==
              widget.acode.trim().toLowerCase();

      final needsFetch = s.invoicesStatus != InvoicesStatus.success ||
          s.invoices.isEmpty ||
          !alreadyLoadedForThisAcode;

      if (needsFetch && widget.acode.isNotEmpty && widget.disid.isNotEmpty) {
        bloc.add(LoadShopInvoicesRequested(acode: widget.acode, disid: widget.disid));
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ---- helpers ----
  String _fmtDate(String? s) {
    if (s == null || s.isEmpty) return '';
    try {
      final d = DateFormat('dd-MMM-yy').parse(s.toUpperCase());
      return DateFormat('dd MMM yyyy').format(d);
    } catch (_) {
      return s;
    }
  }

  double _num(String? s) => double.tryParse((s ?? '').replaceAll(',', '')) ?? 0.0;

  double _sum(Iterable<String?> values) =>
      values.fold<double>(0.0, (p, v) => p + _num(v));

  @override
  Widget build(BuildContext context) {
    final acodeParam = widget.acode.trim();
    final disidParam = widget.disid.trim();

    return Scaffold(
      backgroundColor: _InvTheme.cBg,
      appBar: AppBar(
        backgroundColor: _InvTheme.cBg,
        elevation: 0,
        title: BlocSelector<GlobalBloc, GlobalState, int>(
          selector: (s) => s.invoices.length,
          builder: (_, count) => Text('Invoices ($count)',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<GlobalBloc, GlobalState>(
          buildWhen: (p, c) =>
              p.invoicesStatus != c.invoicesStatus ||
              p.invoices != c.invoices ||
              p.invoicesError != c.invoicesError,
          builder: (context, state) {
            // Top summary values (derive from currently loaded set)
            final invoices = state.invoices;
            final totalAmount = _sum(invoices.map((e) => e.invAmount));
            final totalBalance = _sum(invoices.map((e) => e.balAmount));

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ---- Hero Glass Header ----
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _InvEnter(
                      delayMs: 0,
                      child: _InvHeroGlass(
                        left: _InvBadge(icon: Icons.receipt_long_rounded),
                        titleBottom: 'A/C ${acodeParam} • DIS ${disidParam}',
                        right: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              colors: [_InvTheme.cPrimarySoft, _InvTheme.cPrimary],
                              begin: Alignment(-0.9, -1),
                              end: Alignment(0.9, 1),
                            ),
                            border: Border.all(color: Colors.white.withOpacity(.22)),
                          ),
                          child: const Text(
                            'Invoices',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ---- Stat Pills ----
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      children: [
                        _InvEnter(
                          delayMs: 50,
                          child: _InvMiniStatCard(
                            title: 'Count',
                            value: '${invoices.length}',
                            icon: Icons.numbers,
                          ),
                        ),
                        _InvEnter(
                          delayMs: 90,
                          child: _InvMiniStatCard(
                            title: 'Total Amount',
                            value: NumberFormat('#,##0.00').format(totalAmount),
                            icon: Icons.payments_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const SizedBox(width: 12),
                        _InvEnter(
                          delayMs: 130,
                          child: _InvMiniStatCard(
                            title: 'Balance',
                            value: NumberFormat('#,##0.00').format(totalBalance),
                            icon: Icons.account_balance_wallet_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.invoicesStatus == InvoicesStatus.loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.invoicesStatus == InvoicesStatus.failure)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _InvErrorView(
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
                    ),
                  )
                else
                  _buildInvoicesListSliver(context, state, acodeParam, disidParam),
              ],
            );
          },
        ),
      ),
    );
  }

  SliverList _buildInvoicesListSliver(
    BuildContext context,
    GlobalState state,
    String acodeParam,
    String disidParam,
  ) {
    // Local filter
    final q = _search.text.trim().toLowerCase();
    final src = state.invoices;
    final data = q.isEmpty
        ? src
        : src.where((m) {
            final inv = (m.invno ?? '').toLowerCase();
            final ac = (m.acode ?? '').toLowerCase();
            final id = (m.invid ?? '').toLowerCase();
            return inv.contains(q) || ac.contains(q) || id.contains(q);
          }).toList();

    if (state.invoicesStatus == InvoicesStatus.initial) {
      return SliverList.list(children: const [_InvEmptyView(text: 'No invoices yet.')]);
    }
    if (state.invoicesStatus == InvoicesStatus.success && data.isEmpty) {
      return SliverList.list(
          children: const [_InvEmptyView(text: 'No invoices found.')]);
    }

    return SliverList.separated(
      itemCount: data.length + 1, // +1 for bottom spacer area
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        if (i == data.length) {
          // bottom padded refresh affordance
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            child: _InvEnter(
              delayMs: 60,
              child: _InvPressable(
                onTap: () {
                  if (acodeParam.isNotEmpty && disidParam.isNotEmpty) {
                    context.read<GlobalBloc>().add(
                      LoadShopInvoicesRequested(acode: acodeParam, disid: disidParam),
                    );
                  }
                },
                child: _InvGlass(
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    child: const Text(
                      'Refresh',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _InvTheme.cText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final m = data[i];
  

        return Padding(
          padding: EdgeInsets.fromLTRB(16, i == 0 ? 8 : 0, 16, 0),
          child: _InvEnter(
            delayMs: 60 + (i % 6) * 40,
            child: _InvGlass(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: _InvAvatarLabel(text: (m.cashCredit ?? '').toUpperCase()),
                title: Text(
                  'Invoice #${m.invno ?? '-'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _InvTheme.cText,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    [
                      if ((m.invDate ?? '').isNotEmpty) _fmtDate(m.invDate),
                      if ((m.acode ?? '').isNotEmpty) 'A/C ${m.acode}',
                      if ((m.invid ?? '').isNotEmpty) 'ID ${m.invid}',
                    ].join('\n'),
                    style: const TextStyle(color: _InvTheme.cMuted),
                  ),
                ),

              ),
            ),
          ),
        );
      },
    );
  }
}


class _InvGlass extends StatelessWidget {
  const _InvGlass({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _InvTheme.cStroke),
            boxShadow: const [
              BoxShadow(color: _InvTheme.cShadow, blurRadius: 16, offset: Offset(0, 10)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InvHeroGlass extends StatelessWidget {
  const _InvHeroGlass({required this.left, required this.titleBottom, required this.right});
  final Widget left;
  final String titleBottom;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _InvTheme.cStroke),
            boxShadow: const [
              BoxShadow(color: _InvTheme.cShadow, blurRadius: 22, offset: Offset(0, 12)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              left,
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    titleBottom,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleLarge?.copyWith(
                      color: _InvTheme.cText,
                      fontWeight: FontWeight.w900,
                      height: 1.06,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              right,
            ],
          ),
        ),
      ),
    );
  }
}

class _InvBadge extends StatelessWidget {
  const _InvBadge({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _InvTheme.cStroke, width: 1),
        boxShadow: const [BoxShadow(color: _InvTheme.cShadow, blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Icon(icon, color: _InvTheme.cPrimary, size: 26),
    );
  }
}

class _InvMiniStatCard extends StatelessWidget {
  const _InvMiniStatCard({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _InvGlass(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _InvTheme.cPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.bodySmall?.copyWith(color: _InvTheme.cMuted)),
                  const SizedBox(height: 2),
                  Text(value, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: _InvTheme.cText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvAvatarLabel extends StatelessWidget {
  const _InvAvatarLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: const Color(0xFFF5F5F7),
      child: Text(
        text.isEmpty ? '-' : text,
        style: const TextStyle(fontWeight: FontWeight.w800, color: _InvTheme.cPrimary),
      ),
    );
  }
}

class _InvErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _InvErrorView({required this.message, required this.onRetry});

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
              style: ElevatedButton.styleFrom(
                backgroundColor: _InvTheme.cPrimary,
                foregroundColor: Colors.white,
              ),
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

class _InvEmptyView extends StatelessWidget {
  final String text;
  const _InvEmptyView({this.text = 'No invoices to show'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(24), child: Text(text)),
    );
  }
}

class _InvPressable extends StatefulWidget {
  const _InvPressable({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_InvPressable> createState() => _InvPressableState();
}

class _InvPressableState extends State<_InvPressable> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  void _down(TapDownDetails _) => setState(() => _scale = .98);
  void _up([_]) => setState(() => _scale = 1);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _up,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

class _InvEnter extends StatefulWidget {
  const _InvEnter({required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  State<_InvEnter> createState() => _InvEnterState();
}

class _InvEnterState extends State<_InvEnter> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _opacity = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
  late final Animation<Offset> _offset = Tween(begin: const Offset(0, .1), end: Offset.zero)
      .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), _ac.forward);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: SlideTransition(position: _offset, child: widget.child));
}

