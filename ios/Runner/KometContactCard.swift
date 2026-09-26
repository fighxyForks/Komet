import Flutter
import UIKit

final class KometContactCardViewFactory: NSObject, FlutterPlatformViewFactory {
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
    KometContactCardPlatformView(
      frame: frame, viewId: viewId, arguments: args, messenger: messenger)
  }
}

final class KometContactCardPlatformView: NSObject, FlutterPlatformView, UITextFieldDelegate {
  private let channel: FlutterMethodChannel
  private let card = UIView()
  private let titleLabel = UILabel()
  private let closeButton = UIButton(type: .system)
  private let segments = UISegmentedControl(items: ["По номеру", "По ID"])
  private let field = UITextField()
  private let firstField = UITextField()
  private let lastField = UITextField()
  private let errorLabel = UILabel()
  private let actionButton = UIButton(type: .system)
  private let mode: String
  private var phoneMode = true

  init(frame: CGRect, viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger) {
    let args = arguments as? [String: Any] ?? [:]
    mode = args["mode"] as? String ?? "lookup"
    channel = FlutterMethodChannel(
      name: "ru.komet.app/native_contact_card/\(viewId)", binaryMessenger: messenger)
    super.init()
    card.frame = frame
    card.backgroundColor = .clear
    let panel = UIView()
    panel.backgroundColor = .secondarySystemGroupedBackground
    panel.layer.cornerRadius = 22
    panel.layer.cornerCurve = .continuous
    panel.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(panel)
    titleLabel.font = .preferredFont(forTextStyle: .title2)
    titleLabel.text = mode == "add" ? "Новый контакт" : "Найти"
    closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
    closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
    segments.selectedSegmentIndex = 0
    segments.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    segments.isHidden = mode != "lookup"
    style(field, mode == "add" ? "Телефон" : "Номер телефона")
    style(firstField, "Имя")
    style(lastField, "Фамилия")
    firstField.isHidden = mode != "add"
    lastField.isHidden = mode != "add"
    field.keyboardType = .phonePad
    field.delegate = self
    errorLabel.textColor = .systemRed
    errorLabel.font = .preferredFont(forTextStyle: .footnote)
    errorLabel.numberOfLines = 0
    errorLabel.isHidden = true
    actionButton.setTitle(mode == "add" ? "Сохранить" : "Найти", for: .normal)
    actionButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
    actionButton.backgroundColor = .systemBlue
    actionButton.tintColor = .white
    actionButton.layer.cornerRadius = 12
    actionButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    actionButton.addTarget(self, action: #selector(submit), for: .touchUpInside)
    let header = UIStackView(arrangedSubviews: [titleLabel, closeButton])
    header.axis = .horizontal
    let stack = UIStackView(arrangedSubviews: [
      header, segments, field, firstField, lastField, errorLabel, actionButton,
    ])
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    panel.addSubview(stack)
    NSLayoutConstraint.activate([
      panel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
      panel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
      panel.leadingAnchor.constraint(greaterThanOrEqualTo: card.leadingAnchor, constant: 24),
      panel.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -24),
      panel.widthAnchor.constraint(equalToConstant: 340),
      stack.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),
      stack.topAnchor.constraint(equalTo: panel.topAnchor, constant: 16),
      stack.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -16),
      closeButton.widthAnchor.constraint(equalToConstant: 44),
      closeButton.heightAnchor.constraint(equalToConstant: 44),
    ])
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "status" {
        let map = call.arguments as? [String: Any] ?? [:]
        let error = map["error"] as? String ?? ""
        self?.errorLabel.text = error
        self?.errorLabel.isHidden = error.isEmpty
        self?.actionButton.isEnabled = (map["loading"] as? NSNumber)?.boolValue != true
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  deinit { channel.setMethodCallHandler(nil) }
  func view() -> UIView { card }

  private func style(_ field: UITextField, _ placeholder: String) {
    field.placeholder = placeholder
    field.borderStyle = .roundedRect
    field.font = .preferredFont(forTextStyle: .body)
    field.clearButtonMode = .whileEditing
    field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
  }

  @objc private func close() { channel.invokeMethod("close", arguments: nil) }

  @objc private func segmentChanged() {
    phoneMode = segments.selectedSegmentIndex == 0
    field.text = ""
    field.keyboardType = phoneMode ? .phonePad : .numberPad
    field.placeholder = phoneMode ? "Номер телефона" : "ID"
    field.reloadInputViews()
    errorLabel.isHidden = true
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                 replacementString string: String) -> Bool {
    guard textField === field else { return true }
    let current = textField.text ?? ""
    let next = (current as NSString).replacingCharacters(in: range, with: string)
    let digits = next.filter(\.isNumber)
    if !phoneMode {
      textField.text = digits
      return false
    }
    textField.text = mask(digits)
    return false
  }

  private func mask(_ digits: String) -> String {
    let body = String(digits.prefix(11))
    var result = ""
    for (index, char) in body.enumerated() {
      if index == 1 { result += " (" }
      if index == 4 { result += ") " }
      if index == 7 || index == 9 { result += "-" }
      result.append(char)
    }
    return result
  }

  @objc private func submit() {
    if mode == "add" {
      channel.invokeMethod("save", arguments: [
        "phone": field.text ?? "",
        "first": firstField.text ?? "",
        "last": lastField.text ?? "",
      ])
    } else {
      channel.invokeMethod("find", arguments: [
        "mode": phoneMode ? "phone" : "id",
        "query": field.text ?? "",
      ])
    }
  }
}
