import Flutter
import UIKit

final class KometSettingsViewFactory: NSObject, FlutterPlatformViewFactory {
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
    KometSettingsPlatformView(
      frame: frame, viewId: viewId, arguments: args, messenger: messenger)
  }
}

private final class KometSettingsHeader: UIView {
  let avatar = UIImageView()
  let nameLabel = UILabel()
  let statusLabel = UILabel()
  let phoneLabel = UILabel()
  let bioTitle = UILabel()
  let bioBody = UILabel()
  let qrButton = UIButton(type: .system)
  let menuButton = UIButton(type: .system)
  let editButton = UIButton(type: .system)
  let bioButton = UIButton(type: .system)
  var onAction: ((String, CGRect) -> Void)?
  private var avatarTask: URLSessionDataTask?
  private let bioCard = UIView()
  private var topConstraint: NSLayoutConstraint?
  private var bioBottom: NSLayoutConstraint?
  private var textBottom: NSLayoutConstraint?

  override init(frame: CGRect) {
    super.init(frame: frame)
    avatar.layer.cornerRadius = 44
    avatar.clipsToBounds = true
    avatar.contentMode = .scaleAspectFill
    avatar.backgroundColor = .secondarySystemFill
    avatar.isUserInteractionEnabled = true
    avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))
    nameLabel.font = .preferredFont(forTextStyle: .title2)
    nameLabel.adjustsFontForContentSizeCategory = true
    nameLabel.textAlignment = .center
    nameLabel.numberOfLines = 2
    statusLabel.font = .preferredFont(forTextStyle: .subheadline)
    statusLabel.textColor = .secondaryLabel
    statusLabel.textAlignment = .center
    phoneLabel.font = .preferredFont(forTextStyle: .subheadline)
    phoneLabel.textColor = .secondaryLabel
    phoneLabel.textAlignment = .center
    bioTitle.font = .preferredFont(forTextStyle: .caption1)
    bioTitle.textColor = .secondaryLabel
    bioTitle.text = "О себе"
    bioBody.font = .preferredFont(forTextStyle: .body)
    bioBody.numberOfLines = 4
    bioCard.backgroundColor = .secondarySystemGroupedBackground
    bioCard.layer.cornerRadius = 12
    bioButton.addTarget(self, action: #selector(bioTapped), for: .touchUpInside)
    configure(qrButton, "qrcode", #selector(qrTapped))
    configure(menuButton, "ellipsis", #selector(menuTapped))
    configure(editButton, "square.and.pencil", #selector(editTapped))
    let tools = UIStackView(arrangedSubviews: [qrButton, UIView(), menuButton, editButton])
    tools.axis = .horizontal
    tools.alignment = .center
    let text = UIStackView(arrangedSubviews: [nameLabel, statusLabel, phoneLabel])
    text.axis = .vertical
    text.spacing = 2
    text.alignment = .center
    let bioText = UIStackView(arrangedSubviews: [bioTitle, bioBody])
    bioText.axis = .vertical
    bioText.spacing = 4
    bioText.isUserInteractionEnabled = false
    bioText.translatesAutoresizingMaskIntoConstraints = false
    bioCard.addSubview(bioText)
    bioCard.addSubview(bioButton)
    for view in [avatar, tools, text, bioCard, bioButton, bioText] {
      view.translatesAutoresizingMaskIntoConstraints = false
    }
    addSubview(tools)
    addSubview(avatar)
    addSubview(text)
    addSubview(bioCard)
    let top = tools.topAnchor.constraint(equalTo: topAnchor, constant: 8)
    topConstraint = top
    textBottom = text.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
    NSLayoutConstraint.activate([
      top,
      tools.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
      tools.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
      qrButton.widthAnchor.constraint(equalToConstant: 44),
      qrButton.heightAnchor.constraint(equalToConstant: 44),
      menuButton.widthAnchor.constraint(equalToConstant: 44),
      menuButton.heightAnchor.constraint(equalToConstant: 44),
      editButton.widthAnchor.constraint(equalToConstant: 44),
      editButton.heightAnchor.constraint(equalToConstant: 44),
      avatar.topAnchor.constraint(equalTo: tools.bottomAnchor, constant: 4),
      avatar.centerXAnchor.constraint(equalTo: centerXAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 88),
      avatar.heightAnchor.constraint(equalToConstant: 88),
      text.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 12),
      text.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
      text.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
      bioCard.topAnchor.constraint(equalTo: text.bottomAnchor, constant: 16),
      bioCard.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      bioCard.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      {
        let pin = bioCard.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        bioBottom = pin
        return pin
      }(),
      bioText.leadingAnchor.constraint(equalTo: bioCard.leadingAnchor, constant: 16),
      bioText.trailingAnchor.constraint(equalTo: bioCard.trailingAnchor, constant: -16),
      bioText.topAnchor.constraint(equalTo: bioCard.topAnchor, constant: 12),
      bioText.bottomAnchor.constraint(equalTo: bioCard.bottomAnchor, constant: -12),
      bioButton.leadingAnchor.constraint(equalTo: bioCard.leadingAnchor),
      bioButton.trailingAnchor.constraint(equalTo: bioCard.trailingAnchor),
      bioButton.topAnchor.constraint(equalTo: bioCard.topAnchor),
      bioButton.bottomAnchor.constraint(equalTo: bioCard.bottomAnchor),
    ])
  }

  required init?(coder: NSCoder) { nil }

  func apply(_ map: [String: Any]) {
    let inset = (map["topInset"] as? NSNumber)?.doubleValue ?? 0
    topConstraint?.constant = inset + 8
    nameLabel.text = map["name"] as? String ?? ""
    statusLabel.text = map["status"] as? String ?? ""
    statusLabel.isHidden = statusLabel.text?.isEmpty ?? true
    let online = (map["online"] as? NSNumber)?.boolValue ?? false
    statusLabel.textColor = online ? .systemGreen : .secondaryLabel
    phoneLabel.text = map["phone"] as? String ?? ""
    let bio = map["bio"] as? String ?? ""
    bioBody.text = bio
    let showBio = !bio.isEmpty
    bioCard.isHidden = !showBio
    bioBottom?.isActive = showBio
    textBottom?.isActive = !showBio
    menuButton.isEnabled = (map["canEditAvatar"] as? NSNumber)?.boolValue ?? false
    let url = map["avatarUrl"] as? String ?? ""
    avatarTask?.cancel()
    if url.hasPrefix("http"), let imageUrl = URL(string: url) {
      avatarTask = URLSession.shared.dataTask(with: imageUrl) { [weak self] data, _, _ in
        guard let data, let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { self?.avatar.image = image }
      }
      avatarTask?.resume()
    } else {
      avatar.image = UIImage(systemName: "person.crop.circle.fill")
      avatar.tintColor = .secondaryLabel
    }
  }

  private func configure(_ button: UIButton, _ symbol: String, _ action: Selector) {
    button.setImage(UIImage(systemName: symbol), for: .normal)
    button.tintColor = .label
    button.addTarget(self, action: action, for: .touchUpInside)
  }

  @objc private func qrTapped() { send("qr", from: qrButton) }
  @objc private func menuTapped() { send("menu", from: menuButton) }
  @objc private func editTapped() { send("edit", from: editButton) }
  @objc private func bioTapped() { send("bio", from: bioButton) }
  @objc private func avatarTapped() { send("avatar", from: avatar) }

  private func send(_ action: String, from view: UIView) {
    let rect = view.convert(view.bounds, to: nil)
    onAction?(action, rect)
  }
}

final class KometSettingsPlatformView: NSObject, FlutterPlatformView,
  UITableViewDataSource, UITableViewDelegate {
  private let channel: FlutterMethodChannel
  private let root = UIView()
  private let table = UITableView(frame: .zero, style: .insetGrouped)
  private let header = KometSettingsHeader()
  private let versionButton = UIButton(type: .system)
  private var sections: [[String: Any]] = []

  init(frame: CGRect, viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "ru.komet.app/native_settings/\(viewId)", binaryMessenger: messenger)
    super.init()
    root.frame = frame
    root.backgroundColor = .systemGroupedBackground
    table.frame = root.bounds
    table.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    table.dataSource = self
    table.delegate = self
    table.backgroundColor = .systemGroupedBackground
    table.rowHeight = UITableView.automaticDimension
    table.estimatedRowHeight = 52
    table.separatorInset = UIEdgeInsets(top: 0, left: 56, bottom: 0, right: 0)
    if #available(iOS 15.0, *) {
      table.sectionHeaderTopPadding = 8
    }
    header.onAction = { [weak self] action, rect in
      self?.channel.invokeMethod("header", arguments: [
        "action": action,
        "x": rect.minX, "y": rect.minY, "width": rect.width, "height": rect.height,
      ])
    }
    versionButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
    versionButton.setTitleColor(.secondaryLabel, for: .normal)
    versionButton.addTarget(self, action: #selector(versionTapped), for: .touchUpInside)
    root.addSubview(table)
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
    if let headerMap = map["header"] as? [String: Any] {
      header.apply(headerMap)
    }
    sections = map["sections"] as? [[String: Any]] ?? []
    let version = map["version"] as? String ?? ""
    versionButton.setTitle(version, for: .normal)
    versionButton.isHidden = version.isEmpty
    table.reloadData()
    installChrome()
  }

  private func installChrome() {
    let width = max(root.bounds.width, 1)
    header.frame.size.width = width
    let height = header.systemLayoutSizeFitting(
      CGSize(width: width, height: 0),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    ).height
    header.frame.size.height = height
    table.tableHeaderView = header
    let footer = UIView(frame: CGRect(x: 0, y: 0, width: width, height: versionButton.isHidden ? 32 : 72))
    versionButton.frame = CGRect(x: 24, y: 8, width: width - 48, height: 44)
    if versionButton.superview !== footer { footer.addSubview(versionButton) }
    table.tableFooterView = footer
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    rows(section).count
  }

  func numberOfSections(in tableView: UITableView) -> Int { sections.count }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let row = rows(indexPath.section)[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "settings")
      ?? UITableViewCell(style: .default, reuseIdentifier: "settings")
    let destructive = flag(row, "destructive")
    let enabled = (row["enabled"] as? NSNumber)?.boolValue ?? true
    cell.textLabel?.text = row["title"] as? String
    cell.textLabel?.font = .preferredFont(forTextStyle: .body)
    cell.textLabel?.textColor = destructive ? .systemRed : (enabled ? .label : .secondaryLabel)
    cell.imageView?.image = UIImage(systemName: row["symbol"] as? String ?? "circle")
    cell.imageView?.tintColor = destructive ? .systemRed : .secondaryLabel
    cell.accessoryType = destructive ? .none : .disclosureIndicator
    cell.selectionStyle = enabled ? .default : .none
    cell.backgroundColor = .secondarySystemGroupedBackground
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let row = rows(indexPath.section)[indexPath.row]
    if (row["enabled"] as? NSNumber)?.boolValue == false { return }
    guard let id = row["id"] as? String else { return }
    channel.invokeMethod("tap", arguments: ["id": id])
  }

  private func rows(_ section: Int) -> [[String: Any]] {
    sections[section]["rows"] as? [[String: Any]] ?? []
  }

  private func flag(_ map: [String: Any], _ key: String) -> Bool {
    (map[key] as? NSNumber)?.boolValue ?? false
  }

  @objc private func versionTapped() {
    channel.invokeMethod("header", arguments: ["action": "version"])
  }
}
