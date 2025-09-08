// core/error/exceptions.dart
class ServerException implements Exception {
  final String message;
  final int? statusCode; // 선택 사항: HTTP 상태 코드 등 추가 정보

  ServerException({required this.message, this.statusCode});

  @override
  String toString() {
    return 'ServerException: $message ${statusCode != null ? "(Status Code: $statusCode)" : ""}';
  }
}

// 필요에 따라 다른 Exception 타입도 추가할 수 있습니다.
// class CacheException implements Exception {}
// class NetworkException implements Exception {}

