import Flutter
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // 알림 권한 요청
    UNUserNotificationCenter.current().delegate = self
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if let error = error {
        print("Error requesting notifications authorization: \(error)")
      }
      if granted {
        DispatchQueue.main.async {
          application.registerForRemoteNotifications()
        }
      } else {
        // 권한이 거부된 경우 처리
        print("Notification permission denied")
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
