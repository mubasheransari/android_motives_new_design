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

  final String routeStartUrlZankGroup =
      "http://services.zankgroup.com/motivesteang/index.php?route=api/user/routeStart";

  Map<String, String> get _formHeaders => const {
    "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
  };

  Future<http.Response> login(String email, String password) async {
    final now = DateTime.now();
    final currentDate = DateFormat(
      "dd-MMM-yyyy",
    ).format(now); // e.g., 20-Oct-2025
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
    final res = await http.post(
      Uri.parse(loginUrl),
      headers: _formHeaders,
      body: body,
    );

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
      "dist_id": "0",
      "app_version": "1.0.1",
    };

    final body = {"request": jsonEncode(payload)};
    final res = await http.post(
      Uri.parse(attendanceUrl),
      headers: _formHeaders,
      body: body,
    );

    debugPrint("➡️ /attendance body: $body");
    debugPrint("⬅️ /attendance ${res.statusCode}: ${res.body}");
    return res;
  }

  Future<http.Response> startRouteApi(
    String type,
    String userId,
    String lat,
    String lng,
    String action,
    String disid
  ) async {
    final now = DateTime.now();

    final currentDate = DateFormat("dd-MMM-yyyy").format(now);
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    print("CURRENT DATE $currentDate");
    print("CURRENT DATE $currentDate");
    print("CURRENT TIME $currentTime");
    print("CURRENT TIME $currentTime");
    final payload = {
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

    final body = {"request": jsonEncode(payload)};
    final res = await http.post(
      Uri.parse(routeStartUrlZankGroup),
      headers: _formHeaders,
      body: body,
    );

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

    final currentDate = DateFormat("dd-MMM-yyyy").format(now);
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

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

    final body = {
      "request": requestData,
      //  "pic": "0",
    };

    final res = await http.post(
      Uri.parse(routeStartUrlZankGroup),
      headers: {"Content-Type": "application/json", ..._formHeaders},
      body: jsonEncode(body),
    );

    debugPrint("➡️ /route body: ${jsonEncode(body)}");
    debugPrint("⬅️ /route ${res.statusCode}: ${res.body}");
    return res;
  }
}
