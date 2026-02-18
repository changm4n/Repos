# Prompts

이 프로젝트에서 사용한 프롬프트 목록.

---

## 1

이 프로젝트에서 내가 입력한 프롬프트를 모두 Prompts.md에 저장해줘.

## 2

세션이 바뀌어도 저장할 수 있게 이 내용을 Claude.md에 저장하고 모든 세션에서 공유해

## 3

iOS 앱을 만들거고, Requirements에 요구사항 1,2 를 기록해두었어. 각 요구사항의 구현 예시 사진도 존재해. 이걸 확인해봐

## 4

요구사항 1부터 구현할건데, Architecture.md 에 기록된 내용을 바탕으로 구현할거야. 그 계획을 먼저 Plan.md 파일에 저장해. 존재하는 agent와 skill들을 활용하면 좋겠어.

## 5

좋아 병렬로 작업할 수 있는 구현은 병렬로 진행해줘.

## 6

Feature 패키지 구조를 수정할거야. products엔 FeatureImpl 로 생성하고, target에 SearchImpl를 넣어줘. 앞으로 구현할 feature들을 이런식으로 노출하여 AppTaget에 연결할거야. 이 내용을 필요한 곳에 기록해줘

## 7

RecentSearches 에 대한 usecase들이 crud로 분리되어있는데, RecentSearchesUsecase로 통합해줘.

## 8

프롬프트 기록하는걸 hook으로 만들고, hook이 실행되게 해줘. 필요한 문서도 수정해줘

## 9

platform 패키지에 unit test를 추가해줘. 사용할 수 잇는 agent나 skill들을 사용해

## 10

Domain에 대한 Unit test를 작성해줘. 필요한 skill과 agent를 사용하고, Platform 구현의 mock이 필요하면 생성해.

## 11

UsecaseImplTests의 디펜던시에 PlatformImpl가 존재하는 이유는 뭐야? 존재해선 안 돼 

## 12

UsecaseImpl 도 PlatformImpl에 의존해선 안 돼 

## 13

git commit을 위한 agent를 추가하고 싶어. 요구사항은 다음 과 같아.
1. main branch는 merge commit만 존재해야함. (이후 pr로 관리될 예정) 
2. 각 커밋은 충분히 작고 커밋 메시지는  명확해야함.
3. 모든 커밋은 적절한 branch에서 생성되어야함.

## 14

지금 변경 사항들을 agent 사용해서 커밋해줘 

## 15

진행해 

## 16

요구사항1은 구현했고, 이제 요구사항 2를 구현해야해. Architecutre.md와 기존 프로젝트 구조를 보고. Plan.md에 구현계획을 작성해 

## 17

Plan.md에 요구사항 2를 확인하고 구현해줘. 

## 18

search textfield 가 빈 상태로 활성화되어있을때, "취소" 버튼을 눌러도 textfield가 비활성화되지 않는 문제가 있는데 확인해줘 

## 19

프로젝트 전체에 lint를 적용할거야. swiftformat을 사용할거고, rule 파일도 추가해두었어. 

## 20

매 수정마다 lint를 확인할 수 있게 swiftformat을 사용하여 lint를 체크하는 agent를 추가해줘. 그리고 모든 수정마다 실행해서 formatting을 수행해 

## 21

지금 Domain, Feature, Platform, SharedPackage들이 Package dependencies에만 존재하고, 프로젝트에 포함되지 않아있어. 확인하고 프로젝트에 포함되게 해줘 

## 22

프로젝트에 포함되었다면, package dependencies에선 제거해줘 

## 23

SearchResultRow의 .onTapGesture { onSelect(repo) } 가 잘 불리지 않아. row 영역 전체 아무곳이나 눌러도 호출되게 해줘 

## 24

SearchResultRow의 가로가 List 전체 가로와 달라. 컨텐츠 크기에 따라 크고 작아져. 항상 list 전체 가로와 같게 해서 List row 전체 영역이 터치되게 헤해줘 

## 25

Spacer()를 쓰지 않는 방법을 선호해 

## 26

isLoadingMore 상태일 때 ProgressView 가 보이지 않을 때도 있어

## 28

검색 결과 리스트 아래가 safe area따라 잘리고 있어. 리스트가 safe area까지 다 보이게 하고싶어.  @main에서 Root를 SwiftUI로 시작하지 말고, SceneDeleagte 기반으로 시작하게 수정해줘 

## 29

프로젝트 내에서 사용되지 않거나 구현되지 않은 함수, 인터페이스를 정리해줘 

## 30

지금 변경사항을 새로운 브렌치에 잘 커밋하고, pull request로 만들 수 있어?

## 31

지금 브랜치에 커밋이 너무 커. 여러개의 커맷으로 나눠서 pr로 올려줘 

## 32

Feature 패키지에 UnitTest를 추가해줘. Feature 내 ViewModel에 대해서만 테스트코드 작성해줘 

## 33

프로젝트에 존재하는 모든 테스트케이스를 포함한 TestPlan을 만들고, 그걸 앱스킴에 적용해줘 

## 34

지금 수정 내용들을 여러 브렌치, 커밋으로 잘 분리해서 pr로 올려줘. 

## 35

/init 

## 36

Architecture.md 파일에 대한 레퍼런스도 걸어줘 
