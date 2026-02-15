import Entity
import Foundation
import Platform
import PlatformTestSupport
import Testing
@testable import UsecaseImpl

@Suite
struct SearchRepositoriesUseCaseImplTests {

  // MARK: - Helpers

  private typealias SearchResult = (
    totalCount: Int,
    items: [(id: Int, name: String, htmlURL: String, ownerLogin: String, ownerAvatarURL: String)]
  )

  private static func makeSUT(
    searchHandler: (@Sendable (String, Int) async throws -> SearchResult)? = nil
  ) -> (sut: SearchRepositoriesUseCaseImpl, mock: SearchRepositoryMock) {
    let mock = SearchRepositoryMock()
    if let handler = searchHandler {
      mock.searchHandler = handler
    }
    let sut = SearchRepositoriesUseCaseImpl(searchRepository: mock)
    return (sut, mock)
  }

  // MARK: - execute success mapping

  @Test
  func execute_success_mapsDTOToEntity() async throws {
    // given
    let (sut, mock) = Self.makeSUT { _, _ in
      (
        totalCount: 42,
        items: [(
          id: 1,
          name: "swift-repo",
          htmlURL: "https://github.com/apple/swift",
          ownerLogin: "apple",
          ownerAvatarURL: "https://avatars.githubusercontent.com/u/1"
        )]
      )
    }

    // when
    let result = try await sut.execute(query: "swift", page: 1)

    // then
    #expect(result.totalCount == 42)
    #expect(result.items.count == 1)

    let entity = result.items[0]
    #expect(entity.id == 1)
    #expect(entity.name == "swift-repo")
    #expect(entity.htmlURL == "https://github.com/apple/swift")
    #expect(entity.ownerLogin == "apple")
    #expect(entity.ownerAvatarURL == "https://avatars.githubusercontent.com/u/1")

    #expect(mock.searchCallCount == 1)
  }

  // MARK: - execute empty results

  @Test
  func execute_emptyResults_returnsEmptyEntities() async throws {
    // given
    let (sut, mock) = Self.makeSUT { _, _ in
      (totalCount: 0, items: [])
    }

    // when
    let result = try await sut.execute(query: "nonexistent-xyz", page: 1)

    // then
    #expect(result.totalCount == 0)
    #expect(result.items.isEmpty)
    #expect(mock.searchCallCount == 1)
  }

  // MARK: - execute error propagation

  @Test
  func execute_networkError_throws() async throws {
    // given
    let (sut, mock) = Self.makeSUT { _, _ in
      throw TestError.networkFailed
    }

    // when / then
    await #expect(throws: TestError.networkFailed) {
      try await sut.execute(query: "swift", page: 1)
    }
    #expect(mock.searchCallCount == 1)
  }

  // MARK: - execute multiple items

  @Test
  func execute_multipleItems_mapsAllCorrectly() async throws {
    // given
    let (sut, _) = Self.makeSUT { _, _ in
      (totalCount: 100, items: [
        (
          id: 1,
          name: "repo-alpha",
          htmlURL: "https://github.com/org/repo-alpha",
          ownerLogin: "org",
          ownerAvatarURL: "https://avatars.example.com/org"
        ),
        (
          id: 2,
          name: "repo-beta",
          htmlURL: "https://github.com/user/repo-beta",
          ownerLogin: "user",
          ownerAvatarURL: "https://avatars.example.com/user"
        ),
        (
          id: 3,
          name: "repo-gamma",
          htmlURL: "https://github.com/team/repo-gamma",
          ownerLogin: "team",
          ownerAvatarURL: "https://avatars.example.com/team"
        ),
      ])
    }

    // when
    let result = try await sut.execute(query: "repo", page: 2)

    // then
    #expect(result.totalCount == 100)
    #expect(result.items == [
      RepositoryEntity(
        id: 1,
        name: "repo-alpha",
        htmlURL: "https://github.com/org/repo-alpha",
        ownerLogin: "org",
        ownerAvatarURL: "https://avatars.example.com/org"
      ),
      RepositoryEntity(
        id: 2,
        name: "repo-beta",
        htmlURL: "https://github.com/user/repo-beta",
        ownerLogin: "user",
        ownerAvatarURL: "https://avatars.example.com/user"
      ),
      RepositoryEntity(
        id: 3,
        name: "repo-gamma",
        htmlURL: "https://github.com/team/repo-gamma",
        ownerLogin: "team",
        ownerAvatarURL: "https://avatars.example.com/team"
      ),
    ])
  }

  // MARK: - execute passes correct query and page

  @Test
  func execute_passesCorrectQueryAndPage() async throws {
    // given
    nonisolated(unsafe) var capturedQuery: String?
    nonisolated(unsafe) var capturedPage: Int?
    let (sut, mock) = Self.makeSUT { query, page in
      capturedQuery = query
      capturedPage = page
      return (totalCount: 0, items: [])
    }

    // when
    _ = try await sut.execute(query: "SwiftUI", page: 5)

    // then
    #expect(mock.searchCallCount == 1)
    #expect(capturedQuery == "SwiftUI")
    #expect(capturedPage == 5)
  }
}

// MARK: - Test Helpers

private enum TestError: Error, Equatable {
  case networkFailed
}
