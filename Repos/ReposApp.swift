import SwiftUI
import UIKit
import Search

@main
struct ReposApp: App {
    @State private var appComponent = AppComponent()

    var body: some Scene {
        WindowGroup {
            SearchRootView(appComponent: appComponent)
        }
    }
}

struct SearchRootView: UIViewControllerRepresentable {
    let appComponent: AppComponent

    func makeUIViewController(context: Context) -> UINavigationController {
        let searchVC = appComponent.searchBuildable.build(listener: context.coordinator)
        return UINavigationController(rootViewController: searchVC)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, SearchListener {
        nonisolated func searchDidComplete() {}
    }
}
