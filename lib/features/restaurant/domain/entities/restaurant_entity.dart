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

  const RestaurantEntity({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.rating,
    this.photoReference,     // 선택적 파라미터로 변경
    this.phoneNumber,        // 선택적 파라미터로 변경
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
  ];

  @override
  String toString() {
    return 'RestaurantEntity(placeId: $placeId, name: $name, address: $address, lat: $lat, lng: $lng, rating: $rating, photoReference: $photoReference, phoneNumber: $phoneNumber)';
  }

  RestaurantEntity copyWith({
    String? placeId,
    String? name,
    String? address,
    double? lat,
    double? lng,
    double? rating,
    String? photoReference, // copyWith에도 추가
    String? phoneNumber,    // copyWith에도 추가
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
    );
  }
}

