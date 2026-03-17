import 'package:flutter/material.dart';

class LeafChatbotFab extends StatefulWidget {
  const LeafChatbotFab({super.key});

  @override
  State<LeafChatbotFab> createState() => _LeafChatbotFabState();
}

class _LeafChatbotFabState extends State<LeafChatbotFab> {
  bool _open = false;
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'bot',
      'text': 'Hi 🌿 Ask me anything about herbal remedies.',
    }
  ];

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _messages.add({
        'role': 'bot',
        'text':
            'Great question! Try starting with mild prep and hydration. Did you know? Neem leaves are traditionally used in many skin-support routines.',
      });
      _controller.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_open)
          Positioned(
            right: 0,
            bottom: 72,
            child: Container(
              width: 320,
              height: 380,
              decoration: BoxDecoration(
                color: const Color(0xCC2E7D32),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xAAA5D6A7), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Leaf AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isUser = msg['role'] == 'user';
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? const Color(0xFFFFB74D)
                                  : const Color(0xFF66BB6A),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              msg['text'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Ask about herbal use...',
                              hintStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: const Color(0x33000000),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _send,
                          icon: const Icon(Icons.send, color: Colors.white),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        FloatingActionButton(
          heroTag: 'leafChatFab',
          backgroundColor: const Color(0xFF2E7D32),
          onPressed: () => setState(() => _open = !_open),
          child: const Icon(Icons.spa, color: Colors.white),
        ),
      ],
    );
  }
}
