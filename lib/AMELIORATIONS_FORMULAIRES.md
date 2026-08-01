# Améliorations intégrées

- Messages explicites pour absence de connexion, délai serveur et identifiants incorrects.
- Tous les champs de relation terminant par `_id` sont automatiquement affichés sous forme de liste déroulante.
- Les champs utilisateur techniques (`responsable`, `traite_par`, `archive_par`, `calcule_par`, `cree_par`, `modifie_par`) chargent la table `utilisateurs`.
- Les listes sont chargées depuis `/api/entities/{table}` avec un maximum de 100 éléments selon le dépôt existant.
- Les libellés privilégient `nom_complet`, `nom`, `libelle`, `numero_dossier`, `numero`, `code`, `email`, `matricule`, puis `titre`.
- Une erreur de chargement d’une liste affiche un message et un bouton « Recharger la liste ».

Exemples de correspondance automatique :

- `dossier_id` → `dossiers`
- `utilisateur_id` → `utilisateurs`
- `responsable_id` → `utilisateurs`
- `agence_id` → `agences`
- `service_id` → `services`
- `role_id` → `roles`

Une correspondance particulière peut être forcée avec :

```dart
DynamicFormField(
  keyName: 'champ_id',
  label: 'Libellé',
  type: DynamicFieldType.select,
  referenceEntity: 'table_api',
  required: true,
)
```
