import Flutter
import UIKit

final class KometSettingsListPlatformView: NSObject, FlutterPlatformView,
  UICollectionViewDataSource, UICollectionViewDelegate {
  private let channel: FlutterMethodChannel
  private let root = UIView()
  private let collection: UICollectionView
  private var showsClose = false
  private var tabInset: CGFloat = 0
  private var titleTop: NSLayoutConstraint?
  private var collectionBelowClose: NSLayoutConstraint?
  private var collectionBelowTitle: NSLayoutConstraint?
  private let closeButton = UIButton(type: .system)
  private let titleLabel = UILabel()
  private var sections: [SettingsBlock] = []
  private var all: [SettingsBlock] = []
  private var profileName = ""
  private var profileDetail = ""
  private var profileStatus = ""
  private var profileOnline = false
  private var maskPhone = false
  private var avatarURL = ""
  private var avatarTask: URLSessionDataTask?
  private var appliedFingerprint: Int?
  private var sectionShape: [Int] = []
  private var sectionHeaders: [String] = []
  static var debugReloads = 0

  init(frame: CGRect, viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "ru.komet.app/native_settings/\(viewId)", binaryMessenger: messenger)
    collection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    super.init()
    root.frame = frame
    collection.collectionViewLayout = makeLayout(headers: true)
    collection.backgroundColor = .clear
    collection.dataSource = self
    collection.delegate = self
    collection.keyboardDismissMode = .onDrag
    collection.contentInsetAdjustmentBehavior = .never
    collection.register(SettingsProfileCell.self, forCellWithReuseIdentifier: "profile")
    collection.register(SettingsRowCell.self, forCellWithReuseIdentifier: "row")
    collection.register(
      SettingsHeader.self,
      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
      withReuseIdentifier: "header")
    collection.register(
      SettingsCardBackground.self,
      forSupplementaryViewOfKind: "card",
      withReuseIdentifier: "card")
    titleLabel.text = "Настройки"
    titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.textAlignment = .center
    titleLabel.accessibilityTraits = .header
    closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
    closeButton.tintColor = .label
    closeButton.accessibilityLabel = "Закрыть"
    closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    styleGlass(closeButton, radius: 22)
    for view in [collection, closeButton, titleLabel] {
      view.translatesAutoresizingMaskIntoConstraints = false
      root.addSubview(view)
    }
    titleTop = titleLabel.topAnchor.constraint(equalTo: root.safeAreaLayoutGuide.topAnchor, constant: 12)
    collectionBelowClose = collection.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8)
    collectionBelowTitle = collection.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8)
    NSLayoutConstraint.activate([
      closeButton.leadingAnchor.constraint(equalTo: root.safeAreaLayoutGuide.leadingAnchor, constant: 16),
      closeButton.topAnchor.constraint(equalTo: root.safeAreaLayoutGuide.topAnchor, constant: 8),
      closeButton.widthAnchor.constraint(equalToConstant: 44),
      closeButton.heightAnchor.constraint(equalToConstant: 44),
      titleLabel.centerXAnchor.constraint(equalTo: root.centerXAnchor),
      titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
      titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor, constant: 8),
      collectionBelowClose!,
      collection.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      collection.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      collection.bottomAnchor.constraint(equalTo: root.bottomAnchor),
    ])
    root.backgroundColor = UIColor { traits in
      traits.userInterfaceStyle == .dark ? .black : .systemGroupedBackground
    }
    apply(arguments as? [String: Any])
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "apply" {
        self?.apply(call.arguments as? [String: Any])
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  deinit { channel.setMethodCallHandler(nil) }
  func view() -> UIView { root }

  private func apply(_ map: [String: Any]?) {
    let fingerprint = SettingsFingerprint.of(map)
    if fingerprint == appliedFingerprint { return }
    let header = map?["header"] as? [String: Any] ?? [:]
    let nextBlocks = (map?["sections"] as? [[String: Any]] ?? []).compactMap(SettingsBlock.init(map:))
    let nextShape = nextBlocks.map { $0.rows.count }
    let nextHeaders = nextBlocks.map(\.header)
    let structureChanged = nextShape != sectionShape || nextHeaders != sectionHeaders
    let rowsChanged = structureChanged || nextBlocks.map(\.rows) != all.map(\.rows)
    profileName = header["name"] as? String ?? ""
    profileDetail = header["detail"] as? String ?? ""
    profileStatus = header["status"] as? String ?? ""
    profileOnline = (header["online"] as? NSNumber)?.boolValue ?? false
    maskPhone = (header["maskPhone"] as? NSNumber)?.boolValue ?? false
    avatarURL = header["avatarUrl"] as? String ?? ""
    let layout = map?["layout"] as? String ?? "profile"
    showsClose = (header["showClose"] as? NSNumber)?.boolValue ?? (layout != "settings")
    tabInset = CGFloat((header["bottomInset"] as? NSNumber)?.doubleValue ?? 0)
    if let background = (header["background"] as? NSNumber)?.uint32Value {
      root.backgroundColor = UIColor(argb: background)
    }
    applyChrome()
    all = nextBlocks
    sections = all
    sectionShape = nextShape
    sectionHeaders = nextHeaders
    appliedFingerprint = fingerprint
    if rowsChanged {
      if structureChanged {
        collection.setCollectionViewLayout(makeLayout(headers: true), animated: false)
      }
      KometSettingsListPlatformView.debugReloads += 1
      collection.reloadData()
    } else if collection.numberOfSections > 0 {
      collection.reloadSections(IndexSet(integer: 0))
    }
  }

  private func applyChrome() {
    closeButton.isHidden = !showsClose
    titleTop?.isActive = !showsClose
    collectionBelowClose?.isActive = showsClose
    collectionBelowTitle?.isActive = !showsClose
    collection.contentInset.bottom = tabInset
    collection.verticalScrollIndicatorInsets.bottom = tabInset
  }

  private func isVersionSection(_ index: Int) -> Bool {
    guard index > 0 else { return false }
    let blockIndex = index - 1
    guard sections.indices.contains(blockIndex) else { return false }
    return sections[blockIndex].rows.count == 1 && sections[blockIndex].rows[0].id == "version"
  }

  private func showsHeader(at index: Int, headers: Bool) -> Bool {
    guard headers else { return false }
    if index == 0 { return false }
    let blockIndex = index - 1
    guard sections.indices.contains(blockIndex) else { return false }
    return !sections[blockIndex].header.isEmpty
  }

  private func makeLayout(headers: Bool) -> UICollectionViewLayout {
    let layout = UICollectionViewCompositionalLayout { [weak self] index, _ in
      let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1), heightDimension: .estimated(60)))
      let group = NSCollectionLayoutGroup.vertical(
        layoutSize: NSCollectionLayoutSize(
          widthDimension: .fractionalWidth(1), heightDimension: .estimated(60)),
        subitems: [item])
      let section = NSCollectionLayoutSection(group: group)
      section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 18, trailing: 20)
      let card = NSCollectionLayoutDecorationItem.background(elementKind: "card")
      card.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 18, trailing: 20)
      if self?.isVersionSection(index) != true {
        section.decorationItems = [card]
      }
      if self?.showsHeader(at: index, headers: headers) == true {
        let header = NSCollectionLayoutBoundarySupplementaryItem(
          layoutSize: NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1), heightDimension: .estimated(32)),
          elementKind: UICollectionView.elementKindSectionHeader,
          alignment: .top)
        section.boundarySupplementaryItems = [header]
      }
      return section
    }
    layout.register(SettingsCardBackground.self, forDecorationViewOfKind: "card")
    return layout
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    1 + sections.count
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if section == 0 { return 1 }
    let block = sections[section - 1]
    return block.rows.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if indexPath.section == 0 {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "profile", for: indexPath) as! SettingsProfileCell
      cell.onReveal = { [weak self] in
        self?.channel.invokeMethod("header", arguments: ["action": "revealPhone"])
      }
      cell.apply(
        name: profileName,
        detail: profileDetail,
        status: profileStatus,
        online: profileOnline,
        maskPhone: maskPhone,
        url: avatarURL,
        task: &avatarTask)
      return cell
    }
    let block = sections[indexPath.section - 1]
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "row", for: indexPath) as! SettingsRowCell
    let row = block.rows[indexPath.item]
    cell.apply(
      row: row,
      showsSection: false,
      isLast: indexPath.item == block.rows.count - 1,
      onToggle: { [weak self] value in
        self?.channel.invokeMethod("toggle", arguments: ["id": row.id, "value": value])
      })
    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView,
    viewForSupplementaryElementOfKind kind: String,
    at indexPath: IndexPath
  ) -> UICollectionReusableView {
    let header = collectionView.dequeueReusableSupplementaryView(
      ofKind: kind, withReuseIdentifier: "header", for: indexPath) as! SettingsHeader
    if indexPath.section == 0 {
      header.text = ""
    } else {
      let block = sections[indexPath.section - 1]
      header.text = block.header
    }
    return header
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    if indexPath.section == 0 {
      channel.invokeMethod("header", arguments: ["action": "profile"])
      return
    }
    let block = sections[indexPath.section - 1]
    guard block.kind == .rows else { return }
    let row = block.rows[indexPath.item]
    if row.switchValue != nil || !row.enabled { return }
    channel.invokeMethod("tap", arguments: ["id": row.id])
  }

  @objc private func closeTapped() {
    channel.invokeMethod("header", arguments: ["action": "close"])
  }

  private func styleGlass(_ view: UIView, radius: CGFloat) {
    view.layer.cornerRadius = radius
    view.layer.cornerCurve = .continuous
    view.clipsToBounds = true
    if #available(iOS 26.0, *), let effectView = view as? UIVisualEffectView {
      effectView.effect = UIGlassEffect(style: .regular)
    } else if let effectView = view as? UIVisualEffectView {
      effectView.effect = UIBlurEffect(style: .systemChromeMaterial)
    } else {
      view.backgroundColor = .secondarySystemFill
    }
  }
}

