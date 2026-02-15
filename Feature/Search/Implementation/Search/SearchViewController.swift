import SharedPackage
import UIKit
import WebView

final class SearchViewController: UIViewController, SearchRouting, WebViewListener {
  private let viewModel: SearchViewModel
  private let webViewBuildable: WebViewBuildable

  init(viewModel: SearchViewModel, webViewBuildable: WebViewBuildable) {
    self.viewModel = viewModel
    self.webViewBuildable = webViewBuildable
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError() }

  override func viewDidLoad() {
    super.viewDidLoad()
    SearchView(viewModel: viewModel).attach(to: self)
  }

  // MARK: - Routing

  func attachWebView(url: URL) {
    let webViewVC = webViewBuildable.build(url: url, listener: self)
    present(webViewVC, animated: true)
  }

  // MARK: - Private

  private func detachSheet() {
    dismiss(animated: true)
  }

  // MARK: - WebViewListener

  func webViewDidClose() {
    detachSheet()
  }
}
