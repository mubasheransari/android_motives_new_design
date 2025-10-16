import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Models/login_model.dart';
import 'package:motives_new_ui_conversion/order_menu_screen.dart';
import 'dart:ui';



// ── imports ───────────────────────────────────────────────────────────────────
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// import your app bits that are referenced:
// import 'order_menu_screen.dart';
// import 'global_bloc.dart';
// import 'models.dart'; // contains JourneyPlan, etc.

// ── theme constants ───────────────────────────────────────────────────────────
const kOrange = Color(0xFFEA7A3B);
const kOrangeLite = Color(0xFFFFB07A); // added (used in gradients)
const kText = Color(0xFF1E1E1E);
const kMuted = Color(0xFF707883);
const kField = Color(0xFFF2F3F5);
const kCard = Colors.white;
const kShadow = Color(0x14000000);

class JourneyPlanScreen extends StatefulWidget {
  const JourneyPlanScreen({super.key});

  @override
  State<JourneyPlanScreen> createState() => _JourneyPlanScreenState();
}

class _JourneyPlanScreenState extends State<JourneyPlanScreen> {
  final _search = TextEditingController();
  String? _selectedAddress;

  final Map<String, String> _reasonsByMiscId = {};
  final box = GetStorage();

  void _writeCoveredCount() {
  final data = box.read('journey_reasons');
  final lengthOfMarkedReasons = (data is Map) ? data.length : 0;
  box.write('covered_routes_count', lengthOfMarkedReasons);
}


@override
void initState() {
  super.initState();

    context.read<GlobalBloc>().add(Activity(activity: 'Journey Plan'));

  // existing code that seeds _reasonsByMiscId...
  final raw = box.read('journey_reasons');
  if (raw is Map) {
    raw.forEach((k, v) => _reasonsByMiscId[k.toString()] = v.toString());
  }

  // ✅ NEW: seed & auto-update covered_routes_count whenever journey_reasons changes
  _writeCoveredCount();                                // seed once
  box.listenKey('journey_reasons', (_) => _writeCoveredCount()); // keep in sync
}

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String formatTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .toLowerCase()
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  /// Dedupe helper: keep first occurrence for each shop.
  /// Key = accode (if non-empty) else "partyName||custAddress" (trimmed/lowercased)
  List<JourneyPlan> _dedupeJourneyPlans(List<JourneyPlan> plans) {
    final seen = <String>{};
    final unique = <JourneyPlan>[];
    for (final p in plans) {
      final accode = (p.accode).trim();
      final key = accode.isNotEmpty
          ? 'ID:${accode.toLowerCase()}'
          : 'N:${p.partyName.trim().toLowerCase()}|${p.custAddress.trim().toLowerCase()}';
      if (seen.add(key)) {
        unique.add(p);
      }
    }
    return unique;
  }

  @override
  Widget build(BuildContext context) {


    final t = Theme.of(context).textTheme;

    // Get raw plans from model, then remove duplicates (UI unchanged)
    final journeyPlansRaw =
        context.watch<GlobalBloc>().state.loginModel?.journeyPlan ?? const <JourneyPlan>[];
    final journeyPlans = _dedupeJourneyPlans(journeyPlansRaw);

    // Address counts based on de-duplicated list
    final addressCounts = <String, int>{};
    for (final plan in journeyPlans) {
      final addr = (plan.custAddress).trim();
      if (addr.isNotEmpty) {
        addressCounts[addr] = (addressCounts[addr] ?? 0) + 1;
      }
    }

    final allPlans = journeyPlans; // already non-null and deduped
    final q = _search.text.trim().toLowerCase();

    final filteredPlans = allPlans.where((plan) {
      final name = (plan.partyName).toLowerCase();
      final address = plan.custAddress;
      final matchesSearch = name.contains(q);
      final matchesChip = _selectedAddress == null || address == _selectedAddress;
      return matchesSearch && matchesChip;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Stack(
            children: [
              Container(
                height: 166,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kOrange, kOrangeLite],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 42, 16, 0),
                child: _GlassHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.22),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.2),
                          ),
                          child: const Icon(Icons.route_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Journey Plan',
                                  style: t.titleMedium?.copyWith(
                                      color: Colors.white, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text('${journeyPlans.length} total customers',
                                  style: t.bodySmall?.copyWith(color: Colors.white.withOpacity(.95))),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _HeaderChip(
                              icon: Icons.checklist_outlined,
                              label: 'Filtered: ${filteredPlans.length}'),
                          const SizedBox(width: 8),
                          _HeaderChip(
                            icon: Icons.place_outlined,
                            label: _selectedAddress == null
                                ? 'All Areas'
                                : (_selectedAddress!.length > 24
                                    ? '${_selectedAddress!.substring(0, 24)}…'
                                    : _selectedAddress!),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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
                        hintText: 'Search Customer Shops',
                        hintStyle: TextStyle(color: kMuted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_search.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: kMuted),
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                    ),
                ],
              ),
            ),
          ),

          // address chips
          if (addressCounts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Filter Routes by Area',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: kText)),
              ),
            ),
            SizedBox(
              height: 56,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChoiceChip(
                    label: 'All',
                    selected: _selectedAddress == null,
                    onSelected: () => setState(() => _selectedAddress = null),
                  ),
                  const SizedBox(width: 8),
                  ...addressCounts.entries.map((e) {
                    final addr = e.key;
                    final count = e.value;
                    final selected = _selectedAddress == addr;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChoiceChip(
                        label: '$addr ($count)',
                        selected: selected,
                        onSelected: () => setState(() => _selectedAddress = selected ? null : addr),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // count row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
            child: Row(
              children: [
                Text('${filteredPlans.length} Customers', style: t.bodySmall?.copyWith(color: kMuted)),
                const Spacer(),
                if (_selectedAddress != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: kOrange),
                    onPressed: () => setState(() => _selectedAddress = null),
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    label: const Text('Clear'),
                  ),
              ],
            ),
          ),

          // list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              itemCount: filteredPlans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final plan = filteredPlans[i];

                // stable id for reason map (same as before)
                final miscid = (plan.accode.isNotEmpty
                    ? plan.accode
                    : '${plan.partyName}||${plan.custAddress}');

                return _CustomerCard(
                  title: formatTitleCase(plan.partyName),
                  address: formatTitleCase(plan.custAddress),
                  crLimit: plan.crLimit,
                  crDays: plan.crDays,
                  area: plan.areaName,
                  seg: plan.segement,
                  reason: _reasonsByMiscId[miscid],
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderMenuScreen(
                          miscid: miscid,
                          shopname: plan.partyName,
                          address: plan.custAddress.toString(),
                        ),
                      ),
                    );

                    if (!mounted) return;

                    if (result is Map &&
                        result['miscid'] == miscid &&
                        result['reason'] != null &&
                        (result['reason'] as String).trim().isNotEmpty) {
                      setState(() {
                        _reasonsByMiscId[miscid] = result['reason'] as String;
                      });
                      await box.write('journey_reasons', _reasonsByMiscId);
                    } else {
                      // Also refresh from storage
                      final jr = box.read('journey_reasons');
                      if (jr is Map && jr[miscid] is String) {
                        setState(() => _reasonsByMiscId[miscid] = (jr[miscid] as String));
                      }
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

// ── widgets ───────────────────────────────────────────────────────────────────
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

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.45)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }
}

