import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'outbox_job.dart';


import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'outbox_job.dart';

class OutboxStorage {
  static const _k = 'outbox_v1';
  final _box = GetStorage();

  List<OutboxJob> load() {
    final raw = _box.read(_k);
    if (raw == null) return [];
    try {
      if (raw is String) {
        final list = (jsonDecode(raw) as List).cast<Map>();
        return list
            .map((m) => OutboxJob.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      } else if (raw is List) {
        return raw
            .cast<Map>()
            .map((m) => OutboxJob.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<OutboxJob> jobs) async {
    await _box.write(_k, jsonEncode(jobs.map((j) => j.toJson()).toList()));
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
    final i = list.indexWhere((j) => j.id == job.id);
    if (i != -1) {
      list[i] = job;
      await save(list);
    }
  }

  int count() => load().length;
}
