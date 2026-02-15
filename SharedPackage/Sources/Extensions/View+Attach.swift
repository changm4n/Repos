import SwiftUI
import UIKit

extension View {
  public func attach(to parentViewController: UIViewController) {
    let contentVC = UIHostingController(rootView: self)
    parentViewController.addChild(contentVC)
    contentVC.view.translatesAutoresizingMaskIntoConstraints = false
    parentViewController.view.addSubview(contentVC.view)
    contentVC.didMove(toParent: parentViewController)

    NSLayoutConstraint.activate([
      contentVC.view.topAnchor.constraint(equalTo: parentViewController.view.topAnchor),
      contentVC.view.bottomAnchor.constraint(equalTo: parentViewController.view.bottomAnchor),
      contentVC.view.leadingAnchor.constraint(equalTo: parentViewController.view.leadingAnchor),
      contentVC.view.trailingAnchor.constraint(equalTo: parentViewController.view.trailingAnchor),
    ])
  }
}
