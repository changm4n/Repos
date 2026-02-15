import Foundation
import Testing

@testable import PlatformImpl

// MARK: - OwnerResponseDTOTests

@Suite("OwnerResponseDTO Decoding")
struct OwnerResponseDTOTests {

    @Test
    func decode_mapsSnakeCaseAvatarURL() throws {
        // given
        let json = """
        {
            "login": "octocat",
            "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4"
        }
        """.data(using: .utf8)!

        // when
        let dto = try JSONDecoder().decode(OwnerResponseDTO.self, from: json)

        // then
        #expect(dto.login == "octocat")
        #expect(dto.avatarURL == "https://avatars.githubusercontent.com/u/1?v=4")
    }

    @Test
    func decode_failsWhenLoginIsMissing() throws {
        // given
        let json = """
        {
            "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4"
        }
        """.data(using: .utf8)!

        // when / then
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(OwnerResponseDTO.self, from: json)
        }
    }

    @Test
    func decode_failsWhenAvatarURLIsMissing() throws {
        // given
        let json = """
        {
            "login": "octocat"
        }
        """.data(using: .utf8)!

        // when / then
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(OwnerResponseDTO.self, from: json)
        }
    }
}

// MARK: - RepositoryItemResponseDTOTests

@Suite("RepositoryItemResponseDTO Decoding")
struct RepositoryItemResponseDTOTests {

    @Test
    func decode_mapsSnakeCaseHtmlURL() throws {
        // given
        let json = """
        {
            "id": 1296269,
            "name": "Hello-World",
            "html_url": "https://github.com/octocat/Hello-World",
            "owner": {
                "login": "octocat",
                "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4"
            }
        }
        """.data(using: .utf8)!

        // when
        let dto = try JSONDecoder().decode(RepositoryItemResponseDTO.self, from: json)

        // then
        #expect(dto.id == 1296269)
        #expect(dto.name == "Hello-World")
        #expect(dto.htmlURL == "https://github.com/octocat/Hello-World")
        #expect(dto.owner.login == "octocat")
        #expect(dto.owner.avatarURL == "https://avatars.githubusercontent.com/u/1?v=4")
    }

    @Test
    func decode_failsWhenRequiredFieldIsMissing() throws {
        // given - missing "name" field
        let json = """
        {
            "id": 1296269,
            "html_url": "https://github.com/octocat/Hello-World",
            "owner": {
                "login": "octocat",
                "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4"
            }
        }
        """.data(using: .utf8)!

        // when / then
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RepositoryItemResponseDTO.self, from: json)
        }
    }

    @Test
    func decode_failsWhenOwnerIsMissing() throws {
        // given
        let json = """
        {
            "id": 1296269,
            "name": "Hello-World",
            "html_url": "https://github.com/octocat/Hello-World"
        }
        """.data(using: .utf8)!

        // when / then
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RepositoryItemResponseDTO.self, from: json)
        }
    }
}

// MARK: - SearchRepositoriesResponseDTOTests

@Suite("SearchRepositoriesResponseDTO Decoding")
struct SearchRepositoriesResponseDTOTests {

    @Test
    func decode_mapsSnakeCaseTotalCountAndNestedItems() throws {
        // given
        let json = """
        {
            "total_count": 2,
            "items": [
                {
                    "id": 1,
                    "name": "repo-one",
                    "html_url": "https://github.com/owner/repo-one",
                    "owner": {
                        "login": "owner",
                        "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4"
                    }
                },
                {
                    "id": 2,
                    "name": "repo-two",
                    "html_url": "https://github.com/owner/repo-two",
                    "owner": {
                        "login": "owner",
                        "avatar_url": "https://avatars.githubusercontent.com/u/2?v=4"
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        // when
        let dto = try JSONDecoder().decode(SearchRepositoriesResponseDTO.self, from: json)

        // then
        #expect(dto.totalCount == 2)
        #expect(dto.items.count == 2)
        #expect(dto.items[0].id == 1)
        #expect(dto.items[0].name == "repo-one")
        #expect(dto.items[0].htmlURL == "https://github.com/owner/repo-one")
        #expect(dto.items[0].owner.login == "owner")
        #expect(dto.items[1].id == 2)
        #expect(dto.items[1].name == "repo-two")
    }

    @Test
    func decode_emptyItemsArray() throws {
        // given
        let json = """
        {
            "total_count": 0,
            "items": []
        }
        """.data(using: .utf8)!

        // when
        let dto = try JSONDecoder().decode(SearchRepositoriesResponseDTO.self, from: json)

        // then
        #expect(dto.totalCount == 0)
        #expect(dto.items.isEmpty)
    }

    @Test
    func decode_failsWhenTotalCountIsMissing() throws {
        // given
        let json = """
        {
            "items": []
        }
        """.data(using: .utf8)!

        // when / then
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(SearchRepositoriesResponseDTO.self, from: json)
        }
    }

    @Test
    func decode_failsWhenItemsIsMissing() throws {
        // given
        let json = """
        {
            "total_count": 0
        }
        """.data(using: .utf8)!

        // when / then
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(SearchRepositoriesResponseDTO.self, from: json)
        }
    }
}
