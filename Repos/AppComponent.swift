import SwiftData
import Platform
import PlatformImpl
import Usecase
import UsecaseImpl
import Entity
import Search
import SearchImpl
import SharedPackage

@MainActor
final class AppComponent: SearchDependency {
    // MARK: - Platform
    let networkClient: NetworkClient = NetworkClientImpl()
    lazy var searchRepository: SearchRepository = SearchRepositoryImpl(networkClient: networkClient)
    let recentSearchPersistence: RecentSearchPersistence

    // MARK: - Domain
    lazy var searchRepositoriesUseCase: SearchRepositoriesUseCase = SearchRepositoriesUseCaseImpl(
        searchRepository: searchRepository
    )
    lazy var recentSearchesUseCase: RecentSearchesUseCase = RecentSearchesUseCaseImpl(
        persistence: recentSearchPersistence
    )

    // MARK: - Feature
    lazy var searchBuildable: SearchBuildable = SearchBuilder(dependency: self)

    init() {
        let container = try! ModelContainer(for: RecentSearchRecord.self)
        self.recentSearchPersistence = RecentSearchPersistenceImpl(container: container)
    }
}
