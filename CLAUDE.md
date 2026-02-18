# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# 전체 테스트 (TestPlan 기반, Repos 앱 스킴)
xcodebuild test -scheme Repos -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -testPlan Repos

# 개별 패키지 테스트
xcodebuild test -scheme Feature-Package -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SearchImplTests
xcodebuild test -scheme Feature-Package -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WebViewImplTests
xcodebuild test -scheme Domain-Package -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:UsecaseImplTests
xcodebuild test -scheme Platform-Package -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PlatformTests

# Mock 재생성 (Mockolo)
mockolo -s Platform/Interface -d Platform/TestSupport/PlatformMocks.swift --mock-final
mockolo -s Domain/Usecase/Interface -d Domain/Usecase/TestSupport/UsecaseMocks.swift --mock-final
mockolo -s Feature/{Name}/Interface -d Feature/{Name}/TestSupport/{Name}Mocks.swift --mock-final
```

- iOS 전용 프로젝트이므로 `swift test` 대신 반드시 `xcodebuild test`를 사용한다.
- SwiftFormat hook이 Edit/Write 후 자동 실행된다 (`.claude/hooks/swiftformat-lint.sh`).

## Architecture

> 상세 아키텍처 문서: [Architecture.md](./Architecture.md) — 레이어 구조, Feature 모듈 패턴, DI, 라우팅, 데이터 흐름, 네트워킹, 테스트 전략, 컨벤션 등

3-Layer Clean Architecture + 로컬 SPM 패키지 구조:

```
Repos (App)  ←  AppComponent (Composite Root DI)
    ↓
Feature (Presentation)  →  Search, WebView
    ↓
Domain (Business Logic)  →  Entity, Usecase
    ↓
Platform (Infrastructure)  →  NetworkClient, Repository, Persistence, DTO
    ↓
SharedPackage  →  Builder<T> base class, View+Attach extension
```

**의존성 규칙**: Feature → Domain → Platform. 역방향 의존 금지.

### 패키지 구조 컨벤션

각 패키지는 Interface/Implementation/TestSupport/Tests 4개 레이어로 분리:

| Target | Path | Product | 역할 |
|--------|------|---------|------|
| `{Name}` | `Interface/` | 공개 라이브러리 | Protocol 정의 (`/// @mockable`) |
| `{Name}Impl` | `Implementation/` | 구현 라이브러리 | 실제 구현체 |
| `{Name}TestSupport` | `TestSupport/` | Mock 라이브러리 | Mockolo 자동 생성 Mock |
| `{Name}Tests` | `Tests/` | 테스트 | Swift Testing 기반 유닛테스트 |

### Feature 모듈 패턴

각 Feature는 Builder/ViewController/ViewModel/View로 구성:

- **Builder**: `Builder<Dependency>` 상속, `{Name}Buildable` 프로토콜 구현, DI 조립
- **ViewController**: UIViewController, `{Name}Routing` 구현, SwiftUI View를 `.attach(to:)`로 호스팅
- **ViewModel**: `@MainActor @Observable`, 비즈니스 로직, weak `router` 참조
- **View**: SwiftUI, `@Bindable var viewModel`으로 상태 바인딩
- **Listener**: 자식 → 부모 역방향 통신 프로토콜

### DI 흐름

`AppComponent`(Composite Root)가 모든 의존성을 조립하고 `{Feature}Dependency` 프로토콜을 conform:

```
SceneDelegate → AppComponent.searchBuildable.build(listener: self)
AppComponent conforms to SearchDependency {
  searchRepositoriesUseCase → SearchRepositoriesUseCaseImpl → SearchRepositoryImpl → NetworkClientImpl
  recentSearchesUseCase → RecentSearchesUseCaseImpl → RecentSearchPersistenceImpl (SwiftData)
  webViewBuildable → WebViewBuilder
}
```

## Testing Conventions

- **프레임워크**: Swift Testing (`@Suite`, `@Test`, `#expect`) — XCTest 아님
- **Mock**: `/// @mockable` 주석 → Mockolo가 TestSupport에 Mock 자동 생성
- **패턴**: `makeSUT()` 헬퍼로 SUT 생성, given/when/then 구조
- **ViewModel 테스트**: `@MainActor @Suite` 어노테이션 필수, UseCase mock의 handler/callCount로 검증
- **Network 테스트**: `MockURLProtocol`로 URLSession 인터셉트, `.serialized` trait 사용

## Code Style

- Swift 6.0 strict concurrency: `Sendable`, `@MainActor`, `actor` 준수
- indent 2칸, max width 120
- `@Observable` (iOS 17+) 사용, `ObservableObject` 사용 금지
- SwiftFormat이 Edit/Write hook으로 자동 적용됨 (`*Mocks.swift` 제외)

## 프롬프트 기록 규칙

- `UserPromptSubmit` hook(`.claude/hooks/record-prompt.sh`)이 자동으로 `Prompts.md`에 기록한다.
- Claude가 수동으로 기록할 필요 없음.
