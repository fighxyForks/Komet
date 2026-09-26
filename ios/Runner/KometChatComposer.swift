import Flutter
import UIKit

final class KometChatComposerViewFactory: NSObject, FlutterPlatformViewFactory {
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
    KometChatComposerPlatformView(
      frame: frame, viewId: viewId, arguments: args, messenger: messenger)
  }
}

final class KometChatComposerPlatformView: NSObject, FlutterPlatformView, UITextViewDelegate {
  private let channel: FlutterMethodChannel
  private let root = UIView()
  private let replyLabel = UILabel()
  private let replyClose = UIButton(type: .system)
  private let field = UITextView()
  private let attachButton = UIButton(type: .system)
  private let stickerButton = UIButton(type: .system)
  private let actionButton = UIButton(type: .system)
  private var applying = false
  private var recording = false
  private var hasText = false

  init(frame: CGRect, viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "ru.komet.app/native_chat_composer/\(viewId)", binaryMessenger: messenger)
    super.init()
    root.frame = frame
    root.backgroundColor = .secondarySystemBackground
    replyLabel.font = .preferredFont(forTextStyle: .footnote)
    replyLabel.textColor = .secondaryLabel
    replyClose.setImage(UIImage(systemName: "xmark"), for: .normal)
    replyClose.addTarget(self, action: #selector(cancelReply), for: .touchUpInside)
    field.font = .preferredFont(forTextStyle: .body)
    field.backgroundColor = .clear
    field.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
    field.delegate = self
    field.isScrollEnabled = false
    configure(attachButton, "paperclip", #selector(attach))
    configure(stickerButton, "face.smiling", #selector(stickers))
    actionButton.tintColor = .white
    actionButton.backgroundColor = .systemBlue
    actionButton.layer.cornerRadius = 18
    actionButton.addTarget(self, action: #selector(actionDown), for: .touchDown)
    actionButton.addTarget(self, action: #selector(actionUp), for: .touchUpInside)
    actionButton.addTarget(self, action: #selector(actionCancel), for: .touchUpOutside)
    let replyRow = UIStackView(arrangedSubviews: [replyLabel, replyClose])
    replyRow.axis = .horizontal
    let input = UIStackView(arrangedSubviews: [attachButton, field, stickerButton, actionButton])
    input.axis = .horizontal
    input.alignment = .bottom
    input.spacing = 6
    let column = UIStackView(arrangedSubviews: [replyRow, input])
    column.axis = .vertical
    column.spacing = 4
    column.translatesAutoresizingMaskIntoConstraints = false
    root.addSubview(column)
    NSLayoutConstraint.activate([
      column.leadingAnchor.constraint(equalTo: root.safeAreaLayoutGuide.leadingAnchor, constant: 8),
      column.trailingAnchor.constraint(equalTo: root.safeAreaLayoutGuide.trailingAnchor, constant: -8),
      column.topAnchor.constraint(equalTo: root.topAnchor, constant: 6),
      column.bottomAnchor.constraint(equalTo: root.safeAreaLayoutGuide.bottomAnchor, constant: -6),
      actionButton.widthAnchor.constraint(equalToConstant: 36),
      actionButton.heightAnchor.constraint(equalToConstant: 36),
      attachButton.widthAnchor.constraint(equalToConstant: 36),
      stickerButton.widthAnchor.constraint(equalToConstant: 36),
      field.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),
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

  deinit { channel.setMethodCallHandler(nil) }
  func view() -> UIView { root }

  private func configure(_ button: UIButton, _ symbol: String, _ action: Selector) {
    button.setImage(UIImage(systemName: symbol), for: .normal)
    button.tintColor = .secondaryLabel
    button.addTarget(self, action: action, for: .touchUpInside)
  }

  private func apply(_ map: [String: Any]?) {
    let map = map ?? [:]
    let reply = map["reply"] as? String ?? ""
    replyLabel.text = reply
    replyLabel.isHidden = reply.isEmpty
    replyClose.isHidden = reply.isEmpty
    recording = (map["recording"] as? NSNumber)?.boolValue ?? false
    let text = map["text"] as? String ?? ""
    if field.text != text {
      applying = true
      field.text = text
      applying = false
    }
    hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    let symbol = recording ? "stop.fill" : (hasText ? "arrow.up" : "mic.fill")
    actionButton.setImage(UIImage(systemName: symbol), for: .normal)
    field.isEditable = !recording
  }

  func textViewDidChange(_ textView: UITextView) {
    guard !applying else { return }
    hasText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    let symbol = hasText ? "arrow.up" : "mic.fill"
    actionButton.setImage(UIImage(systemName: symbol), for: .normal)
    channel.invokeMethod("text", arguments: ["text": textView.text ?? ""])
  }

  @objc private func attach() { channel.invokeMethod("attach", arguments: nil) }
  @objc private func stickers() { channel.invokeMethod("stickers", arguments: nil) }
  @objc private func cancelReply() { channel.invokeMethod("replyCancel", arguments: nil) }

  @objc private func actionDown() {
    guard !hasText, !recording else { return }
    channel.invokeMethod("voiceStart", arguments: nil)
  }

  @objc private func actionUp() {
    if hasText {
      channel.invokeMethod("send", arguments: nil)
    } else {
      channel.invokeMethod("voiceStop", arguments: nil)
    }
  }

  @objc private func actionCancel() {
    if !hasText { channel.invokeMethod("voiceCancel", arguments: nil) }
  }
}
