import UIKit

/// @mockable
@MainActor
public protocol SearchBuildable {
    func build(listener: SearchListener) -> UIViewController
}

/// @mockable
@MainActor
public protocol SearchListener: AnyObject {
    func searchDidComplete()
}
