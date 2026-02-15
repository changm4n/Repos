import Entity

/// @mockable
public protocol SearchRepositoriesUseCase: Sendable {
    func execute(query: String, page: Int) async throws -> (totalCount: Int, items: [RepositoryEntity])
}
