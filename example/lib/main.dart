import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:msal_flutter/msal_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const String _authority = "https://login.microsoftonline.com/common";
  static const String _iosRedirectUri =
      "msal701e9fb7-feb3-4832-a4d7-a706dbe54c40://auth";
  static const String _clientId = "701e9fb7-feb3-4832-a4d7-a706dbe54c40";
  static const List<String> _scopes = [
    "https://otiselevator.com/NonOtisSVTAPI-prod-ES/user_impersonation"
  ];

  final config = MSALPublicClientApplicationConfig(
    clientId: _clientId,
    iosRedirectUri: _iosRedirectUri,
    authority: Uri.parse(_authority),
  );
  String _output = 'NONE';

  MSALPublicClientApplication? pca;
  List<MSALAccount>? accounts;

  Future<void> _acquireToken() async {
    print("called acquiretoken");
    //create the PCA if not already created
    if (pca == null) {
      print("creating pca...");
      pca = await MSALPublicClientApplication.createPublicClientApplication(
          config);
      await pca!.initWebViewParams(MSALWebviewParameters());
    }

    print("pca created");

    String res = '';
    try {
      MSALResult? resp = await pca!
          .acquireToken(MSALInteractiveTokenParameters(scopes: _scopes));
      res = resp?.account.identifier ?? 'noAuth';
      res += "\n${resp?.account.username ?? "noName"}";
      res += "\n${resp?.account.accountClaims ?? "noClaims"}";
      res += "\n${resp?.authenticationScheme ?? "noAuthScheme"}";
      res += "\n${resp?.scopes ?? "noScopes"}";
      res += "\n${resp?.expiresOn?.toIso8601String() ?? "noExpirestime"}";
    } on MsalUserCancelledException {
      res = "User cancelled";
    } on MsalNoAccountException {
      res = "no account";
    } on MsalInvalidConfigurationException {
      res = "invalid config";
    } on MsalInvalidScopeException {
      res = "Invalid scope";
    } on MsalException {
      res = "Error getting token. Unspecified reason";
    }

    setState(() {
      _output = res;
    });
  }

  Future<void> _loadAccount() async {
    if (pca == null) {
      print("initializing pca");
      pca = await MSALPublicClientApplication.createPublicClientApplication(
          config);
      await pca!.initWebViewParams(MSALWebviewParameters());
    }
    try {
      final result = await pca!.loadAccounts();
      if (result != null) {
        accounts = result;
      }
    } catch (e) {
      log(e.toString());
    }
    setState(() {});
  }

  Future<void> _acquireTokenSilently() async {
    if (pca == null) {
      print("initializing pca");
      pca = await MSALPublicClientApplication.createPublicClientApplication(
          config);
      await pca!.initWebViewParams(MSALWebviewParameters());
    }

    String res = 'res';
    try {
      final response = await pca!.acquireTokenSilent(
          MSALSilentTokenParameters(
            scopes: _scopes,
          ),
          accounts?.isEmpty == true ? null : accounts?.first);
      res = response?.account.identifier ?? '';
    } on MsalUserCancelledException {
      res = "User cancelled";
    } on MsalNoAccountException {
      res = "no account";
    } on MsalInvalidConfigurationException {
      res = "invalid config";
    } on MsalInvalidScopeException {
      res = "Invalid scope";
    } on MsalException {
      res = "Error getting token silently!";
    }

    print("Got token");
    print(res);

    setState(() {
      _output = res;
    });
  }

  Future<void> _logout() async {
    print("called logout");

    if (pca == null) {
      print("initializing pca");
      pca = await MSALPublicClientApplication.createPublicClientApplication(
          config);
      await pca!.initWebViewParams(MSALWebviewParameters());
    }

    String res;

    try {
      if (accounts?.isNotEmpty != true) {
        res = "No hay cuentas cargadas";
      } else {
        await pca!.logout(MSALSignoutParameters(), accounts!.first);
        res = "Account removed";
      }
    } on MsalException catch (e) {
      res = "Error signing out: $e";
    } on PlatformException catch (e) {
      res = "PlatformException: ${e.message}";
    }

    setState(() {
      _output = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              ElevatedButton(
                onPressed: _acquireToken,
                child: Text('AcquireToken()'),
              ),
              ElevatedButton(
                  onPressed: _loadAccount, child: Text('loadAccount()')),
              ElevatedButton(
                  onPressed: _acquireTokenSilently,
                  child: Text('AcquireTokenSilently()')),
              ElevatedButton(onPressed: _logout, child: Text('Logout')),
              Text(_output),
              Expanded(
                  child: ListView.builder(
                itemCount: accounts?.length ?? 0,
                itemBuilder: (context, index) {
                  final item = accounts![index];
                  return ListTile(
                    title: Text(item.username ?? item.identifier),
                  );
                },
              ))
            ],
          ),
        ),
      ),
    );
  }
}
