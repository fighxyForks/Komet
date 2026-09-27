import UIKit
import XCTest
@testable import Runner

final class RunnerTests: XCTestCase {
  func testMediaSizingClampsExtremes() {
    let cases: [(Int, Int, CGFloat, Bool)] = [
      (300, 600, 260, false),
      (600, 300, 260, false),
      (1, 10, 260, false),
      (10, 1, 260, false),
      (0, 0, 260, false),
      (1, 10, 120, false),
      (10, 1, 360, true),
    ]
    for sample in cases {
      let size = KometChatLayout.fittedMediaSize(
        pixelWidth: sample.0,
        pixelHeight: sample.1,
        available: sample.2,
        wide: sample.3,
        round: false,
        sticker: false)
      XCTAssertLessThanOrEqual(size.width, sample.2 + 0.5, "\(sample)")
      XCTAssertGreaterThan(size.height, 0, "\(sample)")
    }
    let sticker = KometChatLayout.fittedMediaSize(
      pixelWidth: 10, pixelHeight: 10, available: 120, wide: false, round: false, sticker: true)
    XCTAssertEqual(sticker, CGSize(width: 120, height: 120))
    let round = KometChatLayout.fittedMediaSize(
      pixelWidth: 10, pixelHeight: 10, available: 360, wide: false, round: true, sticker: false)
    XCTAssertEqual(round, CGSize(width: 180, height: 180))
  }

  func testStoriesSnapToBandEdges() {
    let top: CGFloat = -200
    let bottom: CGFloat = -100
    XCTAssertEqual(
      StoriesCollapseCoordinator.target(forProjected: -250, velocity: 0, bandTop: top, bandBottom: bottom),
      -250)
    XCTAssertEqual(
      StoriesCollapseCoordinator.target(forProjected: -50, velocity: 0, bandTop: top, bandBottom: bottom),
      -50)
    XCTAssertEqual(
      StoriesCollapseCoordinator.target(forProjected: -160, velocity: 1, bandTop: top, bandBottom: bottom),
      bottom)
    XCTAssertEqual(
      StoriesCollapseCoordinator.target(forProjected: -140, velocity: -1, bandTop: top, bandBottom: bottom),
      top)
    XCTAssertEqual(
      StoriesCollapseCoordinator.target(forProjected: -140, velocity: 0, bandTop: top, bandBottom: bottom),
      bottom)
    XCTAssertEqual(
      StoriesCollapseCoordinator.target(forProjected: -160, velocity: 0, bandTop: top, bandBottom: bottom),
      top)
  }

  func testHeightCacheMeasuresOnce() {
    var cache = KometChatHeightCache()
    var measures = 0
    let key = KometChatHeightCache.Key(
      id: "m", revision: 1, width: 780, category: "large", selecting: false)
    let first = cache.height(for: key) { measures += 1; return 48 }
    let second = cache.height(for: key) { measures += 1; return 90 }
    XCTAssertEqual(first, 48)
    XCTAssertEqual(second, 48)
    XCTAssertEqual(measures, 1)
    cache.invalidate(id: "m")
    _ = cache.height(for: key) { measures += 1; return 50 }
    XCTAssertEqual(measures, 2)
  }

  func testConfigureDoesNotLoadOrPlay() {
    let beforeLoads = KometChatImages.loads
    let beforeShows = KometNotePlayback.shows
    let cell = KometChatMessageCell(frame: CGRect(x: 0, y: 0, width: 390, height: 40))
    for row in ChatFixtures.rows() {
      guard let item = KometChatMessage.parse(row) else {
        XCTFail("fixture \(row["id"] ?? "")")
        continue
      }
      cell.configure(layout: item, accent: .systemBlue, selecting: false, width: 390)
    }
    XCTAssertEqual(KometChatImages.loads, beforeLoads)
    XCTAssertEqual(KometNotePlayback.shows, beforeShows)
  }

  func testRepeatedApplyStaysStable() {
    guard let item = KometChatMessage.parse(ChatFixtures.message(
      id: "repeat",
      text: "Повтор",
      extra: ["buttons": [["text": "Кнопка"]]]
    )) else {
      return XCTFail("parse")
    }
    let cell = KometChatMessageCell(frame: CGRect(x: 0, y: 0, width: 390, height: 80))
    cell.configure(layout: item, accent: .systemBlue, selecting: false, width: 390)
    let first = cell.debugLayoutSnapshot()
    for _ in 0..<50 {
      cell.configure(layout: item, accent: .systemBlue, selecting: false, width: 390)
    }
    let last = cell.debugLayoutSnapshot()
    XCTAssertEqual(first.subviews, last.subviews)
    XCTAssertEqual(first.constraints, last.constraints)
    XCTAssertEqual(first.height, last.height, accuracy: 0.5)
  }

