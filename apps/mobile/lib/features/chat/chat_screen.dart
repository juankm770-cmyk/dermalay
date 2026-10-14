import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api.dart';

/// MVP: consulta mensajes cada 5 s. Se reemplazará por WebSocket.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen(this.conversationId, this.name, {super.key});
  final String conversationId, name;
  @override
  ConsumerState<ChatScreen> createState() => _ChatState();
}

class _ChatState extends ConsumerState<ChatScreen> {
  final input = TextEditingController();
  List<dynamic> messages = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    load();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => load());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final r = await ref.read(dioProvider).get('/chat/conversations/${widget.conversationId}/messages');
      if (mounted) setState(() => messages = r.data);
    } catch (_) {}
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty) return;
    input.clear();
    await ref.read(dioProvider).post('/chat/conversations/${widget.conversationId}/messages', data: {'body': text});
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.name)),
        body: Column(children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (_, i) => Align(
                alignment: Alignment.centerRight,
                child: Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(padding: const EdgeInsets.all(10), child: Text(messages[i]['body'])),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                Expanded(child: TextField(controller: input, decoration: const InputDecoration(hintText: 'Escribe un mensaje'), onSubmitted: (_) => send())),
                IconButton(onPressed: send, icon: const Icon(Icons.send)),
              ]),
            ),
          ),
        ]),
      );
}
