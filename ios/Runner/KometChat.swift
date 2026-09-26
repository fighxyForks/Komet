import Flutter
import UIKit

final class KometChatViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  private weak var host: UIViewController?

  init(messenger: FlutterBinaryMessenger, host: UIViewController?) {
    self.messenger = messenger
    self.host = host
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
    KometChatPlatformView(
      frame: frame, viewId: viewId, arguments: args, messenger: messenger, host: host)
  }
}

final class KometChatPlatformView: NSObject, FlutterPlatformView {
  private let channel: FlutterMethodChannel
  private let chat: KometChatController

  init(frame: CGRect, viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger,
       host: UIViewController?) {
    channel = FlutterMethodChannel(
      name: "ru.komet.app/native_chat/\(viewId)", binaryMessenger: messenger)
    let chat = KometChatController()
    self.chat = chat
    super.init()
    chat.view.frame = frame
    chat.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    chat.onEvent = { [weak self] method, arguments in
      self?.channel.invokeMethod(method, arguments: arguments)
    }
    let map = arguments as? [String: Any] ?? [:]
    chat.applyChrome(KometChatChrome.parse(map["chrome"] as? [String: Any]))
    let rows = map["items"] as? [[String: Any]] ?? []
    let order = map["order"] as? [String]
    chat.apply(order: order, rows: rows, pinnedToEnd: true)
    if let highlight = map["highlight"] as? String {
      chat.highlight(highlight)
    }
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    if let host = host {
      host.addChild(chat)
      chat.didMove(toParent: host)
    }
  }

  deinit {
    channel.setMethodCallHandler(nil)
    chat.willMove(toParent: nil)
    chat.removeFromParent()
  }

  func view() -> UIView { chat.view }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "apply":
      chat.apply(
        order: arguments["order"] as? [String],
        rows: arguments["items"] as? [[String: Any]] ?? [],
        pinnedToEnd: false)
      result(nil)
    case "setChrome":
      chat.applyChrome(KometChatChrome.parse(arguments))
      result(nil)
    case "highlight":
      chat.highlight(arguments["id"] as? String)
      result(nil)
    case "scrollTo":
      if let id = arguments["id"] as? String { chat.scrollTo(id) }
      result(nil)
    case "scrollToEnd":
      chat.scrollToEnd(animated: true)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

final class KometChatController: UIViewController, UICollectionViewDelegate {
  var onEvent: ((String, Any?) -> Void)?

  private lazy var layout: UICollectionViewFlowLayout = {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    layout.sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    return layout
  }()
  private lazy var collectionView: UICollectionView = UICollectionView(
    frame: .zero, collectionViewLayout: layout)
  private lazy var dataSource: UICollectionViewDiffableDataSource<Int, String> = makeDataSource()
  private let sizingMessage = KometChatMessageCell(frame: .zero)
  private let sizingService = KometChatServiceCell(frame: .zero)

  private var contents: [String: KometChatMessage] = [:]
  private var order: [String] = []
  private var chrome = KometChatChrome()
  private var nearBottom = true
  private var olderArmed = false
  private var newerArmed = false
  private var didPinStart = false
  private var width: CGFloat = 0
  private var lastVisible: [String] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    view.isOpaque = false
    collectionView.backgroundColor = .clear
    collectionView.isOpaque = false
    collectionView.alwaysBounceVertical = true
    collectionView.keyboardDismissMode = .interactive
    collectionView.contentInsetAdjustmentBehavior = .never
    collectionView.delegate = self
    collectionView.register(
      KometChatMessageCell.self,
      forCellWithReuseIdentifier: KometChatMessageCell.reuseIdentifier)
    collectionView.register(
      KometChatServiceCell.self,
      forCellWithReuseIdentifier: KometChatServiceCell.reuseIdentifier)
    collectionView.frame = view.bounds
    collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(collectionView)
    applyInsets()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let next = collectionView.bounds.width
    if abs(next - width) > 0.5 {
      width = next
      collectionView.collectionViewLayout.invalidateLayout()
    }
    if !didPinStart && !order.isEmpty && next > 0 {
      didPinStart = true
      scrollToEnd(animated: false)
    }
  }

  func applyChrome(_ chrome: KometChatChrome) {
    self.chrome = chrome
    view.tintColor = chrome.accent
    applyInsets()
    collectionView.reloadData()
  }

