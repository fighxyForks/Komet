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
  private var avatarTask: URLSessionDataTask?

  init(frame: CGRect, viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "ru.komet.app/native_chat_header/\(viewId)", binaryMessenger: messenger)
    super.init()
    root.frame = frame
    root.backgroundColor = .clear
    configure(backButton, symbol: "chevron.backward", action: #selector(closeTapped))
    avatar.layer.cornerRadius = 16
    avatar.clipsToBounds = true
    avatar.backgroundColor = .secondarySystemFill
    avatar.isUserInteractionEnabled = true
    avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(infoTapped)))
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.adjustsFontForContentSizeCategory = true
    subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.adjustsFontForContentSizeCategory = true
    configure(scheduledButton, symbol: "clock", action: #selector(scheduledTapped))
    configure(callButton, symbol: "phone", action: #selector(callTapped))
    configure(menuButton, symbol: "ellipsis", action: #selector(menuTapped))
    let titles = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
    titles.axis = .vertical
    titles.spacing = 0
    let row = UIStackView(arrangedSubviews: [
      backButton, avatar, titles, scheduledButton, callButton, menuButton,
    ])
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 8
    row.translatesAutoresizingMaskIntoConstraints = false
    root.addSubview(row)
    NSLayoutConstraint.activate([
      row.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
      row.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
      row.topAnchor.constraint(equalTo: root.topAnchor),
      row.bottomAnchor.constraint(equalTo: root.bottomAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 32),
      avatar.heightAnchor.constraint(equalToConstant: 32),
      backButton.widthAnchor.constraint(equalToConstant: 44),
      backButton.heightAnchor.constraint(equalToConstant: 44),
      scheduledButton.widthAnchor.constraint(equalToConstant: 44),
      callButton.widthAnchor.constraint(equalToConstant: 44),
      menuButton.widthAnchor.constraint(equalToConstant: 44),
      scheduledButton.heightAnchor.constraint(equalToConstant: 44),
      callButton.heightAnchor.constraint(equalToConstant: 44),
      menuButton.heightAnchor.constraint(equalToConstant: 44),
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
    button.setImage(UIImage(systemName: symbol), for: .normal)
    button.tintColor = .label
    button.addTarget(self, action: action, for: .touchUpInside)
  }

  private func apply(_ map: [String: Any]?) {
    let map = map ?? [:]
    titleLabel.text = map["title"] as? String ?? ""
    subtitleLabel.text = map["subtitle"] as? String ?? ""
    subtitleLabel.isHidden = subtitleLabel.text?.isEmpty ?? true
    backButton.isHidden = (map["embedded"] as? NSNumber)?.boolValue ?? false
    callButton.isHidden = !((map["showCall"] as? NSNumber)?.boolValue ?? false)
    scheduledButton.isHidden = !((map["showScheduled"] as? NSNumber)?.boolValue ?? false)
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
