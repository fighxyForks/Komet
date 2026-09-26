import Flutter
import UIKit

final class KometChatSearchBarFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    KometChatSearchBarView(frame: frame, viewId: viewId, arguments: args, messenger: messenger)
  }
}

final class KometChatSearchResultsFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    KometChatSearchResultsView(frame: frame, viewId: viewId, arguments: args, messenger: messenger)
  }
}

final class KometPinnedBannerFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    KometPinnedBannerView(frame: frame, viewId: viewId, arguments: args, messenger: messenger)
  }
}

private final class KometChatSearchBarView: NSObject, FlutterPlatformView, UITextFieldDelegate {
  private let channel: FlutterMethodChannel
  private let root = UIView()
  private let field = UITextField()
  private let clearButton = UIButton(type: .system)
  private var applying = false
  private var focused = false

  init(frame: CGRect, viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "ru.komet.app/native_chat_search_bar/\(viewId)", binaryMessenger: messenger)
    super.init()
    root.frame = frame
    root.backgroundColor = .clear
    let close = UIButton(type: .system)
    close.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
    close.tintColor = .label
    close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    let capsule = UIView()
    capsule.backgroundColor = .secondarySystemFill
    capsule.layer.cornerRadius = 18
    let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    icon.tintColor = .secondaryLabel
    icon.contentMode = .scaleAspectFit
    field.font = .preferredFont(forTextStyle: .body)
    field.textColor = .label
    field.returnKeyType = .search
    field.autocorrectionType = .no
    field.clearButtonMode = .never
    field.delegate = self
    field.addTarget(self, action: #selector(edited), for: .editingChanged)
    clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
    clearButton.tintColor = .tertiaryLabel
    clearButton.addTarget(self, action: #selector(cleared), for: .touchUpInside)
    for view in [close, capsule, icon, field, clearButton] {
      view.translatesAutoresizingMaskIntoConstraints = false
    }
    capsule.addSubview(icon)
    capsule.addSubview(field)
    capsule.addSubview(clearButton)
    root.addSubview(close)
    root.addSubview(capsule)
    NSLayoutConstraint.activate([
      close.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 4),
      close.centerYAnchor.constraint(equalTo: root.centerYAnchor),
      close.widthAnchor.constraint(equalToConstant: 44),
      close.heightAnchor.constraint(equalToConstant: 44),
      capsule.leadingAnchor.constraint(equalTo: close.trailingAnchor, constant: 4),
      capsule.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
      capsule.centerYAnchor.constraint(equalTo: root.centerYAnchor),
      capsule.heightAnchor.constraint(equalToConstant: 36),
      icon.leadingAnchor.constraint(equalTo: capsule.leadingAnchor, constant: 10),
      icon.centerYAnchor.constraint(equalTo: capsule.centerYAnchor),
      icon.widthAnchor.constraint(equalToConstant: 18),
      icon.heightAnchor.constraint(equalToConstant: 18),
      field.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
      field.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor),
      field.topAnchor.constraint(equalTo: capsule.topAnchor),
      field.bottomAnchor.constraint(equalTo: capsule.bottomAnchor),
      clearButton.trailingAnchor.constraint(equalTo: capsule.trailingAnchor, constant: -4),
      clearButton.centerYAnchor.constraint(equalTo: capsule.centerYAnchor),
      clearButton.widthAnchor.constraint(equalToConstant: 32),
    ])
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
    let text = map?["text"] as? String ?? ""
    if field.text != text {
      applying = true
      field.text = text
      applying = false
    }
    clearButton.isHidden = text.isEmpty
    if !focused {
      focused = true
      field.becomeFirstResponder()
    }
  }

  @objc private func edited() {
    guard !applying else { return }
    clearButton.isHidden = (field.text ?? "").isEmpty
    channel.invokeMethod("text", arguments: ["text": field.text ?? ""])
  }

  @objc private func cleared() {
    field.text = ""
    clearButton.isHidden = true
    channel.invokeMethod("text", arguments: ["text": ""])
  }

  @objc private func closeTapped() { channel.invokeMethod("close", arguments: nil) }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    channel.invokeMethod("submit", arguments: ["text": textField.text ?? ""])
    return true
  }
}

