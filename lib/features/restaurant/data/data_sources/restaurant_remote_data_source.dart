import 'dart:convert'; // JSON 파싱을 위해 필요
import 'package:http/http.dart' as http; // HTTP 요청을 위해 필요
import '../../../../core/error/exceptions.dart'; // ServerException 임포트
import '../models/restaurant_model.dart'; // 응답 파싱 및 반환 타입으로 사용될 수 있음

// 데이터 소스의 추상 클래스(인터페이스)
abstract class RestaurantRemoteDataSource {
  /// 지정된 위도, 경도 주변의 음식점 목록을 가져옵니다.
  ///
  /// 성공 시 [RestaurantModel] 리스트를 반환합니다.
  /// 실패 시 [ServerException]을 throw 합니다.
  Future<List<RestaurantModel>> getNearbyRestaurants(
      double lat, double lng, String apiKey);

  Future<List<RestaurantModel>> searchRestaurants(
      String query, String apiKey);
  
  /// 특정 place_id에 대한 상세 정보를 가져옵니다.
  Future<RestaurantModel> getRestaurantDetails(String placeId, String apiKey);
}

// RestaurantRemoteDataSource의 구현체
class RestaurantRemoteDataSourceImpl implements RestaurantRemoteDataSource {
  final http.Client client; // HTTP 클라이언트 주입
  final String apiKey;
  final String _baseUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  RestaurantRemoteDataSourceImpl({required this.client, required this.apiKey});

