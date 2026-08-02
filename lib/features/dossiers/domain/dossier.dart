class Dossier {
  const Dossier({
    required this.id,
    required this.numero,
    required this.assure,
    required this.typeDossier,
    required this.statut,
    required this.priorite,
    required this.service,
    required this.createdAt,
  });

  final String id;
  final String numero;
  final String assure;
  final String typeDossier;
  final String statut;
  final String priorite;
  final String service;
  final DateTime? createdAt;

  factory Dossier.fromJson(Map<String, dynamic> json) {
    final type = _asMap(json['types_dossier']);
    final service = _asMap(json['services']);
    final people = json['dossier_personne'];

    String assure = 'Non renseigné';
    if (people is List) {
      for (final item in people.whereType<Map>()) {
        final relation = Map<String, dynamic>.from(item);
        final person = _asMap(relation['personnes']);
        if (person.isEmpty) continue;
        final fullName = '${person['prenom'] ?? ''} ${person['nom'] ?? ''}'.trim();
        if (fullName.isNotEmpty) {
          assure = fullName;
          if ((relation['role']?.toString().toUpperCase() ?? '') == 'ASSURE') {
            break;
          }
        }
      }
    }

    final category = type['categorie']?.toString() ?? '';
    final dossierType = type['type']?.toString() ?? '';
    final composedType = [category, dossierType]
        .where((value) => value.trim().isNotEmpty)
        .join(' - ');

    return Dossier(
      id: json['id']?.toString() ?? '',
      numero: json['numero_dossier']?.toString() ??
          json['numero']?.toString() ??
          '',
      assure: assure,
      typeDossier: composedType.isNotEmpty
          ? composedType
          : json['type_dossier']?.toString() ?? 'Non défini',
      statut: json['statut_courant']?.toString() ??
          json['statut']?.toString() ??
          'CREE',
      priorite: json['priorite']?.toString() ?? 'NORMALE',
      service: service['nom']?.toString() ??
          json['service']?.toString() ??
          'Non affecté',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}
