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
  private let formatButton = UIButton(type: .system)
  private let actionButton = UIButton(type: .system)
  private let statusLabel = UILabel()
  private var applying = false
  private var recording = false
  private var videoMode = false
  private var locked = false
  private var hasText = false
  private var pressOrigin: CGPoint?
  private var pressSchedules = false
  private var pressRecording = false

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
    statusLabel.font = .preferredFont(forTextStyle: .subheadline)
    statusLabel.textColor = .secondaryLabel
    statusLabel.isHidden = true
    configure(attachButton, "paperclip", #selector(attach))
    configure(stickerButton, "face.smiling", #selector(stickers))
    configure(formatButton, "textformat", #selector(formatText))
    actionButton.tintColor = .white
    actionButton.backgroundColor = .systemBlue
    actionButton.layer.cornerRadius = 22
    let hold = UILongPressGestureRecognizer(target: self, action: #selector(held(_:)))
    hold.minimumPressDuration = 0.25
    actionButton.addGestureRecognizer(hold)
    let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
    tap.require(toFail: hold)
    actionButton.addGestureRecognizer(tap)
    let replyRow = UIStackView(arrangedSubviews: [replyLabel, replyClose])
    replyRow.axis = .horizontal
    let input = UIStackView(arrangedSubviews: [
      attachButton, field, statusLabel, stickerButton, formatButton, actionButton,
    ])
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
      actionButton.widthAnchor.constraint(equalToConstant: 44),
      actionButton.heightAnchor.constraint(equalToConstant: 44),
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
    recording = flag(map, "recording")
    videoMode = flag(map, "video")
    locked = flag(map, "locked")
    let status = map["status"] as? String ?? ""
    statusLabel.text = status
    statusLabel.isHidden = status.isEmpty
    field.isHidden = !status.isEmpty
    let text = map["text"] as? String ?? ""
    if field.text != text {
      applying = true
      field.text = text
      applying = false
    }
    hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    field.isEditable = !recording
    refreshAction()
  }

  private func flag(_ map: [String: Any], _ key: String) -> Bool {
    if let value = map[key] as? Bool { return value }
    return (map[key] as? NSNumber)?.boolValue ?? false
  }

  private func refreshAction() {
    let symbol: String
    if locked {
      symbol = "stop.fill"
    } else if hasText {
      symbol = "arrow.up"
    } else if videoMode {
      symbol = "video.fill"
    } else {
      symbol = "mic.fill"
    }
    actionButton.setImage(UIImage(systemName: symbol), for: .normal)
    let filled = recording || locked || hasText
    actionButton.backgroundColor = recording || locked ? .systemRed : (hasText ? .systemBlue : .tertiarySystemFill)
    actionButton.tintColor = filled ? .white : .label
  }

  func textViewDidChange(_ textView: UITextView) {
    guard !applying else { return }
    hasText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    refreshAction()
    channel.invokeMethod("text", arguments: ["text": textView.text ?? ""])
  }

  func textViewDidChangeSelection(_ textView: UITextView) {
    guard !applying else { return }
    let range = textView.selectedRange
    let end = range.location + range.length
    channel.invokeMethod("selection", arguments: ["start": range.location, "end": end])
  }

  @objc private func attach() { channel.invokeMethod("attach", arguments: nil) }
  @objc private func stickers() { channel.invokeMethod("stickers", arguments: nil) }
  @objc private func formatText() { channel.invokeMethod("format", arguments: nil) }
  @objc private func cancelReply() { channel.invokeMethod("replyCancel", arguments: nil) }

  @objc private func tapped() {
    if hasText && !recording {
      channel.invokeMethod("send", arguments: nil)
    } else if recording && locked {
      channel.invokeMethod("recordEnd", arguments: nil)
    } else if !recording {
      channel.invokeMethod("toggleVideo", arguments: nil)
    }
  }

  @objc private func held(_ gesture: UILongPressGestureRecognizer) {
    switch gesture.state {
    case .began:
      pressOrigin = gesture.location(in: actionButton)
      pressRecording = false
      if hasText && !recording {
        pressSchedules = true
        channel.invokeMethod("schedule", arguments: nil)
      } else if !hasText && !recording {
        pressSchedules = false
        pressRecording = true
        channel.invokeMethod("recordStart", arguments: nil)
      }
    case .changed:
      guard pressRecording, let origin = pressOrigin else { return }
      let point = gesture.location(in: actionButton)
      channel.invokeMethod("recordDrag", arguments: [
        "x": point.x - origin.x,
        "y": point.y - origin.y,
      ])
    case .ended, .cancelled, .failed:
      if pressRecording {
        channel.invokeMethod("recordEnd", arguments: nil)
      }
      pressOrigin = nil
      pressSchedules = false
      pressRecording = false
    default:
      break
    }
  }
}
