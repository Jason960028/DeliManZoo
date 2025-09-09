import '../../domain/entities/restaurant_entity.dart'; // RestaurantEntity 임포트

class RestaurantModel extends RestaurantEntity {
  const RestaurantModel({
    required String placeId,
    required String name,
    required String address,
    required double lat,
    required double lng,
    required double rating,
    String? photoReference,
    String? phoneNumber,
    String? website,
    List<String>? photos,
    List<String>? types,
    Map<String, dynamic>? openingHours,
    bool? openNow,
    int? priceLevel,
    String? formattedAddress,
  }) : super(
    placeId: placeId,
    name: name,
    address: address,
    lat: lat,
    lng: lng,
    rating: rating,
    photoReference: photoReference,
    phoneNumber: phoneNumber,
    website: website,
    photos: photos,
    types: types,
    openingHours: openingHours,
    openNow: openNow,
    priceLevel: priceLevel,
    formattedAddress: formattedAddress,
  );

  // Google Places Nearby Search API의 JSON 응답을 파싱하기 위한 팩토리 생성자
  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    // rating 필드가 null일 경우 기본값 0.0으로 처리 (API 응답에 따라 null이 올 수 있음)
    final ratingValue = json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0;
    // vicinity가 null일 경우 빈 문자열로 처리 (API 응답에 따라 없을 수 있음)
    final addressValue = json['vicinity'] ?? '';

    return RestaurantModel(
      // 'place_id'는 API 응답에서 snake_case로 오므로 정확히 매핑
      placeId: json['place_id'] as String,
      name: json['name'] as String,
      // 'vicinity'는 주소 정보로 사용
      address: addressValue,
      // 'geometry.location.lat'와 'geometry.location.lng'에서 위도와 경도 추출
      lat: (json['geometry']['location']['lat'] as num).toDouble(),
      lng: (json['geometry']['location']['lng'] as num).toDouble(),
      rating: ratingValue,
    );
  }

  // Google Places Details API의 JSON 응답을 파싱하기 위한 팩토리 생성자
  factory RestaurantModel.fromDetailsJson(Map<String, dynamic> json) {
    final ratingValue = json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0;
    final addressValue = json['vicinity'] ?? json['formatted_address'] ?? '';
    
    // 사진 처리
    final List<String>? photos = json['photos'] != null 
        ? (json['photos'] as List).map((photo) => photo['photo_reference'] as String).toList()
        : null;
    
    // 타입 처리
    final List<String>? types = json['types'] != null 
        ? (json['types'] as List).cast<String>()
        : null;
    
    // 영업시간 처리
    Map<String, dynamic>? openingHours;
    bool? openNow;
    if (json['opening_hours'] != null) {
      openingHours = Map<String, dynamic>.from(json['opening_hours']);
      openNow = json['opening_hours']['open_now'];
    }

    return RestaurantModel(
      placeId: json['place_id'] as String,
      name: json['name'] as String,
      address: addressValue,
      lat: (json['geometry']['location']['lat'] as num).toDouble(),
      lng: (json['geometry']['location']['lng'] as num).toDouble(),
      rating: ratingValue,
      photoReference: photos?.isNotEmpty == true ? photos!.first : null,
      phoneNumber: json['formatted_phone_number'],
      website: json['website'],
      photos: photos,
      types: types,
      openingHours: openingHours,
      openNow: openNow,
      priceLevel: json['price_level'],
      formattedAddress: json['formatted_address'],
    );
  }

  // (선택 사항) 객체를 JSON으로 변환하는 toJson 메서드 (API 요청 시 필요할 수 있음)
  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'name': name,
      'vicinity': address, // 또는 'address': address, API 스펙에 따라
      'geometry': {
        'location': {
          'lat': lat,
          'lng': lng,
        },
      },
      'rating': rating,
    };
  }
}
