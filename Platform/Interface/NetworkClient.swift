import Foundation

/// @mockable
public protocol NetworkClient: Sendable {
  func request<T: Decodable & Sendable>(_ endpoint: Endpoint, type: T.Type) async throws -> T
}
