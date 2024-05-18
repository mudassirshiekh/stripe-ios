//
//  ComponentWebView.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

@_spi(STP) import StripeCore
import UIKit
import WebKit

/// Wraps a `StripeComponentInstance`
class ConnectComponentWebView: ConnectWebView {
    private var connectInstance: StripeConnectInstance
    private var componentType: String
    private var shouldUseHorizontalPadding: Bool

    /// The content controller that registers JS -> Swift message handlers
    private let contentController: WKUserContentController

    init(connectInstance: StripeConnectInstance,
         componentType: String,
         shouldUseHorizontalPadding: Bool = true) {
        self.connectInstance = connectInstance
        self.componentType = componentType
        self.shouldUseHorizontalPadding = shouldUseHorizontalPadding

        contentController = WKUserContentController()
        let config = WKWebViewConfiguration()

        // Allows for custom JS message handlers for JS -> Swift communication
        config.userContentController = contentController

        // Allows the identity verification flow to display the camera feed
        // embedded in the web view instead of full screen. Also works for
        // embedded YouTube videos.
        config.allowsInlineMediaPlayback = true

        super.init(frame: .zero, configuration: config)

        addMessageHandlers()
        addDebugReloadButton()
        loadContents()
        didUpdateColors()
        addNotificationObservers()
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            didUpdateAppearance()
        }
    }
}

// MARK: - Internal

extension ConnectComponentWebView {
    /// Calls `update({appearance: ...})` on the JS StripeConnectInstance
    func didUpdateAppearance() {
        let appearance = connectInstance.appearance
        var script = """
            updateAppearance(\(appearance.asJsonString));
        """

        if shouldUseHorizontalPadding {
            script += """
                document.body.style.marginRight = '\(appearance.horizontalPadding.pxString)';
                document.body.style.marginLeft = '\(appearance.horizontalPadding.pxString)';
            """
        }

        evaluateJavaScript(script)
        didUpdateColors()
    }

    /// Calls `logout()` on the JS StripeConnectInstance
    func logout() async {
        _ = try? await evaluateJavaScript("stripeConnectInstance.logout()")
    }

    /// Convenience method to add `ScriptMessageHandler`
    func addMessageHandler(_ messageHandler: ScriptMessageHandler,
                           contentWorld: WKContentWorld = .page) {
        contentController.add(messageHandler, contentWorld: contentWorld, name: messageHandler.name)
    }

    /// Convenience method to add `ScriptMessageHandlerWithReply`
    func addMessageHandler<T>(_ messageHandler: ScriptMessageHandlerWithReply<T>,
                              contentWorld: WKContentWorld = .page) {
        contentController.addScriptMessageHandler(messageHandler, contentWorld: contentWorld, name: messageHandler.name)
    }
}

// MARK: - Private

private extension ConnectComponentWebView {
    /// Registers JS -> Swift message handlers
    func addMessageHandlers() {
        addMessageHandler(.init(name: "debug", didReceiveMessage: { message in
            debugPrint(message.body)
        }))
        addMessageHandler(.init(name: "fetchClientSecret", didReceiveMessage: { [weak self] _ in
            return await self?.connectInstance.fetchClientSecret()
        }))
    }

    /// Adds NotificationCenter observers
    func addNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.evaluateJavaScript("stripeConnectInstance.update({locale: \(Locale.autoupdatingCurrent.webIdentifier)})")
        }
    }

    /// Updates the view's background color to match appearance.
    /// - Note: This avoids a white flash when initially loading the page when a background color is set
    func didUpdateColors() {
        backgroundColor = connectInstance.appearance.colorBackground ?? .systemBackground
    }

    /**
     Loads the contents of `template.html`, passing in appearance, componentType,
     and publishableKey, then spoofs it's coming from connect-js.stripe.com.

     - Note: This is a temporary hack. Long term, we should host this page on connect-js.stripe.com

     TODO: Delete this function before beta release
     */
    func loadContents() {
        // Load HTML file and spoof that it's coming from connect-js.stripe.com
        // to avoid CORS restrictions from loading a local file.
        guard let htmlFile = BundleLocator.resourcesBundle.url(forResource: "template", withExtension: "html"),
              var htmlText = try? String(contentsOf: htmlFile, encoding: .utf8) else {
            debugPrint("Couldn't load `template.html`")
            return
        }

        let horizontalMargin = shouldUseHorizontalPadding ? connectInstance.appearance.horizontalPadding : 0

        // NOTE (Locale):
        // By default, WKWebViews use the device's first preferred locale instead
        // of the app's locale, so we have to explicitly pass the current locale
        // to the JS connect instance.

        // TODO: Error handle if PK is nil
        htmlText = htmlText
            .replacingOccurrences(of: "{{COMPONENT_TYPE}}", with: componentType)
            .replacingOccurrences(of: "{{PUBLISHABLE_KEY}}", with: connectInstance.apiClient.publishableKey ?? "")
            .replacingOccurrences(of: "{{APPEARANCE}}", with: connectInstance.appearance.asJsonString)
            .replacingOccurrences(of: "{{FONTS}}", with: connectInstance.customFonts.asJsonString)
            .replacingOccurrences(of: "{{LOCALE}}", with: Locale.autoupdatingCurrent.webIdentifier)
            .replacingOccurrences(of: "{{HORIZONTAL_MARGIN}}", with: horizontalMargin.pxString)

        guard let data = htmlText.data(using: .utf8) else {
            debugPrint("Couldn't encode html data")
            return
        }

        load(data, mimeType: "text/html", characterEncodingName: "utf8", baseURL: StripeConnectConstants.connectWrapperURL)
    }

    /**
     Overlays a "Reload" button on top of the web view, for debug purposes only
     so the contents can be reloaded after connecting to the Safari debugger.
     
     - Note: This is only needed while we're implementing the hack to spoof
     `connect-js.stripe.com` mentioned in `loadContents` comments. The Safari 
     debugger has a reload button, however it currently loads `connect-js.stripe.com`
     instead of reloading `template.html`. Once this has been updated to use a
     remote web page, the refresh button in the Safari debugger will be sufficient.

     TODO: Delete this function before beta release
     */
    func addDebugReloadButton() {
        #if DEBUG
        let reloadButton = UIButton(
            type: .system,
            primaryAction: .init(handler: { [weak self] _ in
                // Calling `reload` will just load `connect-js.stripe.com`,
                // so we need to reload the contents instead.
                self?.loadContents()
            })
        )
        reloadButton.setTitle("Reload", for: .normal)
        reloadButton.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        reloadButton.layer.cornerRadius = 4

        addSubview(reloadButton)
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            reloadButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            reloadButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -8),
        ])

        #endif
    }
}

extension Locale {
    /// iOS uses underscores for locale (`en_US`) but web uses hyphens (`en-US`)
    var webIdentifier: String {
        guard let region = stp_regionCode,
              let language = stp_languageCode else {
            return ""
        }
        return "\(language)-\(region)"
    }
}
