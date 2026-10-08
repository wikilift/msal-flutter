import Flutter
import XCTest
import MSAL
import ObjectiveC
@testable import flutter_msal_plus

class RunnerTests: XCTestCase {
    // Valores exactos del contrato; las pruebas nativas se excluyen del paquete publicado.
    private let productionClientId = "701e9fb7-feb3-4832-a4d7-a706dbe54c40"
    private let productionRedirect = "msal701e9fb7-feb3-4832-a4d7-a706dbe54c40://auth"
    private let productionAuthority = "https://login.microsoftonline.com/common/"
    private let productionScope = "https://otiselevator.com/NonOtisSVTAPI-prod-ES/user_impersonation"

    private func productionConfiguration() throws -> MSALPublicClientApplicationConfig {
        return try MSALPublicClientApplicationConfig.fromDict(dictionary: [
            "clientId": productionClientId,
            "redirectUri": productionRedirect,
            "authority": productionAuthority,
            "bypassRedirectURIValidation": true
        ])
    }

    func testProductionConfigurationPreservesCustomRedirectAndCommon() throws {
        let config = try productionConfiguration()
        XCTAssertEqual(config.clientId, productionClientId)
        XCTAssertEqual(config.redirectUri, productionRedirect)
        XCTAssertEqual(config.authority.url.host, "login.microsoftonline.com")
        XCTAssertEqual(config.authority.url.lastPathComponent, "common")
        XCTAssertTrue(config.bypassRedirectURIValidation)
    }

    func testProductionNativeInitializationMatchesExistingCallerOption() throws {
        let config = try productionConfiguration()
        let application = try MSALPublicClientApplication(configuration: config)
        XCTAssertEqual(application.configuration.clientId, productionClientId)
        XCTAssertEqual(application.configuration.redirectUri, productionRedirect)
        XCTAssertTrue(application.configuration.bypassRedirectURIValidation)
    }

