//
//  NetworkingLinkVerificationDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/7/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol NetworkingLinkVerificationDataSource: AnyObject {
    var accountholderCustomerEmailAddress: String { get }
    var manifest: FinancialConnectionsSessionManifest { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var consumerSession: ConsumerSessionData? { get }
    var networkingOTPDataSource: NetworkingOTPDataSource { get }

    func markLinkVerified() -> Future<FinancialConnectionsSessionManifest>
    func fetchNetworkedAccounts() -> Future<FinancialConnectionsNetworkedAccountsResponse>
    func attachConsumerToLinkAccountAndSynchronize() -> Future<FinancialConnectionsSynchronize>
}

final class NetworkingLinkVerificationDataSourceImplementation: NetworkingLinkVerificationDataSource {

    let accountholderCustomerEmailAddress: String
    let manifest: FinancialConnectionsSessionManifest
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    private let returnURL: String?
    private let consumerPublishableKey: String?
    let analyticsClient: FinancialConnectionsAnalyticsClient
    let networkingOTPDataSource: NetworkingOTPDataSource

    private(set) var consumerSession: ConsumerSessionData?

    init(
        accountholderCustomerEmailAddress: String,
        manifest: FinancialConnectionsSessionManifest,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        returnURL: String?,
        consumerPublishableKey: String?,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.accountholderCustomerEmailAddress = accountholderCustomerEmailAddress
        self.manifest = manifest
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.returnURL = returnURL
        self.consumerPublishableKey = consumerPublishableKey
        self.analyticsClient = analyticsClient
        let networkingOTPDataSource = NetworkingOTPDataSourceImplementation(
            otpType: "SMS",
            emailAddress: accountholderCustomerEmailAddress,
            customEmailType: nil,
            connectionsMerchantName: nil,
            pane: .networkingLinkVerification,
            consumerSession: nil,
            apiClient: apiClient,
            clientSecret: clientSecret,
            analyticsClient: analyticsClient,
            isTestMode: manifest.isTestMode,
            theme: manifest.theme
        )
        self.networkingOTPDataSource = networkingOTPDataSource
        networkingOTPDataSource.delegate = self
    }

    func markLinkVerified() -> Future<FinancialConnectionsSessionManifest> {
        return apiClient.markLinkVerified(clientSecret: clientSecret)
    }

    func fetchNetworkedAccounts() -> Future<FinancialConnectionsNetworkedAccountsResponse> {
        guard let consumerSessionClientSecret = consumerSession?.clientSecret else {
            return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "invalid confirmVerificationSession state: no consumerSessionClientSecret"))
        }
        return apiClient.fetchNetworkedAccounts(
            clientSecret: clientSecret,
            consumerSessionClientSecret: consumerSessionClientSecret
        )
    }

    func attachConsumerToLinkAccountAndSynchronize() -> Future<FinancialConnectionsSynchronize> {
        guard manifest.isProductInstantDebits else {
            return Promise(error: FinancialConnectionsSheetError.unknown(
                debugDescription: "Invalid \(#function) state: should only be used in instant debits flow"
            ))
        }

        guard let consumerPublishableKey else {
            return Promise(error: FinancialConnectionsSheetError.unknown(
                debugDescription: "Invalid \(#function) state: no consumerPublishableKey"
            ))
        }

        guard let consumerSessionClientSecret = consumerSession?.clientSecret else {
            return Promise(error: FinancialConnectionsSheetError.unknown(
                debugDescription: "Invalid \(#function) state: no consumerSessionClientSecret"
            ))
        }

        return apiClient.attachLinkConsumerToLinkAccountSession(
            requestSurface: "ios_instant_debits",
            linkAccountSession: clientSecret,
            consumerSessionClientSecret: consumerSessionClientSecret
        )
        .chained { [weak self] _ in
            guard let self else {
                return Promise(error: FinancialConnectionsSheetError.unknown(
                    debugDescription: "Data source deallocated"
                ))
            }

            let consumerApiClient = STPAPIClient(publishableKey: consumerPublishableKey)
            return consumerApiClient.synchronize(
                clientSecret: self.clientSecret,
                returnURL: self.returnURL
            )
        }
    }
}

// MARK: - NetworkingOTPDataSourceDelegate

extension NetworkingLinkVerificationDataSourceImplementation: NetworkingOTPDataSourceDelegate {

    func networkingOTPDataSource(_ dataSource: NetworkingOTPDataSource, didUpdateConsumerSession consumerSession: ConsumerSessionData) {
        self.consumerSession = consumerSession
    }
}
