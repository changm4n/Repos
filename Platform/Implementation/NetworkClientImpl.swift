import Foundation
import Platform

public final class NetworkClientImpl: NetworkClient, @unchecked Sendable {
  private let session: URLSession
  private let host: String

  public init(session: URLSession = .shared, host: String = "https://api.github.com") {
    self.session = session
    self.host = host
  }

  public func request<T: Decodable & Sendable>(_ endpoint: MEndpoint, type: T.Type) async throws -> T {
    var components = URLComponents(string: host + endpoint.path)!
    components.queryItems = endpoint.queryItems

    var request = URLRequest(url: components.url!)
    request.httpMethod = endpoint.method.rawValue
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    if let body = endpoint.body {
      request.httpBody = try JSONEncoder().encode(body)
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    let (data, _) = try await session.data(for: request)
    return try JSONDecoder().decode(T.self, from: data)
  }
}
