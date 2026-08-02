import Flutter
import UIKit
import MSAL
import WebKit

public class SwiftMsalFlutterPluginV2: NSObject, FlutterPlugin {

    static public var customWebView: WKWebView?

    var accessToken = String()
    var applicationContext: MSALPublicClientApplication?
    var webViewParameters: MSALWebviewParameters?
    var currentAccount: MSALAccount?

    public static func register(with registrar: FlutterPluginRegistrar) {
        MSALGlobalConfig.loggerConfig.logMaskingLevel = .settingsMaskAllPII
        MSALGlobalConfig.loggerConfig.logLevel = .verbose

        let channel = FlutterMethodChannel(
            name: "msal_flutter",
            binaryMessenger: registrar.messenger()
        )

        let instance = SwiftMsalFlutterPluginV2()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(result: result, dict: call.arguments as! NSDictionary)

        case "initWebViewParams":
            initWebViewParams(result: result, dict: call.arguments as! NSDictionary)

        case "loadAccounts":
            loadAccounts(result: result, dict: call.arguments as? NSDictionary)

        case "acquireToken":
            acquireToken(result: result, dict: call.arguments as! NSDictionary)

        case "acquireTokenSilent":
            acquireTokenSilent(result: result, dict: call.arguments as! NSDictionary)

        case "logout":
            logout(result: result, dict: call.arguments as! NSDictionary)

        default:
            result(
                FlutterError(
                    code: "INVALID_METHOD",
                    message: "The method called is invalid",
                    details: nil
                )
            )
        }
    }

    private func initialize(result: @escaping FlutterResult, dict: NSDictionary) {
    do {
        let config = try MSALPublicClientApplicationConfig.fromDict(dictionary: dict)
        config.cacheConfig.keychainSharingGroup = "com.microsoft.adalcache"

        let application = try MSALPublicClientApplication(configuration: config)
        applicationContext = application

        guard let viewController = topViewController() else {
            result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not resolve top UIViewController", details: nil))
            return
        }
        
        let privateSession = dict["privateSession"] as? Bool ?? false
        let webParams = MSALWebviewParameters(authPresentationViewController: viewController)
        if #available(iOS 13.0, *) {
            webParams.prefersEphemeralWebBrowserSession = privateSession
        }
        self.webViewParameters = webParams

        do {
            let accounts = try application.allAccounts()
            if let first = accounts.first {
                self.currentAccount = first
            }
        } catch {}

        result(true)
    } catch let error {
        result(
            FlutterError(
                code: "CONFIG_ERROR",
                message: "Unable to create MSALPublicClientApplication with error: \(error)",
                details: nil
            )
        )
    }
}

    private func loadAccounts(result: @escaping FlutterResult, dict: NSDictionary?) {
        guard let applicationContext = self.applicationContext else {
            result(FlutterError(code: "CONFIG_ERROR", message: "MSAL not initialized", details: nil))
            return
        }

        do {
            let accountObjs = try applicationContext.allAccounts()

            self.currentAccount = accountObjs.first

            let map = accountObjs.map { serializeAccount($0) }
            result(map)
        } catch let error {
            result(
                FlutterError(
                    code: "LOAD_ACCOUNTS_ERROR",
                    message: "Could not load accounts: \(error.localizedDescription)",
                    details: nil
                )
            )
        }
    }

    private func acquireToken(result: @escaping FlutterResult, dict: NSDictionary) {
        guard let applicationContext = applicationContext else {
            result(FlutterError(code: "CONFIG_ERROR", message: "Unable to find MSALPublicClientApplication", details: nil))
            return
        }

        guard let webViewParameters = webViewParameters else {
            result(FlutterError(code: "CONFIG_ERROR", message: "webViewParameters is not initialized", details: nil))
            return
        }

        let parameters = MSALInteractiveTokenParameters.fromDict(dict: dict, param: webViewParameters)

        applicationContext.acquireToken(with: parameters) { token, error in
            if let error = error {
                result(FlutterError(code: "AUTH_ERROR", message: "Could not acquire token: \(error)", details: error.localizedDescription))
                return
            }

            guard let tokenResult: MSALResult = token else {
                result(FlutterError(code: "AUTH_ERROR", message: "Could not acquire token: No result returned", details: nil))
                return
            }

            self.accessToken = tokenResult.accessToken
            self.currentAccount = tokenResult.account

            result(tokenResult.toDict())
        }
    }

    private func acquireTokenSilent(result: @escaping FlutterResult, dict: NSDictionary) {
        guard applicationContext != nil else {
            result(FlutterError(code: "CONFIG_ERROR", message: "Call must include an MSALPublicClientApplication", details: nil))
            return
        }

        let account: MSALAccount
        do {
            account = try getAccountById(id: dict["accountId"] as? String)
        } catch {
            result(FlutterError(code: "NO_ACCOUNT", message: "No account is available to acquire token silently for", details: nil))
            return
        }

        let silentParameters = MSALSilentTokenParameters.fromDict(
            dict: dict["tokenParameters"] as! NSDictionary,
            account: account
        )

        self.applicationContext!.acquireTokenSilent(with: silentParameters) { tokenResult, error in
            guard let authResult = tokenResult, error == nil else {
                result(FlutterError(code: "AUTH_ERROR", message: "Authentication error \(String(describing: error))", details: error?.localizedDescription))
                return
            }

            self.currentAccount = authResult.account
            result(authResult.toDict())
        }
    }

    private func logout(result: @escaping FlutterResult, dict: NSDictionary) {
        guard let applicationContext = self.applicationContext else {
            result(FlutterError(code: "CONFIG_ERROR", message: "Unable to find MSALPublicClientApplication", details: nil))
            return
        }

        guard let webViewParameters = self.webViewParameters else {
            result(FlutterError(code: "CONFIG_ERROR", message: "Unable to find webViewParameters", details: nil))
            return
        }

        let account: MSALAccount
        do {
            account = try getAccountById(id: dict["accountId"] as? String)
        } catch {
            result(FlutterError(code: "NO_ACCOUNT", message: "No account is available to logout", details: nil))
            return
        }

        let signoutParameters = MSALSignoutParameters.fromDict(
            dict: dict["signoutParameters"] as! NSDictionary,
            param: webViewParameters
        )

        applicationContext.signout(with: account, signoutParameters: signoutParameters) { success, error in
            if let error = error {
                result(FlutterError(code: "CONFIG_ERROR", message: "Couldn't sign out account with error: \(error)", details: nil))
                return
            }

            self.currentAccount = nil
            result(success)
        }
    }

    private func topViewController() -> UIViewController? {
        if #available(iOS 13.0, *) {
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first {
                    $0.activationState == .foregroundActive ||
                    $0.activationState == .foregroundInactive
                }

            let keyWindow = windowScene?.windows.first { $0.isKeyWindow }
            var top = keyWindow?.rootViewController

            while let presented = top?.presentedViewController {
                top = presented
            }

            return top
        } else {
            var top = UIApplication.shared.keyWindow?.rootViewController

            while let presented = top?.presentedViewController {
                top = presented
            }

            return top
        }
    }

    private func initWebViewParams(result: @escaping FlutterResult, dict: NSDictionary) {
        guard let viewController = topViewController() else {
            result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not resolve top UIViewController", details: nil))
            return
        }

        let parameters = MSALWebviewParameters(authPresentationViewController: viewController)
        parameters.fromDict(dictionary: dict)

        if let customWebView = SwiftMsalFlutterPluginV2.customWebView {
            parameters.customWebview = customWebView
        }

        self.webViewParameters = parameters
        result(true)
    }

    private func getAccountById(id: String?) throws -> MSALAccount {
        if let id = id, !id.isEmpty {
            return try self.applicationContext!.account(forIdentifier: id)
        }

        if let currentAccount = self.currentAccount {
            return currentAccount
        }

        let accounts = try self.applicationContext!.allAccounts()
        if let first = accounts.first {
            self.currentAccount = first
            return first
        }

        throw NSError(domain: "NO_ACCOUNT", code: 0, userInfo: nil)
    }

    private func serializeAccount(_ account: MSALAccount) -> NSDictionary {
        return [
            "username": account.username as Any,
            "identifier": account.identifier,
            "environment": account.environment as Any,
            "accountClaims": serializeClaims(account.accountClaims),
            "isSSOAccount": account.isSSOAccount
        ]
    }

    private func serializeClaims(_ claims: [String: Any]?) -> NSDictionary? {
        guard let claims = claims else { return nil }

        var safe: [String: Any] = [:]

        for (key, value) in claims {
            if let value = value as? String {
                safe[key] = value
            } else if let value = value as? NSNumber {
                safe[key] = value
            } else if let value = value as? Bool {
                safe[key] = value
            } else if let value = value as? [String] {
                safe[key] = value
            } else if let value = value as? [NSNumber] {
                safe[key] = value
            } else {
                safe[key] = String(describing: value)
            }
        }

        return safe as NSDictionary
    }
}