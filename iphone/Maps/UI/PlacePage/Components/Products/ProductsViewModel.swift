struct ProductsViewModel {

  private let productsManager: ProductsManager
  let title: String
  let subtitle: String
  let products: [Product]

  init(manager: ProductsManager, configuration: ProductsConfiguration) {
    self.productsManager = manager
    self.title = configuration.placePagePrompt
    self.products = configuration.products
    self.subtitle = L("already_donated")
  }

  func handleProductAction(_ action: ProductsManager.ProductAction) {
    productsManager.handleProductAction(action, from: .placePage)
  }
}

