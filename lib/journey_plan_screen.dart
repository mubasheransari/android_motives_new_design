import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motives_new_ui_conversion/Bloc/global_bloc.dart';

const kOrange = Color(0xFFEA7A3B);
const kText   = Color(0xFF1E1E1E);
const kMuted  = Color(0xFF707883);
const kField  = Color(0xFFF2F3F5);
const kCard   = Colors.white;
const kShadow = Color(0x14000000);

class JourneyPlanScreen extends StatefulWidget {
  const JourneyPlanScreen({super.key});

  @override
  State<JourneyPlanScreen> createState() => _JourneyPlanScreenState();
}

class _JourneyPlanScreenState extends State<JourneyPlanScreen> {
  final _search = TextEditingController();



  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    String formatTitleCase(String text) {
  if (text.isEmpty) return text;

  return text
      .toLowerCase()
      .split(' ') 
      .map((word) => word.isNotEmpty
          ? '${word[0].toUpperCase()}${word.substring(1)}'
          : '')
      .join(' ');
}


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Text('Customers', style: t.titleLarge?.copyWith(color: kText, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
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
                        hintText: 'Search Customer Shops',
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

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text('${context.read<GlobalBloc>().state.loginModel
                !.journeyPlan.length} Customers', style: t.bodySmall?.copyWith(color: kMuted)),
              ],
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding:  EdgeInsets.fromLTRB(16, 6, 16, 16),
              itemBuilder: (_, i) =>
      

              
              InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
       
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
       
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   
             Row(
               children: [
               Image.asset('assets/shop_orderscreen.png',height: 30,width: 30,),
                SizedBox(width: 4,),
                  Text(
                    formatTitleCase(context.read<GlobalBloc>().state.loginModel
                                          !.journeyPlan[i].partyName),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.titleMedium?.copyWith(
                                      color: kText, fontWeight: FontWeight.w600,
                                    ),
                                  ),
               ],
             ),
             SizedBox(height: 5,),

                 Row(
               children: [
               Image.asset('assets/location.png',height: 30,width: 30,),
                SizedBox(width: 4,),
                         Text(
                    formatTitleCase(context.read<GlobalBloc>().state.loginModel
                                          !.journeyPlan[i].custAddress),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.bodyMedium?.copyWith(
                                      color: kText, fontWeight: FontWeight.w300,
                                    ),
                                  ),
               ],
             ),
             SizedBox(height: 5,),
                  
                                  Row(
                      children: [
                        _TagPill(text: "Credit Limit ${context.read<GlobalBloc>().state.loginModel
                                        !.journeyPlan[i].crLimit}"),
                        const SizedBox(width: 6),
                        _TagPill(text:"Credit Days ${context.read<GlobalBloc>().state.loginModel
                                        !.journeyPlan[i].crDays}"),
                      ],
                    ),
                  
                  
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: context.read<GlobalBloc>().state.loginModel
                !.journeyPlan.length,
            ),
          ),
        ],
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


