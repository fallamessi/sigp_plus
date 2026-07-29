# SIGP+ — Flutter Desktop Offline First

## Fonctions incluses
- Authentification Supabase Auth.
- SQLite local avec Drift.
- Ajout, modification, suppression logique et recherche hors connexion.
- File d’attente de synchronisation et indicateur `synced / pending / error`.
- Synchronisation PostgreSQL au retour de la connexion.
- Pages Agences, Services, Personnes, Dossiers, Documents, Notifications et Audit.
- Design Desktop Material 3 avec menu latéral.
- SQL pour `updated_at`, `deleted_at`, audit par triggers, RLS et Realtime.

## Installation
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows --dart-define=SUPABASE_URL=https://VOTRE-PROJET.supabase.co --dart-define=SUPABASE_ANON_KEY=VOTRE_CLE_PUBLISHABLE
```

Exécutez d’abord votre schéma PostgreSQL dans Supabase, puis `supabase/001_offline_audit.sql`.

## Important
Ne placez jamais la `service_role` dans Flutter. Utilisez seulement la clé publishable/anon. Pour OCR/IA, créez un microservice ou une Edge Function qui lit un document Storage et écrit le résultat dans `documents.donnees_ocr` / `ia_analyses`.

## Extension des modules
Le composant `CrudPage` est générique. Ajoutez un élément dans `ShellPage` avec le nom réel de la table et ses champs. Pour les relations complexes (dossiers, workflow, documents), créez ensuite des formulaires spécialisés avec listes déroulantes et validations métier.
