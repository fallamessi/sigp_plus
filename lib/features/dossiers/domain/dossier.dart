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

  factory Dossier.fromJson(Map<String, dynamic> json) => Dossier(
        id: json['id']?.toString() ?? '',
        numero: json['numero']?.toString() ?? '',
        assure: json['assure']?.toString() ?? '',
        typeDossier: json['type_dossier']?.toString() ?? '',
        statut: json['statut']?.toString() ?? '',
        priorite: json['priorite']?.toString() ?? '',
        service: json['service']?.toString() ?? 'Non affecté',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}
