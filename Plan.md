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
