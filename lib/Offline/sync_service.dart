import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:motives_new_ui_conversion/Repository/repository.dart';
import 'package:uuid/uuid.dart';
import 'outbox_job.dart';
import 'outbox_storage.dart';



class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final OutboxStorage _store = OutboxStorage();
  final _uuid = const Uuid();
  bool _syncing = false;

  Future<void> init() async {
    Connectivity().onConnectivityChanged.listen((_) => trySync());
    await trySync(); 
  }

  Future<bool> isOnlineNow() async {
    final c = await Connectivity().checkConnectivity();
    if (c == ConnectivityResult.none) return false;
    try {
      final res = await InternetAddress.lookup('example.com');
      return res.isNotEmpty;
    } catch (_) {
      return true; 
    }
  }


  Future<void> enqueueAttendance({
    required String type,
    required String userId,
    required String lat,
    required String lng,
    required String action,
  }) async {
    await _store.add(OutboxJob(
      id: _uuid.v4(),
      kind: QueueKind.attendance,
      fields: {'type': type, 'userId': userId, 'lat': lat, 'lng': lng, 'action': action},
      createdAt: DateTime.now(),
    ));
  }

  Future<void> enqueueStartRoute({
    required String type,
    required String userId,
    required String lat,
    required String lng,
    required String action,
  }) async {
    await _store.add(OutboxJob(
      id: _uuid.v4(),
      kind: QueueKind.startRoute,
      fields: {'type': type, 'userId': userId, 'lat': lat, 'lng': lng, 'action': action},
      createdAt: DateTime.now(),
    ));
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
  }


  Future<void> trySync() async {
    if (_syncing) return;
    _syncing = true;
    try {
      if (!await isOnlineNow()) return;

      final repo = Repository();
      var jobs = _store.load();
      if (jobs.isEmpty) return;

      for (final job in List<OutboxJob>.from(jobs)) {
        final ok = await _sendJob(repo, job);
        if (ok) {
          await _store.remove(job.id);
        } else {
          await _store.update(job.copyWith(attempts: job.attempts + 1));
        }
      }
    } finally {
      _syncing = false;
    }
  }

  Future<bool> _sendJob(Repository repo, OutboxJob job) async {
    switch (job.kind) {
      case QueueKind.attendance: {
        final f = job.fields;
        final res = await repo.attendance(f['type'], f['userId'], f['lat'], f['lng'], f['action']);
        return res.statusCode == 200;
      }
      case QueueKind.startRoute: {
        final f = job.fields;
        final res = await repo.startRouteApi(f['type'], f['userId'], f['lat'], f['lng'], f['action']);
        return res.statusCode == 200;
      }
      case QueueKind.routeAction: {
        final f = job.fields;
        final res = await repo.checkin_checkout(
          f['type'], f['userId'], f['lat'], f['lng'],
          f['act_type'], f['action'], f['misc'], f['dist_id'],
          //pic: f['pic'] ?? "0",
        );
        if (res.statusCode != 200) return false;
        return true;
      }
    }
  }

  int pendingCount() => _store.count();
}
