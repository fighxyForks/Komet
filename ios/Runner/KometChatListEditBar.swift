import UIKit

final class KometChatListEditBar: UIView {
  enum Action: String {
    case read
    case archive
    case delete
  }

  var onAction: ((Action) -> Void)?

  private(set) lazy var readButton = makeButton(.read)
  private(set) lazy var archiveButton = makeButton(.archive)
  private(set) lazy var deleteButton = makeButton(.delete)
  private var accent: UIColor = .systemBlue

  override init(frame: CGRect) {
    super.init(frame: frame)
    [readButton, archiveButton, deleteButton].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      addSubview($0)
    }
    NSLayoutConstraint.activate([
      readButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      archiveButton.centerXAnchor.constraint(equalTo: centerXAnchor),
      deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      readButton.trailingAnchor.constraint(lessThanOrEqualTo: archiveButton.leadingAnchor,
                                           constant: -8),
      archiveButton.trailingAnchor.constraint(lessThanOrEqualTo: deleteButton.leadingAnchor,
                                              constant: -8),
    ])
    for button in [readButton, archiveButton, deleteButton] {
      NSLayoutConstraint.activate([
        button.topAnchor.constraint(equalTo: topAnchor),
        button.bottomAnchor.constraint(equalTo: bottomAnchor),
        button.heightAnchor.constraint(equalToConstant: 36),
      ])
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  func update(readTitle: String, archiveTitle: String, deleteTitle: String,
              canArchive: Bool, canDelete: Bool, accent: UIColor) {
    self.accent = accent
    setTitle(readTitle, of: readButton, color: accent)
    setTitle(archiveTitle, of: archiveButton, color: accent)
    setTitle(deleteTitle, of: deleteButton, color: .systemRed)
    archiveButton.isEnabled = canArchive
    deleteButton.isEnabled = canDelete
  }

  private func makeButton(_ action: Action) -> UIButton {
    let button: UIButton
    if #available(iOS 15.0, *) {
      var configuration: UIButton.Configuration
      if #available(iOS 26.0, *) {
        configuration = .glass()
      } else {
        configuration = .filled()
        configuration.background.visualEffect = UIBlurEffect(style: .systemChromeMaterial)
        configuration.background.backgroundColor = .clear
      }
      configuration.cornerStyle = .capsule
      configuration.contentInsets = NSDirectionalEdgeInsets(
        top: 0, leading: 20, bottom: 0, trailing: 20)
      button = UIButton(configuration: configuration)
      button.configurationUpdateHandler = { [weak self] button in
        guard let self = self else { return }
        let base: UIColor = action == .delete ? .systemRed : self.accent
        button.configuration?.baseForegroundColor = button.isEnabled
          ? base : KometChatListStyle.secondary.withAlphaComponent(0.6)
      }
    } else {
      button = UIButton(type: .system)
      button.backgroundColor = .secondarySystemBackground
      button.layer.cornerRadius = 18
      button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    button.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
    return button
  }

  @objc private func tapped(_ sender: UIButton) {
    switch sender {
    case readButton: onAction?(.read)
    case archiveButton: onAction?(.archive)
    case deleteButton: onAction?(.delete)
    default: break
    }
  }

  private func setTitle(_ title: String, of button: UIButton, color: UIColor) {
    let font = UIFont.systemFont(ofSize: 15, weight: .semibold)
    if #available(iOS 15.0, *) {
      var attributed = AttributedString(title)
      attributed.font = font
      button.configuration?.attributedTitle = attributed
      button.configuration?.titleLineBreakMode = .byClipping
      button.setNeedsUpdateConfiguration()
    } else {
      button.setTitle(title, for: .normal)
      button.titleLabel?.font = font
      button.titleLabel?.numberOfLines = 1
      button.titleLabel?.lineBreakMode = .byClipping
      button.titleLabel?.adjustsFontSizeToFitWidth = true
      button.titleLabel?.minimumScaleFactor = 0.75
      button.setTitleColor(color, for: .normal)
      button.setTitleColor(KometChatListStyle.secondary, for: .disabled)
    }
  }
}
