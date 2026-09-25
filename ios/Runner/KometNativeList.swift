import Flutter
import UIKit

struct KometListAction {
  let id: String
  let title: String
  let symbol: String
  let destructive: Bool

  init?(_ map: [String: Any]) {
    guard let id = map["id"] as? String else { return nil }
    self.id = id
    title = map["title"] as? String ?? ""
    symbol = map["symbol"] as? String ?? ""
    destructive = (map["destructive"] as? NSNumber)?.boolValue ?? false
  }
}

struct KometListRow {
  let id: String
  let isAction: Bool
  let title: String
  let alert: Bool
  let verified: Bool
  let subtitle: String
  let subtitleSymbol: String?
  let trailing: String
  let avatarUrl: String
  let avatarSeed: Int
  let avatarSymbol: String?
  let symbol: String?
  let menu: [KometListAction]

  init?(_ map: [String: Any]) {
    guard let id = map["id"] as? String else { return nil }
    self.id = id
    isAction = map["style"] as? String == "action"
    title = map["title"] as? String ?? ""
    alert = (map["alert"] as? NSNumber)?.boolValue ?? false
    verified = (map["verified"] as? NSNumber)?.boolValue ?? false
    subtitle = map["subtitle"] as? String ?? ""
    subtitleSymbol = map["subtitleSymbol"] as? String
    trailing = map["trailing"] as? String ?? ""
    avatarUrl = map["avatarUrl"] as? String ?? ""
    avatarSeed = (map["avatarSeed"] as? NSNumber)?.intValue ?? 0
    avatarSymbol = map["avatarSymbol"] as? String
    symbol = map["symbol"] as? String
    menu = (map["menu"] as? [[String: Any]] ?? []).compactMap(KometListAction.init)
  }
}

struct KometListSection {
  let id: String
  let title: String
  let rows: [String]

  init?(_ map: [String: Any]) {
    guard let id = map["id"] as? String else { return nil }
    self.id = id
    title = map["title"] as? String ?? ""
    rows = map["rows"] as? [String] ?? []
  }
}

final class KometNativeListViewFactory: NSObject, FlutterPlatformViewFactory {
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
    KometNativeListPlatformView(
      frame: frame, viewId: viewId, arguments: args, messenger: messenger, host: host)
  }
}

final class KometNativeListPlatformView: NSObject, FlutterPlatformView {
  private let channel: FlutterMethodChannel
  private let list: KometNativeListController
  private let navigation: UINavigationController

  init(frame: CGRect, viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger,
       host: UIViewController?) {
    channel = FlutterMethodChannel(
      name: "ru.komet.app/native_list/\(viewId)", binaryMessenger: messenger)
    let list = KometNativeListController()
    self.list = list
    navigation = UINavigationController(rootViewController: list)
    super.init()
    navigation.view.frame = frame
    list.onEvent = { [weak self] method, arguments in
      self?.channel.invokeMethod(method, arguments: arguments)
    }
    let map = arguments as? [String: Any] ?? [:]
    if let chrome = map["chrome"] as? [String: Any] {
      list.applyChrome(chrome)
    }
    list.apply(
      sections: map["sections"] as? [[String: Any]],
      rows: map["rows"] as? [[String: Any]] ?? [])
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
      list.apply(
        sections: arguments["sections"] as? [[String: Any]],
        rows: arguments["rows"] as? [[String: Any]] ?? [])
      result(nil)
    case "setChrome":
      list.applyChrome(arguments)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

final class KometNativeListDataSource: UITableViewDiffableDataSource<String, String> {
  var titles: [String: String] = [:]
  var showsIndex = false
  var indexTitles: [String] = []

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int)
    -> String? {
    let ids = snapshot().sectionIdentifiers
    guard section < ids.count, let title = titles[ids[section]], !title.isEmpty else {
      return nil
    }
    return title
  }

  override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    guard showsIndex else { return nil }
    if !indexTitles.isEmpty { return indexTitles }
    let titles = snapshot().sectionIdentifiers.compactMap { self.titles[$0] }
      .filter { !$0.isEmpty }
    return titles.isEmpty ? nil : titles
  }

