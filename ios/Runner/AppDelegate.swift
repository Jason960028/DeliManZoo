import Flutter
import UIKit
import GoogleMaps // GoogleMaps import 추가
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
  // Info.plist에서 API 키 읽어오기
          if let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String {
            GMSServices.provideAPIKey(mapsApiKey)
            print("iOS Maps API Key loaded successfully from Info.plist (via xcconfig)")
          } else {
            print("Error: GOOGLE_MAPS_API_KEY not found in Info.plist. Check configuration.")
            // 여기에 API 키 로드 실패 시 대체 로직이나 오류 처리를 추가할 수 있습니다.
            // 예를 들어, 기본 (제한된) 키를 사용하거나, 기능을 비활성화하거나, 사용자에게 알림을 표시할 수 있습니다.
            // GMSServices.provideAPIKey("YOUR_FALLBACK_KEY_IF_ANY") // 비상용 키 (권장하지는 않음)
          }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
