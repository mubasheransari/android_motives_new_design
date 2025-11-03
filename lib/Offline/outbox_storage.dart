// lib/Offline/outbox_storage.dart
import 'dart:convert';
import 'package:get_storage/get_storage.dart';

import 'outbox_job.dart';

/// Simple persistence layer for the offline outbox queue.
class OutboxStorage {
  static const String _key = 'outbox_v2';
  static bool _inited = false;

  final GetStorage _box = GetStorage();

  /// Call once in app start or from a background isolate.
  static Future<void> ensureInitialized() async {
    if (_inited) return;
    // If GetStorage was already initialized in main(), this is a no-op.
    await GetStorage.init();
    _inited = true;
  }

  List<OutboxJob> load() {
    final raw = _box.read(_key);
    if (raw == null) return <OutboxJob>[];

    try {
      // Support either a stored JSON string or a List<Map>.
      final List data = raw is String ? (jsonDecode(raw) as List) : (raw as List);
      return data
          .map((e) => OutboxJob.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return <OutboxJob>[];
    }
  }

  Future<void> save(List<OutboxJob> jobs) async {
    final encoded = jsonEncode(jobs.map((j) => j.toJson()).toList());
    await _box.write(_key, encoded);
  }

  Future<void> add(OutboxJob job) async {
    final list = load()..add(job);
    await save(list);
  }

  Future<void> remove(String id) async {
    final list = load()..removeWhere((j) => j.id == id);
    await save(list);
  }

  Future<void> update(OutboxJob job) async {
    final list = load();
    final idx = list.indexWhere((j) => j.id == job.id);
    if (idx != -1) {
      list[idx] = job;
      await save(list);
    }
  }

  int count() => load().length;
}