private enum SettingsKind { case rows }

private struct SettingsRow: Equatable {
  let id: String
  let title: String
  let symbol: String
  let section: String
  let trailing: String
  let destructive: Bool
  let enabled: Bool
  let switchValue: Bool?
}

private struct SettingsBlock {
  let kind: SettingsKind
  let header: String
  let rows: [SettingsRow]

  init(kind: SettingsKind, header: String, rows: [SettingsRow]) {
    self.kind = kind
    self.header = header
    self.rows = rows
  }

  init?(map: [String: Any]) {
    let rows = (map["rows"] as? [[String: Any]] ?? []).map { row -> SettingsRow in
      SettingsRow(
        id: row["id"] as? String ?? "",
        title: row["title"] as? String ?? "",
        symbol: row["symbol"] as? String ?? "circle",
        section: map["header"] as? String ?? "",
        trailing: row["trailing"] as? String ?? "",
        destructive: (row["destructive"] as? NSNumber)?.boolValue ?? false,
        enabled: (row["enabled"] as? NSNumber)?.boolValue ?? true,
        switchValue: (row["switchValue"] as? NSNumber)?.boolValue)
    }
    kind = .rows
    header = map["header"] as? String ?? ""
    self.rows = rows
  }
}

private final class SettingsCardBackground: UICollectionReusableView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .secondarySystemGroupedBackground
    layer.cornerRadius = 26
    layer.cornerCurve = .continuous
  }
  required init?(coder: NSCoder) { nil }
}

