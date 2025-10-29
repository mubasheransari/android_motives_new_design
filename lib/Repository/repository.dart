import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:motives_new_ui_conversion/Service/api_basehelper.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Repository {
  // Base endpoints (yours)
  final String baseUrl =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user";
  final String loginUrl =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user/login";
  final String attendanceUrl =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user/attendance";
  final String routeStartUrlZankGroup =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user/routestart";

  Map<String, String> get _formHeaders => const {
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
      };

  /* -------------------------------- Login -------------------------------- */

  Future<http.Response> login(String email, String password) async {
    final now = DateTime.now();
    final currentDate = DateFormat("dd-MMM-yyyy").format(now);
    final currentTime = DateFormat("HH:mm:ss").format(now);

    final payload = {
      "email": email,
      "pass": password,
      "latitude": "0.00",
      "longitude": "0.00",
      "device_id": "e95a9ab3bba86f821",
      "act_type": "LOGIN",
      "action": "IN",
      "att_time": currentTime,
      "att_date": currentDate,
      "misc": "0",
      "dist_id": "0",
      "app_version": "1.0.1",
    };

    final formBody = {"request": jsonEncode(payload)};

    final res = await http
        .post(Uri.parse(loginUrl), headers: _formHeaders, body: formBody)
        .timeout(const Duration(seconds: 30));

    if (res.statusCode == 200) {
      final box = GetStorage();
      box.write("email", email);
      box.write("password", password);
      box.write("email_auth", email);
      box.write("password-auth", password);
      box.write("login_model_json", res.body);
    }

    debugPrint("⬅️ /login ${res.statusCode}: ${res.body}");
    return res;
  }

  /* ------------------------------ Attendance ------------------------------ */

  Future<http.Response> attendance(
    String type,
    String userId,
    String lat,
    String lng,
    String action,
    String distributionId,
  ) async {
    final now = DateTime.now();
    final currentDate = DateFormat("dd-MMM-yyyy").format(now);
    final currentTime = DateFormat("HH:mm:ss").format(now);

    final payload = {
      "type": type,
      "user_id": userId,
      "latitude": lat,
      "longitude": lng,
      "device_id": "e95a9ab3bba86f821",
      "act_type": "ATTENDANCE",
      "action": action,
      "att_time": currentTime,
      "att_date": currentDate,
      "misc": "0",
      "dist_id": distributionId,
      "app_version": "1.0.1",
    };

    final fields = {"request": jsonEncode(payload), "pic": "0"};
    final res = await http
        .post(Uri.parse(attendanceUrl), headers: _formHeaders, body: fields)
        .timeout(const Duration(seconds: 30));

    debugPrint("⬅️ /attendance ${res.statusCode}: ${res.body}");
    return res;
  }

  /* ------------------------------- Route Start ---------------------------- */

  Future<http.Response> startRouteApi(
    String type,
    String userId,
    String lat,
    String lng,
    String action,
    String disid,
  ) async {
    final now = DateTime.now();
    final currentDate = DateFormat("dd-MMM-yyyy").format(now);
    final currentTime = DateFormat("HH:mm:ss").format(now);

    final payload = <String, dynamic>{
      "type": type,
      "user_id": userId,
      "latitude": lat,
      "longitude": lng,
      "device_id": "e95a9ab3bba86f821",
      "act_type": "ROUTE",
      "action": action,
      "att_time": currentTime,
      "att_date": currentDate,
      "misc": "0",
      "dist_id": disid,
      "app_version": "1.0.1",
    };

    final fields = {"request": jsonEncode(payload), "pic": "0"};

    final uri = Uri.parse(routeStartUrlZankGroup);
    final res = await http
        .post(uri, headers: _formHeaders, body: fields)
        .timeout(const Duration(seconds: 30));

    debugPrint("⬅️ /routestart ${res.statusCode}: ${res.body}");
    return res;
  }

  /* -------------------------- Check-in / Checkout ------------------------- */
  /// Uses same PHP form pattern. If your API has a specific URL for this,
  /// change [routeStartUrlZankGroup] to that dedicated endpoint.
  Future<http.Response> checkin_checkout(
    String type,
    String userId,
    String lat,
    String lng,
    String act_type,
    String action,
    String misc,
    String dist_id,
  ) async {
    final now = DateTime.now();
    final currentDate = DateFormat("dd-MMM-yyyy").format(now);
    final currentTime = DateFormat("HH:mm:ss").format(now);

    final payload = {
      "type": type,
      "user_id": userId,
      "latitude": lat,
      "longitude": lng,
      "device_id": "4003dabd04d938c5",
      "act_type": act_type,
      "action": action,
      "att_time": currentTime,
      "att_date": currentDate,
      "misc": misc,
      "dist_id": dist_id,
      "app_version": "1.0.1",
    };

    final fields = {"request": jsonEncode(payload), "pic": "0"};

    final res = await http
        .post(Uri.parse(routeStartUrlZankGroup), headers: _formHeaders, body: fields)
        .timeout(const Duration(seconds: 30));

    debugPrint("⬅️ /checkin_checkout via routestart ${res.statusCode}: ${res.body}");
    return res;
  }
}



