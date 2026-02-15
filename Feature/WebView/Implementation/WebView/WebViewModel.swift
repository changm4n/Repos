import Foundation
import WebView

@MainActor
@Observable
final class WebViewModel {
  // State
  let url: URL
  var title = ""

  // Dependencies
  private let listener: WebViewListener

  init(url: URL, listener: WebViewListener) {
    self.url = url
    self.listener = listener
  }

  // MARK: - Actions

  func updateTitle(_ title: String) {
    self.title = title
  }

  func didTapClose() {
    listener.webViewDidClose()
  }
}
