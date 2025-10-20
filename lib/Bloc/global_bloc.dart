import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';
import 'package:motives_new_ui_conversion/Models/login_model.dart';
import 'package:motives_new_ui_conversion/Models/markattendance_model.dart';
import 'package:motives_new_ui_conversion/Repository/repository.dart';

class GlobalBloc extends Bloc<GlobalEvent, GlobalState> {
  GlobalBloc() : super(const GlobalState()) {
    on<LoginEvent>(_login);
    on<MarkAttendanceEvent>(markAttendance);
    on<StartRouteEvent>(startRoute);
    on<CheckinCheckoutEvent>(checkincheckoutShopEvent);
    on<Activity>(activity);
    on<CoveredRoutesLength>(coveredRoutesLength);
  }

  final Repository repo = Repository();

  Future<void> _login(LoginEvent event, Emitter<GlobalState> emit) async {
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      final response = await repo.login(event.email, event.password);
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final LoginModel loginModel = loginModelFromJson(response.body);
        debugPrint('STATUS CHECK OF LOGIN: ${loginModel.status}');
        if (loginModel.status == "1") {
          emit(state.copyWith(
              status: LoginStatus.success, loginModel: loginModel));
        } else {
          emit(state.copyWith(
              status: LoginStatus.failure, loginModel: loginModel));
        }
      } else {
        emit(state.copyWith(status: LoginStatus.failure));
      }
    } catch (e, st) {
      debugPrint("login error: $e\n$st");
      emit(state.copyWith(status: LoginStatus.failure));
    }
  }

  Future<void> markAttendance(
      MarkAttendanceEvent event, Emitter<GlobalState> emit) async {
    emit(state.copyWith(markAttendanceStatus: MarkAttendanceStatus.loading));
    try {
      final response = await repo.attendance(
        event.type,
        event.userId, // ✅ matches updated repo signature
        event.lat,
        event.lng,
        event.action,
      );

      debugPrint("Attendance Code: ${response.statusCode}");
      debugPrint("Attendance Body: ${response.body}");

      if (response.statusCode == 200) {
        final MarkAttendenceModel m =
            markAttendenceModelFromJson(response.body);
        debugPrint('ATTENDANCE STATUS: ${m.status}');
        if (m.status == "1") {
          emit(state.copyWith(
            markAttendanceStatus: MarkAttendanceStatus.success,
            markAttendenceModel: m,
          ));
        } else {
          emit(state.copyWith(
            markAttendanceStatus: MarkAttendanceStatus.failure,
            markAttendenceModel: m,
          ));
        }
      } else {
        emit(state.copyWith(markAttendanceStatus: MarkAttendanceStatus.failure));
      }
    } catch (e, st) {
      debugPrint("attendance error: $e\n$st");
      emit(state.copyWith(markAttendanceStatus: MarkAttendanceStatus.failure));
    }
  }

  Future<void> startRoute(
      StartRouteEvent event, Emitter<GlobalState> emit) async {
    emit(state.copyWith(startRouteStatus: StartRouteStatus.loading));
    try {
      final Response response = await repo.startRouteApi(
        event.type,
        event.userId,
        event.lat,
        event.lng,
        event.action,
      );

      debugPrint("RouteStart Code: ${response.statusCode}");
      debugPrint("RouteStart Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String status = (data["status"] ?? "").toString();
        final String message = (data["message"] ?? "").toString();

        if (status == "0") {
          debugPrint("RouteStart FAILED: $message");
          emit(state.copyWith(startRouteStatus: StartRouteStatus.failure));
          return;
        }

        debugPrint("RouteStart OK: $message");
        emit(state.copyWith(startRouteStatus: StartRouteStatus.success));
      } else {
        emit(state.copyWith(startRouteStatus: StartRouteStatus.failure));
      }
    } catch (e, st) {
      debugPrint("startRoute error: $e\n$st");
      emit(state.copyWith(startRouteStatus: StartRouteStatus.failure));
    }
  }

  checkincheckoutShopEvent(
  CheckinCheckoutEvent event,
  Emitter<GlobalState> emit,
) async {
  emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.loading));

  try {
    final response = await repo.checkin_checkout(
      event.type,
      event.userId,
      event.lat,
      event.lng,
      event.act_type,
      event.action,
      event.misc,
      event.dist_id,
    );

    print("Status Code checkin_checkout : ${response.statusCode}");
    print("Response Body: ${response.body}");

    // ⬇️ Paste THIS block here
    final body = response.body;
    if (response.statusCode == 200 && body.trim().isEmpty) {
      // Consider it success if server insists on empty body
      print("checkin_checkout empty/non-JSON body.");
      emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.success));
      return;
    }

    if (response.statusCode == 200) {
      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        // 200 but not JSON -> treat as success (matches legacy server behavior)
        print("checkincheckoutShopEvent: non-JSON body; treating as success.");
        emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.success));
        return;
      }

      final String status = (data["status"] ?? "").toString();
      final String message = (data["message"] ?? "").toString();

      print("DATA $status");
      print("MESSAGE $message");

      if (status == "0") {
        emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.failure));
      } else {
        emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.success));
      }
    } else {
      emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.failure));
    }
  } catch (e, st) {
    print("checkincheckoutShopEvent error: $e\n$st");
    emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.failure));
  }
}


  // Future<void> checkincheckoutShopEvent(
  //     CheckinCheckoutEvent event, Emitter<GlobalState> emit) async {
  //   emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.loading));

  //   try {
  //     final Response response = await repo.checkin_checkout(
  //       event.type,
  //       event.userId,
  //       event.lat,
  //       event.lng,
  //       event.act_type,
  //       event.action,
  //       event.misc,
  //       event.dist_id,
  //     );

  //     debugPrint("checkin_checkout code=${response.statusCode}");
  //     final body = response.body;

  //     // 🔒 Guard against empty or non-JSON body (caused your FormatException)
  //     if (response.statusCode != 200 || body.trim().isEmpty) {
  //       debugPrint("checkin_checkout empty/non-JSON body.");
  //       emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.failure));
  //       return;
  //     }

  //     Map<String, dynamic> data;
  //     try {
  //       data = jsonDecode(body) as Map<String, dynamic>;
  //     } catch (_) {
  //       debugPrint("checkin_checkout parse error. Body was: $body");
  //       emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.failure));
  //       return;
  //     }

  //     final String status = (data["status"] ?? "").toString();
  //     final String message = (data["message"] ?? "").toString();

  //     debugPrint("DATA $status");
  //     debugPrint("MESSAGE $message");

  //     if (status == "0") {
  //       emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.failure));
  //       return;
  //     }

  //     emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.success));
  //   } catch (e, st) {
  //     debugPrint("checkincheckoutShopEvent error: $e\n$st");
  //     emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.failure));
  //   }
  // }

  Future<void> activity(Activity event, Emitter<GlobalState> emit) async {
    emit(state.copyWith(activity: event.activity));
  }

  Future<void> coveredRoutesLength(
      CoveredRoutesLength event, Emitter<GlobalState> emit) async {
    emit(state.copyWith(routesCovered: event.lenght));
  }
}