class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: kOrange,
      labelStyle: TextStyle(color: selected ? Colors.white : kText, fontWeight: FontWeight.w600),
      backgroundColor: Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? Colors.transparent : const Color(0xFFEDEFF2)),
      ),
      elevation: selected ? 2 : 0,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.title,
    required this.address,
    required this.crLimit,
    required this.crDays,
    required this.area,
    required this.seg,
    required this.onTap,
    this.reason,
  });

  final String title;
  final String address;
  final String crLimit;
  final String crDays;
  final String area;
  final String seg;
  final VoidCallback onTap;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kOrange, kOrangeLite],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Container(
          margin: const EdgeInsets.all(1.6),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14.4),
            boxShadow: const [BoxShadow(color: kShadow, blurRadius: 14, offset: Offset(0, 8))],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.store_mall_directory_rounded, size: 28, color: kOrange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleMedium?.copyWith(color: kText, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.place_rounded, size: 18, color: kMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium?.copyWith(color: kText, fontWeight: FontWeight.w300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (reason != null && reason!.trim().isNotEmpty)
                    _TagPill(text: "ACTION: ${reason!}"),
                ],
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
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kOrange.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kOrange.withOpacity(.25)),
      ),
      child: Text(text, style: t.bodySmall?.copyWith(color: kText, fontWeight: FontWeight.w500)),
    );
  }
}


// const kOrange = Color(0xFFEA7A3B);
// const kText = Color(0xFF1E1E1E);
// const kMuted = Color(0xFF707883);
// const kField = Color(0xFFF2F3F5);
// const kCard = Colors.white;
// const kShadow = Color(0x14000000);


// class JourneyPlanScreen extends StatefulWidget {
//   const JourneyPlanScreen({super.key});

//   @override
//   State<JourneyPlanScreen> createState() => _JourneyPlanScreenState();
// }

// class _JourneyPlanScreenState extends State<JourneyPlanScreen> {
//   final _search = TextEditingController();
//   String? _selectedAddress;

//   final Map<String, String> _reasonsByMiscId = {};
  
//   final box = GetStorage();

//   @override
//   void initState() {
//     super.initState();
//     final raw = box.read('journey_reasons');

//     if (raw is Map) {
//       raw.forEach((k, v) => _reasonsByMiscId[k.toString()] = v.toString());
//     }

//    // context.read<GlobalBloc>().add(CoveredRoutesLength(lenght: _reasonsByMiscId.length.toString()));
// //    box.write('covered_routes_count', _reasonsByMiscId.length);
//   }

//   @override
//   void dispose() {
//     _search.dispose();
//     super.dispose();
//   }

//   String formatTitleCase(String text) {
//     if (text.isEmpty) return text;
//     return text
//         .toLowerCase()
//         .split(' ')
//         .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
//         .join(' ');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final data = box.read('journey_reasons');
// final lengthOfMarkedReasons = (data is Map) ? data.length : 0;
// print("JOURNEY PLAN LENGTH $data");
// print("JOURNEY PLAN LENGTH $data");
// print("JOURNEY PLAN LENGTH $data");



//     box.write('covered_routes_count',lengthOfMarkedReasons);


//     final t = Theme.of(context).textTheme;

//     final journeyPlans = context.watch<GlobalBloc>().state.loginModel?.journeyPlan ?? const <JourneyPlan>[];

//     final addressCounts = <String, int>{};
//     for (final plan in journeyPlans) {
//       final addr = (plan.custAddress).trim();
//       if (addr.isNotEmpty) {
//         addressCounts[addr] = (addressCounts[addr] ?? 0) + 1;
//       }
//     }

//   // Make a non-null list of plans
// final allPlans = (journeyPlans ?? const <JourneyPlan>[])
//     .whereType<JourneyPlan>()
//     .toList();

// final q = _search.text.trim().toLowerCase();

