final class ProductsViewController: UIViewController {

  private enum Constants {
    static let spacing: CGFloat = 10
    static let titleTopPadding: CGFloat = 20
    static let titleLeadingPadding: CGFloat = 12
    static let titleTrailingPadding: CGFloat = 10
    static let closeButtonSize: CGFloat = 25
    static let closeButtonTrailingPadding: CGFloat = -12
    static let closeButtonTopPadding: CGFloat = 12
    static let stackViewTopPadding: CGFloat = 12
    static let buttonSpacing: CGFloat = 10
    static let subtitleButtonTopPadding: CGFloat = 8
    static let subtitleButtonBottomPadding: CGFloat = -8
  }

  private let viewModel: ProductsViewModel
  private let titleLabel = UILabel()
  private let closeButton = UIButton(type: .system)
  private let stackView = UIStackView()
  private let subtitleButton = UIButton(type: .system)

  init(viewModel: ProductsViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    layout()
  }

  private func setupViews() {
    view.setStyleAndApply("Background")
    setupTitleLabel()
    setupCloseButton()
    setupProductsStackView()
    setupSubtitleButton()
  }

  private func setupTitleLabel() {
    titleLabel.text = viewModel.title
    titleLabel.font = UIFont.regular14()
    titleLabel.numberOfLines = 0
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
  }

  private func setupCloseButton() {
    closeButton.setStyleAndApply("MWMGray")
    closeButton.setImage(UIImage(resource: .icSearchClear), for: .normal)
    closeButton.translatesAutoresizingMaskIntoConstraints = false
    closeButton.addTarget(self, action: #selector(hide), for: .touchUpInside)
  }

  private func setupProductsStackView() {
    stackView.axis = .horizontal
    stackView.alignment = .fill
    stackView.distribution = .fillEqually
    stackView.spacing = Constants.spacing
    stackView.translatesAutoresizingMaskIntoConstraints = false
  }

  private func setupSubtitleButton() {
    subtitleButton.setTitle(viewModel.subtitle, for: .normal)
    subtitleButton.backgroundColor = .clear
    subtitleButton.setTitleColor(.linkBlue(), for: .normal)
    subtitleButton.translatesAutoresizingMaskIntoConstraints = false
    subtitleButton.addTarget(self, action: #selector(hide), for: .touchUpInside)
  }

  private func layout() {
    view.addSubview(titleLabel)
    view.addSubview(closeButton)
    view.addSubview(stackView)

    viewModel.products.forEach { product in
      let button = ProductButton(title: product.title) { [weak self] in
        guard let self else { return }
        self.viewModel.handleProductAction(.openProduct(product))
        self.hide()
      }
      stackView.addArrangedSubview(button)
    }
    view.addSubview(subtitleButton)

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.titleTopPadding),
      titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.titleLeadingPadding),
      titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -Constants.titleTrailingPadding),

      closeButton.widthAnchor.constraint(equalToConstant: Constants.closeButtonSize),
      closeButton.heightAnchor.constraint(equalToConstant: Constants.closeButtonSize),
      closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: Constants.closeButtonTrailingPadding),
      closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.closeButtonTopPadding),

      stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.titleLeadingPadding),
      stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.titleLeadingPadding),
      stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Constants.stackViewTopPadding),

      subtitleButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: Constants.subtitleButtonTopPadding),
      subtitleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.titleLeadingPadding),
      subtitleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.titleLeadingPadding),
      subtitleButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: Constants.subtitleButtonBottomPadding)
    ])
  }

  @objc private func hide() {
    viewModel.handleProductAction(.closeDialog)
    UIView.transition(with: view, duration: kDefaultAnimationDuration / 2, options: .transitionCrossDissolve) {
      self.view.isHidden = true
    }
  }
}
