import UIKit

struct KometStoryItem: Equatable {
  let ownerId: Int
  let title: String
  let avatarUrl: String
  let total: Int
  let read: Int
  let isSelf: Bool

  init?(_ map: [String: Any]) {
    guard let ownerId = (map["ownerId"] as? NSNumber)?.intValue else { return nil }
    self.ownerId = ownerId
    title = map["title"] as? String ?? ""
    avatarUrl = map["avatarUrl"] as? String ?? ""
    total = (map["total"] as? NSNumber)?.intValue ?? 0
    read = (map["read"] as? NSNumber)?.intValue ?? 0
    isSelf = (map["self"] as? NSNumber)?.boolValue ?? false
  }
}

struct KometFolderItem: Equatable {
  let id: String
  let title: String

  init?(_ map: [String: Any]) {
    guard let id = map["id"] as? String else { return nil }
    self.id = id
    title = map["title"] as? String ?? ""
  }
}

final class KometChatListHeader: UIView, UICollectionViewDataSource, UICollectionViewDelegate,
  UISearchBarDelegate {
  static let storiesHeight: CGFloat = 100
  static let searchHeight: CGFloat = 52
  static let foldersHeight: CGFloat = 46
  private static let folderCapsuleHeight: CGFloat = 36
  private static let folderInset: CGFloat = 3
  private static let folderChipPadding: CGFloat = 14
  private static let folderFont = UIFont.systemFont(ofSize: 15, weight: .medium)
  private static let folderSelectedFont = UIFont.systemFont(ofSize: 15, weight: .semibold)

  var onStory: ((KometStoryItem, CGRect) -> Void)?
  var onAddStory: (() -> Void)?
  var onQuery: ((String) -> Void)?
  var onFolder: ((String) -> Void)?
  var onFolderMenu: ((String, CGRect) -> Void)?

  private let folderSegments = UISegmentedControl()
  private let folderCapsule = UIView()
  private let folderScroll = UIScrollView()
  private let folderThumb = UIView()
  private var folderButtons: [UIButton] = []
  private var folders: [KometFolderItem] = []
  private var selectedFolder: String?
  private var usesSegments = true

  let searchBar = UISearchBar()
  private let storiesLayout: UICollectionViewFlowLayout = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.itemSize = CGSize(width: 74, height: KometChatListHeader.storiesHeight)
    layout.minimumLineSpacing = 4
    layout.sectionInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    return layout
  }()
  private lazy var storiesView = UICollectionView(frame: .zero, collectionViewLayout: storiesLayout)
  private var items: [KometStoryItem] = []
  private(set) var showsStories = false
  var storiesCollapsed = false
  var hasStories: Bool { !items.isEmpty }
  var accent: UIColor = .systemBlue {
    didSet { storiesView.reloadData() }
  }

  var showsFolders: Bool { folders.count > 1 }

  var preferredHeight: CGFloat {
    storyBand + KometChatListHeader.searchHeight
      + (showsFolders ? KometChatListHeader.foldersHeight : 0)
  }

  private var storyBand: CGFloat {
    showsStories && !storiesCollapsed ? KometChatListHeader.storiesHeight : 0
  }

  func setStoriesCollapsed(_ collapsed: Bool) {
    guard collapsed != storiesCollapsed else { return }
    storiesCollapsed = collapsed
    storiesView.isHidden = collapsed || !showsStories
    setNeedsLayout()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    storiesView.backgroundColor = .clear
    storiesView.showsHorizontalScrollIndicator = false
    storiesView.alwaysBounceHorizontal = true
    storiesView.dataSource = self
    storiesView.delegate = self
    storiesView.register(KometStoryCell.self, forCellWithReuseIdentifier: KometStoryCell.reuseIdentifier)
    storiesView.isHidden = true
    addSubview(storiesView)

    searchBar.searchBarStyle = .minimal
    searchBar.delegate = self
    searchBar.autocapitalizationType = .none
    addSubview(searchBar)

    folderSegments.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    folderSegments.addGestureRecognizer(
      UILongPressGestureRecognizer(target: self, action: #selector(segmentLongPress(_:))))
    folderCapsule.backgroundColor = .tertiarySystemFill
    folderCapsule.layer.cornerRadius = KometChatListHeader.folderCapsuleHeight / 2
    folderCapsule.clipsToBounds = true
    folderScroll.showsHorizontalScrollIndicator = false
    folderScroll.alwaysBounceHorizontal = true
    folderThumb.backgroundColor = .systemBackground
    folderThumb.layer.cornerRadius =
      (KometChatListHeader.folderCapsuleHeight - KometChatListHeader.folderInset * 2) / 2
    folderThumb.layer.shadowColor = UIColor.black.cgColor
    folderThumb.layer.shadowOpacity = 0.08
    folderThumb.layer.shadowRadius = 4
    folderThumb.layer.shadowOffset = CGSize(width: 0, height: 1)
    folderScroll.addSubview(folderThumb)
    folderCapsule.addSubview(folderScroll)
    [folderSegments, folderCapsule].forEach {
      $0.isHidden = true
      addSubview($0)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let storiesHeight = storyBand
    storiesView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: storiesHeight)
    searchBar.frame = CGRect(x: 8, y: storiesHeight, width: bounds.width - 16,
                             height: KometChatListHeader.searchHeight)
    layoutFolders(top: storiesHeight + KometChatListHeader.searchHeight)
  }

  func setStories(_ next: [KometStoryItem], visible: Bool) {
    let visibilityChanged = visible != showsStories
    showsStories = visible
    storiesView.isHidden = !visible
    if next != items {
      items = next
      storiesView.reloadData()
    }
    if visibilityChanged { setNeedsLayout() }
  }

  func setFolders(_ next: [KometFolderItem], selected: String?) {
    let changed = next != folders
    folders = next
    selectedFolder = selected
    if changed {
      rebuildFolders()
      setNeedsLayout()
    } else {
      applyFolderSelection(animated: true)
    }
  }

  private func rebuildFolders() {
    folderSegments.removeAllSegments()
    for (index, folder) in folders.enumerated() {
      folderSegments.insertSegment(withTitle: folder.title, at: index, animated: false)
    }
    folderButtons.forEach { $0.removeFromSuperview() }
    folderButtons = folders.enumerated().map { index, folder in
      let button = UIButton(type: .custom)
      button.tag = index
      button.setTitle(folder.title, for: .normal)
      button.titleLabel?.lineBreakMode = .byTruncatingTail
      button.addTarget(self, action: #selector(folderTapped(_:)), for: .touchUpInside)
      button.addGestureRecognizer(
        UILongPressGestureRecognizer(target: self, action: #selector(folderLongPress(_:))))
      folderScroll.addSubview(button)
      return button
    }
    applyFolderSelection(animated: false)
  }

  private func naturalFolderWidths() -> [CGFloat] {
    folders.map {
      let width = ($0.title as NSString).size(
        withAttributes: [.font: KometChatListHeader.folderSelectedFont]).width
      return ceil(width) + KometChatListHeader.folderChipPadding * 2
    }
  }

  private func layoutFolders(top: CGFloat) {
    guard showsFolders else {
      folderSegments.isHidden = true
      folderCapsule.isHidden = true
      return
    }
    let height = KometChatListHeader.folderCapsuleHeight
    let frame = CGRect(x: 16, y: top + (KometChatListHeader.foldersHeight - height) / 2 - 2,
                       width: bounds.width - 32, height: height)
    let widths = naturalFolderWidths()
    let inset = KometChatListHeader.folderInset
    usesSegments = widths.reduce(0, +) <= frame.width - inset * 2
    folderSegments.isHidden = !usesSegments
    folderCapsule.isHidden = usesSegments
    if usesSegments {
      folderSegments.frame = frame
      return
    }
    folderCapsule.frame = frame
    folderScroll.frame = folderCapsule.bounds
    var x = inset
    for (index, button) in folderButtons.enumerated() {
      let width = index < widths.count ? widths[index] : 0
      button.frame = CGRect(x: x, y: inset, width: width, height: height - inset * 2)
      x += width
    }
    folderScroll.contentSize = CGSize(width: x + inset, height: height)
    applyFolderSelection(animated: false)
  }

  private var selectedFolderIndex: Int? {
    folders.firstIndex { $0.id == selectedFolder }
  }

  private func applyFolderSelection(animated: Bool) {
    let index = selectedFolderIndex
    folderSegments.selectedSegmentIndex = index ?? UISegmentedControl.noSegment
    for (position, button) in folderButtons.enumerated() {
      let selected = position == index
      button.titleLabel?.font = selected
        ? KometChatListHeader.folderSelectedFont : KometChatListHeader.folderFont
      button.setTitleColor(selected ? .label : .secondaryLabel, for: .normal)
    }
    guard let index = index, index < folderButtons.count, !usesSegments else {
      folderThumb.isHidden = true
      return
    }
    let target = folderButtons[index].frame
    folderThumb.isHidden = target.isEmpty
    let move = {
      self.folderThumb.frame = target
      let visible = target.insetBy(dx: -24, dy: 0)
      self.folderScroll.scrollRectToVisible(visible, animated: false)
    }
    if animated, window != nil {
      UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.85,
                     initialSpringVelocity: 0, options: [.beginFromCurrentState], animations: move)
    } else {
      move()
    }
  }

  private func selectFolder(at index: Int) {
    guard index >= 0, index < folders.count else { return }
    UISelectionFeedbackGenerator().selectionChanged()
    selectedFolder = folders[index].id
    applyFolderSelection(animated: true)
    onFolder?(folders[index].id)
  }

  @objc private func segmentChanged() {
    selectFolder(at: folderSegments.selectedSegmentIndex)
  }

  @objc private func folderTapped(_ sender: UIButton) {
    selectFolder(at: sender.tag)
  }

  @objc private func segmentLongPress(_ gesture: UILongPressGestureRecognizer) {
    guard gesture.state == .began, !folders.isEmpty else { return }
    let width = folderSegments.bounds.width / CGFloat(folders.count)
    let index = min(max(Int(gesture.location(in: folderSegments).x / width), 0), folders.count - 1)
    let rect = CGRect(x: CGFloat(index) * width, y: 0, width: width,
                      height: folderSegments.bounds.height)
    openFolderMenu(at: index, rect: folderSegments.convert(rect, to: nil))
  }

  @objc private func folderLongPress(_ gesture: UILongPressGestureRecognizer) {
    guard gesture.state == .began, let button = gesture.view as? UIButton else { return }
    openFolderMenu(at: button.tag, rect: button.convert(button.bounds, to: nil))
  }

  private func openFolderMenu(at index: Int, rect: CGRect) {
    guard index < folders.count else { return }
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    onFolderMenu?(folders[index].id, rect)
  }

  func setPlaceholder(_ text: String) {
    searchBar.placeholder = text
  }

  func setSearchEnabled(_ enabled: Bool) {
    if !enabled { endSearch() }
    searchBar.isUserInteractionEnabled = enabled
    searchBar.alpha = enabled ? 1 : 0.5
  }

  func endSearch() {
    guard searchBar.isFirstResponder || !(searchBar.text ?? "").isEmpty else { return }
    searchBar.text = ""
    searchBar.setShowsCancelButton(false, animated: true)
    searchBar.resignFirstResponder()
    onQuery?("")
  }

  func collectionView(_ collectionView: UICollectionView,
                      numberOfItemsInSection section: Int) -> Int {
    items.count
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: KometStoryCell.reuseIdentifier, for: indexPath)
    (cell as? KometStoryCell)?.configure(items[indexPath.item], accent: accent)
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    let item = items[indexPath.item]
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    if item.isSelf && item.total <= 0 {
      onAddStory?()
      return
    }
    guard let cell = collectionView.cellForItem(at: indexPath) as? KometStoryCell else { return }
    onStory?(item, cell.avatarFrame(in: nil))
  }

  func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
    searchBar.setShowsCancelButton(true, animated: true)
    return true
  }

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    onQuery?(searchText.trimmingCharacters(in: .whitespacesAndNewlines))
  }

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    endSearch()
  }
}

