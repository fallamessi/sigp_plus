import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cnps_brand.dart';
import 'auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _dialogOpened = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = ref.read(authControllerProvider.notifier);
    try {
      await controller.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      final state = ref.read(authControllerProvider);
      if (state.error != null && state.error!.trim().isNotEmpty) {
        await _showError(state.error!);
      }
    } catch (error, stackTrace) {
      developer.log('Erreur de connexion', name: 'SIGP.LOGIN', error: error, stackTrace: stackTrace);
      if (mounted) await _showError(error.toString());
    }
  }

  Future<void> _showError(String message) async {
    if (!mounted || _dialogOpened) return;
    _dialogOpened = true;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.error_outline_rounded, color: AppTheme.cnpsRed, size: 42),
          title: const Text('Connexion impossible'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SelectableText(message.trim().isEmpty ? 'Une erreur inconnue est survenue.' : message.trim()),
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Fermer'))],
        ),
      );
    } finally {
      _dialogOpened = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 11,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.navy, AppTheme.cnpsBlue],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(right: -100, top: -120, child: _Glow(size: 380, opacity: .08)),
                  Positioned(left: -80, bottom: -100, child: _Glow(size: 320, opacity: .06)),
                  Padding(
                    padding: const EdgeInsets.all(56),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: const CnpsLogo(height: 64),
                        ),
                        const Spacer(),
                        const Text('SIGP+', style: TextStyle(color: Colors.white, fontSize: 58, fontWeight: FontWeight.w900, letterSpacing: -1)),
                        const SizedBox(height: 12),
                        const Text(
                          'Système Intégré de Gestion des Pensions',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 18),
                        const SizedBox(
                          width: 540,
                          child: Text(
                            'Une plateforme institutionnelle sécurisée pour le traitement, le suivi et l’archivage des dossiers de pension de la CNPS.',
                            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.55),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _Feature(icon: Icons.shield_outlined, label: 'Sécurisé'),
                            _Feature(icon: Icons.cloud_sync_outlined, label: 'Online / Offline'),
                            _Feature(icon: Icons.history_rounded, label: 'Traçabilité complète'),
                          ],
                        ),
                        const Spacer(),
                        const Text('© 2026 CNPS Guinée • Direction des systèmes d’information', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 9,
            child: Container(
              color: AppTheme.surface,
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 470),
                  child: Card(
                    child: Column(
                      children: [
                        const CnpsColorBar(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(38, 36, 38, 38),
                          child: AutofillGroup(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Bienvenue', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppTheme.navy)),
                                  const SizedBox(height: 8),
                                  const Text('Connectez-vous à votre espace professionnel SIGP+.', style: TextStyle(color: Color(0xFF64748B), height: 1.5)),
                                  const SizedBox(height: 30),
                                  TextFormField(
                                    controller: _email,
                                    enabled: !auth.loading,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.username, AutofillHints.email],
                                    decoration: const InputDecoration(labelText: 'Adresse e-mail', prefixIcon: Icon(Icons.mail_outline_rounded)),
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty) return 'Adresse e-mail obligatoire';
                                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) return 'Adresse e-mail invalide';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: _password,
                                    enabled: !auth.loading,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [AutofillHints.password],
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: InputDecoration(
                                      labelText: 'Mot de passe',
                                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                                      suffixIcon: IconButton(
                                        tooltip: _obscure ? 'Afficher' : 'Masquer',
                                        onPressed: auth.loading ? null : () => setState(() => _obscure = !_obscure),
                                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                      ),
                                    ),
                                    validator: (value) => (value == null || value.isEmpty) ? 'Mot de passe obligatoire' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(onPressed: auth.loading ? null : () {}, child: const Text('Mot de passe oublié ?')),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: auth.loading ? null : _submit,
                                    icon: auth.loading
                                        ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(Icons.login_rounded),
                                    label: Text(auth.loading ? 'Connexion en cours…' : 'Se connecter'),
                                  ),
                                  const SizedBox(height: 24),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.verified_user_outlined, size: 17, color: AppTheme.cnpsGreen),
                                      SizedBox(width: 8),
                                      Flexible(child: Text('Accès réservé au personnel autorisé de la CNPS', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.opacity});
  final double size;
  final double opacity;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
  );
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: .16))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))]),
  );
}
