import SwiftUI

struct SearchBarView: View {
  @Binding var text: String
  var isTextFieldFocused: FocusState<Bool>.Binding
  var onSearch: () -> Void
  var onClear: () -> Void
  var onCancel: () -> Void
  var showCancel: Bool

  var body: some View {
    HStack(spacing: 8) {
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.secondary)
        TextField("저장소 검색", text: $text)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .submitLabel(.search)
          .onSubmit { onSearch() }
          .focused(isTextFieldFocused)

        if !text.isEmpty {
          Button(action: onClear) {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.secondary)
          }
        }
      }
      .padding(8)
      .background(Color(.systemGray6))
      .cornerRadius(10)

      if showCancel {
        Button("취소") {
          onCancel()
        }
        .transition(.move(edge: .trailing).combined(with: .opacity))
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .animation(.default, value: showCancel)
  }
}