    func testOmittingExistingCallerOptionReproducesIsolatedError() throws {
        let config = try productionConfiguration()
        config.bypassRedirectURIValidation = false
        XCTAssertThrowsError(try MSALPublicClientApplication(configuration: config)) { error in
            let nativeError = error as NSError
            XCTAssertEqual(nativeError.domain, MSALErrorDomain)
            let internalCode = (nativeError.userInfo[MSALInternalErrorCodeKey] as? NSNumber)?.intValue
            if (Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]])?.contains(where: {
                ($0["CFBundleURLSchemes"] as? [String])?.contains("msal" + self.productionClientId) == true
            }) == true {
                XCTAssertEqual(internalCode, -42011)
            }
        }
    }

    func testProductionParametersInitializeActualFlutterBridge() {
        let handler = MsalMethodHandler()
        let completion = expectation(description: "Existing production configuration initializes")
        handler.handle(FlutterMethodCall(methodName: "initialize", arguments: [
            "clientId": productionClientId, "redirectUri": productionRedirect,
            "authority": productionAuthority, "bypassRedirectURIValidation": true
        ])) { result in
            XCTAssertEqual(result as? Bool, true)
            XCTAssertEqual(handler.applicationContext?.configuration.redirectUri, self.productionRedirect)
            XCTAssertEqual(handler.applicationContext?.configuration.knownAuthorities.count, 1)
            completion.fulfill()
        }
        wait(for: [completion], timeout: 5)
    }

    func testOriginalAndModernizedInitializationParametersMatch() throws {
        let arguments: NSDictionary = [
            "clientId": productionClientId, "redirectUri": productionRedirect,
            "authority": productionAuthority, "bypassRedirectURIValidation": true
        ]
        let original = try OriginalMSALInitializationReference.fromDict(dictionary: arguments)
        let modernized = try MSALPublicClientApplicationConfig.fromDict(dictionary: arguments)
        XCTAssertEqual(original.clientId, modernized.clientId)
        XCTAssertEqual(original.redirectUri, modernized.redirectUri)
        XCTAssertEqual(original.authority.url, modernized.authority.url)
        XCTAssertEqual(original.bypassRedirectURIValidation, modernized.bypassRedirectURIValidation)
        XCTAssertEqual(original.knownAuthorities.map { $0.url }, modernized.knownAuthorities.map { $0.url })
        XCTAssertEqual(original.cacheConfig.keychainSharingGroup, modernized.cacheConfig.keychainSharingGroup)
        XCTAssertEqual(original.clientApplicationCapabilities, modernized.clientApplicationCapabilities)
        XCTAssertEqual(original.extendedLifetimeEnabled, modernized.extendedLifetimeEnabled)
        XCTAssertEqual(original.multipleCloudsSupported, modernized.multipleCloudsSupported)
        XCTAssertEqual(original.tokenExpirationBuffer, modernized.tokenExpirationBuffer)
        let originalClient = try MSALPublicClientApplication(configuration: original)
        let modernizedClient = try MSALPublicClientApplication(configuration: modernized)
        XCTAssertEqual(originalClient.configuration.redirectUri, productionRedirect)
        XCTAssertEqual(originalClient.configuration.redirectUri, modernizedClient.configuration.redirectUri)
    }

    func testProductionInteractiveRequestForwardsEnterpriseScope() throws {
        let web = MSALWebviewParameters(authPresentationViewController: UIViewController())
        let parameters = try MSALInteractiveTokenParameters.fromDict(dict: [
            "scopes": [productionScope], "authority": productionAuthority
        ], param: web)
        XCTAssertEqual(parameters.scopes, [productionScope])
        XCTAssertEqual(parameters.authority?.url.lastPathComponent, "common")
        XCTAssertNil(parameters.extraScopesToConsent)
        XCTAssertEqual(parameters.promptType, .default)
    }

    func testProductionSilentRequestForwardsEnterpriseScopeWithoutTenant() throws {
        // Objeto sintético sin credenciales, usado solamente para construir parámetros.
        let account = try XCTUnwrap(class_createInstance(MSALAccount.self, 0) as? MSALAccount)
        let parameters = try MSALSilentTokenParameters.fromDict(dict: [
            "scopes": [productionScope], "forceRefresh": true
        ], account: account)
        XCTAssertEqual(parameters.scopes, [productionScope])
        XCTAssertTrue(parameters.account === account)
        XCTAssertTrue(parameters.forceRefresh)
        XCTAssertNil(parameters.authority)
    }

    func testClientIdOnlyUsesMSAL200GenericAuthority() throws {
        let configuration = try MSALPublicClientApplicationConfig.fromDict(dictionary: [
            "clientId": "00000000-0000-0000-0000-000000000000"
        ])
        XCTAssertEqual(configuration.authority.url.host, "login.microsoftonline.com")
        XCTAssertEqual(configuration.authority.url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")), "common")
        XCTAssertEqual(configuration.redirectUri, "msauth." + Bundle.main.bundleIdentifier! + "://auth")
    }

    func testClientIdOnlyInitializesNativeApplication() throws {
        let configuration = try MSALPublicClientApplicationConfig.fromDict(dictionary: [
            "clientId": "00000000-0000-0000-0000-000000000000"
        ])
        let application = try MSALPublicClientApplication(configuration: configuration)
        XCTAssertEqual(application.configuration.authority.url.host, "login.microsoftonline.com")
    }

    func testOptionalExplicitTenantAuthorityIsPreserved() throws {
        let configuration = try MSALPublicClientApplicationConfig.fromDict(dictionary: [
            "clientId": "00000000-0000-0000-0000-000000000000",
            "authority": "https://login.microsoftonline.com/11111111-1111-1111-1111-111111111111"
        ])
        XCTAssertEqual(configuration.authority.url.lastPathComponent, "11111111-1111-1111-1111-111111111111")
    }

    func testExplicitAuthorityRemainsKnownAsInOriginalBridge() throws {
        let configuration = try MSALPublicClientApplicationConfig.fromDict(dictionary: [
            "clientId": "00000000-0000-0000-0000-000000000000",
            "authority": "https://login.microsoftonline.com/common",
            "knownAuthorities": []
        ])
        XCTAssertEqual(configuration.knownAuthorities.map { $0.url.lastPathComponent }, ["common"])
    }

    func testNestedClaimsUseFlutterCompatibleValues() {
        let serialized = msalChannelValue(["date": Date(timeIntervalSince1970: 0), "roles": ["reader"], "null": NSNull()]) as? [String: Any]
        XCTAssertEqual(serialized?["date"] as? String, "1970-01-01T00:00:00Z")
        XCTAssertEqual(serialized?["roles"] as? [String], ["reader"])
        XCTAssertTrue(serialized?["null"] is NSNull)
        XCTAssertTrue(msalChannelValue(nil) is NSNull)
    }

    func testMalformedArgumentsCompleteOnce() {
        let handler = MsalMethodHandler()
        let completion = expectation(description: "Invalid arguments return an error")
        completion.assertForOverFulfill = true
        handler.handle(FlutterMethodCall(methodName: "acquireToken", arguments: "invalid")) { value in
            XCTAssertEqual((value as? FlutterError)?.code, "INVALID_REQUEST")
            completion.fulfill()
        }
        wait(for: [completion], timeout: 2)
    }

    func testUninitializedClientReturnsControlledError() {
        let handler = MsalMethodHandler()
        let completion = expectation(description: "No client returns an error")
        handler.handle(FlutterMethodCall(methodName: "loadAccounts", arguments: nil)) { value in
            XCTAssertEqual((value as? FlutterError)?.code, "NO_CLIENT")
            completion.fulfill()
        }
        wait(for: [completion], timeout: 2)
    }

    func testMissingClientIdDoesNotCrashInitialization() {
        let handler = MsalMethodHandler()
        let completion = expectation(description: "Missing client ID returns an error")
        handler.handle(FlutterMethodCall(methodName: "initialize", arguments: [:])) { value in
            XCTAssertEqual((value as? FlutterError)?.code, "NO_CLIENTID")
            completion.fulfill()
        }
        wait(for: [completion], timeout: 2)
    }

    func testUnknownMethodUsesFlutterNotImplemented() {
        let handler = MsalMethodHandler()
        let completion = expectation(description: "Unknown method completes")
        handler.handle(FlutterMethodCall(methodName: "unknown", arguments: nil)) { value in
            XCTAssertTrue((value as AnyObject?) === (FlutterMethodNotImplemented as AnyObject))
            completion.fulfill()
        }
        wait(for: [completion], timeout: 2)
    }
}

