import UIKit

final class KometChatServiceCell: UICollectionViewCell {
  static let reuseIdentifier = "KometChatServiceCell"

  private let label = UILabel()
  private let pill = UIView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    pill.layer.cornerRadius = 12
    pill.layer.cornerCurve = .continuous
    label.font = UIFont.preferredFont(forTextStyle: .footnote)
    label.adjustsFontForContentSizeCategory = true
    label.textAlignment = .center
    label.numberOfLines = 0
    pill.translatesAutoresizingMaskIntoConstraints = false
    label.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(pill)
    pill.addSubview(label)
    NSLayoutConstraint.activate([
      pill.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
      pill.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
      pill.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      pill.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 24),
      pill.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -24),
      label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 12),
      label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -12),
      label.topAnchor.constraint(equalTo: pill.topAnchor, constant: 4),
      label.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -4),
    ])
  }

  required init?(coder: NSCoder) { nil }

  func apply(_ item: KometChatMessage, accent: UIColor, width: CGFloat) {
    contentView.bounds.size.width = width
    label.text = item.text
    let control = item.kind == "control"
    label.textColor = .secondaryLabel
    pill.backgroundColor = control || item.role == .date
      ? UIColor.secondarySystemFill
      : accent.withAlphaComponent(0.16)
    label.textColor = item.role == .unread ? accent : .secondaryLabel
  }
}

final class KometChatMessageCell: UICollectionViewCell {
  static let reuseIdentifier = "KometChatMessageCell"

  var onEvent: ((String, [String: Any]) -> Void)?
  private var item: KometChatMessage?
  private var accent = UIColor.systemBlue

