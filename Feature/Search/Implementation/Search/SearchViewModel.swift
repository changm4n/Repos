import UIKit
import Usecase
import Entity
import Search

@MainActor
protocol SearchRouting: AnyObject {
    func attachChild(viewController: UIViewController)
    func detachChild()
    func attachSheet(viewController: UIViewController)
    func detachSheet()
}

enum SearchPhase {
    case idle
    case searching
    case results
}

@MainActor
@Observable
final class SearchViewModel {
    // MARK: - State
    var searchText: String = ""
    var isSearchBarFocused: Bool = false
    var searchPhase: SearchPhase = .idle
    var repositories: [RepositoryEntity] = []
    var totalCount: Int = 0
    var currentPage: Int = 1
    var isLoadingMore: Bool = false
    var recentSearches: [RecentSearchEntity] = []
    var selectedRepository: RepositoryEntity?

    var hasMorePages: Bool {
        repositories.count < totalCount
    }

    var filteredRecentSearches: [RecentSearchEntity] {
        guard !searchText.isEmpty else { return recentSearches }
        return recentSearches.filter {
            $0.keyword.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Dependencies
    weak var router: SearchRouting?
    private let listener: SearchListener
    private let searchRepositoriesUseCase: SearchRepositoriesUseCase
    private let recentSearchesUseCase: RecentSearchesUseCase

    init(
        listener: SearchListener,
        searchRepositoriesUseCase: SearchRepositoriesUseCase,
        recentSearchesUseCase: RecentSearchesUseCase
    ) {
        self.listener = listener
        self.searchRepositoriesUseCase = searchRepositoriesUseCase
        self.recentSearchesUseCase = recentSearchesUseCase
    }

    // MARK: - Actions

    func loadRecentSearches() async {
        do {
            recentSearches = try await recentSearchesUseCase.fetchAll()
        } catch {}
    }

    func search() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        searchPhase = .searching
        currentPage = 1
        repositories = []

        do {
            try await recentSearchesUseCase.save(keyword: query)
            let result = try await searchRepositoriesUseCase.execute(query: query, page: currentPage)
            repositories = result.items
            totalCount = result.totalCount
            searchPhase = .results
            await loadRecentSearches()
        } catch {
            searchPhase = .results
        }
    }

    func loadNextPage() async {
        guard hasMorePages, !isLoadingMore else { return }
        isLoadingMore = true
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let nextPage = currentPage + 1

        do {
            let result = try await searchRepositoriesUseCase.execute(query: query, page: nextPage)
            repositories.append(contentsOf: result.items)
            totalCount = result.totalCount
            currentPage = nextPage
        } catch {}

        isLoadingMore = false
    }

    func selectRecentSearch(keyword: String) async {
        searchText = keyword
        await search()
    }

    func deleteRecentSearch(keyword: String) async {
        do {
            try await recentSearchesUseCase.delete(keyword: keyword)
            await loadRecentSearches()
        } catch {}
    }

    func deleteAllRecentSearches() async {
        do {
            try await recentSearchesUseCase.deleteAll()
            await loadRecentSearches()
        } catch {}
    }

    func clearSearch() {
        searchText = ""
        repositories = []
        totalCount = 0
        searchPhase = .idle
    }

    func cancel() {
        searchText = ""
        repositories = []
        totalCount = 0
        searchPhase = .idle
        isSearchBarFocused = false
    }

    func selectRepository(_ repository: RepositoryEntity) {
        selectedRepository = repository
    }
}
