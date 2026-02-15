public struct RepositoryEntity: Sendable, Equatable, Identifiable {
  public let id: Int
  public let name: String
  public let htmlURL: String
  public let ownerLogin: String
  public let ownerAvatarURL: String

  public init(id: Int, name: String, htmlURL: String, ownerLogin: String, ownerAvatarURL: String) {
    self.id = id
    self.name = name
    self.htmlURL = htmlURL
    self.ownerLogin = ownerLogin
    self.ownerAvatarURL = ownerAvatarURL
  }
}
