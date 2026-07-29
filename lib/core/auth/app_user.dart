class AppUser {
  final String id, nom, prenom, roleCode;
  final bool actif;
  final List<String> permissions;
  const AppUser(
      {required this.id,
      required this.nom,
      required this.prenom,
      required this.roleCode,
      required this.actif,
      required this.permissions});
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
      id: j['id'],
      nom: j['nom'],
      prenom: j['prenom'],
      roleCode: j['role_code'],
      actif: j['actif'] ?? false,
      permissions: List<String>.from(j['permissions'] ?? const []));
  bool can(String permission) => permissions.contains(permission);
}
