import AVFoundation
import Flutter
import UIKit

final class KometStoryViewerViewFactory: NSObject, FlutterPlatformViewFactory {
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
    KometStoryViewerPlatformView(
      frame: frame, viewId: viewId, arguments: args, messenger: messenger)
  }
}

private final class KometPlayerHost: UIView {
  let playerLayer = AVPlayerLayer()

  override init(frame: CGRect) {
    super.init(frame: frame)
    playerLayer.videoGravity = .resizeAspect
    layer.addSublayer(playerLayer)
    isUserInteractionEnabled = false
  }

  required init?(coder: NSCoder) { nil }

  override func layoutSubviews() {
    super.layoutSubviews()
    playerLayer.frame = bounds
  }
}

private final class KometScrim: UIView {
  override class var layerClass: AnyClass { CAGradientLayer.self }

  override init(frame: CGRect) {
    super.init(frame: frame)
    let gradient = layer as! CAGradientLayer
    gradient.colors = [
      UIColor.black.withAlphaComponent(0.55).cgColor,
      UIColor.clear.cgColor,
    ]
    gradient.startPoint = CGPoint(x: 0.5, y: 0)
    gradient.endPoint = CGPoint(x: 0.5, y: 1)
    isUserInteractionEnabled = false
  }

  required init?(coder: NSCoder) { nil }
}

private final class KometStoryBar: UIView {
  private let fill = UIView()
  var fraction: CGFloat = 0 { didSet { setNeedsLayout() } }

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.white.withAlphaComponent(0.28)
    layer.cornerRadius = 1.5
    clipsToBounds = true
    fill.backgroundColor = .white
    addSubview(fill)
  }

  required init?(coder: NSCoder) { nil }

  override func layoutSubviews() {
    super.layoutSubviews()
    let width = bounds.width * min(1, max(0, fraction))
    fill.frame = CGRect(x: 0, y: 0, width: width, height: bounds.height)
  }
}

private final class KometStoryRoot: UIView {
  var onLayout: (() -> Void)?

  override func layoutSubviews() {
    super.layoutSubviews()
    onLayout?()
  }
}

