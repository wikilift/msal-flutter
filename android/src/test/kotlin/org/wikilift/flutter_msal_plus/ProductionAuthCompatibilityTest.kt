package org.wikilift.flutter_msal_plus

import android.app.Activity
import com.google.gson.Gson
import com.microsoft.identity.client.Account
import com.microsoft.identity.client.AuthenticationCallback
import com.microsoft.identity.client.IAuthenticationResult
import com.microsoft.identity.client.PublicClientApplicationConfiguration
import com.microsoft.identity.client.exception.MsalException
import org.junit.Assert.*
import org.junit.Test

class ProductionAuthCompatibilityTest {
    // Contrato exacto de producción, excluido del archivo publicado.
    private val clientId = "701e9fb7-feb3-4832-a4d7-a706dbe54c40"
    private val redirect = "msal701e9fb7-feb3-4832-a4d7-a706dbe54c40://auth"
    private val authority = "https://login.microsoftonline.com/common/"
    private val scope = "https://otiselevator.com/NonOtisSVTAPI-prod-ES/user_impersonation"
    private val callback = object : AuthenticationCallback {
        override fun onSuccess(result: IAuthenticationResult) = Unit
        override fun onError(exception: MsalException) = Unit
        override fun onCancel() = Unit
    }

    @Test fun configurationParserPreservesClientAndCustomRedirect() {
        val file = MSALConfigParser.parse(hashMapOf("client_id" to clientId, "redirect_uri" to redirect))
        try {
            val config = Gson().fromJson(file.readText(), PublicClientApplicationConfiguration::class.java)
            assertEquals(clientId, config.clientId)
            assertEquals(redirect, config.redirectUri)
            assertNull(config.authorities)
        } finally {
            file.delete()
        }
    }

    @Test fun interactiveParserUsesExactScopeAndCommonAuthority() {
        val parameters = MSALTokenParametersParser.parse(Activity(), callback, hashMapOf(
            "scopes" to arrayListOf(scope), "authority" to authority
        ))
        assertEquals(listOf(scope), parameters.scopes)
        assertEquals(authority, parameters.authority)
        assertNull(parameters.extraScopesToConsent)
    }

    @Test fun silentParserUsesSelectedAccountAndDefaultCommonAuthority() {
        val account = Account("synthetic-home-account", null)
        val parameters = MSALSilentTokenParametersParser.parse(
            hashMapOf("scopes" to listOf(scope)), account, authority, callback
        )
        assertEquals(listOf(scope), parameters.scopes)
        assertEquals(authority, parameters.authority)
        assertSame(account, parameters.account)
        assertFalse(parameters.forceRefresh)
    }

    @Test fun customRedirectIsNotMisrepresentedAsBrokerCapable() {
        assertFalse(PublicClientApplicationConfiguration.isBrokerRedirectUri(redirect, "com.example.app"))
    }
}
