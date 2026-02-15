import SwiftUI

struct WebViewView: View {
  let viewModel: WebViewModel

  var body: some View {
    NavigationStack {
      WebContentView(
        url: viewModel.url,
        onTitleChanged: { title in
          viewModel.updateTitle(title)
        }
      )
      .navigationTitle(viewModel.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Done") {
            viewModel.didTapClose()
          }
        }
      }
    }
  }
}
