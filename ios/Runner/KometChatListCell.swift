import UIKit

struct KometChatEditState: Equatable {
  var editing = false
  var selected = false
  var reorderable = false
}

final class KometChatListCell: UICollectionViewCell {
  static let reuseIdentifier = "KometChatListCell"
  static let editShift: CGFloat = 42
  static let gripWidth: CGFloat = 56

  private let avatarView = UIImageView()
  private let kindIcon = UIImageView()
  private let titleLabel = UILabel()
  private let mutedIcon = UIImageView()
  private let verifiedIcon = UIImageView()
  private let lockIcon = UIImageView()
  private let statusIcon = UIImageView()
  private let readIcon = UIImageView()
  private let timeLabel = UILabel()
  private let authorLabel = UILabel()
  private let previewLabel = UILabel()
  private let badgeView = UIView()
  private let badgeLabel = UILabel()
  private let mentionView = UIView()
  private let mentionLabel = UILabel()
  private let pinIcon = UIImageView()
  private let separator = UIView()
  private let checkView = UIImageView()
  private let gripView = UIImageView()

  private var avatarUrl = ""
  private var baseBackground: UIColor = .systemBackground
  private var accent: UIColor = .systemBlue
  private(set) var editState = KometChatEditState()

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.isOpaque = true
    avatarView.contentMode = .scaleAspectFill
    titleLabel.font = KometChatListStyle.titleFont
    titleLabel.textColor = .label
    timeLabel.font = KometChatListStyle.timeFont
    timeLabel.textColor = KometChatListStyle.secondary
    timeLabel.textAlignment = .right
    authorLabel.font = KometChatListStyle.bodyFont
    authorLabel.textColor = .label
    previewLabel.lineBreakMode = .byTruncatingTail
    badgeLabel.font = KometChatListStyle.badgeFont
    badgeLabel.textColor = .white
    badgeLabel.textAlignment = .center
    badgeView.addSubview(badgeLabel)
    mentionLabel.font = KometChatListStyle.badgeFont
    mentionLabel.textColor = .white
    mentionLabel.textAlignment = .center
    mentionLabel.text = "@"
    mentionView.addSubview(mentionLabel)
    kindIcon.tintColor = .label
    mutedIcon.tintColor = KometChatListStyle.secondary
    mutedIcon.image = KometChatListStyle.symbol("speaker.slash.fill", size: 13)
    lockIcon.tintColor = .systemGreen
    lockIcon.image = KometChatListStyle.symbol("lock.fill", size: 12, weight: .semibold)
    pinIcon.tintColor = KometChatListStyle.secondary
    pinIcon.image = KometChatListStyle.symbol("pin.fill", size: 15)
    separator.backgroundColor = .separator
    checkView.contentMode = .center
    gripView.contentMode = .center
    gripView.tintColor = KometChatListStyle.secondary
    gripView.image = KometChatListStyle.symbol("line.3.horizontal", size: 17, weight: .medium)
    [avatarView, kindIcon, titleLabel, mutedIcon, verifiedIcon, lockIcon, statusIcon, readIcon,
     timeLabel, authorLabel, previewLabel, badgeView, mentionView, pinIcon, separator,
     checkView, gripView]
      .forEach(contentView.addSubview)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override var isHighlighted: Bool {
    didSet { applyBackground() }
  }

  override var isSelected: Bool {
    didSet { applyBackground() }
  }

  private func applyBackground() {
    let pressed = (isHighlighted || isSelected) && !editState.editing
    contentView.backgroundColor = pressed ? .systemGray5 : baseBackground
  }

  func gripContains(_ point: CGPoint) -> Bool {
    editState.reorderable && point.x >= contentView.bounds.width - KometChatListCell.gripWidth
  }

