class OrderSubmitResult {
  final bool success;
  final int statusCode;
  final String rawBody;
  final Map<String, dynamic>? json;
  final String? serverMessage;

  const OrderSubmitResult({
    required this.success,
    required this.statusCode,
    required this.rawBody,
    required this.json,
    required this.serverMessage,
  });
}
