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

// repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Repository {
  // Base URLs//http://services.zankgroup.com/motivesteang/index.php?route=api/user/
  final String baseUrl =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user";

  final String loginUrl =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user/login";

  final String attendanceUrl =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user/attendance";

  final String routeStartUrl =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user/routeStart";

  final String routeUrl =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user/route";
      

  // ===== Helpers to match the legacy Android formats =====
  // Android removed separators -> "14.04.15".replace(".", "") => "140415"
  // We'll just produce HHmmss directly.
  String _attTimeNoSep() => DateFormat('HHmmss').format(DateTime.now());

  // Android used "20.Oct.2025".replace(".", "") => "20Oct2025"
  // So we use ddMMMyyyy with en_US to ensure "Oct"
  String _attDateNoSep() => DateFormat('ddMMMyyyy', 'en_US').format(DateTime.now());

  Map<String, String> get _formHeaders => const {
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      };

  // ===== API calls =====

  /// LOGIN — your current format worked, so we keep it.
  Future<http.Response> login(String email, String password) async {
    final now = DateTime.now();
    final currentDate = DateFormat("dd-MMM-yyyy").format(now); // e.g., 20-Oct-2025
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}"; // 14:04:15

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

    final body = {"request": jsonEncode(payload)};
    final res = await http.post(Uri.parse(loginUrl), headers: _formHeaders, body: body);

    if (res.statusCode == 200) {
      final box = GetStorage();
      box.write("email", email);
      box.write("password", password);
      box.write("email_auth", email);
      box.write("password-auth", password);
        box.write("login_model_json", res.body);
    }

    debugPrint("➡️ /login body: $body");
    debugPrint("⬅️ /login ${res.statusCode}: ${res.body}");
    return res;
  }

  /// ATTENDANCE — FIXED parameter order to match Bloc calls:
  /// attendance(type, userId, lat, lng, action)
  Future<http.Response> attendance(
    String type,
    String userId,
    String lat,
    String lng,
    String action,
  ) async {
    final payload = {
      "type": type,
      "user_id": userId,
      "latitude": lat,
      "longitude": lng,
      "device_id": "e95a9ab3bba86f821",
      "act_type": "ATTENDANCE",
      "action": action,
      "att_time": _attTimeNoSep(), // "HHmmss"
      "att_date": _attDateNoSep(), // "ddMMMyyyy"
      "misc": "0",
      "dist_id": "0",
      "app_version": "1.0.1",
    };

    final body = {"request": jsonEncode(payload)};
    final res = await http.post(Uri.parse(attendanceUrl), headers: _formHeaders, body: body);

    debugPrint("➡️ /attendance body: $body");
    debugPrint("⬅️ /attendance ${res.statusCode}: ${res.body}");
    return res;
  }

  /// ROUTE START — uses the no-separator formats as well.
  Future<http.Response> startRouteApi(
    String type,
    String userId,
    String lat,
    String lng,
    String action,
  ) async {
    final payload = {
      "type": type,
      "user_id": userId,
      "latitude": lat,
      "longitude": lng,
      "device_id": "e95a9ab3bba86f821",
      "act_type": "ROUTE",
      "action": action,
      "att_time": _attTimeNoSep(),
      "att_date": _attDateNoSep(),
      "misc": "0",
      "dist_id": "0",
      "app_version": "1.0.1",
    };

    final body = {"request": jsonEncode(payload)};
    final res = await http.post(Uri.parse(routeStartUrl), headers: _formHeaders, body: body);

    debugPrint("➡️ /routeStart body: $body");
    debugPrint("⬅️ /routeStart ${res.statusCode}: ${res.body}");
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

  final currentDate = DateFormat("dd-MMM-yyyy").format(now); // e.g., 22-Oct-2025
  final currentTime =
      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

  // 🔹 Create 'request' object
  final requestData = {
    "type": type,
    "user_id": userId,
    "latitude": lat,
    "longitude": lng,
    "device_id": "e95a9ab3bba86f821",
    "act_type": act_type,
    "action": action,
    "att_time": currentTime,
    "att_date": currentDate,
    "misc": misc,
    "dist_id": dist_id,
    "app_version": "1.0.1",
  };

  // 🔹 Final JSON with 'request' object and 'pic' string
  final body = {
    "request": requestData,
  //  "pic": "0",
  };

  final res = await http.post(
    Uri.parse(routeUrl),
    headers: {
      "Content-Type": "application/json",
      ..._formHeaders, // optional
    },
    body: jsonEncode(body), // ✅ Encode once at the end
  );

  debugPrint("➡️ /route body: ${jsonEncode(body)}");
  debugPrint("⬅️ /route ${res.statusCode}: ${res.body}");
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

//   final payload = {
//     "type": type,
//     "user_id": userId,
//     "latitude": lat,
//     "longitude": lng,
//     "device_id": "e95a9ab3bba86f821",
//     "act_type": act_type,
//     "action": action,
//     "att_time": currentTime,
//     "att_date": currentDate,
//     "misc": misc, // shop id
//     "dist_id": dist_id,
//     "app_version": "1.0.1",
//   };


//   final body = {
//     "request": payload,
//     "pic": "0",
//   };

//   final res = await http.post(
//     Uri.parse(routeUrl),
//     headers: {
//       "Content-Type": "application/json",
//       ..._formHeaders, // merge your custom headers if needed
//     },
//     body: jsonEncode(body),
//   );

//   debugPrint("➡️ /route body: ${jsonEncode(body)}");
//   debugPrint("⬅️ /route ${res.statusCode}: ${res.body}");
//   return res;
// }

/*Future<http.Response> checkin_checkout(
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

  final currentDate = DateFormat("dd-MMM-yyyy").format(now); // e.g., 22-Oct-2025
  final currentTime =
      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

  final payload = {
    "type": type,
    "user_id": userId,
    "latitude": lat,
    "longitude": lng,
    "device_id": "e95a9ab3bba86f821",
    "act_type": act_type,
    "action": action,
    "att_time": currentTime,
    "att_date": currentDate,
    "misc": misc, // shop id
    "dist_id": dist_id,
    "app_version": "1.0.1",
  };

  // ✅ 'pic' as plain string
  final body = {
    "request": payload,
    "pic": "0",
  };

  final res = await http.post(
    Uri.parse(routeUrl),
    headers: {
      "Content-Type": "application/json",
      ..._formHeaders, // merge your custom headers if needed
    },
    body: jsonEncode(body),
  );

  debugPrint("➡️ /route body: ${jsonEncode(body)}");
  debugPrint("⬅️ /route ${res.statusCode}: ${res.body}");
  return res;
}*/

}

