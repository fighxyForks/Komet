import UIKit

struct KometChatListStrings {
  var search = "Search"
  var draft = "Draft: "
  var markRead = "Mark as read"
  var pin = "Pin"
  var unpin = "Unpin"
  var mute = "Mute"
  var unmute = "Unmute"
  var archive = "Archive"
  var delete = "Delete"
  var edit = "Edit"
  var done = "Done"
  var readAll = "Read All"
  var readSelected = "Read"
  var toArchive = "Archive"
  var deleteSelected = "Delete"
  var cancel = "Cancel"

  mutating func apply(_ map: [String: Any]) {
    search = map["search"] as? String ?? search
    draft = map["draft"] as? String ?? draft
    markRead = map["markRead"] as? String ?? markRead
    pin = map["pin"] as? String ?? pin
    unpin = map["unpin"] as? String ?? unpin
    mute = map["mute"] as? String ?? mute
    unmute = map["unmute"] as? String ?? unmute
    archive = map["archive"] as? String ?? archive
    delete = map["delete"] as? String ?? delete
    edit = map["edit"] as? String ?? edit
    done = map["done"] as? String ?? done
    readAll = map["readAll"] as? String ?? readAll
    readSelected = map["readSelected"] as? String ?? readSelected
    toArchive = map["toArchive"] as? String ?? toArchive
    deleteSelected = map["deleteSelected"] as? String ?? deleteSelected
    cancel = map["cancel"] as? String ?? cancel
  }
}

enum KometChatStatus: String {
  case sending
  case sent
  case read
  case error
}

struct KometChatRow {
  let id: Int
  let title: String
  let avatarUrl: String
  let saved: Bool
  let kind: String?
  let encrypted: Bool
  let verified: Bool
  let muted: Bool
  let pinned: Bool
  let time: String
  let author: String
  let text: String
  let mediaKind: String?
  let italic: Bool
  let draft: String?
  let status: KometChatStatus?
  let unread: Int
  let mention: Bool
  let canMarkRead: Bool
  let canDelete: Bool

  init?(_ map: [String: Any]) {
    guard let id = (map["id"] as? NSNumber)?.intValue else { return nil }
    self.id = id
    title = map["title"] as? String ?? ""
    avatarUrl = map["avatarUrl"] as? String ?? ""
    saved = (map["saved"] as? NSNumber)?.boolValue ?? false
    kind = map["kind"] as? String
    encrypted = (map["encrypted"] as? NSNumber)?.boolValue ?? false
    verified = (map["verified"] as? NSNumber)?.boolValue ?? false
    muted = (map["muted"] as? NSNumber)?.boolValue ?? false
    pinned = (map["pinned"] as? NSNumber)?.boolValue ?? false
    time = map["time"] as? String ?? ""
    author = map["author"] as? String ?? ""
    text = map["text"] as? String ?? ""
    mediaKind = map["mediaKind"] as? String
    italic = (map["italic"] as? NSNumber)?.boolValue ?? false
    draft = map["draft"] as? String
    status = (map["status"] as? String).flatMap(KometChatStatus.init(rawValue:))
    unread = (map["unread"] as? NSNumber)?.intValue ?? 0
    mention = (map["mention"] as? NSNumber)?.boolValue ?? false
    canMarkRead = (map["canMarkRead"] as? NSNumber)?.boolValue ?? false
    canDelete = (map["canDelete"] as? NSNumber)?.boolValue ?? false
  }
}

enum KometChatListStyle {
  static let rowHeight: CGFloat = 78
  static let avatarSize: CGFloat = 60
  static let textInset: CGFloat = 86
  static let titleFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
  static let bodyFont = UIFont.systemFont(ofSize: 15, weight: .regular)
  static let timeFont = UIFont.systemFont(ofSize: 15, weight: .regular)
  static let badgeFont = UIFont.systemFont(ofSize: 14, weight: .semibold)

  static let pinnedBackground = UIColor { traits in
    traits.userInterfaceStyle == .dark
      ? UIColor(red: 0x11 / 255, green: 0x11 / 255, blue: 0x13 / 255, alpha: 1)
      : UIColor(red: 0xF7 / 255, green: 0xF7 / 255, blue: 0xF9 / 255, alpha: 1)
  }

  static let mutedBadge = UIColor { traits in
    traits.userInterfaceStyle == .dark
      ? UIColor(red: 0x63 / 255, green: 0x63 / 255, blue: 0x66 / 255, alpha: 1)
      : UIColor(red: 0xB1 / 255, green: 0xB1 / 255, blue: 0xB6 / 255, alpha: 1)
  }

  static let secondary = UIColor { traits in
    traits.userInterfaceStyle == .dark
      ? UIColor(red: 0x8D / 255, green: 0x8D / 255, blue: 0x93 / 255, alpha: 1)
      : UIColor(red: 0x8E / 255, green: 0x8E / 255, blue: 0x93 / 255, alpha: 1)
  }