private final class KometChatSearchResultsView: NSObject, FlutterPlatformView, UITableViewDataSource, UITableViewDelegate {
  private let channel: FlutterMethodChannel
  private let table = UITableView(frame: .zero, style: .plain)
  private let emptyLabel = UILabel()
  private let spinner = UIActivityIndicatorView(style: .medium)
  private var rows: [[String: Any]] = []

  init(frame: CGRect, viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "ru.komet.app/native_chat_search_results/\(viewId)", binaryMessenger: messenger)
    super.init()
    table.frame = frame
    table.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    table.dataSource = self
    table.delegate = self
    table.backgroundColor = .systemBackground
    table.rowHeight = 72
    table.keyboardDismissMode = .onDrag
    table.register(KometChatSearchCell.self, forCellReuseIdentifier: KometChatSearchCell.reuse)
    emptyLabel.text = "Поиск ничего не вернул…"
    emptyLabel.textColor = .secondaryLabel
    emptyLabel.font = .preferredFont(forTextStyle: .body)
    emptyLabel.textAlignment = .center
    emptyLabel.isHidden = true
    spinner.hidesWhenStopped = true
    table.backgroundView = emptyLabel
    table.addSubview(spinner)
    spinner.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      spinner.centerXAnchor.constraint(equalTo: table.centerXAnchor),
      spinner.centerYAnchor.constraint(equalTo: table.centerYAnchor),
    ])
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
  func view() -> UIView { table }

  private func apply(_ map: [String: Any]?) {
    let map = map ?? [:]
    rows = map["items"] as? [[String: Any]] ?? []
    let loading = (map["loading"] as? NSNumber)?.boolValue ?? false
    let performed = (map["performed"] as? NSNumber)?.boolValue ?? false
    emptyLabel.isHidden = !performed || loading || !rows.isEmpty
    if loading && rows.isEmpty { spinner.startAnimating() } else { spinner.stopAnimating() }
    table.reloadData()
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: KometChatSearchCell.reuse, for: indexPath) as! KometChatSearchCell
    cell.apply(rows[indexPath.row])
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard let id = rows[indexPath.row]["id"] as? String else { return }
    channel.invokeMethod("open", arguments: ["id": id])
  }
}

private final class KometChatSearchCell: UITableViewCell {
  static let reuse = "search"
  private let avatar = UIImageView()
  private let nameLabel = UILabel()
  private let dateLabel = UILabel()
  private let bodyLabel = UILabel()
  private var task: URLSessionDataTask?
  private var loaded = ""

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    avatar.layer.cornerRadius = 22
    avatar.clipsToBounds = true
    avatar.backgroundColor = .secondarySystemFill
    avatar.contentMode = .scaleAspectFill
    nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
    dateLabel.font = .preferredFont(forTextStyle: .caption1)
    dateLabel.textColor = .secondaryLabel
    dateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    bodyLabel.font = .preferredFont(forTextStyle: .subheadline)
    bodyLabel.textColor = .label
    bodyLabel.numberOfLines = 2
    let title = UIStackView(arrangedSubviews: [nameLabel, dateLabel])
    title.axis = .horizontal
    title.spacing = 8
    let column = UIStackView(arrangedSubviews: [title, bodyLabel])
    column.axis = .vertical
    column.spacing = 2
    for view in [avatar, column] {
      view.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(view)
    }
    NSLayoutConstraint.activate([
      avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 44),
      avatar.heightAnchor.constraint(equalToConstant: 44),
      column.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
      column.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      column.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }

  required init?(coder: NSCoder) { nil }

