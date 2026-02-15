import Foundation
import Platform
import SwiftData
import Testing
@testable import PlatformImpl

@Suite("RecentSearchPersistenceImpl")
@MainActor
struct RecentSearchPersistenceImplTests {

  private func makeSUT() throws -> RecentSearchPersistenceImpl {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: RecentSearchRecord.self, configurations: config)
    return RecentSearchPersistenceImpl(container: container)
  }

  // MARK: - fetchAll

  @Test
  func fetchAll_returnsEmptyArrayWhenNoRecordsExist() async throws {
    // given
    let sut = try makeSUT()

    // when
    let results = try await sut.fetchAll()

    // then
    #expect(results.isEmpty)
  }

  @Test
  func fetchAll_returnsSavedKeyword() async throws {
    // given
    let sut = try makeSUT()
    try await sut.save(keyword: "swift")

    // when
    let results = try await sut.fetchAll()

    // then
    #expect(results.count == 1)
    #expect(results[0].keyword == "swift")
  }

  @Test
  func fetchAll_returnsSortedBySearchedAtDescending() async throws {
    // given
    let sut = try makeSUT()
    try await sut.save(keyword: "oldest")
    try await Task.yield()
    try await sut.save(keyword: "middle")
    try await Task.yield()
    try await sut.save(keyword: "newest")

    // when
    let results = try await sut.fetchAll()

    // then
    #expect(results.count == 3)
    #expect(results[0].keyword == "newest")
    #expect(results[1].keyword == "middle")
    #expect(results[2].keyword == "oldest")
  }

  @Test
  func fetchAll_returnsMaximum10Results() async throws {
    // given
    let sut = try makeSUT()
    for i in 1...15 {
      try await sut.save(keyword: "keyword\(i)")
    }

    // when
    let results = try await sut.fetchAll()

    // then
    #expect(results.count == 10)
  }

  // MARK: - save

  @Test
  func save_withEmptyKeyword_doesNothing() async throws {
    // given
    let sut = try makeSUT()

    // when
    try await sut.save(keyword: "")

    // then
    let results = try await sut.fetchAll()
    #expect(results.isEmpty)
  }

  @Test
  func save_withWhitespaceOnlyKeyword_doesNothing() async throws {
    // given
    let sut = try makeSUT()

    // when
    try await sut.save(keyword: "   ")

    // then
    let results = try await sut.fetchAll()
    #expect(results.isEmpty)
  }

  @Test
  func save_duplicateKeyword_updatesSearchedAt() async throws {
    // given
    let sut = try makeSUT()
    try await sut.save(keyword: "swift")
    let firstResults = try await sut.fetchAll()
    let firstDate = firstResults[0].searchedAt

    // Allow time to pass so the timestamp differs
    try await Task.sleep(for: .milliseconds(50))

    // when
    try await sut.save(keyword: "swift")

    // then
    let results = try await sut.fetchAll()
    #expect(results.count == 1)
    #expect(results[0].keyword == "swift")
    #expect(results[0].searchedAt >= firstDate)
  }

  @Test
  func save_enforcesMaximum10ItemsByRemovingOldest() async throws {
    // given
    let sut = try makeSUT()
    for i in 1...10 {
      try await sut.save(keyword: "keyword\(i)")
    }

    // when - save 11th keyword
    try await sut.save(keyword: "keyword11")

    // then
    let results = try await sut.fetchAll()
    #expect(results.count == 10)
    #expect(results[0].keyword == "keyword11")

    let allKeywords = results.map(\.keyword)
    #expect(!allKeywords.contains("keyword1"))
  }

  // MARK: - delete

  @Test
  func delete_removesSpecificKeyword() async throws {
    // given
    let sut = try makeSUT()
    try await sut.save(keyword: "swift")
    try await sut.save(keyword: "kotlin")

    // when
    try await sut.delete(keyword: "swift")

    // then
    let results = try await sut.fetchAll()
    #expect(results.count == 1)
    #expect(results[0].keyword == "kotlin")
  }

  @Test
  func delete_withNonExistentKeyword_doesNotCrash() async throws {
    // given
    let sut = try makeSUT()
    try await sut.save(keyword: "swift")

    // when
    try await sut.delete(keyword: "nonexistent")

    // then
    let results = try await sut.fetchAll()
    #expect(results.count == 1)
    #expect(results[0].keyword == "swift")
  }

  // MARK: - deleteAll

  @Test
  func deleteAll_removesAllRecords() async throws {
    // given
    let sut = try makeSUT()
    try await sut.save(keyword: "swift")
    try await sut.save(keyword: "kotlin")
    try await sut.save(keyword: "rust")

    // when
    try await sut.deleteAll()

    // then
    let results = try await sut.fetchAll()
    #expect(results.isEmpty)
  }
}
