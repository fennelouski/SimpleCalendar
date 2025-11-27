//
//  PlatformTypes.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import SwiftUI

#if os(macOS)
import AppKit
public typealias PlatformImage = NSImage
#elseif os(tvOS)
import UIKit
public typealias PlatformImage = UIImage
#else
import UIKit
public typealias PlatformImage = UIImage
#endif

// Cross-platform Image extension
extension Image {
    init(platformImage: PlatformImage) {
        #if os(macOS)
        self.init(nsImage: platformImage)
        #elseif os(tvOS)
        self.init(uiImage: platformImage)
        #else
        self.init(uiImage: platformImage)
        #endif
    }
}
