import 'package:equatable/equatable.dart';

// 모든 Failure의 기본이 되는 추상 클래스
// Equatable을 상속하여 Failure 객체 간의 값 기반 비교를 쉽게 할 수 있습니다.
abstract class Failure extends Equatable {
  final String message;
  final List<dynamic> properties; // 선택 사항: 디버깅 등을 위한 추가 정보

  const Failure({required this.message, this.properties = const []});

  @override
  List<Object?> get props => [message, properties];

  @override
  String toString() => '$runtimeType { message: $message, properties: $properties }';
}

// 일반적인 서버 오류 (예: 4xx, 5xx HTTP 상태 코드)
class ServerFailure extends Failure {
  const ServerFailure({required String message, List<dynamic> properties = const []})
      : super(message: message, properties: properties);
}

// 네트워크 연결 오류 (예: 인터넷 연결 없음)
class NetworkFailure extends Failure {
  const NetworkFailure({String message = '인터넷 연결을 확인해주세요.'}) : super(message: message);
}

// 캐시 오류 (예: 로컬 데이터 접근 실패)
class CacheFailure extends Failure {
  const CacheFailure({required String message, List<dynamic> properties = const []})
      : super(message: message, properties: properties);
}

// 입력값 유효성 검사 실패 등 일반적인 로컬 오류
class LocalValidationFailure extends Failure {
  const LocalValidationFailure({required String message, List<dynamic> properties = const []})
      : super(message: message, properties: properties);
}

// 특정 API에서 발생한 오류
class ApiFailure extends Failure {
  final int? statusCode; // API 응답 코드 등 추가 정보 포함 가능

  const ApiFailure({
    required String message,
    this.statusCode,
    List<dynamic> properties = const [],
  }) : super(message: message, properties: properties);

  @override
  List<Object?> get props => [message, statusCode, properties];
}

// 필요한 경우 더 구체적인 Failure 타입을 추가할 수 있습니다.
// 예: PermissionFailure, AuthenticationFailure 등
