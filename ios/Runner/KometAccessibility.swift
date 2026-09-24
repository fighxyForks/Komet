import Flutter
import UIKit

final class KometAccessibility: NSObject {
  static let shared = KometAccessibility()

  private var eventSink: FlutterEventSink?

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isReduceTransparencyEnabled":
      result(UIAccessibility.isReduceTransparencyEnabled)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func attach(_ sink: FlutterEventSink?) {
    eventSink = sink
    if sink != nil {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(onReduceTransparencyChanged),
        name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
        object: nil
      )
      sink?(UIAccessibility.isReduceTransparencyEnabled)
    } else {
      NotificationCenter.default.removeObserver(self)
    }
  }

  @objc private func onReduceTransparencyChanged() {
    eventSink?(UIAccessibility.isReduceTransparencyEnabled)
  }
}
