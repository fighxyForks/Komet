import AVFoundation
import Flutter
import UIKit

final class KometStoryEditorViewFactory: NSObject, FlutterPlatformViewFactory {
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
    KometStoryEditorPlatformView(
      frame: frame, viewId: viewId, arguments: args, messenger: messenger)
  }
}

private final class KometPlayerHost: UIView {
  let playerLayer = AVPlayerLayer()

  override init(frame: CGRect) {
    super.init(frame: frame)
    playerLayer.videoGravity = .resizeAspect
    layer.addSublayer(playerLayer)
  }

  required init?(coder: NSCoder) { nil }

  override func layoutSubviews() {
    super.layoutSubviews()
    playerLayer.frame = bounds
  }
}

final class KometStoryEditorPlatformView: NSObject, FlutterPlatformView {
  private let channel: FlutterMethodChannel
  private let root = UIView()
  private let backdrop = UIImageView()
  private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
  private let dim = UIView()
  private let imageView = UIImageView()
  private let playerHost = KometPlayerHost()
  private var player: AVPlayer?
  private var endObserver: NSObjectProtocol?
  private let segments = UISegmentedControl(items: ["Все", "Контакты"])
  private let publishButton = UIButton(type: .system)
  private let closeButton = UIButton(type: .system)
  private var loadedKey = ""
  private var applying = false

  init(frame: CGRect, viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "ru.komet.app/native_story_editor/\(viewId)", binaryMessenger: messenger)
    super.init()
    root.frame = frame
    root.backgroundColor = .black
    root.clipsToBounds = true
    backdrop.contentMode = .scaleAspectFill
    backdrop.clipsToBounds = true
    imageView.contentMode = .scaleAspectFit
    dim.backgroundColor = UIColor.black.withAlphaComponent(0.25)
    for view in [backdrop, blur, dim, imageView, playerHost] {
      view.frame = root.bounds
      view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      root.addSubview(view)
    }
    segments.selectedSegmentIndex = 0
    segments.addTarget(self, action: #selector(audienceChanged), for: .valueChanged)
    publishButton.setTitle("Опубликовать", for: .normal)
    publishButton.setTitleColor(.black, for: .normal)
    publishButton.setTitleColor(UIColor.black.withAlphaComponent(0.45), for: .disabled)
    publishButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
    publishButton.backgroundColor = .white
    publishButton.layer.cornerRadius = 22
    publishButton.clipsToBounds = true
    publishButton.addTarget(self, action: #selector(publish), for: .touchUpInside)
    closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
    closeButton.tintColor = .white
    closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
    for view in [segments, publishButton, closeButton] {
      view.translatesAutoresizingMaskIntoConstraints = false
      root.addSubview(view)
    }
    NSLayoutConstraint.activate([
      closeButton.leadingAnchor.constraint(equalTo: root.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      closeButton.topAnchor.constraint(equalTo: root.safeAreaLayoutGuide.topAnchor, constant: 8),
      closeButton.widthAnchor.constraint(equalToConstant: 44),
      closeButton.heightAnchor.constraint(equalToConstant: 44),
      segments.centerXAnchor.constraint(equalTo: root.centerXAnchor),
      segments.bottomAnchor.constraint(equalTo: publishButton.topAnchor, constant: -16),
      publishButton.leadingAnchor.constraint(equalTo: root.safeAreaLayoutGuide.leadingAnchor, constant: 20),
      publishButton.trailingAnchor.constraint(equalTo: root.safeAreaLayoutGuide.trailingAnchor, constant: -20),
      publishButton.bottomAnchor.constraint(equalTo: root.safeAreaLayoutGuide.bottomAnchor, constant: -12),
      publishButton.heightAnchor.constraint(equalToConstant: 50),
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
    if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    player?.pause()
    channel.setMethodCallHandler(nil)
  }

  func view() -> UIView { root }

  private func apply(_ map: [String: Any]?) {
    let map = map ?? [:]
    let path = map["path"] as? String ?? ""
    let video = (map["video"] as? NSNumber)?.boolValue ?? false
    let publishing = (map["publishing"] as? NSNumber)?.boolValue ?? false
    publishButton.isEnabled = !publishing
    publishButton.setTitle(publishing ? "Публикация…" : "Опубликовать", for: .normal)
    let audience = (map["audience"] as? NSNumber)?.intValue ?? 1
    let segment = audience == 2 ? 1 : 0
    applying = true
    if segments.selectedSegmentIndex != segment {
      segments.selectedSegmentIndex = segment
    }
    applying = false
    let key = "\(video)|\(path)"
    if key == loadedKey { return }
    loadedKey = key
    load(path: path, video: video)
  }

  private func load(path: String, video: Bool) {
    if let endObserver {
      NotificationCenter.default.removeObserver(endObserver)
      self.endObserver = nil
    }
    player?.pause()
    player = nil
    playerHost.playerLayer.player = nil
    let showVideo = video && !path.isEmpty
    playerHost.isHidden = !showVideo
    imageView.isHidden = showVideo
    backdrop.isHidden = showVideo
    blur.isHidden = showVideo
    dim.isHidden = showVideo
    guard !path.isEmpty else {
      imageView.image = nil
      backdrop.image = nil
      return
    }
    if showVideo {
      let item = AVPlayerItem(url: URL(fileURLWithPath: path))
      let next = AVPlayer(playerItem: item)
      next.actionAtItemEnd = .none
      endObserver = NotificationCenter.default.addObserver(
        forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
      ) { _ in
        next.seek(to: .zero)
        next.play()
      }
      player = next
      playerHost.playerLayer.player = next
      next.play()
      reportDuration(item.asset)
    } else {
      let image = UIImage(contentsOfFile: path)
      imageView.image = image
      backdrop.image = image
    }
  }

  private func reportDuration(_ asset: AVAsset) {
    asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
      var error: NSError?
      guard asset.statusOfValue(forKey: "duration", error: &error) == .loaded else { return }
      let seconds = CMTimeGetSeconds(asset.duration)
      guard seconds.isFinite, seconds > 0 else { return }
      let ms = Int((seconds * 1000).rounded())
      DispatchQueue.main.async {
        self?.channel.invokeMethod("duration", arguments: ["ms": ms])
      }
    }
  }

  @objc private func audienceChanged() {
    if applying { return }
    channel.invokeMethod("audience", arguments: [
      "value": segments.selectedSegmentIndex == 1 ? 2 : 1,
    ])
  }

  @objc private func publish() { channel.invokeMethod("publish", arguments: nil) }
  @objc private func close() { channel.invokeMethod("close", arguments: nil) }
}