  static func symbol(_ name: String, size: CGFloat, weight: UIImage.SymbolWeight = .regular)
    -> UIImage? {
    UIImage(
      systemName: name,
      withConfiguration: UIImage.SymbolConfiguration(pointSize: size, weight: weight))
  }

  static func kindSymbol(_ kind: String?) -> String? {
    switch kind {
    case "channel": return "megaphone.fill"
    case "group": return "person.2.fill"
    case "bot": return "cpu"
    default: return nil
    }
  }

  static func mediaSymbol(_ kind: String) -> String {
    switch kind {
    case "photo": return "photo"
    case "video": return "film"
    case "videoNote": return "video.circle"
    case "audio": return "mic.fill"
    case "file": return "doc"
    case "sticker": return "face.smiling"
    case "contact": return "person.crop.circle"
    case "location": return "mappin.and.ellipse"
    case "poll": return "chart.bar"
    case "share": return "link"
    case "call": return "phone.fill"
    case "missedCall": return "phone.down.fill"
    case "videoCall": return "video.fill"
    case "missedVideoCall": return "video.slash.fill"
    case "control": return "info.circle"
    default: return "paperclip"
    }
  }
}

final class KometChatRowContent {
  let row: KometChatRow
  let preview: NSAttributedString
  let previewLines: Int

  init(row: KometChatRow, strings: KometChatListStrings) {
    self.row = row
    let hasAuthor = !row.author.isEmpty && row.draft == nil
    previewLines = hasAuthor ? 1 : 2
    preview = KometChatRowContent.makePreview(row, strings: strings)
  }

  private static func makePreview(_ row: KometChatRow, strings: KometChatListStrings)
    -> NSAttributedString {
    let font = KometChatListStyle.bodyFont
    let secondary = KometChatListStyle.secondary
    let result = NSMutableAttributedString()
    if let draft = row.draft {
      result.append(NSAttributedString(
        string: strings.draft,
        attributes: [.font: font, .foregroundColor: UIColor.systemRed]))
      result.append(NSAttributedString(
        string: draft,
        attributes: [.font: font, .foregroundColor: secondary]))
      return result
    }
    if let kind = row.mediaKind,
       let image = KometChatListStyle.symbol(
         KometChatListStyle.mediaSymbol(kind), size: 14, weight: .medium)?
         .withTintColor(secondary, renderingMode: .alwaysOriginal) {
      let attachment = NSTextAttachment()
      attachment.image = image
      let height = font.capHeight + 2
      let width = image.size.height > 0 ? image.size.width * height / image.size.height : height
      attachment.bounds = CGRect(x: 0, y: -1, width: width, height: height)
      result.append(NSAttributedString(attachment: attachment))
      result.append(NSAttributedString(string: " ", attributes: [.font: font]))
    }
    let bodyColor = row.italic ? secondary.withAlphaComponent(0.7) : secondary
    result.append(NSAttributedString(
      string: row.text,
      attributes: [.font: font, .foregroundColor: bodyColor]))
    return result
  }
}

final class KometAvatarCache {
  static let shared = KometAvatarCache()

