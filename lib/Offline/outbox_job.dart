import 'dart:convert';


enum QueueKind { attendance, startRoute, routeAction }

class OutboxJob {
  final String id;
  final QueueKind kind;
  final Map<String, dynamic> fields;
  final DateTime createdAt;
  final int attempts;

  const OutboxJob({
    required this.id,
    required this.kind,
    required this.fields,
    required this.createdAt,
    this.attempts = 0,
  });

  OutboxJob copyWith({int? attempts}) =>
      OutboxJob(id: id, kind: kind, fields: fields, createdAt: createdAt, attempts: attempts ?? this.attempts);

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'fields': fields,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
      };

  static OutboxJob fromJson(Map<String, dynamic> j) => OutboxJob(
        id: j['id'] as String,
        kind: QueueKind.values.firstWhere((k) => k.name == j['kind']),
        fields: Map<String, dynamic>.from(j['fields'] as Map),
        createdAt: DateTime.parse(j['createdAt'] as String),
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
      );

  @override
  String toString() => jsonEncode(toJson());
}
