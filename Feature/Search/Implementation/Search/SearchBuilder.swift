import Search
import SharedPackage
import UIKit
import Usecase
import WebView

public protocol SearchDependency {
  var searchRepositoriesUseCase: SearchRepositoriesUseCase { get }
  var recentSearchesUseCase: RecentSearchesUseCase { get }
  var webViewBuildable: WebViewBuildable { get }
}

public final class SearchBuilder: Builder<SearchDependency>, SearchBuildable {
  public func build(listener: SearchListener) -> UIViewController {
    let viewModel = SearchViewModel(
      listener: listener,
      searchRepositoriesUseCase: dependency.searchRepositoriesUseCase,
      recentSearchesUseCase: dependency.recentSearchesUseCase
    )
    let viewController = SearchViewController(
      viewModel: viewModel,
      webViewBuildable: dependency.webViewBuildable
    )
    viewModel.router = viewController
    return viewController
  }
}
