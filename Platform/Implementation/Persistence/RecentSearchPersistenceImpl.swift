import Foundation
import Platform
import SwiftData

public final actor RecentSearchPersistenceImpl: RecentSearchPersistence {
  private let container: ModelContainer

  public init(container: ModelContainer) {
    self.container = container
  }

  @MainActor
  public func fetchAll() async throws -> [(keyword: String, searchedAt: Date)] {
    let context = container.mainContext
    let descriptor = FetchDescriptor<RecentSearchRecord>(
      sortBy: [SortDescriptor(\.searchedAt, order: .reverse)]
    )
    let records = try context.fetch(descriptor)
    return Array(records.prefix(10)).map { ($0.keyword, $0.searchedAt) }
  }

  @MainActor
  public func save(keyword: String) async throws {
    let context = container.mainContext
    let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    // 기존 키워드가 있으면 시간만 갱신
    let descriptor = FetchDescriptor<RecentSearchRecord>(
      predicate: #Predicate { $0.keyword == trimmed }
    )
    if let existing = try context.fetch(descriptor).first {
      existing.searchedAt = .now
    } else {
      context.insert(RecentSearchRecord(keyword: trimmed))
    }

    // 10개 초과 시 오래된 것 삭제
    let allDescriptor = FetchDescriptor<RecentSearchRecord>(
      sortBy: [SortDescriptor(\.searchedAt, order: .reverse)]
    )
    let all = try context.fetch(allDescriptor)
    for record in all.dropFirst(10) {
      context.delete(record)
    }

    try context.save()
  }

  @MainActor
  public func delete(keyword: String) async throws {
    let context = container.mainContext
    let descriptor = FetchDescriptor<RecentSearchRecord>(
      predicate: #Predicate { $0.keyword == keyword }
    )
    if let record = try context.fetch(descriptor).first {
      context.delete(record)
      try context.save()
    }
  }

  @MainActor
  public func deleteAll() async throws {
    let context = container.mainContext
    try context.delete(model: RecentSearchRecord.self)
    try context.save()
  }
}