  private let selectionMark = UIImageView()
  private let avatar = UIImageView()
  private let bubble = UIView()
  private let stack = UIStackView()
  private let senderLabel = UILabel()
  private let forwardLabel = UILabel()
  private let replyButton = UIButton(type: .system)
  private let bodyLabel = UILabel()
  private let mediaView = UIImageView()
  private let durationLabel = UILabel()
  private let buttonStack = UIStackView()
  private let playButton = UIButton(type: .system)
  private let transcriptPill = UIButton(type: .system)
  private let transcriptLabel = UILabel()
  private let commentsButton = UIButton(type: .system)
  private let metaLabel = UILabel()
  private let statusView = UIImageView()
  private let reactionStack = UIStackView()
  private let metaRow = UIStackView()
  private var bubbleLeading: NSLayoutConstraint?
  private var bubbleTrailing: NSLayoutConstraint?
  private var avatarWidth: NSLayoutConstraint?
  private var mediaHeight: NSLayoutConstraint?
  private var dragX: CGFloat = 0
  private var replyArmed = false

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionMark.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
    selectionMark.tintColor = .systemBlue
    avatar.layer.cornerRadius = 17
    avatar.clipsToBounds = true
    avatar.contentMode = .scaleAspectFill
    avatar.backgroundColor = .secondarySystemFill
    avatar.isUserInteractionEnabled = true
    avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapAvatar)))
    bubble.layer.cornerCurve = .continuous
    bubble.setContentHuggingPriority(.required, for: .horizontal)
    bubble.setContentCompressionResistancePriority(.required, for: .horizontal)
    stack.axis = .vertical
    stack.spacing = 4
    senderLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
    senderLabel.adjustsFontForContentSizeCategory = true
    forwardLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
    forwardLabel.adjustsFontForContentSizeCategory = true
    forwardLabel.textColor = .secondaryLabel
    replyButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
    replyButton.titleLabel?.numberOfLines = 2
    replyButton.contentHorizontalAlignment = .leading
    replyButton.addTarget(self, action: #selector(tapReply), for: .touchUpInside)
    bodyLabel.font = UIFont.preferredFont(forTextStyle: .body)
    bodyLabel.adjustsFontForContentSizeCategory = true
    bodyLabel.numberOfLines = 0
    mediaView.contentMode = .scaleAspectFill
    mediaView.clipsToBounds = true
    mediaView.layer.cornerRadius = 12
    mediaView.layer.cornerCurve = .continuous
    mediaView.isUserInteractionEnabled = true
    mediaView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapMedia)))
    durationLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
    durationLabel.adjustsFontForContentSizeCategory = true
    buttonStack.axis = .vertical
    buttonStack.spacing = 6
    playButton.tintColor = .white
    playButton.backgroundColor = .white.withAlphaComponent(0.18)
    playButton.layer.cornerRadius = 22
    playButton.addTarget(self, action: #selector(tapVoice), for: .touchUpInside)
    transcriptPill.layer.cornerRadius = 16
    transcriptPill.layer.cornerCurve = .continuous
    transcriptPill.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    transcriptPill.addTarget(self, action: #selector(tapTranscript), for: .touchUpInside)
    transcriptLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
    transcriptLabel.adjustsFontForContentSizeCategory = true
    transcriptLabel.numberOfLines = 0
    commentsButton.contentHorizontalAlignment = .leading
    commentsButton.addTarget(self, action: #selector(tapComments), for: .touchUpInside)
    metaLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
    metaLabel.adjustsFontForContentSizeCategory = true
    statusView.contentMode = .scaleAspectFit
    reactionStack.axis = .horizontal
    reactionStack.spacing = 6
    metaRow.axis = .horizontal
    metaRow.spacing = 4
    metaRow.alignment = .center
    metaRow.addArrangedSubview(metaLabel)
    metaRow.addArrangedSubview(statusView)
    for view in [playButton, senderLabel, forwardLabel, replyButton, bodyLabel, mediaView, durationLabel,
                 buttonStack, transcriptPill, transcriptLabel, commentsButton, metaRow, reactionStack] {
      stack.addArrangedSubview(view)
    }
    stack.setCustomSpacing(2, after: bodyLabel)
    bubble.addSubview(stack)
    contentView.addSubview(selectionMark)
    contentView.addSubview(avatar)
    contentView.addSubview(bubble)
    for view in [selectionMark, avatar, bubble, stack] {
      view.translatesAutoresizingMaskIntoConstraints = false
    }
    let lead = bubble.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 8)
    let trail = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
    lead.priority = .required
    trail.priority = .required
    bubbleLeading = lead
    bubbleTrailing = trail
    let avatarW = avatar.widthAnchor.constraint(equalToConstant: 34)
    avatarWidth = avatarW
    let mediaH = mediaView.heightAnchor.constraint(equalToConstant: 180)
    mediaHeight = mediaH
    NSLayoutConstraint.activate([
      selectionMark.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
      selectionMark.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      selectionMark.widthAnchor.constraint(equalToConstant: 22),
      avatar.leadingAnchor.constraint(equalTo: selectionMark.trailingAnchor, constant: 8),
      avatar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
      avatarW,
      avatar.heightAnchor.constraint(equalToConstant: 34),
      lead, trail,
      bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 1),
      bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -1),
      bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.78),
      stack.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 11),
      stack.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -11),
      stack.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 7),
      stack.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -8),
      mediaH,
      statusView.widthAnchor.constraint(equalToConstant: 14),
      statusView.heightAnchor.constraint(equalToConstant: 14),
      transcriptPill.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),
      playButton.widthAnchor.constraint(equalToConstant: 44),
      playButton.heightAnchor.constraint(equalToConstant: 44),
    ])
    let press = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
    press.minimumPressDuration = 0.35
    contentView.addGestureRecognizer(press)
    contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapRow)))
    let pan = UIPanGestureRecognizer(target: self, action: #selector(swipeReply(_:)))
    pan.delegate = self
    contentView.addGestureRecognizer(pan)
  }

  required init?(coder: NSCoder) { nil }

  override func prepareForReuse() {
    super.prepareForReuse()
    onEvent = nil
    item = nil
    mediaView.image = nil
    dragX = 0
    bubble.transform = .identity
    buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    reactionStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
  }

  func apply(_ item: KometChatMessage, accent: UIColor, selecting: Bool, width: CGFloat) {
    self.item = item
    self.accent = accent
    contentView.bounds.size.width = width
    let incomingFill = UIColor.secondarySystemBackground
    let outgoingFill = accent
    bubble.backgroundColor = item.outgoing ? outgoingFill : incomingFill
    let foreground: UIColor = item.outgoing ? .white : .label
    bodyLabel.textColor = foreground
    senderLabel.textColor = accent
    metaLabel.textColor = item.outgoing ? UIColor.white.withAlphaComponent(0.78) : .secondaryLabel
    statusView.tintColor = metaLabel.textColor
    bubble.layer.cornerRadius = item.cluster == "middle" ? 8 : 18
    selectionMark.isHidden = !selecting
    selectionMark.image = UIImage(systemName: item.selected ? "checkmark.circle.fill" : "circle")
    selectionMark.tintColor = item.selected ? accent : .tertiaryLabel
    avatar.isHidden = !item.showAvatar
    avatarWidth?.constant = item.showAvatar ? 34 : 0
    if item.showAvatar, let url = item.avatarUrl.flatMap(URL.init(string:)) {
      KometChatImages.load(url) { [weak self] image in
        guard self?.item?.id == item.id else { return }
        self?.avatar.image = image
      }
    } else {
      avatar.image = nil
    }
    senderLabel.isHidden = !item.showSender
    senderLabel.text = item.senderName
    forwardLabel.isHidden = item.forwardAuthor == nil
    forwardLabel.text = item.forwardAuthor.map { "Переслано от \($0)" }
    let quote = [item.replyAuthor, item.replyText].compactMap { $0 }.filter { !$0.isEmpty }
    replyButton.isHidden = quote.isEmpty
    replyButton.setTitle(quote.joined(separator: "\n"), for: .normal)
    replyButton.setTitleColor(item.outgoing ? UIColor.white.withAlphaComponent(0.9) : accent, for: .normal)
    bodyLabel.isHidden = item.text.isEmpty || item.kind == "sticker"
    bodyLabel.text = item.text
    let showsMedia = item.mediaUrl != nil && (item.kind == "photo" || item.kind == "video" || item.kind == "sticker")
    mediaView.isHidden = !showsMedia
    mediaHeight?.constant = showsMedia ? (item.kind == "sticker" ? 140 : 180) : 0
    if showsMedia, let url = item.mediaUrl.flatMap(URL.init(string:)) {
      KometChatImages.load(url) { [weak self] image in
        guard self?.item?.id == item.id else { return }
        self?.mediaView.image = image
      }
    }
    playButton.isHidden = item.kind != "voice"
    if item.kind == "voice" {
      let symbol = item.playing ? "pause.fill" : "play.fill"
      playButton.setImage(UIImage(systemName: symbol), for: .normal)
      playButton.tintColor = item.outgoing ? .white : accent
      playButton.backgroundColor = item.outgoing
        ? UIColor.white.withAlphaComponent(0.18)
        : accent.withAlphaComponent(0.14)
    }
    durationLabel.isHidden = item.duration == nil
    durationLabel.text = item.duration
    durationLabel.textColor = foreground
    fillButtons(item, foreground: foreground)
    let voice = item.kind == "voice"
    transcriptPill.isHidden = !voice
    transcriptLabel.isHidden = !voice || !item.transcriptOpen || (item.transcript ?? "").isEmpty
    transcriptLabel.text = item.transcript
    transcriptLabel.textColor = foreground
    if voice {
      transcriptPill.backgroundColor = accent
      transcriptPill.tintColor = .white
      transcriptPill.setTitleColor(.white, for: .normal)
      let title = item.transcriptOpen ? "" : "→Т"
      transcriptPill.setTitle(title, for: .normal)
      let symbol = item.transcriptOpen ? "chevron.up" : nil
      transcriptPill.setImage(symbol.flatMap { UIImage(systemName: $0) }, for: .normal)
    }
    commentsButton.isHidden = item.comments == nil
    commentsButton.setTitle(item.comments, for: .normal)
    metaLabel.text = item.deleted ? "\(item.time)" : item.time
    statusView.isHidden = item.delivery == "none"
    statusView.image = UIImage(systemName: statusSymbol(item.delivery))
    fillReactions(item, accent: accent, outgoing: item.outgoing)
    bubbleLeading?.isActive = !item.outgoing
    bubbleTrailing?.isActive = item.outgoing
    contentView.backgroundColor = item.highlighted ? accent.withAlphaComponent(0.12) : .clear
    setNeedsLayout()
  }

  private func fillButtons(_ item: KometChatMessage, foreground: UIColor) {
    buttonStack.isHidden = item.buttons.isEmpty
    for button in item.buttons {
      let view = UIButton(type: .system)
      view.tag = button.index
      view.setTitle(button.text, for: .normal)
      view.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
      view.titleLabel?.adjustsFontForContentSizeCategory = true
      view.setTitleColor(item.outgoing ? .white : accent, for: .normal)
      view.backgroundColor = item.outgoing
        ? UIColor.white.withAlphaComponent(0.16)
        : accent.withAlphaComponent(0.12)
      view.layer.cornerRadius = 12
      view.layer.cornerCurve = .continuous
      view.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
      view.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
      view.addTarget(self, action: #selector(tapKeyboard(_:)), for: .touchUpInside)
      buttonStack.addArrangedSubview(view)
    }
    _ = foreground
  }

  private func fillReactions(_ item: KometChatMessage, accent: UIColor, outgoing: Bool) {
    reactionStack.isHidden = item.reactions.isEmpty
    for reaction in item.reactions {
      let view = UIButton(type: .system)
      let count = reaction.count > 1 ? " \(reaction.count)" : ""
      view.setTitle(reaction.emoji + count, for: .normal)
      view.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
      view.setTitleColor(outgoing ? .white : .label, for: .normal)
      view.backgroundColor = reaction.mine
        ? accent.withAlphaComponent(outgoing ? 0.35 : 0.18)
        : UIColor.tertiarySystemFill
      view.layer.cornerRadius = 12
      view.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
      view.accessibilityLabel = reaction.emoji
      view.accessibilityIdentifier = reaction.emoji
      view.addTarget(self, action: #selector(tapReaction(_:)), for: .touchUpInside)
      reactionStack.addArrangedSubview(view)
    }
  }

  private func statusSymbol(_ delivery: String) -> String {
    switch delivery {
    case "sending": return "clock"
    case "read": return "checkmark.circle.fill"
    case "error": return "exclamationmark.circle"
    default: return "checkmark"
    }
  }

  @objc private func tapRow() {
    guard let item = item else { return }
    onEvent?(selectionMark.isHidden ? "open" : "select", ["id": item.id])
  }

  @objc private func tapReaction(_ sender: UIButton) {
    guard let id = item?.id, let emoji = sender.accessibilityIdentifier else { return }
    onEvent?("reaction", ["id": id, "emoji": emoji])
  }

  @objc private func longPress(_ gesture: UILongPressGestureRecognizer) {
    guard gesture.state == .began, let item = item else { return }
    let rect = contentView.convert(bubble.frame, to: nil)
    onEvent?("longPress", [
      "id": item.id, "x": rect.minX, "y": rect.minY, "width": rect.width, "height": rect.height,
    ])
  }

  @objc private func tapReply() {
    guard let id = item?.replyId else { return }
    onEvent?("replyJump", ["id": id])
  }

  @objc private func tapMedia() {
    guard let item = item else { return }
    if item.kind == "sticker" {
      onEvent?("sticker", ["id": item.id])
    } else {
      onEvent?("media", ["id": item.id])
    }
  }

  @objc private func tapAvatar() {
    guard let senderId = item?.senderId else { return }
    onEvent?("avatar", ["senderId": senderId])
  }

  @objc private func tapKeyboard(_ sender: UIButton) {
    guard let id = item?.id else { return }
    onEvent?("keyboard", ["id": id, "index": sender.tag])
  }

  @objc private func tapVoice() {
    guard let id = item?.id else { return }
    onEvent?("voice", ["id": id])
  }

  @objc private func tapTranscript() {
    guard let id = item?.id else { return }
    UIView.animate(withDuration: 0.22) {
      self.transcriptPill.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
    } completion: { _ in
      UIView.animate(withDuration: 0.22) { self.transcriptPill.transform = .identity }
    }
    onEvent?("transcribe", ["id": id])
  }

  @objc private func tapComments() {
    guard let id = item?.id else { return }
    onEvent?("comments", ["id": id])
  }

  @objc private func swipeReply(_ gesture: UIPanGestureRecognizer) {
    guard item?.canReply == true else { return }
    let translation = gesture.translation(in: contentView)
    switch gesture.state {
    case .changed:
      var raw = translation.x
      if raw > 0 { raw = 0 }
      if raw < -72 { raw = -72 }
      dragX = raw
      bubble.transform = CGAffineTransform(translationX: raw, y: 0)
      if raw <= -64 && !replyArmed {
        replyArmed = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      }
    case .ended, .cancelled:
      if replyArmed, let id = item?.id {
        onEvent?("reply", ["id": id])
      }
      replyArmed = false
      UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4) {
        self.bubble.transform = .identity
      }
    default:
      break
    }
  }
}

extension KometChatMessageCell: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    let velocity = pan.velocity(in: contentView)
    return abs(velocity.x) > abs(velocity.y) && velocity.x < 0
  }
}

enum KometChatImages {
  private static let cache = NSCache<NSURL, UIImage>()

  static func load(_ url: URL, done: @escaping (UIImage) -> Void) {
    if let cached = cache.object(forKey: url as NSURL) {
      done(cached)
      return
    }
    URLSession.shared.dataTask(with: url) { data, _, _ in
      guard let data = data, let image = UIImage(data: data) else { return }
      cache.setObject(image, forKey: url as NSURL)
      DispatchQueue.main.async { done(image) }
    }.resume()
  }
}
