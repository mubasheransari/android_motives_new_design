import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:motives_new_ui_conversion/Bloc/global_event.dart';
import 'package:motives_new_ui_conversion/Bloc/global_state.dart';
import 'package:motives_new_ui_conversion/Models/get_sales_history_model.dart';
import 'package:motives_new_ui_conversion/Models/login_model.dart';
import 'package:motives_new_ui_conversion/Models/markattendance_model.dart';
import 'package:motives_new_ui_conversion/Repository/repository.dart';

import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../models/login_model.dart' hide LoginModel, loginModelFromJson;            // your model imports
import '../offline/sync_service.dart';

import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';



class GlobalBloc extends Bloc<GlobalEvent, GlobalState> {
  GlobalBloc() : super(GlobalState()) {
    on<HydrateLoginFromCache>(_hydrateFromCache);
    on<LoginEvent>(_login);
    on<MarkAttendanceEvent>(_markAttendance);
    on<StartRouteEvent>(_startRoute);
    on<CheckinCheckoutEvent>(_checkinCheckout);
    on<Activity>(activity);
    on<CoveredRoutesLength>(coveredRoutesLength);
    on<LoadShopInvoicesRequested>(_onLoadShopInvoices);
    on<LoadSalesHistoryRequested>(_onLoadSalesHistory);
  }

  final Repository repo = Repository();


  // global_bloc.dart (add method)
DateTime? _tryParseInvDate(String? s) {
  if (s == null || s.trim().isEmpty) return null;
  // API uses "16-DEC-19" → dd-MMM-yy
  try {
    return DateFormat("dd-MMM-yy").parse(s.toUpperCase());
  } catch (_) {
    return null;
  }
}


Future<void> _onLoadSalesHistory(
  LoadSalesHistoryRequested e,
  Emitter<GlobalState> emit,
) async {
  emit(state.copyWith(
    salesHistoryStatus: SalesHistoryStatus.loading,
    salesHistoryError: null,
  ));

  try {
    final res = await repo.getSalesHistory(acode: e.acode, disid: e.disid);

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        final list = decoded
            .whereType<Map<String, dynamic>>()
            .map((m) => GetSaleHistoryModel.fromJson(m))
            .toList();

        emit(state.copyWith(
          salesHistoryStatus: SalesHistoryStatus.success,
          salesHistory: list,
          salesHistoryError: null,
        ));
      } else {
        emit(state.copyWith(
          salesHistoryStatus: SalesHistoryStatus.failure,
          salesHistoryError: 'Unexpected response format.',
        ));
      }
    } else {
      emit(state.copyWith(
        salesHistoryStatus: SalesHistoryStatus.failure,
        salesHistoryError: 'HTTP ${res.statusCode}',
      ));
    }
  } catch (err, st) {
    debugPrint('getSalesHistory error: $err\n$st');
    emit(state.copyWith(
      salesHistoryStatus: SalesHistoryStatus.failure,
      salesHistoryError: 'Failed to load sales history',
    ));
  }
}

