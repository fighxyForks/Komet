import Flutter
import UIKit

final class KometChatHeaderViewFactory: NSObject, FlutterPlatformViewFactory {
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
    KometChatHeaderPlatformView(
      frame: frame, viewId: viewId, arguments: args, messenger: messenger)
  }
}

final class KometChatHeaderPlatformView: NSObject, FlutterPlatformView {
  private let channel: FlutterMethodChannel
  private let root = UIView()
  private let backButton = UIButton(type: .system)
  private let avatar = UIImageView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let scheduledButton = UIButton(type: .system)
  private let callButton = UIButton(type: .system)
  private let menuButton = UIButton(type: .system)
  private let backHost = UIView()
  private let scheduledHost = UIView()
  private let callHost = UIView()
  private let menuHost = UIView()
  private var avatarTask: URLSessionDataTask?

  init(frame: CGRect, viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "ru.komet.app/native_chat_header/\(viewId)", binaryMessenger: messenger)
    super.init()
    root.frame = frame
    root.backgroundColor = .clear
    configure(backButton, symbol: "chevron.backward", action: #selector(closeTapped))
    configure(scheduledButton, symbol: "clock", action: #selector(scheduledTapped))
    configure(callButton, symbol: "phone", action: #selector(callTapped))
    configure(menuButton, symbol: "ellipsis", action: #selector(menuTapped))
    glassCircle(backHost, button: backButton)
    glassCircle(scheduledHost, button: scheduledButton)
    glassCircle(callHost, button: callButton)
    glassCircle(menuHost, button: menuButton)
    avatar.layer.cornerRadius = 16
    avatar.clipsToBounds = true
    avatar.backgroundColor = .secondarySystemFill
    titleLabel.font = UIFontMetrics(forTextStyle: .headline).scaledFont(
      for: .systemFont(ofSize: 17, weight: .semibold))
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.lineBreakMode = .byTruncatingTail
    subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.adjustsFontForContentSizeCategory = true
    subtitleLabel.lineBreakMode = .byTruncatingTail
    let titles = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
    titles.axis = .vertical
    titles.spacing = 0
    titles.isUserInteractionEnabled = false
    let identity = UIStackView(arrangedSubviews: [avatar, titles])
    identity.axis = .horizontal
    identity.alignment = .center
    identity.spacing = 8
    identity.isUserInteractionEnabled = false
    let capsule = UIView()
    glassFill(capsule, radius: 22)
    identity.translatesAutoresizingMaskIntoConstraints = false
    capsule.addSubview(identity)
    capsule.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(infoTapped)))
    capsule.setContentHuggingPriority(.defaultLow, for: .horizontal)
    let row = UIStackView(arrangedSubviews: [
      backHost, capsule, scheduledHost, callHost, menuHost,
    ])
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 8
    row.translatesAutoresizingMaskIntoConstraints = false
    root.addSubview(row)
    NSLayoutConstraint.activate([
      row.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
      row.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
      row.centerYAnchor.constraint(equalTo: root.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 32),
      avatar.heightAnchor.constraint(equalToConstant: 32),
      capsule.heightAnchor.constraint(equalToConstant: 44),
      identity.leadingAnchor.constraint(equalTo: capsule.leadingAnchor, constant: 6),
      identity.trailingAnchor.constraint(equalTo: capsule.trailingAnchor, constant: -12),
      identity.topAnchor.constraint(equalTo: capsule.topAnchor),
      identity.bottomAnchor.constraint(equalTo: capsule.bottomAnchor),
    ])
    apply(arguments as? [String: Any])
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "apply" {
        self?.apply(call.arguments as? [String: Any])
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  deinit {
    avatarTask?.cancel()
    channel.setMethodCallHandler(nil)
  }

  func view() -> UIView { root }

  private func configure(_ button: UIButton, symbol: String, action: Selector) {
    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
    button.setImage(UIImage(systemName: symbol, withConfiguration: symbolConfig), for: .normal)
    button.tintColor = .label
    button.addTarget(self, action: action, for: .touchUpInside)
  }

  private func glassFill(_ host: UIView, radius: CGFloat) {
    host.layer.cornerRadius = radius
    host.layer.cornerCurve = .continuous
    host.clipsToBounds = true
    if #available(iOS 26.0, *) {
      let glass = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
      glass.isUserInteractionEnabled = false
      glass.translatesAutoresizingMaskIntoConstraints = false
      host.insertSubview(glass, at: 0)
      NSLayoutConstraint.activate([
        glass.leadingAnchor.constraint(equalTo: host.leadingAnchor),
        glass.trailingAnchor.constraint(equalTo: host.trailingAnchor),
        glass.topAnchor.constraint(equalTo: host.topAnchor),
        glass.bottomAnchor.constraint(equalTo: host.bottomAnchor),
      ])
    } else {
      host.backgroundColor = .secondarySystemFill
    }
  }

  private func glassCircle(_ host: UIView, button: UIButton) {
    glassFill(host, radius: 22)
    button.translatesAutoresizingMaskIntoConstraints = false
    host.addSubview(button)
    NSLayoutConstraint.activate([
      host.widthAnchor.constraint(equalToConstant: 44),
      host.heightAnchor.constraint(equalToConstant: 44),
      button.leadingAnchor.constraint(equalTo: host.leadingAnchor),
      button.trailingAnchor.constraint(equalTo: host.trailingAnchor),
      button.topAnchor.constraint(equalTo: host.topAnchor),
      button.bottomAnchor.constraint(equalTo: host.bottomAnchor),
    ])
  }

  private func apply(_ map: [String: Any]?) {
    let map = map ?? [:]
    titleLabel.text = map["title"] as? String ?? ""
    subtitleLabel.text = map["subtitle"] as? String ?? ""
    subtitleLabel.isHidden = subtitleLabel.text?.isEmpty ?? true
    backHost.isHidden = (map["embedded"] as? NSNumber)?.boolValue ?? false
    callHost.isHidden = !((map["showCall"] as? NSNumber)?.boolValue ?? false)
    scheduledHost.isHidden = !((map["showScheduled"] as? NSNumber)?.boolValue ?? false)
    if let raw = map["avatarUrl"] as? String, let url = URL(string: raw), raw.hasPrefix("http") {
      avatarTask?.cancel()
      avatarTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
        guard let data = data, let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { self?.avatar.image = image }
      }
      avatarTask?.resume()
    } else {
      avatar.image = UIImage(systemName: "person.crop.circle.fill")
    }
  }

  @objc private func closeTapped() { channel.invokeMethod("close", arguments: nil) }
  @objc private func infoTapped() { channel.invokeMethod("info", arguments: nil) }
  @objc private func scheduledTapped() { channel.invokeMethod("scheduled", arguments: nil) }
  @objc private func callTapped() { channel.invokeMethod("call", arguments: nil) }

  @objc private func menuTapped() {
    let rect = menuButton.convert(menuButton.bounds, to: nil)
    channel.invokeMethod("menu", arguments: [
      "x": rect.minX, "y": rect.minY, "width": rect.width, "height": rect.height,
    ])
  }
}
