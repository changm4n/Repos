import Foundation

/// @mockable
public protocol RecentSearchPersistence: Sendable {
    func fetchAll() async throws -> [(keyword: String, searchedAt: Date)]
    func save(keyword: String) async throws
    func delete(keyword: String) async throws
    func deleteAll() async throws
}
