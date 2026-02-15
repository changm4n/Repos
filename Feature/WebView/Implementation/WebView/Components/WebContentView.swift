import SwiftUI
import WebKit

struct WebContentView: UIViewRepresentable {
  let url: URL
  let onTitleChanged: (String) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onTitleChanged: onTitleChanged)
  }

  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.navigationDelegate = context.coordinator
    webView.load(URLRequest(url: url))
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {}
}

// MARK: - Coordinator

extension WebContentView {
  final class Coordinator: NSObject, WKNavigationDelegate {
    let onTitleChanged: (String) -> Void

    init(onTitleChanged: @escaping (String) -> Void) {
      self.onTitleChanged = onTitleChanged
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      webView.evaluateJavaScript("document.title") { [weak self] result, _ in
        if let title = result as? String, !title.isEmpty {
          Task { @MainActor in
            self?.onTitleChanged(title)
          }
        }
      }
    }
  }
}
