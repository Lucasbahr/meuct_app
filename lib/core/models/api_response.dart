class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic raw)? dataParser,
  }) {
    final rawData = json["data"];
    return ApiResponse<T>(
      success: json["success"] == true,
      message: (json["message"] ?? "").toString(),
      data: dataParser != null ? dataParser(rawData) : rawData as T?,
    );
  }
}