  func apply(_ row: [String: Any]) {
    nameLabel.text = row["name"] as? String ?? ""
    dateLabel.text = row["date"] as? String ?? ""
    let text = row["text"] as? String ?? ""
    let highlights = row["highlights"] as? [String] ?? []
    bodyLabel.attributedText = highlighted(text, highlights)
    let url = row["avatar"] as? String ?? ""
    if url == loaded { return }
    loaded = url
    task?.cancel()
    avatar.image = UIImage(systemName: "person.crop.circle.fill")
    guard url.hasPrefix("http"), let imageUrl = URL(string: url) else { return }
    task = URLSession.shared.dataTask(with: imageUrl) { [weak self] data, _, _ in
      guard let self, let data, let image = UIImage(data: data), self.loaded == url else { return }
      DispatchQueue.main.async { self.avatar.image = image }
    }
    task?.resume()
  }

  private func highlighted(_ text: String, _ terms: [String]) -> NSAttributedString {
    let result = NSMutableAttributedString(
      string: text,
      attributes: [.font: UIFont.preferredFont(forTextStyle: .subheadline), .foregroundColor: UIColor.label]
    )
    let lower = text.lowercased()
    for term in terms where !term.isEmpty {
      var start = lower.startIndex
      let needle = term.lowercased()
      while let range = lower.range(of: needle, range: start..<lower.endIndex) {
        let ns = NSRange(range, in: text)
        result.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .subheadline).bold(), range: ns)
        start = range.upperBound
      }
    }
    return result
  }
}

private extension UIFont {
  func bold() -> UIFont {
    UIFont.systemFont(ofSize: pointSize, weight: .semibold)
  }
}

private final class KometPinnedBannerView: NSObject, FlutterPlatformView {
  private let channel: FlutterMethodChannel
  private let root = UIView()
  private let titleLabel = UILabel()
  private let bodyLabel = UILabel()
  private let close = UIButton(type: .system)

  init(frame: CGRect, viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "ru.komet.app/native_chat_pinned/\(viewId)", binaryMessenger: messenger)
    super.init()
    root.frame = frame
    root.backgroundColor = .secondarySystemGroupedBackground
    root.layer.cornerRadius = 16
    root.clipsToBounds = true
    let bar = UIView()
    bar.backgroundColor = .systemBlue
    bar.layer.cornerRadius = 1.5
    titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
    titleLabel.textColor = .systemBlue
    bodyLabel.font = .preferredFont(forTextStyle: .subheadline)
    bodyLabel.textColor = .secondaryLabel
    bodyLabel.numberOfLines = 1
    close.setImage(UIImage(systemName: "xmark"), for: .normal)
    close.tintColor = .secondaryLabel
    close.addTarget(self, action: #selector(unpin), for: .touchUpInside)
    let open = UITapGestureRecognizer(target: self, action: #selector(tapped))
    root.addGestureRecognizer(open)
    let column = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
    column.axis = .vertical
    column.spacing = 1
    for view in [bar, column, close] {
      view.translatesAutoresizingMaskIntoConstraints = false
      root.addSubview(view)
    }
    NSLayoutConstraint.activate([
      bar.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
      bar.centerYAnchor.constraint(equalTo: root.centerYAnchor),
      bar.widthAnchor.constraint(equalToConstant: 3),
      bar.heightAnchor.constraint(equalToConstant: 28),
      column.leadingAnchor.constraint(equalTo: bar.trailingAnchor, constant: 10),
      column.trailingAnchor.constraint(equalTo: close.leadingAnchor, constant: -8),
      column.centerYAnchor.constraint(equalTo: root.centerYAnchor),
      close.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -4),
      close.centerYAnchor.constraint(equalTo: root.centerYAnchor),
      close.widthAnchor.constraint(equalToConstant: 44),
      close.heightAnchor.constraint(equalToConstant: 44),
    ])
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
    let map = map ?? [:]
    titleLabel.text = map["title"] as? String ?? "Закреплённое"
    bodyLabel.text = map["text"] as? String ?? ""
    close.isHidden = !((map["canUnpin"] as? NSNumber)?.boolValue ?? false)
  }

  @objc private func tapped() { channel.invokeMethod("open", arguments: nil) }
  @objc private func unpin() { channel.invokeMethod("unpin", arguments: nil) }
}
