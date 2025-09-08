import 'package:geolocator/geolocator.dart';

class LocationService {
  /// 사용자의 현재 위치를 가져옵니다.
  ///
  /// 위치 권한이 없거나 비활성화된 경우 예외를 발생시킬 수 있습니다.
  /// 적절한 오류 처리가 필요합니다.
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. 위치 서비스 활성화 여부 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 위치 서비스가 비활성화되어 있으면 사용자에게 활성화를 요청할 수 있습니다.
      // Geolocator.openLocationSettings(); // 직접 설정으로 보내는 방법
      return Future.error('위치 서비스가 비활성화되어 있습니다.');
    }

    // 2. 현재 위치 권한 상태 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // 권한이 거부된 상태면 새로 권한 요청
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // 권한 요청이 다시 거부된 경우
        return Future.error('위치 권한이 거부되었습니다.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // 권한이 영구적으로 거부된 경우, 사용자가 직접 앱 설정에서 변경해야 함
      // Geolocator.openAppSettings(); // 직접 앱 설정으로 보내는 방법
      return Future.error('위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 권한을 허용해주세요.');
    }

    // 3. 권한이 허용된 경우, 현재 위치 가져오기
    // desiredAccuracy는 정확도를 설정합니다. (예: LocationAccuracy.high)
    // forceAndroidLocationManager는 Android에서 FusedLocationProvider 대신 LocationManager를 강제로 사용할지 여부입니다. (일반적으로 false)
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium); // 필요에 따라 정확도 조절
  }

// 스트림으로 위치 업데이트를 받을 수도 있습니다. (필요하다면)
// Stream<Position> getPositionStream() {
//   final LocationSettings locationSettings = LocationSettings(
//     accuracy: LocationAccuracy.high,
//     distanceFilter: 100, // 100미터 이동 시 업데이트
//   );
//   return Geolocator.getPositionStream(locationSettings: locationSettings);
// }
}
