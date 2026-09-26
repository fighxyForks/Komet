import Flutter
import UIKit

final class KometEmojiPanelViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
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
    KometEmojiPanelPlatformView(frame: frame, viewId: viewId, messenger: messenger)
  }
}

final class KometEmojiPanelPlatformView: NSObject, FlutterPlatformView,
  UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate {
  private let channel: FlutterMethodChannel
  private let root = UIView()
  private let search = UISearchBar()
  private let categories = UIScrollView()
  private let categoryRow = UIStackView()
  private var collection: UICollectionView!
  private var glyphs: [String] = []
  private var categoryIds: [String] = []

  init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "ru.komet.app/native_emoji/\(viewId)", binaryMessenger: messenger)
    super.init()
    root.frame = frame
    root.backgroundColor = .systemBackground
    search.searchBarStyle = .minimal
    search.placeholder = "Поиск"
    search.delegate = self
    categoryRow.axis = .horizontal
    categoryRow.spacing = 8
    categories.addSubview(categoryRow)
    categoryRow.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      categoryRow.leadingAnchor.constraint(equalTo: categories.contentLayoutGuide.leadingAnchor, constant: 12),
      categoryRow.trailingAnchor.constraint(equalTo: categories.contentLayoutGuide.trailingAnchor, constant: -12),
      categoryRow.topAnchor.constraint(equalTo: categories.contentLayoutGuide.topAnchor),
      categoryRow.bottomAnchor.constraint(equalTo: categories.contentLayoutGuide.bottomAnchor),
      categoryRow.heightAnchor.constraint(equalTo: categories.frameLayoutGuide.heightAnchor),
    ])
    let layout = UICollectionViewFlowLayout()
    layout.itemSize = CGSize(width: 40, height: 40)
    layout.minimumInteritemSpacing = 4
    layout.minimumLineSpacing = 4
    layout.sectionInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collection.backgroundColor = .clear
    collection.dataSource = self
    collection.delegate = self
    collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "emoji")
    for view in [search, categories, collection!] {
      view.translatesAutoresizingMaskIntoConstraints = false
      root.addSubview(view)
    }
    NSLayoutConstraint.activate([
      search.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      search.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      search.topAnchor.constraint(equalTo: root.topAnchor),
      categories.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      categories.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      categories.topAnchor.constraint(equalTo: search.bottomAnchor),
      categories.heightAnchor.constraint(equalToConstant: 44),
      collection.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      collection.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      collection.topAnchor.constraint(equalTo: categories.bottomAnchor),
      collection.bottomAnchor.constraint(equalTo: root.bottomAnchor),
    ])
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "apply", let map = call.arguments as? [String: Any] else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.apply(map)
      result(nil)
    }
  }

  deinit { channel.setMethodCallHandler(nil) }
  func view() -> UIView { root }

  private func apply(_ map: [String: Any]) {
    glyphs = map["glyphs"] as? [String] ?? []
    let next = map["categories"] as? [[String: Any]] ?? []
    let ids = next.compactMap { $0["id"] as? String }
    if ids != categoryIds {
      categoryIds = ids
      categoryRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
      for item in next {
        guard let id = item["id"] as? String, let title = item["title"] as? String else { continue }
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        button.accessibilityIdentifier = id
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 32).isActive = true
        button.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
        categoryRow.addArrangedSubview(button)
      }
    }
    collection.reloadData()
  }

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    channel.invokeMethod("search", arguments: ["text": searchText])
  }

  @objc private func categoryTapped(_ sender: UIButton) {
    search.text = ""
    channel.invokeMethod("category", arguments: ["id": sender.accessibilityIdentifier ?? ""])
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    glyphs.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emoji", for: indexPath)
    let label = (cell.contentView.viewWithTag(1) as? UILabel) ?? {
      let label = UILabel()
      label.tag = 1
      label.font = .systemFont(ofSize: 28)
      label.textAlignment = .center
      label.translatesAutoresizingMaskIntoConstraints = false
      cell.contentView.addSubview(label)
      NSLayoutConstraint.activate([
        label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
        label.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
        label.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
        label.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
      ])
      let press = UILongPressGestureRecognizer(target: self, action: #selector(holdEmoji(_:)))
      cell.addGestureRecognizer(press)
      return label
    }()
    label.text = glyphs[indexPath.item]
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    channel.invokeMethod("pick", arguments: ["glyph": glyphs[indexPath.item]])
  }

  @objc private func holdEmoji(_ gesture: UILongPressGestureRecognizer) {
    guard gesture.state == .began,
          let cell = gesture.view as? UICollectionViewCell,
          let path = collection.indexPath(for: cell) else { return }
    let glyph = glyphs[path.item]
    channel.invokeMethod("skins", arguments: ["glyph": glyph]) { [weak self] result in
      guard let skins = result as? [String], skins.count > 1, let self = self else { return }
      let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
      for skin in skins {
        sheet.addAction(UIAlertAction(title: skin, style: .default) { _ in
          self.channel.invokeMethod("pick", arguments: ["glyph": skin])
        })
      }
      sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
      var presenter: UIViewController? = self.root.window?.rootViewController
      while let presented = presenter?.presentedViewController { presenter = presented }
      presenter?.present(sheet, animated: true)
    }
  }
}
