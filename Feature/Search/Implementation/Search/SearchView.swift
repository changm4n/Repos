import SwiftUI
import WebKit
import Entity

extension RepositoryEntity: @retroactive Identifiable {}

struct SearchView: View {
    @Bindable var viewModel: SearchViewModel
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Title
            if !isTextFieldFocused && viewModel.searchPhase == .idle {
                HStack {
                    Text("Search")
                        .font(.largeTitle.bold())
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    Spacer()
                }
            }

            // Search Bar
            SearchBarView(
                text: $viewModel.searchText,
                isTextFieldFocused: $isTextFieldFocused,
                onSearch: { Task { await viewModel.search() } },
                onClear: { viewModel.clearSearch() },
                onCancel: { viewModel.cancel() },
                showCancel: isTextFieldFocused || viewModel.searchPhase == .results
            )

            // Content
            contentView
        }
        .sheet(item: $viewModel.selectedRepository) { repo in
            NavigationStack {
                WebViewRepresentable(url: URL(string: repo.htmlURL)!)
            }
        }
        .task {
            await viewModel.loadRecentSearches()
        }
        .onChange(of: isTextFieldFocused) { _, newValue in
            viewModel.isSearchBarFocused = newValue
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.searchPhase {
        case .idle:
            if viewModel.searchText.isEmpty {
                RecentSearchListView(
                    recentSearches: viewModel.recentSearches,
                    onSelect: { keyword in Task { await viewModel.selectRecentSearch(keyword: keyword) } },
                    onDelete: { keyword in Task { await viewModel.deleteRecentSearch(keyword: keyword) } },
                    onDeleteAll: { Task { await viewModel.deleteAllRecentSearches() } }
                )
            } else {
                autocompleteView
            }
        case .searching:
            Spacer()
            ProgressView("Searching...")
            Spacer()
        case .results:
            SearchResultListView(
                repositories: viewModel.repositories,
                totalCount: viewModel.totalCount,
                isLoadingMore: viewModel.isLoadingMore,
                hasMorePages: viewModel.hasMorePages,
                onSelect: { repo in viewModel.selectRepository(repo) },
                onLoadMore: { Task { await viewModel.loadNextPage() } }
            )
        }
    }

    @ViewBuilder
    private var autocompleteView: some View {
        let filtered = viewModel.filteredRecentSearches
        if filtered.isEmpty {
            Spacer()
            Text("No Matches")
                .foregroundStyle(.secondary)
            Spacer()
        } else {
            List(filtered, id: \.keyword) { item in
                HStack {
                    Text(item.keyword)
                    Spacer()
                    RelativeTimeText(date: item.searchedAt)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    Task { await viewModel.selectRecentSearch(keyword: item.keyword) }
                }
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - WebView

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.title") { result, _ in
                if let title = result as? String {
                    DispatchQueue.main.async {
                        var responder: UIResponder? = webView
                        while let next = responder?.next {
                            if let vc = next as? UIViewController {
                                vc.navigationItem.title = title
                                break
                            }
                            responder = next
                        }
                    }
                }
            }
        }
    }
}
