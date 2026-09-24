import Flutter
import UIKit

final class KometTabChromeViewFactory: NSObject, FlutterPlatformViewFactory {
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
    KometTabChromePlatformView(frame: frame, arguments: args)
  }
}

final class KometTabChromePlatformView: NSObject, FlutterPlatformView {
  private let container: KometTabChromeView

  init(frame: CGRect, arguments: Any?) {
    container = KometTabChromeView(frame: frame)
    super.init()
    if let map = arguments as? [String: Any] {
      container.applyArguments(map)
    }
    KometTabChrome.shared.attach(view: container)
  }

  func view() -> UIView { container }
}

final class KometTabChrome: NSObject {
  static let shared = KometTabChrome()
  private weak var view: KometTabChromeView?
  private var eventChannel: FlutterMethodChannel?

  func bindMessenger(_ messenger: FlutterBinaryMessenger) {
    eventChannel = FlutterMethodChannel(
      name: "ru.komet.app/native_tab_chrome_events",
      binaryMessenger: messenger)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onAccessory),
      name: .kometCallAccessoryTapped,
      object: nil)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onTabSelected(_:)),
      name: .kometTabSelected,
      object: nil)
  }

  @objc private func onAccessory() {
    eventChannel?.invokeMethod("accessoryTap", arguments: nil)
  }

  @objc private func onTabSelected(_ note: Notification) {
    let index = note.userInfo?["index"] as? Int ?? 0
    eventChannel?.invokeMethod("tabSelected", arguments: ["index": index])
  }

  func attach(view: KometTabChromeView) {
    self.view = view
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setMinimized":
      let value = (call.arguments as? [String: Any])?["value"] as? Bool ?? false
      view?.setMinimized(value, animated: true)
      result(nil)
    case "setCallAccessory":
      let args = call.arguments as? [String: Any] ?? [:]
      let visible = args["visible"] as? Bool ?? false
      let title = args["title"] as? String
      view?.setCallAccessory(visible: visible, title: title)
      result(nil)
    case "setSelectedIndex":
      let index = (call.arguments as? [String: Any])?["index"] as? Int ?? 0
      view?.setSelectedIndex(index)
      result(nil)
    case "isAvailable":
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

final class KometTabChromeView: UIView, UITabBarDelegate {
  private let tabBar = UITabBar()
  private let accessory = UIButton(type: .system)
  private var minimized = false
  private var accessoryVisible = false

  override init(frame: CGRect) {
    super.init(frame: frame)
    clipsToBounds = true
    backgroundColor = .clear

    accessory.translatesAutoresizingMaskIntoConstraints = false
    accessory.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.92)
    accessory.setTitleColor(.white, for: .normal)
    accessory.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
    accessory.layer.cornerRadius = 12
    accessory.isHidden = true
    accessory.addTarget(self, action: #selector(onAccessoryTap), for: .touchUpInside)

    tabBar.translatesAutoresizingMaskIntoConstraints = false
    tabBar.delegate = self
    tabBar.items = [
      UITabBarItem(title: "Чаты", image: UIImage(systemName: "bubble.left.and.bubble.right"), tag: 0),
      UITabBarItem(title: "Звонки", image: UIImage(systemName: "phone"), tag: 1),
      UITabBarItem(title: "Контакты", image: UIImage(systemName: "person.crop.circle"), tag: 2),
      UITabBarItem(title: "Настройки", image: UIImage(systemName: "gearshape"), tag: 3),
    ]
    tabBar.selectedItem = tabBar.items?.first

    addSubview(accessory)
    addSubview(tabBar)
    NSLayoutConstraint.activate([
      accessory.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      accessory.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
      accessory.topAnchor.constraint(equalTo: topAnchor, constant: 4),
      accessory.heightAnchor.constraint(equalToConstant: 36),
      tabBar.leadingAnchor.constraint(equalTo: leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: trailingAnchor),
      tabBar.bottomAnchor.constraint(equalTo: bottomAnchor),
      tabBar.heightAnchor.constraint(equalToConstant: 49),
    ])
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  func applyArguments(_ args: [String: Any]) {
    if let index = args["index"] as? Int {
      setSelectedIndex(index)
    }
    let visible = args["callVisible"] as? Bool ?? false
    let title = args["callTitle"] as? String
    setCallAccessory(visible: visible, title: title)
  }

  func setSelectedIndex(_ index: Int) {
    guard let items = tabBar.items, index >= 0, index < items.count else { return }
    tabBar.selectedItem = items[index]
  }

  func setCallAccessory(visible: Bool, title: String?) {
    accessoryVisible = visible
    accessory.isHidden = !visible
    accessory.setTitle(title ?? "Вернуться к звонку", for: .normal)
    setNeedsLayout()
  }

  func setMinimized(_ value: Bool, animated: Bool) {
    minimized = value
    let transform = value
      ? CGAffineTransform(translationX: 0, y: bounds.height * 0.55)
      : .identity
    let changes = {
      self.tabBar.transform = transform
      self.tabBar.alpha = value ? 0.35 : 1
    }
    if animated {
      UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseInOut], animations: changes)
    } else {
      changes()
    }
  }

  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    NotificationCenter.default.post(
      name: .kometTabSelected,
      object: nil,
      userInfo: ["index": item.tag])
  }

  @objc private func onAccessoryTap() {
    NotificationCenter.default.post(name: .kometCallAccessoryTapped, object: nil)
  }
}

extension Notification.Name {
  static let kometCallAccessoryTapped = Notification.Name("kometCallAccessoryTapped")
  static let kometTabSelected = Notification.Name("kometTabSelected")
}
