import SwiftUI
import Entity

struct SearchResultRow: View {
    let repository: RepositoryEntity

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: repository.ownerAvatarURL)) { image in
                image.resizable()
            } placeholder: {
                Color(.systemGray5)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(repository.name)
                    .font(.body.bold())
                    .lineLimit(1)
                Text(repository.ownerLogin)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