  private let images = NSCache<NSString, UIImage>()
  private var pending: [String: [(UIImage) -> Void]] = [:]
  private let session: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.urlCache = URLCache(memoryCapacity: 8 << 20, diskCapacity: 64 << 20,
                                      diskPath: "komet-avatars")
    configuration.requestCachePolicy = .returnCacheDataElseLoad
    return URLSession(configuration: configuration)
  }()

  private static let palette: [(UInt32, UInt32)] = [
    (0xFF885E, 0xFF516A), (0xFFCD6A, 0xFFA85C), (0x82B1FF, 0x665FFF),
    (0xA0DE7E, 0x54CB68), (0x53EDD6, 0x28C9B7), (0x72D5FD, 0x2A9EF1),
    (0xE0A2F3, 0xD669ED),
  ]

  private init() {
    images.countLimit = 400
  }

  func cached(_ url: String, side: CGFloat) -> UIImage? {
    images.object(forKey: key(url, side))
  }

  func load(_ url: String, side: CGFloat, scale: CGFloat,
            completion: @escaping (UIImage) -> Void) {
    let cacheKey = key(url, side)
    if let image = images.object(forKey: cacheKey) {
      completion(image)
      return
    }
    let id = cacheKey as String
    if pending[id] != nil {
      pending[id]?.append(completion)
      return
    }
    pending[id] = [completion]
    guard let remote = URL(string: url) else {
      pending[id] = nil
      return
    }
    session.dataTask(with: remote) { [weak self] data, _, _ in
      guard let self = self else { return }
      let image = data.flatMap(UIImage.init(data:)).map {
        KometAvatarCache.circle($0, side: side, scale: scale)
      }
      DispatchQueue.main.async {
        let callbacks = self.pending.removeValue(forKey: id) ?? []
        guard let image = image else { return }
        self.images.setObject(image, forKey: cacheKey)
        callbacks.forEach { $0(image) }
      }
    }.resume()
  }

  func prefetch(_ url: String, side: CGFloat, scale: CGFloat) {
    guard !url.isEmpty else { return }
    load(url, side: side, scale: scale) { _ in }
  }

  func placeholder(for row: KometChatRow, side: CGFloat, scale: CGFloat,
                   accent: UIColor) -> UIImage {
    if row.saved {
      return symbolAvatar("bookmark.fill", side: side, scale: scale, fill: accent, tint: .white)
    }
    if row.kind == "archive" {
      return symbolAvatar("archivebox.fill", side: side, scale: scale,
                          fill: KometChatListStyle.mutedBadge, tint: .white)
    }
    return letterAvatar(seed: row.id, title: row.title, side: side, scale: scale)
  }

  func letterAvatar(seed: Int, title: String, side: CGFloat, scale: CGFloat) -> UIImage {
    let cacheKey = "letter|\(seed)|\(title.prefix(1))|\(side)" as NSString
    if let image = images.object(forKey: cacheKey) { return image }
    let rect = CGRect(x: 0, y: 0, width: side, height: side)
    let image = KometAvatarCache.renderer(side: side, scale: scale).image { context in
      UIBezierPath(ovalIn: rect).addClip()
      let pair = KometAvatarCache.palette[abs(seed % KometAvatarCache.palette.count)]
      let colors = [KometAvatarCache.color(pair.0).cgColor, KometAvatarCache.color(pair.1).cgColor]
      if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                   colors: colors as CFArray, locations: [0, 1]) {
        context.cgContext.drawLinearGradient(
          gradient, start: CGPoint(x: side / 2, y: 0), end: CGPoint(x: side / 2, y: side),
          options: [])
      }
      let letter = String(title.prefix(1)).uppercased() as NSString
      let font = UIFont.systemFont(ofSize: side * 0.4, weight: .semibold)
      let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.white]
      let size = letter.size(withAttributes: attributes)
      letter.draw(at: CGPoint(x: (side - size.width) / 2, y: (side - size.height) / 2),
                  withAttributes: attributes)
    }
    images.setObject(image, forKey: cacheKey)
    return image
  }

  func symbolAvatar(_ symbol: String, side: CGFloat, scale: CGFloat, fill: UIColor,
                    tint: UIColor) -> UIImage {
    let rect = CGRect(x: 0, y: 0, width: side, height: side)
    return KometAvatarCache.renderer(side: side, scale: scale).image { _ in
      let path = UIBezierPath(ovalIn: rect)
      fill.setFill()
      path.fill()
      if let glyph = KometChatListStyle.symbol(symbol, size: side * 0.4, weight: .semibold)?
        .withTintColor(tint, renderingMode: .alwaysOriginal) {
        glyph.draw(at: CGPoint(x: (side - glyph.size.width) / 2,
                               y: (side - glyph.size.height) / 2))
      }
    }
  }

  private static func renderer(side: CGFloat, scale: CGFloat) -> UIGraphicsImageRenderer {
    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    format.opaque = false
    return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
  }

  private func key(_ url: String, _ side: CGFloat) -> NSString {
    "\(url)|\(side)" as NSString
  }

  private static func color(_ rgb: UInt32) -> UIColor {
    UIColor(red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1)
  }

  private static func circle(_ source: UIImage, side: CGFloat, scale: CGFloat) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    format.opaque = false
    let rect = CGRect(x: 0, y: 0, width: side, height: side)
    return UIGraphicsImageRenderer(size: rect.size, format: format).image { _ in
      UIBezierPath(ovalIn: rect).addClip()
      let aspect = max(side / max(source.size.width, 1), side / max(source.size.height, 1))
      let drawn = CGSize(width: source.size.width * aspect, height: source.size.height * aspect)
      source.draw(in: CGRect(x: (side - drawn.width) / 2, y: (side - drawn.height) / 2,
                             width: drawn.width, height: drawn.height))
    }
  }
}

enum KometNavigationChrome {
  static func styleBar(_ bar: UINavigationBar?) {
    guard let bar = bar else { return }
    let standard = UINavigationBarAppearance()
    standard.configureWithDefaultBackground()
    let edge = UINavigationBarAppearance()
    edge.configureWithTransparentBackground()
    bar.standardAppearance = standard
    bar.compactAppearance = standard
    bar.scrollEdgeAppearance = edge
    if #available(iOS 15.0, *) {
      bar.compactScrollEdgeAppearance = edge
    }
  }

  static func pinSearchToTop(_ item: UINavigationItem) {
    item.hidesSearchBarWhenScrolling = false
    if #available(iOS 16.0, *) {
      item.preferredSearchBarPlacement = .stacked
    }
    if #available(iOS 26.0, *) {
      item.searchBarPlacementAllowsToolbarIntegration = false
    }
  }
}
