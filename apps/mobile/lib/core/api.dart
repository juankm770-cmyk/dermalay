import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3000/v1');

final storageProvider = Provider((_) => const FlutterSecureStorage());

/// Token en memoria; se persiste en almacenamiento seguro (Keystore en Android).
final tokenProvider = NotifierProvider<TokenNotifier, String?>(TokenNotifier.new);

class TokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  Future<void> load() async => state = await ref.read(storageProvider).read(key: 'token');

  Future<void> set(String? token) async {
    final s = ref.read(storageProvider);
    token == null ? await s.delete(key: 'token') : await s.write(key: 'token', value: token);
    state = token;
  }
}

final dioProvider = Provider((ref) {
  final dio = Dio(BaseOptions(baseUrl: apiUrl, connectTimeout: const Duration(seconds: 10)));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
    final t = ref.read(tokenProvider);
    if (t != null) o.headers['Authorization'] = 'Bearer $t';
    h.next(o);
  }, onError: (e, h) {
    if (e.response?.statusCode == 401) ref.read(tokenProvider.notifier).set(null);
    h.next(e);
  }));
  return dio;
});
