import Foundation

/// @mockable
public protocol NetworkClient: Sendable {
  func request<T: Decodable & Sendable>(_ endpoint: MEndpoint, type: T.Type) async throws -> T
}