// final filteredPlans = allPlans.where((plan) {
//   final name = (plan.partyName ?? '').toLowerCase();
//   final address = plan.custAddress ?? '';
//   final matchesSearch = name.contains(q);
//   final matchesChip = _selectedAddress == null || address == _selectedAddress;
//   return matchesSearch && matchesChip;
// }).toList();


//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           // Header
//           Stack(
//             children: [
//               Container(
//                 height: 166,
//                 decoration: const BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [kOrange, kOrangeLite],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 42, 16, 0),
//                 child: _GlassHeader(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(children: [
//                         Container(
//                           width: 44, height: 44,
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(.22),
//                             shape: BoxShape.circle,
//                             border: Border.all(color: Colors.white, width: 1.2),
//                           ),
//                           child: const Icon(Icons.route_rounded, color: Colors.white, size: 22),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text('Journey Plan',
//                                   style: t.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
//                               const SizedBox(height: 2),
//                               Text('${journeyPlans.length} total customers',
//                                   style: t.bodySmall?.copyWith(color: Colors.white.withOpacity(.95))),
//                             ],
//                           ),
//                         ),
//                       ]),
//                       const SizedBox(height: 10),
//                       Row(
//                         children: [
//                           _HeaderChip(icon: Icons.checklist_outlined, label: 'Filtered: ${filteredPlans.length}'),
//                           const SizedBox(width: 8),
//                           _HeaderChip(
//                             icon: Icons.place_outlined,
//                             label: _selectedAddress == null
//                                 ? 'All Areas'
//                                 : (_selectedAddress!.length > 24
//                                     ? '${_selectedAddress!.substring(0, 24)}…'
//                                     : _selectedAddress!),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           // search
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: kCard,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: const [BoxShadow(color: kShadow, blurRadius: 12, offset: Offset(0, 6))],
//                 border: Border.all(color: const Color(0xFFEDEFF2)),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Row(
//                 children: [
//                   Icon(Icons.search_rounded, color: kMuted.withOpacity(.9)),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: TextField(
//                       controller: _search,
//                       onChanged: (_) => setState(() {}),
//                       decoration: const InputDecoration(
//                         hintText: 'Search Customer Shops',
//                         hintStyle: TextStyle(color: kMuted),
//                         border: InputBorder.none,
//                       ),
//                     ),
//                   ),
//                   if (_search.text.isNotEmpty)
//                     IconButton(
//                       icon: const Icon(Icons.close_rounded, color: kMuted),
//                       onPressed: () {
//                         _search.clear();
//                         setState(() {});
//                       },
//                     ),
//                 ],
//               ),
//             ),
//           ),

//           // address chips
//           if (addressCounts.isNotEmpty) ...[
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text('Filter Routes by Area',
//                     style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: kText)),
//               ),
//             ),
//             SizedBox(
//               height: 56,
//               child: ListView(
//                 padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
//                 scrollDirection: Axis.horizontal,
//                 children: [
//                   _FilterChoiceChip(
//                     label: 'All',
//                     selected: _selectedAddress == null,
//                     onSelected: () => setState(() => _selectedAddress = null),
//                   ),
//                   const SizedBox(width: 8),
//                   ...addressCounts.entries.map((e) {
//                     final addr = e.key;
//                     final count = e.value;
//                     final selected = _selectedAddress == addr;
//                     return Padding(
//                       padding: const EdgeInsets.only(right: 8),
//                       child: _FilterChoiceChip(
//                         label: '$addr ($count)',
//                         selected: selected,
//                         onSelected: () => setState(() => _selectedAddress = selected ? null : addr),
//                       ),
//                     );
//                   }),
//                 ],
//               ),
//             ),
//           ],

//           // count row
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
//             child: Row(
//               children: [
//                 Text('${filteredPlans.length} Customers', style: t.bodySmall?.copyWith(color: kMuted)),
//                 const Spacer(),
//                 if (_selectedAddress != null)
//                   TextButton.icon(
//                     style: TextButton.styleFrom(foregroundColor: kOrange),
//                     onPressed: () => setState(() => _selectedAddress = null),
//                     icon: const Icon(Icons.clear_rounded, size: 18),
//                     label: const Text('Clear'),
//                   ),
//               ],
//             ),
//           ),

//           // list
//           Expanded(
//             child: ListView.separated(
//               padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
//               itemCount: filteredPlans.length,
//               separatorBuilder: (_, __) => const SizedBox(height: 12),
//               itemBuilder: (_, i) {
//                 final plan = filteredPlans[i];

//                 // stable id for reason map
//                 final miscid = (plan.accode.isNotEmpty
//                     ? plan.accode
//                     : '${plan.partyName}||${plan.custAddress}');

//                 return _CustomerCard(
//                   title: formatTitleCase(plan.partyName),
//                   address: formatTitleCase(plan.custAddress),
//                   crLimit: plan.crLimit,
//                   crDays: plan.crDays,
//                   area: plan.areaName,
//                   seg: plan.segement,
//                   reason: _reasonsByMiscId[miscid],
//                   onTap: () async {
//                     final result = await Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => OrderMenuScreen(
//                           miscid: miscid,
//                           shopname: plan.partyName,
//                           address: plan.custAddress.toString(),
//                           // If you have these values, pass them:
//                           // segId: plan.segid,
//                           // checkCredit: ???,
//                           // orderStatus: context.read<GlobalBloc>().state.loginModel?.log?.orderStatus,
//                         ),
//                       ),
//                     );

//                     if (!mounted) return;

//                     if (result is Map &&
//                         result['miscid'] == miscid &&
//                         result['reason'] != null &&
//                         (result['reason'] as String).trim().isNotEmpty) {
//                       setState(() {
//                         _reasonsByMiscId[miscid] = result['reason'] as String;
//                       }); 
//                       await box.write('journey_reasons', _reasonsByMiscId);
//                     } else {
//                       // Also refresh from storage
//                       final jr = box.read('journey_reasons');
//                       if (jr is Map && jr[miscid] is String) {
//                         setState(() => _reasonsByMiscId[miscid] = (jr[miscid] as String));
//                       }
//                     }
//                   },
//                 );
//               },
//             ),
//           ),
//           SizedBox(height: 50,)
//         ],
//       ),
//     );
//   }
// }

// // ── widgets ───────────────────────────────────────────────────────────────────
// class _GlassHeader extends StatelessWidget {
//   const _GlassHeader({required this.child});
//   final Widget child;
//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(18),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(.18),
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }
// }