private final class SettingsHeader: UICollectionReusableView {
  private let label = UILabel()
  var text: String = "" {
    didSet {
      label.text = text
      isHidden = text.isEmpty
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    label.font = .systemFont(ofSize: 15, weight: .regular)
    label.adjustsFontForContentSizeCategory = true
    label.textColor = .secondaryLabel
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 36),
      label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
      label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
      label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
    ])
  }
  required init?(coder: NSCoder) { nil }
}

private final class SettingsProfileCell: UICollectionViewCell {
  private let avatar = UIImageView()
  private let name = UILabel()
  private let status = UILabel()
  private let detail = UILabel()
  private let eye = UIButton(type: .system)
  private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
  var onReveal: (() -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    avatar.layer.cornerRadius = 28
    avatar.clipsToBounds = true
    avatar.backgroundColor = .tertiarySystemFill
    name.font = .systemFont(ofSize: 17, weight: .semibold)
    name.adjustsFontForContentSizeCategory = true
    name.numberOfLines = 2
    detail.font = .preferredFont(forTextStyle: .subheadline)
    detail.adjustsFontForContentSizeCategory = true
    detail.textColor = .secondaryLabel
    detail.numberOfLines = 2
    status.font = .preferredFont(forTextStyle: .subheadline)
    status.adjustsFontForContentSizeCategory = true
    status.numberOfLines = 1
    eye.addTarget(self, action: #selector(revealPhone), for: .touchUpInside)
    eye.accessibilityLabel = "Показать номер"
    chevron.tintColor = .tertiaryLabel
    chevron.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
    chevron.contentMode = .scaleAspectFit
    chevron.setContentHuggingPriority(.required, for: .horizontal)
    chevron.setContentCompressionResistancePriority(.required, for: .horizontal)
    let phoneRow = UIStackView(arrangedSubviews: [detail, eye])
    phoneRow.axis = .horizontal
    phoneRow.alignment = .center
    phoneRow.spacing = 4
    let text = UIStackView(arrangedSubviews: [name, status, phoneRow])
    text.axis = .vertical
    text.spacing = 2
    let row = UIStackView(arrangedSubviews: [avatar, text, chevron])
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 12
    row.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(row)
    NSLayoutConstraint.activate([
      avatar.widthAnchor.constraint(equalToConstant: 56),
      avatar.heightAnchor.constraint(equalToConstant: 56),
      chevron.widthAnchor.constraint(equalToConstant: 13),
      chevron.heightAnchor.constraint(equalToConstant: 18),
      eye.widthAnchor.constraint(equalToConstant: 44),
      eye.heightAnchor.constraint(equalToConstant: 44),
      row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
    ])
    accessibilityTraits = .button
  }
  required init?(coder: NSCoder) { nil }

  @objc private func revealPhone() { onReveal?() }

  func apply(
    name: String,
    detail: String,
    status: String,
    online: Bool,
    maskPhone: Bool,
    url: String,
    task: inout URLSessionDataTask?
  ) {
    self.name.text = name
    self.status.text = status
    self.status.isHidden = status.isEmpty
    self.status.textColor = online ? UIColor.systemGreen : .secondaryLabel
    let shown = maskPhone && !detail.isEmpty ? String(repeating: "•", count: detail.count) : detail
    self.detail.text = shown
    self.detail.isHidden = detail.isEmpty
    eye.isHidden = detail.isEmpty
    let symbol = maskPhone ? "eye" : "eye.slash"
    eye.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)), for: .normal)
    eye.tintColor = .secondaryLabel
    accessibilityLabel = [name, status, maskPhone ? "номер скрыт" : detail]
      .filter { !$0.isEmpty }
      .joined(separator: ", ")
    task?.cancel()
    if url.hasPrefix("http"), let imageURL = URL(string: url) {
      task = URLSession.shared.dataTask(with: imageURL) { [weak self] data, _, _ in
        guard let data, let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { self?.avatar.image = image }
      }
      task?.resume()
    } else {
      avatar.image = UIImage(systemName: "person.crop.circle.fill")
      avatar.tintColor = .secondaryLabel
    }
  }
}

