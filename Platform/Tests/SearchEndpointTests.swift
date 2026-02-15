import Testing
import Foundation
import Platform
import PlatformImpl

@Suite("SearchEndpoint")
struct SearchEndpointTests {

    // MARK: - path

    @Test
    func path_returnsSearchRepositoriesPath() {
        // given
        let sut = SearchEndpoint.searchRepositories(query: "swift", page: 1)

        // when
        let path = sut.path

        // then
        #expect(path == "/search/repositories")
    }

    // MARK: - method

    @Test
    func method_returnsGet() {
        // given
        let sut = SearchEndpoint.searchRepositories(query: "swift", page: 1)

        // when
        let method = sut.method

        // then
        #expect(method == .get)
    }

    // MARK: - queryItems

    @Test
    func queryItems_containsQueryAndPage() {
        // given
        let sut = SearchEndpoint.searchRepositories(query: "swift", page: 1)

        // when
        let queryItems = sut.queryItems

        // then
        #expect(queryItems != nil)
        #expect(queryItems?.count == 2)
        #expect(queryItems?.contains(URLQueryItem(name: "q", value: "swift")) == true)
        #expect(queryItems?.contains(URLQueryItem(name: "page", value: "1")) == true)
    }

    @Test(arguments: [
        ("swift", 1),
        ("iOS development", 5),
        ("", 0),
        ("language:kotlin stars:>100", 99),
    ])
    func queryItems_withVariousInputs(query: String, page: Int) {
        // given
        let sut = SearchEndpoint.searchRepositories(query: query, page: page)

        // when
        let queryItems = sut.queryItems

        // then
        #expect(queryItems != nil)

        let qItem = queryItems?.first(where: { $0.name == "q" })
        #expect(qItem?.value == query)

        let pageItem = queryItems?.first(where: { $0.name == "page" })
        #expect(pageItem?.value == String(page))
    }

    @Test
    func queryItems_queryParameterIsFirst_pageParameterIsSecond() {
        // given
        let sut = SearchEndpoint.searchRepositories(query: "test", page: 3)

        // when
        let queryItems = sut.queryItems

        // then
        #expect(queryItems?[0].name == "q")
        #expect(queryItems?[1].name == "page")
    }

    // MARK: - body

    @Test
    func body_returnsNil() {
        // given
        let sut = SearchEndpoint.searchRepositories(query: "swift", page: 1)

        // when
        let body = sut.body

        // then
        #expect(body == nil)
    }

    // MARK: - Sendable conformance

    @Test
    func endpoint_isSendable() {
        // given
        let sut: any Sendable = SearchEndpoint.searchRepositories(query: "swift", page: 1)

        // then
        #expect(sut is SearchEndpoint)
    }
}