  func apply(order incoming: [String]?, rows: [[String: Any]], pinnedToEnd: Bool) {
    for row in rows {
      guard let item = KometChatMessage.parse(row) else { continue }
      contents[item.id] = item
    }
    let wasNearBottom = nearBottom
    let before = collectionView.contentSize.height
    let offset = collectionView.contentOffset.y
    if let incoming = incoming { order = incoming }
    contents = contents.filter { order.contains($0.key) }
    var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
    snapshot.appendSections([0])
    snapshot.appendItems(order)
    if #available(iOS 15.0, *) {
      let changed = rows.compactMap { $0["id"] as? String }.filter { order.contains($0) }
      if !changed.isEmpty { snapshot.reconfigureItems(changed) }
    }
    dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
      guard let self = self else { return }
      if #available(iOS 15.0, *) {
      } else {
        self.collectionView.reloadData()
      }
      self.olderArmed = false
      self.newerArmed = false
      self.collectionView.layoutIfNeeded()
      if pinnedToEnd || wasNearBottom {
        self.scrollToEnd(animated: false)
      } else {
        let delta = self.collectionView.contentSize.height - before
        if delta > 0 {
          self.collectionView.contentOffset.y = offset + delta
        }
      }
      self.publishVisible()
    }
  }

  func highlight(_ id: String?) {
    guard let id = id else { return }
    scrollTo(id)
  }

  func scrollTo(_ id: String) {
    guard let index = order.firstIndex(of: id) else { return }
    collectionView.scrollToItem(
      at: IndexPath(item: index, section: 0), at: .centeredVertically, animated: true)
  }

  func scrollToEnd(animated: Bool) {
    guard !order.isEmpty else { return }
    collectionView.layoutIfNeeded()
    let bottom = max(
      -collectionView.adjustedContentInset.top,
      collectionView.contentSize.height - collectionView.bounds.height
        + collectionView.adjustedContentInset.bottom)
    collectionView.setContentOffset(CGPoint(x: 0, y: bottom), animated: animated)
    if !nearBottom {
      nearBottom = true
      onEvent?("nearBottom", ["on": true])
    }
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let itemWidth = collectionView.bounds.width
    guard itemWidth > 0, indexPath.item < order.count,
          let item = contents[order[indexPath.item]] else {
      return CGSize(width: max(itemWidth, 1), height: 44)
    }
    let cell: UICollectionViewCell
    if item.isService {
      sizingService.apply(item, accent: chrome.accent, width: itemWidth)
      cell = sizingService
    } else {
      sizingMessage.apply(item, accent: chrome.accent, selecting: chrome.selecting, width: itemWidth)
      cell = sizingMessage
    }
    let height = cell.contentView.systemLayoutSizeFitting(
      CGSize(width: itemWidth, height: 0),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel).height
    return CGSize(width: itemWidth, height: max(32, ceil(height)))
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let offset = scrollView.contentOffset.y
    let visibleBottom = offset + scrollView.bounds.height
    let distance = scrollView.contentSize.height + scrollView.adjustedContentInset.bottom - visibleBottom
    let atBottom = distance < 140
    if atBottom != nearBottom {
      nearBottom = atBottom
      onEvent?("nearBottom", ["on": atBottom])
    }
    if offset < 160 && !olderArmed && !order.isEmpty {
      olderArmed = true
      onEvent?("loadOlder", nil)
    }
    if atBottom && !newerArmed {
      newerArmed = true
      onEvent?("loadNewer", nil)
    }
    publishVisible()
  }

  private func applyInsets() {
    collectionView.contentInset.bottom = chrome.bottomInset
    collectionView.verticalScrollIndicatorInsets.bottom = chrome.bottomInset
  }

  private func publishVisible() {
    let ids = collectionView.indexPathsForVisibleItems.compactMap { path -> String? in
      guard path.item < order.count else { return nil }
      let id = order[path.item]
      return contents[id]?.role == .message && contents[id]?.kind != "control" ? id : nil
    }
    guard !ids.isEmpty, ids != lastVisible else { return }
    lastVisible = ids
    onEvent?("visible", ["ids": ids])
  }

  private func makeDataSource() -> UICollectionViewDiffableDataSource<Int, String> {
    UICollectionViewDiffableDataSource<Int, String>(collectionView: collectionView) {
      [weak self] collectionView, indexPath, id in
      guard let self = self, let item = self.contents[id] else {
        return collectionView.dequeueReusableCell(
          withReuseIdentifier: KometChatServiceCell.reuseIdentifier, for: indexPath)
      }
      if item.isService {
        let cell = collectionView.dequeueReusableCell(
          withReuseIdentifier: KometChatServiceCell.reuseIdentifier, for: indexPath)
          as! KometChatServiceCell
        cell.apply(item, accent: self.chrome.accent, width: collectionView.bounds.width)
        return cell
      }
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: KometChatMessageCell.reuseIdentifier, for: indexPath)
        as! KometChatMessageCell
      cell.apply(
        item, accent: self.chrome.accent, selecting: self.chrome.selecting,
        width: collectionView.bounds.width)
      cell.onEvent = { [weak self] method, arguments in
        self?.onEvent?(method, arguments)
      }
      return cell
    }
  }
}

extension KometChatController: UICollectionViewDelegateFlowLayout {}
