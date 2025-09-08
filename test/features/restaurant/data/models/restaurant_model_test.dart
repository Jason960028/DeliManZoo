import 'package:flutter_test/flutter_test.dart';
// 실제 RestaurantModel 파일 경로로 수정해야 합니다.
import 'package:delimanzoo/features/restaurant/data/models/restaurant_model.dart';

void main() {
  group('RestaurantModel', () {
    test('fromJson should correctly parse JSON', () {
      // Given
      final Map<String, dynamic> sampleJson = {
        "geometry": {
          "location": {"lat": 37.4219983, "lng": -122.084}
        },
        "name": "Googleplex",
        "place_id": "ChIJN1t_tDeuEmsRUsoyG83frY4",
        "rating": 4.5,
        "vicinity": "1600 Amphitheatre Parkway, Mountain View"
      };

      // When
      final result = RestaurantModel.fromJson(sampleJson);

      // Then
      expect(result.placeId, equals("ChIJN1t_tDeuEmsRUsoyG83frY4"));
      expect(result.name, equals("Googleplex"));
      expect(result.address, equals("1600 Amphitheatre Parkway, Mountain View"));
      expect(result.lat, equals(37.4219983));
      expect(result.lng, equals(-122.084));
      expect(result.rating, equals(4.5));
    });

    // rating이 null인 경우, vicinity가 null인 경우 등 다양한 케이스에 대한 테스트 추가 가능
    test('fromJson should handle null rating and vicinity', () {
      // Given
      final Map<String, dynamic> sampleJsonWithNulls = {
        "geometry": {
          "location": {"lat": 37.0, "lng": -122.0}
        },
        "name": "Null Cafe",
        "place_id": "test_place_id_nulls",
        "rating": null, // rating이 null
        "vicinity": null // vicinity가 null
      };
      // When
      final result = RestaurantModel.fromJson(sampleJsonWithNulls);

      // Then
      expect(result.placeId, equals("test_place_id_nulls"));
      expect(result.name, equals("Null Cafe"));
      expect(result.address, equals("")); // null일 때 빈 문자열로 처리했으므로
      expect(result.lat, equals(37.0));
      expect(result.lng, equals(-122.0));
      expect(result.rating, equals(0.0)); // null일 때 0.0으로 처리했으므로
    });
  });
}

