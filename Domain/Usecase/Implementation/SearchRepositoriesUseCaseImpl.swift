import Entity
import Platform
import Usecase

public final class SearchRepositoriesUseCaseImpl: SearchRepositoriesUseCase {
  private let searchRepository: SearchRepository

  public init(searchRepository: SearchRepository) {
    self.searchRepository = searchRepository
  }

  public func execute(query: String, page: Int) async throws -> (totalCount: Int, items: [RepositoryEntity]) {
    let result = try await searchRepository.search(query: query, page: page)
    let entities = result.items.map { item in
      RepositoryEntity(
        id: item.id,
        name: item.name,
        htmlURL: item.htmlURL,
        ownerLogin: item.ownerLogin,
        ownerAvatarURL: item.ownerAvatarURL
      )
    }
    return (totalCount: result.totalCount, items: entities)
  }
}
