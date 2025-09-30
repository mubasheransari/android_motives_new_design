import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';


const kOrange = Color(0xFFEA7A3B);
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
}





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