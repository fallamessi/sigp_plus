import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(), password = TextEditingController();
  bool loading = false;
  String? error;
  Future<void> submit() async {
    setState(() => loading = true);
    try {
      await AuthRepository(ApiClient())
          .signIn(email.text.trim(), password.text);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      body: Center(
          child: SizedBox(
              width: 420,
              child: Card(
                  child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text('SIGP+',
                            style: TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        TextField(
                            controller: email,
                            decoration:
                                const InputDecoration(labelText: 'E-mail')),
                        const SizedBox(height: 12),
                        TextField(
                            controller: password,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Mot de passe')),
                        if (error != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(error!,
                                  style: const TextStyle(color: Colors.red))),
                        const SizedBox(height: 20),
                        FilledButton(
                            onPressed: loading ? null : submit,
                            child:
                                Text(loading ? 'Connexion...' : 'Se connecter'))
                      ]))))));
}
