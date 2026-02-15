# Plan — 요구사항 1. 검색 화면

Architecture.md 기반, Bottom-Up(Platform → Domain → Feature) 순서로 구현한다.

---

## Phase 1. SharedPackage (기반 유틸리티)

Feature 모듈이 공통으로 사용하는 기반 코드를 먼저 생성한다.

| 파일 | 내용 |
|------|------|
| `SharedPackage/Utilities/Builder.swift` | `open class Builder<DependencyType>` 베이스 클래스 |
| `SharedPackage/Extensions/View+Attach.swift` | `View.attach(to:)` UIHostingController 호스팅 확장 |
| `SharedPackage/Package.swift` | 패키지 매니페스트 |

---

## Phase 2. Platform (인프라) — `platform` agent

### 2-1. NetworkClient 인터페이스 & 구현

| 파일 | 내용 |
|------|------|
| `Platform/Interface/MEndpoint.swift` | `MEndpoint` Protocol (path, method, body, queryItems) |
| `Platform/Interface/NetworkClient.swift` | `NetworkClient` Protocol (`/// @mockable`) |
| `Platform/Implementation/NetworkClientImpl.swift` | URLSession 기반 구현체 |

### 2-2. Search Endpoint & DTO — `/new-endpoint` skill

> `/new-endpoint Search`

| 파일 | 내용 |
|------|------|
| `Platform/Implementation/Endpoint/SearchEndpoint.swift` | `.searchRepositories(query:page:)` 케이스, GitHub API 매핑 |
| `Platform/Implementation/DTO/SearchRepositoriesResponseDTO.swift` | `total_count`, `items` 응답 매핑 |
| `Platform/Implementation/DTO/RepositoryItemResponseDTO.swift` | `id`, `name`, `html_url`, `owner` 매핑 |

### 2-3. RecentSearch Persistence (SwiftData)

| 파일 | 내용 |
|------|------|
| `Platform/Interface/RecentSearchPersistence.swift` | CRUD Protocol (`/// @mockable`) |
| `Platform/Implementation/Persistence/RecentSearchPersistenceImpl.swift` | SwiftData `@Model` + 구현체 |

### 2-4. Package.swift

`Platform/Package.swift`에 Interface/Implementation/TestSupport/Tests 타겟 등록.

---

## Phase 3. Domain (비즈니스 로직) — `domain` agent

### 3-1. Entity — `/new-entity` skill

> `/new-entity Repository`, `/new-entity RecentSearch`

| Entity | 프로퍼티 |
|--------|----------|
| `RepositoryEntity` | `id: Int`, `name: String`, `htmlURL: String`, `ownerLogin: String`, `ownerAvatarURL: String` |
| `RecentSearchEntity` | `keyword: String`, `searchedAt: Date` |

### 3-2. UseCase — `/new-usecase` skill

> `/new-usecase SearchRepositories`
> `/new-usecase FetchRecentSearches`
> `/new-usecase SaveRecentSearch`
> `/new-usecase DeleteRecentSearch`
> `/new-usecase DeleteAllRecentSearches`

| UseCase | 시그니처 | 의존성 |
|---------|----------|--------|
| `SearchRepositoriesUseCase` | `execute(query:page:) async throws -> (totalCount: Int, items: [RepositoryEntity])` | `NetworkClient` |
| `FetchRecentSearchesUseCase` | `execute() async throws -> [RecentSearchEntity]` | `RecentSearchPersistence` |
| `SaveRecentSearchUseCase` | `execute(keyword:) async throws` | `RecentSearchPersistence` |
| `DeleteRecentSearchUseCase` | `execute(keyword:) async throws` | `RecentSearchPersistence` |
| `DeleteAllRecentSearchesUseCase` | `execute() async throws` | `RecentSearchPersistence` |

### 3-3. Package.swift

`Domain/Package.swift`에 Usecase(Interface), UsecaseImpl(Implementation), Entity 타겟 등록.

---

## Phase 4. Feature (UI) — `feature` agent

### 4-1. Search Feature 스캐폴딩 — `/new-feature` skill

> `/new-feature Search`

기본 파일 생성: `SearchInterface.swift`, `SearchView.swift`, `SearchViewModel.swift`, `SearchViewController.swift`, `SearchBuilder.swift`, `SearchEventLog.swift`

### 4-2. SearchViewModel 구현

