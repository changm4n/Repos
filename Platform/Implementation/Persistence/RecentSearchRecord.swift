import Foundation
import SwiftData

@Model
public final class RecentSearchRecord {
  @Attribute(.unique) public var keyword: String
  public var searchedAt: Date

  public init(keyword: String, searchedAt: Date = .now) {
    self.keyword = keyword
    self.searchedAt = searchedAt
  }
}
