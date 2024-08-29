//
//  PaymentSheet+NSNotification.swift
//  StripePaymentSheet
//

import Foundation

@_spi(MobilePaymentElementEventsBeta)
public extension Notification.Name {
    static let mobilePaymentElement = Notification.Name("MobilePaymentElement")
}


@_spi(MobilePaymentElementEventsBeta)
public struct MobilePaymentElementEvent {
    let eventName: String
    let metadata: [String: Any?]
}
