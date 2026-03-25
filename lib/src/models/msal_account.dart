import 'package:msal_flutter/src/utility/extensions/map_cleanup_extension.dart';

class MSALAccount {
  String? username;
  String identifier;
  String? environment;
  Map<String, dynamic>? accountClaims;
  bool isSSOAccount;

  MSALAccount({
    required this.identifier,
    this.isSSOAccount = false,
    this.username,
    this.environment,
    this.accountClaims,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'identifier': identifier,
      'environment': environment,
      'accountClaims': accountClaims,
      'isSSOAccount': isSSOAccount,
    }.cleanup();
  }

  MSALAccount.fromMap(Map<String, dynamic> map)
      : this(
          username: map['username'] as String?,
          identifier: map['identifier'] as String? ?? '',
          environment: map['environment'] as String?,
          accountClaims: map['accountClaims'] == null
              ? null
              : Map<String, dynamic>.from(map['accountClaims'] as Map),
          isSSOAccount: map['isSSOAccount'] as bool? ?? false,
        );
}
