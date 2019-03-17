//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  Provides supporting functions for setting up a live view.
//

import UIKit
import PlaygroundSupport

/// Instantiates a new instance of a live view.
///
/// By default, this loads an instance of `LiveViewController` from `LiveView.storyboard`.
public func instantiateLiveView() -> PlaygroundLiveViewable {
    let storyboard = UIStoryboard(name: "LiveView", bundle: nil)

    guard let viewController = storyboard.instantiateInitialViewController() else {
        fatalError("Main.storyboard does not have an initial scene; please set one or update this function")
    }
	
	dump(viewController as! ViewController)
	

    guard let liveViewController = viewController as? ViewController else {
        fatalError("Main.storyboard's initial scene is not a ViewController; please either update the storyboard or this function")
    }

    return liveViewController
}

