// utils/order_meta.dart
import 'dart:math';

String generateUuidV4() {
  final r = Random.secure();
  String h(int n) => n.toRadixString(16).padLeft(2, '0');
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // v4
  b[8] = (b[8] & 0x3f) | 0x80; // variant
  return '${h(b[0])}${h(b[1])}${h(b[2])}${h(b[3])}-'
         '${h(b[4])}${h(b[5])}-'
         '${h(b[6])}${h(b[7])}-'
         '${h(b[8])}${h(b[9])}-'
         '${h(b[10])}${h(b[11])}${h(b[12])}${h(b[13])}${h(b[14])}${h(b[15])}';
}

String formatDdMmmYyLower(DateTime dt) {
  const m = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'];
  final dd = dt.day.toString().padLeft(2, '0');
  final mon = m[dt.month - 1];
  final yy = (dt.year % 100).toString().padLeft(2, '0');
  return '$dd-$mon-$yy';
}

class OrderMeta {
  final String userId;
  final DateTime date;
  final String accCode;
  final String segmentId;
  final String compId;
  final String orderBookerId;
  final String paymentType;  // "CR" or "CS"
  final String orderType;    // "OR"
  final String orderStatus;  // "N"
  final String distId;
  final String? unique;

  const OrderMeta({
    required this.userId,
    required this.date,
    required this.accCode,
    required this.segmentId,
    required this.compId,
    required this.orderBookerId,
    required this.paymentType,
    required this.orderType,
    required this.orderStatus,
    required this.distId,
    this.unique,
  });
}

class SimpleItemRef {
  final String key;
  final String? itemId;
  final String name;
  const SimpleItemRef({required this.key, required this.itemId, required this.name});
}
