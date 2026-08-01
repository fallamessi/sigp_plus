# Intégration de la nouvelle interface SIGP+

1. Sauvegarder l'ancien dossier `lib`.
2. Remplacer entièrement le dossier `lib` du projet par celui-ci.
3. Vérifier dans `pubspec.yaml` :

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  go_router: ^14.8.1
  flutter_secure_storage: ^9.2.4
```

4. Exécuter :

```powershell
flutter clean
Remove-Item -Recurse -Force .dart_tool -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
flutter pub get
flutter run -d windows
```

Identifiants de démonstration :
- admin@sigp.local
- Admin@123

Cette version est une maquette fonctionnelle statique. Les repositories devront ensuite être reliés à l'API PHP/Supabase PostgreSQL.

## Logo CNPS

Le logo est livré dans `assets/images/cnps_logo.png`.
Ajoutez dans le `pubspec.yaml` principal :

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/cnps_logo.png
```

Le dossier `assets` fourni doit être copié à la racine du projet Flutter, au même niveau que `lib` et `pubspec.yaml`.
