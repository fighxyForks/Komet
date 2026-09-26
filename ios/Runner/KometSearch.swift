import Flutter
import UIKit

final class KometSearchViewFactory: NSObject, FlutterPlatformViewFactory {
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
    KometSearchPlatformView(frame: frame, viewId: viewId, messenger: messenger)
  }
}

final class KometSearchPlatformView: NSObject, FlutterPlatformView, UITableViewDataSource,
  UITableViewDelegate, UISearchBarDelegate {
  private let channel: FlutterMethodChannel
  private let root = UIView()
  private let searchBar = UISearchBar()
  private let closeButton = UIButton(type: .system)
  private let table = UITableView(frame: .zero, style: .insetGrouped)
  private var hits: [[String: Any]] = []

  init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "ru.komet.app/native_search/\(viewId)", binaryMessenger: messenger)
    super.init()
    root.frame = frame
    root.backgroundColor = .systemBackground
    searchBar.searchBarStyle = .minimal
    searchBar.placeholder = "Поиск"
    searchBar.autocapitalizationType = .none
    searchBar.delegate = self
    closeButton.setTitle("Закрыть", for: .normal)
    closeButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
    closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
    table.dataSource = self
    table.delegate = self
    table.keyboardDismissMode = .onDrag
    table.backgroundColor = .systemGroupedBackground
    for view in [searchBar, closeButton, table] {
      view.translatesAutoresizingMaskIntoConstraints = false
      root.addSubview(view)
    }
    NSLayoutConstraint.activate([
      searchBar.leadingAnchor.constraint(equalTo: root.safeAreaLayoutGuide.leadingAnchor, constant: 8),
      searchBar.topAnchor.constraint(equalTo: root.safeAreaLayoutGuide.topAnchor, constant: 4),
      closeButton.leadingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: 4),
      closeButton.trailingAnchor.constraint(equalTo: root.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      closeButton.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
      closeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
      closeButton.heightAnchor.constraint(equalToConstant: 44),
      table.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      table.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
      table.bottomAnchor.constraint(equalTo: root.bottomAnchor),
    ])
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      if call.method == "apply" {
        let map = call.arguments as? [String: Any] ?? [:]
        self.hits = map["hits"] as? [[String: Any]] ?? []
        self.table.reloadData()
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    DispatchQueue.main.async { [weak self] in
      self?.searchBar.becomeFirstResponder()
    }
  }

  deinit { channel.setMethodCallHandler(nil) }

  func view() -> UIView { root }

  @objc private func close() {
    channel.invokeMethod("close", arguments: nil)
  }

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    channel.invokeMethod("query", arguments: ["text": searchText])
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    hits.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let hit = hits[indexPath.row]
    let kind = hit["kind"] as? String ?? ""
    let cell = tableView.dequeueReusableCell(withIdentifier: kind) ??
      UITableViewCell(style: .subtitle, reuseIdentifier: kind)
    cell.textLabel?.text = hit["title"] as? String
    cell.detailTextLabel?.text = hit["subtitle"] as? String
    cell.textLabel?.font = kind == "header"
      ? .preferredFont(forTextStyle: .footnote)
      : .preferredFont(forTextStyle: .body)
    cell.textLabel?.textColor = kind == "header" ? .secondaryLabel : .label
    cell.selectionStyle = kind == "header" ? .none : .default
    cell.accessoryType = kind == "more" ? .disclosureIndicator : .none
    cell.backgroundColor = kind == "header" ? .clear : .secondarySystemGroupedBackground
    return cell
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let kind = hits[indexPath.row]["kind"] as? String
    return kind == "header" ? 28 : 52
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let hit = hits[indexPath.row]
    let kind = hit["kind"] as? String ?? ""
    guard kind != "header", let id = hit["id"] as? String else { return }
    if kind == "more" {
      channel.invokeMethod("more", arguments: nil)
    } else {
      channel.invokeMethod("open", arguments: ["id": id])
    }
  }
}
