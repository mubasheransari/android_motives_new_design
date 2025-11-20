import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '../Models/login_model.dart'; 

const kOrange = Color(0xFFEA7A3B);
const kOrangeLite = Color(0xFFFFB07A);
const kText = Color(0xFF1E1E1E);
const kMuted = Color(0xFF707883);
const kField = Color(0xFFF2F3F5);
const kCard = Colors.white;
const kShadow = Color(0x14000000);

class InactiveJourneyPlanScreen extends StatelessWidget {
  InactiveJourneyPlanScreen({
    super.key,
    required this.allPlans,
    required this.alreadyAddedKeys,
  });

  final List<JourneyPlan> allPlans;
  final List<String> alreadyAddedKeys;

  final box = GetStorage();
  static const _manualAddKey = 'journey_manual_additions';

  String _shopKey(JourneyPlan p) =>
      p.accode.isNotEmpty ? p.accode : '${p.partyName}||${p.custAddress}';

  Future<void> _showThemedConfirm({
    required BuildContext ctx,
    required String title,
    required String message,
    required VoidCallback onYes,
  }) async {
    await showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => _GlassDialog(
        title: title,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: Theme.of(ctx)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: kText),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kMuted,
                        side: BorderSide(color: kMuted.withOpacity(.35)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: const Text('No'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        onYes();
                      },
                      child: const Text('Yes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    // only status == "0" and not already added
    final inactive = allPlans.where((p) {
      final key = _shopKey(p);
      return p.status == "0" && !alreadyAddedKeys.contains(key);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kOrange,
        title: const Text(
          'Inactive / Extra Shops',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: inactive.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final p = inactive[i];
          final key = _shopKey(p);

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              await _showThemedConfirm(
                ctx: context,
                title: 'Add to Journey',
                message:
                    'Do you want to add "${p.partyName}" to your Journey Plan?',
                onYes: () async {
                  final raw = box.read(_manualAddKey);
                  List<String> list;
                  if (raw is List) {
                    list = raw.map((e) => e.toString()).toList();
                  } else {
                    list = [];
                  }
                  if (!list.contains(key)) {
                    list.add(key);
                    await box.write(_manualAddKey, list);
                  }
                  if (context.mounted) Navigator.pop(context, true);
                },
              );
            },
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
                  boxShadow: const [
                    BoxShadow(
                        color: kShadow, blurRadius: 12, offset: Offset(0, 6))
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.partyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleMedium
                          ?.copyWith(color: kText, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded,
                            size: 16, color: kMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            p.custAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall?.copyWith(color: kMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap to add to Journey Plan',
                      style: t.bodySmall?.copyWith(color: kOrange),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// same dialog style as OrderMenuScreen
class _GlassDialog extends StatelessWidget {
  final String title;
  final Widget child;
  const _GlassDialog({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kOrange, kOrangeLite],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Container(
          margin: const EdgeInsets.all(1.8),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: kShadow, blurRadius: 16, offset: Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: const BoxDecoration(
                  color: kField,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Text(title,
                    textAlign: TextAlign.center,
                    style: t.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800, color: kText)),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