private final class SettingsRowCell: UICollectionViewCell {
  private let icon = UIImageView()
  private let title = UILabel()
  private let section = UILabel()
  private let trailing = UILabel()
  private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
  private let separator = UIView()
  private let toggle = UISwitch()
  private var onToggle: ((Bool) -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    icon.tintColor = .label
    icon.contentMode = .scaleAspectFit
    icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
    title.font = .preferredFont(forTextStyle: .body)
    title.adjustsFontForContentSizeCategory = true
    title.numberOfLines = 0
    section.font = .preferredFont(forTextStyle: .subheadline)
    section.adjustsFontForContentSizeCategory = true
    section.textColor = .secondaryLabel
    section.numberOfLines = 0
    trailing.font = .preferredFont(forTextStyle: .body)
    trailing.adjustsFontForContentSizeCategory = true
    trailing.textColor = .secondaryLabel
    chevron.tintColor = .tertiaryLabel
    chevron.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
    chevron.contentMode = .scaleAspectFit
    chevron.setContentHuggingPriority(.required, for: .horizontal)
    chevron.setContentCompressionResistancePriority(.required, for: .horizontal)
    trailing.setContentHuggingPriority(.required, for: .horizontal)
    trailing.setContentCompressionResistancePriority(.required, for: .horizontal)
    separator.backgroundColor = .separator
    toggle.addTarget(self, action: #selector(toggled), for: .valueChanged)
    let text = UIStackView(arrangedSubviews: [title, section])
    text.axis = .vertical
    text.spacing = 2
    let row = UIStackView(arrangedSubviews: [icon, text, trailing, toggle, chevron])
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 16
    row.translatesAutoresizingMaskIntoConstraints = false
    separator.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(row)
    contentView.addSubview(separator)
    NSLayoutConstraint.activate([
      icon.widthAnchor.constraint(equalToConstant: 22),
      icon.heightAnchor.constraint(equalToConstant: 22),
      chevron.widthAnchor.constraint(equalToConstant: 13),
      chevron.heightAnchor.constraint(equalToConstant: 18),
      row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
      separator.leadingAnchor.constraint(equalTo: title.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
    ])
  }
  required init?(coder: NSCoder) { nil }

  func apply(row: SettingsRow, showsSection: Bool, isLast: Bool, onToggle: @escaping (Bool) -> Void) {
    self.onToggle = onToggle
    let version = row.id == "version"
    icon.image = version ? nil : UIImage(systemName: row.symbol)
    icon.isHidden = version
    title.text = row.title
    title.textAlignment = version ? .center : .natural
    title.font = version
      ? .systemFont(ofSize: 13, weight: .regular)
      : .preferredFont(forTextStyle: .body)
    title.textColor = version
      ? .secondaryLabel
      : (row.destructive ? .systemRed : (row.enabled ? .label : .secondaryLabel))
    icon.tintColor = row.destructive ? .systemRed : .label
    section.text = row.section
    section.isHidden = !showsSection || row.section.isEmpty
    trailing.text = row.trailing
    trailing.isHidden = row.trailing.isEmpty || row.switchValue != nil
    chevron.isHidden = version || row.destructive || row.switchValue != nil
    toggle.isHidden = row.switchValue == nil
    if let value = row.switchValue { toggle.isOn = value }
    separator.isHidden = version || isLast
    accessibilityLabel = showsSection && !row.section.isEmpty
      ? "\(row.title), \(row.section)"
      : row.title
    accessibilityTraits = row.switchValue == nil ? .button : .none
  }

  @objc private func toggled() {
    onToggle?(toggle.isOn)
  }
}

enum SettingsFingerprint {
  static func of(_ map: [String: Any]?) -> Int {
    var hasher = Hasher()
    hash(map, into: &hasher)
    return hasher.finalize()
  }

  private static func hash(_ value: Any?, into hasher: inout Hasher) {
    switch value {
    case let map as [String: Any]:
      for key in map.keys.sorted() {
        hasher.combine(key)
        hash(map[key], into: &hasher)
      }
    case let list as [Any]:
      hasher.combine(list.count)
      for item in list { hash(item, into: &hasher) }
    case let number as NSNumber:
      hasher.combine(number.stringValue)
    case let text as String:
      hasher.combine(text)
    default:
      hasher.combine(0)
    }
  }
}