Future<void> _onLoadShopInvoices(
  LoadShopInvoicesRequested e,
  Emitter<GlobalState> emit,
) async {
  emit(state.copyWith(
    invoicesStatus: InvoicesStatus.loading,
    invoicesError: null,
  ));

  try {
    final res = await repo.getShopInvoices(acode: e.acode, disid: e.disid);
    if (res.statusCode == 200) {
      final list = repo.parseInvoicesBody(res.body);

      // Optional: sort by date desc (unknowns last)
      final sorted = [...list]..sort((a, b) {
        final ad = _tryParseInvDate(a.invDate);
        final bd = _tryParseInvDate(b.invDate);
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });

      emit(state.copyWith(
        invoicesStatus: InvoicesStatus.success,
        invoices: sorted,
        invoicesError: null,
      ));
    } else {
      emit(state.copyWith(
        invoicesStatus: InvoicesStatus.failure,
        invoicesError: 'HTTP ${res.statusCode}',
      ));
    }
  } catch (err, st) {
    debugPrint('getShopInvoices error: $err\n$st');
    emit(state.copyWith(
      invoicesStatus: InvoicesStatus.failure,
      invoicesError: '$err',
    ));
  }
}


  Future<void> _hydrateFromCache(
      HydrateLoginFromCache event, Emitter<GlobalState> emit) async {
    try {
      final raw = GetStorage().read("login_model_json");
      if (raw is String && raw.isNotEmpty) {
        final cached = loginModelFromJson(raw);
        emit(state.copyWith(
          status: LoginStatus.success,
          loginModel: cached,
        ));
      }
    } catch (_) {}
  }

  Future<void> _login(LoginEvent event, Emitter<GlobalState> emit) async {
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      final response = await repo.login(event.email, event.password);
      if (response.statusCode == 200) {
        final loginModel = loginModelFromJson(response.body);
        if (loginModel.status == "1") {
          emit(state.copyWith(status: LoginStatus.success, loginModel: loginModel));
        } else {
          emit(state.copyWith(status: LoginStatus.failure, loginModel: loginModel));
        }
      } else {
        emit(state.copyWith(status: LoginStatus.failure));
      }
    } catch (e, st) {
      debugPrint("login error: $e\n$st");
      emit(state.copyWith(status: LoginStatus.failure));
    }
  }

  Future<void> _markAttendance(MarkAttendanceEvent e, Emitter<GlobalState> emit) async {
    emit(state.copyWith(markAttendanceStatus: MarkAttendanceStatus.loading));
    try {
      final res = await repo.attendance(
        e.type, e.userId, e.lat, e.lng, e.action,
        state.loginModel?.userinfo?.disid.toString() ?? "0",
      );
      if (res.statusCode == 200) {
        final m = markAttendenceModelFromJson(res.body);
        if ((m.status ?? '0') == '1') {
          emit(state.copyWith(markAttendanceStatus: MarkAttendanceStatus.success, markAttendenceModel: m));
        } else {
          emit(state.copyWith(markAttendanceStatus: MarkAttendanceStatus.failure, markAttendenceModel: m));
        }
      } else {
        emit(state.copyWith(markAttendanceStatus: MarkAttendanceStatus.failure));
      }
    } catch (e, st) {
      debugPrint("attendance error: $e\n$st");
      emit(state.copyWith(markAttendanceStatus: MarkAttendanceStatus.failure));
    }
  }

  Future<void> _startRoute(StartRouteEvent e, Emitter<GlobalState> emit) async {
    if (!await SyncService.instance.isOnlineNow()) {
      await SyncService.instance.enqueueStartRoute(
        type: e.type, userId: e.userId, lat: e.lat, lng: e.lng, action: e.action, disid: e.disid,
      );
      emit(state.copyWith(startRouteStatus: StartRouteStatus.queued));
      emit(state.copyWith(startRouteStatus: StartRouteStatus.initial));
      return;
    }

    emit(state.copyWith(startRouteStatus: StartRouteStatus.loading));
    try {
      final res = await repo.startRouteApi(e.type, e.userId, e.lat, e.lng, e.action, e.disid);
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final status = (data["status"] ?? "").toString();
        emit(state.copyWith(
          startRouteStatus: status == "0" ? StartRouteStatus.failure : StartRouteStatus.success,
        ));
      } else {
        // enqueue on non-200
        await SyncService.instance.enqueueStartRoute(
          type: e.type, userId: e.userId, lat: e.lat, lng: e.lng, action: e.action, disid: e.disid,
        );
        emit(state.copyWith(startRouteStatus: StartRouteStatus.queued));
      }
    } catch (err, st) {
      debugPrint("startRoute error: $err\n$st");
      await SyncService.instance.enqueueStartRoute(
        type: e.type, userId: e.userId, lat: e.lat, lng: e.lng, action: e.action, disid: e.disid,
      );
      emit(state.copyWith(startRouteStatus: StartRouteStatus.queued));
    } finally {
      emit(state.copyWith(startRouteStatus: StartRouteStatus.initial));
    }
  }

  // ✅ Key fix: on ANY non-200/exception, enqueue & show "queued" instead of failure.
  Future<void> _checkinCheckout(CheckinCheckoutEvent e, Emitter<GlobalState> emit) async {
    emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.loading));

    final online = await SyncService.instance.isOnlineNow();
    if (!online) {
      await SyncService.instance.enqueueRouteAction(
        type: e.type,
        userId: e.userId,
        lat: e.lat,
        lng: e.lng,
        actType: e.act_type,
        action: e.action,
        misc: e.misc,
        distId: e.dist_id,
      );
      emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.queued));
      emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.initial));
      return;
    }

    try {
      final res = await repo.checkin_checkout(
        e.type, e.userId, e.lat, e.lng, e.act_type, e.action, e.misc, e.dist_id,
      );

      if (res.statusCode == 200) {
        emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.success));
      } else {
        await SyncService.instance.enqueueRouteAction(
          type: e.type,
          userId: e.userId,
          lat: e.lat,
          lng: e.lng,
          actType: e.act_type,
          action: e.action,
          misc: e.misc,
          distId: e.dist_id,
        );
        emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.queued));
      }
    } catch (err, st) {
      debugPrint("checkin/checkout error: $err\n$st");
      await SyncService.instance.enqueueRouteAction(
        type: e.type,
        userId: e.userId,
        lat: e.lat,
        lng: e.lng,
        actType: e.act_type,
        action: e.action,
        misc: e.misc,
        distId: e.dist_id,
      );
      emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.queued));
    } finally {
      emit(state.copyWith(checkinCheckoutStatus: CheckinCheckoutStatus.initial));
    }
  }

  Future<void> activity(Activity event, Emitter<GlobalState> emit) async {
    emit(state.copyWith(activity: event.activity));
  }

  Future<void> coveredRoutesLength(CoveredRoutesLength event, Emitter<GlobalState> emit) async {
    emit(state.copyWith(routesCovered: event.lenght));
  }}