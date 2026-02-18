import Foundation

public enum HTTPMethod: String, Sendable {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case delete = "DELETE"
}

public protocol Endpoint: Sendable {
  var path: String { get }
  var method: HTTPMethod { get }
  var body: (any Encodable & Sendable)? { get }
  var queryItems: [URLQueryItem]? { get }
}

extension Endpoint {
  public var body: (any Encodable & Sendable)? { nil }
  public var queryItems: [URLQueryItem]? { nil }
}
