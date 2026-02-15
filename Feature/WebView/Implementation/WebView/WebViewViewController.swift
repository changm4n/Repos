import SharedPackage
import UIKit

final class WebViewViewController: UIViewController {
  private let viewModel: WebViewModel

  init(viewModel: WebViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError() }

  override func viewDidLoad() {
    super.viewDidLoad()
    WebViewView(viewModel: viewModel).attach(to: self)
  }
}