// If you had logic here originally, keep it. Leaving it as a stub so the file compiles.
class ApiBaseHelper {}



/*
class Repository {
  final ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

  final baseUrl =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user";

  final loginUrl =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user/login";

  final String attendanceUrl =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user/attendance";

  final String routeStartUrl =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user/routeStart";

  final String routeUrl =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user/route";

  Future<http.Response> login(String email, String password) async {
    final now = DateTime.now();
    final currentDate = DateFormat("dd-MMM-yyyy").format(now);
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    try {
      final Map<String, dynamic> payload = {
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

      final body = {"request": jsonEncode(payload)};

      final response = await http.post(Uri.parse(loginUrl), body: body);

      if (response.statusCode == 200) {
        final box = GetStorage();
        box.write("email", email);
        box.write("password", password);
        box.write("email_auth", email);
        box.write("password-auth", password);
      }

      debugPrint("➡️ /login body: $body");
      debugPrint("⬅️ /login ${response.statusCode}: ${response.body}");
      return response;
    } catch (e) {
      throw Exception("Login API failed: $e");
    }
  }

  /// 🔄 Signature updated to match how Bloc calls it:
  /// attendance(type, userId, lat, lng, action)
  Future<http.Response> attendance(
    String type,
    String userId,
    String lat,
    String lng,
    String action,
  ) async {
    final now = DateTime.now();
    final currentDate = DateFormat("dd-MMM-yyyy").format(now);
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    try {
      final Map<String, dynamic> payload = {
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
        "dist_id": "0",
        "app_version": "1.0.1",
      };

      final body = {"request": jsonEncode(payload)};
      final response = await http.post(Uri.parse(attendanceUrl), body: body);

      debugPrint("➡️ /attendance body: $body");
      debugPrint("⬅️ /attendance ${response.statusCode}: ${response.body}");
      return response;
    } catch (e) {
      throw Exception("Attendance API failed: $e");
    }
  }

  Future<http.Response> startRouteApi(
    String type,
    String userId,
    String lat,
    String lng,
    String action,
  ) async {
    final now = DateTime.now();
    final currentDate = DateFormat("dd-MMM-yyyy").format(now);
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    try {
      final Map<String, dynamic> payload = {
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
        "dist_id": "0",
        "app_version": "1.0.1"
      };

      final body = {"request": jsonEncode(payload)};
      final response = await http.post(Uri.parse(routeStartUrl), body: body);

      debugPrint("➡️ /routeStart body: $body");
      debugPrint("⬅️ /routeStart ${response.statusCode}: ${response.body}");
      return response;
    } catch (e) {
      throw Exception("RouteStart API failed: $e");
    }
  }

  /// 🔧 Always send "pic" like the Java app (even if "0")
  Future<http.Response> checkin_checkout(
    String type,
    String userId,
    String lat,
    String lng,
    String act_type,
    String action,
    String misc,
    String dist_id, {
    String pic = "0",
  }) async {
    final now = DateTime.now();
    final currentDate = DateFormat("dd-MMM-yyyy").format(now);
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    final payload = {
      "type": type,
      "user_id": userId,
      "latitude": lat,
      "longitude": lng,
      "device_id": "e95a9ab3bba86f821",
      "act_type": act_type,
      "action": action,
      "att_time": currentTime,
      "att_date": currentDate,
      "misc": misc,
      "dist_id": dist_id,
      "app_version": "1.0.1",
    };

    final body = {
      "request": jsonEncode(payload),
      "pic": pic, // 👈 IMPORTANT
    };

    final resp = await http
        .post(
          Uri.parse(routeUrl),
          headers: {"Accept": "application/json"},
          body: body,
        )
        .timeout(const Duration(seconds: 60));

    debugPrint("➡️ /route body: $body");
    debugPrint("⬅️ /route ${resp.statusCode}: ${resp.body}");
    return resp;
  }
}

/// Placeholder for your actual helper to avoid breaking imports.
class ApiBaseHelper {}*/


