import UIKit
import SharedPackage

final class SearchViewController: UIViewController, SearchRouting {
    private let viewModel: SearchViewModel

    init(viewModel: SearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        SearchView(viewModel: viewModel).attach(to: self)
    }

    // MARK: - Routing

    func attachChild(viewController: UIViewController) {
        show(viewController, sender: nil)
    }

    func detachChild() {
        navigationController?.popViewController(animated: true)
    }

    func attachSheet(viewController: UIViewController) {
        present(viewController, animated: true)
    }

    func detachSheet() {
        dismiss(animated: true)
    }
}
