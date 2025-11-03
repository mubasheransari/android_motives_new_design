import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';


import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:motives_new_ui_conversion/Models/get_sales_history_model.dart';

// import your bloc/state/events
// import 'global_bloc.dart';
// import 'global_state.dart';
// import 'global_event.dart';

class SalesHistoryScreen extends StatefulWidget {
  final String acode; // ONLY widget params
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final b = context.read<GlobalBloc>();
      final s = b.state;

      final loadedForThisAcode = s.salesHistory.isNotEmpty &&
          (s.salesHistory.first.acode ?? '').trim().toLowerCase() ==
              widget.acode.trim().toLowerCase();

      final needsFetch = s.salesHistoryStatus != SalesHistoryStatus.success ||
          s.salesHistory.isEmpty ||
          !loadedForThisAcode;

      if (needsFetch && widget.acode.isNotEmpty && widget.disid.isNotEmpty) {
        b.add(LoadSalesHistoryRequested(acode: widget.acode, disid: widget.disid));
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  double _num(String? s) => double.tryParse((s ?? '').replaceAll(',', '')) ?? 0.0;
  double _sum(Iterable<String?> values) =>
      values.fold<double>(0.0, (p, v) => p + _num(v));

  String _segTail(String? seg) {
    final s = (seg ?? '').trim();
    if (s.isEmpty) return 'OR';
    return s.length <= 2 ? s : s.substring(s.length - 2);
  }

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
          selector: (s) => s.salesHistory.length,
          builder: (_, count) => Text(
            'Sales History ($count)',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<GlobalBloc, GlobalState>(
          buildWhen: (p, c) =>
              p.salesHistoryStatus != c.salesHistoryStatus ||
              p.salesHistory != c.salesHistory ||
              p.salesHistoryError != c.salesHistoryError,
          builder: (context, state) {
            final rows = state.salesHistory;

            // Stats
            final totalQty = _sum(rows.map((e) => e.qty));
            final totalPcs = _sum(rows.map((e) => e.pcsQty));
            final totalCtn = _sum(rows.map((e) => e.totCtnQty));
            final distinctOrders = rows.map((e) => (e.ordNo ?? '').trim()).toSet().length;
     

            // Filter
            final q = _search.text.trim().toLowerCase();
            final data = q.isEmpty
                ? rows
                : rows.where((m) {
                    final ord = (m.ordNo ?? '').toLowerCase();
                    final ac = (m.acode ?? '').toLowerCase();
                    final desc = (m.itemDesc ?? '').toLowerCase();
                    final item = (m.itemid ?? '').toLowerCase();
                              final shopenamee =(m.partyName ?? '').toLowerCase();
                    return ord.contains(q) || ac.contains(q) || desc.contains(q) || item.contains(q);
                  }).toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ---- Hero ----
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _InvEnter(
                      delayMs: 0,
                      child: _InvHeroGlass(
                        left: const _InvBadge(icon: Icons.shopping_bag_rounded),
                        titleBottom: 'A/C $acodeParam • DIS $disidParam',
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
                            'Sales',
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

                // ---- Stat cards ----
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      children: [
                        _InvEnter(
                          delayMs: 40,
                          child: _InvMiniStatCard(
                            title: 'Distinct Orders',
                            value: '$distinctOrders',
                            icon: Icons.receipt_long_rounded,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _InvEnter(
                          delayMs: 80,
                          child: _InvMiniStatCard(
                            title: 'Total Qty',
                            value: NumberFormat('#,##0').format(totalQty),
                            icon: Icons.countertops_rounded,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _InvEnter(
                          delayMs: 120,
                          child: _InvMiniStatCard(
                            title: 'Pcs • Ctn',
                            value:
                                '${NumberFormat('#,##0').format(totalPcs)} • ${NumberFormat('#,##0').format(totalCtn)}',
                            icon: Icons.inventory_2_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ---- Search (same glass style) ----
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _InvEnter(
                      delayMs: 160,
                      child: _InvGlass(
                        child: TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search order #, A/C, item, description',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close_rounded, color: _InvTheme.cMuted),
                                    onPressed: () {
                                      _search.clear();
                                      setState(() {});
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ---- Body states ----
                if (state.salesHistoryStatus == SalesHistoryStatus.loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.salesHistoryStatus == SalesHistoryStatus.failure)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _InvErrorView(
                      message: state.salesHistoryError ?? 'Failed to load sales history',
                      onRetry: () {
                        if (acodeParam.isNotEmpty && disidParam.isNotEmpty) {
                          context.read<GlobalBloc>().add(
                                LoadSalesHistoryRequested(acode: acodeParam, disid: disidParam),
                              );
                        }
                      },
                    ),
                  )
                else
                  _buildSalesListSliver(context, state, data, acodeParam, disidParam),
              ],
            );
          },
        ),
      ),
    );
  }

  SliverList _buildSalesListSliver(
    BuildContext context,
    GlobalState state,
    List<GetSaleHistoryModel> data,
    String acodeParam,
    String disidParam,
  ) {
    if (state.salesHistoryStatus == SalesHistoryStatus.initial) {
      return SliverList.list(children: const [_InvEmptyView(text: 'No sales yet.')]);
    }
    if (state.salesHistoryStatus == SalesHistoryStatus.success && data.isEmpty) {
      return SliverList.list(
          children: const [_InvEmptyView(text: 'No records found.')]);
    }

    return SliverList.separated(
      itemCount: data.length + 1, // +1 spacer/refresh
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        if (i == data.length) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            child: _InvEnter(
              delayMs: 60,
              child: _InvPressable(
                onTap: () {
                  if (acodeParam.isNotEmpty && disidParam.isNotEmpty) {
                    context.read<GlobalBloc>().add(
                      LoadSalesHistoryRequested(acode: acodeParam, disid: disidParam),
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
        final qty = _num(m.qty);
        final pcs = _num(m.pcsQty);
        final ctn = _num(m.totCtnQty);
        final segTail = _segTail(m.segmentId);

        return Padding(
          padding: EdgeInsets.fromLTRB(16, i == 0 ? 8 : 0, 16, 0),
          child: _InvEnter(
            delayMs: 60 + (i % 6) * 40,
            child: _InvGlass(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                leading: _InvAvatarLabel(text: segTail),
                title: Text(
                  'Order #${m.ordNo ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _InvTheme.cText,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    [
                      if ((m.itemDesc ?? '').isNotEmpty) (m.itemDesc ?? ''),
                      if ((m.acode ?? '').isNotEmpty) 'A/C ${m.acode}',
                      if ((m.partyName ?? '').isNotEmpty) m.partyName!,
                      if ((m.itemid ?? '').isNotEmpty) '#${m.itemid}',
                    ].join('\n'),
                    style: const TextStyle(color: _InvTheme.cMuted),
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Qty: ${NumberFormat('#,##0').format(qty)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: _InvTheme.cText)),
                    const SizedBox(height: 2),
                    Text('Pcs: ${NumberFormat('#,##0').format(pcs)}',
                        style: const TextStyle(fontSize: 12, color: _InvTheme.cMuted)),
                    Text('Ctn: ${NumberFormat('#,##0').format(ctn)}',
                        style: const TextStyle(fontSize: 12, color: _InvTheme.cMuted)),
                  ],
                ),
                // onTap: () {}, // optional details
              ),
            ),
          ),
        );
      },
    );
  }
}

/* ---------- If you ALREADY have these helpers in another file, delete the duplicates below and import them. ---------- */

class _InvTheme {
  static const cBg = Color(0xFFEEEEEE);
  static const cText = Color(0xFF1F2937);
  static const cMuted = Color(0xFF6B7280);
  static const cStroke = Color(0xFFE9E9EF);
  static const cPrimary = Color(0xFFEA7A3B);
  static const cPrimarySoft = Color(0xFFFFB07A);
  static const cShadow = Color(0x14000000);
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
                  Text(
                    value,
                    style: t.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _InvTheme.cText,
                    ),
                  ),
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
  const _InvEmptyView({this.text = 'No records to show'});

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
  late final Animation<double> _opacity =
      CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
  late final Animation<Offset> _offset =
      Tween(begin: const Offset(0, .1), end: Offset.zero).animate(
    CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic),
  );

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


// ⬇️ your bloc/state imports
// import 'global_bloc.dart';
// import 'global_state.dart';
// import 'global_event.dart';
/*
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
  // HomeUpdated / NewLogin theme palette
  static const cBg = Color(0xFFEEEEEE);
  static const cSurface = Colors.white;
  static const cText = Color(0xFF1F2937);
  static const cMuted = Color(0xFF6B7280);
  static const cStroke = Color(0xFFE9E9EF);
  static const cPrimary = Color(0xFFEA7A3B);
  static const cPrimarySoft = Color(0xFFFFB07A);
  static const cShadow = Color(0x14000000);

  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    // fire once using widget params; don’t re-hit if already loaded & non-empty
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

  OutlineInputBorder _border([Color c = Colors.transparent]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c),
      );

  InputDecoration _searchDec() => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintText: 'Search order #, item, or A/C code',
        hintStyle: const TextStyle(color: cMuted),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: (_search.text.isNotEmpty)
            ? IconButton(
                icon: const Icon(Icons.close_rounded, color: cMuted),
                onPressed: () {
                  _search.clear();
                  setState(() {});
                },
              )
            : null,
        enabledBorder: _border(Colors.transparent),
        focusedBorder: _border(cStroke),
      );

  @override
  Widget build(BuildContext context) {
    final acodeParam = widget.acode.trim();
    final disidParam = widget.disid.trim();
    final t = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: cBg,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Gradient header background
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Container(
                      height: 140,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cPrimary, cPrimarySoft],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _HeroGlassHeader(
                        titleBottom: 'Sales history',
                        right: _AcDisBadge(acode: acodeParam, disid: disidParam),
                      ),
                    ),
                  ],
                ),
              ),

              // Search card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: _GlassCard(
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: _searchDec(),
                    ),
                  ),
                ),
              ),

              // Count row (reactive)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: BlocSelector<GlobalBloc, GlobalState, int>(
                    selector: (s) => s.salesHistory.length,
                    builder: (_, count) => Row(
                      children: [
                        Text('$count records',
                            style: t.bodySmall?.copyWith(color: cMuted)),
                        const Spacer(),
                        if (_search.text.isNotEmpty)
                          Text(
                            'filter: "${_search.text.trim()}"',
                            style: t.bodySmall?.copyWith(
                              color: cPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content (loading / error / list)
              SliverFillRemaining(
                hasScrollBody: true,
                child: BlocBuilder<GlobalBloc, GlobalState>(
                  buildWhen: (p, c) =>
                      p.salesHistoryStatus != c.salesHistoryStatus ||
                      p.salesHistory != c.salesHistory ||
                      p.salesHistoryError != c.salesHistoryError,
                  builder: (context, state) {
                    // Loading
                    if (state.salesHistoryStatus ==
                        SalesHistoryStatus.loading) {
                      return const Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.6),
                        ),
                      );
                    }

                    // Failure
                    if (state.salesHistoryStatus ==
                        SalesHistoryStatus.failure) {
                      return _ThemedError(
                        message: state.salesHistoryError ??
                            'Failed to load sales history',
                        onRetry: () {
                          if (acodeParam.isNotEmpty &&
                              disidParam.isNotEmpty) {
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

                    // Filter
                    final q = _search.text.trim().toLowerCase();
                    final all = state.salesHistory;
                    final data = q.isEmpty
                        ? all
                        : all.where((m) {
                            final ord = (m.ordNo ?? '').toLowerCase();
                            final ac = (m.acode ?? '').toLowerCase();
                            final desc = (m.itemDesc ?? '').toLowerCase();
                            return ord.contains(q) ||
                                ac.contains(q) ||
                                desc.contains(q);
                          }).toList();

                    if (state.salesHistoryStatus ==
                        SalesHistoryStatus.initial) {
                      return const _EmptyView(
                          text: 'No sales yet. Pull to refresh.');
                    }

                    if (state.salesHistoryStatus ==
                            SalesHistoryStatus.success &&
                        data.isEmpty) {
                      return const _EmptyView(
                          text: 'No results match your search.');
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
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                        itemCount: data.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final m = data[i];
                          final qty = _num(m.qty);
                          final pcs = _num(m.pcsQty);
                          final ctn = _num(m.totCtnQty);

                          return _HistoryTile(
                            orderNo: m.ordNo ?? '-',
                            itemDesc: m.itemDesc ?? '',
                            acode: m.acode ?? '-',
                            party: m.partyName ?? '',
                            itemId: m.itemid ?? '',
                            segmentTail: _segTail(m.segmentId),
                            qty: qty,
                            pcs: pcs,
                            ctn: ctn,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _segTail(String? seg) {
    final s = (seg ?? '').trim();
    if (s.isEmpty) return 'OR';
    if (s.length <= 2) return s;
    return s.substring(s.length - 2);
  }
}

/* ---------------- themed pieces ---------------- */

class _HeroGlassHeader extends StatelessWidget {
  const _HeroGlassHeader({
    required this.titleBottom,
    required this.right,
  });

  final String titleBottom;
  final Widget right;

  static const cStroke = _SalesHistoryScreenState.cStroke;
  static const cText = _SalesHistoryScreenState.cText;
  static const cShadow = _SalesHistoryScreenState.cShadow;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.75),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cStroke),
            boxShadow: const [
              BoxShadow(color: cShadow, blurRadius: 22, offset: Offset(0, 12)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: cStroke),
                  boxShadow: const [
                    BoxShadow(
                        color: cShadow, blurRadius: 12, offset: Offset(0, 6)),
                  ],
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: _SalesHistoryScreenState.cPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    titleBottom,
                    overflow: TextOverflow.ellipsis,
                    style: t.headlineSmall?.copyWith(
                      color: cText,
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

class _AcDisBadge extends StatelessWidget {
  const _AcDisBadge({required this.acode, required this.disid});
  final String acode;
  final String disid;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _SalesHistoryScreenState.cStroke),
        boxShadow: const [
          BoxShadow(
              color: _SalesHistoryScreenState.cShadow,
              blurRadius: 12,
              offset: Offset(0, 6)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'A/C $acode • DIS $disid',
        style: const TextStyle(
          color: _SalesHistoryScreenState.cText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _SalesHistoryScreenState.cStroke),
            boxShadow: const [
              BoxShadow(
                  color: _SalesHistoryScreenState.cShadow,
                  blurRadius: 16,
                  offset: Offset(0, 10)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.orderNo,
    required this.itemDesc,
    required this.acode,
    required this.party,
    required this.itemId,
    required this.segmentTail,
    required this.qty,
    required this.pcs,
    required this.ctn,
  });

  final String orderNo;
  final String itemDesc;
  final String acode;
  final String party;
  final String itemId;
  final String segmentTail;
  final double qty;
  final double pcs;
  final double ctn;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_SalesHistoryScreenState.cPrimary, _SalesHistoryScreenState.cPrimarySoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.4),
          boxShadow: const [
            BoxShadow(
              color: _SalesHistoryScreenState.cShadow,
              blurRadius: 14,
              offset: Offset(0, 8),
            )
          ],
          border: Border.all(color: const Color(0xFFEDEFF2)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // icon box
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                segmentTail,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _SalesHistoryScreenState.cPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Pill(text: 'A/C $acode'),
                  const SizedBox(height: 6),
                  Text(
                    orderNo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleMedium?.copyWith(
                      color: _SalesHistoryScreenState.cText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (itemDesc.isNotEmpty)
                    Text(
                      itemDesc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(color: _SalesHistoryScreenState.cMuted),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: -6,
                    children: [
                      if (party.isNotEmpty) _Chip('• $party'),
                      if (itemId.isNotEmpty) _Chip('#$itemId'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // amounts
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Qty: ${qty.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Pcs: ${pcs.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: _SalesHistoryScreenState.cMuted)),
                Text('Ctn: ${ctn.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _SalesHistoryScreenState.cText,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _SalesHistoryScreenState.cPrimary.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _SalesHistoryScreenState.cPrimary.withOpacity(.25),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _SalesHistoryScreenState.cText,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: _SalesHistoryScreenState.cText),
      ),
    );
  }
}

class _ThemedError extends StatelessWidget {
  const _ThemedError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _SalesHistoryScreenState.cPrimary, size: 36),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: _SalesHistoryScreenState.cText),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 140,
              height: 42,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _SalesHistoryScreenState.cPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                label: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({this.text = 'No records to show'});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _GlassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inbox_outlined,
                    color: _SalesHistoryScreenState.cPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: t.bodyMedium?.copyWith(
                    color: _SalesHistoryScreenState.cMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/

// class SalesHistoryScreen extends StatefulWidget {
//   final String acode;
//   final String disid;
//   const SalesHistoryScreen({
//     super.key,
//     required this.acode,
//     required this.disid,
//   });

//   @override
//   State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
// }

// class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
//   final _search = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     // fire once using only widget params; don’t re-hit if already loaded & non-empty
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final s = context.read<GlobalBloc>().state;
//       final alreadyLoaded =
//           s.salesHistoryStatus == SalesHistoryStatus.success &&
//           s.salesHistory.isNotEmpty;

//       if (!alreadyLoaded &&
//           widget.acode.trim().isNotEmpty &&
//           widget.disid.trim().isNotEmpty) {
//         context.read<GlobalBloc>().add(
//               LoadSalesHistoryRequested(
//                 acode: widget.acode.trim(),
//                 disid: widget.disid.trim(),
//               ),
//             );
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _search.dispose();
//     super.dispose();
//   }

//   double _num(String? s) => double.tryParse((s ?? '').replaceAll(',', '')) ?? 0;

//   @override
//   Widget build(BuildContext context) {
//     final acodeParam = widget.acode.trim();
//     final disidParam = widget.disid.trim();

//     return Scaffold(
//       appBar: AppBar(
//         title: BlocSelector<GlobalBloc, GlobalState, int>(
//           selector: (s) => s.salesHistory.length,
//           builder: (_, count) => Text('Sales History ($count)'),
//         ),
//       ),
//       body: Column(
//         children: [
//           // Search bar
//           Padding(
//             padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
//             child: TextField(
//               controller: _search,
//               decoration: const InputDecoration(
//                 hintText: 'Search by Order #, Item, or A/C code',
//                 prefixIcon: Icon(Icons.search),
//                 border: OutlineInputBorder(),
//               ),
//               onChanged: (_) => setState(() {}),
//             ),
//           ),

//           // List / States
//           Expanded(
//             child: BlocBuilder<GlobalBloc, GlobalState>(
//               buildWhen: (p, c) =>
//                   p.salesHistoryStatus != c.salesHistoryStatus ||
//                   p.salesHistory != c.salesHistory ||
//                   p.salesHistoryError != c.salesHistoryError,
//               builder: (context, state) {
//                 // loading
//                 if (state.salesHistoryStatus == SalesHistoryStatus.loading) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 // failure
//                 if (state.salesHistoryStatus == SalesHistoryStatus.failure) {
//                   return _SHErrorView(
//                     message:
//                         state.salesHistoryError ?? 'Failed to load sales history',
//                     onRetry: () {
//                       if (acodeParam.isNotEmpty && disidParam.isNotEmpty) {
//                         context.read<GlobalBloc>().add(
//                               LoadSalesHistoryRequested(
//                                 acode: acodeParam,
//                                 disid: disidParam,
//                               ),
//                             );
//                       }
//                     },
//                   );
//                 }

//                 final q = _search.text.trim().toLowerCase();
//                 final all = state.salesHistory;

//                 final data = q.isEmpty
//                     ? all
//                     : all.where((m) {
//                         final ord = (m.ordNo ?? '').toLowerCase();
//                         final ac = (m.acode ?? '').toLowerCase();
//                         final desc = (m.itemDesc ?? '').toLowerCase();
//                         return ord.contains(q) || ac.contains(q) || desc.contains(q);
//                       }).toList();

//                 if (state.salesHistoryStatus == SalesHistoryStatus.initial) {
//                   return const _SHEmptyView(text: 'No sales yet.');
//                 }
//                 if (state.salesHistoryStatus == SalesHistoryStatus.success &&
//                     data.isEmpty) {
//                   return const _SHEmptyView(text: 'No results match your search.');
//                 }

//                 return RefreshIndicator(
//                   onRefresh: () async {
//                     if (acodeParam.isNotEmpty && disidParam.isNotEmpty) {
//                       context.read<GlobalBloc>().add(
//                             LoadSalesHistoryRequested(
//                               acode: acodeParam,
//                               disid: disidParam,
//                             ),
//                           );
//                     }
//                   },
//                   child: ListView.separated(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//                     itemCount: data.length,
//                     separatorBuilder: (_, __) => const SizedBox(height: 8),
//                     itemBuilder: (ctx, i) {
//                       final m = data[i];

//                       final qty = _num(m.qty);
//                       final pcs = _num(m.pcsQty);
//                       final ctn = _num(m.totCtnQty);

//                       return Card(
//                         elevation: 0.5,
//                         child: ListTile(
//                           leading: CircleAvatar(
//                             child: Text((m.segmentId ?? '').isEmpty
//                                 ? 'OR'
//                                 : (m.segmentId!.length >= 2
//                                     ? m.segmentId!.substring(m.segmentId!.length - 2)
//                                     : m.segmentId!)),
//                           ),
//                           title: Text(m.ordNo ?? '-'), // Order #
//                           subtitle: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               if ((m.itemDesc ?? '').isNotEmpty)
//                                 Text(
//                                   m.itemDesc!,
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               const SizedBox(height: 4),
//                               Wrap(
//                                 spacing: 8,
//                                 runSpacing: -6,
//                                 children: [
//                                   _chip('A/C ${m.acode ?? '-'}'),
//                                   if ((m.partyName ?? '').isNotEmpty)
//                                     _chip(m.partyName!),
//                                   if ((m.itemid ?? '').isNotEmpty) _chip('#${m.itemid}'),
//                                 ],
//                               ),
//                             ],
//                           ),
//                           trailing: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               Text('Qty: ${qty.toStringAsFixed(0)}'),
//                               Text('Pcs: ${pcs.toStringAsFixed(0)}',
//                                   style: const TextStyle(fontSize: 12)),
//                               Text('Ctn: ${ctn.toStringAsFixed(0)}',
//                                   style: const TextStyle(
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.w600)),
//                             ],
//                           ),
//                           onTap: () {
//                             // you can push a detail screen here if needed
//                           },
//                         ),
//                       );
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _chip(String s) => Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           color: const Color(0xFFF5F5F7),
//           borderRadius: BorderRadius.circular(999),
//         ),
//         child: Text(
//           s,
//           style: const TextStyle(fontSize: 12, color: Color(0xFF1E1E1E)),
//         ),
//       );
// }

// class _SHErrorView extends StatelessWidget {
//   final String message;
//   final VoidCallback onRetry;
//   const _SHErrorView({required this.message, required this.onRetry});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(message, textAlign: TextAlign.center),
//             const SizedBox(height: 12),
//             ElevatedButton.icon(
//               onPressed: onRetry,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Retry'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _SHEmptyView extends StatelessWidget {
//   final String text;
//   const _SHEmptyView({this.text = 'No records to show'});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Text(text),
//       ),
//     );
//   }
// }
