struct Product: Decodable {
  let title: String
  let link: String
}

struct ProductsConfiguration: Decodable {
  let placePagePrompt: String
  let aboutScreenPrompt: String
  let products: [Product]
}
