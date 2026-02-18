import Foundation
import Platform
import Testing
@testable import PlatformImpl

// MARK: - Test Helpers

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
  nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard let handler = MockURLProtocol.requestHandler else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }

    do {
      let (response, data) = try handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}

private final class RequestCapture: @unchecked Sendable {
  var capturedRequest: URLRequest?
  var capturedBodyData: Data?
}

private struct StubEndpoint: Endpoint {
  var path = "/test"
  var method: HTTPMethod = .get
  var body: (any Encodable & Sendable)? = nil
  var queryItems: [URLQueryItem]? = nil
}

private struct TestModel: Decodable, Sendable, Equatable {
  let id: Int
  let name: String
}

private struct StubBody: Codable, Sendable, Equatable {
  let title: String
}

// MARK: - Tests

@Suite("NetworkClientImpl", .serialized)
struct NetworkClientImplTests {

  private let host = "https://api.example.com"

  private func makeSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: configuration)
  }

  private func makeSUT() -> NetworkClientImpl {
    NetworkClientImpl(session: makeSession(), host: host)
  }

  private func stubJSON() -> Data {
    Data(#"{"id": 1, "name": "test"}"#.utf8)
  }

  private func makeSuccessResponse(
    url: URL,
    data: Data = Data(),
    statusCode: Int = 200
  ) -> (HTTPURLResponse, Data) {
    let response = HTTPURLResponse(
      url: url,
      statusCode: statusCode,
      httpVersion: nil,
      headerFields: nil
    )!
    return (response, data)
  }

  /// Read body data from a URLRequest intercepted by URLProtocol.
  /// URLSession moves httpBody into httpBodyStream when passing the request to URLProtocol,
  /// so we need to read from the stream to get the body data.
  private func bodyData(from request: URLRequest) -> Data? {
    if let httpBody = request.httpBody {
      return httpBody
    }
    guard let stream = request.httpBodyStream else { return nil }
    stream.open()
    defer { stream.close() }

    var data = Data()
    let bufferSize = 1024
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }

    while stream.hasBytesAvailable {
      let bytesRead = stream.read(buffer, maxLength: bufferSize)
      if bytesRead > 0 {
        data.append(buffer, count: bytesRead)
      } else {
        break
      }
    }
    return data.isEmpty ? nil : data
  }

  // MARK: - URL construction

  @Test
  func request_constructsCorrectURL() async throws {
    // given
    let sut = makeSUT()
    let endpoint = StubEndpoint(path: "/users/repos")
    let capture = RequestCapture()

    MockURLProtocol.requestHandler = { request in
      capture.capturedRequest = request
      return makeSuccessResponse(url: request.url!, data: stubJSON())
    }

    // when
    let _: TestModel = try await sut.request(endpoint, type: TestModel.self)

    // then
    let url = try #require(capture.capturedRequest?.url)
    #expect(url.scheme == "https")
    #expect(url.host() == "api.example.com")
    #expect(url.path() == "/users/repos")
  }

  // MARK: - Query items

  @Test
  func request_includesQueryItemsInURL() async throws {
    // given
    let sut = makeSUT()
    let endpoint = StubEndpoint(
      path: "/search",
      queryItems: [
        URLQueryItem(name: "q", value: "swift"),
        URLQueryItem(name: "page", value: "2"),
      ]
    )
    let capture = RequestCapture()

    MockURLProtocol.requestHandler = { request in
      capture.capturedRequest = request
      return makeSuccessResponse(url: request.url!, data: stubJSON())
    }

    // when
    let _: TestModel = try await sut.request(endpoint, type: TestModel.self)

    // then
    let url = try #require(capture.capturedRequest?.url)
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let queryItems = try #require(components?.queryItems)
    #expect(queryItems.contains(URLQueryItem(name: "q", value: "swift")))
    #expect(queryItems.contains(URLQueryItem(name: "page", value: "2")))
  }

  // MARK: - HTTP method

  @Test(arguments: [
    (HTTPMethod.get, "GET"),
    (HTTPMethod.post, "POST"),
    (HTTPMethod.put, "PUT"),
    (HTTPMethod.delete, "DELETE"),
  ])
  func request_setsCorrectHTTPMethod(method: HTTPMethod, expectedRawValue: String) async throws {
    // given
    let sut = makeSUT()
    let endpoint = StubEndpoint(path: "/test", method: method)
    let capture = RequestCapture()

    MockURLProtocol.requestHandler = { request in
      capture.capturedRequest = request
      return makeSuccessResponse(url: request.url!, data: stubJSON())
    }

    // when
    let _: TestModel = try await sut.request(endpoint, type: TestModel.self)

    // then
    #expect(capture.capturedRequest?.httpMethod == expectedRawValue)
  }

  // MARK: - Accept header

  @Test
  func request_setsAcceptHeaderToJSON() async throws {
    // given
    let sut = makeSUT()
    let endpoint = StubEndpoint()
    let capture = RequestCapture()

    MockURLProtocol.requestHandler = { request in
      capture.capturedRequest = request
      return makeSuccessResponse(url: request.url!, data: stubJSON())
    }

    // when
    let _: TestModel = try await sut.request(endpoint, type: TestModel.self)

    // then
    #expect(capture.capturedRequest?.value(forHTTPHeaderField: "Accept") == "application/json")
  }

  // MARK: - Body encoding

  @Test
  func request_encodesBodyAndSetsContentTypeHeader() async throws {
    // given
    let sut = makeSUT()
    let stubBody = StubBody(title: "Hello")
    let endpoint = StubEndpoint(
      path: "/items",
      method: .post,
      body: stubBody
    )
    let capture = RequestCapture()

    MockURLProtocol.requestHandler = { request in
      capture.capturedRequest = request
      capture.capturedBodyData = bodyData(from: request)
      return makeSuccessResponse(url: request.url!, data: stubJSON())
    }

    // when
    let _: TestModel = try await sut.request(endpoint, type: TestModel.self)

    // then
    #expect(capture.capturedRequest?.value(forHTTPHeaderField: "Content-Type") == "application/json")

    let data = try #require(capture.capturedBodyData)
    let decodedBody = try JSONDecoder().decode(StubBody.self, from: data)
    #expect(decodedBody == stubBody)
  }

  @Test
  func request_doesNotSetContentTypeHeaderWhenBodyIsNil() async throws {
    // given
    let sut = makeSUT()
    let endpoint = StubEndpoint(path: "/items", method: .get, body: nil)
    let capture = RequestCapture()

    MockURLProtocol.requestHandler = { request in
      capture.capturedRequest = request
      capture.capturedBodyData = bodyData(from: request)
      return makeSuccessResponse(url: request.url!, data: stubJSON())
    }

    // when
    let _: TestModel = try await sut.request(endpoint, type: TestModel.self)

    // then
    #expect(capture.capturedRequest?.value(forHTTPHeaderField: "Content-Type") == nil)
    #expect(capture.capturedBodyData == nil)
  }

  // MARK: - Response decoding

  @Test
  func request_decodesResponseCorrectly() async throws {
    // given
    let sut = makeSUT()
    let endpoint = StubEndpoint()

    MockURLProtocol.requestHandler = { request in
      let json = Data(#"{"id": 42, "name": "decoded-item"}"#.utf8)
      return makeSuccessResponse(url: request.url!, data: json)
    }

    // when
    let result: TestModel = try await sut.request(endpoint, type: TestModel.self)

    // then
    #expect(result.id == 42)
    #expect(result.name == "decoded-item")
  }

  // MARK: - Invalid JSON

  @Test
  func request_throwsErrorOnInvalidJSON() async throws {
    // given
    let sut = makeSUT()
    let endpoint = StubEndpoint()

    MockURLProtocol.requestHandler = { request in
      let invalidJSON = Data("not valid json".utf8)
      return makeSuccessResponse(url: request.url!, data: invalidJSON)
    }

    // when / then
    await #expect(throws: DecodingError.self) {
      let _: TestModel = try await sut.request(endpoint, type: TestModel.self)
    }
  }
}
