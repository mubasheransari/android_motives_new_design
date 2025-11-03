// lib/Offline/outbox_job.dart
import 'dart:convert';

/// Types of queued work the Outbox/SyncService can send.
enum QueueKind { attendance, startRoute, routeAction, order }

/// One unit of offline work to be synced later.
class OutboxJob {
  /// Unique id for this job (e.g., uuid v4).
  final String id;

  /// The queue bucket / handler this job belongs to.
  final QueueKind kind;

  /// Arbitrary payload for the handler. Must be JSON-serializable.
  final Map<String, dynamic> fields;

  /// When the job was created.
  final DateTime createdAt;

  /// How many send attempts have been made.
  final int attempts;

  /// Optional: last error message captured by the sender.
  final String? lastError;

  /// Optional: do not attempt before this time (exponential backoff).
  final DateTime? nextAttemptAt;

  /// Schema version (for future migrations).
  final int version;

  const OutboxJob({
    required this.id,
    required this.kind,
    required this.fields,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
    this.nextAttemptAt,
    this.version = 1,
  });

  /// Copy-with helper.
  OutboxJob copyWith({
    String? id,
    QueueKind? kind,
    Map<String, dynamic>? fields,
    DateTime? createdAt,
    int? attempts,
    String? lastError,
    DateTime? nextAttemptAt,
    int? version,
  }) {
    return OutboxJob(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      fields: fields ?? this.fields,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      version: version ?? this.version,
    );
  }

  /// Whether the job is ready to be attempted now (ignores network state).
  bool isDue([DateTime? now]) {
    final n = now ?? DateTime.now();
    return nextAttemptAt == null || !nextAttemptAt!.isAfter(n);
  }

  /// Increment attempts and schedule the next retry using backoff.
  OutboxJob bumpFailure({
    String? error,
    DateTime? now,
  }) {
    final a = attempts + 1;
    final when = _computeNextAttempt(a, now ?? DateTime.now());
    return copyWith(
      attempts: a,
      lastError: error ?? lastError,
      nextAttemptAt: when,
    );
  }

  /// Clear error and backoff timing (use after a successful send).
  OutboxJob clearFailure() => copyWith(lastError: null, nextAttemptAt: null);

  /// Serialize to a stable JSON shape.
  Map<String, dynamic> toJson() => {
        'v': version,
        'id': id,
        'kind': kind.name,
        'fields': fields,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
        if (lastError != null) 'lastError': lastError,
        if (nextAttemptAt != null) 'nextAttemptAt': nextAttemptAt!.toIso8601String(),
      };

  /// Backward/forward compatible deserializer.
  static OutboxJob fromJson(Map<String, dynamic> j) {
    final v = (j['v'] as num?)?.toInt() ?? 1;
    final kind = _parseKind(j['kind']);
    final fields = _parseFields(j['fields']);
    final created = _parseDate(j['createdAt']) ?? DateTime.now();
    final attempts = (j['attempts'] as num?)?.toInt() ?? 0;
    final lastErr = (j['lastError'] is String) ? j['lastError'] as String : null;
    final nextAt = _parseDate(j['nextAttemptAt']);

    return OutboxJob(
      id: (j['id'] ?? '').toString(),
      kind: kind,
      fields: fields,
      createdAt: created,
      attempts: attempts,
      lastError: lastErr,
      nextAttemptAt: nextAt,
      version: v,
    );
  }

  /// String representation (compact JSON).
  @override
  String toString() => jsonEncode(toJson());

  // ---------------------------------------------------------------------------
  // Convenience builders for each QueueKind (keeps callsites tidy)
  // ---------------------------------------------------------------------------

  /// Queue an attendance job.
  ///
  /// Expected by SyncService:
  ///   fields: {type, userId, lat, lng, action, dist_id}
  factory OutboxJob.attendance({
    required String id,
    required String type,
    required String userId,
    required String lat,
    required String lng,
    required String action,
    required String distId,
    DateTime? createdAt,
  }) {
    return OutboxJob(
      id: id,
      kind: QueueKind.attendance,
      fields: {
        'type': type,
        'userId': userId,
        'lat': lat,
        'lng': lng,
        'action': action,
        'dist_id': distId,
      },
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Queue a startRoute job.
  ///
  /// Expected by SyncService:
  ///   fields: {type, userId, lat, lng, action, dist_id}
  factory OutboxJob.startRoute({
    required String id,
    required String type,
    required String userId,
    required String lat,
    required String lng,
    required String action,
    required String distId,
    DateTime? createdAt,
  }) {
    return OutboxJob(
      id: id,
      kind: QueueKind.startRoute,
      fields: {
        'type': type,
        'userId': userId,
        'lat': lat,
        'lng': lng,
        'action': action,
        'dist_id': distId,
      },
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Queue a routeAction job.
  ///
  /// Expected by SyncService:
  ///   fields: {type, userId, lat, lng, act_type, action, misc, dist_id, pic}
  factory OutboxJob.routeAction({
    required String id,
    required String type,
    required String userId,
    required String lat,
    required String lng,
    required String actType,
    required String action,
    required String misc,
    required String distId,
    String pic = '0',
    DateTime? createdAt,
  }) {
    return OutboxJob(
      id: id,
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
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Queue an order job.
  ///
  /// Expected by SyncService:
  ///   fields: {endpoint, payload, requestField, headers, userId, distId, orderId}
  factory OutboxJob.order({
    required String id,
    required String endpoint,
    required Map<String, dynamic> payload,
    String requestField = 'request',
    Map<String, String>? headers,
    required String userId,
    required String distId,
    required String orderId,
    DateTime? createdAt,
  }) {
    return OutboxJob(
      id: id,
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
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  static QueueKind _parseKind(dynamic v) {
    if (v is QueueKind) return v;
    if (v is String) {
      final name = v.trim();
      for (final k in QueueKind.values) {
        if (k.name == name) return k;
      }
      // legacy: sometimes enums were saved as index strings
      final asInt = int.tryParse(name);
      if (asInt != null && asInt >= 0 && asInt < QueueKind.values.length) {
        return QueueKind.values[asInt];
      }
    }
    if (v is num) {
      final i = v.toInt();
      if (i >= 0 && i < QueueKind.values.length) {
        return QueueKind.values[i];
      }
    }
    // Fallback to safest handler
    return QueueKind.routeAction;
  }

  static Map<String, dynamic> _parseFields(dynamic v) {
    if (v == null) return <String, dynamic>{};
    if (v is Map<String, dynamic>) return v;
    if (v is Map) {
      return v.map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    // if it was stringified JSON
    if (v is String) {
      try {
        final d = jsonDecode(v);
        if (d is Map) {
          return d.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v);
      } catch (_) {}
    }
    return null;
    }

  /// Simple capped exponential backoff schedule.
  static DateTime _computeNextAttempt(int attempt, DateTime base) {
    // attempt: 1 → 5s, 2 → 30s, 3 → 2m, 4 → 5m, 5 → 15m, 6+ → 60m
    const table = <Duration>[
      Duration(seconds: 5),
      Duration(seconds: 30),
      Duration(minutes: 2),
      Duration(minutes: 5),
      Duration(minutes: 15),
      Duration(hours: 1),
    ];
    final idx = attempt <= 0 ? 0 : (attempt - 1);
    final d = idx < table.length ? table[idx] : table.last;
    return base.add(d);
  }
}
