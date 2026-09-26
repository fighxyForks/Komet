import Flutter
import UIKit

final class KometSettingsListPlatformView: NSObject, FlutterPlatformView,
  UICollectionViewDataSource, UICollectionViewDelegate {
  private let channel: FlutterMethodChannel
  private let root = UIView()
  private let collection: UICollectionView
  private let searchWrap = UIVisualEffectView()
  private let searchField = UITextField()
  private let closeButton = UIButton(type: .system)
  private let titleLabel = UILabel()
  private var sections: [SettingsBlock] = []
  private var all: [SettingsBlock] = []
  private var profileName = ""
  private var profileDetail = ""
  private var avatarURL = ""
  private var avatarTask: URLSessionDataTask?
  private var query = ""

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
    collection.contentInset.bottom = 88
    collection.register(SettingsProfileCell.self, forCellWithReuseIdentifier: "profile")
    collection.register(SettingsRowCell.self, forCellWithReuseIdentifier: "row")
    collection.register(SettingsEmptyCell.self, forCellWithReuseIdentifier: "empty")
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
    searchField.placeholder = "Поиск по настройкам"
    searchField.font = .preferredFont(forTextStyle: .body)
    searchField.adjustsFontForContentSizeCategory = true
    searchField.clearButtonMode = .whileEditing
    searchField.autocorrectionType = .no
    searchField.returnKeyType = .search
    searchField.addTarget(self, action: #selector(queryChanged), for: .editingChanged)
    let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    icon.tintColor = .secondaryLabel
    icon.contentMode = .scaleAspectFit
    searchField.leftView = icon
    searchField.leftViewMode = .always
    searchField.accessibilityLabel = "Поиск по настройкам"
    styleGlass(searchWrap, radius: 22)
    for view in [collection, closeButton, titleLabel, searchWrap] {
      view.translatesAutoresizingMaskIntoConstraints = false
      root.addSubview(view)
    }
    searchField.translatesAutoresizingMaskIntoConstraints = false
    searchWrap.contentView.addSubview(searchField)
    NSLayoutConstraint.activate([
      closeButton.leadingAnchor.constraint(equalTo: root.safeAreaLayoutGuide.leadingAnchor, constant: 16),
      closeButton.topAnchor.constraint(equalTo: root.safeAreaLayoutGuide.topAnchor, constant: 8),
      closeButton.widthAnchor.constraint(equalToConstant: 44),
      closeButton.heightAnchor.constraint(equalToConstant: 44),
      titleLabel.centerXAnchor.constraint(equalTo: root.centerXAnchor),
      titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
      titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor, constant: 8),
      collection.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8),
      collection.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      collection.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      collection.bottomAnchor.constraint(equalTo: root.bottomAnchor),
      searchWrap.leadingAnchor.constraint(equalTo: root.safeAreaLayoutGuide.leadingAnchor, constant: 20),
      searchWrap.trailingAnchor.constraint(equalTo: root.safeAreaLayoutGuide.trailingAnchor, constant: -20),
      searchWrap.bottomAnchor.constraint(equalTo: root.safeAreaLayoutGuide.bottomAnchor, constant: -12),
      searchWrap.heightAnchor.constraint(equalToConstant: 44),
      searchField.leadingAnchor.constraint(equalTo: searchWrap.leadingAnchor, constant: 12),
      searchField.trailingAnchor.constraint(equalTo: searchWrap.trailingAnchor, constant: -12),
      searchField.topAnchor.constraint(equalTo: searchWrap.topAnchor),
      searchField.bottomAnchor.constraint(equalTo: searchWrap.bottomAnchor),
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
    let header = map?["header"] as? [String: Any] ?? [:]
    profileName = header["name"] as? String ?? ""
    profileDetail = header["detail"] as? String ?? ""
    avatarURL = header["avatarUrl"] as? String ?? ""
    all = (map?["sections"] as? [[String: Any]] ?? []).compactMap(SettingsBlock.init(map:))
    reloadVisible()
  }

  private func reloadVisible() {
    let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if needle.isEmpty {
      sections = all
    } else {
      var hits: [SettingsRow] = []
      for block in all where block.kind == .rows {
        for row in block.rows where row.matches(needle) {
          hits.append(row)
        }
      }
      sections = hits.isEmpty
        ? [SettingsBlock(kind: .empty, header: "", rows: [])]
        : [SettingsBlock(kind: .rows, header: "", rows: hits)]
    }
    collection.setCollectionViewLayout(makeLayout(headers: needle.isEmpty), animated: false)
    collection.reloadData()
  }

  private func makeLayout(headers: Bool) -> UICollectionViewLayout {
    let layout = UICollectionViewCompositionalLayout { _, _ in
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
      section.decorationItems = [card]
      if headers {
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
    (query.isEmpty ? 1 : 0) + sections.count
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if query.isEmpty && section == 0 { return 1 }
    let block = sections[section - (query.isEmpty ? 1 : 0)]
    return block.kind == .empty ? 1 : block.rows.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if query.isEmpty && indexPath.section == 0 {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "profile", for: indexPath) as! SettingsProfileCell
      cell.apply(name: profileName, detail: profileDetail, url: avatarURL, task: &avatarTask)
      return cell
    }
    let block = sections[indexPath.section - (query.isEmpty ? 1 : 0)]
    if block.kind == .empty {
      return collectionView.dequeueReusableCell(withReuseIdentifier: "empty", for: indexPath)
    }
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "row", for: indexPath) as! SettingsRowCell
    let row = block.rows[indexPath.item]
    cell.apply(
      row: row,
      showsSection: !query.isEmpty,
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
    if query.isEmpty && indexPath.section == 0 {
      header.text = ""
    } else {
      let block = sections[indexPath.section - (query.isEmpty ? 1 : 0)]
      header.text = block.header
    }
    return header
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    if query.isEmpty && indexPath.section == 0 {
      channel.invokeMethod("header", arguments: ["action": "profile"])
      return
    }
    let block = sections[indexPath.section - (query.isEmpty ? 1 : 0)]
    guard block.kind == .rows else { return }
    let row = block.rows[indexPath.item]
    if row.switchValue != nil || !row.enabled { return }
    channel.invokeMethod("tap", arguments: ["id": row.id])
  }

  @objc private func closeTapped() {
    channel.invokeMethod("header", arguments: ["action": "close"])
  }

  @objc private func queryChanged() {
    query = searchField.text ?? ""
    reloadVisible()
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

private enum SettingsKind { case rows, empty }

private struct SettingsRow {
  let id: String
  let title: String
  let symbol: String
  let section: String
  let trailing: String
  let keywords: String
  let destructive: Bool
  let enabled: Bool
  let switchValue: Bool?

  func matches(_ needle: String) -> Bool {
    let hay = "\(title) \(section) \(keywords)".lowercased()
    return hay.contains(needle)
  }
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
      let words = (row["keywords"] as? [String])?.joined(separator: " ") ?? ""
      return SettingsRow(
        id: row["id"] as? String ?? "",
        title: row["title"] as? String ?? "",
        symbol: row["symbol"] as? String ?? "circle",
        section: map["header"] as? String ?? "",
        trailing: row["trailing"] as? String ?? "",
        keywords: words,
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
  private let detail = UILabel()
  private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

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
    chevron.tintColor = .tertiaryLabel
    let text = UIStackView(arrangedSubviews: [name, detail])
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
      row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
    ])
    accessibilityTraits = .button
  }
  required init?(coder: NSCoder) { nil }

  func apply(name: String, detail: String, url: String, task: inout URLSessionDataTask?) {
    self.name.text = name
    self.detail.text = detail
    self.detail.isHidden = detail.isEmpty
    accessibilityLabel = detail.isEmpty ? name : "\(name), \(detail)"
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
    icon.image = UIImage(systemName: row.symbol)
    title.text = row.title
    title.textColor = row.destructive ? .systemRed : (row.enabled ? .label : .secondaryLabel)
    icon.tintColor = row.destructive ? .systemRed : .label
    section.text = row.section
    section.isHidden = !showsSection || row.section.isEmpty
    trailing.text = row.trailing
    trailing.isHidden = row.trailing.isEmpty || row.switchValue != nil
    chevron.isHidden = row.destructive || row.switchValue != nil
    toggle.isHidden = row.switchValue == nil
    if let value = row.switchValue { toggle.isOn = value }
    separator.isHidden = isLast
    accessibilityLabel = showsSection && !row.section.isEmpty
      ? "\(row.title), \(row.section)"
      : row.title
    accessibilityTraits = row.switchValue == nil ? .button : .none
  }

  @objc private func toggled() {
    onToggle?(toggle.isOn)
  }
}

private final class SettingsEmptyCell: UICollectionViewCell {
  private let label = UILabel()
  override init(frame: CGRect) {
    super.init(frame: frame)
    label.text = "Ничего не найдено"
    label.font = .preferredFont(forTextStyle: .body)
    label.adjustsFontForContentSizeCategory = true
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
      label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
    ])
  }
  required init?(coder: NSCoder) { nil }
}
