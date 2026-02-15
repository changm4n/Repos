# Architecture

iOS 앱 아키텍처 문서. 새로운 프로젝트에서도 동일한 구조를 재사용할 수 있도록, 구현 세부사항이 아닌 **구조와 패턴**을 중심으로 기술한다.

---

## 목차

1. [레이어 구조](#1-레이어-구조)
2. [패키지 구성](#2-패키지-구성)
3. [Feature 모듈 구조](#3-feature-모듈-구조)
4. [의존성 주입 (DI)](#4-의존성-주입-di)
5. [네비게이션 / 라우팅](#5-네비게이션--라우팅)
6. [데이터 흐름](#6-데이터-흐름)
7. [네트워킹](#7-네트워킹)
8. [테스트 전략](#8-테스트-전략)
9. [Sample App](#9-sample-app)
10. [기술 스택](#10-기술-스택)
11. [컨벤션](#11-컨벤션)

---

## 1. 레이어 구조

Clean Architecture 기반의 3-레이어 구조를 사용한다.

```
┌─────────────────────────────────────┐
│          Feature (Presentation)     │  ← UI, ViewModel, Builder
├─────────────────────────────────────┤
│          Domain (Business Logic)    │  ← UseCase, Entity
├─────────────────────────────────────┤
│          Platform (Infrastructure)  │  ← Network, DB, FileManager 등
└─────────────────────────────────────┘
```

| 레이어 | 역할 | 포함 요소 |
|--------|------|-----------|
| **Feature** | 화면 단위의 UI 모듈 | SwiftUI View, ViewController(Routing), ViewModel, Builder |
| **Domain** | Platform을 활용한 비즈니스 로직 | Entity, UseCase(Protocol + Impl), Repository(선택적) |
| **Platform** | DB, Network 등 시스템 인프라 | NetworkClient, Persistence 등 파운데이션 레벨 구현체 |

### 의존 규칙

- Feature → Domain (O)
- Feature → Platform (X) — Domain을 통해서만 접근
- Domain → Platform (O) — UseCase가 Platform의 인프라(NetworkClient 등)를 활용하여 비즈니스 로직 수행
- Platform → Domain (X) — Platform은 순수 인프라만 제공, Domain을 알지 못함

---

## 2. 패키지 구성

Swift Package Manager(SPM)로 각 레이어를 독립 패키지로 관리한다.

```
Root/
├── Domain/
│   └── Package.swift
├── Feature/
│   └── Package.swift
├── Platform/
│   └── Package.swift
├── SharedPackage/
│   └── Package.swift
└── App/
    └── AppDelegate, AppComponent 등
```

### 각 패키지의 모듈 구조

각 모듈은 **Interface / Implementation / TestSupport / Tests** 4개 디렉토리로 분리한다.

```
Domain/
├── Usecase/
│   ├── Interface/         # UseCase Protocol, Repository Protocol
│   ├── Implementation/    # UseCaseImpl, RepositoryImpl
│   ├── TestSupport/       # Generated Mocks (Mockolo)
│   └── Tests/             # Unit Tests
├── Entity/                # 도메인 모델
└── Package.swift
```

```swift
// 예시: Domain/Package.swift
products: [
    .library(name: "Domain", targets: ["Usecase", "Entity"]),           // Interface
    .library(name: "DomainImpl", targets: ["UsecaseImpl", "Entity"]),   // Implementation
    .library(name: "DomainTestSupport", targets: ["UsecaseTestSupport"]), // Test Mocks
    .library(name: "DomainTests", targets: ["UsecaseTests"])            // Tests
],
targets: [
    .target(name: "Usecase", path: "Usecase/Interface"),
    .target(name: "UsecaseImpl", path: "Usecase/Implementation"),
    .target(name: "UsecaseTestSupport", path: "Usecase/TestSupport"),
    .testTarget(name: "UsecaseTests", path: "Usecase/Tests"),
    .target(name: "Entity"),
]
```

```swift
// 예시: Feature/Package.swift
// products는 Feature / FeatureImpl / FeatureTestSupport로 통합 노출한다.
// 새로운 Feature를 추가할 때는 targets에 해당 Feature의 타겟을 추가하고,
// products의 targets 배열에 포함시킨다.
products: [
    .library(name: "Feature", targets: ["Search", ...]),                 // Interface
    .library(name: "FeatureImpl", targets: ["SearchImpl", ...]),         // Implementation
    .library(name: "FeatureTestSupport", targets: ["SearchTestSupport", ...]), // Test Mocks
],
targets: [
    .target(name: "Search", path: "Search/Interface"),
    .target(name: "SearchImpl", path: "Search/Implementation"),
    .target(name: "SearchTestSupport", path: "Search/TestSupport"),
    // 새 Feature 추가 시 동일 패턴으로 target 추가
]
```

| 디렉토리 | 설명 | 의존 대상 |
|----------|------|-----------|
| Interface | Protocol 등 공개 계약 | 다른 모듈이 import |
| Implementation | 실제 구현체 | App Target이 import |
| TestSupport | Mock, Stub (Mockolo 자동 생성) | 테스트 및 Sample App이 import |
| Tests | 유닛 테스트 | CI 및 로컬에서 실행 |

### SharedPackage

공통 유틸리티와 디자인 시스템을 담는 패키지.

```
SharedPackage/
├── DesignSystem/           # 공통 UI 컴포넌트
├── Extensions/             # Swift/UIKit 확장
├── Resources/              # 에셋, 로컬라이제이션
├── Utilities/              # 유틸리티
└── Package.swift
```

---

## 3. Feature 모듈 구조

각 Feature는 독립된 모듈로, 아래 3-디렉토리 구조를 따른다.

```
Feature/{FeatureName}/
├── Interface/
│   └── {FeatureName}Interface.swift
├── Implementation/
│   ├── {FeatureName}/
│   │   ├── {FeatureName}View.swift
│   │   ├── {FeatureName}ViewModel.swift
│   │   ├── {FeatureName}ViewController.swift
│   │   ├── {FeatureName}Builder.swift
│   │   └── Components/
│   └── Generated/
│       └── {FeatureName}ImplMocks.swift
└── TestSupport/
    └── {FeatureName}Mocks.swift
```

### Interface

외부에 공개하는 계약. `Buildable`과 `Listener` 두 Protocol만 노출한다.

```swift
// {FeatureName}Interface.swift

/// Feature를 생성하는 계약
@MainActor
public protocol {FeatureName}Buildable {
    func build(listener: {FeatureName}Listener) -> UIViewController
}

/// 부모에게 이벤트를 전달하는 계약
@MainActor
public protocol {FeatureName}Listener: AnyObject {
    func didComplete()
    func didCancel()
}
```

### Implementation

UI는 **SwiftUI**로 구현하고, **UIViewController**가 이를 감싸서 UIKit 기반의 라우팅을 수행한다.

| 파일 | 역할 |
|------|------|
| **View** | SwiftUI 뷰. UI 렌더링만 담당하며 ViewModel을 주입받는다 |
| **ViewModel** | 상태 관리(`@Observable`), 비즈니스 로직 호출, Router를 통한 화면 전환 요청 |
| **ViewController** | SwiftUI View를 `attach(to:)`로 호스팅하고, `Routing` Protocol을 구현하여 UIKit 네비게이션 수행 |
| **Builder** | 의존성을 주입하여 ViewModel + ViewController를 조립 |
| **Components/** | Feature 내부에서만 사용하는 SwiftUI 서브뷰 |

### SwiftUI View ↔ ViewController 연결

SharedPackage에 정의된 `View.attach(to:)` 확장을 사용하여 SwiftUI View를 UIViewController에 호스팅한다.

```swift
// SharedPackage: View+Extension.swift
extension View {
    public func attach(to parentViewController: UIViewController) {
        let contentVC = UIHostingController(rootView: self)
        parentViewController.addChild(contentVC)
        contentVC.view.translatesAutoresizingMaskIntoConstraints = false
        parentViewController.view.addSubview(contentVC.view)
        contentVC.didMove(toParent: parentViewController)

        NSLayoutConstraint.activate([
            contentVC.view.topAnchor.constraint(equalTo: parentViewController.view.topAnchor),
            contentVC.view.bottomAnchor.constraint(equalTo: parentViewController.view.bottomAnchor),
            contentVC.view.leadingAnchor.constraint(equalTo: parentViewController.view.leadingAnchor),
            contentVC.view.trailingAnchor.constraint(equalTo: parentViewController.view.trailingAnchor),
        ])
    }
}
```

```swift
// View: SwiftUI로 UI만 정의
struct {FeatureName}View: View {
    let viewModel: {FeatureName}ViewModel

    var body: some View {
        VStack {
            // UI 구현
            Button("Action") {
                viewModel.didTapAction()
            }
        }
    }
}

// ViewController: SwiftUI View를 호스팅하고 Routing을 구현
final class {FeatureName}ViewController: UIViewController, {FeatureName}Routing {
    private let viewModel: {FeatureName}ViewModel

    init(viewModel: {FeatureName}ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        {FeatureName}View(viewModel: viewModel).attach(to: self)
    }

    // MARK: - Routing

    func attachChild(viewController: UIViewController) {
        show(viewController, sender: nil)
    }

    func detachChild() {
        navigationController?.popViewController(animated: true)
    }

    func attachSheet(viewController: UIViewController) {
        present(viewController, animated: true)
    }

    func detachSheet() {
        dismiss(animated: true)
    }
}
```

---

## 4. 의존성 주입 (DI)

프레임워크 없이 **Builder 패턴 + Dependency Protocol**로 수동 DI를 구현한다.

### Builder 기본 구조

```swift
// 공통 베이스 클래스 (SharedPackage에 위치)
open class Builder<DependencyType> {
    public let dependency: DependencyType
    public init(dependency: DependencyType) {
        self.dependency = dependency
    }
}
```

### Feature별 DI 흐름

```swift
// 1단계: Dependency Protocol 정의
public protocol {FeatureName}Dependency {
    var someRepository: SomeRepository { get }
    var someUseCase: SomeUseCase { get }
    var childBuildable: ChildBuildable { get }
}

// 2단계: Builder가 Dependency를 받아 조립
public final class {FeatureName}Builder: Builder<{FeatureName}Dependency>, {FeatureName}Buildable {
    public func build(listener: {FeatureName}Listener) -> UIViewController {
        let viewModel = {FeatureName}ViewModel(
            listener: listener,
            someRepository: dependency.someRepository,
            someUseCase: dependency.someUseCase
        )
        let viewController = {FeatureName}ViewController(viewModel: viewModel)
        viewModel.router = viewController
        return viewController
    }
}
```

### Composite Root (AppComponent)

앱 진입점에서 모든 의존성을 한곳에서 생성하고 조립한다.

```swift
// App Target에 위치
final class AppComponent: HomeDependency, LibraryDependency, ... {
    // Platform 인프라
    let networkClient: NetworkClient
    let tokenManager: TokenManager

    // UseCase (Platform 인프라를 직접 주입)
    lazy var fetchItemsUseCase: FetchItemsUseCase = FetchItemsUseCaseImpl(networkClient: networkClient)

    // UseCase (Repository를 통해 주입 — 여러 UseCase가 공유하는 경우)
    lazy var someRepository: SomeRepository = SomeRepositoryImpl(networkClient: networkClient)
    lazy var createItemUseCase: CreateItemUseCase = CreateItemUseCaseImpl(repository: someRepository)

    // Feature Builder
    lazy var homeBuildable: HomeBuildable = HomeBuilder(dependency: self)
    lazy var libraryBuildable: LibraryBuildable = LibraryBuilder(dependency: self)

    init() {
        // Platform 인프라 초기화
    }
}
```

---

## 5. 네비게이션 / 라우팅

UI는 SwiftUI, 라우팅은 UIKit으로 수행한다. ViewController가 `Routing` Protocol을 구현하여 화면 전환을 담당한다.

### Routing Protocol

```swift
@MainActor
protocol {FeatureName}Routing: AnyObject {
    func attachChild(viewController: UIViewController)
    func detachChild()
    func attachSheet(viewController: UIViewController)
    func detachSheet()
}
```

### 흐름

```
SwiftUI View (사용자 액션) → ViewModel (로직 처리) → router (화면 전환 요청)
                                                        ↓
                                                  ViewController가
                                                  Routing을 구현하여
                                                  UIKit으로 실제 전환 수행
```

### Root Router

앱 전체의 최상위 화면 전환을 관리한다.

```swift
enum RootScreen {
    case splash
    case main
    case signIn
    case onboarding
}

final class RootRouter {
    func switchRoot(to screen: RootScreen) {
        // 화면에 따라 적절한 Builder로 생성 후 root 교체
    }
}
```

### Listener를 통한 역방향 통신

자식 Feature는 Listener Protocol을 통해 부모에게 이벤트를 전달한다. 부모는 Listener 구현체를 만들어 자식의 이벤트를 수신한다.

```swift
// 부모 ViewModel 내부
struct ChildListenerImpl: ChildListener {
    weak var viewModel: ParentViewModel?

    func didSelectItem(_ item: SomeItem) {
        viewModel?.handleSelectedItem(item)
        viewModel?.router?.detachChild()
    }
}
```

---

## 6. 데이터 흐름

### MVVM + @Observable

ViewModel은 `@Observable`을 사용하여 상태를 관리하고, SwiftUI View가 이를 자동으로 관찰한다.

```swift
@MainActor
@Observable
final class SomeViewModel {
    // 상태 — @Observable이 자동 추적
    var items: [ItemViewModel] = []
    var isLoading = false

    weak var router: SomeRouting?

    private let repository: SomeRepository

    init(repository: SomeRepository) {
        self.repository = repository
    }

    // 사용자 액션
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        items = try await repository.fetchItems().map(ItemViewModel.init)
    }
}

// SwiftUI View에서 ViewModel 사용
struct SomeView: View {
    let viewModel: SomeViewModel

    var body: some View {
        List(viewModel.items) { item in
            Text(item.title)
        }
        .overlay {
            if viewModel.isLoading { ProgressView() }
        }
        .task { await viewModel.loadData() }
    }
}
```

### AsyncStream (실시간 데이터)

지속적으로 변경되는 데이터를 관찰할 때는 `AsyncStream`을 사용한다.

```swift
// Repository Protocol
public protocol SomeRepository: AnyObject, Sendable {
    func observeItems() -> AsyncStream<[SomeEntity]>
}

// ViewModel에서 사용
@MainActor
@Observable
final class SomeViewModel {
    var items: [ItemViewModel] = []

    private let repository: SomeRepository
    private var observeTask: Task<Void, Never>?

    func startObserving() {
        observeTask = Task {
            for await data in repository.observeItems() {
                items = data.map(ItemViewModel.init)
            }
        }
    }

    deinit {
        observeTask?.cancel()
    }
}
```

### UseCase와 Repository

UseCase와 Repository는 구조적으로 동일하다. 둘 다 `Usecase/Interface`에 Protocol을, `Usecase/Implementation`에 구현체를 둔다. 이름만 역할에 따라 다를 뿐이다.

- **UseCase**: 비즈니스 로직 단위
- **Repository**: 데이터 접근 로직 단위. 여러 UseCase가 동일 데이터 소스를 공유할 때 사용

```
Domain/Usecase/
├── Interface/
│   ├── FetchItemsUseCase.swift
│   └── ItemRepository.swift
└── Implementation/
    ├── FetchItemsUseCaseImpl.swift
    └── ItemRepositoryImpl.swift
```

```swift
// Interface/FetchItemsUseCase.swift
/// @mockable
public protocol FetchItemsUseCase: Sendable {
    func execute() async throws -> [SomeEntity]
}

// Interface/ItemRepository.swift
/// @mockable
public protocol ItemRepository: AnyObject, Sendable {
    func fetchItems() async throws -> [SomeEntity]
    func create(_ item: SomeEntity) async throws -> SomeEntity
}

// Implementation/ItemRepositoryImpl.swift
public final class ItemRepositoryImpl: ItemRepository {
    private let networkClient: NetworkClient

    public init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    public func fetchItems() async throws -> [SomeEntity] {
        let response = try await networkClient.request(
            SomeEndpoint.getItems,
            type: [SomeResponseDTO].self
        )
        return response.map { $0.toEntity() }
    }
}

// Implementation/FetchItemsUseCaseImpl.swift
public final class FetchItemsUseCaseImpl: FetchItemsUseCase {
    private let repository: ItemRepository
    public init(repository: ItemRepository) { self.repository = repository }
    public func execute() async throws -> [SomeEntity] {
        try await repository.fetchItems()
    }
}
```

### DTO ↔ Entity 매핑

API 응답(DTO)과 도메인 모델(Entity)을 명확히 분리한다.

```swift
// DTO (API 응답 그대로)
struct SomeResponseDTO: Codable {
    let id: String
    let createdAt: String
}

// Entity (도메인 모델)
struct SomeEntity {
    let id: String
    let createdAt: Date
}

// 매핑
extension SomeResponseDTO {
    func toEntity() -> SomeEntity {
        SomeEntity(id: id, createdAt: DateFormatter.iso8601.date(from: createdAt)!)
    }
}
```

---

## 7. 네트워킹

### Endpoint 정의 (Enum 패턴)

API Endpoint를 enum으로 타입 세이프하게 관리한다.

```swift
public enum SomeEndpoint: Sendable {
    case getItems
    case getItem(id: String)
    case createItem(request: CreateRequestDTO)
    case deleteItem(id: String)
}

extension SomeEndpoint: MEndpoint {
    public var path: String {
        let base = "/api/v1/items"
        switch self {
        case .getItems:               return base
        case .getItem(let id):        return "\(base)/\(id)"
        case .createItem:             return base
        case .deleteItem(let id):     return "\(base)/\(id)"
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .getItems, .getItem:     return .get
        case .createItem:             return .post
        case .deleteItem:             return .delete
        }
    }

    public var body: Encodable? {
        switch self {
        case .createItem(let request): return request
        default:                       return nil
        }
    }
}
```

### NetworkClient Protocol

Platform의 Interface/Implementation 구조를 따른다.

```
Platform/
├── Interface/                     # Protocol
│   ├── NetworkClient.swift
│   └── MEndpoint.swift
├── Implementation/                # 구현체, Endpoint, DTO
│   ├── NetworkClientImpl.swift
│   ├── Endpoint/
│   └── DTO/
├── TestSupport/
├── Tests/
└── Package.swift
```

```swift
// Interface/NetworkClient.swift
/// @mockable
public protocol NetworkClient: Sendable {
    func request<T: Decodable>(_ endpoint: MEndpoint, type: T.Type) async throws -> T
}

// Implementation/NetworkClientImpl.swift (URLSession 기반)
public final class NetworkClientImpl: NetworkClient {
    private let session: URLSession
    private let host: String

    public func request<T: Decodable>(_ endpoint: MEndpoint, type: T.Type) async throws -> T {
        // URLSession 요청 수행
    }
}
```

---

## 8. 테스트 전략

### Mock 자동 생성 (Mockolo)

모든 Protocol에 `/// @mockable` 주석을 달면 [Mockolo](https://github.com/nicklama/mockolo-swift)가 자동으로 Mock 클래스를 생성한다.

```swift
/// @mockable
public protocol SomeRepository: AnyObject, Sendable {
    func fetchItems() async throws -> [SomeEntity]
}

// → 자동 생성되는 Mock
class SomeRepositoryMock: SomeRepository {
    var fetchItemsCallCount = 0
    var fetchItemsHandler: (() async throws -> [SomeEntity])?

    func fetchItems() async throws -> [SomeEntity] {
        fetchItemsCallCount += 1
        return try await fetchItemsHandler!()
    }
}
```

### TestSupport 모듈

각 패키지가 TestSupport Product를 제공하여, 테스트 시 실제 구현 대신 Mock을 주입한다.

```
Domain/
├── Usecase/
│   ├── Interface/         # UseCase Protocol, Repository Protocol
│   ├── Implementation/    # UseCaseImpl, RepositoryImpl
│   ├── TestSupport/       # Generated Mocks ← 테스트에서 import
│   └── Tests/             # Unit Tests
├── Entity/
└── Package.swift
```

---

## 9. Sample App

각 Feature를 독립적으로 실행하고 검증하기 위한 경량 앱.

```
{FeatureName}SampleApp/
├── {FeatureName}SampleApp.swift    # App 진입점
├── Dependency.swift                # Mock/Stub으로 구성된 DI 컨테이너
└── Info.plist
```

### 역할

- Feature를 메인 앱 없이 빠르게 빌드 & 실행
- TestSupport의 Mock을 활용하여 외부 의존성 제거
- UI 변경사항을 격리된 환경에서 확인

---

## 10. 기술 스택

### 서드파티 최소화 원칙

Apple 네이티브 API로 대체 가능한 경우 서드파티를 사용하지 않는다. 서드파티는 네이티브로 불가능하거나 외부 서비스 연동이 필수인 경우에만 도입한다.

| 카테고리 | 기술 | 비고 |
|----------|------|------|
| **UI** | SwiftUI (iOS 17+), UIKit은 라우팅/호스팅 전용 | Native |
| **상태 관리** | `@Observable`, `AsyncStream` | Native |
| **네트워킹** | URLSession | Native |
| **이미지** | SwiftUI `AsyncImage` / 자체 캐싱 | Native |
| **로컬 저장** | SwiftData | Native |
| **인증** | Firebase Auth | 서드파티 (서비스 SDK) |
| **분석** | Firebase Analytics | 서드파티 (서비스 SDK) |
| **크래시** | Firebase Crashlytics | 서드파티 (서비스 SDK) |
| **원격 설정** | Firebase RemoteConfig | 서드파티 (서비스 SDK) |
| **푸시** | Firebase Cloud Messaging | 서드파티 (서비스 SDK) |
| **결제** | RevenueCat | 서드파티 (서비스 SDK) |
| **광고** | Google AdMob | 서드파티 (서비스 SDK) |
| **Mock 생성** | Mockolo | 서드파티 (개발 도구) |
| **빌드/배포** | Fastlane | 서드파티 (개발 도구) |

---

## 11. 컨벤션

### 동시성

- ViewModel, Routing Protocol 등 UI 관련 타입에는 `@MainActor`를 명시한다.
- 공유 상태를 가진 Repository는 `actor`로 선언하여 data race를 방지한다.

```swift
@MainActor
final class SomeViewModel { ... }

public final actor TokenRepositoryImpl: TokenRepository { ... }
```

### 네이밍

| 대상 | 네이밍 규칙 | 예시 |
|------|-------------|------|
| Feature Interface | `{Name}Buildable`, `{Name}Listener` | `HomeBuildable`, `HomeListener` |
| Builder | `{Name}Builder` | `HomeBuilder` |
| Dependency | `{Name}Dependency` | `HomeDependency` |
| View (SwiftUI) | `{Name}View` | `HomeView` |
| ViewModel | `{Name}ViewModel` | `HomeViewModel` |
| ViewController | `{Name}ViewController` | `HomeViewController` |
| Routing | `{Name}Routing` | `HomeRouting` |
| Repository (Protocol) | `{Name}Repository` | `UserRepository` |
| Repository (Impl) | `{Name}RepositoryImpl` | `UserRepositoryImpl` |
| UseCase (Protocol) | `{Name}UseCase` | `GenerateUseCase` |
| UseCase (Impl) | `{Name}UseCaseImpl` | `GenerateUseCaseImpl` |
| Endpoint | `{Name}Endpoint` | `UserEndpoint` |
| DTO | `{Name}RequestDTO` / `{Name}ResponseDTO` | `CreateItemRequestDTO` |

### 파일 구성

- 하나의 파일에 하나의 주요 타입을 정의한다.
- Listener 구현체(struct)는 해당 ViewModel 파일 하단에 위치시킨다.
- Extension은 동일 파일 내 `// MARK: -` 로 구분하거나, 별도 파일 `{Type}+{Extension}.swift`로 분리한다.
