import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';
import 'package:motives_new_ui_conversion/Models/login_model.dart';
import 'package:motives_new_ui_conversion/Models/markattendance_model.dart';
import 'package:motives_new_ui_conversion/Repository/repository.dart';

class GlobalBloc extends Bloc<GlobalEvent, GlobalState> {
  GlobalBloc() : super(GlobalState()) {
    on<LoginEvent>(_login);
    on<MarkAttendanceEvent>(markAttendance);
    on<StartRouteEvent>(startRoute);
    on<CheckinCheckoutEvent>(checkincheckoutShopEvent);
    on<Activity>(activity);
    on<CoveredRoutesLength>(coveredRoutesLength);

  }

  Repository repo = Repository();

  _login(LoginEvent event, Emitter<GlobalState> emit) async {
    emit(state.copyWith(status: LoginStatus.loading));

    try {
      final response = await repo.login(event.email, event.password);

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final LoginModel loginModel = loginModelFromJson(response.body);

        print('STATUS CHECK OF LOGIN: ${loginModel.status}');

        if (loginModel.status == "1") {
          emit(
            state.copyWith(status: LoginStatus.success, loginModel: loginModel),
          );
        } else {
          emit(
            state.copyWith(status: LoginStatus.failure, loginModel: loginModel),
          );
        }
      } else {
        emit(state.copyWith(status: LoginStatus.failure));
      }
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.failure));
    }
  }

  markAttendance(MarkAttendanceEvent event, Emitter<GlobalState> emit) async {
    emit(state.copyWith(markAttendanceStatus: MarkAttendanceStatus.loading));

    try {
      final response = await repo.attendance(
        event.type,
        event.userId,
        event.lat,
        event.lng,
        event.action
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print('Under status code 200 print');
        print('Under status code 200 print');
        print('Under status code 200 print');
        final MarkAttendenceModel markAttendenceModel =
            markAttendenceModelFromJson(response.body);

        print('STATUS CHECK: ${markAttendenceModel.status}');

        if (markAttendenceModel.status == "1") {
          emit(
            state.copyWith(
              markAttendanceStatus: MarkAttendanceStatus.success,
              markAttendenceModel: markAttendenceModel,
            ),
          );
        } else {
          emit(
            state.copyWith(
              markAttendanceStatus: MarkAttendanceStatus.failure,
              markAttendenceModel: markAttendenceModel,
            ),
          );
        }
      } else {
        emit(
          state.copyWith(markAttendanceStatus: MarkAttendanceStatus.failure),
        );
      }
    } catch (e) {
      emit(state.copyWith(markAttendanceStatus: MarkAttendanceStatus.failure));
    }
  }

  startRoute(StartRouteEvent event, Emitter<GlobalState> emit) async {
    emit(state.copyWith(startRouteStatus: StartRouteStatus.loading));

    try {
      Response response = await repo.startRouteApi(
        event.type,
        event.userId,
        event.lat,
        event.lng,
        event.action
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final String status = data["status"] ?? "";
        final String message = data["message"] ?? "";

        if (status == "0") {
          print("STATUS 0 CONDITION");
          print("STATUS 0 CONDITION");
          print("STATUS 0 CONDITION");
          print("STATUS 0 CONDITION");
          print("STATUS 0 CONDITION");
          emit(state.copyWith(startRouteStatus: StartRouteStatus.failure));
        }

        print("STATUS ${status}");
        print("STATUS ${status}");
        print("STATUS ${status}");

        print("MESSAGE ${message}");
        print("MESSAGE ${message}");

        emit(state.copyWith(startRouteStatus: StartRouteStatus.success));
      } else {
        emit(state.copyWith(startRouteStatus: StartRouteStatus.failure));
      }
    } catch (e) {
      emit(state.copyWith(startRouteStatus: StartRouteStatus.failure));
    }
  }

  checkincheckoutShopEvent(
    CheckinCheckoutEvent event,
    Emitter<GlobalState> emit,
  ) async {
    emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.loading));

    try {
      Response response = await repo.checkin_checkout(
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final String status = data["status"] ?? "";
        final String message = data["message"] ?? "";

        print("DATA $status");

         print("MESSAGE $message");

        if (status == "0") {
          emit(
            state.copyWith(
              checkinCheckoutStatus: CheckinCheckoutStatus.failure,
            ),
          );
        }

        emit(
          state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.success),
        );
      } else {
        emit(
          state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.failure),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.failure),
      );
    }
  }

   activity(Activity event, Emitter<GlobalState> emit) async {
    emit(state.copyWith(activity: event.activity));

  }

     coveredRoutesLength(CoveredRoutesLength event, Emitter<GlobalState> emit) async {
    emit(state.copyWith(routesCovered: event.lenght));

  }
}