// class _HeaderChip extends StatelessWidget {
//   const _HeaderChip({required this.icon, required this.label});
//   final IconData icon;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(.18),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: Colors.white.withOpacity(.45)),
//       ),
//       child: Row(mainAxisSize: MainAxisSize.min, children: [
//         Icon(icon, size: 16, color: Colors.white),
//         const SizedBox(width: 6),
//         Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
//       ]),
//     );
//   }
// }

// class _FilterChoiceChip extends StatelessWidget {
//   const _FilterChoiceChip({
//     required this.label,
//     required this.selected,
//     required this.onSelected,
//   });
//   final String label;
//   final bool selected;
//   final VoidCallback onSelected;

//   @override
//   Widget build(BuildContext context) {
//     return ChoiceChip(
//       label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
//       selected: selected,
//       onSelected: (_) => onSelected(),
//       selectedColor: kOrange,
//       labelStyle: TextStyle(color: selected ? Colors.white : kText, fontWeight: FontWeight.w600),
//       backgroundColor: Colors.white,
//       shape: StadiumBorder(
//         side: BorderSide(color: selected ? Colors.transparent : const Color(0xFFEDEFF2)),
//       ),
//       elevation: selected ? 2 : 0,
//       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//     );
//   }
// }

// class _CustomerCard extends StatelessWidget {
//   const _CustomerCard({
//     required this.title,
//     required this.address,
//     required this.crLimit,
//     required this.crDays,
//     required this.area,
//     required this.seg,
//     required this.onTap,
//     this.reason,
//   });

//   final String title;
//   final String address;
//   final String crLimit;
//   final String crDays;
//   final String area;
//   final String seg;
//   final VoidCallback onTap;
//   final String? reason;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return InkWell(
//       borderRadius: BorderRadius.circular(16),
//       onTap: onTap,
//       child: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [kOrange, kOrangeLite],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.all(Radius.circular(16)),
//         ),
//         child: Container(
//           margin: const EdgeInsets.all(1.6),
//           decoration: BoxDecoration(
//             color: kCard,
//             borderRadius: BorderRadius.circular(14.4),
//             boxShadow: const [BoxShadow(color: kShadow, blurRadius: 14, offset: Offset(0, 8))],
//           ),
//           padding: const EdgeInsets.all(14),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   const Icon(Icons.store_mall_directory_rounded, size: 28, color: kOrange),
//                   const SizedBox(width: 6),
//                   Expanded(
//                     child: Text(
//                       title,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: t.titleMedium?.copyWith(color: kText, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 5),
//               Row(
//                 children: [
//                   const Icon(Icons.place_rounded, size: 18, color: kMuted),
//                   const SizedBox(width: 6),
//                   Expanded(
//                     child: Text(
//                       address,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: t.bodyMedium?.copyWith(color: kText, fontWeight: FontWeight.w300),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Wrap(
//                 spacing: 6,
//                 runSpacing: 6,
//                 children: [
//                   if (reason != null && reason!.trim().isNotEmpty)
//                     _TagPill(text: "Reason: ${reason!}"),
//                 ],
//               ),

//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _TagPill extends StatelessWidget {
//   const _TagPill({required this.text});
//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: kOrange.withOpacity(.10),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: kOrange.withOpacity(.25)),
//       ),
//       child: Text(text, style: t.bodySmall?.copyWith(color: kText, fontWeight: FontWeight.w500)),
//     );
//   }
// }





