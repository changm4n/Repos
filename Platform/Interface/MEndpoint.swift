import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public protocol MEndpoint: Sendable {
    var path: String { get }
    var method: HTTPMethod { get }
    var body: (any Encodable & Sendable)? { get }
    var queryItems: [URLQueryItem]? { get }
}

public extension MEndpoint {
    var body: (any Encodable & Sendable)? { nil }
    var queryItems: [URLQueryItem]? { nil }
}
