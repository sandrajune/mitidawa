import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'auth_screen.dart';

class Message {
  final String text;
  final bool isUser;

  Message(this.text, this.isUser);
}

class PlantAssistantScreen extends StatefulWidget {
  const PlantAssistantScreen({super.key});

  @override
  State<PlantAssistantScreen> createState() => _PlantAssistantScreenState();
}

class _PlantAssistantScreenState extends State<PlantAssistantScreen> {
  final Color _darkGreen = const Color.fromARGB(255, 18, 54, 45);
  final Color _brown = const Color.fromARGB(255, 91, 45, 23);
  final Color _lightGreen = const Color(0xFF558B6E);
  final Color _creamBackground = const Color(0xFFFAF8F5);

  final List<Message> _messages = [
    Message('Hello! Ask me anything about plants and remedies.', false),
  ];

  bool _isLoading = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChatHistory(); // Load history when the screen starts
  }

  Future<void> _loadChatHistory() async {
    try {
      // 1. Fetch data from Supabase, ordered by oldest first
      final data = await Supabase.instance.client
          .from('chat_history')
          .select()
          .order('created_at', ascending: true);

      // 2. Update the UI
      setState(() {
        if (data.isNotEmpty) {
          _messages.clear(); // Clear the default welcome message
          for (var row in data) {
            _messages.add(Message(row['text'], row['is_user']));
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    // 1. Update UI for User Message
    setState(() {
      _messages.add(Message(text, true));
      _controller.clear();
      _isLoading = true;
    });

    try {
      // 2. SAVE User Message to Supabase
      await Supabase.instance.client.from('chat_history').insert({
        'text': text,
        'is_user': true,
      });

      // 3. Ask Gemini via Edge Function
      final response = await Supabase.instance.client.functions.invoke(
        'chat-bot',
        body: {'prompt': text},
      );

      final dynamic data = response.data;
      String reply = 'Sorry, I could not generate a reply right now.';

      if (response.status >= 400) {
        final err = data is Map && data['error'] != null
            ? data['error'].toString()
            : 'Edge function call failed (${response.status}).';
        throw Exception(err);
      }

      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }

      if (data is Map && data['reply'] != null) {
        reply = data['reply'].toString();
      }

      // 4. Update UI for Bot Reply
      setState(() {
        _messages.add(Message(reply, false));
      });

      // 5. SAVE Bot Reply to Supabase
      await Supabase.instance.client.from('chat_history').insert({
        'text': reply,
        'is_user': false,
      });
    } catch (e) {
      final message = e.toString().toLowerCase();
      String friendlyError = 'Connection issue. Please try again in a moment.';

      if (message.contains('missing api key')) {
        friendlyError =
            'Chatbot backend is missing Gemini API key. Please contact support/admin.';
      } else if (message.contains('permission') || message.contains('rls')) {
        friendlyError =
            'Chat history permission denied. Please check Supabase RLS policies.';
      } else if (message.contains('failed to fetch') ||
          message.contains('network')) {
        friendlyError =
            'Network error while contacting chatbot service. Please retry.';
      } else if (message.contains('edge function call failed')) {
        friendlyError =
            'Chatbot service is currently unavailable. Please try again later.';
      }

      setState(() {
        _messages.add(Message(friendlyError, false));
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }

  Future<void> _clearChat() async {
    // 1. Show the loading spinner
    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Delete all rows from the Supabase table
      // (Supabase requires a filter to delete, so we tell it to delete where text is not null)
      await Supabase.instance.client
          .from('chat_history')
          .delete()
          .not('text', 'is', null);

      // 3. Reset the UI back to the default greeting
      setState(() {
        _messages.clear();
        _messages.add(Message(
            'Hello! Ask me anything about plants and remedies.', false));
      });
    } catch (e) {
      debugPrint('Error clearing chat: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _creamBackground,
      appBar: AppBar(
        title: const Text(
          'Plant Assistant',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 18, 54, 45),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        // ADD THIS ACTIONS BLOCK:
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Clear Chat',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_brown),
              ),
            ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask about a plant...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _lightGreen),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _darkGreen, width: 2.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: _lightGreen, size: 28),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment:
            msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0, right: 8.0, left: 40.0),
            child: Text(
              msg.isUser ? 'User' : 'Assistant',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          Row(
            mainAxisAlignment:
                msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!msg.isUser) ...[
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: msg.isUser ? _lightGreen : _darkGreen,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft:
                          msg.isUser ? const Radius.circular(16) : Radius.zero,
                      bottomRight:
                          msg.isUser ? Radius.zero : const Radius.circular(16),
                    ),
                  ),
                  child: MarkdownBody(
                    data: msg.text,
                    selectable: true, // Let users copy text!
                    styleSheet: MarkdownStyleSheet(
                      // We set the color to white to match your green backgrounds
                      p: const TextStyle(
                          color: Colors.white, fontSize: 15, height: 1.3),
                      listBullet:
                          const TextStyle(color: Colors.white, fontSize: 15),
                      strong: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      em: const TextStyle(
                          color: Colors.white, fontStyle: FontStyle.italic),
                      h1: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                      h2: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      h3: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
