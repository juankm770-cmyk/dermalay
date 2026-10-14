import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api.dart';
import 'doctor_model.dart';

class Filters {
  const Filters({this.city, this.specialty});
  final String? city, specialty;
  @override
  bool operator ==(Object other) => other is Filters && other.city == city && other.specialty == specialty;
  @override
  int get hashCode => Object.hash(city, specialty);
}

final filtersProvider = NotifierProvider<FiltersNotifier, Filters>(FiltersNotifier.new);

class FiltersNotifier extends Notifier<Filters> {
  @override
  Filters build() => const Filters();
  void set(Filters f) => state = f;
}

final citiesProvider = FutureProvider((ref) async {
  final r = await ref.read(dioProvider).get('/cities');
  return [for (final j in r.data) Option.fromJson(j)];
});

final specialtiesProvider = FutureProvider((ref) async {
  final r = await ref.read(dioProvider).get('/specialties');
  return [for (final j in r.data) Option.fromJson(j)];
});

final doctorsProvider = FutureProvider((ref) async {
  final f = ref.watch(filtersProvider);
  final r = await ref.read(dioProvider).get('/doctors', queryParameters: {
    if (f.city != null) 'city': f.city,
    if (f.specialty != null) 'specialty': f.specialty,
  });
  return [for (final j in r.data['items']) Doctor.fromJson(j)];
});

final doctorProvider = FutureProvider.family((ref, String slug) async {
  final r = await ref.read(dioProvider).get('/doctors/$slug');
  return Doctor.fromJson(r.data);
});
