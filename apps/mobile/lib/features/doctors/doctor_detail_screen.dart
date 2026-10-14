import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../core/api.dart';
import 'doctor_model.dart';
import 'doctors_providers.dart';

const _icons = <String, IconData>{
  'hair': Icons.content_cut,
  'acne': Icons.face_retouching_natural,
  'spots': Icons.blur_on,
  'aesthetic': Icons.auto_awesome,
  'kids': Icons.child_care,
  'oncology': Icons.health_and_safety,
};

class DoctorDetailScreen extends ConsumerWidget {
  const DoctorDetailScreen(this.slug, {super.key});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctor = ref.watch(doctorProvider(slug));
    return Scaffold(
      appBar: AppBar(),
      body: doctor.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('No se pudo cargar')),
        data: (d) => _Body(d),
      ),
      bottomNavigationBar: doctor.value == null ? null : SafeArea(child: _ChatButton(doctor.value!)),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.d);
  final Doctor d;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        CircleAvatar(
          radius: 44,
          backgroundImage: d.photoUrl == null ? null : CachedNetworkImageProvider(d.photoUrl!),
          child: d.photoUrl == null ? const Icon(Icons.person, size: 40) : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.fullName, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text('${d.rating.toStringAsFixed(1)} ★ (${d.ratingCount}) · ${d.city}'),
            Text('\$${d.fee} COP / consulta', style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
      const SizedBox(height: 16),
      if (d.videoUrl != null) ...[_Video(d.videoUrl!), const SizedBox(height: 16)],
      Text(d.bio),
      const SizedBox(height: 20),
      Text('Especialidades', style: t.titleMedium),
      const SizedBox(height: 8),
      Wrap(spacing: 12, runSpacing: 12, children: [
        for (final s in d.specialties)
          SizedBox(
            width: 96,
            child: Column(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(_icons[s.icon] ?? Icons.spa, size: 28),
              ),
              const SizedBox(height: 4),
              Text(s.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ]),
          ),
      ]),
      const SizedBox(height: 20),
      Text('Agenda disponible', style: t.titleMedium),
      const SizedBox(height: 8),
      d.slots.isEmpty
          ? const Text('Sin horarios abiertos por ahora')
          : Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in d.slots)
                Chip(label: Text('${s.day}/${s.month}  ${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}')),
            ]),
    ]);
  }
}

class _Video extends StatefulWidget {
  const _Video(this.url);
  final String url;
  @override
  State<_Video> createState() => _VideoState();
}

class _VideoState extends State<_Video> {
  late final VideoPlayerController c = VideoPlayerController.networkUrl(Uri.parse(widget.url))..initialize().then((_) => setState(() {}));

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: c.value.isInitialized ? c.value.aspectRatio : 16 / 9,
          child: !c.value.isInitialized
              ? const ColoredBox(color: Colors.black12, child: Center(child: CircularProgressIndicator()))
              : GestureDetector(
                  onTap: () => setState(() => c.value.isPlaying ? c.pause() : c.play()),
                  child: Stack(alignment: Alignment.center, children: [
                    VideoPlayer(c),
                    if (!c.value.isPlaying) const Icon(Icons.play_circle_fill, size: 64, color: Colors.white70),
                  ]),
                ),
        ),
      );
}

class _ChatButton extends ConsumerWidget {
  const _ChatButton(this.d);
  final Doctor d;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Chatear con el doctor'),
          onPressed: () async {
            if (ref.read(tokenProvider) == null) {
              context.push('/login');
              return;
            }
            try {
              final r = await ref.read(dioProvider).post('/chat/doctors/${d.id}');
              if (context.mounted) context.push('/chat/${r.data['id']}?name=${Uri.encodeComponent(d.fullName)}');
            } on DioException {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el chat')));
            }
          },
        ),
      );
}