// class Repository {
//   // Base URLs
//   // http://services.zankgroup.com/motivesteang/index.php?route=api/user/
//   final String baseUrl =
//       "http://services.zankgroup.com/motivesteang/index.php?route=api/user";

//   final String loginUrl =
//       "http://services.zankgroup.com/motivesteang/index.php?route=api/user/login";

//   final String attendanceUrl =
//       "http://services.zankgroup.com/motivesteang/index.php?route=api/user/attendance";

//   final String routeStartUrlZankGroup =
//       "http://services.zankgroup.com/motivesteang/index.php?route=api/user/routestart";

//   // Keep _formHeaders minimal; each call sets its own Content-Type
//   Map<String, String> get _formHeaders => const {
//         "Accept": "application/json",
//       };

//   Future<http.Response> login(String email, String password) async {
//     final now = DateTime.now();
//     final currentDate = DateFormat("dd-MMM-yyyy").format(now); // e.g. 29-Oct-2025
//     final currentTime = DateFormat("HH:mm:ss").format(now);    // e.g. 01:52:10

//     final payload = {
//       "email": email,
//       "pass": password,
//       "latitude": "0.00",
//       "longitude": "0.00",
//       "device_id": "e95a9ab3bba86f821", // put your real device id here
//       "act_type": "LOGIN",
//       "action": "IN",
//       "att_time": currentTime,
//       "att_date": currentDate,
//       "misc": "0",
//       "dist_id": "0",
//       "app_version": "1.0.1",
//     };

//     // Form body: request=<JSON string>
//     final formBody = {
//       "request": jsonEncode(payload),
//     };

//     final uri = Uri.parse(loginUrl);

//     final headers = <String, String>{
//       ..._formHeaders,
//       "Content-Type": "application/x-www-form-urlencoded",
//     };

//     debugPrint("➡️ /login headers: $headers");
//     debugPrint("➡️ /login body (form): $formBody");

//     final res = await http
//         .post(uri, headers: headers, body: formBody)
//         .timeout(const Duration(seconds: 30));

//     debugPrint("⬅️ /login ${res.statusCode}: ${res.body}");

//     if (res.statusCode == 200) {
//       final box = GetStorage();
//       box.write("email", email);
//       box.write("password", password);
//       box.write("email_auth", email);
//       box.write("password-auth", password);
//       box.write("login_model_json", res.body);
//     }

//     return res;
//   }

//   Future<http.Response> attendance(
//     String type,
//     String userId,
//     String lat,
//     String lng,
//     String action,
//     String distributionId,
//   ) async {
//     final now = DateTime.now();
//     final currentDate = DateFormat("dd-MMM-yyyy").format(now); // e.g., 29-Oct-2025
//     final currentTime = DateFormat("HH:mm:ss").format(now);    // e.g., 02:07:12

//     final payload = {
//       "type": type,
//       "user_id": userId,
//       "latitude": lat,
//       "longitude": lng,
//       "device_id": "e95a9ab3bba86f821", // keep your device id source as needed
//       "act_type": "ATTENDANCE",
//       "action": action,
//       "att_time": currentTime,
//       "att_date": currentDate,
//       "misc": "0",
//       "dist_id": distributionId,
//       "app_version": "1.0.1",
//     };

//     final headers = <String, String>{
//       ..._formHeaders,
//       "Content-Type": "application/x-www-form-urlencoded",
//     };

