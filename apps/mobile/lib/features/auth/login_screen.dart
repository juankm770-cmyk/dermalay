import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginScreen> {
  final email = TextEditingController(), password = TextEditingController(), name = TextEditingController();
  bool register = false, busy = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = await ref.read(dioProvider).post(register ? '/auth/register' : '/auth/login', data: {
        if (register) 'fullName': name.text.trim(),
        'email': email.text.trim(),
        'password': password.text,
      });
      await ref.read(tokenProvider.notifier).set(r.data['accessToken']);
      if (mounted) context.pop();
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      setState(() => error = code == 401 ? 'Correo o contraseña incorrectos' : code == 409 ? 'Ese correo ya está registrado' : 'No se pudo conectar');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(register ? 'Crear cuenta' : 'Iniciar sesión')),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          if (register) ...[TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre completo')), const SizedBox(height: 12)],
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo')),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña (mín. 8)')),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 20),
          FilledButton(onPressed: busy ? null : submit, child: Text(register ? 'Registrarme' : 'Entrar')),
          TextButton(onPressed: () => setState(() => register = !register), child: Text(register ? 'Ya tengo cuenta' : 'Crear cuenta')),
          const Divider(height: 32),
          // TODO: Google y teléfono (Firebase) cuando esté el proyecto Firebase.
          const Text('Acceso con Google y teléfono: próximamente', textAlign: TextAlign.center),
        ]),
      );
}
