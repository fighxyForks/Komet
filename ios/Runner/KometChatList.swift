import Flutter
import UIKit

final class KometChatListViewFactory: NSObject, FlutterPlatformViewFactory {
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
    KometChatListPlatformView(
      frame: frame, viewId: viewId, arguments: args, messenger: messenger, host: host)
  }
}

final class KometChatListPlatformView: NSObject, FlutterPlatformView {
  private let channel: FlutterMethodChannel
  private let list: KometChatListController
  private let navigation: UINavigationController

  init(frame: CGRect, viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger,
       host: UIViewController?) {
    channel = FlutterMethodChannel(
      name: "ru.komet.app/native_chat_list/\(viewId)", binaryMessenger: messenger)
    let list = KometChatListController()
    self.list = list
    navigation = UINavigationController(rootViewController: list)
    super.init()
    navigation.view.frame = frame
    navigation.navigationBar.prefersLargeTitles = true
    list.onEvent = { [weak self] method, arguments in
      self?.channel.invokeMethod(method, arguments: arguments)
    }
    let map = arguments as? [String: Any] ?? [:]
    if let chrome = map["chrome"] as? [String: Any] {
      list.applyChrome(chrome)
    }
    let rows = map["rows"] as? [[String: Any]] ?? []
    list.applyRows(
      order: rows.compactMap { ($0["id"] as? NSNumber)?.intValue }, rows: rows)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    if let host = host {
      host.addChild(navigation)
      navigation.didMove(toParent: host)
    }
  }

  deinit {
    channel.setMethodCallHandler(nil)
    navigation.willMove(toParent: nil)
    navigation.removeFromParent()
  }

  func view() -> UIView { navigation.view }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "apply":
      let order = (arguments["order"] as? [NSNumber])?.map { $0.intValue }
      list.applyRows(order: order, rows: arguments["rows"] as? [[String: Any]] ?? [])
      result(nil)
    case "setChrome":
      list.applyChrome(arguments)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

final class KometChatListController: UIViewController, UICollectionViewDelegate,
  UICollectionViewDataSourcePrefetching, UISearchResultsUpdating {
  var onEvent: ((String, Any?) -> Void)?

  private lazy var layout: UICollectionViewFlowLayout = {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    return layout
  }()
  private lazy var collectionView: UICollectionView = UICollectionView(
    frame: .zero, collectionViewLayout: layout)
  private lazy var dataSource: UICollectionViewDiffableDataSource<Int, Int> = makeDataSource()
  private let searchController = UISearchController(searchResultsController: nil)
  private let menuButton = UIButton(type: .system)
  private let composeButton = UIButton(type: .system)

  private let layoutQueue = DispatchQueue(label: "ru.komet.app.chat-list-layout",
                                          qos: .userInitiated)
  private var contents: [Int: KometChatRowContent] = [:]
  private var order: [Int] = []
  private var strings = KometChatListStrings()
  private var accent: UIColor = .systemBlue
  private var bottomInset: CGFloat = 0
  private var query = ""
  private var hasApplied = false

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    navigationItem.largeTitleDisplayMode = .always

    collectionView.backgroundColor = .systemBackground
    collectionView.alwaysBounceVertical = true
    collectionView.delegate = self
    collectionView.prefetchDataSource = self
    collectionView.keyboardDismissMode = .onDrag
    collectionView.register(
      KometChatListCell.self, forCellWithReuseIdentifier: KometChatListCell.reuseIdentifier)
    collectionView.frame = view.bounds
    collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(collectionView)
    applyBottomInset()
    view.tintColor = accent
    navigationController?.view.tintColor = accent

    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.placeholder = strings.search
    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false
    definesPresentationContext = true

    menuButton.setImage(KometChatListStyle.symbol("ellipsis", size: 17, weight: .semibold),
                        for: .normal)
    menuButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
    menuButton.addTarget(self, action: #selector(openMenu), for: .touchUpInside)
    navigationItem.leftBarButtonItem = UIBarButtonItem(customView: menuButton)

    composeButton.setImage(KometChatListStyle.symbol("square.and.pencil", size: 17,
                                                     weight: .semibold),
                           for: .normal)
    composeButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
    composeButton.addTarget(self, action: #selector(openCompose), for: .touchUpInside)
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: composeButton)

    applySnapshot(changed: [])
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let size = CGSize(width: collectionView.bounds.width, height: KometChatListStyle.rowHeight)
    if layout.itemSize != size, size.width > 0 {
      layout.itemSize = size
      layout.invalidateLayout()
    }
  }

  func applyChrome(_ chrome: [String: Any]) {
    if let title = chrome["title"] as? String {
      navigationItem.title = title
    }
    if let value = (chrome["accent"] as? NSNumber)?.int64Value {
      let argb = UInt32(truncatingIfNeeded: value)
      accent = UIColor(red: CGFloat((argb >> 16) & 0xFF) / 255,
                       green: CGFloat((argb >> 8) & 0xFF) / 255,
                       blue: CGFloat(argb & 0xFF) / 255,
                       alpha: CGFloat((argb >> 24) & 0xFF) / 255)
      if isViewLoaded { applyAccent() }
    }
    if let inset = (chrome["bottomInset"] as? NSNumber)?.doubleValue {
      bottomInset = CGFloat(inset)
      if isViewLoaded { applyBottomInset() }
    }
    strings.apply(chrome)
    if isViewLoaded {
      searchController.searchBar.placeholder = strings.search
    }
  }

  func applyRows(order newOrder: [Int]?, rows: [[String: Any]]) {
    let strings = self.strings
    layoutQueue.async { [weak self] in
      let built = rows.compactMap(KometChatRow.init).map {
        KometChatRowContent(row: $0, strings: strings)
      }
      DispatchQueue.main.async {
        self?.merge(order: newOrder, built: built)
      }
    }
  }

  private func merge(order newOrder: [Int]?, built: [KometChatRowContent]) {
    for content in built {
      contents[content.row.id] = content
    }
    if let newOrder = newOrder {
      var seen = Set<Int>()
      order = newOrder.filter { seen.insert($0).inserted }
      contents = contents.filter { seen.contains($0.key) }
    }
    applySnapshot(changed: built.map { $0.row.id })
  }

  private func visibleOrder() -> [Int] {
    let ids = order.filter { contents[$0] != nil }
    guard !query.isEmpty else { return ids }
    return ids.filter { contents[$0]?.row.title.localizedCaseInsensitiveContains(query) ?? false }
  }

  private func applySnapshot(changed: [Int]) {
    guard isViewLoaded else { return }
    let visible = visibleOrder()
    let previous = Set(dataSource.snapshot().itemIdentifiers)
    var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
    snapshot.appendSections([0])
    snapshot.appendItems(visible, toSection: 0)
    let present = Set(visible)
    let refresh = changed.filter { present.contains($0) && previous.contains($0) }
    if !refresh.isEmpty {
      if #available(iOS 15.0, *) {
        snapshot.reconfigureItems(refresh)
      } else {
        snapshot.reloadItems(refresh)
      }
    }
    let animate = hasApplied && view.window != nil
    hasApplied = true
    dataSource.apply(snapshot, animatingDifferences: animate)
  }

