import Flutter
import UIKit
import MSAL
import WebKit

public class MsalMethodHandler: NSObject, FlutterPlugin {

    static public var customWebView: WKWebView?

    var applicationContext: MSALPublicClientApplication?
    var webViewParameters: MSALWebviewParameters?
    var currentAccount: MSALAccount?

    public static func register(with registrar: FlutterPluginRegistrar) {
        MSALGlobalConfig.loggerConfig.logMaskingLevel = .settingsMaskAllPII
        MSALGlobalConfig.loggerConfig.logLevel = .warning

        let channel = FlutterMethodChannel(
            name: "msal_flutter",
            binaryMessenger: registrar.messenger()
        )

        let instance = MsalMethodHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result callback: @escaping FlutterResult) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { self.handle(call, result: callback) }
            return
        }
        var completed = false
        let result: FlutterResult = { value in
            let deliver = {
                guard !completed else { return }
                completed = true
                callback(value)
            }
            if Thread.isMainThread { deliver() }
            else { DispatchQueue.main.async(execute: deliver) }
        }
        if ["initialize", "initWebViewParams", "acquireToken", "acquireTokenSilent", "logout"].contains(call.method),
           !(call.arguments is NSDictionary) {
            result(FlutterError(code: "INVALID_REQUEST", message: "Expected a parameter dictionary", details: nil))
            return
        }
        switch call.method {
        case "initialize":
            guard let dict = call.arguments as? NSDictionary else {
                result(
                    FlutterError(
                        code: "INVALID_REQUEST",
                        message: "initialize requires a configuration dictionary",
                        details: nil
                    )
                )
                return
            }
            initialize(result: result, dict: dict)

        case "initWebViewParams":
            initWebViewParams(result: result, dict: (call.arguments as? NSDictionary) ?? NSDictionary())

        case "loadAccounts":
            loadAccounts(result: result, dict: call.arguments as? NSDictionary)

        case "acquireToken":
            acquireToken(result: result, dict: (call.arguments as? NSDictionary) ?? NSDictionary())

        case "acquireTokenSilent":
            acquireTokenSilent(result: result, dict: (call.arguments as? NSDictionary) ?? NSDictionary())

        case "logout":
            logout(result: result, dict: (call.arguments as? NSDictionary) ?? NSDictionary())

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func initialize(result: @escaping FlutterResult, dict: NSDictionary) {
        do {
            let config = try MSALPublicClientApplicationConfig.fromDict(dictionary: dict)
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
        } catch let error as MsalFlutterConfigurationError {
            result(error.flutterError(configuration: dict))
        } catch let error {
            result(msalConfigurationFlutterError(error: error, configuration: dict))
        }
    }

    private func msalConfigurationFlutterError(error: Error, configuration: NSDictionary) -> FlutterError {
        let nativeError = error as NSError
        return FlutterError(code: "CONFIG_ERROR", message: "Unable to initialize MSAL; verify authority, redirect URI and keychain entitlements", details: ["domain": nativeError.domain, "code": nativeError.code])
    }

    private func authenticationError(_ error: Error) -> FlutterError {
        let nativeError = error as NSError
        let cancelled = nativeError.domain == MSALErrorDomain && nativeError.code == MSALError.userCanceled.rawValue
        return FlutterError(code: cancelled ? "CANCELLED" : "AUTH_ERROR", message: cancelled ? "User cancelled authentication" : "MSAL authentication failed", details: ["domain": nativeError.domain, "code": nativeError.code])
    }

    private func validScopes(_ dictionary: NSDictionary, result: FlutterResult) -> Bool {
        guard let scopes = dictionary["scopes"] as? [String], !scopes.isEmpty,
              scopes.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            result(FlutterError(code: "NO_SCOPE", message: "At least one non-empty scope is required", details: nil))
            return false
        }
        return true
    }

    private func loadAccounts(result: @escaping FlutterResult, dict: NSDictionary?) {
        guard let applicationContext = self.applicationContext else {
            result(FlutterError(code: "NO_CLIENT", message: "MSAL not initialized", details: nil))
            return
        }

        do {
            // Conserva la enumeración local y la selección inicial del puente original.
            let accounts = try applicationContext.allAccounts()
            self.currentAccount = accounts.first
            result(accounts.map { self.serializeAccount($0) })
        } catch {
            result(authenticationError(error))
        }
    }

    private func acquireToken(result: @escaping FlutterResult, dict: NSDictionary) {
        guard let applicationContext = applicationContext else {
            result(FlutterError(code: "NO_CLIENT", message: "Unable to find MSALPublicClientApplication", details: nil))
            return
        }

        guard let webViewParameters = webViewParameters else {
            result(FlutterError(code: "CONFIG_ERROR", message: "webViewParameters is not initialized", details: nil))
            return
        }

        guard validScopes(dict, result: result) else { return }
        let parameters: MSALInteractiveTokenParameters
        do { parameters = try MSALInteractiveTokenParameters.fromDict(dict: dict, param: webViewParameters) }
        catch { result(authenticationError(error)); return }
        parameters.completionBlockQueue = DispatchQueue.main

        applicationContext.acquireToken(with: parameters) { token, error in
            if let error = error {
                result(self.authenticationError(error))
                return
            }

            guard let tokenResult: MSALResult = token else {
                result(FlutterError(code: "AUTH_ERROR", message: "Could not acquire token: No result returned", details: nil))
                return
            }

            self.currentAccount = tokenResult.account

            result(tokenResult.toDict())
        }
    }

    private func acquireTokenSilent(result: @escaping FlutterResult, dict: NSDictionary) {
        guard let applicationContext = applicationContext else {
            result(FlutterError(code: "NO_CLIENT", message: "MSAL not initialized", details: nil))
            return
        }

        let account: MSALAccount
        do {
            account = try getAccountById(id: dict["accountId"] as? String)
        } catch {
            result(FlutterError(code: "NO_ACCOUNT", message: "No account is available to acquire token silently for", details: nil))
            return
        }

        guard let tokenParameters = dict["tokenParameters"] as? NSDictionary else {
            result(FlutterError(code: "INVALID_REQUEST", message: "tokenParameters is required", details: nil)); return
        }
        guard validScopes(tokenParameters, result: result) else { return }
        let silentParameters: MSALSilentTokenParameters
        do { silentParameters = try MSALSilentTokenParameters.fromDict(dict: tokenParameters, account: account) }
        catch { result(authenticationError(error)); return }
        silentParameters.completionBlockQueue = DispatchQueue.main

        applicationContext.acquireTokenSilent(with: silentParameters) { tokenResult, error in
            guard let authResult = tokenResult, error == nil else {
                if let error = error { result(self.authenticationError(error)) }
                else { result(FlutterError(code: "AUTH_ERROR", message: "MSAL returned no result", details: nil)) }
                return
            }

            self.currentAccount = authResult.account
            result(authResult.toDict())
        }
    }

    private func logout(result: @escaping FlutterResult, dict: NSDictionary) {
        guard let applicationContext = self.applicationContext else {
            result(FlutterError(code: "NO_CLIENT", message: "Unable to find MSALPublicClientApplication", details: nil))
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

        guard let signoutDictionary = dict["signoutParameters"] as? NSDictionary else {
            result(FlutterError(code: "INVALID_REQUEST", message: "signoutParameters is required", details: nil)); return
        }
        let signoutParameters = MSALSignoutParameters.fromDict(
            dict: signoutDictionary,
            param: webViewParameters
        )

        signoutParameters.completionBlockQueue = DispatchQueue.main
        applicationContext.signout(with: account, signoutParameters: signoutParameters) { success, error in
            if let error = error {
                result(self.authenticationError(error))
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

        if let customWebView = MsalMethodHandler.customWebView {
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
        return account.nsDictionary
    }
}

// Conserva el acceso nativo histórico a la vista web personalizada.
public typealias SwiftMsalFlutterPluginV2 = MsalMethodHandler
