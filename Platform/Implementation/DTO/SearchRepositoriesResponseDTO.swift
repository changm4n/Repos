public struct SearchRepositoriesResponseDTO: Decodable, Sendable {
    public let totalCount: Int
    public let items: [RepositoryItemResponseDTO]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case items
    }
}
