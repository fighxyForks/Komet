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

final class KometPowerState: NSObject {
  static let shared = KometPowerState()

  private var eventSink: FlutterEventSink?

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isLowPowerModeEnabled":
      result(ProcessInfo.processInfo.isLowPowerModeEnabled)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func attach(_ sink: FlutterEventSink?) {
    eventSink = sink
    if sink != nil {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(onPowerChanged),
        name: Notification.Name.NSProcessInfoPowerStateDidChange,
        object: nil
      )
      sink?(ProcessInfo.processInfo.isLowPowerModeEnabled)
    } else {
      NotificationCenter.default.removeObserver(self)
    }
  }

  @objc private func onPowerChanged() {
    eventSink?(ProcessInfo.processInfo.isLowPowerModeEnabled)
  }
}
