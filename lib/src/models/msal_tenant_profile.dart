class MSALTenantProfile {
  String? tenantId;
  String? environment;
  String? identifier;
  bool? isHomeTenantProfile;

  MSALTenantProfile({
    this.tenantId,
    this.environment,
    this.identifier,
    this.isHomeTenantProfile,
  });

  MSALTenantProfile.fromMap(Map<String, dynamic> map)
      : this(
          tenantId: map['tenantId'] as String?,
          environment: map['environment'] as String?,
          identifier: map['identifier'] as String?,
          isHomeTenantProfile: map['isHomeTenantProfile'] as bool?,
        );
}
