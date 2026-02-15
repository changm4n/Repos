import Entity
import Foundation
import Platform
import PlatformTestSupport
import Testing
@testable import UsecaseImpl

@Suite
struct RecentSearchesUseCaseImplTests {

  // MARK: - fetchAll

  @Test
  func fetchAll_success_mapsRecordsToEntities() async throws {
    // given
    let date1 = Date(timeIntervalSince1970: 1_000_000)
    let date2 = Date(timeIntervalSince1970: 2_000_000)
    let mockPersistence = RecentSearchPersistenceMock()
    mockPersistence.fetchAllHandler = {
      [
        (keyword: "swift", searchedAt: date1),
        (keyword: "iOS", searchedAt: date2),
      ]
    }
    let sut = RecentSearchesUseCaseImpl(persistence: mockPersistence)

    // when
    let result = try await sut.fetchAll()

    // then
    #expect(result.count == 2)
    #expect(result[0] == RecentSearchEntity(keyword: "swift", searchedAt: date1))
    #expect(result[1] == RecentSearchEntity(keyword: "iOS", searchedAt: date2))
    #expect(mockPersistence.fetchAllCallCount == 1)
  }

  @Test
  func fetchAll_emptyRecords_returnsEmptyArray() async throws {
    // given
    let mockPersistence = RecentSearchPersistenceMock()
    mockPersistence.fetchAllHandler = {
      []
    }
    let sut = RecentSearchesUseCaseImpl(persistence: mockPersistence)

    // when
    let result = try await sut.fetchAll()

    // then
    #expect(result.isEmpty)
    #expect(mockPersistence.fetchAllCallCount == 1)
  }

  @Test
  func fetchAll_error_throws() async throws {
    // given
    let mockPersistence = RecentSearchPersistenceMock()
    mockPersistence.fetchAllHandler = {
      throw TestError.persistenceFailed
    }
    let sut = RecentSearchesUseCaseImpl(persistence: mockPersistence)

    // when / then
    await #expect(throws: TestError.persistenceFailed) {
      try await sut.fetchAll()
    }
    #expect(mockPersistence.fetchAllCallCount == 1)
  }

  // MARK: - save

  @Test
  func save_delegatesToPersistence() async throws {
    // given
    let captured = SendableBox<String?>()
    let mockPersistence = RecentSearchPersistenceMock()
    mockPersistence.saveHandler = { keyword in
      captured.value = keyword
    }
    let sut = RecentSearchesUseCaseImpl(persistence: mockPersistence)

    // when
    try await sut.save(keyword: "swift")

    // then
    #expect(captured.value == "swift")
    #expect(mockPersistence.saveCallCount == 1)
  }

  @Test
  func save_error_throws() async throws {
    // given
    let mockPersistence = RecentSearchPersistenceMock()
    mockPersistence.saveHandler = { _ in
      throw TestError.persistenceFailed
    }
    let sut = RecentSearchesUseCaseImpl(persistence: mockPersistence)

    // when / then
    await #expect(throws: TestError.persistenceFailed) {
      try await sut.save(keyword: "swift")
    }
    #expect(mockPersistence.saveCallCount == 1)
  }

  // MARK: - delete

  @Test
  func delete_delegatesToPersistence() async throws {
    // given
    let captured = SendableBox<String?>()
    let mockPersistence = RecentSearchPersistenceMock()
    mockPersistence.deleteHandler = { keyword in
      captured.value = keyword
    }
    let sut = RecentSearchesUseCaseImpl(persistence: mockPersistence)

    // when
    try await sut.delete(keyword: "iOS")

    // then
    #expect(captured.value == "iOS")
    #expect(mockPersistence.deleteCallCount == 1)
  }

  @Test
  func delete_error_throws() async throws {
    // given
    let mockPersistence = RecentSearchPersistenceMock()
    mockPersistence.deleteHandler = { _ in
      throw TestError.persistenceFailed
    }
    let sut = RecentSearchesUseCaseImpl(persistence: mockPersistence)

    // when / then
    await #expect(throws: TestError.persistenceFailed) {
      try await sut.delete(keyword: "iOS")
    }
    #expect(mockPersistence.deleteCallCount == 1)
  }

  // MARK: - deleteAll

  @Test
  func deleteAll_delegatesToPersistence() async throws {
    // given
    let mockPersistence = RecentSearchPersistenceMock()
    mockPersistence.deleteAllHandler = {}
    let sut = RecentSearchesUseCaseImpl(persistence: mockPersistence)

    // when
    try await sut.deleteAll()

    // then
    #expect(mockPersistence.deleteAllCallCount == 1)
  }

  @Test
  func deleteAll_error_throws() async throws {
    // given
    let mockPersistence = RecentSearchPersistenceMock()
    mockPersistence.deleteAllHandler = {
      throw TestError.persistenceFailed
    }
    let sut = RecentSearchesUseCaseImpl(persistence: mockPersistence)

    // when / then
    await #expect(throws: TestError.persistenceFailed) {
      try await sut.deleteAll()
    }
    #expect(mockPersistence.deleteAllCallCount == 1)
  }
}

// MARK: - Test Helpers

private enum TestError: Error, Equatable {
  case persistenceFailed
}

private final class SendableBox<T: Sendable>: @unchecked Sendable {
  var value: T

  init(_ value: T) {
    self.value = value
  }
}

extension SendableBox where T: ExpressibleByNilLiteral {
  convenience init() {
    self.init(nil)
  }
}
