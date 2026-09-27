import AVFoundation
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

final class KometChatMessageCell: UICollectionViewCell, UIGestureRecognizerDelegate {
  static let reuseIdentifier = "KometChatMessageCell"

  var onEvent: ((String, [String: Any]) -> Void)?
  private var item: KometChatMessage?
  private var accent = UIColor.systemBlue
  private var stickerToken = 0

  private let selectionMark = UIImageView()
  private let avatar = UIImageView()
  private let bubble = UIView()
  private let stack = UIStackView()
  private let senderLabel = UILabel()
  private let forwardLabel = UILabel()
  private let replyButton = UIButton(type: .system)
  private let bodyView = KometChatTextView()
  private let mediaView = UIImageView()
  private let albumStack = UIStackView()
  private let pollStack = UIStackView()
  private var pollSelection = Set<Int>()
  private let durationLabel = UILabel()
  private let buttonStack = UIStackView()
  private let playButton = UIButton(type: .system)
  private let waveView = KometWaveView()
  private let transcriptPill = UIButton(type: .system)
  private let transcriptLabel = UILabel()
  private let commentsButton = UIButton(type: .system)
  private let metaLabel = UILabel()
  private let statusView = UIImageView()
  private let reactionStack = KometReactionFlow()
  private let metaRow = UIStackView()
  private let metaSpacer = UIView()
  private let commentRule = UIView()
  private let commentChevron = UIImageView()
  private var bubbleLeading: NSLayoutConstraint?
  private var bubbleTrailing: NSLayoutConstraint?
  private var wideLeading: NSLayoutConstraint?
  private var wideTrailing: NSLayoutConstraint?
  private var bubbleCap: NSLayoutConstraint?
  private var avatarWidth: NSLayoutConstraint?
  private var mediaHeight: NSLayoutConstraint?
  private var mediaWidth: NSLayoutConstraint?
  private var selectionWidth: NSLayoutConstraint?
  private var selectionLeading: NSLayoutConstraint?
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
    bodyView.delegate = self
    bodyView.preferredWidth = 240
    albumStack.axis = .vertical
    albumStack.spacing = 2
    pollStack.axis = .vertical
    pollStack.spacing = 6
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
    waveView.isHidden = true
    transcriptPill.layer.cornerRadius = 16
    transcriptPill.layer.cornerCurve = .continuous
    transcriptPill.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    transcriptPill.addTarget(self, action: #selector(tapTranscript), for: .touchUpInside)
    transcriptLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
    transcriptLabel.adjustsFontForContentSizeCategory = true
    transcriptLabel.numberOfLines = 0
    commentsButton.contentHorizontalAlignment = .leading
    commentsButton.setImage(UIImage(systemName: "bubble.left"), for: .normal)
    commentsButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 20)
    commentsButton.addTarget(self, action: #selector(tapComments), for: .touchUpInside)
    commentsButton.addSubview(commentChevron)
    commentChevron.image = UIImage(systemName: "chevron.right")
    commentChevron.tintColor = .tertiaryLabel
    commentChevron.contentMode = .scaleAspectFit
    commentChevron.translatesAutoresizingMaskIntoConstraints = false
    commentRule.backgroundColor = .separator
    metaLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
    metaLabel.adjustsFontForContentSizeCategory = true
    metaLabel.setContentHuggingPriority(.required, for: .horizontal)
    statusView.contentMode = .scaleAspectFit
    metaSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    metaRow.axis = .horizontal
    metaRow.spacing = 4
    metaRow.alignment = .center
    metaRow.addArrangedSubview(metaSpacer)
    metaRow.addArrangedSubview(metaLabel)
    metaRow.addArrangedSubview(statusView)
    for view in [mediaView, albumStack, playButton, waveView, senderLabel, forwardLabel, replyButton, bodyView, pollStack, durationLabel,
                 buttonStack, transcriptPill, transcriptLabel, reactionStack, metaRow, commentRule, commentsButton] {
      stack.addArrangedSubview(view)
    }
    stack.setCustomSpacing(2, after: bodyView)
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
    let mediaW = mediaView.widthAnchor.constraint(equalToConstant: 180)
    mediaWidth = mediaW
    mediaView.backgroundColor = .secondarySystemFill
    mediaView.tag = 0
    let markLead = selectionMark.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10)
    let markWidth = selectionMark.widthAnchor.constraint(equalToConstant: 22)
    selectionLeading = markLead
    selectionWidth = markWidth
    wideLeading = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
    wideTrailing = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
    bubbleCap = bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.78)
    bubbleCap?.isActive = true
    NSLayoutConstraint.activate([
      markLead,
      markWidth,
      commentChevron.trailingAnchor.constraint(equalTo: commentsButton.trailingAnchor),
      commentChevron.centerYAnchor.constraint(equalTo: commentsButton.centerYAnchor),
      commentChevron.widthAnchor.constraint(equalToConstant: 13),
      commentChevron.heightAnchor.constraint(equalToConstant: 16),
      commentRule.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
      commentsButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
      selectionMark.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      avatar.leadingAnchor.constraint(equalTo: selectionMark.trailingAnchor, constant: 8),
      avatar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
      avatarW,
      avatar.heightAnchor.constraint(equalToConstant: 34),
      lead, trail,
      bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 1),
      bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -1),
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

  override func layoutSubviews() {
    super.layoutSubviews()
    KometNotePlayback.layout(mediaView)
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    KometNotePlayback.stop(ifHost: mediaView)
    stickerToken += 1
    onEvent = nil
    item = nil
    mediaView.image = nil
    pollSelection.removeAll()
    dragX = 0
    bubble.transform = .identity
    buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    reactionStack.setChips([])
    albumStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    pollStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
  }

  func apply(_ item: KometChatMessage, accent: UIColor, selecting: Bool, width: CGFloat) {
    self.item = item
    self.accent = accent
    contentView.bounds.size.width = width
    let incomingFill = UIColor.secondarySystemBackground
    let outgoingFill = accent
    bubble.backgroundColor = item.outgoing ? outgoingFill : incomingFill
    let foreground: UIColor = item.outgoing ? .white : .label
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
    let showsText = !item.text.isEmpty && item.kind != "sticker"
    bodyView.isHidden = !showsText
    let roundMedia = item.kind == "videoNote" || item.kind == "sticker"
    let showsMedia = item.kind == "sticker" || (
      item.kind != "album" && item.mediaUrl != nil &&
      (item.kind == "photo" || item.kind == "video" || item.kind == "videoNote"))
    let wide = item.wide
    let inner = wide ? max(120, width - 54) : max(120, width * 0.78 - 22)
    var contentWidth = inner
    bodyView.preferredWidth = contentWidth
    if showsText {
      bodyView.attributedText = KometChatText.make(item, foreground: foreground, accent: accent)
    }
    fillAlbum(item)
    fillPoll(item, foreground: foreground, accent: accent)
    mediaView.contentMode = item.kind == "sticker" ? .scaleAspectFit : .scaleAspectFill
    mediaView.isHidden = !showsMedia
    let fitted = fittedMediaSize(
      pixelWidth: item.mediaWidth,
      pixelHeight: item.mediaHeight,
      maxWidth: wide ? inner : min(width * 0.78, inner),
      round: roundMedia,
      sticker: item.kind == "sticker")
    mediaWidth?.constant = fitted.width
    mediaWidth?.isActive = showsMedia
    mediaHeight?.constant = showsMedia ? fitted.height : 0
    mediaView.layer.cornerRadius = item.kind == "videoNote" ? fitted.width / 2 : (wide ? 0 : 12)
    let token = stickerToken
    if showsMedia, let url = mediaURL(item.mediaUrl) {
      KometChatImages.load(url) { [weak self] image in
        guard let self, self.item?.id == item.id, self.stickerToken == token else { return }
        self.mediaView.image = image
      }
    }
    if item.kind == "videoNote", let path = item.playUrl, !path.isEmpty {
      KometNotePlayback.show(id: item.id, path: path, in: mediaView)
    } else {
      KometNotePlayback.stop(ifHost: mediaView)
    }
    bubble.backgroundColor = roundMedia ? .clear : (item.outgoing ? outgoingFill : incomingFill)
    playButton.isHidden = item.kind != "voice"
    waveView.isHidden = item.kind != "voice"
    waveView.isUserInteractionEnabled = item.kind == "voice"
    if waveView.gestureRecognizers?.isEmpty ?? true {
      waveView.addGestureRecognizer(
        UIPanGestureRecognizer(target: self, action: #selector(scrubWave(_:))))
    }
    waveView.amps = item.wave
    waveView.progress = item.progress
    waveView.active = item.outgoing ? .white : accent
    waveView.inactive = (item.outgoing ? UIColor.white : accent).withAlphaComponent(0.35)
    waveView.setNeedsDisplay()
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
    commentsButton.setTitleColor(accent, for: .normal)
    commentsButton.tintColor = accent
    commentChevron.isHidden = item.comments == nil || !item.wide
    commentRule.isHidden = commentChevron.isHidden
    var stamp = item.time
    if item.edited && !stamp.contains("ред.") { stamp += " ред." }
    metaLabel.text = item.deleted ? stamp : stamp
    statusView.isHidden = item.delivery == "none"
    statusView.image = UIImage(systemName: statusSymbol(item.delivery))
    fillReactions(item, accent: accent, outgoing: item.outgoing)
    selectionLeading?.constant = selecting ? 10 : 0
    selectionWidth?.constant = selecting ? 22 : 0
    bubbleLeading?.isActive = !wide && !item.outgoing
    bubbleTrailing?.isActive = !wide && item.outgoing
    wideLeading?.isActive = wide
    wideTrailing?.isActive = wide
    bubbleCap?.isActive = !wide
    if wide {
      bubble.backgroundColor = .secondarySystemBackground
      bubble.layer.cornerRadius = 18
    }
    reactionStack.preferredWidth = contentWidth
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
    var chips: [UIView] = []
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
      view.layer.cornerCurve = .continuous
      view.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
      view.setContentHuggingPriority(.required, for: .horizontal)
      view.setContentCompressionResistancePriority(.required, for: .horizontal)
      view.accessibilityLabel = reaction.emoji
      view.accessibilityIdentifier = reaction.emoji
      view.addTarget(self, action: #selector(tapReaction(_:)), for: .touchUpInside)
      chips.append(view)
    }
    reactionStack.setChips(chips)
  }

  private func statusSymbol(_ delivery: String) -> String {
    switch delivery {
    case "sending": return "clock"
    case "read": return "checkmark.circle.fill"
    case "error": return "exclamationmark.circle"
    default: return "checkmark"
    }
  }

  func showStickerFrame(_ image: UIImage, id: String) {
    guard item?.id == id, item?.kind == "sticker" else { return }
    stickerToken += 1
    mediaView.image = image
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
    openMedia(index: 0)
  }

  @objc private func tapAlbum(_ sender: UIButton) {
    openMedia(index: sender.tag)
  }

  private func openMedia(index: Int) {
    guard let item = item else { return }
    if item.kind == "sticker" {
      onEvent?("sticker", ["id": item.id])
    } else {
      onEvent?("media", ["id": item.id, "index": index])
    }
  }

  private func fillAlbum(_ item: KometChatMessage) {
    albumStack.isHidden = item.kind != "album" || item.media.isEmpty
    guard item.kind == "album" else { return }
    let tiles = Array(item.media.prefix(4))
    var row: UIStackView?
    for (offset, tile) in tiles.enumerated() {
      if offset % 2 == 0 {
        let line = UIStackView()
        line.axis = .horizontal
        line.spacing = 2
        line.distribution = .fillEqually
        line.heightAnchor.constraint(equalToConstant: 96).isActive = true
        albumStack.addArrangedSubview(line)
        row = line
      }
      let button = UIButton(type: .custom)
      button.tag = offset
      button.imageView?.contentMode = .scaleAspectFill
      button.clipsToBounds = true
      button.layer.cornerRadius = 8
      button.addTarget(self, action: #selector(tapAlbum(_:)), for: .touchUpInside)
      if offset == 3 && item.media.count > 4 {
        button.setTitle("+\(item.media.count - 3)", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.45)
      }
      row?.addArrangedSubview(button)
      if let url = URL(string: tile.url) {
        KometChatImages.load(url) { [weak button] image in
          button?.setImage(image, for: .normal)
        }
      }
    }
  }

  private func fillPoll(_ item: KometChatMessage, foreground: UIColor, accent: UIColor) {
    pollStack.isHidden = item.kind != "poll"
    guard item.kind == "poll" else { return }
    if item.pollChoices.isEmpty {
      let waiting = UILabel()
      waiting.text = "Загрузка опроса…"
      waiting.font = UIFont.preferredFont(forTextStyle: .footnote)
      waiting.textColor = foreground.withAlphaComponent(0.7)
      pollStack.addArrangedSubview(waiting)
      return
    }
    let total = item.pollChoices.reduce(0) { $0 + $1.count }
    for choice in item.pollChoices {
      let button = UIButton(type: .system)
      button.tag = choice.id
      let title = item.pollVoted ? "\(choice.text)  \(choice.count)" : choice.text
      button.setTitle(title, for: .normal)
      button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
      button.titleLabel?.numberOfLines = 2
      button.contentHorizontalAlignment = .leading
      button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
      button.layer.cornerRadius = 12
      button.layer.cornerCurve = .continuous
      button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
      let marked = choice.mine || pollSelection.contains(choice.id)
      button.backgroundColor = marked
        ? accent.withAlphaComponent(0.22)
        : UIColor.tertiarySystemFill
      button.setTitleColor(foreground, for: .normal)
      button.isEnabled = !item.pollVoted
      button.addTarget(self, action: #selector(tapPoll(_:)), for: .touchUpInside)
      if item.pollVoted && total > 0 {
        let host = UIView()
        host.layer.cornerRadius = 12
        host.clipsToBounds = true
        host.backgroundColor = UIColor.tertiarySystemFill
        let fill = UIView()
        fill.backgroundColor = accent.withAlphaComponent(0.28)
        fill.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(fill)
        host.addSubview(button)
        let share = max(0.04, CGFloat(choice.count) / CGFloat(total))
        NSLayoutConstraint.activate([
          fill.leadingAnchor.constraint(equalTo: host.leadingAnchor),
          fill.topAnchor.constraint(equalTo: host.topAnchor),
          fill.bottomAnchor.constraint(equalTo: host.bottomAnchor),
          fill.widthAnchor.constraint(equalTo: host.widthAnchor, multiplier: share),
          button.leadingAnchor.constraint(equalTo: host.leadingAnchor),
          button.trailingAnchor.constraint(equalTo: host.trailingAnchor),
          button.topAnchor.constraint(equalTo: host.topAnchor),
          button.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])
        pollStack.addArrangedSubview(host)
      } else {
        pollStack.addArrangedSubview(button)
      }
    }
    if item.pollMultiple && !item.pollVoted {
      let vote = UIButton(type: .system)
      vote.tag = -1
      vote.setTitle("Проголосовать", for: .normal)
      vote.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
      vote.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
      vote.addTarget(self, action: #selector(tapPoll(_:)), for: .touchUpInside)
      pollStack.addArrangedSubview(vote)
    }
  }

  @objc private func tapPoll(_ sender: UIButton) {
    guard let item = item else { return }
    if sender.tag == -1 {
      onEvent?("poll", ["id": item.id, "answers": Array(pollSelection).sorted()])
      return
    }
    if item.pollMultiple {
      if pollSelection.contains(sender.tag) {
        pollSelection.remove(sender.tag)
      } else {
        pollSelection.insert(sender.tag)
      }
      pollStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
      fillPoll(item, foreground: item.outgoing ? .white : .label, accent: accent)
      return
    }
    onEvent?("poll", ["id": item.id, "answers": [sender.tag]])
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

  @objc private func scrubWave(_ gesture: UIPanGestureRecognizer) {
    guard item?.kind == "voice", let id = item?.id else { return }
    let width = max(waveView.bounds.width, 1)
    let fraction = min(1, max(0, gesture.location(in: waveView).x / width))
    waveView.progress = fraction
    onEvent?("voiceSeek", ["id": id, "fraction": fraction])
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

  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    let velocity = pan.velocity(in: contentView)
    return abs(velocity.x) > abs(velocity.y) && velocity.x < 0
  }
}

extension NSAttributedString.Key {
  static let kometQuote = NSAttributedString.Key("kometQuote")
}

final class KometChatTextView: UITextView {
  var preferredWidth: CGFloat = 240 {
    didSet { invalidateIntrinsicContentSize() }
  }

  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    isEditable = false
    isScrollEnabled = false
    backgroundColor = .clear
    textContainerInset = .zero
    self.textContainer.lineFragmentPadding = 0
  }

  required init?(coder: NSCoder) { nil }

  override var intrinsicContentSize: CGSize {
    let limit = max(preferredWidth, 44)
    let fitted = sizeThatFits(CGSize(width: limit, height: .greatestFiniteMagnitude))
    let single = sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: 40))
    let width = min(limit, max(44, ceil(single.width)))
    return CGSize(width: width, height: max(20, ceil(fitted.height)))
  }

  override func draw(_ rect: CGRect) {
    super.draw(rect)
    guard textStorage.length > 0 else { return }
    let full = NSRange(location: 0, length: textStorage.length)
    textStorage.enumerateAttribute(.kometQuote, in: full) { value, range, _ in
      guard value != nil else { return }
      let glyphs = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
      layoutManager.enumerateEnclosingRects(
        forGlyphRange: glyphs,
        withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0),
        in: textContainer
      ) { line, _ in
        let bar = CGRect(x: line.minX - 10, y: line.minY, width: 3, height: line.height)
        UIColor.systemBlue.setFill()
        UIBezierPath(roundedRect: bar, cornerRadius: 1.5).fill()
      }
    }
  }
}

enum KometChatText {
  static func make(_ item: KometChatMessage, foreground: UIColor, accent: UIColor) -> NSAttributedString {
    let font = UIFont.preferredFont(forTextStyle: .body)
    let paragraph = NSMutableParagraphStyle()
    paragraph.hyphenationFactor = 0
    paragraph.lineBreakMode = .byWordWrapping
    let text = NSMutableAttributedString(string: item.text, attributes: [
      .font: font,
      .foregroundColor: foreground,
      .paragraphStyle: paragraph,
    ])
    let limit = (item.text as NSString).length
    for span in item.spans {
      let start = min(max(span.start, 0), limit)
      let end = min(start + max(span.length, 0), limit)
      guard end > start else { continue }
      let range = NSRange(location: start, length: end - start)
      var attributes: [NSAttributedString.Key: Any] = [:]
      var face = font
      if span.styles.contains("mono") {
        face = UIFont.monospacedSystemFont(ofSize: font.pointSize, weight: .regular)
      } else if span.styles.contains("heading") {
        face = UIFont.preferredFont(forTextStyle: .headline)
      }
      var traits = face.fontDescriptor.symbolicTraits
      if span.styles.contains("strong") || span.styles.contains("heading") {
        traits.insert(.traitBold)
      }
      if span.styles.contains("emphasized") {
        traits.insert(.traitItalic)
      }
      if let described = face.fontDescriptor.withSymbolicTraits(traits) {
        attributes[.font] = UIFont(descriptor: described, size: face.pointSize)
      }
      if span.styles.contains("quote") {
        let paragraph = NSMutableParagraphStyle()
        paragraph.hyphenationFactor = 0
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.headIndent = 14
        paragraph.firstLineHeadIndent = 14
        attributes[.paragraphStyle] = paragraph
        attributes[.kometQuote] = true
        attributes[.backgroundColor] = accent.withAlphaComponent(0.12)
      }
      if span.styles.contains("underline") {
        attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
      }
      if span.styles.contains("strike") {
        attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
      }
      if span.styles.contains("link"), let raw = span.url, let link = URL(string: raw) {
        attributes[.link] = link
      }
      if span.styles.contains("mention"), let userId = span.userId,
         let link = URL(string: "komet-user://\(userId)") {
        attributes[.link] = link
        attributes[.foregroundColor] = accent
      }
      if !attributes.isEmpty { text.addAttributes(attributes, range: range) }
    }
    return text
  }
}

extension KometChatMessageCell: UITextViewDelegate {
  func textView(
    _ textView: UITextView,
    shouldInteractWith url: URL,
    in characterRange: NSRange,
    interaction: UITextItemInteraction
  ) -> Bool {
    if url.scheme == "komet-user", let host = url.host, let userId = Int(host) {
      onEvent?("mention", ["userId": userId])
    } else {
      onEvent?("link", ["url": url.absoluteString])
    }
    return false
  }
}

final class KometWaveView: UIView {
  var amps: [Int] = [] { didSet { setNeedsDisplay() } }
  var progress: CGFloat = 0 { didSet { setNeedsDisplay() } }
  var active = UIColor.white { didSet { setNeedsDisplay() } }
  var inactive = UIColor.white.withAlphaComponent(0.35) { didSet { setNeedsDisplay() } }

  override init(frame: CGRect) {
    super.init(frame: frame)
    isOpaque = false
    backgroundColor = .clear
    contentMode = .redraw
  }

  required init?(coder: NSCoder) { nil }

  override var intrinsicContentSize: CGSize {
    CGSize(width: UIView.noIntrinsicMetric, height: 22)
  }

  override func draw(_ rect: CGRect) {
    let barWidth: CGFloat = 2.5
    let gap: CGFloat = 1.75
    let slot = barWidth + gap
    let count = max(amps.count, 1)
    let maxBars = max(1, Int(bounds.width / slot))
    let bars = min(maxBars, count)
    let maxAmp = max(amps.max() ?? 1, 1)
    let step = CGFloat(count) / CGFloat(bars)
    for index in 0..<bars {
      let ampIndex = min(count - 1, Int(CGFloat(index) * step))
      let amp = amps.isEmpty ? 0 : amps[ampIndex]
      let height = amp <= 0 ? 3 : max(3, min(bounds.height, CGFloat(amp) / CGFloat(maxAmp) * bounds.height))
      let x = CGFloat(index) * slot
      let played = (CGFloat(index) + 0.5) / CGFloat(bars) <= progress
      let path = UIBezierPath(
        roundedRect: CGRect(x: x, y: bounds.height - height, width: barWidth, height: height),
        cornerRadius: barWidth / 2)
      (played ? active : inactive).setFill()
      path.fill()
    }
  }
}

enum KometNotePlayback {
  private static var player: AVPlayer?
  private static var itemId: String?
  private static weak var host: UIImageView?
  private static var layer: AVPlayerLayer?
  private static var loop: NSObjectProtocol?

  static func show(id: String, path: String, in view: UIImageView) {
    if itemId == id, host === view, player != nil {
      layout(view)
      return
    }
    stop()
    let item = AVPlayerItem(url: URL(fileURLWithPath: path))
    let next = AVPlayer(playerItem: item)
    next.isMuted = true
    let playerLayer = AVPlayerLayer(player: next)
    playerLayer.videoGravity = .resizeAspectFill
    playerLayer.frame = view.bounds
    view.layer.addSublayer(playerLayer)
    loop = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { _ in
      next.seek(to: .zero)
      next.play()
    }
    player = next
    itemId = id
    host = view
    layer = playerLayer
    next.play()
  }

  static func stop(ifHost view: UIImageView? = nil) {
    if let view, host !== view { return }
    if let loop { NotificationCenter.default.removeObserver(loop) }
    loop = nil
    player?.pause()
    player = nil
    layer?.removeFromSuperlayer()
    layer = nil
    itemId = nil
    host = nil
  }

  static func layout(_ view: UIImageView) {
    guard host === view else { return }
    layer?.frame = view.bounds
  }
}

private func mediaURL(_ raw: String?) -> URL? {
  guard let raw, !raw.isEmpty else { return nil }
  if raw.hasPrefix("/") { return URL(fileURLWithPath: raw) }
  return URL(string: raw)
}

private func fittedMediaSize(
  pixelWidth: Int,
  pixelHeight: Int,
  maxWidth: CGFloat,
  round: Bool,
  sticker: Bool
) -> CGSize {
  if sticker { return CGSize(width: 150, height: 150) }
  if round { return CGSize(width: 180, height: 180) }
  let limit = max(150, maxWidth)
  let aspect: CGFloat = pixelWidth > 0 && pixelHeight > 0
    ? CGFloat(pixelHeight) / CGFloat(pixelWidth)
    : 0.75
  var width = limit
  var height = width * aspect
  let maxHeight = width * 1.3
  if height > maxHeight {
    height = maxHeight
    width = height / max(aspect, 0.01)
  }
  return CGSize(width: max(150, width), height: max(80, height))
}

final class KometReactionFlow: UIView {
  private var chips: [UIView] = []
  var preferredWidth: CGFloat = 240
  func setChips(_ views: [UIView]) {
    chips.forEach { $0.removeFromSuperview() }
    chips = views
    views.forEach(addSubview)
    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }
  override func layoutSubviews() {
    super.layoutSubviews()
    place(width: bounds.width > 1 ? bounds.width : preferredWidth)
  }
  override var intrinsicContentSize: CGSize {
    let used = place(width: preferredWidth)
    return CGSize(width: UIView.noIntrinsicMetric, height: max(1, used))
  }
  @discardableResult
  private func place(width maxW: CGFloat) -> CGFloat {
    var x: CGFloat = 0
    var y: CGFloat = 0
    var row: CGFloat = 0
    for chip in chips {
      let size = chip.intrinsicContentSize
      let w = min(max(1, size.width), maxW)
      if x > 0, x + w > maxW + 0.5 {
        x = 0
        y += row + 6
        row = 0
      }
      chip.frame = CGRect(x: x, y: y, width: w, height: max(28, size.height))
      x += w + 6
      row = max(row, chip.frame.height)
    }
    return chips.isEmpty ? 0 : y + row
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
