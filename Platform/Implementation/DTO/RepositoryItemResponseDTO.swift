public struct RepositoryItemResponseDTO: Decodable, Sendable {
    public let id: Int
    public let name: String
    public let htmlURL: String
    public let owner: OwnerResponseDTO

    enum CodingKeys: String, CodingKey {
        case id, name
        case htmlURL = "html_url"
        case owner
    }
}

public struct OwnerResponseDTO: Decodable, Sendable {
    public let login: String
    public let avatarURL: String

    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
    }
}
