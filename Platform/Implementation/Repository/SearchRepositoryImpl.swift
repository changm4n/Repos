import Foundation
import Platform

public final class SearchRepositoryImpl: SearchRepository {
  private let networkClient: NetworkClient

  public init(networkClient: NetworkClient) {
    self.networkClient = networkClient
  }

  public func search(query: String, page: Int) async throws -> (totalCount: Int, items: [(
    id: Int,
    name: String,
    htmlURL: String,
    ownerLogin: String,
    ownerAvatarURL: String
  )]) {
    let response = try await networkClient.request(
      SearchEndpoint.searchRepositories(query: query, page: page),
      type: SearchRepositoriesResponseDTO.self
    )
    let items = response.items.map { item in
      (
        id: item.id,
        name: item.name,
        htmlURL: item.htmlURL,
        ownerLogin: item.owner.login,
        ownerAvatarURL: item.owner.avatarURL
      )
    }
    return (totalCount: response.totalCount, items: items)
  }
}
