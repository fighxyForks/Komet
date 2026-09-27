import Foundation

enum ChatFixtures {
  static func rows() -> [[String: Any]] {
    let longText = String(repeating: "Синтетическая строка для переноса. ", count: 8)
    return [
      message(id: "text-in", text: "Короткий входящий"),
      message(id: "text-out", text: "Короткий исходящий", extra: ["outgoing": true]),
      message(id: "text-long", text: longText),
      message(id: "photo", text: "Подпись к фото", extra: [
        "kind": "photo",
        "mediaUrl": "https://example.test/photo.jpg",
        "mediaWidth": 800,
        "mediaHeight": 1200,
      ]),
      message(id: "photo-wide", text: "Широкое фото канала", extra: [
        "kind": "photo",
        "wide": true,
        "mediaUrl": "https://example.test/wide.jpg",
        "mediaWidth": 1600,
        "mediaHeight": 900,
      ]),
      message(id: "album", extra: [
        "kind": "album",
        "media": [
          ["url": "https://example.test/1.jpg", "kind": "photo", "width": 400, "height": 400],
          ["url": "https://example.test/2.jpg", "kind": "photo", "width": 400, "height": 400],
          ["url": "https://example.test/3.jpg", "kind": "photo", "width": 400, "height": 400],
          ["url": "https://example.test/4.jpg", "kind": "photo", "width": 400, "height": 400],
          ["url": "https://example.test/5.jpg", "kind": "photo", "width": 400, "height": 400],
        ],
      ]),
      message(id: "voice", extra: [
        "kind": "voice",
        "duration": "0:12",
        "wave": [1, 4, 8, 3],
      ]),
      message(id: "video-note", extra: [
        "kind": "videoNote",
        "mediaUrl": "https://example.test/note.jpg",
        "playUrl": "/tmp/note.mp4",
        "mediaWidth": 400,
        "mediaHeight": 400,
      ]),
      message(id: "sticker", extra: [
        "kind": "sticker",
        "mediaUrl": "https://example.test/sticker.png",
      ]),
      message(id: "poll", text: "Опрос", extra: [
        "kind": "poll",
        "pollChoices": [
          ["id": 1, "text": "Да", "count": 0, "mine": false],
          ["id": 2, "text": "Нет", "count": 0, "mine": false],
        ],
      ]),
      message(id: "keyboard", text: "Клавиатура", extra: [
        "buttons": [
          ["text": "Один"],
          ["text": "Два"],
        ],
      ]),
      message(id: "contact", extra: [
        "kind": "contact",
        "units": [["kind": "contact", "name": "Синтетический контакт", "hasPhone": false, "contactId": 7]],
      ]),
      message(id: "file", extra: [
        "kind": "file",
        "units": [["kind": "file", "name": "заметка.txt", "size": 128, "extension": "txt"]],
      ]),
      message(id: "location", extra: [
        "kind": "location",
        "units": [["kind": "location", "latitude": 55.75, "longitude": 37.62]],
      ]),
      message(id: "link", extra: [
        "kind": "share",
        "units": [["kind": "linkPreview", "title": "Пример", "url": "https://example.test/a"]],
      ]),
      message(id: "keyboard-rows", text: "Ряды", extra: [
        "units": [[
          "kind": "botKeyboard",
          "rows": [
            [["text": "Один"], ["text": "Два"]],
            [["text": "Три"]],
          ],
        ]],
      ]),
      message(id: "animoji", text: "😀", extra: [
        "spans": [["start": 0, "length": 2, "styles": ["animoji"]]],
      ]),
    ]
  }

  static func message(id: String, text: String = "", extra: [String: Any] = [:]) -> [String: Any] {
    var row: [String: Any] = [
      "id": id,
      "role": "message",
      "kind": "text",
      "text": text,
      "time": "12:00",
      "outgoing": false,
    ]
    for (key, value) in extra { row[key] = value }
    return row
  }
}