// Referencia extraída de b44c247; se compila contra el mismo SDK que el puente actual.
private enum OriginalMSALInitializationReference {
    static func fromDict(dictionary: NSDictionary) throws -> MSALPublicClientApplicationConfig {
        guard let clientId = dictionary["clientId"] as? String,
              clientId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw MsalFlutterConfigurationError(
                code: "NO_CLIENTID",
                message: "Call must include a non-empty clientId"
            )
        }

        guard let authority = try originalAuthority(entry: dictionary["authority"] as? String) else {
            throw MsalFlutterConfigurationError(
                code: "INVALID_AUTHORITY",
                message: "Call must include a non-empty authority URL"
            )
        }

        let redirectUri = (dictionary["redirectUri"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let config = MSALPublicClientApplicationConfig(
            clientId: clientId,
            redirectUri: redirectUri?.isEmpty == false ? redirectUri : originalGeneratedRedirectUri(),
            authority: authority
        )
        config.bypassRedirectURIValidation = dictionary["bypassRedirectURIValidation"] as? Bool ?? false
        config.clientApplicationCapabilities = dictionary["clientApplicationCapabilities"] as? [String]
        config.extendedLifetimeEnabled = dictionary["extendedLifetimeEnabled"] as? Bool ?? false

        var knownAuthorities: [MSALAuthority] = [authority]
        if let rawKnownAuthorities = dictionary["knownAuthorities"] {
            guard let knownAuthorityStrings = rawKnownAuthorities as? [String] else {
                throw MsalFlutterConfigurationError(
                    code: "INVALID_AUTHORITY",
                    message: "knownAuthorities must be a list of authority URLs"
                )
            }

            for (index, item) in knownAuthorityStrings.enumerated() {
                guard let knownAuthority = try originalAuthority(entry: item) else {
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


    static func originalGeneratedRedirectUri() -> String? {
        guard let bundleId = Bundle.main.bundleIdentifier else { return nil }
        return "msauth." + bundleId + "://auth"
    }

    static func originalAuthority(entry: String?) throws -> MSALAuthority? {
        guard let entry = entry?.trimmingCharacters(in: .whitespacesAndNewlines), !entry.isEmpty else { return nil }
        guard let url = URL(string: entry), let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme), url.host?.isEmpty == false else {
            throw MsalFlutterConfigurationError(code: "INVALID_AUTHORITY", message: "Invalid authority URL")
        }
        return try MSALAuthority(url: url)
    }
}
