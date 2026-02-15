import Foundation
import Platform

public enum SearchEndpoint: Sendable {
  case searchRepositories(query: String, page: Int)
}

extension SearchEndpoint: MEndpoint {
  public var path: String {
    switch self {
    case .searchRepositories:
      return "/search/repositories"
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .searchRepositories:
      return .get
    }
  }

  public var queryItems: [URLQueryItem]? {
    switch self {
    case .searchRepositories(let query, let page):
      return [
        URLQueryItem(name: "q", value: query),
        URLQueryItem(name: "page", value: String(page)),
      ]
    }
  }
}
