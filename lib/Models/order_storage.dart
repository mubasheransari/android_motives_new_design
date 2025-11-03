import 'dart:convert';
import 'package:get_storage/get_storage.dart';


// storage/orders_storage.dart
import 'dart:convert';
import 'package:get_storage/get_storage.dart';

class OrderRecord {
  final String id;                 // payload.unique
  final String userId;
  final String distId;
  final String dateStr;            // payload.date "dd-mon-yy"
  final String status;             // "Success" | "Queued (Offline)"
  final Map<String, dynamic> payload; // <- enriched with _client_* fields
  final int httpStatus;            // 0 when queued/offline
  final String? serverBody;        // may be null when queued
  final DateTime createdAt;

  OrderRecord({
    required this.id,
    required this.userId,
    required this.distId,
    required this.dateStr,
    required this.status,
    required this.payload,
    required this.httpStatus,
    this.serverBody,
    required this.createdAt,
  });

  // Convenience getters for Records UI
  String? get partyName =>
      (payload['_client_shop_name'] ?? payload['party_name'])?.toString();

  List<Map<String, dynamic>> get lines =>
      ((payload['order'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();

  Map<String, dynamic> toJson() => {
        "id": id,
        "userId": userId,
        "distId": distId,
        "dateStr": dateStr,
        "status": status,
        "payload": payload,
        "httpStatus": httpStatus,
        "serverBody": serverBody,
        "createdAt": createdAt.toIso8601String(),
      };

  static OrderRecord fromJson(Map<String, dynamic> j) => OrderRecord(
        id: j["id"]?.toString() ?? "",
        userId: j["userId"]?.toString() ?? "",
        distId: j["distId"]?.toString() ?? "",
        dateStr: j["dateStr"]?.toString() ?? "",
        status: j["status"]?.toString() ?? "Success",
        payload: (j["payload"] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
        httpStatus: (j["httpStatus"] as num?)?.toInt() ?? 200,
        serverBody: j["serverBody"]?.toString(),
        createdAt: DateTime.tryParse(j["createdAt"]?.toString() ?? "") ??
            DateTime.now(),
      );
}

class OrdersStorage {
  final _box = GetStorage();
  String _key(String userId) => 'orders_$userId';

  Future<void> addOrder(String userId, OrderRecord record) async {
    final list = await listOrders(userId);
    list.removeWhere((e) => e.id == record.id);
    list.insert(0, record);
    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await _box.write(_key(userId), encoded);
  }

  Future<List<OrderRecord>> listOrders(String userId) async {
    final raw = _box.read(_key(userId));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => OrderRecord.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clear(String userId) => _box.remove(_key(userId));
}


// class OrderRecord {
//   final String id;                 // payload.unique
//   final String userId;
//   final String distId;
//   final String dateStr;            // payload.date "dd-mon-yy"
//   final String status;             // "Success"
//   final Map<String, dynamic> payload;
//   final int httpStatus;
//   final String? serverBody;
//   final DateTime createdAt;

//   OrderRecord({
//     required this.id,
//     required this.userId,
//     required this.distId,
//     required this.dateStr,
//     required this.status,
//     required this.payload,
//     required this.httpStatus,
//     this.serverBody,
//     required this.createdAt,
//   });

//   Map<String, dynamic> toJson() => {
//     "id": id,
//     "userId": userId,
//     "distId": distId,
//     "dateStr": dateStr,
//     "status": status,
//     "payload": payload,
//     "httpStatus": httpStatus,
//     "serverBody": serverBody,
//     "createdAt": createdAt.toIso8601String(),
//   };

//   static OrderRecord fromJson(Map<String, dynamic> j) => OrderRecord(
//     id: j["id"] ?? "",
//     userId: j["userId"] ?? "",
//     distId: j["distId"] ?? "",
//     dateStr: j["dateStr"] ?? "",
//     status: j["status"] ?? "Success",
//     payload: (j["payload"] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
//     httpStatus: j["httpStatus"] ?? 200,
//     serverBody: j["serverBody"],
//     createdAt: DateTime.tryParse(j["createdAt"] ?? "") ?? DateTime.now(),
//   );
// }

// class OrdersStorage {
//   final _box = GetStorage();
//   String _key(String userId) => 'orders_$userId';

//   /// Append a successful order
//   Future<void> addOrder(String userId, OrderRecord record) async {
//     final list = await listOrders(userId);
//     list.removeWhere((e) => e.id == record.id);
//     list.insert(0, record);
//     final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
//     await _box.write(_key(userId), encoded);
//   }

//   Future<List<OrderRecord>> listOrders(String userId) async {
//     final raw = _box.read(_key(userId));
//     if (raw == null) return [];
//     try {
//       final decoded = jsonDecode(raw);
//       if (decoded is! List) return [];
//       return decoded
//           .whereType<Map>()
//           .map((e) => OrderRecord.fromJson(e.cast<String, dynamic>()))
//           .toList();
//     } catch (_) {
//       return [];
//     }
//   }

//   Future<void> clear(String userId) => _box.remove(_key(userId));
// }
