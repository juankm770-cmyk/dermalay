import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/api.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/doctors/doctor_detail_screen.dart';
import 'features/doctors/doctors_list_screen.dart';

final _router = GoRouter(routes: [
  GoRoute(path: '/', builder: (_, _) => const DoctorsListScreen()),
  GoRoute(path: '/doctor/:slug', builder: (_, s) => DoctorDetailScreen(s.pathParameters['slug']!)),
  GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
  GoRoute(
    path: '/chat/:id',
    builder: (_, s) => ChatScreen(s.pathParameters['id']!, s.uri.queryParameters['name'] ?? 'Chat'),
  ),
]);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(tokenProvider.notifier).load();
  runApp(UncontrolledProviderScope(container: container, child: const DermalayApp()));
}

class DermalayApp extends StatelessWidget {
  const DermalayApp({super.key});
  @override
  Widget build(BuildContext context) =>
      MaterialApp.router(title: 'Dermalay', theme: buildTheme(), routerConfig: _router, debugShowCheckedModeBanner: false);
}