| 상태 | 타입 | 설명 |
|------|------|------|
| `searchText` | `String` | 검색바 입력 텍스트 |
| `isSearchBarFocused` | `Bool` | 검색바 포커스 상태 |
| `searchPhase` | `enum SearchPhase` | `.idle` / `.searching` / `.results` |
| `repositories` | `[RepositoryEntity]` | 검색 결과 |
| `totalCount` | `Int` | 총 결과 수 |
| `currentPage` | `Int` | 현재 페이지 |
| `hasMorePages` | `Bool` | 추가 페이지 존재 여부 |
| `isLoadingMore` | `Bool` | 다음 페이지 로딩 중 |
| `recentSearches` | `[RecentSearchEntity]` | 최근 검색어 목록 |
| `filteredRecentSearches` | `[RecentSearchEntity]` | 자동완성 필터 결과 (computed) |

| 액션 메서드 | 설명 |
|-------------|------|
| `search()` | 검색 실행 (API 호출 + 최근 검색어 저장) |
| `loadNextPage()` | 다음 페이지 로드 |
| `loadRecentSearches()` | 최근 검색어 불러오기 |
| `deleteRecentSearch(keyword:)` | 개별 삭제 |
| `deleteAllRecentSearches()` | 전체 삭제 |
| `selectRecentSearch(keyword:)` | 최근 검색어 탭 → 검색 실행 |
| `clearSearch()` | 텍스트 + 결과 초기화 |
| `cancel()` | 텍스트 초기화 + 결과 초기화 + 포커스 해제 |

### 4-3. SearchView 구현 (SwiftUI)

```
SearchView
├── SearchBarView (커스텀 검색바)
│   ├── 돋보기 아이콘 + TextField + X 버튼
│   └── Cancel 버튼 (포커스/검색 시 표시)
├── Content (searchPhase에 따라 분기)
│   ├── .idle → RecentSearchListView
│   │   ├── 헤더: "최근 검색" + "전체 삭제"
│   │   ├── 행: 시계 아이콘 + 키워드 + 상대시간 + X
│   │   └── 빈 상태: "No Recent Searches"
│   ├── .idle + 텍스트 입력 중 → AutocompleteListView
│   │   ├── 필터된 최근 검색어 목록
│   │   └── 빈 상태: "No Matches"
│   ├── .searching → ProgressView("Searching...")
│   └── .results → SearchResultListView
│       ├── 헤더: "Total: {totalCount}"
│       ├── 행: 원형 아바타(40x40) + name + owner.login
│       ├── 하단: ProgressView (페이지 로딩 중)
│       └── 빈 상태: "No Results"
└── .sheet → WebView (저장소 선택 시)
```

### 4-4. Components

| 파일 | 설명 |
|------|------|
| `Components/SearchBarView.swift` | 커스텀 검색바 컴포넌트 |
| `Components/RecentSearchListView.swift` | 최근 검색어 리스트 |
| `Components/SearchResultListView.swift` | 검색 결과 리스트 |
| `Components/SearchResultRow.swift` | 검색 결과 행 (아바타 + 텍스트) |
| `Components/RelativeTimeText.swift` | 상대 시간 포맷 헬퍼 |

### 4-5. Builder & Dependency

```swift
public protocol SearchDependency {
    var searchRepositoriesUseCase: SearchRepositoriesUseCase { get }
    var fetchRecentSearchesUseCase: FetchRecentSearchesUseCase { get }
    var saveRecentSearchUseCase: SaveRecentSearchUseCase { get }
    var deleteRecentSearchUseCase: DeleteRecentSearchUseCase { get }
    var deleteAllRecentSearchesUseCase: DeleteAllRecentSearchesUseCase { get }
}
```

---

## Phase 5. App Target 연결

| 파일 | 내용 |
|------|------|
| `Repos/AppComponent.swift` | Composite Root — 모든 의존성 조립 |
| `Repos/ReposApp.swift` | 앱 진입점, SearchBuilder로 루트 화면 생성 |

---

## 실행 순서 요약

| 단계 | 작업 | 도구 |
|------|------|------|
| 1 | SharedPackage 생성 | `platform` agent |
| 2 | Platform 인프라 구현 | `platform` agent + `/new-endpoint Search` |
| 3 | Domain Entity 생성 | `/new-entity Repository`, `/new-entity RecentSearch` |
| 4 | Domain UseCase 생성 | `/new-usecase` x 5 |
| 5 | Feature 스캐폴딩 | `/new-feature Search` |
| 6 | Feature 상세 구현 | `feature` agent |
| 7 | App Target 연결 | 직접 구현 |
| 8 | Mock 생성 | `/gen-mocks` |
| 9 | Unit Test | `unit-test` agent |

