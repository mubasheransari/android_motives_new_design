import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// THEME — grey + peach
const kBrand = Color(0xFFFFB07A); // accent
const kHeader = Color(0xFF4A4A4A); // grey header
const kSurface = Colors.white;
const kBorder = Color(0xFFE7E9ED);
const kText = Color(0xFF1E1E1E);
const kMuted = Color(0xFF707883);
const kChipBg = Color(0xFFF5F6F8);
final _money = NumberFormat('#,##0.##');

/// MODELS (share with TakeOrderPage or extract to a separate file if you prefer)
class Product {
  final String sku;
  final String name;
  final double unitWeight; // Kgs/Ltr per unit
  final double unitPrice; // Price per unit
  final int stock;

  const Product({
    required this.sku,
    required this.name,
    required this.unitWeight,
    required this.unitPrice,
    required this.stock,
  });
}

class CartLine {
  final Product product;
  int qty;
  CartLine({required this.product, required this.qty});

  double get lineWeight => product.unitWeight * qty;
  double get lineTotal => product.unitPrice * qty;
}

/// ADD ITEMS PICKER
class AddItemsPage extends StatefulWidget {
  final Set<String> alreadyInCart; // to dim/disable rows already in cart
  const AddItemsPage({super.key, this.alreadyInCart = const {}});

  @override
  State<AddItemsPage> createState() => _AddItemsPageState();
}

class _AddItemsPageState extends State<AddItemsPage> {
  final List<Product> _catalog = const [
    Product(
      sku: '110254',
      name: 'FIZUP NEXT • LEMON 2.25 LTR (2.25 LTR x 4)',
      unitWeight: 2.25,
      unitPrice: 745.2,
      stock: 2303,
    ),
    Product(
      sku: '110269',
      name: 'ANAAR NEXT • QANDHARI 2.25 LTR (2.25 LTR x 4)',
      unitWeight: 2.25,
      unitPrice: 745.2,
      stock: 2395,
    ),
    Product(
      sku: '110264',
      name: 'DARE NEXT • 2.25 LTR (2.25 LTR x 4)',
      unitWeight: 2.25,
      unitPrice: 745.2,
      stock: 808,
    ),
    Product(
      sku: '110274',
      name: 'LYCHEE NEXT • 2.25 LTR (2.25 LTR x 4)',
      unitWeight: 2.25,
      unitPrice: 745.2,
      stock: 1433,
    ),
    Product(
      sku: '110259',
      name: 'RANGO NEXT • ORANGE 2.25 LTR (2.25 LTR x 4)',
      unitWeight: 2.25,
      unitPrice: 745.2,
      stock: 3006,
    ),
  ];

  final Map<String, int> _qty = {}; // sku -> qty
  String _query = '';

  List<Product> get _filtered {
    if (_query.isEmpty) return _catalog;
    final q = _query.toLowerCase();
    return _catalog
        .where((p) => p.name.toLowerCase().contains(q) || p.sku.contains(q))
        .toList();
  }

  void _save() {
    final lines = <CartLine>[];
    _qty.forEach((sku, q) {
      if (q > 0) {
        final prod = _catalog.firstWhere((p) => p.sku == sku);
        lines.add(CartLine(product: prod, qty: q));
      }
    });
    Navigator.pop(context, lines);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      // appBar: AppBar(
      //   elevation: 0,
      //   backgroundColor: kHeader,
      //   foregroundColor: Colors.white,
      //   title: const Text('Add Items'),
      //   centerTitle: true,
      //   shape: const RoundedRectangleBorder(
      //     borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      //   ),
      //   actions: [
      //     IconButton(
      //       onPressed: () async {
      //         final q = await showSearch<String?>(
      //           context: context,
      //           delegate: _ProductSearchDelegate(initialQuery: _query),
      //         );
      //         if (q != null) setState(() => _query = q);
      //       },
      //       icon: const Icon(Icons.search),
      //     ),
      //   ],
      // ),
      body: Column(
        children: [
          SizedBox(height: 30,),
          Container(
            height: 54,
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            decoration: BoxDecoration(
              color: kChipBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SortFilterButton(
                    icon: Icons.sort_rounded,
                    label: 'Sort by',
                    onTap: () {}, // TODO
                  ),
                ),
                const VerticalDivider(width: 1, color: kBorder, thickness: 1),
                Expanded(
                  child: _SortFilterButton(
                    icon: Icons.filter_list_rounded,
                    label: 'Filter by',
                    onTap: () {}, // TODO
                  ),
                ),
              ],
            ),
          ),

          // Items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final p = _filtered[index];
                final disabled = widget.alreadyInCart.contains(p.sku);
                final qty = _qty[p.sku] ?? 0;

                return Opacity(
                  opacity: disabled ? .55 : 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          p.name.split('•').first.trim(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            letterSpacing: .2,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Subtitle (sku + rest)
                        Text(
                          '${p.sku} — ${p.name}',
                          style: const TextStyle(
                            color: kMuted,
                            fontSize: 12.5,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Stock + Price row
                        Row(
                          children: [
                            _InfoPill(
                              icon: Icons.inventory_2_outlined,
                              label: 'Stock',
                              value: _money.format(p.stock),
                            ),
                            const SizedBox(width: 8),
                            _InfoPill(
                              icon: Icons.sell_outlined,
                              label: 'Price',
                              value: 'Rs. ${_money.format(p.unitPrice)}',
                            ),
                            const Spacer(),
                            const Text('qty', style: TextStyle(color: kMuted)),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Stepper
                        Row(
                          children: [
                            _StepperButton(
                              icon: Icons.remove_rounded,
                              onTap: disabled || qty <= 0
                                  ? null
                                  : () => setState(() => _qty[p.sku] = qty - 1),
                            ),
                            SizedBox(
                              width: 44,
                              child: Center(
                                child: Text(
                                  '$qty',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            _StepperButton(
                              icon: Icons.add_rounded,
                              onTap: disabled
                                  ? null
                                  : () => setState(() => _qty[p.sku] = qty + 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom buttons
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _PrimaryButton(label: 'SAVE', onTap: _save),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SecondaryButton(
                      label: 'CANCEL',
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

/// ---- helpers / shared widgets (private to this file) ----

class _SortFilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SortFilterButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: kMuted),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoPill(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kChipBg,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kMuted),
          const SizedBox(width: 6),
          Text('$label: ',
              style: const TextStyle(color: kMuted, fontSize: 12.5)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: kText,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 36,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: kBrand,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Icon(icon, size: 20),
      ),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }
}

/// -------- Simple search (FIXED: pass BuildContext to `close`) --------
class _ProductSearchDelegate extends SearchDelegate<String?> {
  _ProductSearchDelegate({String initialQuery = ''}) {
    query = initialQuery;
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: kHeader,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
      ),
      textTheme: base.textTheme.apply(bodyColor: Colors.white),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
              icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _body(context);
  @override
  Widget buildSuggestions(BuildContext context) => _body(context);

  Widget _body(BuildContext context) => ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.search),
            title: Text('Search "$query"'),
            onTap: () => close(context, query), // <-- use context, not null
          ),
        ],
      );
}
