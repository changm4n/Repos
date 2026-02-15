import UIKit

/// @mockable
@MainActor
public protocol WebViewBuildable {
  func build(url: URL, listener: WebViewListener) -> UIViewController
}

/// @mockable
@MainActor
public protocol WebViewListener: AnyObject {
  func webViewDidClose()
}
