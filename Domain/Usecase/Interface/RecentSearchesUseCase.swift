import Entity

/// @mockable
public protocol RecentSearchesUseCase: Sendable {
  func fetchAll() async throws -> [RecentSearchEntity]
  func save(keyword: String) async throws
  func delete(keyword: String) async throws
  func deleteAll() async throws
}
