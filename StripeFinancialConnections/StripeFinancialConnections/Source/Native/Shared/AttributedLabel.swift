//
//  Label.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 5/8/23.
//

import Foundation
import UIKit

// Prefer `AttributedLabel` over `AttributedTextView` for single-line text.
final class AttributedLabel: UILabel {

    private let customFont: FinancialConnectionsFont
    private let customTextColor: UIColor

    init(font: FinancialConnectionsFont, textColor: UIColor) {
        self.customFont = font
        self.customTextColor = textColor
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // UILabel with custom `lineHeight` via `NSParagraphStyle` was not properly
    // centering the text, so here we adjust it to be centered.
    override func drawText(in rect: CGRect) {
        guard
            let attributedText = self.attributedText,
            let font = attributedText.attributes(at: 0, effectiveRange: nil)[.font] as? UIFont,
            let paragraphStyle = attributedText.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        else {
            super.drawText(in: rect)
            return
        }
        let uiFontLineHeight = font.lineHeight
        let paragraphStyleLineHeight = paragraphStyle.minimumLineHeight
        assert(paragraphStyle.minimumLineHeight == paragraphStyle.maximumLineHeight, "we are assuming that minimum and maximum are the same")

        if paragraphStyleLineHeight > uiFontLineHeight {
            let lineHeightDifference = (paragraphStyle.minimumLineHeight - uiFontLineHeight)
            let newRect = CGRect(
                x: rect.origin.x,
                y: rect.origin.y - lineHeightDifference / 2,
                width: rect.width,
                height: rect.height
            )
            super.drawText(in: newRect)
        } else {
            super.drawText(in: rect)
        }
    }

    func setText(_ text: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = customFont.lineHeight
        paragraphStyle.maximumLineHeight = customFont.lineHeight
        let string = NSMutableAttributedString(
            string: text,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: customFont.uiFont,
                .foregroundColor: customTextColor,
            ]
        )
        attributedText = string
    }
}
