
import Foundation
import Flutter
import MSAL
import UIKit

struct MsalFlutterConfigurationError: Error {
    let code: String
    let message: String
    let details: [String: Any]

    init(code: String, message: String, details: [String: Any] = [:]) {
        self.code = code
        self.message = message
        self.details = details
    }

    func flutterError(configuration: NSDictionary) -> FlutterError {
        return FlutterError(code: code, message: message, details: details)
    }
}

// Normaliza valores opcionales y atributos para el códec estándar de Flutter.
func msalChannelValue(_ value: Any?) -> Any {
    guard let value = value else { return NSNull() }
    if let date = value as? Date { return ISO8601DateFormatter().string(from: date) }
    if let dictionary = value as? [String: Any] {
        return dictionary.mapValues { msalChannelValue($0) }
    }
    if let array = value as? [Any] { return array.map { msalChannelValue($0) } }
    if value is String || value is NSNumber || value is NSNull { return value }
    return String(describing: value)
}

extension MSALAccount {
    var nsDictionary: NSDictionary {
        return [
            "username": msalChannelValue(username),
            "identifier": msalChannelValue(identifier),
            "environment": msalChannelValue(environment),
            "isSSOAccount": isSSOAccount,
            "accountClaims": msalChannelValue(accountClaims)
        ] as NSDictionary
    }
}

extension MSALWebviewParameters {
    func fromDict(dictionary: NSDictionary) {
        if dictionary["webviewType"] != nil {
            webviewType = MSALWebviewType.fromString(entry: dictionary["webviewType"] as? String)
        }
        if #available(iOS 13.0, *) {
            prefersEphemeralWebBrowserSession = dictionary["prefersEphemeralWebBrowserSession"] as? Bool ?? false
        }
        if dictionary["presentationStyle"] != nil {
            presentationStyle = UIModalPresentationStyle.fromString(entry: dictionary["presentationStyle"] as? String)
        }


    }
}

extension MSALWebviewType {
    static func fromString(entry: String?) -> MSALWebviewType {
        switch entry {
        case "safariViewController":
            return MSALWebviewType.safariViewController
        case "authenticationSession":
            return MSALWebviewType.authenticationSession
        case "wkWebView":
            return MSALWebviewType.wkWebView
        case "default":
            return MSALWebviewType.default
        default:
            return MSALWebviewType.default
        }
    }
}

extension UIModalPresentationStyle {
    static func fromString(entry: String?) -> UIModalPresentationStyle {
        switch entry {
        case "fullScreen":
            return .fullScreen
        case "pageSheet":
            return .pageSheet
        case "formSheet":
            return .formSheet
        case "currentContext":
            return .currentContext
        case "custom":
            return .custom
        case "overFullScreen":
            return .overFullScreen
        case "overCurrentContext":
            return .overCurrentContext
        case "popover":
            return .popover
        case "none":
            return .none
        case "automatic":
            if #available(iOS 13.0, *) {
                return .automatic
            } else {
                return .fullScreen
            }
        default:
            return .fullScreen
        }
    }
}

extension MSALPublicClientApplicationConfig {
    static func fromDict(dictionary: NSDictionary) throws -> MSALPublicClientApplicationConfig {
        guard let clientId = dictionary["clientId"] as? String,
              clientId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw MsalFlutterConfigurationError(
                code: "NO_CLIENTID",
                message: "Call must include a non-empty clientId"
            )
        }

        // Sin autoridad explícita, MSAL conserva su autoridad AAD genérica predeterminada.
        let authority = try MSALAuthority.fromString(entry: dictionary["authority"] as? String)