---
---

# Plan — 요구사항 2. WebView

요구사항 1 구현 시 WebView가 `SearchView.swift`에 인라인으로 포함되었다.
Architecture.md의 Feature 모듈 패턴(Interface/Implementation/TestSupport)에 맞게 WebView를 독립 Feature 모듈로 분리하고, 화면 전환을 UIKit Routing을 통해 수행하도록 리팩터링한다.

### 현재 문제

- `WebViewRepresentable`가 `SearchView.swift`에 직접 정의되어 있음
- `.sheet(item: $viewModel.selectedRepository)`로 SwiftUI 바인딩 기반 표시 → Architecture의 UIKit Routing 패턴 미준수
- 네비게이션 타이틀 설정에 responder chain 탐색 사용

### 목표

- WebView를 독립 Feature 모듈로 분리
- Search → WebView 화면 전환을 UIKit Routing 패턴으로 변경
- 웹페이지 `<title>`을 `@Observable` ViewModel + SwiftUI `.navigationTitle`로 표시

---

## Phase 1. WebView Feature 모듈 생성 — `/new-feature` skill + `feature` agent

### 1-1. Interface (`Feature/WebView/Interface/WebViewInterface.swift`)

```swift
@MainActor
public protocol WebViewBuildable {
    func build(url: URL, listener: WebViewListener) -> UIViewController
}

@MainActor
public protocol WebViewListener: AnyObject {
    func webViewDidClose()
}
```

> 기존 `{FeatureName}Buildable`은 `build(listener:) -> UIViewController`이지만,
> WebView는 표시할 URL이 런타임 파라미터이므로 `build(url:listener:)`로 정의한다.

### 1-2. Implementation

| 파일 | 역할 |
|------|------|
| `WebViewBuilder.swift` | `WebViewBuildable` 구현. Dependency 없음 (UseCase 불필요) |
| `WebViewModel.swift` | `@Observable`. `url: URL`, `title: String` 상태 관리 |
| `WebViewView.swift` | `NavigationStack` + `WebContentView` + `.navigationTitle(viewModel.title)` |
| `WebViewViewController.swift` | `WebViewView`를 `attach(to:)`로 호스팅 |
| `Components/WebContentView.swift` | `UIViewRepresentable` — WKWebView 래핑, `didFinish` 시 `document.title` 추출 → 콜백으로 ViewModel에 전달 |
| `WebViewEventLog.swift` | 이벤트 로깅 상수 |

### 1-3. TestSupport (`Feature/WebView/TestSupport/WebViewMocks.swift`)

`/// @mockable` 기반 Mockolo 자동 생성 대상.

---

## Phase 2. Search Feature 수정 — `feature` agent

### 2-1. SearchView.swift 변경

- **삭제**: `import WebKit`
- **삭제**: `extension RepositoryEntity: @retroactive Identifiable {}`
- **삭제**: `.sheet(item: $viewModel.selectedRepository) { ... }` 블록
- **삭제**: `WebViewRepresentable` struct 전체

### 2-2. SearchViewModel.swift 변경

- **삭제**: `var selectedRepository: RepositoryEntity?` 프로퍼티
- **변경**: `selectRepository(_:)` → `router?.attachWebView(url:)` 호출

```swift
func selectRepository(_ repository: RepositoryEntity) {
    guard let url = URL(string: repository.htmlURL) else { return }
    router?.attachWebView(url: url)
}
```

### 2-3. SearchRouting 변경 (SearchViewModel.swift 내)

```swift
@MainActor
protocol SearchRouting: AnyObject {
    func attachChild(viewController: UIViewController)
    func detachChild()
    func attachSheet(viewController: UIViewController)
    func detachSheet()
    func attachWebView(url: URL)  // 추가
}
```

### 2-4. SearchViewController.swift 변경

- `webViewBuildable: WebViewBuildable` 프로퍼티 추가 (init 주입)
- `WebViewListener` 구현: `webViewDidClose()` → `detachSheet()`
- `attachWebView(url:)` 구현: WebView VC 빌드 → `attachSheet`로 표시

```swift
func attachWebView(url: URL) {
    let webViewVC = webViewBuildable.build(url: url, listener: self)
    attachSheet(viewController: webViewVC)
}
```

### 2-5. SearchBuilder.swift / SearchDependency 변경

