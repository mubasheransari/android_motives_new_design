import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:motives_new_ui_conversion/Models/get_shop_invoices_model.dart';
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
      final String getSalesHistoryUrl = "http://services.zankgroup.com/motivesteang/index.php?route=api/user/getSaleHistory";

   final String getShopInvoicesUrl = "http://services.zankgroup.com/motivesteang/index.php?route=api/user/getShopInvoices";


  Map<String, String> get _formHeaders => const {
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
      };

  /* -------------------------------- Login -------------------------------- */
  Future<http.Response> getSalesHistory({
    required String acode,
    required String disid,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final uri = Uri.parse(getSalesHistoryUrl);

    // EXACTLY these two fields; no JSON, no "request=" wrapper
    final fields = {
      'acode': acode,
      'disid': disid,
    };

    final res = await http
        .post(uri, headers: _formHeaders, body: fields)
        .timeout(timeout);

    // Optional debug
    // ignore: avoid_print
    print('⬅️ getSaleHistory ${res.statusCode}: ${res.body}');
    return res;
  }
  /*
Future<http.Response> getSalesHistory({
    required String acode,
    required String disid,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final uri = Uri.parse(getSalesHistoryUrl);

    final req = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..fields['acode'] = acode
      ..fields['disid'] = disid;

    // If you ever need to add files later:
    // req.files.add(await http.MultipartFile.fromPath('file', path));

    final streamed = await req.send().timeout(timeout);
    final res = await http.Response.fromStream(streamed);

    // Debug (optional)
    // ignore: avoid_print
    print('⬅️ getSaleHistory ${res.statusCode}: ${res.body}');

    return res;
  }*/

  Future<http.Response> postLegacyFormEncoded({
  required String url,
  required Map<String, dynamic> payload,
  String requestField = 'request',
  Map<String, String>? extraHeaders,
  Duration timeout = const Duration(seconds: 45),
}) async {
  final uri = Uri.parse(url);
  final headers = <String, String>{...?(extraHeaders ?? const {})};
  headers.removeWhere((k, _) => k.toLowerCase() == 'content-type');
  headers['Accept'] = headers['Accept'] ?? 'application/json';
  headers['Content-Type'] = 'application/x-www-form-urlencoded';

  final body = <String, String>{ requestField: jsonEncode(payload) };

  debugPrint('➡️ POST $uri');
  debugPrint('➡️ headers: $headers');
  debugPrint('➡️ fields:  $body');

  final res = await http.post(uri, headers: headers, body: body).timeout(timeout);
  debugPrint('⬅️ $uri ${res.statusCode}: ${res.body}');
  return res;
}


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


  Future<http.Response> getShopInvoices({
  required String acode,
  required String disid,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final uri = Uri.parse(getShopInvoicesUrl);
  // This endpoint expects regular form-data keys (NOT {"request": ...})
  final res = await http
      .post(
        uri,
        headers: _formHeaders, // application/x-www-form-urlencoded
        body: {"acode": acode, "disid": disid},
      )
      .timeout(timeout);

  debugPrint('⬅️ /getShopInvoices ${res.statusCode}: ${res.body}');
  return res;
}

List<GetShopInvoicesModel> parseInvoicesBody(String body) {
  final decoded = jsonDecode(body);

  if (decoded is! List) return const <GetShopInvoicesModel>[];

  // If it already matches the invoice shape:
  final hasInvoiceKeys = decoded.isNotEmpty &&
      decoded.first is Map &&
      (decoded.first as Map).containsKey('invid');

  if (hasInvoiceKeys) {
    return GetShopInvoicesModel.listFromJson(
        decoded.cast<Map<String, dynamic>>());
  }


  return decoded.map<GetShopInvoicesModel>((e) {
    final m = (e as Map).cast<String, dynamic>();
    final ordNo = (m['ord_no'] as String?)?.trim();

    return GetShopInvoicesModel(
      invid: ordNo,                 // map order number into invoice id
      invno: ordNo,                 // show as invoice number
      invDate: m['inv_date']        // if backend ever returns it
          as String? ?? m['order_date'] as String?, // optional
      acode: m['acode'] as String?,
      cashCredit: m['cash_credit'] as String?,      // optional if present
      invAmount: m['inv_amount'] as String?
          ?? m['amount'] as String?,                // optional if present
      ledAmount: m['led_amount'] as String?,        // likely missing
      balAmount: m['bal_amount'] as String?,        // likely missing
    );
  }).toList();
}

}