final class KometStoryCell: UICollectionViewCell {
  static let reuseIdentifier = "KometStoryCell"
  private static let avatarSide: CGFloat = 60

  private let ringView = KometStoryRingView()
  private let avatarView = UIImageView()
  private let plusView = UIImageView()
  private let nameLabel = UILabel()
  private var avatarUrl = ""

  override init(frame: CGRect) {
    super.init(frame: frame)
    avatarView.contentMode = .scaleAspectFill
    plusView.contentMode = .center
    nameLabel.font = .systemFont(ofSize: 12, weight: .regular)
    nameLabel.textColor = .label
    nameLabel.textAlignment = .center
    nameLabel.lineBreakMode = .byTruncatingTail
    [ringView, avatarView, plusView, nameLabel].forEach(contentView.addSubview)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override var isHighlighted: Bool {
    didSet {
      UIView.animate(withDuration: 0.12) {
        self.contentView.transform = self.isHighlighted
          ? CGAffineTransform(scaleX: 0.92, y: 0.92) : .identity
      }
    }
  }

  func avatarFrame(in view: UIView?) -> CGRect {
    avatarView.convert(avatarView.bounds, to: view)
  }

  func configure(_ item: KometStoryItem, accent: UIColor) {
    nameLabel.text = item.title
    ringView.update(total: item.total, read: item.read, accent: accent)
    plusView.isHidden = !item.isSelf
    plusView.image = KometChatListStyle.symbol("plus.circle.fill", size: 20, weight: .semibold)?
      .withTintColor(accent, renderingMode: .alwaysOriginal)
    plusView.backgroundColor = .systemBackground
    let scale = traitCollection.displayScale > 0 ? traitCollection.displayScale : UIScreen.main.scale
    let side = KometStoryCell.avatarSide
    avatarUrl = item.avatarUrl
    if !item.avatarUrl.isEmpty,
       let image = KometAvatarCache.shared.cached(item.avatarUrl, side: side) {
      avatarView.image = image
    } else {
      avatarView.image = KometAvatarCache.shared.letterAvatar(
        seed: item.ownerId, title: item.title, side: side, scale: scale)
      if !item.avatarUrl.isEmpty {
        let requested = item.avatarUrl
        KometAvatarCache.shared.load(requested, side: side, scale: scale) { [weak self] image in
          guard let self = self, self.avatarUrl == requested else { return }
          self.avatarView.image = image
        }
      }
    }
    setNeedsLayout()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let width = contentView.bounds.width
    let side = KometStoryCell.avatarSide
    let ring = side + 10
    ringView.frame = CGRect(x: (width - ring) / 2, y: 8, width: ring, height: ring)
    avatarView.frame = CGRect(x: (width - side) / 2, y: 13, width: side, height: side)
    let plus: CGFloat = 22
    plusView.frame = CGRect(x: avatarView.frame.maxX - plus + 2,
                            y: avatarView.frame.maxY - plus + 2, width: plus, height: plus)
    plusView.layer.cornerRadius = plus / 2
    nameLabel.frame = CGRect(x: 2, y: ringView.frame.maxY + 4, width: width - 4, height: 16)
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    avatarUrl = ""
  }
}

final class KometStoryRingView: UIView {
  private var total = 0
  private var read = 0
  private var accent: UIColor = .systemBlue

  override init(frame: CGRect) {
    super.init(frame: frame)
    isOpaque = false
    contentMode = .redraw
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  func update(total: Int, read: Int, accent: UIColor) {
    self.total = total
    self.read = read
    self.accent = accent
    setNeedsDisplay()
  }

  override func draw(_ rect: CGRect) {
    guard total > 0 else { return }
    let lineWidth: CGFloat = 2.5
    let center = CGPoint(x: bounds.midX, y: bounds.midY)
    let radius = min(bounds.width, bounds.height) / 2 - lineWidth / 2
    let segments = min(total, 30)
    let gap: CGFloat = segments > 1 ? 0.14 : 0
    let sweep = (2 * CGFloat.pi - gap * CGFloat(segments)) / CGFloat(segments)
    let readSegments = min(max(read, 0), segments)
    var start = -CGFloat.pi / 2 + gap / 2
    for index in 0..<segments {
      let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: start,
                              endAngle: start + sweep, clockwise: true)
      path.lineWidth = lineWidth
      path.lineCapStyle = .round
      (index < readSegments ? UIColor.systemGray3 : accent).setStroke()
      path.stroke()
      start += sweep + gap
    }
  }
}
