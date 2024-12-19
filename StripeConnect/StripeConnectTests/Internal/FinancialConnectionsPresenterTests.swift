//
//  FinancialConnectionsPresenterTests.swift
//  StripeConnect
//
//  Created by Chris Mays on 12/18/24.
//
@_spi(PrivateBetaConnect) @_spi(DashboardOnly) @testable import StripeConnect
@testable import StripeFinancialConnections

import UIKit
import XCTest

class FinancialConnectionsPresenterTests: XCTestCase {
    
    func testStandardPresent() async {
        let presenter = FinancialConnectionsPresenter()
        
        let clientSecret = "client_secret"
        let connectedAccountId = "account_1234"
        let publishableKey = "pk_12"
        
        let componentManager = EmbeddedComponentManager(apiClient: .init(publishableKey: publishableKey),
                                                        appearance: .default,
                                                        fonts: [],
                                                        fetchClientSecret: {return nil})
        
        var sheetMock: FinancialConnectionsSheetMock?
        
        _ = await presenter.presentForToken(componentManager: componentManager, clientSecret: clientSecret, connectedAccountId: connectedAccountId, from: .init()) { clientSecret, returnURL in
            let mock: FinancialConnectionsSheetMock = .init(financialConnectionsSessionClientSecret: clientSecret, returnURL: returnURL)
            sheetMock = mock
            return mock
        }
        
        XCTAssertEqual(sheetMock?.apiClient.publishableKey, publishableKey)
        XCTAssertEqual(sheetMock?.apiClient.stripeAccount, connectedAccountId)
        XCTAssertEqual(sheetMock?.clientSecret, clientSecret)
        
    }
    
    func testPresentWithPublicKeyOverride() async {
        let clientSecret = "client_secret"
        let connectedAccountId = "account_1234"
        let ukKey = "uk_123"
        let publishableKey = "pk_12"
        
        let presenter = FinancialConnectionsPresenter()
        let componentManager = EmbeddedComponentManager(apiClient: .init(publishableKey: ukKey),
                                                        appearance: .default,
                                                        publicKeyOverride: publishableKey,
                                                        baseURLOverride: nil)
        
        
        var sheetMock: FinancialConnectionsSheetMock?
        
        _ = await presenter.presentForToken(componentManager: componentManager, clientSecret: clientSecret, connectedAccountId: connectedAccountId, from: .init()) { clientSecret, returnURL in
            let mock: FinancialConnectionsSheetMock = .init(financialConnectionsSessionClientSecret: clientSecret, returnURL: returnURL)
            sheetMock = mock
            return mock
        }
        
        XCTAssertEqual(sheetMock?.apiClient.publishableKey, publishableKey)
        XCTAssertEqual(sheetMock?.apiClient.stripeAccount, connectedAccountId)
        XCTAssertEqual(sheetMock?.clientSecret, clientSecret)
    }
    
}


class FinancialConnectionsSheetMock: FinancialConnectionSheetImplementation {
    let clientSecret: String
    let returnURL: String?
    var returnedResult: FinancialConnectionsSheet.TokenResult = .canceled
    required init(financialConnectionsSessionClientSecret: String, returnURL: String?) {
        self.clientSecret = financialConnectionsSessionClientSecret
        self.returnURL = returnURL
    }
    var apiClient: STPAPIClient = .shared
    func presentForToken(from presentingViewController: UIViewController, completion: @escaping (FinancialConnectionsSheet.TokenResult) -> Void) {
        completion(returnedResult)
    }
}
