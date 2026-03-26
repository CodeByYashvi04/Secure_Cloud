import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  
  final List<Message> _messages = [
    Message(
      id: '1',
      text: 'Hello! I am your AI Security Assistant. I monitor your cloud access and analyze threats. How can I help you today?',
      isAi: true,
    ),
    Message(
      id: '2',
      text: 'Why did I get an alert earlier?',
      isAi: false,
    ),
    Message(
      id: '3',
      text: 'Your login from Russia (45.33.22.1) was flagged because it is an unusual location for your account, and the device was not recognized. My risk engine scored this at 85 (Critical).',
      isAi: true,
    ),
  ];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _messages.add(Message(
        id: DateTime.now().toString(),
        text: _controller.text,
        isAi: false,
      ));
    });
    
    _controller.clear();
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add(Message(
            id: DateTime.now().toString(),
            text: "I am currently running in simulation mode. I would analyze the logs and give you insights based on Isolation Forest anomaly detection.",
            isAi: true,
          ));
        });
        _scrollToBottom();
      }
    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Security Assistant', style: TextStyle(color: Color(0xFF00F0FF))),
        backgroundColor: const Color(0xFF0F1522),
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: message.isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.isAi) ...[
            const Icon(LucideIcons.bot, color: Color(0xFF00F0FF), size: 24),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isAi ? const Color(0xFF1A233A) : const Color(0xFF4F6B92),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isAi ? 4 : 16),
                  bottomRight: Radius.circular(message.isAi ? 16 : 4),
                ),
              ),
              child: Text(
                message.text,
                style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
              ),
            ),
          ),
          if (!message.isAi) ...[
            const SizedBox(width: 8),
            const Icon(LucideIcons.user, color: Color(0xFFA0B2C6), size: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1522),
        border: Border(top: BorderSide(color: Color(0xFF1A233A))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ask about a threat or log...',
                  hintStyle: const TextStyle(color: Color(0xFF4F6B92)),
                  filled: true,
                  fillColor: const Color(0xFF0B0F19),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF1A233A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF1A233A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF00F0FF)),
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