  @override
  Future<List<RestaurantModel>> getNearbyRestaurants(
      double lat, double lng, String apiKey) async {
    // API 요청 URL 구성
    // 필수 파라미터: location, radius, key
    // type=restaurant, rankby=distance 등 다양한 옵션 추가 가능 (여기서는 기본 radius 사용)
    // rankby=distance를 사용하려면 keyword, name, or type 중 하나가 필수이며 radius는 사용 불가
    final radius = 5000; // 예: 5km 반경 (단위: 미터)
    final type = 'restaurant'; // 음식점으로 타입 지정

    // Google Places API Nearby Search URL (GET 요청)
    // rankby=prominence (기본값, radius 필수)
    final url = Uri.parse(
        '$_baseUrl?location=$lat,$lng&radius=$radius&type=$type&key=$apiKey&language=ko');

    // 만약 rankby=distance를 사용하고 싶다면 (keyword, name, or type 중 하나 필수, radius 사용 불가)
    // final keyword = "음식점"; // 또는 name, type
    // final url = Uri.parse('$_baseUrl?location=$lat,$lng&rankby=distance&keyword=$keyword&key=$apiKey&language=ko');

    print('🔍 [DEBUG] Making API request to: $url');
    
    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('🔍 [DEBUG] API Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        print('🔍 [DEBUG] API Response Body Keys: ${responseBody.keys.toList()}');
        
        if (responseBody['error_message'] != null) {
          print('🔍 [DEBUG] API Error Message: ${responseBody['error_message']}');
        }
        
        if (responseBody['status'] != null) {
          print('🔍 [DEBUG] API Status: ${responseBody['status']}');
        }
        
        // Check if status is OK before processing results
        if (responseBody['status'] != 'OK') {
          String errorMsg = responseBody['error_message'] ?? 'API returned status: ${responseBody['status']}';
          print('🔍 [DEBUG] API request failed: $errorMsg');
          throw ServerException(message: errorMsg, statusCode: response.statusCode);
        }
        
        // API 응답 구조에 따라 'results' 키에서 리스트를 가져옵니다.
        final List<dynamic> results = responseBody['results'] ?? [];
        print('🔍 [DEBUG] Found ${results.length} restaurants in API response');
        
        // 각 JSON 객체를 RestaurantModel로 변환
        final restaurants = results
            .map((jsonItem) => RestaurantModel.fromJson(jsonItem))
            .toList();
            
        print('🔍 [DEBUG] Successfully parsed ${restaurants.length} restaurants');
        return restaurants;
      } else {
        // 200 OK가 아닌 경우, 에러 메시지와 상태 코드를 포함하여 ServerException 발생
        // API 응답 바디에 에러 메시지가 포함되어 있을 수 있으므로 확인 (예: responseBody['error_message'])
        String errorMessage = 'API 요청 실패';
        try {
          final responseBody = json.decode(response.body);
          print('🔍 [DEBUG] Error response body: $responseBody');
          if (responseBody['error_message'] != null) {
            errorMessage = responseBody['error_message'];
          } else if (responseBody['status'] != null && responseBody['status'] != 'OK') {
            errorMessage = 'API Status: ${responseBody['status']}';
          }
        } catch (e) {
          // JSON 파싱 실패 시, 기본 에러 메시지 사용
          print('🔍 [DEBUG] Failed to parse error response: $e');
        }
        throw ServerException(message: errorMessage, statusCode: response.statusCode);
      }
    } on http.ClientException catch (e) {
      // http 패키지에서 발생하는 네트워크 관련 예외 처리
      print('🔍 [DEBUG] HTTP Client Exception: ${e.message}');
      throw ServerException(message: '네트워크 오류: ${e.message}');
    } catch (e) {
      // 기타 예외 (예: json.decode 실패 등)
      print('🔍 [DEBUG] Unexpected error: ${e.toString()}');
      throw ServerException(message: '알 수 없는 오류 발생: ${e.toString()}');
    }
  }

  @override
  Future<List<RestaurantModel>> searchRestaurants(
      String query, String apiKey) async {
    final textSearchUrl =
      'https://maps.googleapis.com/maps/api/place/textsearch/json';
    final url = Uri.parse('$textSearchUrl?query=$query&key=$apiKey&language=ko&type=restaurant');

    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final List<dynamic> results = responseBody['results'];
        return results
            .map((jsonItem) => RestaurantModel.fromJson(jsonItem))
            .toList();
      } else {
        String errorMessage = 'API 요청 실패';
        try {
          final responseBody = json.decode(response.body);
          if (responseBody['error_message'] != null) {
            errorMessage = responseBody['error_message'];
          } else if (responseBody['status'] != null && responseBody['status'] != 'OK') {
            errorMessage = 'API Status: ${responseBody['status']}';
          }
        } catch (e) {
          // JSON 파싱 실패 시, 기본 에러 메시지 사용
        }
        throw ServerException(message: errorMessage, statusCode: response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw ServerException(message: '네트워크 오류: ${e.message}');
    } catch (e) {
      throw ServerException(message: '알 수 없는 오류 발생: ${e.toString()}');
    }
  }

  @override
  Future<RestaurantModel> getRestaurantDetails(String placeId, String apiKey) async {
    final detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json';
    final fields = 'place_id,name,formatted_address,geometry,rating,formatted_phone_number,website,photos,types,opening_hours,price_level,vicinity';
    final url = Uri.parse('$detailsUrl?place_id=$placeId&fields=$fields&key=$apiKey&language=ko');

    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final result = responseBody['result'];
        if (result == null) {
          throw ServerException(message: "API 응답에서 'result'를 찾을 수 없습니다.", statusCode: response.statusCode);
        }
        return RestaurantModel.fromDetailsJson(result);
      } else {
        String errorMessage = 'API 요청 실패';
        try {
          final responseBody = json.decode(response.body);
          if (responseBody['error_message'] != null) {
            errorMessage = responseBody['error_message'];
          } else if (responseBody['status'] != null && responseBody['status'] != 'OK') {
            errorMessage = 'API Status: ${responseBody['status']}';
          }
        } catch (e) {
          // JSON 파싱 실패 시, 기본 에러 메시지 사용
        }
        throw ServerException(message: errorMessage, statusCode: response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw ServerException(message: '네트워크 오류: ${e.message}');
    } catch (e) {
      throw ServerException(message: '알 수 없는 오류 발생: ${e.toString()}');
    }
  }
}

