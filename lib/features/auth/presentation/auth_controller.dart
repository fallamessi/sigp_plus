import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
as supabase;

import '../../../core/providers/supabase_provider.dart';
import '../../../core/security/permission.dart';
import '../domain/app_user.dart';

class AppAuthState {
  const AppAuthState({
    this.user,
    this.loading = false,
    this.error,
  });

  final AppUser? user;
  final bool loading;
  final String? error;

  bool get authenticated => user != null;

  AppAuthState copyWith({
    AppUser? user,
    bool? loading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AppAuthState(
      user: clearUser
          ? null
          : user ?? this.user,
      loading: loading ?? this.loading,
      error: clearError
          ? null
          : error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'AppAuthState('
        'loading: $loading, '
        'authenticated: $authenticated, '
        'user: ${user?.email}, '
        'error: $error'
        ')';
  }
}

class AuthController
    extends StateNotifier<AppAuthState> {
  AuthController(this._supabase)
      : super(const AppAuthState()) {
    developer.log(
      'Initialisation de AuthController',
      name: 'SIGP.AUTH',
    );

    _listenToAuthChanges();
    restore();
  }

  final supabase.SupabaseClient _supabase;

  StreamSubscription<supabase.AuthState>?
  _subscription;

  void _listenToAuthChanges() {
    developer.log(
      'Démarrage de l’écoute Supabase Auth',
      name: 'SIGP.AUTH',
    );

    _subscription =
        _supabase.auth.onAuthStateChange.listen(
              (supabase.AuthState authState) {
            developer.log(
              'Événement Supabase Auth : '
                  '${authState.event.name}',
              name: 'SIGP.AUTH',
            );

            developer.log(
              'Session présente : '
                  '${authState.session != null}',
              name: 'SIGP.AUTH',
            );

            developer.log(
              'Utilisateur de la session : '
                  '${authState.session?.user.email}',
              name: 'SIGP.AUTH',
            );

            switch (authState.event) {
              case supabase.AuthChangeEvent.signedIn:
              case supabase.AuthChangeEvent.tokenRefreshed:
              case supabase.AuthChangeEvent.userUpdated:
              case supabase.AuthChangeEvent.initialSession:
              case supabase.AuthChangeEvent.passwordRecovery:
              case supabase.AuthChangeEvent.mfaChallengeVerified:
                restore();
                break;

              case supabase.AuthChangeEvent.signedOut:
              case supabase.AuthChangeEvent.userDeleted:
                state = const AppAuthState();
                break;
            }
          },
          onError: (
              Object error,
              StackTrace stackTrace,
              ) {
            developer.log(
              'Erreur du flux Supabase Auth',
              name: 'SIGP.AUTH',
              error: error,
              stackTrace: stackTrace,
            );

            state = AppAuthState(
              user: state.user,
              loading: false,
              error:
              'Erreur de session Supabase : $error',
            );
          },
        );
  }

  Future<void> restore() async {
    developer.log(
      'Restauration de la session',
      name: 'SIGP.AUTH',
    );

    final supabase.Session? session =
        _supabase.auth.currentSession;

    if (session == null) {
      developer.log(
        'Aucune session Supabase enregistrée',
        name: 'SIGP.AUTH',
      );

      state = const AppAuthState();
      return;
    }

    developer.log(
      'Session trouvée pour ${session.user.email}',
      name: 'SIGP.AUTH',
    );

    state = AppAuthState(
      user: state.user,
      loading: true,
    );

    try {
      final AppUser appUser = await _loadUser(
        session.user,
      );

      developer.log(
        'Session restaurée avec succès : '
            '${appUser.email}',
        name: 'SIGP.AUTH',
      );

      state = AppAuthState(
        user: appUser,
        loading: false,
      );
    } on supabase.AuthException catch (
    error,
    stackTrace
    ) {
    developer.log(
    'Erreur Auth pendant restore()',
    name: 'SIGP.AUTH',
    error: error,
    stackTrace: stackTrace,
    );

    state = AppAuthState(
    loading: false,
    error: _translateAuthError(
    error.message,
    ),
    );
    } catch (error, stackTrace) {
    developer.log(
    'Erreur inattendue pendant restore()',
    name: 'SIGP.AUTH',
    error: error,
    stackTrace: stackTrace,
    );

    state = AppAuthState(
    loading: false,
    error:
    'Impossible de restaurer la session : '
    '$error',
    );
    }
  }

  Future<bool> login(
      String email,
      String password,
      ) async {
    final String normalizedEmail =
    email.trim().toLowerCase();

    developer.log(
      'Début de login()',
      name: 'SIGP.AUTH',
    );

    developer.log(
      'Email normalisé : $normalizedEmail',
      name: 'SIGP.AUTH',
    );

    if (normalizedEmail.isEmpty) {
      state = const AppAuthState(
        error:
        'Veuillez saisir votre adresse e-mail.',
      );

      return false;
    }

    if (password.isEmpty) {
      state = const AppAuthState(
        error:
        'Veuillez saisir votre mot de passe.',
      );

      return false;
    }

    state = const AppAuthState(
      loading: true,
    );

    try {
      developer.log(
        'Envoi de signInWithPassword() à Supabase',
        name: 'SIGP.AUTH',
      );

      final supabase.AuthResponse response =
      await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      developer.log(
        'Réponse Supabase reçue',
        name: 'SIGP.AUTH',
      );

      developer.log(
        'Session créée : '
            '${response.session != null}',
        name: 'SIGP.AUTH',
      );

      developer.log(
        'ID utilisateur : '
            '${response.user?.id}',
        name: 'SIGP.AUTH',
      );

      developer.log(
        'E-mail utilisateur : '
            '${response.user?.email}',
        name: 'SIGP.AUTH',
      );

      final supabase.User? authUser =
          response.user;

      if (authUser == null) {
        throw const supabase.AuthException(
          'Connexion refusée : aucun utilisateur retourné.',
        );
      }

      developer.log(
        'Chargement du profil métier',
        name: 'SIGP.AUTH',
      );

      final AppUser appUser = await _loadUser(
        authUser,
      );

      developer.log(
        'Profil métier chargé : '
            '${appUser.fullName}',
        name: 'SIGP.AUTH',
      );

      state = AppAuthState(
        user: appUser,
        loading: false,
      );

      developer.log(
        'Connexion terminée avec succès',
        name: 'SIGP.AUTH',
      );

      return true;
    } on supabase.AuthException catch (
    error,
    stackTrace
    ) {
    developer.log(
    'Erreur Supabase pendant login()',
    name: 'SIGP.AUTH',
    error: error,
    stackTrace: stackTrace,
    );

    state = AppAuthState(
    loading: false,
    error: _translateAuthError(
    error.message,
    ),
    );

    return false;
    } on supabase.PostgrestException catch (
    error,
    stackTrace
    ) {
    developer.log(
    'Erreur PostgreSQL pendant login()',
    name: 'SIGP.AUTH',
    error: error,
    stackTrace: stackTrace,
    );

    developer.log(
    'PostgREST code=${error.code}, '
    'message=${error.message}, '
    'details=${error.details}, '
    'hint=${error.hint}',
    name: 'SIGP.AUTH',
    );

    state = AppAuthState(
    loading: false,
    error:
    'Erreur de lecture du profil PostgreSQL.\n\n'
    'Code : ${error.code}\n'
    'Message : ${error.message}\n'
    'Détails : ${error.details ?? '-'}\n'
    'Conseil : ${error.hint ?? '-'}',
    );

    return false;
    } catch (error, stackTrace) {
    developer.log(
    'Erreur inattendue pendant login()',
    name: 'SIGP.AUTH',
    error: error,
    stackTrace: stackTrace,
    );

    state = AppAuthState(
    loading: false,
    error:
    'Une erreur inattendue est survenue : '
    '$error',
    );

    return false;
    }
  }

  Future<AppUser> _loadUser(
      supabase.User authUser,
      ) async {
    developer.log(
      'Lecture de profils_utilisateurs',
      name: 'SIGP.AUTH.PROFILE',
    );

    developer.log(
      'Recherche du profil avec id=${authUser.id}',
      name: 'SIGP.AUTH.PROFILE',
    );

    final dynamic profileResponse =
    await _supabase
        .from('profils_utilisateurs')
        .select(
      '''
              id,
              matricule,
              nom,
              prenom,
              actif,
              role_id,
              roles (
                id,
                code,
                libelle
              ),
              agences (
                id,
                code,
                nom
              ),
              services (
                id,
                code,
                nom
              )
              ''',
    )
        .eq('id', authUser.id)
        .maybeSingle();

    developer.log(
      'Réponse profils_utilisateurs : '
          '$profileResponse',
      name: 'SIGP.AUTH.PROFILE',
    );

    if (profileResponse == null) {
      developer.log(
        'Aucun profil métier trouvé',
        name: 'SIGP.AUTH.PROFILE',
      );

      throw const supabase.AuthException(
        'Aucun profil métier n’est associé '
            'à ce compte dans profils_utilisateurs.',
      );
    }

    final Map<String, dynamic> profile =
    Map<String, dynamic>.from(
      profileResponse as Map,
    );

    developer.log(
      'Profil actif=${profile['actif']}',
      name: 'SIGP.AUTH.PROFILE',
    );

    if (profile['actif'] != true) {
      developer.log(
        'Compte désactivé, déconnexion',
        name: 'SIGP.AUTH.PROFILE',
      );

      await _supabase.auth.signOut();

      throw const supabase.AuthException(
        'Votre compte utilisateur est désactivé.',
      );
    }

    final Map<String, dynamic> role =
    _mapFromDynamic(profile['roles']);

    final Map<String, dynamic> agence =
    _mapFromDynamic(profile['agences']);

    final Map<String, dynamic> service =
    _mapFromDynamic(profile['services']);

    developer.log(
      'Rôle reçu : $role',
      name: 'SIGP.AUTH.PROFILE',
    );

    developer.log(
      'Agence reçue : $agence',
      name: 'SIGP.AUTH.PROFILE',
    );

    developer.log(
      'Service reçu : $service',
      name: 'SIGP.AUTH.PROFILE',
    );

    final String? roleId =
        role['id']?.toString() ??
            profile['role_id']?.toString();

    final Set<Permission> permissions =
    await _loadPermissions(roleId);

    final String prenom =
        profile['prenom']?.toString().trim() ??
            '';

    final String nom =
        profile['nom']?.toString().trim() ??
            '';

    final AppUser appUser = AppUser(
      id: authUser.id,
      fullName: '$prenom $nom'.trim(),
      email: authUser.email ?? '',
      role: role['code']?.toString() ?? '',
      roleLabel:
      role['libelle']?.toString(),
      matricule:
      profile['matricule']?.toString(),
      agence: agence['nom']?.toString(),
      service: service['nom']?.toString(),
      permissions: permissions,
    );

    developer.log(
      'AppUser construit : '
          'id=${appUser.id}, '
          'email=${appUser.email}, '
          'role=${appUser.role}, '
          'permissions=${permissions.length}',
      name: 'SIGP.AUTH.PROFILE',
    );

    return appUser;
  }

  Future<Set<Permission>> _loadPermissions(
      String? roleId,
      ) async {
    developer.log(
      'Chargement des permissions '
          'pour roleId=$roleId',
      name: 'SIGP.AUTH.PERMISSIONS',
    );

    if (roleId == null || roleId.isEmpty) {
      developer.log(
        'Aucun roleId fourni',
        name: 'SIGP.AUTH.PERMISSIONS',
      );

      return <Permission>{};
    }

    final dynamic response = await _supabase
        .from('role_permissions')
        .select(
      '''
          permission_id,
          permissions (
            id,
            code,
            module,
            description
          )
          ''',
    )
        .eq('role_id', roleId);

    developer.log(
      'Réponse permissions : $response',
      name: 'SIGP.AUTH.PERMISSIONS',
    );

    final Set<Permission> permissions =
    <Permission>{};

    if (response is! List) {
      developer.log(
        'Format de permissions inattendu',
        name: 'SIGP.AUTH.PERMISSIONS',
      );

      return permissions;
    }

    for (final dynamic item in response) {
      if (item is! Map) {
        continue;
      }

      final Map<String, dynamic> row =
      Map<String, dynamic>.from(item);

      final Map<String, dynamic>
      permissionData = _mapFromDynamic(
        row['permissions'],
      );

      final String code =
          permissionData['code']?.toString() ??
              '';

      developer.log(
        'Permission PostgreSQL : $code',
        name: 'SIGP.AUTH.PERMISSIONS',
      );

      final Permission? permission =
      permissionFromApi(code);

      if (permission != null) {
        permissions.add(permission);
      } else {
        developer.log(
          'Permission inconnue dans Flutter : $code',
          name: 'SIGP.AUTH.PERMISSIONS',
        );
      }
    }

    developer.log(
      '${permissions.length} permission(s) chargée(s)',
      name: 'SIGP.AUTH.PERMISSIONS',
    );

    return permissions;
  }

  Future<void> refreshProfile() async {
    final supabase.User? authUser =
        _supabase.auth.currentUser;

    if (authUser == null) {
      state = const AppAuthState();
      return;
    }

    state = AppAuthState(
      user: state.user,
      loading: true,
    );

    try {
      final AppUser appUser =
      await _loadUser(authUser);

      state = AppAuthState(
        user: appUser,
        loading: false,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Erreur refreshProfile()',
        name: 'SIGP.AUTH',
        error: error,
        stackTrace: stackTrace,
      );

      state = AppAuthState(
        user: state.user,
        loading: false,
        error:
        'Impossible de rafraîchir le profil : '
            '$error',
      );
    }
  }

  Future<void> logout() async {
    developer.log(
      'Déconnexion demandée',
      name: 'SIGP.AUTH',
    );

    state = AppAuthState(
      user: state.user,
      loading: true,
    );

    try {
      await _supabase.auth.signOut();

      developer.log(
        'Déconnexion Supabase réussie',
        name: 'SIGP.AUTH',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Erreur pendant logout()',
        name: 'SIGP.AUTH',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      state = const AppAuthState();
    }
  }

  void clearError() {
    developer.log(
      'Effacement de l’erreur Auth',
      name: 'SIGP.AUTH',
    );

    state = AppAuthState(
      user: state.user,
      loading: false,
    );
  }

  Map<String, dynamic> _mapFromDynamic(
      dynamic value,
      ) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return <String, dynamic>{};
  }

  String _translateAuthError(String message) {
    final String normalized =
    message.toLowerCase();

    if (normalized.contains(
      'invalid login credentials',
    )) {
      return 'Adresse e-mail ou mot de passe incorrect.';
    }

    if (normalized.contains(
      'email not confirmed',
    )) {
      return 'Votre adresse e-mail n’a pas '
          'encore été confirmée.';
    }

    if (normalized.contains(
      'user not found',
    )) {
      return 'Aucun utilisateur ne correspond '
          'à ces informations.';
    }

    if (normalized.contains(
      'too many requests',
    )) {
      return 'Trop de tentatives. Veuillez '
          'réessayer plus tard.';
    }

    if (normalized.contains('network')) {
      return 'Impossible de contacter Supabase. '
          'Vérifiez votre connexion Internet.';
    }

    return message;
  }

  @override
  void dispose() {
    developer.log(
      'Destruction de AuthController',
      name: 'SIGP.AUTH',
    );

    _subscription?.cancel();

    super.dispose();
  }
}

final authControllerProvider =
StateNotifierProvider<
    AuthController,
    AppAuthState>(
      (Ref ref) {
    final supabase.SupabaseClient client =
    ref.watch(supabaseClientProvider);

    return AuthController(client);
  },
);