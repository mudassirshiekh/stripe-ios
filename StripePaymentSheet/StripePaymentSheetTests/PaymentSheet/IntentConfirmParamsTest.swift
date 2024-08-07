//
//  IntentConfirmParamsTest.swift
//  StripePaymentSheetTests
//

import Foundation

@testable import StripePaymentSheet
import StripePaymentsTestUtils
import XCTest

class IntentConfirmParamsTest: XCTestCase {
    func testAllCases() {
        let testCases: [(IntentConfirmParams.SaveForFutureUseCheckboxState, PaymentSheetComponentFeature?, Bool, STPPaymentMethodAllowRedisplay)] = [
            // Legacy
            (saveForFutureUseCheckboxState: .hidden, paymentSheetComponentFeature: nil, isSettingUp: true, expectedResult: .unspecified),
            (saveForFutureUseCheckboxState: .selected, paymentSheetComponentFeature: nil, isSettingUp: true, expectedResult: .unspecified),
            (saveForFutureUseCheckboxState: .deselected, paymentSheetComponentFeature: nil, isSettingUp: false, expectedResult: .unspecified),

            // MARK: CustomerSession, PI+SFU & SetupIntent
            (saveForFutureUseCheckboxState: .selected, paymentSheetComponentFeature: .init(paymentMethodSave: true, paymentMethodRemove: false, paymentMethodSaveAllowRedisplayOverride: nil), isSettingUp: true, expectedResult: .always),

        ]
        for (saveForFutureUseCheckboxState, paymentSheetComponentFeature, isSettingUp, expectedResult) in testCases {
            XCTContext.runActivity(named: "checkboxState: \(saveForFutureUseCheckboxState), paymentSheetComponentFeatur isSettingUp: \(isSettingUp)") { activity in
                
                let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

                intentConfirmParams.saveForFutureUseCheckboxState = saveForFutureUseCheckboxState
                intentConfirmParams.setAllowRedisplay(paymentSheetFeatures: paymentSheetComponentFeature, isSettingUp: isSettingUp)

                XCTAssertEqual(expectedResult, intentConfirmParams.paymentMethodParams.allowRedisplay)
            }
        }


    }

    // MARK: Legacy
    func testSetAllowRedisplay_legacySI() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.saveForFutureUseCheckboxState = .hidden
        intentConfirmParams.setAllowRedisplay(paymentSheetFeatures: nil, isSettingUp: true)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_legacyPI_selected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.saveForFutureUseCheckboxState = .selected
        intentConfirmParams.setAllowRedisplay(paymentSheetFeatures: nil, isSettingUp: false)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_legacyPI_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.saveForFutureUseCheckboxState = .deselected
        intentConfirmParams.setAllowRedisplay(paymentSheetFeatures: nil, isSettingUp: false)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    // MARK: CustomerSession, PI+SFU & SetupIntent
    func testSetAllowRedisplay_SI_saveEnabled_selected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        intentConfirmParams.setAllowRedisplay(paymentSheetFeatures: .init(paymentMethodSave: true, paymentMethodRemove: false, paymentMethodSaveAllowRedisplayOverride: nil),
                                              isSettingUp: true)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_SI_saveEnabled_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        intentConfirmParams.setAllowRedisplay(paymentSheetFeatures: .init(paymentMethodSave: true, paymentMethodRemove: false, paymentMethodSaveAllowRedisplayOverride: nil),
                                              isSettingUp: true)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    func testInvalidState_SetAllowRedisplay_SI_saveEnabled_allowRedisplay() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        // The backend will prevent allowRedisplayValue from being set, when paymentMethodSave is set to enabled
        // but our code should be defensive enough to ensure allowRedisplayOverride does not override the value
        intentConfirmParams.setAllowRedisplay(paymentSheetFeatures: .init(paymentMethodSave: true, paymentMethodRemove: false, paymentMethodSaveAllowRedisplayOverride: .always),
                                              isSettingUp: true)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    func testSetAllowRedisplay_SI_saveDisabled() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .hidden

        intentConfirmParams.setAllowRedisplay(paymentSheetFeatures: .init(paymentMethodSave: false, paymentMethodRemove: false, paymentMethodSaveAllowRedisplayOverride: nil),
                                              isSettingUp: true)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    func testSetAllowRedisplay_SI_saveDisabled_allowRedisplayOverrideAlways() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .hidden

        intentConfirmParams.setAllowRedisplay(paymentSheetFeatures: .init(paymentMethodSave: false, paymentMethodRemove: false, paymentMethodSaveAllowRedisplayOverride: .always),
                                              isSettingUp: true)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_SI_saveDisabled_allowRedisplayOverrideLimited() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .hidden

        intentConfirmParams.setAllowRedisplay(paymentSheetFeatures: .init(paymentMethodSave: false, paymentMethodRemove: false, paymentMethodSaveAllowRedisplayOverride: .limited),
                                              isSettingUp: true)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_SI_saveDisabled_allowRedisplayOverrideUnspecified() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .hidden

        intentConfirmParams.setAllowRedisplay(paymentSheetFeatures: .init(paymentMethodSave: false, paymentMethodRemove: false, paymentMethodSaveAllowRedisplayOverride: .unspecified),
                                              isSettingUp: true)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    // MARK: CustomerSession, Payment Intents
    func testSetAllowRedisplay_PI_saveEnabled_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        intentConfirmParams.setAllowRedisplay(paymentSheetFeatures: .init(paymentMethodSave: true, paymentMethodRemove: false, paymentMethodSaveAllowRedisplayOverride: nil),
                                              isSettingUp: false)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_PI_saveEnabled_selected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        intentConfirmParams.setAllowRedisplay(paymentSheetFeatures: .init(paymentMethodSave: true, paymentMethodRemove: false, paymentMethodSaveAllowRedisplayOverride: nil),
                                              isSettingUp: false)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_PI_saveDisabled_hidden() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.setAllowRedisplay(paymentSheetFeatures: .init(paymentMethodSave: false, paymentMethodRemove: false, paymentMethodSaveAllowRedisplayOverride: nil),
                                              isSettingUp: false)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    func testSetAllowRedisplay_PI_saveDisabled_hidden_doesNotOverride() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.setAllowRedisplay(paymentSheetFeatures: .init(paymentMethodSave: false, paymentMethodRemove: false, paymentMethodSaveAllowRedisplayOverride: .limited),
                                              isSettingUp: false)

        // Ensure that allowRedisplayOverride doesn't override: (hidden checkbox and not attached to customer)
        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    // MARK: CustomerSheet
    func testSetAllowRedisplayForCustomerSheet_legacy() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.setAllowRedisplayForCustomerSheet(.legacy)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplayForCustomerSheet_customerSession() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.setAllowRedisplayForCustomerSheet(.customerSheetWithCustomerSession)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
}
