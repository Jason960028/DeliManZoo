import 'package:equatable/equatable.dart';

class RestaurantEntity extends Equatable {
  final String placeId; // Google Places API의 place_id
  final String name;
  final String address; // Google Places API에서는 'vicinity' 또는 상세 정보의 'formatted_address'
  final double lat;
  final double lng;
  final double rating;
  final String? photoReference; // 사진 참조 ID (선택 사항, Google Places Photos API 사용 시 필요)
  final String? phoneNumber;    // 전화번호 필드 (선택 사항, nullable)
  final String? website;        // 웹사이트 URL
  final List<String>? photos;   // 사진 참조 ID 목록
  final List<String>? types;    // 레스토랑 카테고리/타입
  final Map<String, dynamic>? openingHours; // 영업시간 정보
  final bool? openNow;          // 현재 영업 중 여부
  final int? priceLevel;        // 가격 수준 (0-4)
  final String? formattedAddress; // 완전한 주소

  const RestaurantEntity({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.rating,
    this.photoReference,     // 선택적 파라미터로 변경
    this.phoneNumber,        // 선택적 파라미터로 변경
    this.website,
    this.photos,
    this.types,
    this.openingHours,
    this.openNow,
    this.priceLevel,
    this.formattedAddress,
  });

  @override
  List<Object?> get props => [
    placeId,
    name,
    address,
    lat,
    lng,
    rating,
    photoReference,
    phoneNumber,
    website,
    photos,
    types,
    openingHours,
    openNow,
    priceLevel,
    formattedAddress,
  ];

  @override
  String toString() {
    return 'RestaurantEntity(placeId: $placeId, name: $name, address: $address, lat: $lat, lng: $lng, rating: $rating, photoReference: $photoReference, phoneNumber: $phoneNumber, website: $website, photos: $photos, types: $types, openingHours: $openingHours, openNow: $openNow, priceLevel: $priceLevel, formattedAddress: $formattedAddress)';
  }

  RestaurantEntity copyWith({
    String? placeId,
    String? name,
    String? address,
    double? lat,
    double? lng,
    double? rating,
    String? photoReference,
    String? phoneNumber,
    String? website,
    List<String>? photos,
    List<String>? types,
    Map<String, dynamic>? openingHours,
    bool? openNow,
    int? priceLevel,
    String? formattedAddress,
  }) {
    return RestaurantEntity(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      rating: rating ?? this.rating,
      photoReference: photoReference ?? this.photoReference,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      photos: photos ?? this.photos,
      types: types ?? this.types,
      openingHours: openingHours ?? this.openingHours,
      openNow: openNow ?? this.openNow,
      priceLevel: priceLevel ?? this.priceLevel,
      formattedAddress: formattedAddress ?? this.formattedAddress,
    );
  }
}

