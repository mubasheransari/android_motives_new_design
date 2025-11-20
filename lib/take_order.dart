import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motives_new_ui_conversion/addItems.dart';

/// THEME TOKENS (same as picker)
const kBrand = Color(0xFFFFB07A);
const kHeader = Color(0xFF3C4A57);
const kSurface = Colors.white;
const kBorder = Color(0xFFE7E9ED);
const kText = Color(0xFF1E1E1E);
const kMuted = Color(0xFF707883);
const kChipBg = Color(0xFFF5F6F8);
final _money = NumberFormat('#,##0.##');
   const Color orange = Color(0xFFEA7A3B);


class TakeOrderPage extends StatefulWidget {
  const TakeOrderPage({super.key});

  @override
  State<TakeOrderPage> createState() => _TakeOrderPageState();
}

class _TakeOrderPageState extends State<TakeOrderPage> {
  final List<CartLine> _cart = [
    CartLine(
      product: const Product(
        sku: 'MZ-2.5-BUCKET',
        name: 'MEZAN 2.5 KG GHEE BUCKET',
        unitWeight: 2.50,
        unitPrice: 1380,
        stock: 120,
      ),
      qty: 1,
    ),
    CartLine(
      product: const Product(
        sku: 'MZ-2.5-TIN',
        name: 'MEZAN 2.5 KG GHEE TIN',
        unitWeight: 2.50,
        unitPrice: 1375,
        stock: 80,
      ),
      qty: 1,
    ),
    CartLine(
      product: const Product(
        sku: 'MZ-5-BUCKET',
        name: 'MEZAN 5 KG GHEE BUCKET',
        unitWeight: 5.00,
        unitPrice: 2730,
        stock: 44,
      ),
      qty: 1,
    ),
    CartLine(
      product: const Product(
        sku: 'MZ-10-BUCKET',
        name: 'MEZAN 10 KG GHEE BUCKET',
        unitWeight: 10.00,
        unitPrice: 5400,
        stock: 30,
      ),
      qty: 2,
    ),
  ];

  int get totalQty => _cart.fold(0, (s, e) => s + e.qty);
  double get totalWeight => _cart.fold(0.0, (s, e) => s + e.lineWeight);
  double get grand => _cart.fold(0.0, (s, e) => s + e.lineTotal);

  Future<void> _openAddItems() async {
    final result = await Navigator.push<List<CartLine>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemsPage(
          alreadyInCart: _cart.map((e) => e.product.sku).toSet(),
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        for (final r in result) {
          final i = _cart.indexWhere((c) => c.product.sku == r.product.sku);
          if (i >= 0) {
            _cart[i].qty += r.qty;
          } else {
            _cart.add(r);
          }
        }
      });
    }
  }
  

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
 

          const SizedBox(height: 52),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: kHeader,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.storefront_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'AMPIRIOSHOPINGMALL',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .2,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _HeaderRow(columns: const ['Name', 'Qty', 'Kgs/Ltr', 'G. Amount', 'Del']),
          ),

          const SizedBox(height: 6),

          // Lines
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _cart.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: kBorder),
              itemBuilder: (context, index) {
                final line = _cart[index];
                return _LineRow(
                  name: line.product.name,
                  qty: line.qty,
                  weight: line.lineWeight,
                  amount: line.lineTotal,
                  onDelete: () => setState(() => _cart.removeAt(index)),
                );
              },
            ),
          ),

          // Totals
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _TotalsRow(
              qty: totalQty,
              weight: totalWeight,
              amount: grand,
            ),
          ),

          // Bottom buttons
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _PrimaryButton(label: 'ADD', onTap: _openAddItems),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SecondaryButton(
                      label: 'BACK',
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _HeaderRow extends StatelessWidget {
  final List<String> columns;
  const _HeaderRow({required this.columns});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: kChipBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          _HeaderCell(columns[0], flex: 6),
          _HeaderCell(columns[1], flex: 2),
          _HeaderCell(columns[2], flex: 2),
          _HeaderCell(columns[3], flex: 3),
          _HeaderCell(columns[4], flex: 1, center: true),
        ],
      ),
    );
  }
}



class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final bool center;
  const _HeaderCell(this.label, {this.flex = 1, this.center = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: kMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            letterSpacing: .2,
          ),
        ),
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final String name;
  final int qty;
  final double weight;
  final double amount;
  final VoidCallback onDelete;

  const _LineRow({
    required this.name,
    required this.qty,
    required this.weight,
    required this.amount,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kSurface,
      height: 52,
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, color: kText),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text('$qty',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(weight.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 13.5)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Text(_money.format(amount),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Remove',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  final int qty;
  final double weight;
  final double amount;
  const _TotalsRow({
    required this.qty,
    required this.weight,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    Widget totalBox(String v) => Container(
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEF6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            v,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: kHeader,
            ),
          ),
        );

    return Row(
      children: [
        const Expanded(
          flex: 6,
          child: Text('Total',
              style:
                  TextStyle(fontWeight: FontWeight.w700, color: kText)),
        ),
        Expanded(flex: 2, child: totalBox('$qty')),
        const SizedBox(width: 6),
        Expanded(flex: 2, child: totalBox(weight.toStringAsFixed(2))),
        const SizedBox(width: 6),
        Expanded(flex: 4, child: totalBox(_money.format(amount))),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kHeader,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: kHeader.withOpacity(.35), width: 1.4),
          foregroundColor: kHeader,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }
}


class _GlassHeader extends StatelessWidget {
  const _GlassHeader({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.width});
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(.24), blurRadius: 10, spreadRadius: 1),
        ],
      ),
    );
  }
}
class _OrangePills extends StatelessWidget {
  const _OrangePills();

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFEA7A3B);
    return Transform.rotate(
      angle: -12 * 3.1415926 / 180,
      child: Column(
        children: [
          _Pill(color: Colors.white.withOpacity(.28), width: 64),
          const SizedBox(height: 6),
          _Pill(color: orange.withOpacity(.34), width: 78),
          const SizedBox(height: 6),
          _Pill(color: orange, width: 86),
        ],
      ),
    );
  }
}


class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.45), width: .8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_turned_in_rounded,
              size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: t.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}