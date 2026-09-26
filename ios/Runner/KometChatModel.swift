import UIKit

struct KometChatChrome {
  var accent = UIColor.systemBlue
  var bottomInset: CGFloat = 0
  var selecting = false

  static func parse(_ map: [String: Any]?) -> KometChatChrome {
    guard let map = map else { return KometChatChrome() }
    var chrome = KometChatChrome()
    if let accent = map["accent"] as? NSNumber {
      chrome.accent = UIColor(argb: accent.uint32Value)
    }
    if let inset = map["bottomInset"] as? NSNumber {
      chrome.bottomInset = CGFloat(truncating: inset)
    }
    chrome.selecting = (map["selecting"] as? NSNumber)?.boolValue ?? false
    return chrome
  }
}

struct KometChatReaction {
  let emoji: String
  let count: Int
  let mine: Bool
}

struct KometChatButton {
  let text: String
  let index: Int
}

struct KometChatMessage {
  enum Role {
    case date
    case unread
    case message
  }

  let id: String
  let role: Role
  let kind: String
  let text: String
  let outgoing: Bool
  let time: String
  let delivery: String
  let cluster: String
  let edited: Bool
  let deleted: Bool
  let canReply: Bool
  let selected: Bool
  let highlighted: Bool
  let showAvatar: Bool
  let showSender: Bool
  let senderName: String?
  let avatarUrl: String?
  let replyId: String?
  let replyAuthor: String?
  let replyText: String?
  let forwardAuthor: String?
  let mediaUrl: String?
  let duration: String?
  let transcript: String?
  let transcriptOpen: Bool
  let playing: Bool
  let comments: String?
  let senderId: Int?
  let reactions: [KometChatReaction]
  let buttons: [KometChatButton]

  var isService: Bool { role != .message || kind == "control" }

  static func parse(_ map: [String: Any]) -> KometChatMessage? {
    guard let id = map["id"] as? String, !id.isEmpty else { return nil }
    let roleName = map["role"] as? String ?? "message"
    let role: Role
    switch roleName {
    case "date": role = .date
    case "unread": role = .unread
    default: role = .message
    }
    let reactionMaps = map["reactions"] as? [[String: Any]] ?? []
    let buttonMaps = map["buttons"] as? [[String: Any]] ?? []
    return KometChatMessage(
      id: id,
      role: role,
      kind: map["kind"] as? String ?? "text",
      text: map["text"] as? String ?? "",
      outgoing: (map["outgoing"] as? NSNumber)?.boolValue ?? false,
      time: map["time"] as? String ?? "",
      delivery: map["delivery"] as? String ?? "none",
      cluster: map["cluster"] as? String ?? "single",
      edited: (map["edited"] as? NSNumber)?.boolValue ?? false,
      deleted: (map["deleted"] as? NSNumber)?.boolValue ?? false,
      canReply: (map["canReply"] as? NSNumber)?.boolValue ?? false,
      selected: (map["selected"] as? NSNumber)?.boolValue ?? false,
      highlighted: (map["highlighted"] as? NSNumber)?.boolValue ?? false,
      showAvatar: (map["showAvatar"] as? NSNumber)?.boolValue ?? false,
      showSender: (map["showSender"] as? NSNumber)?.boolValue ?? false,
      senderName: map["senderName"] as? String,
      avatarUrl: map["avatarUrl"] as? String,
      replyId: map["replyId"] as? String,
      replyAuthor: map["replyAuthor"] as? String,
      replyText: map["replyText"] as? String,
      forwardAuthor: map["forwardAuthor"] as? String,
      mediaUrl: map["mediaUrl"] as? String,
      duration: map["duration"] as? String,
      transcript: map["transcript"] as? String,
      transcriptOpen: (map["transcriptOpen"] as? NSNumber)?.boolValue ?? false,
      playing: (map["playing"] as? NSNumber)?.boolValue ?? false,
      comments: map["comments"] as? String,
      senderId: (map["senderId"] as? NSNumber)?.intValue,
      reactions: reactionMaps.compactMap { raw in
        guard let emoji = raw["emoji"] as? String, !emoji.isEmpty else { return nil }
        return KometChatReaction(
          emoji: emoji,
          count: (raw["count"] as? NSNumber)?.intValue ?? 0,
          mine: (raw["mine"] as? NSNumber)?.boolValue ?? false)
      },
      buttons: buttonMaps.enumerated().compactMap { offset, raw in
        guard let text = raw["text"] as? String, !text.isEmpty else { return nil }
        return KometChatButton(text: text, index: offset)
      })
  }
}

private extension UIColor {
  convenience init(argb: UInt32) {
    let alpha = CGFloat((argb >> 24) & 0xFF) / 255
    self.init(
      red: CGFloat((argb >> 16) & 0xFF) / 255,
      green: CGFloat((argb >> 8) & 0xFF) / 255,
      blue: CGFloat(argb & 0xFF) / 255,
      alpha: alpha == 0 ? 1 : alpha)
  }
}