//     // Form fields: request=<json>, pic=0
//     final fields = <String, String>{
//       "request": jsonEncode(payload),
//       "pic": "0",
//     };

//     final uri = Uri.parse(attendanceUrl);

//     debugPrint("➡️ POST $attendanceUrl");
//     debugPrint("➡️ headers: $headers");
//     debugPrint("➡️ form fields: $fields");

//     final res = await http
//         .post(uri, headers: headers, body: fields)
//         .timeout(const Duration(seconds: 30));

//     debugPrint("⬅️ $attendanceUrl ${res.statusCode}: ${res.body}");
//     return res;
//   }

//   Future<http.Response> startRouteApi(
//     String type,
//     String userId,
//     String lat,
//     String lng,
//     String action,
//     String disid,
//   ) async {
//     // Format date/time once
//     final now = DateTime.now();
//     final currentDate = DateFormat("dd-MMM-yyyy").format(now); // e.g., 29-Oct-2025
//     final currentTime = DateFormat("HH:mm:ss").format(now);    // e.g., 02:19:26

//     // Build the payload your API expects
//     final payload = <String, dynamic>{
//       "type": type,
//       "user_id": userId,
//       "latitude": lat,
//       "longitude": lng,
//       "device_id": "e95a9ab3bba86f821", // keep/replace with your actual device id
//       "act_type": "ROUTE",
//       "action": action,
//       "att_time": currentTime,
//       "att_date": currentDate,
//       "misc": "0",
//       "dist_id": disid,
//       "app_version": "1.0.1",
//     };

//     final uri = Uri.parse(
//       "http://services.zankgroup.com/motivesteang/index.php?route=api/user/routestart",
//     );

//     final headers = <String, String>{
//       ..._formHeaders,
//       "Content-Type": "application/x-www-form-urlencoded",
//     };

//     // Form fields: request=<json>, pic=0
//     final fields = <String, String>{
//       "request": jsonEncode(payload),
//       "pic": "0",
//     };

//     debugPrint("➡️ POST $uri");
//     debugPrint("➡️ headers: $headers");
//     debugPrint("➡️ form fields: $fields");

//     final res = await http
//         .post(uri, headers: headers, body: fields)
//         .timeout(const Duration(seconds: 30));

//     debugPrint("⬅️ $uri ${res.statusCode}: ${res.body}");
//     return res;
//   }

//   Future<http.Response> checkin_checkout(
//     String type,
//     String userId,
//     String lat,
//     String lng,
//     String act_type,
//     String action,
//     String misc,
//     String dist_id,
//   ) async {
//     final now = DateTime.now();
//     final currentDate = DateFormat("dd-MMM-yyyy").format(now); // e.g. 29-Oct-2025
//     final currentTime = DateFormat("HH:mm:ss").format(now);    // e.g. 01:45:12

//     final requestData = {
//       "type": type,
//       "user_id": userId,
//       "latitude": lat,
//       "longitude": lng,
//       "device_id": "4003dabd04d938c5", // swap with your real device id
//       "act_type": act_type,
//       "action": action,
//       "att_time": currentTime,
//       "att_date": currentDate,
//       "misc": misc,
//       "dist_id": dist_id,
//       "app_version": "1.0.1",
//     };

//     // Form body: request=<json>, pic=0
//     final formBody = {
//       "request": jsonEncode(requestData),
//       "pic": "0",
//     };

//     final uri = Uri.parse(routeStartUrlZankGroup);

//     final headers = <String, String>{
//       ..._formHeaders,
//       "Content-Type": "application/x-www-form-urlencoded",
//     };

//     debugPrint("➡️ /routestart headers: $headers");
//     debugPrint("➡️ /routestart body (form): $formBody");

//     final res = await http
//         .post(uri, headers: headers, body: formBody)
//         .timeout(const Duration(seconds: 30));

//     debugPrint("⬅️ /routestart ${res.statusCode}: ${res.body}");
//     return res;
//   }
// }