// class Repository {
//   ApiBaseHelper _apiBaseHelper = ApiBaseHelper();

//   var baseUrl =
//       "http://services.zankgroup.com/motivesteang/index.php?route=api/user";

//   var loginUrl =
//       "http://services.zankgroup.com/motivesteang/index.php?route=api/user/login";
//   final String attendanceUrl =
//       "http://services.zankgroup.com/motivesteang/index.php?route=api/user/attendance";

//   final String routeStartUrl =
//       "http://services.zankgroup.com/motivesteang/index.php?route=api/user/routeStart";

//         final String routeUrl =
//       "http://services.zankgroup.com/motivesteang/index.php?route=api/user/route";

//   Future<http.Response> login(String email, String password) async {
//     DateTime now = DateTime.now();

//     String currentDate = DateFormat("dd-MMM-yyyy").format(now);
//     String currentTime =
//         "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

//     try {
//       final Map<String, dynamic> payload = {
//         "email": email,
//         "pass": password,
//         "latitude": "0.00",
//         "longitude": "0.00",
//         "device_id": "e95a9ab3bba86f821",
//         "act_type": "LOGIN",
//         "action": "IN",
//         "att_time": currentTime,
//         "att_date": currentDate,
//         "misc": "0",
//         "dist_id": "0",
//         "app_version": "1.0.1",
//       };

//       print("PAYLOAD $payload");

//       final body = {"request": jsonEncode(payload)};

//       final response = await http.post(Uri.parse(loginUrl), body: body);
//       if (response.statusCode == 200) {
//         final box = GetStorage();
//         box.write("email", email);
//         box.write("password", password);
//         box.write("email_auth", email);
//         box.write("password-auth", password);
//       }

//       print("➡️ Sending: ${body}");
//       print("⬅️ Status Code: ${response.statusCode}");
//       print("⬅️ Response Body: ${response.body}");

//       return response;
//     } catch (e) {
//       throw Exception("Login API failed: $e");
//     }
//   }

//   Future<http.Response> attendance(
//     String type,
//     String action,
//     String userId,
//     String lat,
//     String lng,
//   ) async {
//     DateTime now = DateTime.now();

