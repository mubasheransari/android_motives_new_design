import 'package:equatable/equatable.dart';



abstract class GlobalEvent extends Equatable {
  const GlobalEvent();
  @override
  List<Object?> get props => [];
}

class HydrateLoginFromCache extends GlobalEvent {
  const HydrateLoginFromCache();
}

class LoginEvent extends GlobalEvent {
  final String email;
  final String password;
  const LoginEvent({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class MarkAttendanceEvent extends GlobalEvent {
  final String type;
  final String action;
  final String userId;
  final String lat;
  final String lng;
  const MarkAttendanceEvent({
    required this.type,
    required this.action,
    required this.userId,
    required this.lat,
    required this.lng,
  });
  @override
  List<Object?> get props => [type, action, userId, lat, lng];
}

class StartRouteEvent extends GlobalEvent {
  final String type;
  final String userId;
  final String lat;
  final String lng;
  final String action;
  final String disid;
  const StartRouteEvent({
    required this.type,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.action,
    required this.disid,
  });
  @override
  List<Object?> get props => [type, userId, lat, lng, action, disid];
}

class CheckinCheckoutEvent extends GlobalEvent {
  final String type;
  final String userId;
  final String lat;
  final String lng;
  final String act_type;
  final String action;
  final String misc;
  final String dist_id;
  const CheckinCheckoutEvent({
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
  List<Object?> get props =>
      [type, userId, lat, lng, act_type, action, misc, dist_id];
}

class Activity extends GlobalEvent {
  final String activity;
  const Activity({required this.activity});
  @override
  List<Object?> get props => [activity];
}

class CoveredRoutesLength extends GlobalEvent {
  final String lenght;
  const CoveredRoutesLength({required this.lenght});
  @override
  List<Object?> get props => [lenght];
}