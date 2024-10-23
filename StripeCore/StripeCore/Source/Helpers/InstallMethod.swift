//
//  InstallMethod.swift
//  StripeCore
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) public enum InstallMethod: String {
    case cocoapods = "C"
    case spm = "S"
    case binary = "B"  // Built via export_builds.sh
    case xcode = "X"  // Directly built via Xcode or xcodebuild

    @_spi(STP) public static let current: InstallMethod = {
        #if COCOAPODS
            return .cocoapods
        #elseif SWIFT_PACKAGE
            return .spm
        #elseif STRIPE_BUILD_PACKAGE
            return .binary
        #else
            return .xcode
        #endif
    }()
}
