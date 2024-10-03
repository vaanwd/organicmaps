import XCTest
@testable import Organic_Maps__Debug_

final class ProductsManagerTests: XCTestCase {
  private var productsManager: ProductsManager!
  private var mockSettings: MockProductsSettings!

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

  override func setUpWithError() throws {
    super.setUp()
    let settings = MockProductsSettings()
    settings.productsConfiguration = Self.validProductsConfigJSON_1
    MockProductsSettings.default = settings
    mockSettings = settings
    productsManager = ProductsManager(productsSettings: MockProductsSettings.self)
  }

  override func tearDownWithError() throws {
    productsManager = nil
    mockSettings = nil
    super.tearDown()
  }

  func testValidJSON() {
    let jsonStrings = [
      Self.validProductsConfigJSON_1,
      Self.validProductsConfigJSON_2
    ]

    for jsonString in jsonStrings {
      mockSettings.productsConfiguration = jsonString
      XCTAssertNoThrow(try productsManager.fetchProductsConfiguration(for: .placePage))
    }
  }

  func testInvalidJSON() {
    let jsonStrings = [
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
    ]

    for jsonString in jsonStrings {
      mockSettings.productsConfiguration = jsonString
      XCTAssertThrowsError(try productsManager.fetchProductsConfiguration(for: .placePage))
    }
  }

  func testJSONParsing() throws {
    let config = try XCTUnwrap(productsManager.fetchProductsConfiguration(for: .placePage))
    XCTAssertNotNil(config)
    XCTAssertFalse(config.products.isEmpty)
    XCTAssertEqual(config.placePagePrompt, "prompt1")
    XCTAssertEqual(config.aboutScreenPrompt, "prompt2")
    XCTAssertEqual(config.products[0].title, "$3")
    XCTAssertEqual(config.products[0].link, "http://product1")
  }

  func testEmptyProducts() {
    mockSettings.productsConfiguration = """
        {
          "placePagePrompt": "Please donate",
          "aboutScreenPrompt": "Please donate",
          "products": []
        }
        """
    XCTAssertThrowsError(try productsManager.fetchProductsConfiguration(for: .placePage)) { error in
      XCTAssertEqual(error as? ProductError, ProductError.productsAreEmpty)
    }
  }

  func testProductsDisabled() throws {
    mockSettings.isProductsEnabled = false
    XCTAssertNil(try productsManager.fetchProductsConfiguration(for: .placePage))
  }

  func testClosedTimeNotExpired() throws {
    mockSettings.productsDialogClosedTime = Date().timeIntervalSince1970 - 1
    XCTAssertNil(try productsManager.fetchProductsConfiguration(for: .placePage))
  }

  func testClosedTimeExpired() throws {
    mockSettings.productsDialogClosedTime = 1
    XCTAssertNotNil(try productsManager.fetchProductsConfiguration(for: .placePage))
  }

  func testLaunchTimeNotExpired() throws {
    mockSettings.launchTime = Date().timeIntervalSince1970 - 1
    XCTAssertNil(try productsManager.fetchProductsConfiguration(for: .placePage))
  }

  func testLaunchTimeExpired() throws {
    mockSettings.launchTime = 1
    XCTAssertNotNil(try productsManager.fetchProductsConfiguration(for: .placePage))
  }

  func testCloseActionIsCalled() throws {
    let lastClosedTime = mockSettings.productsDialogClosedTime
    productsManager.handleProductAction(.closeDialog, from: .placePage)
    XCTAssertGreaterThan(mockSettings.productsDialogClosedTime, lastClosedTime)
    XCTAssertNil(try productsManager.fetchProductsConfiguration(for: .placePage))
  }

  func testOpenURLActionIsCalled() throws {
    let product = Product(title: "$3", link: "http://product1")
    let lastClosedTime = mockSettings.productsDialogClosedTime
    productsManager.handleProductAction(.openProduct(product), from: .placePage)
    XCTAssertGreaterThan(mockSettings.productsDialogClosedTime, lastClosedTime)
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