```swift
public protocol SearchDependency {
    var searchRepositoriesUseCase: SearchRepositoriesUseCase { get }
    var recentSearchesUseCase: RecentSearchesUseCase { get }
    var webViewBuildable: WebViewBuildable { get }  // 추가
}
```

Builder에서 `webViewBuildable`을 SearchViewController에 주입.

---

## Phase 3. Entity 수정

`Domain/Entity/RepositoryEntity.swift`에 `Identifiable` 프로토콜 적합성을 직접 추가한다.
(기존 SearchView.swift의 `@retroactive Identifiable` 제거 대응)

---

## Phase 4. Feature/Package.swift 수정

```swift
products: [
    .library(name: "Feature", targets: ["Search", "WebView"]),
    .library(name: "FeatureImpl", targets: ["SearchImpl", "WebViewImpl"]),
    .library(name: "FeatureTestSupport", targets: ["SearchTestSupport", "WebViewTestSupport"]),
],
targets: [
    // WebView targets 추가
    .target(name: "WebView", path: "WebView/Interface"),
    .target(
        name: "WebViewImpl",
        dependencies: ["WebView", .product(name: "SharedPackage", package: "SharedPackage")],
        path: "WebView/Implementation"
    ),
    .target(
        name: "WebViewTestSupport",
        dependencies: ["WebView"],
        path: "WebView/TestSupport"
    ),
]
```

SearchImpl 의존성에 `"WebView"` 추가 (Interface만 참조).

---

## Phase 5. App Target 수정

### AppComponent.swift

```swift
@MainActor
final class AppComponent: SearchDependency {
    // ... 기존 ...
    lazy var webViewBuildable: WebViewBuildable = WebViewBuilder()
    lazy var searchBuildable: SearchBuildable = SearchBuilder(dependency: self)
}
```

`import WebViewImpl` 추가.

---

## Phase 6. Mock 생성 & 테스트

1. `/gen-mocks` 실행 → WebView, Search TestSupport Mock 재생성
2. `unit-test` agent → WebViewModel 테스트 작성

---

## 수정 파일 요약

| 파일 | 변경 |
|------|------|
| `Feature/WebView/Interface/WebViewInterface.swift` | **신규** |
| `Feature/WebView/Implementation/WebView/WebViewBuilder.swift` | **신규** |
| `Feature/WebView/Implementation/WebView/WebViewModel.swift` | **신규** |
| `Feature/WebView/Implementation/WebView/WebViewView.swift` | **신규** |
| `Feature/WebView/Implementation/WebView/WebViewViewController.swift` | **신규** |
| `Feature/WebView/Implementation/WebView/Components/WebContentView.swift` | **신규** |
| `Feature/WebView/Implementation/WebView/WebViewEventLog.swift` | **신규** |
| `Feature/WebView/TestSupport/WebViewMocks.swift` | **신규** |
| `Feature/Search/Implementation/Search/SearchView.swift` | 수정 — WebView 관련 코드 제거 |
| `Feature/Search/Implementation/Search/SearchViewModel.swift` | 수정 — selectedRepository 제거, router 호출 변경 |
| `Feature/Search/Implementation/Search/SearchViewController.swift` | 수정 — WebViewBuildable 주입, attachWebView 구현 |
| `Feature/Search/Implementation/Search/SearchBuilder.swift` | 수정 — SearchDependency에 webViewBuildable 추가 |
| `Feature/Package.swift` | 수정 — WebView targets 추가, SearchImpl 의존성 추가 |
| `Domain/Entity/RepositoryEntity.swift` | 수정 — Identifiable 적합성 추가 |
| `Repos/AppComponent.swift` | 수정 — webViewBuildable 추가 |

## 실행 순서 요약

| 단계 | 작업 | 도구 |
|------|------|------|
| 1 | WebView Feature 스캐폴딩 | `/new-feature WebView` |
| 2 | WebView Feature 상세 구현 | `feature` agent |
| 3 | Search Feature 수정 | `feature` agent |
| 4 | Entity Identifiable 추가 | `domain` agent |
| 5 | Feature/Package.swift 수정 | 직접 수정 |
| 6 | App Target 수정 | 직접 수정 |
| 7 | Mock 생성 | `/gen-mocks` |
| 8 | Unit Test | `unit-test` agent |

## 검증

1. 빌드 확인: `xcodebuild build` (전체 앱 타겟)
2. 기능 확인: 검색 결과 탭 → WebView sheet 표시 → 페이지 로드 → 타이틀 표시
3. 기존 테스트 통과 확인
