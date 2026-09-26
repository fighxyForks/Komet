import Flutter
import UIKit

final class KometProfileActionsViewFactory: NSObject, FlutterPlatformViewFactory {
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
    KometProfileActionsPlatformView(
      frame: frame, viewId: viewId, arguments: args, messenger: messenger)
  }
}

final class KometProfileActionsPlatformView: NSObject, FlutterPlatformView,
  UITableViewDataSource, UITableViewDelegate {
  private let channel: FlutterMethodChannel
  private let table = UITableView(frame: .zero, style: .insetGrouped)
  private var rows: [[String: Any]] = []

  init(frame: CGRect, viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "ru.komet.app/native_profile_actions/\(viewId)", binaryMessenger: messenger)
    super.init()
    table.frame = frame
    table.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    table.dataSource = self
    table.delegate = self
    table.isScrollEnabled = false
    table.backgroundColor = .clear
    table.rowHeight = 52
    if let map = arguments as? [String: Any] {
      rows = map["rows"] as? [[String: Any]] ?? []
    }
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "apply", let map = call.arguments as? [String: Any] else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.rows = map["rows"] as? [[String: Any]] ?? []
      self?.table.reloadData()
      result(nil)
    }
  }

  deinit { channel.setMethodCallHandler(nil) }
  func view() -> UIView { table }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    rows.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let row = rows[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "action")
      ?? UITableViewCell(style: .default, reuseIdentifier: "action")
    let destructive = (row["destructive"] as? NSNumber)?.boolValue ?? false
    cell.textLabel?.text = row["title"] as? String
    cell.textLabel?.font = .preferredFont(forTextStyle: .body)
    cell.textLabel?.textColor = destructive ? .systemRed : .label
    let symbol = row["symbol"] as? String ?? ""
    cell.imageView?.image = UIImage(systemName: symbol)
    cell.imageView?.tintColor = destructive ? .systemRed : .secondaryLabel
    cell.backgroundColor = .secondarySystemGroupedBackground
    cell.selectionStyle = .default
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard let id = rows[indexPath.row]["id"] as? String else { return }
    channel.invokeMethod("tap", arguments: ["id": id])
  }
}
