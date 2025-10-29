// lib/Offline/sync_service.dart
import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'; // ValueNotifier
import 'package:motives_new_ui_conversion/Repository/repository.dart';
import 'package:workmanager/workmanager.dart';
import 'package:uuid/uuid.dart';

import 'outbox_job.dart';
import 'outbox_storage.dart';

/// Events your UI can listen to (for progress dialog / badges etc.)
enum SyncEventType { started, itemSynced, completed, failed, idle }

class SyncEvent {
  final SyncEventType type;
  final int total;
  final int remaining;
  final OutboxJob? job;
  final String? message;

  const SyncEvent({
    required this.type,
    required this.total,
    required this.remaining,
    this.job,
    this.message,
  });

  @override
  String toString() =>
      'SyncEvent(type:$type total:$total remaining:$remaining job:${job?.kind} msg:$message)';
}

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final OutboxStorage _store = OutboxStorage();
  final _uuid = const Uuid();
  bool _syncing = false;
  bool _initialized = false;

  // ---------- Public observables ----------
  /// Emits progress (started / itemSynced / completed / failed).
  final StreamController<SyncEvent> _eventsCtl =
      StreamController<SyncEvent>.broadcast();
  Stream<SyncEvent> get events => _eventsCtl.stream;

  /// Live count of queued jobs (for badges).
  final ValueNotifier<int> pendingNotifier = ValueNotifier<int>(0);

  // ---------- Lifecycle ----------
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // keep initial count & emit idle
    _refreshPendingCount(emitIdle: true);

    // Foreground re-sync when connectivity changes
    Connectivity().onConnectivityChanged.listen((_) => trySync());

    // First attempt
    await trySync();
  }

  Future<void> registerBackgroundJobs() async {
    if (!Platform.isAndroid) return;

    await Workmanager().registerPeriodicTask(
      'taskoon.sync.periodic',
      'taskoonSync',
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 5),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints:  Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
  }

  /// More robust than DNS to example.com. Touches your own host.
  Future<bool> isOnlineNow() async {
    final c = await Connectivity().checkConnectivity();
    if (c == ConnectivityResult.none) return false;

    try {
      final repo = Repository();
      final uri = Uri.parse(repo.loginUrl); // same host as your APIs
      final addrs = await InternetAddress.lookup(uri.host);
      if (addrs.isEmpty) return false;

      // Quick GET / with 1.5s timeout to verify routing
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
      try {
        final req = await client.getUrl(Uri(
          scheme: uri.scheme,
          host: uri.host,
          port: uri.port == 0 ? (uri.scheme == 'https' ? 443 : 80) : uri.port,
          path: '/',
        ));
        req.headers.set(HttpHeaders.userAgentHeader, 'motives-ping');
        final resp = await req.close().timeout(const Duration(milliseconds: 1500));
        return resp.statusCode < 500; // 200/301/403 are fine
      } catch (_) {
        // Might be blocked but DNS worked — likely online
        return true;
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> enqueueOrder({
  required String endpoint,
  required Map<String, dynamic> payload,
  required String requestField,
  Map<String, String>? headers,
  required String userId,
  required String distId,
  required String orderId, // for linking to OrdersStorage entries
}) async {
  await _store.add(OutboxJob(
    id: _uuid.v4(),
    kind: QueueKind.order,
    fields: {
      'endpoint': endpoint,
      'payload': payload,
      'requestField': requestField,
      'headers': headers ?? <String, String>{},
      'userId': userId,
      'distId': distId,
      'orderId': orderId,
    },
    createdAt: DateTime.now(),
  ));
  _refreshPendingCount(emitIdle: true);
}


  // ---------- Enqueue APIs ----------
  Future<void> enqueueAttendance({
    required String type,
    required String userId,
    required String lat,
    required String lng,
    required String action,
    required String distId,
  }) async {
    await _store.add(OutboxJob(
      id: _uuid.v4(),
      kind: QueueKind.attendance,
      fields: {
        'type': type,
        'userId': userId,
        'lat': lat,
        'lng': lng,
        'action': action,
        'dist_id': distId,
      },
      createdAt: DateTime.now(),
    ));
    _refreshPendingCount(emitIdle: true);
  }

  Future<void> enqueueStartRoute({
    required String type,
    required String userId,
    required String lat,
    required String lng,
    required String action,
    required String disid,
  }) async {
    await _store.add(OutboxJob(
      id: _uuid.v4(),
      kind: QueueKind.startRoute,
      fields: {
        'type': type,
        'userId': userId,
        'lat': lat,
        'lng': lng,
        'action': action,
        'dist_id': disid,
      },
      createdAt: DateTime.now(),
    ));
    _refreshPendingCount(emitIdle: true);
  }

  Future<void> enqueueRouteAction({
    required String type,
    required String userId,
    required String lat,
    required String lng,
    required String actType,
    required String action,
    required String misc,
    required String distId,
    String pic = "0",
  }) async {
    await _store.add(OutboxJob(
      id: _uuid.v4(),
      kind: QueueKind.routeAction,
      fields: {
        'type': type,
        'userId': userId,
        'lat': lat,
        'lng': lng,
        'act_type': actType,
        'action': action,
        'misc': misc,
        'dist_id': distId,
        'pic': pic,
      },
      createdAt: DateTime.now(),
    ));
    _refreshPendingCount(emitIdle: true);
  }

  // ---------- Sync core ----------
  Future<void> trySync() async {
    if (_syncing) return;
    _syncing = true;
    try {
      if (!await isOnlineNow()) return;

      final repo = Repository();
      final jobs = _store.load();
      if (jobs.isEmpty) {
        _refreshPendingCount(emitIdle: true);
        return;
      }

      // announce start
      _emit(SyncEvent(
        type: SyncEventType.started,
        total: jobs.length,
        remaining: jobs.length,
      ));

      var remaining = jobs.length;
      for (final job in List<OutboxJob>.from(jobs)) {
        final ok = await _sendJob(repo, job);
        if (ok) {
          await _store.remove(job.id);
          remaining--;
          _emit(SyncEvent(
            type: SyncEventType.itemSynced,
            total: jobs.length,
            remaining: remaining,
            job: job,
          ));
        } else {
          await _store.update(job.copyWith(attempts: job.attempts + 1));
          // do not decrement remaining; we'll retry next time
        }
      }

      // finished cycle
      _refreshPendingCount();
      _emit(SyncEvent(
        type: SyncEventType.completed,
        total: jobs.length,
        remaining: _store.count(),
      ));
    } catch (e, st) {
      debugPrint('trySync error: $e\n$st');
      _emit(SyncEvent(
        type: SyncEventType.failed,
        total: pendingNotifier.value,
        remaining: pendingNotifier.value,
        message: e.toString(),
      ));
    } finally {
      _syncing = false;
    }
  }

  Future<bool> _sendJob(Repository repo, OutboxJob job) async {
    try {
      switch (job.kind) {

         case QueueKind.order: {
        final f = job.fields;

        // cast headers safely
        Map<String, String>? _hdrs;
        final h = f['headers'];
        if (h is Map) {
          _hdrs = h.map((k, v) => MapEntry(k.toString(), v.toString()));
        }

        final res = await repo.postLegacyFormEncoded(
          url: f['endpoint'] as String,
          payload: Map<String, dynamic>.from(f['payload'] as Map),
          requestField: (f['requestField'] as String?) ?? 'request',
          extraHeaders: _hdrs,
        );

        final ok = res.statusCode == 200;

        // Optional: if success, you can also mark/update OrdersStorage status here
        // using f['userId'], f['orderId'] etc., if you want to flip "Queued" → "Success"

        return ok;
      }
        case QueueKind.attendance:
          {
            final f = job.fields;
            final res = await repo.attendance(
              f['type'],
              f['userId'],
              f['lat'],
              f['lng'],
              f['action'],
              f['dist_id'],
            );
            return res.statusCode == 200;
          }
        case QueueKind.startRoute:
          {
            final f = job.fields;
            final res = await repo.startRouteApi(
              f['type'],
              f['userId'],
              f['lat'],
              f['lng'],
              f['action'],
              f['dist_id'],
            );
            return res.statusCode == 200;
          }
        case QueueKind.routeAction:
          {
            final f = job.fields;
            final res = await repo.checkin_checkout(
              f['type'],
              f['userId'],
              f['lat'],
              f['lng'],
              f['act_type'],
              f['action'],
              f['misc'],
              f['dist_id'],
            );
            return res.statusCode == 200;
          }
      }
    } catch (e, st) {
      debugPrint('sendJob error: $e\n$st');
      return false;
    }
  }

  // ---------- helpers ----------
  void _refreshPendingCount({bool emitIdle = false}) {
    final c = _store.count();
    pendingNotifier.value = c;
    if (emitIdle) {
      _emit(SyncEvent(type: SyncEventType.idle, total: c, remaining: c));
    }
  }

  void _emit(SyncEvent e) {
    if (!_eventsCtl.isClosed) {
      _eventsCtl.add(e);
    }
  }
}