  func testVoiceBubbleIsWiderThanThePlayButton() {
    guard let item = KometChatMessage.parse(ChatFixtures.message(
      id: "voice-width",
      extra: ["kind": "voice", "duration": "0:03", "wave": [2, 4, 6]]
    )) else {
      return XCTFail("parse")
    }
    let cell = laidOut(item, width: 390)
    XCTAssertGreaterThan(cell.debugBubbleWidth(), 44 + 22)
  }

  func testChannelCardFillsTheWidth() {
    guard let item = KometChatMessage.parse(ChatFixtures.message(
      id: "channel",
      text: "Канал",
      extra: ["wide": true, "kind": "photo", "mediaUrl": "https://example.test/a.jpg", "mediaWidth": 800, "mediaHeight": 400]
    )) else {
      return XCTFail("parse")
    }
    let width: CGFloat = 390
    let cell = laidOut(item, width: width)
    XCTAssertEqual(cell.debugBubbleWidth(), width - 32, accuracy: 1)
  }

  func testFixturesAreNotAmbiguous() {
    for width in [320.0, 390.0, 430.0] as [CGFloat] {
      for row in ChatFixtures.rows() {
        guard let item = KometChatMessage.parse(row) else {
          XCTFail("parse")
          continue
        }
        let cell = laidOut(item, width: width)
        let name = row["id"] as? String ?? ""
        XCTAssertFalse(cell.contentView.hasAmbiguousLayout, name)
        XCTAssertFalse(cell.hasAmbiguousLayout, name)
      }
    }
  }

  func testAnchorSurvivesAPrepend() {
    assertAnchorSurvivesPrepend(repetitions: 20)
  }

  func testPartiallyVisibleLongPostSurvivesAPrepend() {
    assertAnchorSurvivesPrepend(repetitions: 800)
  }

  private func assertAnchorSurvivesPrepend(repetitions: Int) {
    let controller = KometChatController()
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
    window.rootViewController = controller
    window.isHidden = false
    controller.loadViewIfNeeded()
    controller.view.frame = window.bounds
    let original = (0..<40).map { index in
      ChatFixtures.message(
        id: "m\(index)",
        text: "Строка \(index) " + String(repeating: "текст ", count: repetitions))
    }
    controller.apply(
      order: original.map { $0["id"] as! String },
      rows: original,
      pinnedToEnd: false)
    RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    controller.collectionView.layoutIfNeeded()
    controller.collectionView.contentOffset.y = 400
    controller.scrollViewDidScroll(controller.collectionView)
    controller.collectionView.layoutIfNeeded()
    guard let anchor = controller.collectionView.indexPathsForVisibleItems
      .sorted(by: { $0.item < $1.item }).first,
          let before = controller.collectionView.layoutAttributesForItem(at: anchor)?.frame else {
      return XCTFail("no visible row")
    }
    let id = "m\(anchor.item)"
    let screenY = before.minY - controller.collectionView.contentOffset.y
    let older = (0..<12).map { index in
      ChatFixtures.message(id: "o\(index)", text: "Раньше \(index)")
    }
    let order = older.map { $0["id"] as! String } + original.map { $0["id"] as! String }
    controller.apply(order: order, rows: older, pinnedToEnd: false)
    RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    controller.collectionView.layoutIfNeeded()
    guard let index = order.firstIndex(of: id),
          let after = controller.collectionView.layoutAttributesForItem(
            at: IndexPath(item: index, section: 0))?.frame else {
      return XCTFail("anchor missing")
    }
    let nextY = after.minY - controller.collectionView.contentOffset.y
    XCTAssertEqual(nextY, screenY, accuracy: 1)
  }

  func testTextHeightMatchesTheLaidOutWidth() {
    guard let item = KometChatMessage.parse(ChatFixtures.message(
      id: "wrap",
      text: String(repeating: "Синтетическая строка для переноса. ", count: 6)
    )) else {
      return XCTFail("parse")
    }
    let cell = laidOut(item, width: 320)
    XCTAssertLessThanOrEqual(cell.debugBodyDelta(), 1)
  }

