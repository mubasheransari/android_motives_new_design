import 'package:flutter/material.dart';
import 'package:motives_new_ui_conversion/Models/order_storage.dart';

const _kMuted = Color(0xFF707883);
const _kShadow = Color(0x14000000);

class RecordDetailScreen extends StatelessWidget {
  final OrderRecord record;
  const RecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lines = (record.payload['order'] as List?)?.cast<Map>() ?? const <Map>[];
    return Scaffold(
      appBar: AppBar(title: Text('Order ${record.id.substring(0, 8)}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: _kShadow, blurRadius: 10, offset: Offset(0,6))],
              border: Border.all(color: const Color(0xFFEDEFF2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Summary', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _kv('Unique', record.id),
                _kv('Status', record.status),
                _kv('User ID', record.userId),
                _kv('Distributor ID', record.distId),
                _kv('Date (payload)', record.payload['date']?.toString() ?? ''),
                _kv('HTTP', record.httpStatus.toString()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Items', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...lines.map((m) {
            final mm = m.cast<String, dynamic>();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEDEFF2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F3F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_mall_outlined),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Item ${mm['item_id'] ?? ''}', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          'SKU: ${mm['item_qty_sku']}  •  CTN: ${mm['item_qty_ctn']}  •  Total: ${mm['item_total_qty']}',
                          style: t.bodySmall?.copyWith(color: _kMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(width: 130, child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.w600))),
        Expanded(child: Text(v)),
      ],
    ),
  );
}