        let redirectUri = (dictionary["redirectUri"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let config = MSALPublicClientApplicationConfig(
            clientId: clientId,
            redirectUri: redirectUri?.isEmpty == false ? redirectUri : self.generatedRedirectUri(),
            authority: authority
        )
        config.bypassRedirectURIValidation = dictionary["bypassRedirectURIValidation"] as? Bool ?? false
        config.clientApplicationCapabilities = dictionary["clientApplicationCapabilities"] as? [String]
        config.extendedLifetimeEnabled = dictionary["extendedLifetimeEnabled"] as? Bool ?? false

        var knownAuthorities: [MSALAuthority] = authority.map { [$0] } ?? []
        if let rawKnownAuthorities = dictionary["knownAuthorities"] {
            guard let knownAuthorityStrings = rawKnownAuthorities as? [String] else {
                throw MsalFlutterConfigurationError(
                    code: "INVALID_AUTHORITY",
                    message: "knownAuthorities must be a list of authority URLs"
                )
            }

            for (index, item) in knownAuthorityStrings.enumerated() {
                guard let knownAuthority = try MSALAuthority.fromString(entry: item) else {
                    throw MsalFlutterConfigurationError(
                        code: "INVALID_AUTHORITY",
                        message: "knownAuthorities[\(index)] must be a non-empty authority URL"
                    )
                }
                knownAuthorities.append(knownAuthority)
            }
        }

        config.knownAuthorities = knownAuthorities
        if dictionary["cacheConfig"] != nil {
            guard let cacheConfig = dictionary["cacheConfig"] as? NSDictionary else {
                throw MsalFlutterConfigurationError(
                    code: "CONFIG_ERROR",
                    message: "cacheConfig must be a dictionary"
                )
            }
            config.cacheConfig.fromDict(dict: cacheConfig)
        }
        config.multipleCloudsSupported = dictionary["multipleCloudsSupported"] as? Bool ?? false
        config.sliceConfig = MSALSliceConfig.fromDict(dict: dictionary["sliceConfig"] as? NSDictionary)
        if let tokenBuff = dictionary["tokenExpirationBuffer"] as? NSNumber {
            config.tokenExpirationBuffer = tokenBuff.doubleValue
        }
        return config
    }


    static func generatedRedirectUri() -> String? {
        if let bundleId = Bundle.main.bundleIdentifier {
            return "msauth." + bundleId + "://auth"
        }
        return nil
    }
}

extension MSALAuthority {
    static func fromString(entry: String?) throws -> MSALAuthority? {
        guard let entry = entry?.trimmingCharacters(in: .whitespacesAndNewlines),
              entry.isEmpty == false else {
            return nil
        }

        guard let authorityUrl = URL(string: entry),
              let scheme = authorityUrl.scheme?.lowercased(),
              scheme == "https",
              authorityUrl.host?.isEmpty == false else {
            throw MsalFlutterConfigurationError(
                code: "INVALID_AUTHORITY",
                message: "Authority must be an absolute HTTPS URL"
            )
        }

        return try MSALAuthority(url: authorityUrl)
    }
}

extension MSALCacheConfig {
    func fromDict(dict: NSDictionary) {
        if let keychain = dict["keychainSharingGroup"] as? String,
           keychain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            keychainSharingGroup = keychain
        }

    }
}

extension MSALSliceConfig {
    static func fromDict(dict: NSDictionary?) -> MSALSliceConfig? {
        if let dict = dict {
            return MSALSliceConfig(slice: dict["slice"] as? String, dc: dict["dc"] as? String)
        }
        return nil
    }
}

extension MSALInteractiveTokenParameters {
    static func fromDict(dict: NSDictionary, param: MSALWebviewParameters) throws -> MSALInteractiveTokenParameters {
        var tokenParam: MSALInteractiveTokenParameters
        guard let scopes = dict["scopes"] as? [String] else {
            throw MsalFlutterConfigurationError(code: "NO_SCOPE", message: "scopes must be a list of strings")
        }
        tokenParam = MSALInteractiveTokenParameters(scopes: scopes, webviewParameters: param)
        tokenParam.fromDict(dict: dict)
        if dict["authority"] != nil {
            tokenParam.authority = try MSALAuthority.fromString(entry: dict["authority"] as? String)
        }

        tokenParam.promptType = MSALPromptType.fromString(entry: dict["promptType"] as? String)
        tokenParam.extraScopesToConsent = dict["extraScopesToConsent"] as? [String]
        tokenParam.loginHint = dict["loginHint"] as? String

        return tokenParam
    }

}

