import Flutter
import UIKit

final class KometNativeSheet: NSObject, UISheetPresentationControllerDelegate {
  static let shared = KometNativeSheet()

  private var engineGroup: FlutterEngineGroup?
  private var sheetEngine: FlutterEngine?
  private var sheetController: FlutterViewController?
  private var hostingController: UIViewController?
  private var eventSink: FlutterEventSink?
  private var zoomAnchor: UIView?

  private let entrypoint = "nativeAttachmentSheetMain"

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "presentAttachmentSheet":
      present(arguments: call.arguments as? [String: Any], result: result)
    case "dismiss":
      let payload = (call.arguments as? [String: Any])?["result"]
      dismiss(resultPayload: payload, flutterResult: result)
    case "isAvailable":
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func attach(_ sink: FlutterEventSink?) {
    eventSink = sink
  }

  private func present(arguments: [String: Any]?, result: @escaping FlutterResult) {
    guard let root = rootViewController() else {
      result(
        FlutterError(
          code: "NO_ROOT", message: "No root view controller", details: nil))
      return
    }
    if hostingController != nil {
      result(true)
      return
    }

    let group = engineGroup ?? FlutterEngineGroup(name: "komet.native.sheet", project: nil)
    engineGroup = group
    let engine = group.makeEngine(withEntrypoint: entrypoint, libraryURI: nil)
    GeneratedPluginRegistrant.register(with: engine)
    sheetEngine = engine

    let flutterVC = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    flutterVC.isViewOpaque = false
    sheetController = flutterVC

    let content = FlutterMethodChannel(
      name: "ru.komet.app/native_sheet_content",
      binaryMessenger: engine.binaryMessenger)
    content.setMethodCallHandler { [weak self] call, result in
      if call.method == "requestDismiss" {
        let payload = (call.arguments as? [String: Any])?["result"]
        self?.dismiss(resultPayload: payload, flutterResult: { _ in })
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    let host = UIViewController()
    host.view.backgroundColor = .clear
    host.addChild(flutterVC)
    flutterVC.view.translatesAutoresizingMaskIntoConstraints = false
    host.view.addSubview(flutterVC.view)
    NSLayoutConstraint.activate([
      flutterVC.view.topAnchor.constraint(equalTo: host.view.topAnchor),
      flutterVC.view.bottomAnchor.constraint(equalTo: host.view.bottomAnchor),
      flutterVC.view.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
      flutterVC.view.trailingAnchor.constraint(equalTo: host.view.trailingAnchor),
    ])
    flutterVC.didMove(toParent: host)

    host.modalPresentationStyle = .pageSheet
    if let sheet = host.sheetPresentationController {
      sheet.delegate = self
      sheet.detents = [.medium(), .large()]
      sheet.selectedDetentIdentifier = .medium
      sheet.prefersGrabberVisible = true
      sheet.prefersScrollingExpandsWhenScrolledToEdge = true
      if #available(iOS 16.0, *) {
        sheet.largestUndimmedDetentIdentifier = .medium
      }
    }

    if let source = arguments?["source"] as? [String: Any] {
      applyZoomTransition(host: host, root: root, source: source)
    }

    hostingController = host
    root.present(host, animated: true) {
      result(true)
    }
  }

  private func applyZoomTransition(
    host: UIViewController, root: UIViewController, source: [String: Any]
  ) {
    guard #available(iOS 18.0, *) else { return }
    let x = CGFloat((source["x"] as? NSNumber)?.doubleValue ?? 0)
    let y = CGFloat((source["y"] as? NSNumber)?.doubleValue ?? 0)
    let w = CGFloat((source["w"] as? NSNumber)?.doubleValue ?? 44)
    let h = CGFloat((source["h"] as? NSNumber)?.doubleValue ?? 44)
    let anchor = UIView(frame: CGRect(x: x, y: y, width: max(w, 1), height: max(h, 1)))
    anchor.isUserInteractionEnabled = false
    anchor.backgroundColor = .clear
    root.view.addSubview(anchor)
    zoomAnchor = anchor
    host.preferredTransition = .zoom(sourceViewProvider: { _ in anchor })
  }

  private func dismiss(resultPayload: Any?, flutterResult: @escaping FlutterResult) {
    guard let host = hostingController else {
      flutterResult(nil)
      return
    }
    host.dismiss(animated: true) { [weak self] in
      self?.cleanup()
      self?.eventSink?(["type": "dismissed", "result": resultPayload as Any])
      flutterResult(nil)
    }
  }

  func sheetPresentationControllerDidDismiss(
    _ sheetPresentationController: UISheetPresentationController
  ) {
    cleanup()
    eventSink?(["type": "dismissed", "result": NSNull()])
  }

  private func cleanup() {
    sheetController?.engine?.destroyContext()
    sheetController = nil
    sheetEngine = nil
    hostingController = nil
    zoomAnchor?.removeFromSuperview()
    zoomAnchor = nil
  }

  private func rootViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    for scene in scenes {
      if let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
        return top(from: root)
      }
    }
    return nil
  }

  private func top(from root: UIViewController) -> UIViewController {
    if let presented = root.presentedViewController {
      return top(from: presented)
    }
    return root
  }
}
