import 'package:msal_flutter/src/models/msal_account.dart';
import 'msal_tenant_profile.dart';

class MSALResult {
  String accessToken;
  MSALAccount account;
  String authenticationScheme;
  Uri authority;
  String authorizationHeader;
  String correlationId;
  DateTime? expiresOn;
  bool? extendedLifeTimeToken;
  String? idToken;
  List<String> scopes;
  MSALTenantProfile? tenantProfile;

  MSALResult({
    required this.accessToken,
    required this.account,
    required this.authenticationScheme,
    required this.authority,
    required this.authorizationHeader,
    required this.correlationId,
    required this.scopes,
    this.expiresOn,
    this.extendedLifeTimeToken,
    this.idToken,
    this.tenantProfile,
  });

  MSALResult.fromMap(Map<String, dynamic> map)
      : this(
          accessToken: map['accessToken'] as String? ?? '',
          account: MSALAccount.fromMap(
            Map<String, dynamic>.from(
              (map['account'] as Map?) ?? const <String, dynamic>{},
            ),
          ),
          authenticationScheme: map['authenticationScheme'] as String? ?? '',
          authority: Uri.tryParse(map['authority'] as String? ?? '') ?? Uri(),
          authorizationHeader: map['authorizationHeader'] as String? ?? '',
          correlationId: map['correlationId'] as String? ?? '',
          expiresOn: _parseExpiresOn(map['expiresOn']),
          extendedLifeTimeToken: map['extendedLifeTimeToken'] as bool?,
          idToken: map['idToken'] as String?,
          scopes: List<String>.from(map['scopes'] ?? const []),
          tenantProfile: map['tenantProfile'] == null
              ? null
              : MSALTenantProfile.fromMap(
                  Map<String, dynamic>.from(map['tenantProfile'] as Map),
                ),
        );

  static DateTime? _parseExpiresOn(dynamic value) {
    if (value == null) return null;

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