  override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String,
                          at index: Int) -> Int {
    let sectionTitles = snapshot().sectionIdentifiers.map { titles[$0] ?? "" }
    if let exact = sectionTitles.firstIndex(of: title) { return exact }
    guard let wanted = indexTitles.firstIndex(of: title) else { return 0 }
    let following = sectionTitles.firstIndex { sectionTitle in
      guard let position = indexTitles.firstIndex(of: sectionTitle) else { return false }
      return position >= wanted
    }
    return following ?? max(0, sectionTitles.count - 1)
  }
}

final class KometNativeListController: UIViewController, UITableViewDelegate,
  UISearchResultsUpdating {
  var onEvent: ((String, Any?) -> Void)?

  private let tableView = UITableView(frame: .zero, style: .plain)
  private lazy var dataSource: KometNativeListDataSource = makeDataSource()
  private var searchController: UISearchController?
  private var segmentedControl: UISegmentedControl?
  private var buttons: [(id: String, button: UIButton)] = []
  private let spinner = UIActivityIndicatorView(style: .medium)
  private let emptyLabel = UILabel()

  private var sections: [KometListSection] = []
  private var rows: [String: KometListRow] = [:]
  private var chrome: [String: Any] = [:]
  private var accent: UIColor = .systemBlue
  private var query = ""
  private var hasApplied = false

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    tableView.frame = view.bounds
    tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    tableView.backgroundColor = .systemBackground
    tableView.delegate = self
    tableView.keyboardDismissMode = .onDrag
    tableView.separatorInset = UIEdgeInsets(
      top: 0, left: KometListCell.textInset, bottom: 0, right: 0)
    tableView.register(KometListCell.self, forCellReuseIdentifier: KometListCell.reuseIdentifier)
    tableView.sectionHeaderHeight = 28
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0
    }
    view.addSubview(tableView)
    emptyLabel.textColor = KometChatListStyle.secondary
    emptyLabel.font = .systemFont(ofSize: 17)
    emptyLabel.textAlignment = .center
    emptyLabel.numberOfLines = 0
    applyChromeToViews()
    applySnapshot(changed: [])
  }

  func applyChrome(_ update: [String: Any]) {
    chrome.merge(update) { _, new in new }
    if let value = (update["accent"] as? NSNumber)?.int64Value {
      let argb = UInt32(truncatingIfNeeded: value)
      accent = UIColor(red: CGFloat((argb >> 16) & 0xFF) / 255,
                       green: CGFloat((argb >> 8) & 0xFF) / 255,
                       blue: CGFloat(argb & 0xFF) / 255,
                       alpha: CGFloat((argb >> 24) & 0xFF) / 255)
    }
    navigationItem.title = chrome["title"] as? String
    if isViewLoaded {
      applyChromeToViews()
      applySnapshot(changed: [])
    }
  }

  private func applyChromeToViews() {
    KometNavigationChrome.styleBar(navigationController?.navigationBar)
    view.tintColor = accent
    navigationController?.view.tintColor = accent

    let segments = chrome["segments"] as? [String] ?? []
    if segments.isEmpty {
      segmentedControl = nil
      navigationItem.titleView = nil
      let large = (chrome["largeTitle"] as? NSNumber)?.boolValue ?? true
      navigationController?.navigationBar.prefersLargeTitles = large
      navigationItem.largeTitleDisplayMode = large ? .always : .never
    } else {
      let control = segmentedControl ?? makeSegmentedControl(segments)
      segmentedControl = control
      control.selectedSegmentIndex = (chrome["segment"] as? NSNumber)?.intValue ?? 0
      navigationItem.titleView = control
      navigationController?.navigationBar.prefersLargeTitles = false
      navigationItem.largeTitleDisplayMode = .never
    }

    if let placeholder = chrome["search"] as? String {
      let controller = searchController ?? makeSearchController()
      controller.searchBar.placeholder = placeholder
    }

    let specs = chrome["buttons"] as? [[String: Any]] ?? []
    let ids = specs.compactMap { $0["id"] as? String }
    if ids != buttons.map({ $0.id }) {
      buttons = specs.compactMap { spec -> (id: String, button: UIButton)? in
        guard let id = spec["id"] as? String, let symbol = spec["symbol"] as? String else {
          return nil
        }
        let button = UIButton(type: .system)
        button.setImage(KometChatListStyle.symbol(symbol, size: 17, weight: .semibold),
                        for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return (id: id, button: button)
      }
      navigationItem.rightBarButtonItems = buttons.reversed().map {
        UIBarButtonItem(customView: $0.button)
      }
    }

    let inset = CGFloat((chrome["bottomInset"] as? NSNumber)?.doubleValue ?? 0)
    tableView.contentInset.bottom = inset
    tableView.verticalScrollIndicatorInsets.bottom = inset
    emptyLabel.text = chrome["emptyText"] as? String
    dataSource.showsIndex = (chrome["index"] as? NSNumber)?.boolValue ?? false
    dataSource.indexTitles = chrome["indexTitles"] as? [String] ?? []
  }

  private func makeSegmentedControl(_ segments: [String]) -> UISegmentedControl {
    let control = UISegmentedControl(items: segments)
    control.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
    return control
  }

  private func makeSearchController() -> UISearchController {
    let controller = UISearchController(searchResultsController: nil)
    controller.searchResultsUpdater = self
    controller.obscuresBackgroundDuringPresentation = false
    navigationItem.searchController = controller
    KometNavigationChrome.pinSearchToTop(navigationItem)
    definesPresentationContext = true
    searchController = controller
    return controller
  }

  func apply(sections update: [[String: Any]]?, rows updatedRows: [[String: Any]]) {
    let decoded = updatedRows.compactMap(KometListRow.init)
    for row in decoded {
      rows[row.id] = row
    }
    if let update = update {
      sections = update.compactMap(KometListSection.init)
      let alive = Set(sections.flatMap { $0.rows })
      rows = rows.filter { alive.contains($0.key) }
    }
    applySnapshot(changed: decoded.map { $0.id })
  }

  private func visibleSections() -> [(section: KometListSection, rows: [String])] {
    var seen = Set<String>()
    return sections.compactMap { section -> (section: KometListSection, rows: [String])? in
      let ids = section.rows.filter { id in
        guard let row = rows[id], seen.insert(id).inserted else { return false }
        if query.isEmpty { return true }
        return !row.isAction && row.title.localizedCaseInsensitiveContains(query)
      }
      return ids.isEmpty ? nil : (section: section, rows: ids)
    }
  }

  private func applySnapshot(changed: [String]) {
    guard isViewLoaded else { return }
    let visible = visibleSections()
    var usedSections = Set<String>()
    var snapshot = NSDiffableDataSourceSnapshot<String, String>()
    var titles: [String: String] = [:]
    for entry in visible where usedSections.insert(entry.section.id).inserted {
      snapshot.appendSections([entry.section.id])
      snapshot.appendItems(entry.rows, toSection: entry.section.id)
      titles[entry.section.id] = entry.section.title
    }
    let previous = Set(dataSource.snapshot().itemIdentifiers)
    let present = Set(snapshot.itemIdentifiers)
    let refresh = changed.filter { present.contains($0) && previous.contains($0) }
    if !refresh.isEmpty {
      if #available(iOS 15.0, *) {
        snapshot.reconfigureItems(refresh)
      } else {
        snapshot.reloadItems(refresh)
      }
    }
    dataSource.titles = titles
    let animate = hasApplied && view.window != nil
    hasApplied = true
    dataSource.apply(snapshot, animatingDifferences: animate)
    updateBackground(hasItems: visible.contains { entry in
      entry.rows.contains { rows[$0]?.isAction == false }
    })
  }

  private func updateBackground(hasItems: Bool) {
    let loading = (chrome["loading"] as? NSNumber)?.boolValue ?? false
    if loading {
      spinner.startAnimating()
      tableView.backgroundView = spinner
    } else if !hasItems, !(emptyLabel.text ?? "").isEmpty {
      spinner.stopAnimating()
      tableView.backgroundView = emptyLabel
    } else {
      spinner.stopAnimating()
      tableView.backgroundView = nil
    }
  }

  private func makeDataSource() -> KometNativeListDataSource {
    KometNativeListDataSource(tableView: tableView) { [weak self] tableView, indexPath, id in
      let cell = tableView.dequeueReusableCell(
        withIdentifier: KometListCell.reuseIdentifier, for: indexPath)
      guard let self = self, let listCell = cell as? KometListCell,
            let row = self.rows[id] else { return cell }
      listCell.configure(row, accent: self.accent)
      return listCell
    }
  }

  @objc private func buttonTapped(_ sender: UIButton) {
    guard let entry = buttons.first(where: { $0.button === sender }) else { return }
    let rect = sender.convert(sender.bounds, to: nil)
    onEvent?("button", ["id": entry.id, "x": rect.minX, "y": rect.minY,
                        "width": rect.width, "height": rect.height])
  }

  @objc private func segmentChanged(_ sender: UISegmentedControl) {
    onEvent?("segment", ["index": sender.selectedSegmentIndex])
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    guard let id = dataSource.itemIdentifier(for: indexPath), let row = rows[id] else {
      return KometListCell.itemHeight
    }
    return row.isAction ? KometListCell.actionHeight : KometListCell.itemHeight
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard let id = dataSource.itemIdentifier(for: indexPath) else { return }
    onEvent?("tap", ["id": id])
  }

  func tableView(_ tableView: UITableView,
                 contextMenuConfigurationForRowAt indexPath: IndexPath,
                 point: CGPoint) -> UIContextMenuConfiguration? {
    guard let id = dataSource.itemIdentifier(for: indexPath), let row = rows[id],
          !row.menu.isEmpty else { return nil }
    return UIContextMenuConfiguration(identifier: id as NSString, previewProvider: nil) {
      [weak self] _ in
      UIMenu(title: "", children: row.menu.map { action in
        UIAction(title: action.title, image: UIImage(systemName: action.symbol),
                 attributes: action.destructive ? .destructive : []) { _ in
          self?.onEvent?("menu", ["id": row.id, "action": action.id])
        }
      })
    }
  }

  func tableView(_ tableView: UITableView,
                 trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
    guard let id = dataSource.itemIdentifier(for: indexPath), let row = rows[id] else {
      return nil
    }
    let actions = row.menu.filter { $0.destructive }.map { action -> UIContextualAction in
      let contextual = UIContextualAction(style: .destructive, title: action.title) {
        [weak self] _, _, done in
        self?.onEvent?("menu", ["id": row.id, "action": action.id])
        done(true)
      }
      contextual.image = UIImage(systemName: action.symbol)
      return contextual
    }
    return actions.isEmpty ? nil : UISwipeActionsConfiguration(actions: actions)
  }

  func updateSearchResults(for searchController: UISearchController) {
    let text = searchController.searchBar.text?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard text != query else { return }
    query = text
    applySnapshot(changed: [])
  }
}

