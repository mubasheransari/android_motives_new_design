// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'order_storage.dart';




// class OrderService {
//   final OrdersStorage storage;
//   final http.Client client;
//   final String endpoint;
//   final Map<String, String> defaultHeaders;

//   OrderService({
//     required this.storage,
//     http.Client? client,
//     this.endpoint = 'https://your.api/orders', // TODO: real endpoint
//     Map<String, String>? defaultHeaders,
//   })  : client = client ?? http.Client(),
//         defaultHeaders = {
//           'Content-Type': 'application/json',
//           ...?defaultHeaders,
//         };

//   /// Posts JSON payload. If HTTP 2xx and body either lacks isSuccess
//   /// or isSuccess==true → store as Success.
//   Future<OrderRecord> submitAndSave({
//     required Map<String, dynamic> payload,
//     required String userId,
//     required String distId,
//     Map<String, String>? extraHeaders,
//   }) async {
//     final res = await client.post(
//       Uri.parse(endpoint),
//       headers: {...defaultHeaders, ...?extraHeaders},
//       body: jsonEncode(payload),
//     );

//     bool ok = res.statusCode >= 200 && res.statusCode < 300;
//     try {
//       final body = jsonDecode(res.body);
//       if (body is Map && body.containsKey('isSuccess')) {
//         ok = ok && (body['isSuccess'] == true);
//       }
//     } catch (_) {}

//     if (!ok) {
//       throw Exception('Order submit failed (${res.statusCode}): ${res.body}');
//     }

//     final record = OrderRecord(
//       id: (payload['unique'] ?? '').toString(),
//       userId: userId,
//       distId: distId,
//       dateStr: (payload['date'] ?? '').toString(),
//       status: 'Success',
//       payload: payload,           // <- already enriched with _client_* fields
//       httpStatus: res.statusCode,
//       serverBody: res.body,
//       createdAt: DateTime.now(),
//     );

//     await storage.addOrder(userId, record);
//     return record;
//   }
// }