  func testKeyboardTapsUseFlatIndicesAcrossRows() {
    let rows: [[[String: Any]]] = [
      [["text": "First", "row": 0, "column": 0], ["text": "", "row": 0, "column": 1]],
      [["text": "Second", "row": 1, "column": 0], ["text": "Third", "row": 1, "column": 1]],
      [["text": "Fourth", "row": 0, "column": 0]],
    ]
    guard let item = KometChatMessage.parse(ChatFixtures.message(
      id: "keyboard", extra: ["units": [["kind": "botKeyboard", "rows": rows]]]
    )) else { return XCTFail("parse") }
    let cell = laidOut(item, width: 390)
    var indices: [Int] = []
    cell.onEvent = { event, data in
      if event == "keyboard", let index = data["index"] as? Int { indices.append(index) }
    }
    let buttons = buttons(in: cell).filter {
      $0.actions(forTarget: cell, forControlEvent: .touchUpInside)?.contains("tapKeyboard:") == true
    }
    XCTAssertEqual(buttons.count, 4)
    buttons.forEach { $0.sendActions(for: .touchUpInside) }
    XCTAssertEqual(indices, [0, 1, 2, 3])
  }

  func testCardsEmitTheSelectedAttachmentIndex() {
    let units: [[String: Any]] = [
      ["kind": "file", "name": "a.txt"],
      ["kind": "contact", "name": "Synthetic A"],
      ["kind": "location"],
      ["kind": "file", "name": "b.txt"],
      ["kind": "contact", "name": "Synthetic B"],
      ["kind": "location"],
    ]
    guard let item = KometChatMessage.parse(ChatFixtures.message(
      id: "cards", extra: ["units": units]
    )) else { return XCTFail("parse") }
    let cell = laidOut(item, width: 390)
    var events: [String] = []
    cell.onEvent = { event, data in
      if let index = data["index"] as? Int { events.append("\(event):\(index)") }
    }
    let actions = Set(["tapFile:", "tapContact:", "tapLocation:"])
    for button in buttons(in: cell) {
      let targets = button.actions(forTarget: cell, forControlEvent: .touchUpInside) ?? []
      if !actions.isDisjoint(with: targets) { button.sendActions(for: .touchUpInside) }
    }
    XCTAssertEqual(events, ["file:0", "contact:0", "location:0", "file:1", "contact:1", "location:1"])
  }

  func testAlbumPreservesSpanningTiles() {
    for count in [3, 4] {
      let tiles: [[String: Any]] = (0..<count).map { index in
        ["url": "https://example.test/\(index).jpg", "width": index == 0 ? 400 : 800, "height": 800]
      }
      guard let item = KometChatMessage.parse(ChatFixtures.message(
        id: "album", extra: ["kind": "album", "units": [["kind": "album", "tiles": tiles]]]
      )) else { return XCTFail("parse") }
      let cell = laidOut(item, width: 390)
      let tilesInView = buttons(in: cell).filter {
        $0.actions(forTarget: cell, forControlEvent: .touchUpInside)?.contains("tapAlbum:") == true
      }.sorted { $0.tag < $1.tag }
      XCTAssertEqual(tilesInView.count, count)
      guard let container = tilesInView.first?.superview else { return XCTFail("album missing") }
      let expected = KometAlbumLayout.frames(ratios: [0.5] + Array(repeating: 1, count: count - 1), width: container.bounds.width)
      for (button, frame) in zip(tilesInView, expected) {
        XCTAssertEqual(button.frame.minX, frame.minX, accuracy: 0.5)
        XCTAssertEqual(button.frame.minY, frame.minY, accuracy: 0.5)
        XCTAssertEqual(button.frame.width, frame.width, accuracy: 0.5)
        XCTAssertEqual(button.frame.height, frame.height, accuracy: 0.5)
      }
      XCTAssertEqual(container.bounds.height, expected.map(\.maxY).max() ?? 0, accuracy: 0.5)
    }
  }

  private func buttons(in view: UIView) -> [UIButton] {
    (view as? UIButton).map { [$0] } ?? view.subviews.flatMap { buttons(in: $0) }
  }

  private func laidOut(_ item: KometChatMessage, width: CGFloat) -> KometChatMessageCell {
    let cell = KometChatMessageCell(frame: CGRect(x: 0, y: 0, width: width, height: 10))
    cell.configure(layout: item, accent: .systemBlue, selecting: false, width: width)
    let height = cell.contentView.systemLayoutSizeFitting(
      CGSize(width: width, height: 0),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel).height
    cell.frame.size = CGSize(width: width, height: height)
    cell.contentView.frame = cell.bounds
    cell.layoutIfNeeded()
    return cell
  }
}
