import UIKit

enum KometChatLayout {
  enum Mode: Equatable {
    case incoming
    case outgoing
    case channel
  }

  struct Metrics: Equatable {
    let mode: Mode
    let maxBubbleWidth: CGFloat
    let maxContentWidth: CGFloat
    let cardWidth: CGFloat
  }

  static func leadingReserve(selecting: Bool, showAvatar: Bool) -> CGFloat {
    let selection: CGFloat = selecting ? 10 + 22 : 0
    let avatar: CGFloat = showAvatar ? 34 : 0
    return selection + 8 + avatar + 8
  }

  static func metrics(
    cellWidth: CGFloat,
    wide: Bool,
    outgoing: Bool,
    showAvatar: Bool,
    selecting: Bool
  ) -> Metrics {
    if wide {
      let card = max(0, cellWidth - 32)
      return Metrics(
        mode: .channel,
        maxBubbleWidth: card,
        maxContentWidth: max(1, card - 22),
        cardWidth: card)
    }
    let reserve = leadingReserve(selecting: selecting, showAvatar: showAvatar)
    let capped = min(cellWidth * 0.78, cellWidth - reserve - 12)
    let maxBubble = max(66, capped)
    return Metrics(
      mode: outgoing ? .outgoing : .incoming,
      maxBubbleWidth: maxBubble,
      maxContentWidth: max(44, maxBubble - 22),
      cardWidth: 0)
  }

  static func fittedMediaSize(
    pixelWidth: Int,
    pixelHeight: Int,
    available: CGFloat,
    wide: Bool,
    round: Bool,
    sticker: Bool
  ) -> CGSize {
    let cap = max(1, available)
    if sticker {
      let side = min(150, cap)
      return CGSize(width: side, height: side)
    }
    if round {
      let side = min(180, cap)
      return CGSize(width: side, height: side)
    }
    let aspect: CGFloat = pixelWidth > 0 && pixelHeight > 0
      ? CGFloat(pixelHeight) / CGFloat(pixelWidth)
      : 0.75
    let width = cap
    let raw = width * aspect
    if wide {
      let maxHeight = width * 1.25
      let minHeight = min(120, maxHeight)
      return CGSize(width: width, height: min(max(raw, minHeight), maxHeight))
    }
    let maxHeight = width * 1.3
    let minHeight = min(80, maxHeight)
    return CGSize(width: width, height: min(max(raw, minHeight), maxHeight))
  }

  static func revision(_ item: KometChatMessage) -> Int {
    var hasher = Hasher()
    hasher.combine(item.id)
    hasher.combine(item.kind)
    hasher.combine(item.text)
    hasher.combine(item.wide)
    hasher.combine(item.outgoing)
    hasher.combine(item.showAvatar)
    hasher.combine(item.showSender)
    hasher.combine(item.cluster)
    hasher.combine(item.mediaWidth)
    hasher.combine(item.mediaHeight)
    hasher.combine(item.transcriptOpen)
    hasher.combine(item.transcript)
    hasher.combine(item.comments)
    hasher.combine(item.replyAuthor)
    hasher.combine(item.replyText)
    hasher.combine(item.forwardAuthor)
    hasher.combine(item.senderName)
    hasher.combine(item.duration)
    hasher.combine(item.edited)
    hasher.combine(item.deleted)
    hasher.combine(item.time)
    hasher.combine(item.media.count)
    for tile in item.media {
      hasher.combine(tile.url)
      hasher.combine(tile.width)
      hasher.combine(tile.height)
    }
    hasher.combine(item.buttons.count)
    for button in item.buttons {
      hasher.combine(button.text)
    }
    hasher.combine(item.pollVoted)
    hasher.combine(item.pollMultiple)
    hasher.combine(item.pollTotal)
    for choice in item.pollChoices {
      hasher.combine(choice.id)
      hasher.combine(choice.text)
      hasher.combine(choice.count)
      hasher.combine(choice.mine)
    }
    for reaction in item.reactions {
      hasher.combine(reaction.emoji)
      hasher.combine(reaction.count)
      hasher.combine(reaction.mine)
    }
    for span in item.spans {
      hasher.combine(span.start)
      hasher.combine(span.length)
      hasher.combine(span.styles)
    }
    return hasher.finalize()
  }
}

struct KometChatHeightCache {
  struct Key: Hashable {
    let id: String
    let revision: Int
    let width: Int
    let category: String
    let selecting: Bool
  }

  private var values: [Key: CGFloat] = [:]

  mutating func height(for key: Key, measure: () -> CGFloat) -> CGFloat {
    if let cached = values[key] { return cached }
    let measured = measure()
    values[key] = measured
    return measured
  }

  mutating func invalidate(id: String) {
    values = values.filter { $0.key.id != id }
  }

  mutating func removeAll() {
    values.removeAll()
  }
}

enum StoriesCollapseCoordinator {
  static func target(
    forProjected projected: CGFloat,
    velocity: CGFloat,
    bandTop: CGFloat,
    bandBottom: CGFloat
  ) -> CGFloat {
    let top = min(bandTop, bandBottom)
    let bottom = max(bandTop, bandBottom)
    if projected <= top || projected >= bottom { return projected }
    if velocity > 0.05 { return bottom }
    if velocity < -0.05 { return top }
    let mid = (top + bottom) / 2
    return projected < mid ? top : bottom
  }

  static func progress(offsetY: CGFloat, expandedTop: CGFloat, band: CGFloat) -> CGFloat {
    guard band > 0.5 else { return 1 }
    let traveled = offsetY - (-expandedTop)
    return min(1, max(0, 1 - traveled / band))
  }
}
