import Search
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, SearchListener {
  var window: UIWindow?
  private var appComponent: AppComponent?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let appComponent = AppComponent()
    self.appComponent = appComponent

    let searchVC = appComponent.searchBuildable.build(listener: self)
    let navController = UINavigationController(rootViewController: searchVC)
    navController.setNavigationBarHidden(true, animated: false)

    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = navController
    window.makeKeyAndVisible()
    self.window = window
  }

  // MARK: - SearchListener
}
