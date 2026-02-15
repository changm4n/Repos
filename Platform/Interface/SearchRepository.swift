import Foundation

/// @mockable
public protocol SearchRepository: Sendable {
    func search(query: String, page: Int) async throws -> (totalCount: Int, items: [(id: Int, name: String, htmlURL: String, ownerLogin: String, ownerAvatarURL: String)])
}