//     String currentDate = DateFormat("dd-MMM-yyyy").format(now);
//     String currentTime =
//         "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

//     try {
//       final Map<String, dynamic> payload = {
//         "type": type,
//         "user_id": userId,
//         "latitude": lat,
//         "longitude": lng,
//         "device_id": "e95a9ab3bba86f821",
//         "act_type": "ATTENDANCE",
//         "action": action,
//         "att_time": currentTime,
//         "att_date": currentDate,
//         "misc": "0",
//         "dist_id": "0",
//         "app_version": "1.0.1",
//       };

//       print("PAYLOAD $payload");

//       final body = {"request": jsonEncode(payload)};

//       final response = await http.post(Uri.parse(attendanceUrl), body: body);
//       if (response.statusCode == 200) {}

//       print("➡️ Sending: ${body}");
//       print("⬅️ Status Code: ${response.statusCode}");
//       print("⬅️ Response Body: ${response.body}");

//       return response;
//     } catch (e) {
//       throw Exception("Login API failed: $e");
//     }
//   }


//    Future<http.Response> startRouteApi(
//     String type,
//     String userId,
//     String lat,
//     String lng,
//     String action
//   ) async {
//     DateTime now = DateTime.now();

//     String currentDate = DateFormat("dd-MMM-yyyy").format(now);
//     String currentTime =
//         "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

//     try {
//       final Map<String, dynamic> payload = {

//         "type":type,
//         "user_id":userId,
//         "latitude":lat,
//         "longitude":lng,
//         "device_id":"e95a9ab3bba86f821",
//         "act_type":"ROUTE",
//         "action":action,
//          "att_time": currentTime,
//         "att_date": currentDate,
//         "misc":"0",
//         "dist_id":"0",
//         "app_version":"1.0.1"
//       };

//       print("PAYLOAD $payload");

//       final body = {"request": jsonEncode(payload)};

//       final response = await http.post(Uri.parse(routeStartUrl), body: body);
//       if (response.statusCode == 200) {}

//       print("➡️ Sending: ${body}");
//       print("⬅️ Status Code: ${response.statusCode}");
//       print("⬅️ Response Body: ${response.body}");

//       return response;
//     } catch (e) {
//       throw Exception("Login API failed: $e");
//     }
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
//     final currentDate = DateFormat("dd-MMM-yyyy").format(now);
//     final currentTime =
//         "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

//     final payload = {
//       "type": type,
//       "user_id": userId,
//       "latitude": lat,
//       "longitude": lng,
//       "device_id": "e95a9ab3bba86f821",
//       "act_type": act_type,
//       "action": action,
//       "att_time": currentTime,
//       "att_date": currentDate,
//       "misc": misc,      // <- miscid (shop id)
//       "dist_id": dist_id,
//       "app_version": "1.0.1",
//     };

//     final body = {"request": jsonEncode(payload)};
//     // 🔁 Correct endpoint
//     return http.post(Uri.parse(routeUrl), body: body);
//   }
// }

//     Future<http.Response> checkin_checkout(
//     String type,
//     String userId,
//     String lat,
//     String lng,
//     String act_type,
//     String action,
//     String misc,
//     String dist_id
//   ) async {
//     DateTime now = DateTime.now();

//     String currentDate = DateFormat("dd-MMM-yyyy").format(now);
//     String currentTime =
//         "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

//     try {
//       final Map<String, dynamic> payload = {

//         "type":type,
//         "user_id":userId,
//         "latitude":lat,
//         "longitude":lng,
//         "device_id":"e95a9ab3bba86f821",
//         "act_type":act_type,
//         "action":action,
//         "att_time": currentTime,
//         "att_date": currentDate,
//         "misc":misc,
//         "dist_id":dist_id,
//         "app_version":"1.0.1"
//       };

//       print("PAYLOAD $payload");

//       final body = {"request": jsonEncode(payload)};

//       final response = await http.post(Uri.parse(routeStartUrl), body: body);
//       if (response.statusCode == 200) {}

//       print("➡️ Sending: ${body}");
//       print("⬅️ Status Code: ${response.statusCode}");
//       print("⬅️ Response Body: ${response.body}");

//       return response;
//     } catch (e) {
//       throw Exception("Login API failed: $e");
//     }
//   }
// }