/*class JourneyPlanScreen extends StatefulWidget {
  const JourneyPlanScreen({super.key});

  @override
  State<JourneyPlanScreen> createState() => _JourneyPlanScreenState();
}

class _JourneyPlanScreenState extends State<JourneyPlanScreen> {
  final _search = TextEditingController();
  String? _selectedAddress;

  final Map<String, String> _reasonsByMiscId = {};
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    final raw = box.read('journey_reasons');
    if (raw is Map) {
      raw.forEach((k, v) => _reasonsByMiscId[k.toString()] = v.toString());
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String formatTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .toLowerCase()
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final journeyPlans =
        context.read<GlobalBloc>().state.loginModel?.journeyPlan ?? const [];

    final addressCounts = <String, int>{};
    for (final plan in journeyPlans) {
      final addr = (plan.custAddress).trim();
      if (addr.isNotEmpty) {
        addressCounts[addr] = (addressCounts[addr] ?? 0) + 1;
      }
    }

    final q = _search.text.trim().toLowerCase();
    final filteredPlans = journeyPlans.where((plan) {
      final matchesSearch = plan.partyName.toLowerCase().contains(q);
      final matchesChip =
          _selectedAddress == null || plan.custAddress == _selectedAddress;
      return matchesSearch && matchesChip;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Stack(
            children: [
              Container(
                height: 166,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kOrange, Color(0xFFFFB07A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 42, 16, 0),
                child: _GlassHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.22),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.2),
                          ),
                          child: const Icon(Icons.route_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Journey Plan',
                                  style: t.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text('${journeyPlans.length} total customers',
                                  style: t.bodySmall?.copyWith(color: Colors.white.withOpacity(.95))),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _HeaderChip(icon: Icons.checklist_outlined, label: 'Filtered: ${filteredPlans.length}'),
                          const SizedBox(width: 8),
                          _HeaderChip(
                            icon: Icons.place_outlined,
                            label: _selectedAddress == null
                                ? 'All Areas'
                                : (_selectedAddress!.length > 24
                                    ? '${_selectedAddress!.substring(0, 24)}…'
                                    : _selectedAddress!),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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
                        hintText: 'Search Customer Shops',
                        hintStyle: TextStyle(color: kMuted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_search.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: kMuted),
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                    ),
                ],
              ),
            ),
          ),

          // address chips
          if (addressCounts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Filter Routes by Area',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: kText)),
              ),
            ),
            SizedBox(
              height: 56,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChoiceChip(
                    label: 'All',
                    selected: _selectedAddress == null,
                    onSelected: () => setState(() => _selectedAddress = null),
                  ),
                  const SizedBox(width: 8),
                  ...addressCounts.entries.map((e) {
                    final addr = e.key;
                    final count = e.value;
                    final selected = _selectedAddress == addr;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChoiceChip(
                        label: '$addr ($count)',
                        selected: selected,
                        onSelected: () => setState(() => _selectedAddress = selected ? null : addr),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // count row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
            child: Row(
              children: [
                Text('${filteredPlans.length} Customers', style: t.bodySmall?.copyWith(color: kMuted)),
                const Spacer(),
                if (_selectedAddress != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: kOrange),
                    onPressed: () => setState(() => _selectedAddress = null),
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    label: const Text('Clear'),
                  ),
              ],
            ),
          ),

          // list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              itemCount: filteredPlans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final plan = filteredPlans[i];

                // stable id for reason map
                final miscid = (plan.accode.isNotEmpty ? plan.accode : '${plan.partyName}||${plan.custAddress}');

                return _CustomerCard(
                  title: formatTitleCase(plan.partyName),
                  address: formatTitleCase(plan.custAddress),
                  crLimit: plan.crLimit,
                  crDays: plan.crDays,
                  area: plan.areaName,
                  seg: plan.segement,
                  reason: _reasonsByMiscId[miscid],
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderMenuScreen(
                          miscid: miscid,
                          shopname: plan.partyName,
                          address: plan.custAddress.toString(),
                        ),
                      ),
                    );

                    if (result is Map &&
                        result['miscid'] == miscid &&
                        result['reason'] != null &&
                        (result['reason'] as String).trim().isNotEmpty) {
                      setState(() {
                        _reasonsByMiscId[miscid] = result['reason'] as String;
                      });
                      await box.write('journey_reasons', _reasonsByMiscId);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── widgets ───────────────────────────────────────────────────────────────────
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

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.45)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }
}

class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: kOrange,
      labelStyle: TextStyle(color: selected ? Colors.white : kText, fontWeight: FontWeight.w600),
      backgroundColor: Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? Colors.transparent : const Color(0xFFEDEFF2)),
      ),
      elevation: selected ? 2 : 0,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.title,
    required this.address,
    required this.crLimit,
    required this.crDays,
    required this.area,
    required this.seg,
    required this.onTap,
    this.reason,
  });

  final String title;
  final String address;
  final String crLimit;
  final String crDays;
  final String area;
  final String seg;
  final VoidCallback onTap;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset('assets/shop_orderscreen.png', height: 30, width: 30),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleMedium?.copyWith(color: kText, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Image.asset('assets/location.png', height: 30, width: 30),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium?.copyWith(color: kText, fontWeight: FontWeight.w300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  // _TagPill(text: "Credit Limit $crLimit"),
                  // _TagPill(text: "Credit Days $crDays"),
                  // if (area.trim().isNotEmpty) _TagPill(text: area),
                  // if (seg.trim().isNotEmpty) _TagPill(text: seg),
                  if (reason != null && reason!.trim().isNotEmpty) _TagPill(text: "Reason: ${reason!}"),
                ],
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
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kOrange.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kOrange.withOpacity(.25)),
      ),
      child: Text(text, style: t.bodySmall?.copyWith(color: kText, fontWeight: FontWeight.w500)),
    );
  }
}

*/

// class JourneyPlanScreen extends StatefulWidget {
//   const JourneyPlanScreen({super.key});

//   @override
//   State<JourneyPlanScreen> createState() => _JourneyPlanScreenState();
// }

// class _JourneyPlanScreenState extends State<JourneyPlanScreen> {
//   final _search = TextEditingController();
//   String? _selectedAddress;

//   @override
//   void dispose() {
//     _search.dispose();
//     super.dispose();
//   }

//   String formatTitleCase(String text) {
//     if (text.isEmpty) return text;
//     return text
//         .toLowerCase()
//         .split(' ')
//         .map(
//             (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
//         .join(' ');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     final journeyPlans =
//         context.read<GlobalBloc>().state.loginModel?.journeyPlan ?? const [];

//     final addressCounts = <String, int>{};
//     for (final plan in journeyPlans) {
//       final addr = (plan.custAddress).trim();
//       if (addr.isNotEmpty) {
//         addressCounts[addr] = (addressCounts[addr] ?? 0) + 1;
//       }
//     }

//     final q = _search.text.trim().toLowerCase();
//     final filteredPlans = journeyPlans.where((plan) {
//       final matchesSearch = plan.partyName.toLowerCase().contains(q);
//       final matchesChip =
//           _selectedAddress == null || plan.custAddress == _selectedAddress;
//       return matchesSearch && matchesChip;
//     }).toList();

