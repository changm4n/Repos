import Entity
import Foundation
import Search
import SearchTestSupport
import Testing
import UsecaseTestSupport
@testable import SearchImpl

// MARK: - Test Helpers

private actor QueryCapture {
  var value: String?
  func set(_ v: String) { value = v }
}

@MainActor
private final class SearchRoutingMock: SearchRouting {
  var attachWebViewCallCount = 0
  var attachWebViewURL: URL?

  func attachWebView(url: URL) {
    attachWebViewCallCount += 1
    attachWebViewURL = url
  }
}

// MARK: - Tests

@MainActor
@Suite("SearchViewModel")
struct SearchViewModelTests {

  private let listenerMock = SearchListenerMock()
  private let searchReposMock = SearchRepositoriesUseCaseMock()
  private let recentSearchesMock = RecentSearchesUseCaseMock()
  private let routerMock = SearchRoutingMock()

  private func makeSUT() -> SearchViewModel {
    let vm = SearchViewModel(
      listener: listenerMock,
      searchRepositoriesUseCase: searchReposMock,
      recentSearchesUseCase: recentSearchesMock
    )
    vm.router = routerMock
    return vm
  }

  private func makeRepo(id: Int = 1, name: String = "repo") -> RepositoryEntity {
    RepositoryEntity(
      id: id,
      name: name,
      htmlURL: "https://github.com/owner/\(name)",
      ownerLogin: "owner",
      ownerAvatarURL: "https://avatars.githubusercontent.com/u/1"
    )
  }

  private func makeRecentSearch(keyword: String = "swift") -> RecentSearchEntity {
    RecentSearchEntity(keyword: keyword, searchedAt: Date())
  }

  // MARK: - loadRecentSearches

  @Test
  func loadRecentSearches_setsRecentSearches() async {
    // given
    let sut = makeSUT()
    let expected = [makeRecentSearch(keyword: "swift"), makeRecentSearch(keyword: "kotlin")]
    recentSearchesMock.fetchAllHandler = { expected }

    // when
    await sut.loadRecentSearches()

    // then
    #expect(sut.recentSearches == expected)
    #expect(recentSearchesMock.fetchAllCallCount == 1)
  }

  @Test
  func loadRecentSearches_onError_keepsCurrentState() async {
    // given
    let sut = makeSUT()
    sut.recentSearches = [makeRecentSearch()]
    recentSearchesMock.fetchAllHandler = { throw CancellationError() }

    // when
    await sut.loadRecentSearches()

    // then — error is silently caught, existing state unchanged
    #expect(sut.recentSearches.count == 1)
  }

  // MARK: - search

  @Test
  func search_successfullyUpdatesState() async {
    // given
    let sut = makeSUT()
    sut.searchText = "swift"
    let repos = [makeRepo(id: 1, name: "swift"), makeRepo(id: 2, name: "swift-nio")]
    searchReposMock.executeHandler = { _, _ in (totalCount: 10, items: repos) }
    recentSearchesMock.fetchAllHandler = { [] }

    // when
    await sut.search()

    // then
    #expect(sut.searchPhase == .results)
    #expect(sut.repositories == repos)
    #expect(sut.totalCount == 10)
    #expect(sut.currentPage == 1)
    #expect(recentSearchesMock.saveCallCount == 1)
    #expect(searchReposMock.executeCallCount == 1)
  }

  @Test
  func search_emptyQuery_doesNothing() async {
    // given
    let sut = makeSUT()
    sut.searchText = "   "

    // when
    await sut.search()

    // then
    #expect(sut.searchPhase == .idle)
    #expect(searchReposMock.executeCallCount == 0)
  }

  @Test
  func search_onError_setsPhaseToResults() async {
    // given
    let sut = makeSUT()
    sut.searchText = "swift"
    searchReposMock.executeHandler = { _, _ in throw CancellationError() }

    // when
    await sut.search()

    // then
    #expect(sut.searchPhase == .results)
    #expect(sut.repositories.isEmpty)
  }

  @Test
  func search_trimsWhitespace() async {
    // given
    let sut = makeSUT()
    sut.searchText = "  swift  "
    let capture = QueryCapture()
    searchReposMock.executeHandler = { query, _ in
      await capture.set(query)
      return (totalCount: 0, items: [])
    }
    recentSearchesMock.fetchAllHandler = { [] }

    // when
    await sut.search()

    // then
    let captured = await capture.value
    #expect(captured == "swift")
  }

  // MARK: - loadNextPage

  @Test
  func loadNextPage_appendsResults() async {
    // given
    let sut = makeSUT()
    sut.searchText = "swift"
    let firstPage = [makeRepo(id: 1)]
    sut.repositories = firstPage
    sut.totalCount = 10
    sut.currentPage = 1

    let secondPage = [makeRepo(id: 2)]
    searchReposMock.executeHandler = { _, page in
      #expect(page == 2)
      return (totalCount: 10, items: secondPage)
    }

    // when
    await sut.loadNextPage()

    // then
    #expect(sut.repositories.count == 2)
    #expect(sut.currentPage == 2)
    #expect(sut.isLoadingMore == false)
  }