  private func makeDataSource() -> UICollectionViewDiffableDataSource<Int, Int> {
    UICollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) {
      [weak self] collectionView, indexPath, id in
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: KometChatListCell.reuseIdentifier, for: indexPath)
      guard let self = self, let chatCell = cell as? KometChatListCell,
            let content = self.contents[id] else { return cell }
      let count = collectionView.numberOfItems(inSection: indexPath.section)
      chatCell.configure(content, accent: self.accent,
                         showsSeparator: indexPath.item < count - 1)
      return chatCell
    }
  }

  private func applyAccent() {
    view.tintColor = accent
    navigationController?.view.tintColor = accent
    applySnapshot(changed: order)
  }

  private func applyBottomInset() {
    collectionView.contentInset.bottom = bottomInset
    collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
  }

  @objc private func openMenu() {
    onEvent?("menu", rectArguments(menuButton))
  }

  @objc private func openCompose() {
    onEvent?("compose", rectArguments(composeButton))
  }

  private func rectArguments(_ source: UIView) -> [String: Any] {
    let rect = source.convert(source.bounds, to: nil)
    return ["x": rect.minX, "y": rect.minY, "width": rect.width, "height": rect.height]
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    guard let id = dataSource.itemIdentifier(for: indexPath) else { return }
    onEvent?("open", ["id": id])
  }

  func collectionView(_ collectionView: UICollectionView,
                      contextMenuConfigurationForItemAt indexPath: IndexPath,
                      point: CGPoint) -> UIContextMenuConfiguration? {
    contextMenu(at: indexPath)
  }

  @available(iOS 16.0, *)
  func collectionView(_ collectionView: UICollectionView,
                      contextMenuConfigurationForItemsAt indexPaths: [IndexPath],
                      point: CGPoint) -> UIContextMenuConfiguration? {
    guard indexPaths.count == 1, let indexPath = indexPaths.first else { return nil }
    return contextMenu(at: indexPath)
  }

  private func contextMenu(at indexPath: IndexPath) -> UIContextMenuConfiguration? {
    guard let id = dataSource.itemIdentifier(for: indexPath),
          let row = contents[id]?.row else { return nil }
    return UIContextMenuConfiguration(identifier: NSNumber(value: id), previewProvider: nil) {
      [weak self] _ in
      self?.menu(for: row)
    }
  }

  private func menu(for row: KometChatRow) -> UIMenu {
    func action(_ title: String, _ symbol: String, _ name: String,
                destructive: Bool = false) -> UIAction {
      UIAction(title: title, image: UIImage(systemName: symbol),
               attributes: destructive ? .destructive : []) { [weak self] _ in
        self?.onEvent?("action", ["id": row.id, "action": name])
      }
    }
    var actions: [UIMenuElement] = []
    if row.canMarkRead {
      actions.append(action(strings.markRead, "envelope.open", "markRead"))
    }
    actions.append(row.pinned
      ? action(strings.unpin, "pin.slash", "unpin")
      : action(strings.pin, "pin", "pin"))
    actions.append(row.muted
      ? action(strings.unmute, "bell", "unmute")
      : action(strings.mute, "bell.slash", "mute"))
    actions.append(action(strings.archive, "archivebox", "archive"))
    if row.canDelete {
      actions.append(UIMenu(title: "", options: .displayInline, children: [
        action(strings.delete, "trash", "delete", destructive: true),
      ]))
    }
    return UIMenu(title: "", children: actions)
  }

  func collectionView(_ collectionView: UICollectionView,
                      prefetchItemsAt indexPaths: [IndexPath]) {
    let scale = view.traitCollection.displayScale
    for indexPath in indexPaths {
      guard let id = dataSource.itemIdentifier(for: indexPath),
            let row = contents[id]?.row, !row.saved else { continue }
      KometAvatarCache.shared.prefetch(
        row.avatarUrl, side: KometChatListStyle.avatarSize, scale: scale)
    }
  }

  func updateSearchResults(for searchController: UISearchController) {
    let text = searchController.searchBar.text?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard text != query else { return }
    query = text
    applySnapshot(changed: [])
  }
}
