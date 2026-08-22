import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'content': 'Hello! I am your NirogX Clinical Assistant. I can help interpret your daily wellness trends, explain Health Score pillars, or discuss restorative habits based on your synchronized baseline.',
    }
  ];

  Future<void> _sendMessage(HealthProvider health) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isSending = true;
      _textController.clear();
    });

    _scrollToBottom();

    final contextDto = health.buildAIContext();

    try {
      final reply = await ApiService.sendChatMessage(_messages, contextDto.toJson());
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final scoreDisplay = health.healthScore != null && health.healthScore!.hasSufficientData
              ? '${health.healthScore!.score.toStringAsFixed(1)}/100'
              : 'Insufficient Data';
          _messages.add({
            'role': 'assistant',
            'content': 'Based on your synchronized wellness record (Current Score: $scoreDisplay), maintaining adequate hydration and consistent sleep schedules supports autonomic stability. Please consult a physician for medical advice.'
          });
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final health = Provider.of<HealthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Clinical Assistant',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Contextualized with daily aggregate trends',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF00897B) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.02),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: Text(
                      msg['content'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: isUser ? Colors.white : const Color(0xFF0F172A),
                        height: 1.45,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isSending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00897B)),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Ask about your score, sleep, or vitals...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      onSubmitted: (_) => _sendMessage(health),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : () => _sendMessage(health),
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF00897B)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
