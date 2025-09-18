import 'package:equatable/equatable.dart';

abstract class GlobalEvent extends Equatable {
  const GlobalEvent();

  @override
  List<Object> get props => [];
}

// ignore: must_be_immutable
class LoginEvent extends GlobalEvent {
  final String email;
  final String password;

  LoginEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

// ignore: must_be_immutable
class MarkAttendanceEvent extends GlobalEvent {
  String type;
  String userId;
  String lat;
  String lng;

  MarkAttendanceEvent({
    required this.type,
    required this.userId,
    required this.lat,
    required this.lng,
  });

  @override
  List<Object> get props => [type, userId, lat, lng];
}

class StartRouteEvent extends GlobalEvent {
  String type;
  String userId;
  String lat;
  String lng;

  StartRouteEvent({
    required this.type,
    required this.userId,
    required this.lat,
    required this.lng,
  });

  @override
  List<Object> get props => [type, userId, lat, lng];
}

// ignore: must_be_immutable
class CheckinCheckoutEvent extends GlobalEvent {
  String type;
  String userId;
  String lat;
  String lng;
  String act_type;
  String action;
  String misc;
  String dist_id;

  CheckinCheckoutEvent({
    required this.type,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.act_type,
    required this.action,
    required this.misc,
    required this.dist_id,
  });

  @override
  List<Object> get props => [
    type,
    userId,
    lat,
    lng,
    act_type,
    action,
    misc,
    dist_id,
  ];
}
