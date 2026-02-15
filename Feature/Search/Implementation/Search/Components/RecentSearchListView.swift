import Entity
import SwiftUI

struct RecentSearchListView: View {
  let recentSearches: [RecentSearchEntity]
  let onSelect: (String) -> Void
  let onDelete: (String) -> Void
  let onDeleteAll: () -> Void

  var body: some View {
    if recentSearches.isEmpty {
      Spacer()
      Text("No Recent Searches")
        .foregroundStyle(.secondary)
      Spacer()
    } else {
      List {
        Section {
          ForEach(recentSearches, id: \.keyword) { item in
            HStack {
              Image(systemName: "clock")
                .foregroundStyle(.secondary)
              Text(item.keyword)
              Spacer()
              RelativeTimeText(date: item.searchedAt)
                .foregroundStyle(.secondary)
                .font(.caption)
              Button {
                onDelete(item.keyword)
              } label: {
                Image(systemName: "xmark")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              .buttonStyle(.plain)
            }
            .contentShape(Rectangle())
            .onTapGesture {
              onSelect(item.keyword)
            }
          }
        } header: {
          HStack {
            Text("최근 검색")
            Spacer()
            Button("전체삭제") {
              onDeleteAll()
            }
            .font(.caption)
            .foregroundStyle(.pink)
          }
        }
      }
      .listStyle(.plain)
    }
  }
}
