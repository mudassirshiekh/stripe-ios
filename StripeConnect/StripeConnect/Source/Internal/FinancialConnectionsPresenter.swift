//
//  FinancialConnectionsPresenter.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/18/24.
//

@_spi(STP) import StripeCore
import StripeFinancialConnections
import UIKit

protocol FinancialConnectionSheetImplementation: AnyObject {
    init(financialConnectionsSessionClientSecret: String, returnURL: String?)
    var apiClient: STPAPIClient { get set}
    func presentForToken(
        from presentingViewController: UIViewController,
        completion: @escaping (FinancialConnectionsSheet.TokenResult) -> Void
    )
}

extension FinancialConnectionsSheet: FinancialConnectionSheetImplementation {}

/// Wraps `FinancialConnectionsSheet` for easy dependency injection in tests
class FinancialConnectionsPresenter {
    @MainActor
    @available(iOS 15, *)
    func presentForToken(
        componentManager: EmbeddedComponentManager,
        clientSecret: String,
        connectedAccountId: String,
        from presentingViewController: UIViewController,
        financialConnectionSheetInitializer: (_ secret: String, _ returnURL: String?) -> FinancialConnectionSheetImplementation = FinancialConnectionsSheet.init
    ) async -> FinancialConnectionsSheet.TokenResult {
        let financialConnectionsSheet = financialConnectionSheetInitializer(clientSecret, nil)
        // FC needs the connected account ID to be configured on the API Client
        // Make a copy before modifying so we don't unexpectedly modify the shared API client
        financialConnectionsSheet.apiClient = componentManager.apiClient.makeCopy()
        
        // FC expects a public key and not a UK. If there is a public key override we should use that.
        financialConnectionsSheet.apiClient.publishableKey = componentManager.publicKeyOverride ?? financialConnectionsSheet.apiClient.publishableKey
        financialConnectionsSheet.apiClient.stripeAccount = connectedAccountId
        return await withCheckedContinuation { continuation in
            financialConnectionsSheet.presentForToken(from: presentingViewController) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
