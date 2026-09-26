import Flutter
import UIKit

final class KometStreamHandler: NSObject, FlutterStreamHandler {
  private let onSink: (FlutterEventSink?) -> Void

  init(onSink: @escaping (FlutterEventSink?) -> Void) {
    self.onSink = onSink
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    onSink(events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    onSink(nil)
    return nil
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var channels: [FlutterMethodChannel] = []
  private var eventChannels: [FlutterEventChannel] = []
  private var streamHandlers: [KometStreamHandler] = []
  private var videoNote: KometVideoNote?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    KometNotifications.shared.start()

    if let controller = window?.rootViewController as? FlutterViewController {
      let messenger = controller.binaryMessenger
      registerAppIcon(messenger)
      registerVideo(messenger)
      registerVideoNote(messenger)
      registerNotifications(messenger)
      registerScreen(messenger)
      registerClipboard(messenger)
      registerAppearance(messenger)
      registerAccessibility(messenger)
      registerNativeSheet(messenger)
      registerNativeTabChrome(messenger)
      registerNativeChatList(messenger, host: controller)
      registerNativeChat(messenger, host: controller)
      registerNativeSearch(messenger)
      registerNativeChatHeader(messenger)
      registerNativeChatComposer(messenger)
      registerNativeList(messenger, host: controller)
      method("ru.komet.app/native_alert", messenger) { call, result in
        KometNativeAlert.shared.handle(call, result: result)
      }
      registerMenuButton(messenger)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
    KometNativeSheet.shared.noteMemoryWarning()
    super.applicationDidReceiveMemoryWarning(application)
  }

  private func method(_ name: String, _ messenger: FlutterBinaryMessenger,
                      _ handler: @escaping FlutterMethodCallHandler) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler(handler)
    channels.append(channel)
  }

  private func events(_ name: String, _ messenger: FlutterBinaryMessenger,
                      _ onSink: @escaping (FlutterEventSink?) -> Void) {
    let handler = KometStreamHandler(onSink: onSink)
    let channel = FlutterEventChannel(name: name, binaryMessenger: messenger)
    channel.setStreamHandler(handler)
    streamHandlers.append(handler)
    eventChannels.append(channel)
  }

  private func registerAppIcon(_ messenger: FlutterBinaryMessenger) {
    method("ru.komet.app/app_icon", messenger) { call, result in
      switch call.method {
      case "getAppIcon":
        result(UIApplication.shared.alternateIconName)
      case "setAppIcon":
        let requested = (call.arguments as? [String: Any])?["name"] as? String
        let iconName: String? = (requested?.isEmpty ?? true) ? nil : requested
        guard UIApplication.shared.supportsAlternateIcons else {
          result(FlutterError(code: "UNSUPPORTED",
                              message: "Alternate icons are not supported",
                              details: nil))
          return
        }
        guard UIApplication.shared.alternateIconName != iconName else {
          result(nil)
          return
        }
        UIApplication.shared.setAlternateIconName(iconName) { error in
          DispatchQueue.main.async {
            if let error = error {
              result(FlutterError(code: "APPLY_FAILED",
                                  message: error.localizedDescription,
                                  details: nil))
            } else {
              result(nil)
            }
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func registerVideo(_ messenger: FlutterBinaryMessenger) {
    method("ru.komet.app/video", messenger) { call, result in
      KometVideo.shared.handle(call, result: result)
    }
  }

  private func registerVideoNote(_ messenger: FlutterBinaryMessenger) {
    guard let textures = registrar(forPlugin: "KometVideoNote")?.textures() else { return }

    method("ru.komet.app/video_note", messenger) { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "permission":
        KometVideoNote.requestPermission(result)
      case "init":
        let args = call.arguments as? [String: Any] ?? [:]
        self.videoNote?.dispose()
        let recorder = KometVideoNote(registry: textures)
        self.videoNote = recorder
        recorder.initialize(
          front: (args["front"] as? NSNumber)?.boolValue ?? true,
          cameraId: args["cameraId"] as? String,
          edge: (args["size"] as? NSNumber)?.intValue ?? 480,
          fps: (args["fps"] as? NSNumber)?.intValue ?? 30,
          result: result)
      case "start":
        self.withRecorder(result) { $0.start(result: result) }
      case "switch":
        self.withRecorder(result) { $0.switchCamera(result: result) }
      case "torch":
        let on = ((call.arguments as? [String: Any])?["on"] as? NSNumber)?.boolValue ?? false
        self.withRecorder(result) { $0.setTorch(on: on, result: result) }
      case "stop":
        self.withRecorder(result) { $0.stop(result: result) }
      case "distribute":
        self.videoNote?.dispose()
        self.videoNote = nil
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func withRecorder(_ result: @escaping FlutterResult,
                            _ body: (KometVideoNote) -> Void) {
    guard let recorder = videoNote else {
      result(FlutterError(code: "NOT_READY", message: "recorder not initialized", details: nil))
      return
    }
    body(recorder)
  }

  private func registerScreen(_ messenger: FlutterBinaryMessenger) {
    method("ru.komet.app/screen", messenger) { call, result in
      switch call.method {
      case "setKeepAwake":
        let enabled = ((call.arguments as? [String: Any])?["enabled"] as? NSNumber)?.boolValue ?? false
        DispatchQueue.main.async {
          UIApplication.shared.isIdleTimerDisabled = enabled
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func registerClipboard(_ messenger: FlutterBinaryMessenger) {
    method("ru.komet.app/clipboard", messenger) { call, result in
      KometClipboard.handle(call, result: result)
    }
  }

  private func registerAppearance(_ messenger: FlutterBinaryMessenger) {
    method("ru.komet.app/appearance", messenger) { [weak self] call, result in
      guard call.method == "setBrightness",
            let brightness = call.arguments as? String,
            ["dark", "light", "system"].contains(brightness) else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.window?.overrideUserInterfaceStyle = brightness == "system"
        ? .unspecified : (brightness == "dark" ? .dark : .light)
      result(nil)
    }
  }



  private func registerNativeSheet(_ messenger: FlutterBinaryMessenger) {
    method("ru.komet.app/native_sheet", messenger) { call, result in
      KometNativeSheet.shared.handle(call, result: result)
    }
    events("ru.komet.app/native_sheet_events", messenger) { sink in
      KometNativeSheet.shared.attach(sink)
    }
  }

  private func registerNativeTabChrome(_ messenger: FlutterBinaryMessenger) {
    method("ru.komet.app/native_tab_chrome", messenger) { call, result in
      KometTabChrome.shared.handle(call, result: result)
    }
    KometTabChrome.shared.bindMessenger(messenger)
    let factory = KometTabChromeViewFactory(messenger: messenger)
    registrar(forPlugin: "KometTabChrome")?.register(
      factory,
      withId: "ru.komet.app/native_tab_chrome_view")
  }

  private func registerNativeChatList(_ messenger: FlutterBinaryMessenger,
                                      host: UIViewController) {
    registrar(forPlugin: "KometChatList")?.register(
      KometChatListViewFactory(messenger: messenger, host: host),
      withId: "ru.komet.app/native_chat_list")
  }

  private func registerNativeChat(_ messenger: FlutterBinaryMessenger,
                                  host: UIViewController) {
    registrar(forPlugin: "KometChat")?.register(
      KometChatViewFactory(messenger: messenger, host: host),
      withId: "ru.komet.app/native_chat")
  }

  private func registerNativeSearch(_ messenger: FlutterBinaryMessenger) {
    registrar(forPlugin: "KometSearch")?.register(
      KometSearchViewFactory(messenger: messenger),
      withId: "ru.komet.app/native_search")
  }

  private func registerNativeChatHeader(_ messenger: FlutterBinaryMessenger) {
    registrar(forPlugin: "KometChatHeader")?.register(
      KometChatHeaderViewFactory(messenger: messenger),
      withId: "ru.komet.app/native_chat_header")
  }

  private func registerNativeChatComposer(_ messenger: FlutterBinaryMessenger) {
    registrar(forPlugin: "KometChatComposer")?.register(
      KometChatComposerViewFactory(messenger: messenger),
      withId: "ru.komet.app/native_chat_composer")
  }

  private func registerNativeList(_ messenger: FlutterBinaryMessenger, host: UIViewController) {
    registrar(forPlugin: "KometNativeList")?.register(
      KometNativeListViewFactory(messenger: messenger, host: host),
      withId: "ru.komet.app/native_list")
  }

  private func registerMenuButton(_ messenger: FlutterBinaryMessenger) {
    registrar(forPlugin: "KometMenuButton")?.register(
      KometMenuButtonViewFactory(messenger: messenger),
      withId: "ru.komet.app/menu_button")
  }

  private func registerAccessibility(_ messenger: FlutterBinaryMessenger) {
    method("ru.komet.app/accessibility", messenger) { call, result in
      KometAccessibility.shared.handle(call, result: result)
    }
    events("ru.komet.app/accessibility_events", messenger) { sink in
      KometAccessibility.shared.attach(sink)
    }
    method("ru.komet.app/power", messenger) { call, result in
      KometPowerState.shared.handle(call, result: result)
    }
    events("ru.komet.app/power_events", messenger) { sink in
      KometPowerState.shared.attach(sink)
    }
  }

  private func registerNotifications(_ messenger: FlutterBinaryMessenger) {
    method("ru.komet.app/notifications", messenger) { call, result in
      KometNotifications.shared.handle(call, result: result)
    }
    events("ru.komet.app/notification_events", messenger) { sink in
      KometNotifications.shared.attach(sink)
    }
  }
}
