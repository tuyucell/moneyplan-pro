import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var pushChannel: FlutterMethodChannel?
  private var latestDeviceToken: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let registrar = registrar(forPlugin: "MoneyPlanPushPlugin") {
      pushChannel = FlutterMethodChannel(
        name: "pro.moneyplan.app/push",
        binaryMessenger: registrar.messenger()
      )
      pushChannel?.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "getAuthorizationStatus":
          UNUserNotificationCenter.current().getNotificationSettings { settings in
            let value: String
            switch settings.authorizationStatus {
            case .authorized:
              value = "authorized"
            case .provisional, .ephemeral:
              value = "provisional"
            case .denied:
              value = "denied"
            case .notDetermined:
              value = "notDetermined"
            @unknown default:
              value = "notDetermined"
            }
            DispatchQueue.main.async {
              result(value)
            }
          }
        case "requestPermission":
          UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
          ) { granted, error in
            if let error = error {
              DispatchQueue.main.async {
                self?.pushChannel?.invokeMethod(
                  "onRegistrationError",
                  arguments: error.localizedDescription
                )
                result(false)
              }
              return
            }
            DispatchQueue.main.async {
              if granted {
                UIApplication.shared.registerForRemoteNotifications()
              }
              result(granted)
            }
          }
        case "registerToken":
          UIApplication.shared.registerForRemoteNotifications()
          result(nil)
        case "unregisterToken":
          UIApplication.shared.unregisterForRemoteNotifications()
          result(nil)
        case "openSettings":
          guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            result(nil)
            return
          }
          UIApplication.shared.open(settingsURL)
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    latestDeviceToken = token
    pushChannel?.invokeMethod("onToken", arguments: token)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    pushChannel?.invokeMethod("onRegistrationError", arguments: error.localizedDescription)
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return super.application(app, open: url, options: options)
  }
}