final class KometStoryViewerPlatformView: NSObject, FlutterPlatformView,
  UIGestureRecognizerDelegate, UITextFieldDelegate
{
  private let channel: FlutterMethodChannel
  private let root = KometStoryRoot()
  private let veil = UIView()
  private let card = UIView()
  private let backdrop = UIImageView()
  private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
  private let dim = UIView()
  private let imageView = UIImageView()
  private let playerHost = KometPlayerHost()
  private let scrim = KometScrim()
  private let spinner = UIActivityIndicatorView(style: .large)
  private let emptyLabel = UILabel()
  private let bars = UIStackView()
  private var barViews: [KometStoryBar] = []
  private let avatarView = UIImageView()
  private let nameLabel = UILabel()
  private let timeLabel = UILabel()
  private let closeButton = UIButton(type: .system)
  private let reactionTray = UIStackView()
  private let replyField = UITextField()
  private let reactButton = UIButton(type: .system)
  private let replyRow = UIStackView()
  private let bottomBar = UIStackView()
  private var bottomConstraint: NSLayoutConstraint?
  private var player: AVPlayer?
  private var timeToken: Any?
  private var endObserver: NSObjectProtocol?
  private var keyboardObserver: NSObjectProtocol?
  private var storyKey = ""
  private var storyIndex = 0
  private var headers: [String: String] = [:]
  private var imageToken = 0
  private var avatarToken = 0
  private var loadedAvatar = ""
  private var modeIsVideo = false
  private var photoTimer: Timer?
  private var photoAnchor: CFTimeInterval = 0
  private var photoElapsed: CFTimeInterval = 0
  private var progress: CGFloat = 0
  private var finished = false
  private var pressHold = false
  private var dragHold = false
  private var keyboardHold = false
  private var panAxis = 0
  private var pendingSlide: CATransitionSubtype?
  private var revealed = false
  private var closing = false
  private var keyboardOverlap: CGFloat = 0
  private var loadedMediaKey = ""
  private var originX: CGFloat?
  private var originY: CGFloat?
  private let reactionsFallback = ["❤️", "🔥", "👍", "😂", "😮", "😢"]

  init(frame: CGRect, viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "ru.komet.app/native_story_viewer/\(viewId)", binaryMessenger: messenger)
    super.init()
    root.frame = frame
    root.backgroundColor = .clear
    root.isOpaque = false
    veil.backgroundColor = .black
    veil.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    veil.frame = root.bounds
    card.backgroundColor = .black
    card.clipsToBounds = true
    backdrop.contentMode = .scaleAspectFill
    backdrop.clipsToBounds = true
    imageView.contentMode = .scaleAspectFit
    dim.backgroundColor = UIColor.black.withAlphaComponent(0.15)
    for view in [backdrop, blur, dim, imageView, playerHost, scrim] {
      view.translatesAutoresizingMaskIntoConstraints = false
      view.isUserInteractionEnabled = false
      card.addSubview(view)
    }
    spinner.color = .white
    spinner.hidesWhenStopped = true
    emptyLabel.text = "Историй нет"
    emptyLabel.textColor = UIColor.white.withAlphaComponent(0.7)
    emptyLabel.font = .preferredFont(forTextStyle: .body)
    emptyLabel.isHidden = true
    bars.axis = .horizontal
    bars.spacing = 5
    bars.distribution = .fillEqually
    avatarView.contentMode = .scaleAspectFill
    avatarView.clipsToBounds = true
    avatarView.layer.cornerRadius = 17
    avatarView.backgroundColor = UIColor.white.withAlphaComponent(0.16)
    nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
    nameLabel.textColor = .white
    nameLabel.layer.shadowColor = UIColor.black.cgColor
    nameLabel.layer.shadowOpacity = 0.6
    nameLabel.layer.shadowRadius = 4
    nameLabel.layer.shadowOffset = .zero
    timeLabel.font = .systemFont(ofSize: 12, weight: .regular)
    timeLabel.textColor = UIColor.white.withAlphaComponent(0.8)
    closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
    closeButton.tintColor = .white
    closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.14)
    closeButton.layer.cornerRadius = 22
    closeButton.accessibilityLabel = "Закрыть"
    closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    reactionTray.axis = .horizontal
    reactionTray.spacing = 8
    reactionTray.distribution = .fillEqually
    reactionTray.isHidden = true
    replyField.attributedPlaceholder = NSAttributedString(
      string: "Ответить…",
      attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.65)]
    )
    replyField.textColor = .white
    replyField.font = .preferredFont(forTextStyle: .body)
    replyField.returnKeyType = .send
    replyField.delegate = self
    replyField.keyboardAppearance = .dark
    reactButton.tintColor = .white
    reactButton.titleLabel?.font = .systemFont(ofSize: 26)
    reactButton.backgroundColor = UIColor.white.withAlphaComponent(0.14)
    reactButton.layer.cornerRadius = 22
    reactButton.addTarget(self, action: #selector(toggleReactions), for: .touchUpInside)
    showReaction("")
    replyRow.axis = .horizontal
    replyRow.spacing = 8
    replyRow.alignment = .fill
    let fieldChrome = UIView()
    fieldChrome.backgroundColor = UIColor.white.withAlphaComponent(0.16)
    fieldChrome.layer.cornerRadius = 22
    replyField.translatesAutoresizingMaskIntoConstraints = false
    fieldChrome.addSubview(replyField)
    NSLayoutConstraint.activate([
      replyField.leadingAnchor.constraint(equalTo: fieldChrome.leadingAnchor, constant: 16),
      replyField.trailingAnchor.constraint(equalTo: fieldChrome.trailingAnchor, constant: -12),
      replyField.topAnchor.constraint(equalTo: fieldChrome.topAnchor),
      replyField.bottomAnchor.constraint(equalTo: fieldChrome.bottomAnchor),
    ])
    replyRow.addArrangedSubview(fieldChrome)
    replyRow.addArrangedSubview(reactButton)
    reactButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
    bottomBar.axis = .vertical
    bottomBar.spacing = 10
    bottomBar.addArrangedSubview(reactionTray)
    bottomBar.addArrangedSubview(replyRow)
    reactionTray.heightAnchor.constraint(equalToConstant: 44).isActive = true
    replyRow.heightAnchor.constraint(equalToConstant: 44).isActive = true

    let header = UIStackView(arrangedSubviews: [avatarView, nameBlock(), closeButton])
    header.axis = .horizontal
    header.alignment = .center
    header.spacing = 10
    avatarView.widthAnchor.constraint(equalToConstant: 34).isActive = true
    avatarView.heightAnchor.constraint(equalToConstant: 34).isActive = true
    closeButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
    closeButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

    for view in [spinner, emptyLabel, bars, header, bottomBar] {
      view.translatesAutoresizingMaskIntoConstraints = false
      card.addSubview(view)
    }
    card.translatesAutoresizingMaskIntoConstraints = false
    root.addSubview(veil)
    root.addSubview(card)
    let bottom = bottomBar.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -20)
    bottomConstraint = bottom
    NSLayoutConstraint.activate([
      card.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      card.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      card.topAnchor.constraint(equalTo: root.topAnchor),
      card.bottomAnchor.constraint(equalTo: root.bottomAnchor),
      backdrop.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      backdrop.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      backdrop.topAnchor.constraint(equalTo: card.topAnchor),
      backdrop.bottomAnchor.constraint(equalTo: card.bottomAnchor),
      blur.leadingAnchor.constraint(equalTo: backdrop.leadingAnchor),
      blur.trailingAnchor.constraint(equalTo: backdrop.trailingAnchor),
      blur.topAnchor.constraint(equalTo: backdrop.topAnchor),
      blur.bottomAnchor.constraint(equalTo: backdrop.bottomAnchor),
      dim.leadingAnchor.constraint(equalTo: backdrop.leadingAnchor),
      dim.trailingAnchor.constraint(equalTo: backdrop.trailingAnchor),
      dim.topAnchor.constraint(equalTo: backdrop.topAnchor),
      dim.bottomAnchor.constraint(equalTo: backdrop.bottomAnchor),
      imageView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      imageView.topAnchor.constraint(equalTo: card.topAnchor),
      imageView.bottomAnchor.constraint(equalTo: card.bottomAnchor),
      playerHost.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      playerHost.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      playerHost.topAnchor.constraint(equalTo: card.topAnchor),
      playerHost.bottomAnchor.constraint(equalTo: card.bottomAnchor),
      scrim.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      scrim.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      scrim.topAnchor.constraint(equalTo: card.topAnchor),
      scrim.heightAnchor.constraint(equalToConstant: 150),
      spinner.centerXAnchor.constraint(equalTo: card.centerXAnchor),
      spinner.centerYAnchor.constraint(equalTo: card.centerYAnchor),
      emptyLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
      emptyLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
      bars.leadingAnchor.constraint(equalTo: card.safeAreaLayoutGuide.leadingAnchor, constant: 10),
      bars.trailingAnchor.constraint(equalTo: card.safeAreaLayoutGuide.trailingAnchor, constant: -10),
      bars.topAnchor.constraint(equalTo: card.safeAreaLayoutGuide.topAnchor, constant: 10),
      bars.heightAnchor.constraint(equalToConstant: 3),
      header.leadingAnchor.constraint(equalTo: card.safeAreaLayoutGuide.leadingAnchor, constant: 14),
      header.trailingAnchor.constraint(equalTo: card.safeAreaLayoutGuide.trailingAnchor, constant: -8),
      header.topAnchor.constraint(equalTo: bars.bottomAnchor, constant: 8),
      bottomBar.leadingAnchor.constraint(equalTo: card.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      bottomBar.trailingAnchor.constraint(equalTo: card.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      bottom,
    ])
    let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
    let hold = UILongPressGestureRecognizer(target: self, action: #selector(held))
    let pan = UIPanGestureRecognizer(target: self, action: #selector(panned))
    tap.delegate = self
    hold.delegate = self
    pan.delegate = self
    hold.minimumPressDuration = 0.2
    tap.require(toFail: pan)
    tap.require(toFail: hold)
    root.addGestureRecognizer(tap)
    root.addGestureRecognizer(hold)
    root.addGestureRecognizer(pan)
    root.onLayout = { [weak self] in
      self?.revealIfNeeded()
      self?.liftBottom()
    }
    keyboardObserver = NotificationCenter.default.addObserver(
      forName: UIResponder.keyboardWillChangeFrameNotification,
      object: nil,
      queue: .main
    ) { [weak self] note in
      self?.keyboard(note)
    }
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
    stopPlayer()
    photoTimer?.invalidate()
    if let keyboardObserver { NotificationCenter.default.removeObserver(keyboardObserver) }
    channel.setMethodCallHandler(nil)
  }

  func view() -> UIView { root }

  private func nameBlock() -> UIStackView {
    let column = UIStackView(arrangedSubviews: [nameLabel, timeLabel])
    column.axis = .vertical
    column.spacing = 1
    return column
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    var view = touch.view
    while let current = view {
      if current is UIControl { return false }
      view = current.superview
    }
    return true
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    let text = textField.text ?? ""
    textField.text = ""
    textField.resignFirstResponder()
    channel.invokeMethod("reply", arguments: ["text": text])
    return false
  }

  private func apply(_ map: [String: Any]?) {
    let map = map ?? [:]
    let key = map["key"] as? String ?? ""
    let count = max(1, (map["count"] as? NSNumber)?.intValue ?? 1)
    let index = min(count - 1, max(0, (map["index"] as? NSNumber)?.intValue ?? 0))
    headers = stringMap(map["headers"])
    nameLabel.text = map["name"] as? String ?? "…"
    timeLabel.text = map["timeLabel"] as? String ?? ""
    timeLabel.isHidden = timeLabel.text?.isEmpty ?? true
    let loading = flag(map, "loading")
    let empty = flag(map, "empty")
    emptyLabel.isHidden = !empty
    if loading { spinner.startAnimating() } else { spinner.stopAnimating() }
    let canReply = flag(map, "canReply")
    let canReact = flag(map, "canReact")
    replyField.superview?.isHidden = !canReply
    reactButton.isHidden = !canReact
    bottomBar.isHidden = !canReply && !canReact
    if !canReact { reactionTray.isHidden = true }
    showReaction(map["reaction"] as? String ?? "")
    rebuildReactions(map["reactions"] as? [String] ?? reactionsFallback)
    let avatar = map["avatarUrl"] as? String ?? ""
    if avatar != loadedAvatar {
      loadedAvatar = avatar
      loadAvatar(avatar)
    }
    if let x = map["originX"] as? NSNumber, let y = map["originY"] as? NSNumber {
      originX = CGFloat(x.doubleValue)
      originY = CGFloat(y.doubleValue)
    }
    let isHold = key.hasPrefix("hold:")
    let changed = !isHold && key != storyKey && !key.isEmpty
    if changed {
      storyKey = key
      resetClock()
      if let slide = pendingSlide {
        pendingSlide = nil
        let transition = CATransition()
        transition.duration = 0.28
        transition.type = .push
        transition.subtype = slide
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        card.layer.add(transition, forKey: "owner")
      }
    }
    storyIndex = index
    ensureBars(count)
    paintBars()
    if changed && key != loadedMediaKey {
      loadedMediaKey = key
      loadMedia(
        imageUrl: map["imageUrl"] as? String,
        videoUrl: map["videoUrl"] as? String,
        thumbnail: map["thumbnailUrl"] as? String,
        preview: map["preview"] as? String
      )
    }
    if isHold && loading {
      pauseClock()
    } else if loading || empty {
      pauseClock()
    } else {
      syncClock()
    }
    liftBottom()
  }

  @objc private func reactionTapped(_ sender: UIButton) {
    reactionTray.isHidden = true
    channel.invokeMethod("react", arguments: ["emoji": sender.title(for: .normal) ?? ""])
  }

  private func rebuildReactions(_ emojis: [String]) {
    let items = emojis.isEmpty ? reactionsFallback : emojis
    if reactionTray.arrangedSubviews.count == items.count { return }
    for view in reactionTray.arrangedSubviews { view.removeFromSuperview() }
    for emoji in items {
      let button = UIButton(type: .system)
      button.setTitle(emoji, for: .normal)
      button.titleLabel?.font = .systemFont(ofSize: 26)
      button.backgroundColor = UIColor.white.withAlphaComponent(0.14)
      button.layer.cornerRadius = 22
      button.addTarget(self, action: #selector(reactionTapped(_:)), for: .touchUpInside)
      reactionTray.addArrangedSubview(button)
    }
  }

  private func showReaction(_ emoji: String) {
    if emoji.isEmpty {
      reactButton.setTitle(nil, for: .normal)
      reactButton.setImage(UIImage(systemName: "heart"), for: .normal)
    } else {
      reactButton.setImage(nil, for: .normal)
      reactButton.setTitle(emoji, for: .normal)
    }
  }

  private func ensureBars(_ count: Int) {
    if barViews.count == count { return }
    for view in barViews { view.removeFromSuperview() }
    barViews = (0..<count).map { _ in KometStoryBar() }
    for bar in barViews { bars.addArrangedSubview(bar) }
  }

  private func paintBars() {
    for (offset, bar) in barViews.enumerated() {
      if offset < storyIndex {
        bar.fraction = 1
      } else if offset > storyIndex {
        bar.fraction = 0
      } else {
        bar.fraction = progress
      }
    }
  }

  private func loadMedia(imageUrl: String?, videoUrl: String?, thumbnail: String?, preview: String?) {
    stopPlayer()
    let previewImage = decodePreview(preview)
    backdrop.image = previewImage
    modeIsVideo = false
    playerHost.isHidden = true
    if let videoUrl, !videoUrl.isEmpty, let url = URL(string: videoUrl) {
      modeIsVideo = true
      playerHost.isHidden = false
      imageView.image = previewImage
      if let thumbnail, !thumbnail.isEmpty { loadImage(thumbnail, intoAvatar: false) }
      let asset = makeAsset(url)
      let item = AVPlayerItem(asset: asset)
      let next = AVPlayer(playerItem: item)
      next.actionAtItemEnd = .pause
      player = next
      playerHost.playerLayer.player = next
      endObserver = NotificationCenter.default.addObserver(
        forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
      ) { [weak self] _ in
        self?.finish()
      }
      let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
      timeToken = next.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
        guard let self, self.modeIsVideo else { return }
        let total = CMTimeGetSeconds(item.duration)
        guard total.isFinite, total > 0 else { return }
        self.progress = CGFloat(min(1, max(0, CMTimeGetSeconds(time) / total)))
        self.paintBars()
      }
      asset.loadValuesAsynchronously(forKeys: ["playable"]) { [weak self] in
        DispatchQueue.main.async {
          guard let self, self.player === next else { return }
          if asset.statusOfValue(forKey: "playable", error: nil) == .failed {
            self.fallBackToPhoto()
          }
        }
      }
      return
    }
    if let imageUrl, !imageUrl.isEmpty {
      imageView.image = previewImage
      loadImage(imageUrl, intoAvatar: false)
    } else {
      imageView.image = previewImage
    }
  }

  private func fallBackToPhoto() {
    modeIsVideo = false
    stopPlayer()
    playerHost.isHidden = true
    syncClock()
  }

  private func makeAsset(_ url: URL) -> AVURLAsset {
    if headers.isEmpty { return AVURLAsset(url: url) }
    return AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
  }

  private func loadImage(_ urlString: String, intoAvatar: Bool) {
    if intoAvatar {
      avatarToken += 1
    } else {
      imageToken += 1
    }
    let token = intoAvatar ? avatarToken : imageToken
    guard let url = URL(string: urlString) else { return }
    var request = URLRequest(url: url)
    headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
    URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
      guard let self, let data, let image = UIImage(data: data) else { return }
      DispatchQueue.main.async {
        if intoAvatar {
          guard token == self.avatarToken else { return }
          self.avatarView.image = image
        } else {
          guard token == self.imageToken else { return }
          self.imageView.image = image
          if self.backdrop.image == nil { self.backdrop.image = image }
        }
      }
    }.resume()
  }

  private func loadAvatar(_ urlString: String) {
    avatarView.image = nil
    if urlString.isEmpty { return }
    loadImage(urlString, intoAvatar: true)
  }

  private func decodePreview(_ raw: String?) -> UIImage? {
    guard let raw, !raw.isEmpty else { return nil }
    let payload: String
    if let comma = raw.lastIndex(of: ",") {
      payload = String(raw[raw.index(after: comma)...])
    } else {
      payload = raw
    }
    guard let data = Data(base64Encoded: payload) else { return nil }
    return UIImage(data: data)
  }

  private var holding: Bool { pressHold || dragHold || keyboardHold }

  private func resetClock() {
    photoTimer?.invalidate()
    photoTimer = nil
    photoElapsed = 0
    photoAnchor = 0
    progress = 0
    finished = false
    pressHold = false
    dragHold = false
  }

  private func pauseClock() {
    player?.pause()
    if photoTimer != nil {
      photoElapsed += CACurrentMediaTime() - photoAnchor
      photoTimer?.invalidate()
      photoTimer = nil
    }
  }

  private func syncClock() {
    if holding || finished {
      pauseClock()
      return
    }
    if modeIsVideo {
      photoTimer?.invalidate()
      photoTimer = nil
      player?.play()
      return
    }
    if photoTimer != nil { return }
    photoAnchor = CACurrentMediaTime()
    photoTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
      self?.tickPhoto()
    }
  }

  private func tickPhoto() {
    let elapsed = photoElapsed + (CACurrentMediaTime() - photoAnchor)
    progress = CGFloat(min(1, elapsed / 5.0))
    paintBars()
    if elapsed >= 5 { finish() }
  }

  private func finish() {
    if finished || storyKey.isEmpty { return }
    finished = true
    pauseClock()
    channel.invokeMethod("ended", arguments: ["key": storyKey])
  }

  private func stopPlayer() {
    if let timeToken, let player { player.removeTimeObserver(timeToken) }
    timeToken = nil
    if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    endObserver = nil
    player?.pause()
    player = nil
    playerHost.playerLayer.player = nil
  }

  @objc private func tapped(_ gesture: UITapGestureRecognizer) {
    if replyField.isFirstResponder {
      replyField.resignFirstResponder()
      return
    }
    let point = gesture.location(in: root)
    if point.x < root.bounds.width * 0.32 {
      channel.invokeMethod("rewind", arguments: ["key": storyKey])
    } else {
      channel.invokeMethod("advance", arguments: ["key": storyKey])
    }
  }

  @objc private func held(_ gesture: UILongPressGestureRecognizer) {
    if gesture.state == .began { pressHold = true }
    if gesture.state == .ended || gesture.state == .cancelled { pressHold = false }
    syncClock()
  }

  @objc private func panned(_ gesture: UIPanGestureRecognizer) {
    let translation = gesture.translation(in: root)
    let velocity = gesture.velocity(in: root)
    switch gesture.state {
    case .began:
      panAxis = 0
      dragHold = true
      syncClock()
    case .changed:
      if panAxis == 0 {
        if abs(translation.x) < 12 && abs(translation.y) < 12 { return }
        panAxis = abs(translation.y) >= abs(translation.x) ? 1 : 2
      }
      if panAxis == 1 {
        let dy = min(600, max(-40, translation.y))
        let amount = min(1, abs(dy) / 320)
        card.transform = CGAffineTransform(translationX: 0, y: dy)
          .scaledBy(x: 1 - amount * 0.12, y: 1 - amount * 0.12)
        card.layer.cornerRadius = amount * 26
        veil.alpha = 1 - amount * 0.7
      } else {
        card.transform = CGAffineTransform(translationX: translation.x, y: 0)
      }
    case .ended, .cancelled:
      let dismiss = panAxis == 1 && (translation.y > 120 || velocity.y > 700)
      let forward = panAxis == 2 && (translation.x < -80 || velocity.x < -700)
      let backward = panAxis == 2 && (translation.x > 80 || velocity.x > 700)
      dragHold = false
      panAxis = 0
      if dismiss {
        closeAnimated()
        return
      }
      UIView.animate(withDuration: 0.32, delay: 0, options: .curveEaseOut) {
        self.card.transform = .identity
        self.card.layer.cornerRadius = 0
        self.veil.alpha = 1
      }
      if forward {
        pendingSlide = .fromRight
        askOwner("nextOwner")
      } else if backward {
        pendingSlide = .fromLeft
        askOwner("prevOwner")
      } else {
        syncClock()
      }
    default:
      break
    }
  }

  private func askOwner(_ method: String) {
    channel.invokeMethod(method, arguments: ["key": storyKey]) { [weak self] result in
      if (result as? NSNumber)?.boolValue != true {
        self?.pendingSlide = nil
        self?.syncClock()
      }
    }
  }

  @objc private func closeTapped() { closeAnimated() }

  @objc private func toggleReactions() {
    reactionTray.isHidden.toggle()
  }

  private func closeAnimated() {
    if closing { return }
    closing = true
    pauseClock()
    UIView.animate(withDuration: 0.28, animations: {
      self.root.alpha = 0
      self.card.transform = self.card.transform.scaledBy(x: 0.96, y: 0.96)
    }, completion: { _ in
      self.channel.invokeMethod("dismiss", arguments: nil)
    })
  }

  private func keyboard(_ note: Notification) {
    guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
    let local = root.convert(frame, from: nil)
    let overlap = max(0, root.bounds.maxY - local.minY)
    keyboardOverlap = overlap
    keyboardHold = overlap > 80
    liftBottom()
    let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
    UIView.animate(withDuration: duration) { self.root.layoutIfNeeded() }
    syncClock()
  }

  private func liftBottom() {
    let lift = max(root.safeAreaInsets.bottom, keyboardOverlap) + 8
    if bottomConstraint?.constant != -lift {
      bottomConstraint?.constant = -lift
    }
  }

  private func revealIfNeeded() {
    if revealed || root.bounds.width < 1 || root.window == nil { return }
    revealed = true
    guard let originX, let originY else { return }
    let center = root.convert(CGPoint(x: originX, y: originY), from: nil)
    let bounds = root.bounds
    let corners = [
      CGPoint(x: bounds.minX, y: bounds.minY),
      CGPoint(x: bounds.maxX, y: bounds.minY),
      CGPoint(x: bounds.minX, y: bounds.maxY),
      CGPoint(x: bounds.maxX, y: bounds.maxY),
    ]
    let radius = corners.map { hypot($0.x - center.x, $0.y - center.y) }.max() ?? bounds.width
    let mask = CAShapeLayer()
    let start = UIBezierPath(ovalIn: CGRect(x: center.x - 28, y: center.y - 28, width: 56, height: 56))
    let end = UIBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    mask.path = end.cgPath
    root.layer.mask = mask
    let animation = CABasicAnimation(keyPath: "path")
    animation.fromValue = start.cgPath
    animation.toValue = end.cgPath
    animation.duration = 0.42
    animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
    mask.add(animation, forKey: "reveal")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) { [weak self] in
      self?.root.layer.mask = nil
    }
  }

  private func flag(_ map: [String: Any], _ key: String) -> Bool {
    if let value = map[key] as? Bool { return value }
    return (map[key] as? NSNumber)?.boolValue ?? false
  }

  private func stringMap(_ raw: Any?) -> [String: String] {
    guard let raw = raw as? [String: Any] else { return [:] }
    var out: [String: String] = [:]
    for (key, value) in raw {
      if let value = value as? String { out[key] = value }
    }
    return out
  }
}