/*

class Repository {
  // Base URLs//http://services.zankgroup.com/motivesteang/index.php?route=api/user/
  final String baseUrl =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user";

  final String loginUrl =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user/login";

  final String attendanceUrl =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user/attendance";

  final String routeStartUrlZankGroup =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user/routestart";

  Map<String, String> get _formHeaders => const {
    "Content-Type": "application/json",
  };

  //   String _fmtDate(DateTime dt) => DateFormat("dd-MMM-yyyy").format(dt); // 29-Oct-2025
  // String _fmtTime(DateTime dt) => DateFormat("HH:mm:ss").format(dt); 
  
  //   Future<http.Response> _postForm(String url, Map<String, String> fields) async {
  //   final uri = Uri.parse(url);
  //   debugPrint("➡️ POST $url");
  //   debugPrint("➡️ headers: $_formHeaders");
  //   debugPrint("➡️ form fields: $fields");
  //   final res = await http
  //       .post(uri, headers: _formHeaders, body: fields)
  //       .timeout(const Duration(seconds: 30));
  //   debugPrint("⬅️ $url ${res.statusCode}: ${res.body}");
  //   return res;
  // }   // 01:55:1

  Future<http.Response> login(String email, String password) async {
  final now = DateTime.now();
  final currentDate = DateFormat("dd-MMM-yyyy").format(now); // e.g. 29-Oct-2025
  final currentTime = DateFormat("HH:mm:ss").format(now);    // e.g. 01:52:10

  final payload = {
    "email": email,
    "pass": password,
    "latitude": "0.00",
    "longitude": "0.00",
    "device_id": "e95a9ab3bba86f821", // put your real device id here
    "act_type": "LOGIN",
    "action": "IN",
    "att_time": currentTime,
    "att_date": currentDate,
    "misc": "0",
    "dist_id": "0",
    "app_version": "1.0.1",
  };

  // 👇 Form body: request=<JSON string>
  final formBody = {
    "request": jsonEncode(payload),
  };

  final uri = Uri.parse(loginUrl);

  // (Optional) force headers to be exactly what we want
  final headers = <String, String>{
    "Accept": "application/json",
    "Content-Type": "application/x-www-form-urlencoded",
  };

  debugPrint("➡️ /login headers: $headers");
  debugPrint("➡️ /login body (form): $formBody");

  final res = await http
      .post(uri, headers: headers, body: formBody)
      .timeout(const Duration(seconds: 30));

  debugPrint("⬅️ /login ${res.statusCode}: ${res.body}");

  if (res.statusCode == 200) {
    final box = GetStorage();
    box.write("email", email);
    box.write("password", password);
    box.write("email_auth", email);
    box.write("password-auth", password);
    box.write("login_model_json", res.body);
  }

  return res;
}

  // Future<http.Response> login(String email, String password) async {
  //   final now = DateTime.now();
  //   final currentDate = DateFormat(
  //     "dd-MMM-yyyy",
  //   ).format(now); // e.g., 20-Oct-2025
  //   final currentTime =
  //       "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}"; // 14:04:15

  //   final payload = {
  //     "email": email,
  //     "pass": password,
  //     "latitude": "0.00",
  //     "longitude": "0.00",
  //     "device_id": "e95a9ab3bba86f821",
  //     "act_type": "LOGIN",
  //     "action": "IN",
  //     "att_time": currentTime,
  //     "att_date": currentDate,
  //     "misc": "0",
  //     "dist_id": "0",
  //     "app_version": "1.0.1",
  //   };

  //   final body = {"request": jsonEncode(payload)};
  //   final res = await http.post(
  //     Uri.parse(loginUrl),
  //     headers: _formHeaders,
  //     body: body,
  //   );

  //   if (res.statusCode == 200) {
  //     final box = GetStorage();
  //     box.write("email", email);
  //     box.write("password", password);
  //     box.write("email_auth", email);
  //     box.write("password-auth", password);
  //     box.write("login_model_json", res.body);
  //   }

  //   debugPrint("➡️ /login body: $body");
  //   debugPrint("⬅️ /login ${res.statusCode}: ${res.body}");
  //   return res;
  // }

Future<http.Response> attendance(
  String type,
  String userId,
  String lat,
  String lng,
  String action,
  String distributionId,
) async {
  final now = DateTime.now();
  final currentDate = DateFormat("dd-MMM-yyyy").format(now); // e.g., 29-Oct-2025
  final currentTime = DateFormat("HH:mm:ss").format(now);    // e.g., 02:07:12

  final payload = {
    "type": type,
    "user_id": userId,
    "latitude": lat,
    "longitude": lng,
    "device_id": "e95a9ab3bba86f821", // keep your device id source as needed
    "act_type": "ATTENDANCE",
    "action": action,
    "att_time": currentTime,
    "att_date": currentDate,
    "misc": "0",
    "dist_id": distributionId,
    "app_version": "1.0.1",
  };

  // IMPORTANT: Use form encoding (NOT application/json)
  final headers = <String, String>{
    "Accept": "application/json",
    "Content-Type": "application/x-www-form-urlencoded",
  };

  // Form fields: request=<json>, pic=0
  final fields = <String, String>{
    "request": jsonEncode(payload),
    "pic": "0",
  };

  final uri = Uri.parse(attendanceUrl);

  debugPrint("➡️ POST $attendanceUrl");
  debugPrint("➡️ headers: $headers");
  debugPrint("➡️ form fields: $fields");

  final res = await http
      .post(uri, headers: headers, body: fields)
      .timeout(const Duration(seconds: 30));

  debugPrint("⬅️ $attendanceUrl ${res.statusCode}: ${res.body}");
  return res;
}


  // Future<http.Response> attendance(
  //   String type,
  //   String userId,
  //   String lat,
  //   String lng,
  //   String action,
  //   String distributionId,
  // ) async {
  //   final now = DateTime.now();
  //   final currentDate = DateFormat("dd-MMM-yyyy").format(now);
  //   final currentTime =
  //       "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
  //   final payload = {
  //     "type": type,
  //     "user_id": userId,
  //     "latitude": lat,
  //     "longitude": lng,
  //     "device_id": "e95a9ab3bba86f821",
  //     "act_type": "ATTENDANCE",
  //     "action": action,
  //     "att_time": currentTime,
  //     "att_date": currentDate,
  //     "misc": "0",
  //     "dist_id": distributionId,
  //     "app_version": "1.0.1",
  //   };

  //   final body = {"request": jsonEncode(payload)};
  //   final res = await http.post(
  //     Uri.parse(attendanceUrl),
  //     headers: _formHeaders,
  //     body: body,
  //   );

  //   debugPrint("➡️ /attendance body: $body");
  //   debugPrint("⬅️ /attendance ${res.statusCode}: ${res.body}");
  //   return res;
  // }

  // Future<http.Response> startRouteApi(
  //   String type,
  //   String userId,
  //   String lat,
  //   String lng,
  //   String action,
  //   String disid,
  // ) async {
  //   final now = DateTime.now();

  //   final currentDate = DateFormat("dd-MMM-yyyy").format(now);
  //   final currentTime =
  //       "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
  //   print("CURRENT DATE $currentDate");
  //   print("CURRENT DATE $currentDate");
  //   print("CURRENT TIME $currentTime");
  //   print("CURRENT TIME $currentTime");
  //   final payload = {
  //     "type": type,
  //     "user_id": userId,
  //     "latitude": lat,
  //     "longitude": lng,
  //     "device_id": "e95a9ab3bba86f821",
  //     "act_type": "ROUTE",
  //     "action": action,
  //     "att_time": currentTime,
  //     "att_date": currentDate,
  //     "misc": "0",
  //     "dist_id": disid,
  //     "app_version": "1.0.1",
  //   };

  //   final body = {"request": jsonEncode(payload)};
  //   final res = await http.post(
  //     Uri.parse(routeStartUrlZankGroup),
  //     headers: _formHeaders,
  //     body: body,
  //   );

  //   debugPrint("➡️ /routeStart body: $body");
  //   debugPrint("⬅️ /routeStart ${res.statusCode}: ${res.body}");
  //   return res;
  // }

// ✅ For legacy PHP: form-encoded "request=<json-string>&pic=0"
// Map<String, String> get _formHeaders => const {
//   "Accept": "application/json",
//   "Content-Type": "application/x-www-form-urlencoded",
// };


Future<http.Response> startRouteApi(
  String type,
  String userId,
  String lat,
  String lng,
  String action,
  String disid,
) async {
  // Format date/time once
  final now = DateTime.now();
  final currentDate = DateFormat("dd-MMM-yyyy").format(now); // e.g., 29-Oct-2025
  final currentTime = DateFormat("HH:mm:ss").format(now);    // e.g., 02:19:26

  // Build the payload your API expects
  final payload = <String, dynamic>{
    "type": type,
    "user_id": userId,
    "latitude": lat,
    "longitude": lng,
    "device_id": "e95a9ab3bba86f821", // keep/replace with your actual device id
    "act_type": "ROUTE",
    "action": action,
    "att_time": currentTime,
    "att_date": currentDate,
    "misc": "0",
    "dist_id": disid,
    "app_version": "1.0.1",
  };

  // Endpoint (in-method so nothing global is required)
  final uri = Uri.parse(
    "http://services.zankgroup.com/motivesteang/index.php?route=api/user/routestart",
  );

  // MUST be form-encoded, not JSON
  final headers = <String, String>{
    "Accept": "application/json",
    "Content-Type": "application/x-www-form-urlencoded",
  };

  // Form fields: request=<json>, pic=0
  final fields = <String, String>{
    "request": jsonEncode(payload),
    "pic": "0",
  };

  // Debug logs
  debugPrint("➡️ POST $uri");
  debugPrint("➡️ headers: $headers");
  debugPrint("➡️ form fields: $fields");

  // Send
  final res = await http
      .post(uri, headers: headers, body: fields)
      .timeout(const Duration(seconds: 30));

  debugPrint("⬅️ $uri ${res.statusCode}: ${res.body}");
  return res;
}


Future<http.Response> checkin_checkout(
  String type,
  String userId,
  String lat,
  String lng,
  String act_type,
  String action,
  String misc,
  String dist_id,
) async {
  final now = DateTime.now();
  final currentDate = DateFormat("dd-MMM-yyyy").format(now); // e.g. 29-Oct-2025
  final currentTime = DateFormat("HH:mm:ss").format(now);    // e.g. 01:45:12

  final requestData = {
    "type": type,
    "user_id": userId,
    "latitude": lat,
    "longitude": lng,
    "device_id": "4003dabd04d938c5", // swap with your real device id
    "act_type": act_type,
    "action": action,
    "att_time": currentTime,
    "att_date": currentDate,
    "misc": misc,
    "dist_id": dist_id,
    "app_version": "1.0.1",
  };

  // 👇 DO NOT jsonEncode the whole map; send as form fields
  final formBody = {
    "request": jsonEncode(requestData),
    "pic": "0",
  };

  final uri = Uri.parse(routeStartUrlZankGroup);

  // 🔒 Make sure we are NOT overriding Content-Type elsewhere
  final headers = Map<String, String>.from(_formHeaders);
  headers.removeWhere((k, _) => k.toLowerCase() == 'content-type' && _formHeaders[k] != null);
  headers['Content-Type'] = 'application/x-www-form-urlencoded';

  debugPrint("➡️ /routestart headers: $headers");
  debugPrint("➡️ /routestart body (form): $formBody");

  final res = await http
      .post(uri, headers: headers, body: formBody)
      .timeout(const Duration(seconds: 30));

  debugPrint("⬅️ /routestart ${res.statusCode}: ${res.body}");
  return res;
}


  // Future<http.Response> checkin_checkout(
  //   String type,
  //   String userId,
  //   String lat,
  //   String lng,
  //   String act_type,
  //   String action,
  //   String misc,
  //   String dist_id,
  // ) async {
  //   final now = DateTime.now();

  //   final currentDate = DateFormat("dd-MMM-yyyy").format(now);
  //   final currentTime =
  //       "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

  //   final requestData = {
  //     "type": type,
  //     "user_id": userId,
  //     "latitude": lat,
  //     "longitude": lng,
  //     "device_id": "4003dabd04d938c5",
  //     "act_type": act_type,
  //     "action": action,
  //     "att_time": "29-10-2025",
  //     "att_date": "01:34:59",
  //     "misc": misc,
  //     "dist_id": dist_id,
  //     "app_version": "1.0.1",
  //   };

  //   final body = {"request": requestData};

  //   final res = await http.post(
  //     Uri.parse(routeStartUrlZankGroup),
  //     headers: {
  //       "Accept": "application/json",
  //     //  "Content-Type": "application/json",
  //     },
  //     body: jsonDecode(body),
  //   );

  //   debugPrint("➡️ /route body: ${jsonEncode(body)}");
  //   debugPrint("⬅️ /route ${res.statusCode}: ${res.body}");
  //   return res;
  // }
}
*/