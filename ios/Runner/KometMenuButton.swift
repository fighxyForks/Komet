import Flutter
import UIKit

final class KometMenuButtonViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    KometMenuButtonPlatformView(
      frame: frame, viewId: viewId, arguments: args, messenger: messenger)
  }
}

final class KometMenuButtonPlatformView: NSObject, FlutterPlatformView {
  private static let avatarSide: CGFloat = 28
  private static let avatars = NSCache<NSString, UIImage>()

  private let channel: FlutterMethodChannel
  private let button = UIButton(type: .custom)
  private var items: [[String: Any]] = []
  private var pendingAvatars = Set<String>()

  init(frame: CGRect, viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "ru.komet.app/menu_button/\(viewId)", binaryMessenger: messenger)
    super.init()
    button.frame = frame
    button.backgroundColor = .clear
    let map = arguments as? [String: Any] ?? [:]
    items = map["items"] as? [[String: Any]] ?? []
    if #available(iOS 14.0, *) {
      button.showsMenuAsPrimaryAction = true
      rebuildMenu()
    } else {
      button.addTarget(self, action: #selector(fallbackTap), for: .touchUpInside)
    }
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "setItems":
        self.items = call.arguments as? [[String: Any]] ?? []
        if #available(iOS 14.0, *) { self.rebuildMenu() }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  func view() -> UIView { button }

  @objc private func fallbackTap() {
    channel.invokeMethod("fallback", arguments: nil)
  }

  @available(iOS 14.0, *)
  private func rebuildMenu() {
    var sections: [[UIMenuElement]] = [[]]
    for item in items {
      if item["separator"] as? Bool == true {
        sections.append([])
        continue
      }
      guard let id = item["id"] as? String, let title = item["title"] as? String else { continue }
      let action = UIAction(title: title, image: image(for: item)) { [weak self] _ in
        self?.channel.invokeMethod("select", arguments: id)
      }
      if #available(iOS 15.0, *), let subtitle = item["subtitle"] as? String, !subtitle.isEmpty {
        action.subtitle = subtitle
      }
      if item["checked"] as? Bool == true { action.state = .on }
      if item["destructive"] as? Bool == true { action.attributes.insert(.destructive) }
      sections[sections.count - 1].append(action)
    }
    let children: [UIMenuElement] = sections.filter { !$0.isEmpty }.map {
      UIMenu(title: "", options: .displayInline, children: $0)
    }
    button.menu = UIMenu(title: "", children: children)
  }

  @available(iOS 14.0, *)
  private func image(for item: [String: Any]) -> UIImage? {
    let symbol = (item["symbol"] as? String).flatMap { UIImage(systemName: $0) }
    guard let url = item["imageUrl"] as? String, !url.isEmpty else { return symbol }
    if let cached = Self.avatars.object(forKey: url as NSString) { return cached }
    loadAvatar(url)
    return symbol ?? UIImage(systemName: "person.crop.circle")
  }

  @available(iOS 14.0, *)
  private func loadAvatar(_ url: String) {
    guard let target = URL(string: url), !pendingAvatars.contains(url) else { return }
    pendingAvatars.insert(url)
    URLSession.shared.dataTask(with: target) { [weak self] data, _, _ in
      let avatar = data.flatMap(UIImage.init(data:)).map(Self.circular)
      DispatchQueue.main.async {
        guard let self = self else { return }
        self.pendingAvatars.remove(url)
        guard let avatar = avatar else { return }
        Self.avatars.setObject(avatar, forKey: url as NSString)
        self.rebuildMenu()
      }
    }.resume()
  }

  private static func circular(_ image: UIImage) -> UIImage {
    let side = avatarSide
    let format = UIGraphicsImageRendererFormat.preferred()
    let rendered = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
      .image { _ in
        let bounds = CGRect(x: 0, y: 0, width: side, height: side)
        UIBezierPath(ovalIn: bounds).addClip()
        let scale = max(side / image.size.width, side / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        image.draw(
          in: CGRect(
            x: (side - size.width) / 2, y: (side - size.height) / 2,
            width: size.width, height: size.height))
      }
    return rendered.withRenderingMode(.alwaysOriginal)
  }
}
