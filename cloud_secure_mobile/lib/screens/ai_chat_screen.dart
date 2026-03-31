import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';

class Message {
  final String id;
  final String text;
  final bool isAi;

  Message({required this.id, required this.text, required this.isAi});
}

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isAiThinking = false;
  
  final List<Message> _messages = [
    Message(
      id: '1',
      text: 'Hello! I am your AI Security Assistant. I monitor your cloud access and analyze threats. How can I help you today?',
      isAi: true,
    ),
  ];

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message(
        id: DateTime.now().toString(),
        text: text,
        isAi: false,
      ));
      _isAiThinking = true;
    });
    
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await ApiService.chatWithAI(text);
      if (mounted) {
        setState(() {
          _isAiThinking = false;
          _messages.add(Message(
            id: DateTime.now().toString(),
            text: response['reply'] ?? 'I encountered a temporal shift in my logic. Please try again.',
            isAi: true,
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAiThinking = false;
          _messages.add(Message(
            id: DateTime.now().toString(),
            text: 'Mission failure. Connection to the security matrix lost.',
            isAi: true,
          ));
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
    Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Security Assistant', style: TextStyle(color: isDark ? const Color(0xFF00F0FF) : const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? const Color(0xFF00F0FF) : const Color(0xFF1E293B)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isAiThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                } else {
                  return _buildMessageBubble(Message(
                    id: 'thinking',
                    text: 'CloudSecure Assistant is analyzing...',
                    isAi: true,
                  ));
                }
              },
            ),
          ),
          _buildInputArea(isDark, theme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAi = message.isAi;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAi) ...[
            Icon(LucideIcons.bot, color: isDark ? const Color(0xFF00F0FF) : Colors.cyan.shade700, size: 24),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isAi 
                    ? (isDark ? const Color(0xFF1A233A) : Colors.grey.shade100) 
                    : (isDark ? const Color(0xFF4F6B92) : const Color(0xFF00F0FF).withOpacity(0.1)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isAi ? 4 : 16),
                  bottomRight: Radius.circular(isAi ? 16 : 4),
                ),
                border: isDark ? null : Border.all(color: isAi ? Colors.grey.shade200 : const Color(0xFF00F0FF).withOpacity(0.2)),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isAi 
                      ? (isDark ? Colors.white : const Color(0xFF1E293B))
                      : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  fontSize: 15, 
                  height: 1.4
                ),
              ),
            ),
          ),
          if (!isAi) ...[
            const SizedBox(width: 8),
            Icon(LucideIcons.user, color: isDark ? const Color(0xFFA0B2C6) : Colors.grey.shade400, size: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1522) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF1A233A) : Colors.grey.shade100)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: 'Ask about a threat or log...',
                  hintStyle: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black38),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0B0F19) : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: isDark ? const BorderSide(color: Color(0xFF1A233A)) : BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: isDark ? const BorderSide(color: Color(0xFF1A233A)) : BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF00F0FF),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(LucideIcons.send, color: Color(0xFF0B0F19)),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
