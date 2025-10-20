import 'package:equatable/equatable.dart';
import 'package:motives_new_ui_conversion/Models/login_model.dart';
import 'package:motives_new_ui_conversion/Models/markattendance_model.dart';


enum LoginStatus { initial, loading, success, failure }
enum MarkAttendanceStatus { initial, loading, success, failure }
enum StartRouteStatus { initial, loading, success, failure }
enum CheckinCheckoutStatus { initial, loading, success, failure }


class GlobalState extends Equatable {
  final LoginStatus status;
  final MarkAttendanceStatus markAttendanceStatus;
  final StartRouteStatus startRouteStatus;
  final CheckinCheckoutStatus checkinCheckoutStatus;
  final LoginModel? loginModel;
  final MarkAttendenceModel? markAttendenceModel;
  final String? activity;
  final String? routesCovered;

  const GlobalState({
    this.status = LoginStatus.initial,
    this.markAttendanceStatus = MarkAttendanceStatus.initial,
    this.startRouteStatus = StartRouteStatus.initial,
    this.checkinCheckoutStatus = CheckinCheckoutStatus.initial,
    this.loginModel,
    this.markAttendenceModel,
    this.activity,
    this.routesCovered,
  });

  GlobalState copyWith({
    LoginStatus? status,
    MarkAttendanceStatus? markAttendanceStatus,
    StartRouteStatus? startRouteStatus,
    CheckinCheckoutStatus? checkinCheckoutStatus,
    LoginModel? loginModel,
    MarkAttendenceModel? markAttendenceModel,
    String? activity,
    String? routesCovered,
  }) {
    return GlobalState(
      status: status ?? this.status,
      markAttendanceStatus: markAttendanceStatus ?? this.markAttendanceStatus,
      startRouteStatus: startRouteStatus ?? this.startRouteStatus,
      checkinCheckoutStatus:
          checkinCheckoutStatus ?? this.checkinCheckoutStatus,
      loginModel: loginModel ?? this.loginModel,
      markAttendenceModel: markAttendenceModel ?? this.markAttendenceModel,
      activity: activity ?? this.activity,
      routesCovered: routesCovered ?? this.routesCovered,
    );
  }

  @override
  List<Object?> get props => [
        routesCovered,
        status,
        markAttendanceStatus,
        startRouteStatus,
        checkinCheckoutStatus,
        loginModel,
        markAttendenceModel,
        activity,
      ];
}


// enum LoginStatus { initial, loading, success, failure }

// enum MarkAttendanceStatus { initial, loading, success, failure }

// enum StartRouteStatus { initial, loading, success, failure }

// enum CheckinCheckoutStatus { initial, loading, success, failure }

// // ignore: must_be_immutable
// class GlobalState extends Equatable {
//   final LoginStatus status;
//   final MarkAttendanceStatus markAttendanceStatus;
//   final StartRouteStatus startRouteStatus;
//   final CheckinCheckoutStatus checkinCheckoutStatus;
//   LoginModel? loginModel;
//   MarkAttendenceModel ? markAttendenceModel;
//  String? activity;
//  String? routesCovered;

//   GlobalState({
//     this.status = LoginStatus.initial,
//     this.markAttendanceStatus = MarkAttendanceStatus.initial,
//     this.startRouteStatus = StartRouteStatus.initial,
//     this.checkinCheckoutStatus = CheckinCheckoutStatus.initial,
//     this.loginModel,
//     this.markAttendenceModel,
//     this.activity,
//     this.routesCovered
//   });

//   GlobalState copyWith({
//     LoginStatus? status,
//     MarkAttendanceStatus? markAttendanceStatus,
//     StartRouteStatus ? startRouteStatus,
//     CheckinCheckoutStatus ? checkinCheckoutStatus,
//     LoginModel? loginModel,
//     MarkAttendenceModel ? markAttendenceModel,
//     String? activity,
//      String? routesCovered
//   }) {
//     return GlobalState(
//       status: status ?? this.status,
//       markAttendanceStatus: markAttendanceStatus ?? this.markAttendanceStatus,
//       startRouteStatus: startRouteStatus ?? this.startRouteStatus,
//       checkinCheckoutStatus:  checkinCheckoutStatus ?? this.checkinCheckoutStatus,
//       loginModel: loginModel ?? this.loginModel,
//       markAttendenceModel:  markAttendenceModel ?? this.markAttendenceModel,
//       activity: activity ?? this.activity,
//       routesCovered: routesCovered ?? this.routesCovered
//     );
//   }

//   @override
//   List<Object?> get props => [routesCovered,status, markAttendanceStatus,startRouteStatus,checkinCheckoutStatus ,loginModel,markAttendenceModel,activity];
// }
