import Testing
@testable import Organic_Maps__Debug_

@Suite(.serialized) struct ProductsManagerTest {
  fileprivate var productsManager: ProductsManager
  fileprivate var mockSettings: MockProductsSettings

  static let validProductsConfigJSON_1 = """
    {
      "placePagePrompt": "prompt1",
      "aboutScreenPrompt": "prompt2",
      "products": [
        {"title": "$3", "link": "http://product1"},
        {"title": "$10", "link": "http://product2"}
      ]
    }
    """
  static let validProductsConfigJSON_2 = """
    {
      "placePagePrompt": "",
      "aboutScreenPrompt": "",
      "products": [
        {"title": "$3", "link": ""},
      ]
    }
    """

  init() {
    let settings = MockProductsSettings()
    settings.productsConfiguration = Self.validProductsConfigJSON_1
    MockProductsSettings.default = settings
    mockSettings = settings
    productsManager = ProductsManager(productsSettings: MockProductsSettings.self)
  }

  @Test(arguments: [
    Self.validProductsConfigJSON_1,
    Self.validProductsConfigJSON_2
  ])
  func validJSON(jsonSting: String) throws {
    mockSettings.productsConfiguration = jsonSting
    #expect(throws: Never.self) {
      try productsManager.fetchProductsConfiguration(for: .placePage)
    }
  }

  @Test(arguments: [
    "Invalid JSON",
    "{}",
    """
    {
      "placePagePrompt": "Please donate",
    }
    """,
    """
    {
      "products": [
        {"title": "$3", "link": "http://product1"},
      ]
    }
    """
  ])
  func invalidJSON(jsonSting: String) throws {
    mockSettings.productsConfiguration = jsonSting
    #expect(throws: (any Error).self) {
      try productsManager.fetchProductsConfiguration(for: .placePage)
    }
  }

  @Test
  func JSONParsing() throws {
    let config = try #require(try productsManager.fetchProductsConfiguration(for: .placePage))
    #expect(!config.products.isEmpty)
    #expect(config.placePagePrompt == "prompt1")
    #expect(config.aboutScreenPrompt == "prompt2")
    #expect(config.products[0].title == "$3")
    #expect(config.products[0].link == "http://product1")
    #expect(config.products[0].title == "$3")
    #expect(config.products[0].link == "http://product1")
  }

  @Test
  func emptyProducts() throws {
    mockSettings.productsConfiguration = """
  {
    "placePagePrompt": "Please donate",
    "aboutScreenPrompt": "Please donate",
    "products": []
  }
  """
    #expect(throws: ProductError.productsAreEmpty ) {
      try productsManager.fetchProductsConfiguration(for: .placePage)
    }
  }
  @Test
  func missedProductsConfig() throws {
    mockSettings.productsConfiguration = nil
    #expect(throws: ProductError.missedProductsConfig, performing: {
      try productsManager.fetchProductsConfiguration(for: .placePage)
    })
  }

  @Test
  func productsDisabled() throws {
    mockSettings.isProductsEnabled = false
    #expect(try productsManager.fetchProductsConfiguration(for: .placePage) == nil)
  }

  @Test
  func closedTimeNotExpired() throws {
    mockSettings.productsDialogClosedTime = Date().timeIntervalSince1970 - 1
    #expect(try productsManager.fetchProductsConfiguration(for: .placePage) == nil)
  }

  @Test
  func closedTimeExpired() throws {
    mockSettings.productsDialogClosedTime = 1
    #expect(try productsManager.fetchProductsConfiguration(for: .placePage) != nil)
  }

  @Test
  func launchTimeNotExpired() throws {
    mockSettings.launchTime = Date().timeIntervalSince1970 - 1
    #expect(try productsManager.fetchProductsConfiguration(for: .placePage) == nil)
  }

  @Test
  func launchTimeExpired() throws {
    mockSettings.launchTime = 1
    #expect(try productsManager.fetchProductsConfiguration(for: .placePage) != nil)
  }

  @Test
  func closeActionIsCalled() throws {
    let lastClosedTime = mockSettings.productsDialogClosedTime
    productsManager.handleProductAction(.closeDialog, from: .placePage)
    #expect(mockSettings.productsDialogClosedTime > lastClosedTime)
    #expect(try productsManager.fetchProductsConfiguration(for: .placePage) == nil)
  }

  @Test
  func openURLActionIsCalled() throws {
    let product = Product(title: "$3", link: "http://product1")
    let lastClosedTime = mockSettings.productsDialogClosedTime
    productsManager.handleProductAction(.openProduct(product), from: .placePage)
    #expect(mockSettings.productsDialogClosedTime > lastClosedTime)
  }
}

// MARK: - Mock Settings

fileprivate class MockProductsSettings: NSObject, ProductsSettings {
  var isProductsEnabled: Bool = true
  var productsConfiguration: String?
  var productsDialogClosedTime: TimeInterval = 0
  var launchTime: TimeInterval = 0
  var setProductsDialogClosedCalled = false

  static var `default` = MockProductsSettings()

  static func isProductsEnabled() -> Bool {
    Self.default.isProductsEnabled
  }

  static func getProductsConfiguration() -> String? {
    Self.default.productsConfiguration
  }

  static func productsDialogClosedTime() -> TimeInterval {
    Self.default.productsDialogClosedTime
  }

  static func launchTime() -> TimeInterval {
    Self.default.launchTime
  }
  static func setProductsDialogClosed() {
    Self.default.productsDialogClosedTime = Date().timeIntervalSince1970
  }
}
