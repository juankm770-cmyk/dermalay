import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'doctor_model.dart';
import 'doctors_providers.dart';

class DoctorsListScreen extends ConsumerWidget {
  const DoctorsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctors = ref.watch(doctorsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dermalay'), centerTitle: false),
      body: Column(children: [
        const _FilterBar(),
        Expanded(
          child: doctors.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: FilledButton(onPressed: () => ref.invalidate(doctorsProvider), child: const Text('Reintentar')),
            ),
            data: (list) => list.isEmpty
                ? const Center(child: Text('No hay dermatólogos con esos filtros'))
                : RefreshIndicator(
                    onRefresh: () async => ref.refresh(doctorsProvider.future),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => DoctorCard(list[i]),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(filtersProvider);
    final cities = ref.watch(citiesProvider).value ?? [];
    final specs = ref.watch(specialtiesProvider).value ?? [];
    Widget drop(String hint, List<Option> items, String? value, void Function(String?) on) => Expanded(
          child: DropdownButtonFormField<String?>(
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(labelText: hint, isDense: true),
            items: [
              DropdownMenuItem(value: null, child: Text('Todas')),
              for (final o in items) DropdownMenuItem(value: o.slug, child: Text(o.name)),
            ],
            onChanged: on,
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(children: [
        drop('Ciudad', cities, f.city, (v) => ref.read(filtersProvider.notifier).set(Filters(city: v, specialty: f.specialty))),
        const SizedBox(width: 12),
        drop('Especialidad', specs, f.specialty, (v) => ref.read(filtersProvider.notifier).set(Filters(city: f.city, specialty: v))),
      ]),
    );
  }
}

class DoctorCard extends StatelessWidget {
  const DoctorCard(this.d, {super.key});
  final Doctor d;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/doctor/${d.slug}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: d.photoUrl == null
                      ? const ColoredBox(color: Color(0xFFE3EFEE), child: Icon(Icons.person, size: 48))
                      : CachedNetworkImage(imageUrl: d.photoUrl!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.fullName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF5A623)),
                    Text(' ${d.rating.toStringAsFixed(1)} (${d.ratingCount})'),
                    const SizedBox(width: 10),
                    const Icon(Icons.place_outlined, size: 16),
                    Text(' ${d.city}'),
                  ]),
                  const SizedBox(height: 6),
                  Text(d.bio, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text('\$${d.fee} COP / consulta', style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
        ),
      );
}
