import Foundation

public struct RecentSearchEntity: Sendable, Equatable {
  public let keyword: String
  public let searchedAt: Date

  public init(keyword: String, searchedAt: Date) {
    self.keyword = keyword
    self.searchedAt = searchedAt
  }
}