final class KometListCell: UITableViewCell {
  static let reuseIdentifier = "KometListCell"
  static let itemHeight: CGFloat = 62
  static let actionHeight: CGFloat = 52
  static let avatarSize: CGFloat = 44
  static let textInset: CGFloat = 72

  private let avatarView = UIImageView()
  private let titleLabel = UILabel()
  private let verifiedIcon = UIImageView()
  private let subtitleIcon = UIImageView()
  private let subtitleLabel = UILabel()
  private let trailingLabel = UILabel()
  private var avatarUrl = ""
  private var isAction = false

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .systemBackground
    avatarView.contentMode = .center
    titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
    subtitleLabel.font = .systemFont(ofSize: 15)
    subtitleLabel.textColor = KometChatListStyle.secondary
    subtitleIcon.tintColor = KometChatListStyle.secondary
    trailingLabel.font = .systemFont(ofSize: 15)
    trailingLabel.textColor = KometChatListStyle.secondary
    trailingLabel.textAlignment = .right
    [avatarView, titleLabel, verifiedIcon, subtitleIcon, subtitleLabel, trailingLabel]
      .forEach(contentView.addSubview)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  func configure(_ row: KometListRow, accent: UIColor) {
    isAction = row.isAction
    let scale = traitCollection.displayScale > 0 ? traitCollection.displayScale : UIScreen.main.scale
    let side = KometListCell.avatarSize
    avatarUrl = row.avatarUrl

    if row.isAction {
      avatarView.image = row.symbol.flatMap {
        KometChatListStyle.symbol($0, size: 20, weight: .medium)
      }
      avatarView.tintColor = accent
      titleLabel.textColor = accent
    } else if let symbol = row.avatarSymbol {
      avatarView.image = KometAvatarCache.shared.symbolAvatar(
        symbol, side: side, scale: scale, fill: accent.withAlphaComponent(0.18), tint: accent)
      titleLabel.textColor = row.alert ? .systemRed : .label
    } else {
      if !row.avatarUrl.isEmpty,
         let image = KometAvatarCache.shared.cached(row.avatarUrl, side: side) {
        avatarView.image = image
      } else {
        avatarView.image = KometAvatarCache.shared.letterAvatar(
          seed: row.avatarSeed, title: row.title, side: side, scale: scale)
        if !row.avatarUrl.isEmpty {
          let requested = row.avatarUrl
          KometAvatarCache.shared.load(requested, side: side, scale: scale) { [weak self] image in
            guard let self = self, self.avatarUrl == requested else { return }
            self.avatarView.image = image
          }
        }
      }
      titleLabel.textColor = row.alert ? .systemRed : .label
    }

    titleLabel.text = row.title
    verifiedIcon.isHidden = !row.verified
    verifiedIcon.tintColor = accent
    verifiedIcon.image = KometChatListStyle.symbol("checkmark.seal.fill", size: 14)
    subtitleLabel.text = row.subtitle
    subtitleLabel.isHidden = row.subtitle.isEmpty || row.isAction
    subtitleIcon.image = row.subtitleSymbol.flatMap { KometChatListStyle.symbol($0, size: 12) }
    subtitleIcon.isHidden = subtitleIcon.image == nil || subtitleLabel.isHidden
    trailingLabel.text = row.trailing
    trailingLabel.isHidden = row.trailing.isEmpty
    setNeedsLayout()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let bounds = contentView.bounds
    let side = KometListCell.avatarSize
    avatarView.frame = CGRect(x: 16, y: (bounds.height - side) / 2, width: side, height: side)

    let right = bounds.width - 16
    var textRight = right
    if !trailingLabel.isHidden {
      let width = ceil(trailingLabel.sizeThatFits(CGSize(width: 120, height: 20)).width)
      trailingLabel.frame = CGRect(x: right - width, y: (bounds.height - 20) / 2,
                                   width: width, height: 20)
      textRight = right - width - 8
    }

    let x = KometListCell.textInset
    let twoLines = !subtitleLabel.isHidden
    let titleY = twoLines ? (bounds.height - 42) / 2 : (bounds.height - 22) / 2
    let verifiedWidth: CGFloat = verifiedIcon.isHidden ? 0 : 18
    let fit = ceil(titleLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: 22)).width)
    let titleWidth = max(0, min(fit, textRight - x - verifiedWidth))
    titleLabel.frame = CGRect(x: x, y: titleY, width: titleWidth, height: 22)
    if let size = verifiedIcon.image?.size, !verifiedIcon.isHidden {
      verifiedIcon.frame = CGRect(x: titleLabel.frame.maxX + 4, y: titleY + 11 - size.height / 2,
                                  width: size.width, height: size.height)
    }

    if twoLines {
      var subtitleX = x
      if let size = subtitleIcon.image?.size, !subtitleIcon.isHidden {
        subtitleIcon.frame = CGRect(x: x, y: titleY + 32 - size.height / 2,
                                    width: size.width, height: size.height)
        subtitleX += size.width + 4
      }
      subtitleLabel.frame = CGRect(x: subtitleX, y: titleY + 22,
                                   width: max(0, textRight - subtitleX), height: 20)
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    avatarUrl = ""
  }
}
