import UIKit
import Usecase
import Search
import SharedPackage

public protocol SearchDependency {
    var searchRepositoriesUseCase: SearchRepositoriesUseCase { get }
    var recentSearchesUseCase: RecentSearchesUseCase { get }
}

public final class SearchBuilder: Builder<SearchDependency>, SearchBuildable {
    public func build(listener: SearchListener) -> UIViewController {
        let viewModel = SearchViewModel(
            listener: listener,
            searchRepositoriesUseCase: dependency.searchRepositoriesUseCase,
            recentSearchesUseCase: dependency.recentSearchesUseCase
        )
        let viewController = SearchViewController(viewModel: viewModel)
        viewModel.router = viewController
        return viewController
    }
}
