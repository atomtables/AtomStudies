//
//  OrientationInfo.swift
//  AtomStudies
//
//  Created by Adithiya Venkatakrishnan on 9/2/2025.
//

import SwiftUI
import UIKit

@Observable
final class OrientationInfo {
    enum Orientation {
        case portrait
        case landscape
    }

    var orientation: Orientation

    private var _observer: NSObjectProtocol?

    init() {
        // fairly arbitrary starting value for 'flat' orientations
        if UIDevice.current.orientation.isLandscape {
            self.orientation = .landscape
        }
        else {
            self.orientation = .portrait
        }

        // unowned self because we unregister before self becomes invalid
        _observer = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [unowned self] note in
            guard let device = note.object as? UIDevice else {
                return
            }
            if device.orientation.isPortrait {
                self.orientation = .portrait
            }
            else if device.orientation.isLandscape {
                self.orientation = .landscape
            }
        }
    }

    deinit {
        if let observer = _observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