extension MSALPromptType {
    static func fromString(entry: String?) -> MSALPromptType {
        switch entry {
        case "consent":
            return MSALPromptType.consent
        case "create":
            return MSALPromptType.create
        case "login":
            return MSALPromptType.login
        case "promptIfNecessary":
            return MSALPromptType.promptIfNecessary
        case "selectAccount":
            return MSALPromptType.selectAccount
        case "defaultType":
            return MSALPromptType.default
        default:
            return MSALPromptType.default
        }
    }
}

extension MSALTokenParameters {
    func fromDict(dict: NSDictionary) {
        extraQueryParameters = dict["extraQueryParameters"] as? [String: String]
        correlationId = UUID(uuidString: dict["correlationId"] as? String ?? "")

    }
}

extension MSALSilentTokenParameters {
    static func fromDict(dict: NSDictionary, account: MSALAccount) throws -> MSALSilentTokenParameters {
        var silentParam: MSALSilentTokenParameters

        guard let scopes = dict["scopes"] as? [String] else {
            throw MsalFlutterConfigurationError(code: "NO_SCOPE", message: "scopes must be a list of strings")
        }
        silentParam = MSALSilentTokenParameters(scopes: scopes, account: account)

        if dict["forceRefresh"] != nil {
            silentParam.forceRefresh = dict["forceRefresh"] as? Bool ?? false
        }
        silentParam.fromDict(dict: dict)
        return silentParam
    }
}

extension MSALSignoutParameters {
    static func fromDict(dict: NSDictionary, param: MSALWebviewParameters) -> MSALSignoutParameters {
        let signOutParam = MSALSignoutParameters(webviewParameters: param)
        signOutParam.signoutFromBrowser = dict["signoutFromBrowser"] as? Bool ?? false
        signOutParam.wipeAccount = dict["wipeAccount"] as? Bool ?? false
        signOutParam.wipeCacheForAllAccounts = dict["wipeCacheForAllAccounts"] as? Bool ?? false
        return signOutParam
    }
}

extension MSALAccountEnumerationParameters {
    static func fromDict(dict: NSDictionary?) -> MSALAccountEnumerationParameters {
        if let username = dict?["username"] as? String {
            return MSALAccountEnumerationParameters(identifier: dict?["identifier"] as? String, username: username)
        }
        if let identifier = dict?["identifier"] as? String {
            return MSALAccountEnumerationParameters(identifier: identifier)
        }
        if let tenant = dict?["tenantProfileIdentifier"] as? String {
            return MSALAccountEnumerationParameters(tenantProfileIdentifier: tenant)
        }
        return MSALAccountEnumerationParameters()
    }
}

extension MSALResult {
    func toDict() -> [String: Any] {
        // Conserva el formato de vencimiento entregado por el puente original.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return [
            "accessToken": accessToken,
            "account": account.nsDictionary,
            "authenticationScheme": authenticationScheme,
            "authority": authority.url.absoluteString,
            "authorizationHeader": authorizationHeader,
            "correlationId": correlationId.uuidString,
            "expiresOn": msalChannelValue(expiresOn.map { dateFormatter.string(from: $0) }),
            "extendedLifeTimeToken": extendedLifeTimeToken,
            "idToken": msalChannelValue(idToken),
            "scopes": scopes,
            "tenantProfile": tenantProfile.toDict()
        ]
    }
}

extension MSALTenantProfile {
    func toDict() -> [String: Any] {
        return [
            "tenantId": msalChannelValue(tenantId),
            "claims": msalChannelValue(claims),
            "environment": msalChannelValue(environment),
            "identifier": msalChannelValue(identifier),
            "isHomeTenantProfile": isHomeTenantProfile
        ]
    }
}
