import 'package:flutter/material.dart';
import 'package:flutter_msal_plus/flutter_msal_plus.dart';

void main() => runApp(const MsalExampleApp());

class MsalExampleApp extends StatelessWidget {
  const MsalExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MSAL authentication',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
    home: const AuthenticationPage(),
  );
}

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  static const clientId = String.fromEnvironment('CLIENT_ID');
  static const redirectUri = String.fromEnvironment(
    'REDIRECT_URI',
    defaultValue: 'msauth.com.example.a://auth',
  );
  static const scope = String.fromEnvironment(
    'SCOPE',
    defaultValue: 'https://api.example.com/application/user_impersonation',
  );
  MSALPublicClientApplication? _application;
  List<MSALAccount> _accounts = [];
  MSALAccount? _selectedAccount;
  bool _busy = false;
  String _status = 'Configure CLIENT_ID before initializing.';

  Future<void> _run(Future<String> Function() operation) async {
    setState(() => _busy = true);
    try {
      final status = await operation();
      if (mounted) setState(() => _status = status);
    } on MsalUserCancelledException {
      if (mounted) setState(() => _status = 'Authentication cancelled.');
    } on MsalException catch (error) {
      if (mounted) setState(() => _status = error.toString());
    } catch (_) {
      if (mounted) {
        setState(
          () => _status =
              'Authentication unavailable. Verify native configuration.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _initialize() async {
    _application =
        await MSALPublicClientApplication.createPublicClientApplication(
          MSALPublicClientApplicationConfig(
            clientId: clientId,
            iosRedirectUri: redirectUri,
            androidRedirectUri: redirectUri,
          ),
        );
    await _reloadAccounts();
    return 'MSAL initialized.';
  }

  Future<void> _reloadAccounts() async {
    final accounts = await _application!.loadAccounts() ?? [];
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _selectedAccount =
          accounts
              .where(
                (account) => account.identifier == _selectedAccount?.identifier,
              )
              .firstOrNull ??
          accounts.firstOrNull;
    });
  }

  Future<String> _login() async {
    final result = await _application!.acquireToken(
      MSALInteractiveTokenParameters(scopes: [scope]),
    );
    await _reloadAccounts();
    return result == null
        ? 'No result returned.'
        : 'Signed in. Token expires: ${result.expiresOn?.toLocal() ?? 'unknown'}';
  }

  Future<String> _silent() async {
    final result = await _application!.acquireTokenSilent(
      MSALSilentTokenParameters(scopes: [scope]),
      _selectedAccount,
    );
    return result == null
        ? 'No result returned.'
        : 'Token acquired silently. Expires: ${result.expiresOn?.toLocal() ?? 'unknown'}';
  }

  Future<String> _logout() async {
    final success = await _application!.logout(
      const MSALSignoutParameters(signoutFromBrowser: true),
      _selectedAccount!,
    );
    await _reloadAccounts();
    return success ? 'Signed out.' : 'Sign-out did not complete.';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MSAL authentication')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_status, key: const Key('status')),
          const SizedBox(height: 16),
          if (_busy) const LinearProgressIndicator(),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: _busy ? null : () => _run(_initialize),
                child: const Text('Initialize'),
              ),
              FilledButton(
                onPressed: _busy || _application == null
                    ? null
                    : () => _run(_login),
                child: const Text('Sign in'),
              ),
              OutlinedButton(
                onPressed: _busy || _application == null
                    ? null
                    : () => _run(() async {
                        await _reloadAccounts();
                        return 'Accounts refreshed.';
                      }),
                child: const Text('Refresh accounts'),
              ),
              OutlinedButton(
                onPressed: _busy || _selectedAccount == null
                    ? null
                    : () => _run(_silent),
                child: const Text('Acquire silently'),
              ),
              OutlinedButton(
                onPressed: _busy || _selectedAccount == null
                    ? null
                    : () => _run(_logout),
                child: const Text('Sign out'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Select an account'),
          Expanded(
            child: ListView(
              children: [
                for (final account in _accounts)
                  ListTile(
                    selected:
                        account.identifier == _selectedAccount?.identifier,
                    title: Text(account.username ?? 'Account'),
                    subtitle: Text(account.identifier),
                    onTap: _busy
                        ? null
                        : () => setState(() => _selectedAccount = account),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
