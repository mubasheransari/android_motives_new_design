import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motives_new_ui_conversion/Models/order_storage.dart';



const kOrange = Color(0xFFEA7A3B);
const kText   = Color(0xFF1E1E1E);
const kMuted  = Color(0xFF707883);
const kField  = Color(0xFFF2F3F5);
const kCard   = Colors.white;
const kShadow = Color(0x14000000);

class RecordDetailScreen extends StatelessWidget {
  final OrderRecord record;
  const RecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final payload = Map<String, dynamic>.from(record.payload);
    final unique     = (payload['unique'] ?? '').toString();
    final userId     = (payload['user_id'] ?? '').toString();
    final dateStr    = (payload['date'] ?? '').toString();
    final accCode    = (payload['acc_code'] ?? '').toString();
    final segmentId  = (payload['segment_id'] ?? '').toString();
    final compId     = (payload['compid'] ?? '').toString();
    final obId       = (payload['order_booker_id'] ?? '').toString();
    final payment    = (payload['payment_type'] ?? '').toString();
    final hdrType    = (payload['order_type'] ?? '').toString();   // "OR"
    final statusHdr  = (payload['order_status'] ?? '').toString(); // "N"
    final distId     = (payload['dist_id'] ?? '').toString();

    final created = DateFormat('dd MMM yyyy, hh:mm a').format(record.createdAt);

    // Lines: ensure strong typing
    final List<Map<String, dynamic>> lines = ((payload['order'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // Totals
    final totalQty = _sumQty(lines, 'item_total_qty');
    final linesCount = lines.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: kText),
        title: Text('Order Details',
          style: t.titleLarge?.copyWith(color: kText, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
        /*  _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title('Summary', t),
                const SizedBox(height: 8),
                _kv('Unique', unique),
                _kv('Status', record.status),
                _kv('User ID', record.userId),
                _kv('Distributor ID', record.distId),
                _kv('Date (payload)', dateStr),
                _kv('Submitted (local)', created),
                _kv('HTTP', record.httpStatus.toString()),
                if ((record.serverBody)!.trim().isNotEmpty)
                  _kv('Response Size', '${record.serverBody!.length} bytes'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Header fields card
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title('Header Fields', t),
                const SizedBox(height: 8),
                _kv('user_id', userId),
                _kv('acc_code', accCode),
                _kv('segment_id', segmentId),
                _kv('compid', compId),
                _kv('order_booker_id', obId),
                _kv('payment_type', payment),
                _kv('order_type', hdrType),
                _kv('order_status', statusHdr),
                _kv('dist_id', distId),
                const Divider(height: 18),
                _kv('Lines', '$linesCount'),
                _kv('Total Qty', _trimQty(totalQty)),
              ],
            ),
          ),

          const SizedBox(height: 14),*/

          // Items list
          Text('Items', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: kText)),
          const SizedBox(height: 8),
          if (lines.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEDEFF2)),
              ),
              child: Text('No lines found', style: t.bodyMedium?.copyWith(color: kMuted)),
            )
          else
            ...lines.map((m) => _LineRow(t: t, line: m)),

        /*  const SizedBox(height: 14),

          // Raw response (optional)
          if (record.serverBody
          !.trim().isNotEmpty)
            _Card(
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Raw Response', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: kText)),
                childrenPadding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kField,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _prettyJsonOrRaw(record.serverBody.toString()),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: kText),
                    ),
                  ),
                ],
              ),
            ),*/

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static String _shortId(String id) => id.isEmpty ? '—' : (id.length <= 8 ? id : id.substring(0, 8));

  static double _sumQty(List<Map<String, dynamic>> lines, String key) {
    var sum = 0.0;
    for (final m in lines) {
      final v = m[key];
      if (v != null) {
        sum += double.tryParse(v.toString()) ?? 0.0;
      }
    }
    return sum;
  }

  static String _trimQty(double q) {
    final s = q.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  static String _prettyJsonOrRaw(String body) {
    try {
      final decoded = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return body;
    }
  }
}

// ============ UI helpers ============

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: kShadow, blurRadius: 10, offset: Offset(0, 6))],
        border: Border.all(color: const Color(0xFFEDEFF2)),
      ),
      child: child,
    );
  }
}

Widget _title(String text, TextTheme t) => Text(
  text,
  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: kText),
);

Widget _kv(String k, String v) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 2.5),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 150,
        child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.w600, color: kText)),
      ),
      const SizedBox(width: 6),
      Expanded(child: Text(v.isEmpty ? '—' : v, style: const TextStyle(color: kText))),
    ],
  ),
);

class _LineRow extends StatelessWidget {
  final TextTheme t;
  final Map<String, dynamic> line;
  const _LineRow({required this.t, required this.line});

  @override
  Widget build(BuildContext context) {
    final id   = (line['item_id'] ?? '').toString();
    final sku  = (line['item_qty_sku'] ?? '').toString();
    final ctn  = (line['item_qty_ctn'] ?? '').toString();
    final tot  = (line['item_total_qty'] ?? '').toString();
    final ltyp = (line['order_type'] ?? '').toString(); // "or"

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEFF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kField,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_mall_outlined, color: kOrange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Item $id',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: kText)),
                const SizedBox(height: 2),
                Text('Type: $ltyp  •  SKU: $sku  •  CTN: $ctn  •  Total: $tot',
                    style: t.bodySmall?.copyWith(color: kMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
