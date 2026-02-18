import Foundation
import Testing
import WebView
import WebViewTestSupport
@testable import WebViewImpl

@MainActor
@Suite("WebViewModel")
struct WebViewViewModelTests {

  private let listenerMock = WebViewListenerMock()

  private func makeSUT(
    url: URL = URL(string: "https://github.com")!
  ) -> WebViewModel {
    WebViewModel(url: url, listener: listenerMock)
  }

  // MARK: - init

  @Test
  func init_setsURL() {
    let url = URL(string: "https://example.com")!
    let sut = makeSUT(url: url)

    #expect(sut.url == url)
    #expect(sut.title == "")
  }

  // MARK: - updateTitle

  @Test
  func updateTitle_updatesTitle() {
    let sut = makeSUT()

    sut.updateTitle("GitHub")

    #expect(sut.title == "GitHub")
  }

  @Test
  func updateTitle_canUpdateMultipleTimes() {
    let sut = makeSUT()

    sut.updateTitle("First")
    sut.updateTitle("Second")

    #expect(sut.title == "Second")
  }

  // MARK: - didTapClose

  @Test
  func didTapClose_callsListener() {
    let sut = makeSUT()

    sut.didTapClose()

    #expect(listenerMock.webViewDidCloseCallCount == 1)
  }

  @Test
  func didTapClose_calledMultipleTimes_incrementsCount() {
    let sut = makeSUT()

    sut.didTapClose()
    sut.didTapClose()

    #expect(listenerMock.webViewDidCloseCallCount == 2)
  }
}
