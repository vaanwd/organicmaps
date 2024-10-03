enum ProductError: Error {
  case productsAreEmpty
  case failedToDecodeConfig
}

final class ProductsManager {

  enum ProductsScreen {
    case placePage
  }

  enum ProductAction {
    case closeDialog
    case openProduct(Product)
  }

  fileprivate enum ProductsVisibilityCondition {
    case lastPromotionClosingTimeoutExpired(closedTime: TimeInterval)
    case appLaunchTimeoutExpired(launchTime: TimeInterval)
  }

  static let `default` = ProductsManager(productsSettings: Settings.self)

  private let settings: ProductsSettings.Type
  private var configuration: ProductsConfiguration?
  private let decoder = JSONDecoder()

  init(productsSettings: ProductsSettings.Type) {
    self.settings = productsSettings
  }

  // MARK: - Public methods

  func fetchProductsConfiguration(for screen: ProductsScreen) throws -> ProductsConfiguration? {
    guard shouldShowProducts(for: screen) else {
      return nil
    }
    if let configuration {
      return configuration
    }
    guard let configString = settings.getProductsConfiguration() else {
      return nil
    }
    let configuration = try decodeProductsConfiguration(from: configString)
    guard !configuration.products.isEmpty else {
      throw ProductError.productsAreEmpty
    }
    self.configuration = configuration
    return configuration
  }

  func handleProductAction(_ action: ProductAction, from screen: ProductsScreen) {
    switch screen {
    case .placePage:
      switch action {
      case .closeDialog:
        break
      case .openProduct(let product):
        DispatchQueue.main.async {
          UIViewController.topViewController().openUrl(product.link, externally: true)
        }
      }
      settings.setProductsDialogClosed()
    }
  }

  // MARK: - Private methods

  private func decodeProductsConfiguration(from string: String) throws -> ProductsConfiguration {
    guard let jsonData = string.data(using: .utf8) else {
      throw ProductError.failedToDecodeConfig
    }
    return try decoder.decode(ProductsConfiguration.self, from: jsonData)
  }

  private func shouldShowProducts(for screen: ProductsScreen) -> Bool {
    guard settings.isProductsEnabled() else {
      return false
    }
    let conditions: [ProductsVisibilityCondition]
    switch screen {
    case .placePage:
      conditions = [
        .lastPromotionClosingTimeoutExpired(closedTime: settings.productsDialogClosedTime()),
        .appLaunchTimeoutExpired(launchTime: settings.launchTime()),
      ]
    }
    return conditions.allSatisfy { $0.evaluate() }
  }
}

private extension ProductsManager.ProductsVisibilityCondition {
  static let kMinTimeoutSinceLastClosing: TimeInterval = {
    #if DEBUG
    return 10
    #else
    return 180 * 24 * 60 * 60 // 180 days
    #endif
  }()

  static let kMinTimeoutSinceFirstLaunch: TimeInterval = {
    #if DEBUG
    return 3 * 60 // 3 min - usually it may takes some time to download the map after the first launch
    #else
    return 3 * 60 * 60 // 3 hours
    #endif
  }()

  func evaluate() -> Bool {
    switch self {
    case .lastPromotionClosingTimeoutExpired(let closedTime):
      if closedTime == 0 {
        return true // The dialog was never closed.
      }
      return closedTime + Self.kMinTimeoutSinceLastClosing < Date().timeIntervalSince1970
    case .appLaunchTimeoutExpired(let launchTime):
      return Date().timeIntervalSince1970 > launchTime + Self.kMinTimeoutSinceFirstLaunch
    }
  }
}

extension ProductError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .productsAreEmpty:
      return "Products are empty"
    case .failedToDecodeConfig:
      return "Failed to decode products configuration"
    }
  }
}
