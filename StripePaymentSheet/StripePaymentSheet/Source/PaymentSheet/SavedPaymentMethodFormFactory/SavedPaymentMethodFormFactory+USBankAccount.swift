//
//  SavedPaymentMethodFormFactory+USBankAccount.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/22/24.
//

import Foundation
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

extension SavedPaymentMethodFormFactory {
    func makeUSBankAccount() -> UIView {
        let nameElement: SectionElement = {
            let nameElement = SectionElement(elements: [TextFieldElement.NameConfiguration(defaultValue: viewModel.paymentMethod.billingDetails?.name, isEditable: false).makeElement(theme: viewModel.appearance.asElementsTheme)])
            nameElement.view.layer.backgroundColor = transparentMaskViewBackgroundColor().cgColor
            return nameElement
        }()
        let emailElement: SectionElement = {
            let emailElement = SectionElement(elements: [TextFieldElement.EmailConfiguration(defaultValue: viewModel.paymentMethod.billingDetails?.email, isEditable: false).makeElement(theme: viewModel.appearance.asElementsTheme)])
            emailElement.view.layer.backgroundColor = transparentMaskViewBackgroundColor().cgColor
            return emailElement
        }()
        let bankAccountElement: SectionElement = {
            let bankAccountElement = SectionElement(elements: [TextFieldElement.USBankNumberConfiguration(bankName: viewModel.paymentMethod.usBankAccount?.bankName ?? "Bank name", lastFour: viewModel.paymentMethod.usBankAccount?.last4 ?? "").makeElement(theme: viewModel.appearance.asElementsTheme)])
            bankAccountElement.view.layer.backgroundColor = transparentMaskViewBackgroundColor().cgColor
            return bankAccountElement
        }()
        let stackView = UIStackView(arrangedSubviews: [nameElement.view, emailElement.view, bankAccountElement.view])
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.setCustomSpacing(8, after: nameElement.view) // custom spacing from figma
        stackView.setCustomSpacing(8, after: emailElement.view) // custom spacing from figma
        return stackView
    }
}
