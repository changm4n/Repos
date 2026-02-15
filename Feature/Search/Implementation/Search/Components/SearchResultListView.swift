import Entity
import SwiftUI

struct SearchResultListView: View {
  let repositories: [RepositoryEntity]
  let totalCount: Int
  let isLoadingMore: Bool
  let hasMorePages: Bool
  let onSelect: (RepositoryEntity) -> Void
  let onLoadMore: () -> Void

  var body: some View {
    if repositories.isEmpty {
      Spacer()
      Text("No Results")
        .foregroundStyle(.secondary)
      Spacer()
    } else {
      List {
        Section {
          ForEach(repositories) { repo in
            SearchResultRow(repository: repo)
              .contentShape(Rectangle())
              .onTapGesture { onSelect(repo) }
              .onAppear {
                if repo.id == repositories.last?.id, hasMorePages {
                  onLoadMore()
                }
              }
          }

        } header: {
          Text("Total: \(totalCount)")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
      .listStyle(.plain)
      .safeAreaInset(edge: .bottom) {
        if isLoadingMore {
          ProgressView()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
      }
    }
  }
}
