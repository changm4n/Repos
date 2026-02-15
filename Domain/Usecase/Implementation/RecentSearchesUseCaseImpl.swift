import Entity
import Usecase
import Platform

public final class RecentSearchesUseCaseImpl: RecentSearchesUseCase {
    private let persistence: RecentSearchPersistence

    public init(persistence: RecentSearchPersistence) {
        self.persistence = persistence
    }

    public func fetchAll() async throws -> [RecentSearchEntity] {
        let records = try await persistence.fetchAll()
        return records.map { RecentSearchEntity(keyword: $0.keyword, searchedAt: $0.searchedAt) }
    }

    public func save(keyword: String) async throws {
        try await persistence.save(keyword: keyword)
    }

    public func delete(keyword: String) async throws {
        try await persistence.delete(keyword: keyword)
    }

    public func deleteAll() async throws {
        try await persistence.deleteAll()
    }
}
