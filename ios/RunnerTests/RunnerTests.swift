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
      top)
    XCTAssertEqual(
      StoriesCollapseCoordinator.target(forProjected: -160, velocity: 0, bandTop: top, bandBottom: bottom),
      bottom)
  }

  func testHeightCacheMeasuresOnce() {
    var cache = KometChatHeightCache()
    var measures = 0
    let key = KometChatHeightCache.Key(
      revision: "abc", width: 780, category: "large", selecting: false)
    let first = cache.height(for: key) { measures += 1; return 48 }
    let second = cache.height(for: key) { measures += 1; return 90 }
    XCTAssertEqual(first, 48)
    XCTAssertEqual(second, 48)
    XCTAssertEqual(measures, 1)
    let changed = KometChatHeightCache.Key(
      revision: "def", width: 780, category: "large", selecting: false)
    _ = cache.height(for: changed) { measures += 1; return 50 }
    XCTAssertEqual(measures, 2)
    cache.removeAll()
    let afterReset = cache.height(for: key) { measures += 1; return 12 }
    XCTAssertEqual(afterReset, 12)
    XCTAssertEqual(measures, 3)
    let selecting = KometChatHeightCache.Key(
      revision: "abc", width: 780, category: "large", selecting: true)
    _ = cache.height(for: selecting) { measures += 1; return 20 }
    XCTAssertEqual(measures, 4)
  }

  func testAlbumFramesStayInsideWidth() {
    for count in 1...10 {
      for width in [CGFloat(240), 300, 360] {
        let ratios = (0..<count).map { CGFloat(($0 % 3) + 1) / CGFloat(($0 % 2) + 1) }
        let frames = KometAlbumLayout.frames(ratios: ratios, width: width)
        XCTAssertEqual(frames.count, count, "\(count) @ \(width)")
        for frame in frames {
          XCTAssertGreaterThan(frame.width, 0)
          XCTAssertGreaterThan(frame.height, 0)
          XCTAssertGreaterThanOrEqual(frame.minX, -0.5)
          XCTAssertLessThanOrEqual(frame.maxX, width + 1.5, "\(frame) width \(width)")
        }
      }
    }
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
    let controller = KometChatController()
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
    window.rootViewController = controller
    window.isHidden = false
    controller.loadViewIfNeeded()
    controller.view.frame = window.bounds
    let original = (0..<40).map { index in
      ChatFixtures.message(
        id: "m\(index)",
        text: "Строка \(index) " + String(repeating: "текст ", count: 20))
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