  func applyEditState(_ state: KometChatEditState, animated: Bool) {
    guard state != editState else { return }
    editState = state
    applyEditVisuals()
    applyBackground()
    guard animated, window != nil else {
      setNeedsLayout()
      return
    }
    UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1,
                   initialSpringVelocity: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
      self.setNeedsLayout()
      self.layoutIfNeeded()
    }
  }

  private func applyEditVisuals() {
    let symbol = editState.selected ? "checkmark.circle.fill" : "circle"
    checkView.image = KometChatListStyle.symbol(symbol, size: 22, weight: .regular)
    checkView.tintColor = editState.selected ? accent : KometChatListStyle.mutedBadge
    checkView.alpha = editState.editing ? 1 : 0
    gripView.alpha = editState.reorderable ? 1 : 0
    let trailing: CGFloat = editState.reorderable ? 0 : 1
    [timeLabel, statusIcon, readIcon, badgeView, mentionView, pinIcon].forEach {
      $0.alpha = trailing
    }
  }

  func configure(_ content: KometChatRowContent, accent: UIColor, showsSeparator: Bool,
                 editState: KometChatEditState) {
    self.accent = accent
    self.editState = editState
    let row = content.row
    baseBackground = row.pinned ? KometChatListStyle.pinnedBackground : .systemBackground
    applyBackground()

    let scale = traitCollection.displayScale > 0 ? traitCollection.displayScale : UIScreen.main.scale
    let side = KometChatListStyle.avatarSize
    avatarUrl = row.avatarUrl
    if !row.saved, !row.avatarUrl.isEmpty,
       let image = KometAvatarCache.shared.cached(row.avatarUrl, side: side) {
      avatarView.image = image
    } else {
      avatarView.image = KometAvatarCache.shared.placeholder(
        for: row, side: side, scale: scale, accent: accent)
      if !row.saved, !row.avatarUrl.isEmpty {
        let requested = row.avatarUrl
        KometAvatarCache.shared.load(requested, side: side, scale: scale) { [weak self] image in
          guard let self = self, self.avatarUrl == requested else { return }
          self.avatarView.image = image
        }
      }
    }

    kindIcon.image = KometChatListStyle.kindImage(row.kind)
    kindIcon.isHidden = kindIcon.image == nil
    titleLabel.text = row.title
    mutedIcon.isHidden = !row.muted
    verifiedIcon.isHidden = !row.verified
    verifiedIcon.tintColor = accent
    verifiedIcon.image = KometChatListStyle.symbol("checkmark.seal.fill", size: 14)
    lockIcon.isHidden = !row.encrypted

    timeLabel.text = row.time
    configureStatus(row.status, accent: accent)

    authorLabel.text = row.author
    authorLabel.isHidden = content.previewLines == 2
    previewLabel.attributedText = content.preview
    previewLabel.numberOfLines = content.previewLines

    badgeView.isHidden = row.unread <= 0
    badgeView.backgroundColor = row.muted ? KometChatListStyle.mutedBadge : accent
    badgeLabel.text = KometChatListCell.badgeText(row.unread)
    mentionView.isHidden = !row.mention
    mentionView.backgroundColor = accent
    pinIcon.isHidden = !(row.pinned && row.unread <= 0 && !row.mention)
    separator.isHidden = !showsSeparator
    applyEditVisuals()
    applyBackground()
    setNeedsLayout()
  }

  private func configureStatus(_ status: KometChatStatus?, accent: UIColor) {
    readIcon.isHidden = true
    switch status {
    case .none:
      statusIcon.isHidden = true
    case .some(.sending):
      statusIcon.isHidden = false
      statusIcon.tintColor = KometChatListStyle.secondary
      statusIcon.image = KometChatListStyle.symbol("clock", size: 12)
    case .some(.error):
      statusIcon.isHidden = false
      statusIcon.tintColor = .systemRed
      statusIcon.image = KometChatListStyle.symbol("exclamationmark.circle.fill", size: 13)
    case .some(.sent):
      statusIcon.isHidden = false
      statusIcon.tintColor = accent
      statusIcon.image = KometChatListStyle.symbol("checkmark", size: 12, weight: .semibold)
    case .some(.read):
      statusIcon.isHidden = false
      statusIcon.tintColor = accent
      statusIcon.image = KometChatListStyle.symbol("checkmark", size: 12, weight: .semibold)
      readIcon.isHidden = false
      readIcon.tintColor = accent
      readIcon.image = statusIcon.image
    }
  }

  private static func badgeText(_ count: Int) -> String {
    if count < 1000 { return "\(count)" }
    let value = Double(count) / 1000
    let text = value >= 10 ? String(format: "%.0f", value) : String(format: "%.1f", value)
    return (text.hasSuffix(".0") ? String(text.dropLast(2)) : text) + "K"
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let width = contentView.bounds.width
    let height = contentView.bounds.height
    let shift = editState.editing ? KometChatListCell.editShift : 0
    let right = width - 16 - (editState.reorderable ? KometChatListCell.gripWidth - 16 : 0)
    let side = KometChatListStyle.avatarSize
    avatarView.frame = CGRect(x: 16 + shift, y: (height - side) / 2, width: side, height: side)
    checkView.frame = CGRect(x: shift - KometChatListCell.editShift + 10, y: (height - 30) / 2,
                             width: 30, height: 30)
    gripView.frame = CGRect(x: width - KometChatListCell.gripWidth, y: 0,
                            width: KometChatListCell.gripWidth, height: height)

    let timeSize = timeLabel.sizeThatFits(CGSize(width: 120, height: 20))
    let timeX = right - ceil(timeSize.width)
    timeLabel.frame = CGRect(x: timeX, y: 11, width: ceil(timeSize.width), height: 20)

    var titleRight = timeX - 8
    if !statusIcon.isHidden {
      let size = statusIcon.image?.size ?? .zero
      let readShift: CGFloat = readIcon.isHidden ? 0 : 5
      let x = timeX - 4 - size.width - readShift
      statusIcon.frame = CGRect(x: x, y: 21 - size.height / 2, width: size.width, height: size.height)
      readIcon.frame = statusIcon.frame.offsetBy(dx: readShift, dy: 0)
      titleRight = x - 6
    }

    var x = KometChatListStyle.textInset + shift
    if !kindIcon.isHidden, let size = kindIcon.image?.size {
      kindIcon.frame = CGRect(x: x, y: 21 - size.height / 2, width: size.width, height: size.height)
      x += size.width + 4
    }
    let trailingIcons = [mutedIcon, verifiedIcon, lockIcon].filter { !$0.isHidden }
    let iconsWidth = trailingIcons.reduce(CGFloat(0)) { $0 + ($1.image?.size.width ?? 0) + 4 }
    let titleFit = titleLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: 22))
    let titleWidth = max(0, min(ceil(titleFit.width), titleRight - x - iconsWidth))
    titleLabel.frame = CGRect(x: x, y: 10, width: titleWidth, height: 22)
    var iconX = titleLabel.frame.maxX + 4
    for icon in trailingIcons {
      let size = icon.image?.size ?? .zero
      icon.frame = CGRect(x: iconX, y: 21 - size.height / 2, width: size.width, height: size.height)
      iconX += size.width + 4
    }

    var trailingX = right
    if !badgeView.isHidden {
      let textWidth = ceil(badgeLabel.sizeThatFits(CGSize(width: 80, height: 20)).width)
      let badgeWidth = max(20, textWidth + 12)
      trailingX -= badgeWidth
      badgeView.frame = CGRect(x: trailingX, y: 44, width: badgeWidth, height: 20)
      badgeView.layer.cornerRadius = 10
      badgeLabel.frame = badgeView.bounds
      trailingX -= 6
    }
    if !mentionView.isHidden {
      trailingX -= 20
      mentionView.frame = CGRect(x: trailingX, y: 44, width: 20, height: 20)
      mentionView.layer.cornerRadius = 10
      mentionLabel.frame = mentionView.bounds
      trailingX -= 6
    }
    if !pinIcon.isHidden, let size = pinIcon.image?.size {
      trailingX -= size.width
      pinIcon.frame = CGRect(x: trailingX, y: 54 - size.height / 2, width: size.width, height: size.height)
      trailingX -= 8
    }

    let textX = KometChatListStyle.textInset + shift
    let textWidth = max(0, trailingX - textX)
    if authorLabel.isHidden {
      let fit = previewLabel.sizeThatFits(CGSize(width: textWidth, height: 40))
      previewLabel.frame = CGRect(x: textX, y: 32, width: textWidth, height: min(40, ceil(fit.height)))
    } else {
      authorLabel.frame = CGRect(x: textX, y: 32, width: textWidth, height: 20)
      previewLabel.frame = CGRect(x: textX, y: 52, width: textWidth, height: 20)
    }

    let hairline = 1 / max(traitCollection.displayScale, 1)
    separator.frame = CGRect(x: textX, y: height - hairline,
                             width: width - textX, height: hairline)
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    avatarUrl = ""
  }
}
