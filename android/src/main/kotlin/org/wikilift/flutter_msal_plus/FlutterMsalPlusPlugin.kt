package org.wikilift.flutter_msal_plus

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.microsoft.identity.client.*
import com.microsoft.identity.client.exception.MsalClientException
import com.microsoft.identity.client.exception.MsalException
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.Exception

class FlutterMsalPlusPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private var activity: Activity? = null
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var msalApp: IPublicClientApplication
    private fun isClientInitialized() = ::msalApp.isInitialized

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "msal_flutter")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext;
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {

        if (call.method in listOf("logout", "loadAccounts", "acquireToken", "acquireTokenSilent") && !isClientInitialized()) {
            result.error("NO_CLIENT", "Initialize MSAL before calling this method", null)
            return
        }
        when (call.method) {
            "logout" -> Thread(Runnable {
                logout(
                    call.arguments<HashMap<String, Any>>(),
                    result
                )
            }).start()
            "initialize" -> initialize(call.arguments<HashMap<String, Any>>(), result)
            "loadAccounts" -> Thread(Runnable { loadAccounts(result) }).start()
            "acquireToken" -> Thread(Runnable {
                acquireToken(
                    call.arguments<HashMap<String, Any>>(), result
                )
            }).start()
            "acquireTokenSilent" -> Thread(Runnable {
                acquireTokenSilent(
                    call.arguments<HashMap<String, Any>>(),
                    result
                )
            }).start()
            else -> result.notImplemented()
        }

    }

    private fun initialize(args: HashMap<String, Any>?, result: MethodChannel.Result) {
        if (args == null) {
            result.error("NO_CONFIG", "Call must include a config", null)
            return
        }
        try {
            val configFile = MSALConfigParser.parse(args)

            MultipleAccountPublicClientApplication.create(
                context, configFile, getApplicationCreatedListener(result)
            )

        } catch (e: Throwable) {
            Handler(Looper.getMainLooper()).post {
                result.error("UNKNOWN", "Unknown error occurred.", null)
            }
        }
    }

    private fun acquireToken(args: HashMap<String, Any>?, result: MethodChannel.Result) {

        if (args == null) {
            result.error("NO_CONFIG", "Call must include a config", null)
            return
        }

        try {
            val currentActivity = activity
            if (currentActivity == null) {
                Handler(Looper.getMainLooper()).post { result.error("NO_ACTIVITY", "No foreground Activity", null) }
                return
            }
            Handler(Looper.getMainLooper()).post {
                try {
                    val parameters = MSALTokenParametersParser.parse(currentActivity, getAuthCallback(result), args)
                    msalApp.acquireToken(parameters)
                } catch (e: MsalException) { handleMsalException(e, result) }
                catch (e: Throwable) { result.error("INVALID_REQUEST", "Invalid token parameters", null) }
            }
        } catch (e: MsalException) {
            handleMsalException(e, result)
        } catch (e: Throwable) {
            Handler(Looper.getMainLooper()).post {
                result.error("UNKNOWN", "An unknown error occured.", null)
            }
        }
    }

    private fun acquireTokenSilent(args: HashMap<String, Any>?, result: MethodChannel.Result) {


        if (args == null) {
            Handler(Looper.getMainLooper()).post {
                result.error("NO_SCOPE", "Call must include a scope", null)
            }
            return
        }


        if (msalApp is MultipleAccountPublicClientApplication) {
            val accounts = (msalApp as MultipleAccountPublicClientApplication).accounts
            if (accounts.isEmpty()) {
                Handler(Looper.getMainLooper()).post {
                    result.error("NO_ACCOUNT", "No accounts exist", null)
                }
                return
            }
        }


        try {
            val account = getAccountFromId(args["accountId"] as? String)
            val params = MSALSilentTokenParametersParser.parse(
                args["tokenParameters"] as HashMap<String, Any>,
                account as Account,
                msalApp.configuration.defaultAuthority.authorityURL.toURI().toString(),
                getAuthCallback(result)
            )
            msalApp.acquireTokenSilentAsync(
                params
            )

        } catch (e: MsalException) {
            handleMsalException(e, result)
        } catch (e: Throwable) {
            Handler(Looper.getMainLooper()).post {
                result.error("UNKNOWN", "An unknown error occured.", null)
            }
        }
    }

    private fun loadAccounts(result: MethodChannel.Result) {

        if (msalApp is MultipleAccountPublicClientApplication) {
            try {
                val accounts = (msalApp as MultipleAccountPublicClientApplication).accounts
                val accountList = ArrayList<HashMap<String, Any?>>()
                for (account in accounts) {
                    accountList.add(MsalAccountParse.parse(account as Account))
                }
                Handler(Looper.getMainLooper()).post {
                    result.success(accountList)
                }
            } catch (e: MsalException) {
                handleMsalException(e, result)
            } catch (e: Throwable) {
                Handler(Looper.getMainLooper()).post {
                    result.error("UNKNOWN", "An unknown error occured.", null)
                }
            }
        } else {
            try {
                val account =
                    (msalApp as SingleAccountPublicClientApplication).currentAccount.currentAccount
                val accountList = ArrayList<HashMap<String, Any?>>()
                accountList.add(MsalAccountParse.parse(account as Account))
                Handler(Looper.getMainLooper()).post {
                    result.success(accountList)
                }
            } catch (e: MsalException) {
                handleMsalException(e, result)
            } catch (e: Throwable) {
                Handler(Looper.getMainLooper()).post {
                    result.error("UNKNOWN", "An unknown error occured.", null)
                }
            }
        }
    }

    private fun logout(args: HashMap<String, Any>?, result: MethodChannel.Result) {

        try
        {
            if (msalApp is MultipleAccountPublicClientApplication && args?.get("accountId") != null) {
                (msalApp as MultipleAccountPublicClientApplication).removeAccount(getAccountFromId(args["accountId"] as? String) as Account)
            } else if (msalApp is SingleAccountPublicClientApplication) {
                (msalApp as SingleAccountPublicClientApplication).signOut()
            } else {
                Handler(Looper.getMainLooper()).post { result.error("NO_ACCOUNT", "An account identifier is required", null) }
                return
            }
            Handler(Looper.getMainLooper()).post {
                result.success(true)
            }
        }
        catch (e: MsalException) {
            handleMsalException(e, result)
        } catch (e: Throwable) {
            Handler(Looper.getMainLooper()).post {
                result.error("UNKNOWN", "An unknown error occured.", null)
            }
        }

    }

    private fun getAuthCallback(result: MethodChannel.Result): AuthenticationCallback {
        return object : AuthenticationCallback {
            override fun onSuccess(authenticationResult: IAuthenticationResult) {
                Handler(Looper.getMainLooper()).post {
                    val map = MSALResultParser.parse(authenticationResult as AuthenticationResult)
                    result.success(map)
                }
            }

            override fun onError(exception: MsalException) {
                handleMsalException(exception, result)
            }

            override fun onCancel() {
                Handler(Looper.getMainLooper()).post {
                    result.error("CANCELLED", "User cancelled", "User cancelled")
                }
            }
        }
    }

    private fun getAccountFromId(id: String?): IAccount? {
        if (msalApp is MultipleAccountPublicClientApplication) {
            if (id != null && id.isNotEmpty()) {
                return (msalApp as MultipleAccountPublicClientApplication).getAccount(id)
            }
            val accounts = (msalApp as MultipleAccountPublicClientApplication).accounts
            if (accounts != null && accounts.isNotEmpty()) {
                return accounts[0]
            }
        } else {
            return (msalApp as SingleAccountPublicClientApplication).currentAccount.currentAccount
        }
        throw MsalClientException("No account found")
    }

    private fun getApplicationCreatedListener(result: MethodChannel.Result): IPublicClientApplication.ApplicationCreatedListener {
        return object : IPublicClientApplication.ApplicationCreatedListener {


            override fun onCreated(application: IPublicClientApplication?) {
                if (application != null) {


                    msalApp = application

                    Handler(Looper.getMainLooper()).post {
                        result.success(true)
                    }
                } else {
                    Handler(Looper.getMainLooper()).post {
                        result.success(false)
                    }
                }
            }

            override fun onError(exception: MsalException?) {
                if (exception != null) {
                    handleMsalException(exception, result)
                } else {
                    Handler(Looper.getMainLooper()).post {
                        result.error(
                            "INIT_ERROR", "Error initializting client", null
                        )
                    }
                }
            }
        }
    }

    private fun handleMsalException(exception: MsalException, result: MethodChannel.Result) {

        val errorCode: String = when (exception.errorCode) {
            "access_denied" -> "CANCELLED"
            "declined_scope_error" -> "SCOPE_ERROR"
            "invalid_request" -> "INVALID_REQUEST"
            "invalid_grant" -> "INVALID_GRANT"
            "unknown_authority" -> "INVALID_AUTHORITY"
            "unknown_error" -> "UNKNOWN"
            else -> "AUTH_ERROR"
        }


        Handler(Looper.getMainLooper()).post {
            result.error(errorCode, "Authentication failed", null)
        }
    }

}
