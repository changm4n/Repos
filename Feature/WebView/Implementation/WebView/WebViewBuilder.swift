import UIKit
import WebView

public final class WebViewBuilder: WebViewBuildable {
  public init() {}

  public func build(url: URL, listener: WebViewListener) -> UIViewController {
    let viewModel = WebViewModel(url: url, listener: listener)
    let viewController = WebViewViewController(viewModel: viewModel)
    return viewController
  }
}
