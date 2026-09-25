import Flutter
import UIKit

final class KometNativeAlert: NSObject {
  static let shared = KometNativeAlert()

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "prompt":
      prompt(call.arguments as? [String: Any] ?? [:], result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func prompt(_ arguments: [String: Any], result: @escaping FlutterResult) {
    guard let presenter = topViewController() else {
      result(FlutterError(code: "NO_ROOT", message: "No view controller to present from",
                          details: nil))
      return
    }
    let alert = UIAlertController(
      title: nonEmpty(arguments["title"]), message: nonEmpty(arguments["message"]),
      preferredStyle: .alert)
    var finished = false
    var observer: NSObjectProtocol?
    func finish(_ value: String?) {
      guard !finished else { return }
      finished = true
      if let observer = observer {
        NotificationCenter.default.removeObserver(observer)
      }
      result(value)
    }

    alert.addTextField { field in
      field.placeholder = arguments["placeholder"] as? String
      field.text = arguments["text"] as? String
      field.isSecureTextEntry = (arguments["secure"] as? NSNumber)?.boolValue ?? false
      field.clearButtonMode = .whileEditing
      field.returnKeyType = .done
      KometNativeAlert.applyKeyboard(arguments["keyboard"] as? String, to: field)
    }

    let cancel = UIAlertAction(
      title: arguments["cancel"] as? String ?? "Cancel", style: .cancel) { _ in finish(nil) }
    let confirm = UIAlertAction(
      title: arguments["confirm"] as? String ?? "OK", style: .default) { [weak alert] _ in
      let text = alert?.textFields?.first?.text?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      finish(text.isEmpty ? nil : text)
    }
    alert.addAction(cancel)
    alert.addAction(confirm)
    alert.preferredAction = confirm

    let field = alert.textFields?.first
    let updateConfirm = { [weak field] in
      let text = field?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      confirm.isEnabled = !text.isEmpty
    }
    updateConfirm()
    if let field = field {
      observer = NotificationCenter.default.addObserver(
        forName: UITextField.textDidChangeNotification, object: field, queue: .main
      ) { _ in updateConfirm() }
    }
    presenter.present(alert, animated: true)
  }

  private static func applyKeyboard(_ kind: String?, to field: UITextField) {
    switch kind {
    case "url":
      field.keyboardType = .URL
      field.autocapitalizationType = .none
      field.autocorrectionType = .no
      field.textContentType = .URL
    case "number":
      field.keyboardType = .numberPad
    case "email":
      field.keyboardType = .emailAddress
      field.autocapitalizationType = .none
      field.autocorrectionType = .no
    default:
      field.keyboardType = .default
    }
  }

  private func nonEmpty(_ value: Any?) -> String? {
    guard let text = value as? String, !text.isEmpty else { return nil }
    return text
  }

  private func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    for scene in scenes {
      if let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
        var top = root
        while let presented = top.presentedViewController, !presented.isBeingDismissed {
          top = presented
        }
        return top
      }
    }
    return nil
  }
}