  @Test
  func loadNextPage_noMorePages_doesNothing() async {
    // given
    let sut = makeSUT()
    sut.repositories = [makeRepo()]
    sut.totalCount = 1

    // when
    await sut.loadNextPage()

    // then
    #expect(searchReposMock.executeCallCount == 0)
  }

  @Test
  func loadNextPage_alreadyLoading_doesNothing() async {
    // given
    let sut = makeSUT()
    sut.totalCount = 10
    sut.isLoadingMore = true

    // when
    await sut.loadNextPage()

    // then
    #expect(searchReposMock.executeCallCount == 0)
  }

  // MARK: - selectRecentSearch

  @Test
  func selectRecentSearch_setsTextAndSearches() async {
    // given
    let sut = makeSUT()
    searchReposMock.executeHandler = { _, _ in (totalCount: 0, items: []) }
    recentSearchesMock.fetchAllHandler = { [] }

    // when
    await sut.selectRecentSearch(keyword: "kotlin")

    // then
    #expect(sut.searchText == "kotlin")
    #expect(searchReposMock.executeCallCount == 1)
  }

  // MARK: - deleteRecentSearch

  @Test
  func deleteRecentSearch_callsUseCaseAndReloads() async {
    // given
    let sut = makeSUT()
    recentSearchesMock.fetchAllHandler = { [] }

    // when
    await sut.deleteRecentSearch(keyword: "swift")

    // then
    #expect(recentSearchesMock.deleteCallCount == 1)
    #expect(recentSearchesMock.fetchAllCallCount == 1)
  }

  // MARK: - deleteAllRecentSearches

  @Test
  func deleteAllRecentSearches_callsUseCaseAndReloads() async {
    // given
    let sut = makeSUT()
    recentSearchesMock.fetchAllHandler = { [] }

    // when
    await sut.deleteAllRecentSearches()

    // then
    #expect(recentSearchesMock.deleteAllCallCount == 1)
    #expect(recentSearchesMock.fetchAllCallCount == 1)
  }

  // MARK: - clearSearch

  @Test
  func clearSearch_resetsState() {
    // given
    let sut = makeSUT()
    sut.searchText = "swift"
    sut.repositories = [makeRepo()]
    sut.totalCount = 10
    sut.searchPhase = .results

    // when
    sut.clearSearch()

    // then
    #expect(sut.searchText == "")
    #expect(sut.repositories.isEmpty)
    #expect(sut.totalCount == 0)
    #expect(sut.searchPhase == .idle)
  }

  // MARK: - cancel

  @Test
  func cancel_resetsStateAndFocus() {
    // given
    let sut = makeSUT()
    sut.searchText = "swift"
    sut.repositories = [makeRepo()]
    sut.totalCount = 10
    sut.searchPhase = .results
    sut.isSearchBarFocused = true

    // when
    sut.cancel()

    // then
    #expect(sut.searchText == "")
    #expect(sut.repositories.isEmpty)
    #expect(sut.totalCount == 0)
    #expect(sut.searchPhase == .idle)
    #expect(sut.isSearchBarFocused == false)
  }

  // MARK: - selectRepository

  @Test
  func selectRepository_callsRouterWithURL() {
    // given
    let sut = makeSUT()
    let repo = makeRepo(id: 1, name: "swift")

    // when
    sut.selectRepository(repo)

    // then
    #expect(routerMock.attachWebViewCallCount == 1)
    #expect(routerMock.attachWebViewURL?.absoluteString == "https://github.com/owner/swift")
  }

  @Test
  func selectRepository_invalidURL_doesNotCallRouter() {
    // given
    let sut = makeSUT()
    let repo = RepositoryEntity(
      id: 1,
      name: "bad",
      htmlURL: "",
      ownerLogin: "owner",
      ownerAvatarURL: ""
    )

    // when
    sut.selectRepository(repo)

    // then
    #expect(routerMock.attachWebViewCallCount == 0)
  }

  // MARK: - hasMorePages

  @Test
  func hasMorePages_returnsTrue_whenMorePagesAvailable() {
    let sut = makeSUT()
    sut.repositories = [makeRepo()]
    sut.totalCount = 10

    #expect(sut.hasMorePages == true)
  }

  @Test
  func hasMorePages_returnsFalse_whenAllLoaded() {
    let sut = makeSUT()
    sut.repositories = [makeRepo()]
    sut.totalCount = 1

    #expect(sut.hasMorePages == false)
  }

  // MARK: - filteredRecentSearches

  @Test
  func filteredRecentSearches_emptyText_returnsAll() {
    let sut = makeSUT()
    sut.searchText = ""
    sut.recentSearches = [makeRecentSearch(keyword: "swift"), makeRecentSearch(keyword: "kotlin")]

    #expect(sut.filteredRecentSearches.count == 2)
  }

  @Test
  func filteredRecentSearches_filtersMatchingKeywords() {
    let sut = makeSUT()
    sut.searchText = "swi"
    sut.recentSearches = [makeRecentSearch(keyword: "swift"), makeRecentSearch(keyword: "kotlin")]

    #expect(sut.filteredRecentSearches.count == 1)
    #expect(sut.filteredRecentSearches.first?.keyword == "swift")
  }
}
