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
    if let stories = map["stories"] as? [String: Any] {
      list.applyStories(stories)
    }
    list.applyArchive(map["archive"] as? [String: Any])
    if let folders = map["folders"] as? [String: Any] {
      list.applyFolders(folders)
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
    case "setEditing":
      list.setListEditing((arguments["on"] as? NSNumber)?.boolValue ?? false, notify: true)
      result(nil)
    case "actionSheet":
      list.presentActionSheet(arguments, result: result)
    case "setStories":
      list.applyStories(arguments)
      result(nil)
    case "setArchive":
      list.applyArchive(arguments["archive"] as? [String: Any])
      result(nil)
    case "setFolders":
      list.applyFolders(arguments)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

final class KometChatListController: UIViewController, UICollectionViewDelegate,
  UICollectionViewDataSourcePrefetching, UIGestureRecognizerDelegate {
  private static let archiveId = Int.min
  private static let archivePullThreshold: CGFloat = 120

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
  private let header = KometChatListHeader()
  private let composeButton = UIButton(type: .system)
  private let downloadsButton = UIButton(type: .system)
  private let lockButton = UIButton(type: .system)
  private let editBar = KometChatListEditBar()
  private lazy var reorderGesture: UILongPressGestureRecognizer = {
    let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleReorder(_:)))
    gesture.minimumPressDuration = 0.05
    gesture.delegate = self
    return gesture
  }()

  private let layoutQueue = DispatchQueue(label: "ru.komet.app.chat-list-layout",
                                          qos: .userInitiated)
  private var contents: [Int: KometChatRowContent] = [:]
  private var order: [Int] = []
  private var strings = KometChatListStrings()
  private var accent: UIColor = .systemBlue
  private var bottomInset: CGFloat = 0
  private var query = ""
  private var hasApplied = false
  private var lockEnabled = false
  private var editingList = false
  private var selectedIds = Set<Int>()
  private var reordering = false
  private var archive: [String: Any]?
  private var archiveContent: KometChatRowContent?
  private var archiveRevealed = false
  private var archiveArmed = false
  private var stories: [KometStoryItem] = []
  private var folders: [KometFolderItem] = []
  private var selectedFolder: String?
  private var storiesVisible = false

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

    KometNavigationChrome.styleBar(navigationController?.navigationBar)
    header.setPlaceholder(strings.search)
    header.accent = accent
    header.setStories(stories, visible: storiesVisible)
    header.onQuery = { [weak self] text in self?.updateQuery(text) }
    header.onStory = { [weak self] item, rect in
      self?.onEvent?("story", ["ownerId": item.ownerId, "x": rect.minX, "y": rect.minY,
                               "width": rect.width, "height": rect.height])
    }
    header.onAddStory = { [weak self] in self?.onEvent?("storyAdd", nil) }
    header.setFolders(folders, selected: selectedFolder)
    header.onFolder = { [weak self] id in
      self?.onEvent?("folder", ["id": id])
    }
    header.onFolderMenu = { [weak self] id, rect in
      self?.onEvent?("folderMenu", ["id": id, "x": rect.minX, "y": rect.minY,
                                    "width": rect.width, "height": rect.height])
    }
    collectionView.addSubview(header)
    layoutHeader()

    setUpBarButton(composeButton, symbol: "square.and.pencil", action: #selector(openCompose))
    setUpBarButton(downloadsButton, symbol: "arrow.down.circle",
                   action: #selector(openDownloads))
    setUpBarButton(lockButton, symbol: "lock.open", action: #selector(lockNow))
    updateBarItems()

    collectionView.addGestureRecognizer(reorderGesture)
    if #available(iOS 14.0, *) {
      dataSource.reorderingHandlers.canReorderItem = { [weak self] id in
        self?.isReorderable(id) ?? false
      }
      dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
        self?.finishReorder(transaction.finalSnapshot.itemIdentifiers)
      }
    }

    editBar.alpha = 0
    editBar.isHidden = true
    editBar.translatesAutoresizingMaskIntoConstraints = false
    editBar.onAction = { [weak self] action in self?.handleEditAction(action) }
    view.addSubview(editBar)
    NSLayoutConstraint.activate([
      editBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      editBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      editBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                      constant: -8),
    ])
    updateEditBar()

    applySnapshot(changed: [])
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    layoutHeader()
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
    if let lock = (chrome["lockEnabled"] as? NSNumber)?.boolValue {
      lockEnabled = lock
    }
    strings.apply(chrome)
    if isViewLoaded {
      header.setPlaceholder(strings.search)
      updateBarItems()
      updateEditBar()
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
      let kept = selectedIds.intersection(seen)
      if kept != selectedIds {
        selectedIds = kept
        emitSelection()
      }
    }
    applySnapshot(changed: built.map { $0.row.id })
    updateEditBar()
  }

  private func visibleOrder() -> [Int] {
    let ids = order.filter { contents[$0] != nil }
    guard query.isEmpty else {
      return ids.filter {
        contents[$0]?.row.title.localizedCaseInsensitiveContains(query) ?? false
      }
    }
    return showsArchiveRow ? [KometChatListController.archiveId] + ids : ids
  }

  private var archivePullEnabled: Bool {
    (archive?["pull"] as? NSNumber)?.boolValue ?? true
  }

  private var showsArchiveRow: Bool {
    archiveContent != nil && !editingList && (!archivePullEnabled || archiveRevealed)
  }

  private var archiveAwaitsPull: Bool {
    archiveContent != nil && archivePullEnabled && !archiveRevealed && !editingList
      && query.isEmpty
  }

  func applyStories(_ payload: [String: Any]) {
    stories = (payload["items"] as? [[String: Any]] ?? []).compactMap(KometStoryItem.init)
    storiesVisible = (payload["visible"] as? NSNumber)?.boolValue ?? false
    guard isViewLoaded else { return }
    header.setStories(stories, visible: storiesVisible)
    layoutHeader()
  }

  func applyFolders(_ payload: [String: Any]) {
    folders = (payload["items"] as? [[String: Any]] ?? []).compactMap(KometFolderItem.init)
    selectedFolder = payload["selected"] as? String
    guard isViewLoaded else { return }
    header.setFolders(folders, selected: selectedFolder)
    layoutHeader()
  }

  func applyArchive(_ payload: [String: Any]?) {
    archive = payload
    if let payload = payload, ((payload["count"] as? NSNumber)?.intValue ?? 0) > 0 {
      let map: [String: Any] = [
        "id": KometChatListController.archiveId,
        "title": payload["title"] as? String ?? "",
        "kind": "archive",
        "text": payload["text"] as? String ?? "",
        "unread": payload["unread"] ?? 0,
        "muted": true,
      ]
      archiveContent = KometChatRow(map).map { KometChatRowContent(row: $0, strings: strings) }
    } else {
      archiveContent = nil
      archiveRevealed = false
    }
    guard isViewLoaded else { return }
    applySnapshot(changed: [KometChatListController.archiveId])
  }

  private func content(for id: Int) -> KometChatRowContent? {
    id == KometChatListController.archiveId ? archiveContent : contents[id]
  }

  private func layoutHeader() {
    let height = header.preferredHeight
    let width = collectionView.bounds.width
    let previousTop = collectionView.contentInset.top
    header.frame = CGRect(x: 0, y: -height, width: width, height: height)
    guard previousTop != height else { return }
    let atTop = collectionView.contentOffset.y <= -collectionView.adjustedContentInset.top + 1
    collectionView.contentInset.top = height
    if atTop {
      collectionView.contentOffset.y = -collectionView.adjustedContentInset.top
    }
  }

  private func updateQuery(_ text: String) {
    guard text != query else { return }
    query = text
    applySnapshot(changed: [])
  }

  private func revealArchive() {
    guard archiveAwaitsPull else { return }
    archiveRevealed = true
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    applySnapshot(changed: [])
  }

  private func collapseArchiveIfScrolledPast(_ scrollView: UIScrollView) {
    guard archiveRevealed, archivePullEnabled, !editingList else { return }
    let offset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
    let rowHeight = KometChatListStyle.rowHeight
    guard offset > rowHeight + 8 else { return }
    archiveRevealed = false
    applySnapshot(changed: [], animated: false)
    scrollView.contentOffset.y -= rowHeight
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    collapseArchiveIfScrolledPast(scrollView)
    guard archiveAwaitsPull, scrollView.isTracking else {
      archiveArmed = false
      return
    }
    let pull = -(scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
    let armed = pull > KometChatListController.archivePullThreshold
    if armed != archiveArmed {
      archiveArmed = armed
      if armed { UISelectionFeedbackGenerator().selectionChanged() }
    }
  }

  func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint,
                                 targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    guard archiveArmed else { return }
    archiveArmed = false
    revealArchive()
  }

  private func applySnapshot(changed: [Int], animated: Bool = true) {
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
    let animate = animated && hasApplied && view.window != nil
    hasApplied = true
    dataSource.apply(snapshot, animatingDifferences: animate)
  }

  private func makeDataSource() -> UICollectionViewDiffableDataSource<Int, Int> {
    UICollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) {
      [weak self] collectionView, indexPath, id in
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: KometChatListCell.reuseIdentifier, for: indexPath)
      guard let self = self, let chatCell = cell as? KometChatListCell,
            let content = self.content(for: id) else { return cell }
      let count = collectionView.numberOfItems(inSection: indexPath.section)
      chatCell.configure(content, accent: self.accent,
                         showsSeparator: indexPath.item < count - 1,
                         editState: self.editState(for: id))
      return chatCell
    }
  }

  private func applyAccent() {
    header.accent = accent
    view.tintColor = accent
    navigationController?.view.tintColor = accent
    applySnapshot(changed: order)
  }

  private func applyBottomInset() {
    collectionView.contentInset.bottom = bottomInset
    collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
  }

  @objc private func openCompose() {
    onEvent?("compose", rectArguments(composeButton))
  }

  @objc private func openDownloads() {
    onEvent?("downloads", rectArguments(downloadsButton))
  }

  @objc private func lockNow() {
    onEvent?("lock", rectArguments(lockButton))
  }

  private func setUpBarButton(_ button: UIButton, symbol: String, action: Selector) {
    button.setImage(KometChatListStyle.symbol(symbol, size: 17, weight: .semibold), for: .normal)
    button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
    button.addTarget(self, action: action, for: .touchUpInside)
  }

  private func updateBarItems() {
    let edit = UIBarButtonItem(
      title: editingList ? strings.done : strings.edit,
      style: editingList ? .done : .plain,
      target: self, action: #selector(toggleEditing))
    navigationItem.setLeftBarButton(edit, animated: false)
    var trailing: [UIBarButtonItem] = []
    if !editingList {
      trailing.append(UIBarButtonItem(customView: composeButton))
      trailing.append(UIBarButtonItem(customView: downloadsButton))
      if lockEnabled { trailing.append(UIBarButtonItem(customView: lockButton)) }
    }
    navigationItem.setRightBarButtonItems(trailing, animated: true)
  }

  @objc private func toggleEditing() {
    setListEditing(!editingList, notify: true)
  }

  func setListEditing(_ on: Bool, notify: Bool) {
    guard on != editingList else { return }
    editingList = on
    selectedIds.removeAll()
    header.setSearchEnabled(!on)
    updateBarItems()
    applySnapshot(changed: [])
    updateEditBar()
    for cell in collectionView.visibleCells {
      guard let chatCell = cell as? KometChatListCell,
            let indexPath = collectionView.indexPath(for: cell),
            let id = dataSource.itemIdentifier(for: indexPath) else { continue }
      chatCell.applyEditState(editState(for: id), animated: true)
    }
    if on { editBar.isHidden = false }
    editBar.transform = on ? CGAffineTransform(translationX: 0, y: 24) : .identity
    UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState]) {
      self.editBar.alpha = on ? 1 : 0
      self.editBar.transform = on ? .identity : CGAffineTransform(translationX: 0, y: 24)
    } completion: { _ in
      if !self.editingList { self.editBar.isHidden = true }
    }
    if notify { onEvent?("editing", ["on": on]) }
    emitSelection()
  }

  private func editState(for id: Int) -> KometChatEditState {
    KometChatEditState(editing: editingList,
                       selected: editingList && selectedIds.contains(id),
                       reorderable: editingList && isReorderable(id))
  }

  private func isReorderable(_ id: Int) -> Bool {
    guard #available(iOS 14.0, *) else { return false }
    guard editingList, query.isEmpty else { return false }
    return contents[id]?.row.pinned ?? false
  }

  private func toggleSelection(_ id: Int, at indexPath: IndexPath) {
    if selectedIds.contains(id) {
      selectedIds.remove(id)
    } else {
      selectedIds.insert(id)
    }
    (collectionView.cellForItem(at: indexPath) as? KometChatListCell)?
      .applyEditState(editState(for: id), animated: true)
    updateEditBar()
    emitSelection()
  }

  private func emitSelection() {
    onEvent?("selection", ["ids": orderedSelection()])
  }

  private func orderedSelection() -> [Int] {
    order.filter { selectedIds.contains($0) }
  }

  private func updateEditBar() {
    let selected = orderedSelection().compactMap { contents[$0]?.row }
    editBar.update(
      readTitle: selected.isEmpty ? strings.readAll : strings.readSelected,
      archiveTitle: strings.toArchive,
      deleteTitle: strings.deleteSelected,
      canArchive: !selected.isEmpty,
      canDelete: !selected.isEmpty && selected.allSatisfy { $0.canDelete },
      accent: accent)
  }

  private func handleEditAction(_ action: KometChatListEditBar.Action) {
    let ids = orderedSelection()
    switch action {
    case .read:
      onEvent?("bulk", ["action": ids.isEmpty ? "readAll" : "read", "ids": ids])
      setListEditing(false, notify: true)
    case .archive:
      guard !ids.isEmpty else { return }
      onEvent?("bulk", ["action": "archive", "ids": ids])
      setListEditing(false, notify: true)
    case .delete:
      guard !ids.isEmpty else { return }
      onEvent?("bulk", ["action": "delete", "ids": ids])
    }
  }

  func presentActionSheet(_ arguments: [String: Any], result: @escaping FlutterResult) {
    let title = arguments["title"] as? String
    let message = arguments["message"] as? String
    let sheet = UIAlertController(
      title: title?.isEmpty == false ? title : nil,
      message: message?.isEmpty == false ? message : nil,
      preferredStyle: .actionSheet)
    var finished = false
    func finish(_ value: String?) {
      guard !finished else { return }
      finished = true
      result(value)
    }
    for action in arguments["actions"] as? [[String: Any]] ?? [] {
      guard let id = action["id"] as? String, let label = action["title"] as? String else {
        continue
      }
      let destructive = (action["destructive"] as? NSNumber)?.boolValue ?? false
      sheet.addAction(UIAlertAction(title: label, style: destructive ? .destructive : .default) {
        _ in finish(id)
      })
    }
    sheet.addAction(UIAlertAction(title: strings.cancel, style: .cancel) { _ in finish(nil) })
    if let popover = sheet.popoverPresentationController {
      let anchor: UIView = editingList ? editBar.deleteButton : view
      popover.sourceView = anchor
      popover.sourceRect = anchor.bounds
    }
    let presenter: UIViewController = navigationController ?? self
    guard presenter.presentedViewController == nil else {
      finish(nil)
      return
    }
    presenter.present(sheet, animated: true)
  }

  @objc private func handleReorder(_ gesture: UILongPressGestureRecognizer) {
    let location = gesture.location(in: collectionView)
    switch gesture.state {
    case .began:
      guard let indexPath = collectionView.indexPathForItem(at: location) else { return }
      reordering = collectionView.beginInteractiveMovementForItem(at: indexPath)
      if reordering { UISelectionFeedbackGenerator().selectionChanged() }
    case .changed:
      guard reordering else { return }
      collectionView.updateInteractiveMovementTargetPosition(
        CGPoint(x: collectionView.bounds.midX, y: location.y))
    case .ended:
      guard reordering else { return }
      reordering = false
      collectionView.endInteractiveMovement()
    default:
      guard reordering else { return }
      reordering = false
      collectionView.cancelInteractiveMovement()
    }
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard gestureRecognizer === reorderGesture else { return true }
    let location = gestureRecognizer.location(in: collectionView)
    guard editingList,
          let indexPath = collectionView.indexPathForItem(at: location),
          let cell = collectionView.cellForItem(at: indexPath) as? KometChatListCell else {
      return false
    }
    return cell.gripContains(collectionView.convert(location, to: cell))
  }

  private var pinnedCount: Int {
    dataSource.snapshot().itemIdentifiers.prefix { contents[$0]?.row.pinned ?? false }.count
  }

  private func clampedMove(_ proposed: IndexPath) -> IndexPath {
    let limit = max(pinnedCount - 1, 0)
    return IndexPath(item: min(max(proposed.item, 0), limit), section: proposed.section)
  }

  func collectionView(_ collectionView: UICollectionView,
                      targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath,
                      toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
    clampedMove(proposedIndexPath)
  }

  @available(iOS 15.0, *)
  func collectionView(_ collectionView: UICollectionView,
                      targetIndexPathForMoveOfItemFromOriginalIndexPath originalIndexPath: IndexPath,
                      atCurrentIndexPath currentIndexPath: IndexPath,
                      toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
    clampedMove(proposedIndexPath)
  }

  private func finishReorder(_ ids: [Int]) {
    let moved = Set(ids)
    order = ids + order.filter { !moved.contains($0) }
    let pinned = ids.filter { contents[$0]?.row.pinned ?? false }
    onEvent?("reorderPinned", ["ids": pinned])
  }

  private func rectArguments(_ source: UIView) -> [String: Any] {
    let rect = source.convert(source.bounds, to: nil)
    return ["x": rect.minX, "y": rect.minY, "width": rect.width, "height": rect.height]
  }

  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                      forItemAt indexPath: IndexPath) {
    guard let chatCell = cell as? KometChatListCell,
          let id = dataSource.itemIdentifier(for: indexPath) else { return }
    chatCell.applyEditState(editState(for: id), animated: false)
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: !editingList)
    guard let id = dataSource.itemIdentifier(for: indexPath) else { return }
    if id == KometChatListController.archiveId {
      onEvent?("archive", nil)
      return
    }
    if editingList {
      toggleSelection(id, at: indexPath)
      return
    }
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
    guard !editingList, let id = dataSource.itemIdentifier(for: indexPath),
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

}
