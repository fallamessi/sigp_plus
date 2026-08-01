import '../../../core/security/permission.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.permissions,
    this.roleLabel,
    this.matricule,
    this.agence,
    this.service,
  });

  final String id;
  final String fullName;
  final String email;

  /// Code technique du rôle : ADMIN, AGENT, SUPERVISEUR...
  final String role;

  /// Libellé affiché : Administrateur système...
  final String? roleLabel;

  final Set<Permission> permissions;
  final String? matricule;
  final String? agence;
  final String? service;

  /// Vérifie si l'utilisateur est administrateur.
  bool get isAdmin {
    final normalizedRole = role.trim().toUpperCase();

    return normalizedRole == 'ADMIN' ||
        normalizedRole == 'SUPER_ADMIN' ||
        normalizedRole == 'SUPERADMIN';
  }

  /// Vérifie une permission.
  ///
  /// L'administrateur système possède automatiquement
  /// l'accès à tous les modules.
  bool can(Permission permission) {
    if (isAdmin) {
      return true;
    }

    return permissions.contains(permission);
  }

  /// Vérifie si l'utilisateur possède au moins une permission.
  bool canAny(Iterable<Permission> requiredPermissions) {
    if (isAdmin) {
      return true;
    }

    return requiredPermissions.any(permissions.contains);
  }

  /// Vérifie si l'utilisateur possède toutes les permissions.
  bool canAll(Iterable<Permission> requiredPermissions) {
    if (isAdmin) {
      return true;
    }

    return requiredPermissions.every(permissions.contains);
  }

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((element) => element.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final roleValue = json['role'];

    String roleCode = '';
    String? roleLabel;

    if (roleValue is Map) {
      /*
       * Important :
       * on récupère d'abord le CODE technique,
       * puis séparément le libellé.
       */
      roleCode = (
          roleValue['code'] ??
              json['role_code'] ??
              ''
      ).toString().trim();

      final labelValue =
          roleValue['libelle'] ??
              roleValue['label'] ??
              roleValue['description'];

      roleLabel = labelValue?.toString().trim();
    } else {
      roleCode = (
          roleValue ??
              json['role_code'] ??
              ''
      ).toString().trim();

      roleLabel = json['role_libelle']?.toString().trim();
    }

    final agenceValue = json['agence'];
    final serviceValue = json['service'];

    final rawPermissions =
        json['permissions'] as List<dynamic>? ??
            const <dynamic>[];

    final permissions = rawPermissions
        .map<String>((item) {
      if (item is Map) {
        return item['code']?.toString().trim() ?? '';
      }

      return item.toString().trim();
    })
        .where((code) => code.isNotEmpty)
        .map(permissionFromApi)
        .whereType<Permission>()
        .toSet();

    final fullName = (
        json['nom_complet'] ??
            json['full_name'] ??
            json['fullName'] ??
            ''
    ).toString().trim();

    final fallbackName = [
      json['prenom']?.toString().trim() ?? '',
      json['nom']?.toString().trim() ?? '',
    ].where((value) => value.isNotEmpty).join(' ');

    return AppUser(
      id: json['id']?.toString() ?? '',
      fullName: fullName.isNotEmpty
          ? fullName
          : fallbackName,
      email: json['email']?.toString() ?? '',
      role: roleCode.toUpperCase(),
      roleLabel: roleLabel,
      matricule: json['matricule']?.toString(),
      agence: _extractName(agenceValue),
      service: _extractName(serviceValue),
      permissions: permissions,
    );
  }

  static String? _extractName(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Map) {
      final name = (
          value['nom'] ??
              value['libelle'] ??
              value['name']
      )?.toString().trim();

      return name == null || name.isEmpty ? null : name;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }
}