//     return Scaffold(
//       backgroundColor: Colors.white,
//       // appBar: AppBar(
//       //   elevation: 0,
//       //   scrolledUnderElevation: 0,
//       //   backgroundColor: Colors.white,
//       //   title: Text('Customers',
//       //       style: t.titleLarge
//       //           ?.copyWith(color: kText, fontWeight: FontWeight.w700)),
//       //   centerTitle: false,
//       // ),
//       body: Column(
//         children: [
//           // hero header with frosted info
//           Stack(
//             children: [
//               Container(
//                 height: 166,
//                 decoration: const BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [kOrange, Color(0xFFFFB07A)],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16,42, 16, 0),
//                 child: _GlassHeader(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(children: [
//                         Container(
//                           width: 44,
//                           height: 44,
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(.22),
//                             shape: BoxShape.circle,
//                             border: Border.all(color: Colors.white, width: 1.2),
//                           ),
//                           child: const Icon(Icons.route_rounded,
//                               color: Colors.white, size: 22),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text('Journey Plan',
//                                   style: t.titleMedium?.copyWith(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w700,
//                                   )),
//                               const SizedBox(height: 2),
//                               Text(
//                                 '${journeyPlans.length} total customers',
//                                 style: t.bodySmall?.copyWith(
//                                   color: Colors.white.withOpacity(.95),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ]),
//                       const SizedBox(height: 10),
//                       Row(
//                         children: [
//                           _HeaderChip(
//                             icon: Icons.checklist_outlined,
//                             label: 'Filtered: ${filteredPlans.length}',
//                           ),
//                           const SizedBox(width: 8),
//                           _HeaderChip(
//                             icon: Icons.place_outlined,
//                             label: _selectedAddress == null
//                                 ? 'All Areas'
//                                 : (_selectedAddress!.length > 24
//                                     ? '${_selectedAddress!.substring(0, 24)}…'
//                                     : _selectedAddress!),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           // search
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: kCard,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: const [
//                   BoxShadow(
//                       color: kShadow, blurRadius: 12, offset: Offset(0, 6))
//                 ],
//                 border: Border.all(color: const Color(0xFFEDEFF2)),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Row(
//                 children: [
//                   Icon(Icons.search_rounded, color: kMuted.withOpacity(.9)),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: TextField(
//                       controller: _search,
//                       onChanged: (_) => setState(() {}),
//                       decoration: const InputDecoration(
//                         hintText: 'Search Customer Shops',
//                         hintStyle: TextStyle(color: kMuted),
//                         border: InputBorder.none,
//                       ),
//                     ),
//                   ),
//                   if (_search.text.isNotEmpty)
//                     IconButton(
//                       icon: const Icon(Icons.close_rounded, color: kMuted),
//                       onPressed: () {
//                         _search.clear();
//                         setState(() {});
//                       },
//                     ),
//                 ],
//               ),
//             ),
//           ),

//           // address filter chips (like above)
//           if (addressCounts.isNotEmpty) ...[
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text('Filter Routes by Area',
//                     style: t.titleMedium?.copyWith(
//                       fontWeight: FontWeight.w600,
//                       color: kText,
//                     )),
//               ),
//             ),
//             SizedBox(
//               height: 56,
//               child: ListView(
//                 padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
//                 scrollDirection: Axis.horizontal,
//                 children: [
//                   _FilterChoiceChip(
//                     label: 'All',
//                     selected: _selectedAddress == null,
//                     onSelected: () => setState(() => _selectedAddress = null),
//                   ),
//                   const SizedBox(width: 8),
//                   ...addressCounts.entries.map((e) {
//                     final addr = e.key;
//                     final count = e.value;
//                     final selected = _selectedAddress == addr;
//                     return Padding(
//                       padding: const EdgeInsets.only(right: 8),
//                       child: _FilterChoiceChip(
//                         label: '$addr ($count)',
//                         selected: selected,
//                         onSelected: () => setState(
//                             () => _selectedAddress = selected ? null : addr),
//                       ),
//                     );
//                   }),
//                 ],
//               ),
//             ),
//           ],

//           // small count row
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
//             child: Row(
//               children: [
//                 Text('${filteredPlans.length} Customers',
//                     style: t.bodySmall?.copyWith(color: kMuted)),
//                 const Spacer(),
//                 if (_selectedAddress != null)
//                   TextButton.icon(
//                     style: TextButton.styleFrom(foregroundColor: kOrange),
//                     onPressed: () => setState(() => _selectedAddress = null),
//                     icon: const Icon(Icons.clear_rounded, size: 18),
//                     label: const Text('Clear'),
//                   ),
//               ],
//             ),
//           ),

//           // list
//           Expanded(
//             child: ListView.separated(
//               padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
//               itemCount: filteredPlans.length,
//               separatorBuilder: (_, __) => const SizedBox(height: 12),
//               itemBuilder: (_, i) {
//                 final plan = filteredPlans[i];
//                 return _CustomerCard(
//                   title: formatTitleCase(plan.partyName),
//                   address: formatTitleCase(plan.custAddress),
//                   crLimit: plan.crLimit,
//                   crDays: plan.crDays,
//                   area: plan.areaName,
//                   seg: plan.segement,
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => OrderMenuScreen(
//                           miscid: '',
//                           shopname: plan.partyName,
//                           address: plan.custAddress.toString(),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


// class _GlassHeader extends StatelessWidget {
//   const _GlassHeader({required this.child});
//   final Widget child;
//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(18),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(.18),
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }
// }

// class _HeaderChip extends StatelessWidget {
//   const _HeaderChip({required this.icon, required this.label});
//   final IconData icon;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(.18),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: Colors.white.withOpacity(.45)),
//       ),
//       child: Row(mainAxisSize: MainAxisSize.min, children: [
//         Icon(icon, size: 16, color: Colors.white),
//         const SizedBox(width: 6),
//         Text(label,
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w700,
//               fontSize: 12,
//             )),
//       ]),
//     );
//   }
// }

// class _FilterChoiceChip extends StatelessWidget {
//   const _FilterChoiceChip({
//     required this.label,
//     required this.selected,
//     required this.onSelected,
//   });
//   final String label;
//   final bool selected;
//   final VoidCallback onSelected;

//   @override
//   Widget build(BuildContext context) {
//     return ChoiceChip(
//       label: Text(
//         label,
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//       ),
//       selected: selected,
//       onSelected: (_) => onSelected(),
//       selectedColor: kOrange,
//       labelStyle: TextStyle(
//         color: selected ? Colors.white : kText,
//         fontWeight: FontWeight.w600,
//       ),
//       backgroundColor: Colors.white,
//       shape: StadiumBorder(
//         side: BorderSide(
//           color: selected ? Colors.transparent : const Color(0xFFEDEFF2),
//         ),
//       ),
//       elevation: selected ? 2 : 0,
//       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//     );
//   }
// }

// class _CustomerCard extends StatelessWidget {
//   const _CustomerCard({
//     required this.title,
//     required this.address,
//     required this.crLimit,
//     required this.crDays,
//     required this.area,
//     required this.seg,
//     required this.onTap,
//   });

//   final String title;
//   final String address;
//   final String crLimit;
//   final String crDays;
//   final String area;
//   final String seg;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return InkWell(
//       borderRadius: BorderRadius.circular(16),
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: [kOrange, Color(0xFFFFB07A)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Container(
//           margin: const EdgeInsets.all(1.6),
//           decoration: BoxDecoration(
//             color: kCard,
//             borderRadius: BorderRadius.circular(14.4),
//             boxShadow: const [
//               BoxShadow(color: kShadow, blurRadius: 14, offset: Offset(0, 8))
//             ],
//           ),
//           padding: const EdgeInsets.all(14),
//           child:Column(
//             children: [
//                                               Row(
//                                   children: [
//                                     Image.asset(
//                                       'assets/shop_orderscreen.png',
//                                       height: 30,
//                                       width: 30,
//                                     ),
//                                     const SizedBox(width: 4),
//                                     Text(
//                                       formatTitleCase(title),
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: t.titleMedium?.copyWith(
//                                         color: kText,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 5),
//                                 Row(
//                                   children: [
//                                     Image.asset(
//                                       'assets/location.png',
//                                       height: 30,
//                                       width: 30,
//                                     ),
//                                     const SizedBox(width: 4),
//                                     Text(
//                                       formatTitleCase(address),
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: t.bodyMedium?.copyWith(
//                                         color: kText,
//                                         fontWeight: FontWeight.w300,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 5),
//                                 Row(
//                                   children: [
//                                     Image.asset(
//                                       'assets/money.png',
//                                       height: 30,
//                                       width: 30,
//                                     ),
//                                     SizedBox(width: 5),
//                                     _TagPill(
//                                       text: "Credit Limit ${crLimit}",
//                                     ),
//                                     const SizedBox(width: 6),
//                                     _TagPill(
//                                       text: "Credit Days ${crDays}",
//                                     ),
//                                   ],
//                                 ),
//             ],
//           ),
          
//        /*    Row(
//             children: [
//               // avatar
//               // Container(
//               //   width: 52,
//               //   height: 52,
//               //   decoration: BoxDecoration(
//               //       color: kField, borderRadius: BorderRadius.circular(14)),
//               //   child: const Icon(Icons.storefront_rounded, color: kOrange),
//               // ),
//               // const SizedBox(width: 12),
//               // content
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: t.bodyLarge?.copyWith(
//                         color: kText,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     // address
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.place_rounded,
//                             size: 16, color: kMuted),
//                         const SizedBox(width: 4),
//                         Expanded(
//                           child: Text(
//                             address,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: t.bodySmall?.copyWith(color: kMuted),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Wrap(
//                       spacing: 6,
//                       runSpacing: 6,
//                       children: [
//                         _TagPill(text: 'Credit Limit $crLimit'),
//                         _TagPill(text: 'Credit Days $crDays'),
//                         if (area.trim().isNotEmpty) _TagPill(text: area),
//                         if (seg.trim().isNotEmpty) _TagPill(text: seg),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 8),
//               const Icon(Icons.chevron_right_rounded, color: kMuted),
//             ],
//           ),*/
//         ),
//       ),
//     );
//   }
// }

// class _TagPill extends StatelessWidget {
//   const _TagPill({required this.text});
//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: kOrange.withOpacity(.10),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: kOrange.withOpacity(.25)),
//       ),
//       child: Text(
//         text,
//         style: t.bodySmall?.copyWith(color: kText, fontWeight: FontWeight.w500),
//       ),
//     );
//   }
// }


// const kOrange = Color(0xFFEA7A3B);
// const kText = Color(0xFF1E1E1E);
// const kMuted = Color(0xFF707883);
// const kField = Color(0xFFF2F3F5);
// const kCard = Colors.white;
// const kShadow = Color(0x14000000);

// class JourneyPlanScreen extends StatefulWidget {
//   const JourneyPlanScreen({super.key});

//   @override
//   State<JourneyPlanScreen> createState() => _JourneyPlanScreenState();
// }

// class _JourneyPlanScreenState extends State<JourneyPlanScreen> {
//   final _search = TextEditingController();
//   String? _selectedAddress; 

//   @override
//   void dispose() {
//     _search.dispose();
//     super.dispose();
//   }

  String formatTitleCase(String text) {
    if (text.isEmpty) return text;

    return text
        .toLowerCase()
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     final journeyPlans = context
//         .read<GlobalBloc>()
//         .state
//         .loginModel!
//         .journeyPlan;

//     final addressCounts = <String, int>{};
//     for (var plan in journeyPlans) {
//       final addr = plan.custAddress.trim();
//       if (addr.isNotEmpty) {
//         addressCounts[addr] = (addressCounts[addr] ?? 0) + 1;
//       }
//     }

//     final filteredPlans = journeyPlans.where((plan) {
//       final matchesSearch = plan.partyName.toLowerCase().contains(
//         _search.text.toLowerCase(),
//       );

//       final matchesChip =
//           _selectedAddress == null || plan.custAddress == _selectedAddress;

//       return matchesSearch && matchesChip;
//     }).toList();

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         centerTitle: false,
//         title: Text(
//           'Customers',
//           style: t.titleLarge?.copyWith(
//             color: kText,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//       body: Column(
//         children: [

//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: kCard,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: const [
//                   BoxShadow(
//                     color: kShadow,
//                     blurRadius: 12,
//                     offset: Offset(0, 6),
//                   ),
//                 ],
//                 border: Border.all(color: Color(0xFFEDEFF2)),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Row(
//                 children: [
//                   Icon(Icons.search_rounded, color: kMuted.withOpacity(.9)),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: TextField(
//                       controller: _search,
//                       onChanged: (_) => setState(() {}),
//                       decoration: const InputDecoration(
//                         hintText: 'Search Customer Shops',
//                         hintStyle: TextStyle(color: kMuted),
//                         border: InputBorder.none,
//                       ),
//                     ),
//                   ),
//                   if (_search.text.isNotEmpty)
//                     IconButton(
//                       onPressed: () {
//                         _search.clear();
//                         setState(() {});
//                       },
//                       icon: const Icon(Icons.close_rounded, color: kMuted),
//                     ),
//                 ],
//               ),
//             ),
//           ),

//           if (addressCounts.isNotEmpty) ...[
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   "Filter Routes by Area",
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.w600,
//                     color: kText,
//                   ),
//                 ),
//               ),
//             ),
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: Row(
//                 children: addressCounts.entries.map((entry) {
//                   final addr = entry.key;
//                   final count = entry.value;
//                   final selected = _selectedAddress == addr;
//                   return Padding(
//                     padding: const EdgeInsets.only(right: 8),
//                     child: ChoiceChip(
//                       label: Text("$addr ($count)"),
//                       selected: selected,
//                       selectedColor: kOrange.withOpacity(0.2),
//                       onSelected: (val) {
//                         setState(() {
//                           _selectedAddress = val ? addr : null;
//                         });
//                       },
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ],

//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
//             child: Row(
//               children: [
//                 Text(
//                   '${filteredPlans.length} Customers',
//                   style: t.bodySmall?.copyWith(color: kMuted),
//                 ),
//               ],
//             ),
//           ),

//           Expanded(
//             child: ListView.separated(
//               padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
//               itemBuilder: (_, i) {
//                 final plan = filteredPlans[i];
//                 return InkWell(
//                   borderRadius: BorderRadius.circular(16),
//                   onTap: () {
//                   Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => OrderMenuScreen(miscid: '',shopname: plan.partyName,address:plan.custAddress.toString()),
//                           ),
//                         );
//                   },
//                   child: Container(
//                     decoration: BoxDecoration(
//                       gradient: const LinearGradient(
//                         colors: [kOrange, Color(0xFFFFB07A)],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Container(
//                       margin: const EdgeInsets.all(1.6),
//                       decoration: BoxDecoration(
//                         color: kCard,
//                         borderRadius: BorderRadius.circular(14.4),
//                         boxShadow: const [
//                           BoxShadow(
//                             color: kShadow,
//                             blurRadius: 14,
//                             offset: Offset(0, 8),
//                           ),
//                         ],
//                       ),
//                       padding: const EdgeInsets.all(14),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Image.asset(
//                                       'assets/shop_orderscreen.png',
//                                       height: 30,
//                                       width: 30,
//                                     ),
//                                     const SizedBox(width: 4),
//                                     Text(
//                                       formatTitleCase(plan.partyName),
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: t.titleMedium?.copyWith(
//                                         color: kText,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 5),
//                                 Row(
//                                   children: [
//                                     Image.asset(
//                                       'assets/location.png',
//                                       height: 30,
//                                       width: 30,
//                                     ),
//                                     const SizedBox(width: 4),
//                                     Text(
//                                       formatTitleCase(plan.custAddress),
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: t.bodyMedium?.copyWith(
//                                         color: kText,
//                                         fontWeight: FontWeight.w300,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 5),
//                                 Row(
//                                   children: [
//                                     Image.asset(
//                                       'assets/money.png',
//                                       height: 30,
//                                       width: 30,
//                                     ),
//                                     SizedBox(width: 5),
//                                     _TagPill(
//                                       text: "Credit Limit ${plan.crLimit}",
//                                     ),
//                                     const SizedBox(width: 6),
//                                     _TagPill(
//                                       text: "Credit Days ${plan.crDays}",
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//               separatorBuilder: (_, __) => const SizedBox(height: 12),
//               itemCount: filteredPlans.length,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _TagPill extends StatelessWidget {
//   const _TagPill({required this.text});
//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: kOrange.withOpacity(.10),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: kOrange.withOpacity(.25)),
//       ),
//       child: Text(
//         text,
//         style: t.bodySmall?.copyWith(color: kText, fontWeight: FontWeight.w300),
//       ),
//     );
//   }
// }
