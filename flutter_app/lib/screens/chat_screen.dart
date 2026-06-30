import 'package:flutter/material.dart';
import '../models/intent.dart';
import '../services/db_service.dart';
import '../services/gemini_service.dart';
import '../services/voice_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final GeminiService _gemini = GeminiService();
  final DatabaseService _db = DatabaseService();
  final VoiceService _voice = VoiceService();

  bool _isProcessing = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'sender': 'ai',
      'text': 'Hello! I am NeuroCore. Type or record any thought, expense, task, or reminder.',
    });
  }

  void _handleVoiceTap() async {
    if (_isListening) {
      await _voice.stopListening();
      setState(() => _isListening = false);
    } else {
      final avail = await _voice.initSpeech();
      if (avail) {
        setState(() => _isListening = true);
        await _voice.startListening((words) {
          setState(() {
            _controller.text = words;
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone access not available.')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_isListening) {
      await _voice.stopListening();
      setState(() => _isListening = false);
    }

    _controller.clear();
    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isProcessing = true;
    });

    // Check if it's a Q&A query
    if (text.startsWith('/ask ') || text.toLowerCase().startsWith('what') || text.toLowerCase().startsWith('how much') || text.toLowerCase().startsWith('did i')) {
      final entries = await _db.getEntries();
      final answer = await _gemini.askQuestion(text, entries);
      setState(() {
        _messages.add({'sender': 'ai', 'text': answer});
        _isProcessing = false;
      });
      return;
    }

    // Extract Intent
    final intent = await _gemini.extractIntent(text);
    final now = DateTime.now().toIso8601String();

    final entry = EntryItem(
      domain: intent.domain,
      action: intent.action,
      rawContent: text,
      extractedJson: intent.entities,
      createdAt: now,
    );

    final entryId = await _db.insertEntry(entry);

    String reply = "";

    // Handle reminder scheduling
    if (intent.domain == 'reminder' || intent.action == 'remind') {
      final msg = intent.entities['message']?.toString() ?? text;
      final dueAt = intent.entities['due_at']?.toString() ?? DateTime.now().add(const Duration(hours: 4)).toIso8601String();
      
      await _db.insertReminder(ReminderItem(
        entryId: entryId,
        message: msg,
        dueAt: dueAt,
        createdAt: now,
      ));
      reply = "⏰ Reminder scheduled: \"$msg\" for $dueAt.";
    } else {
      final entries = await _db.getEntries();
      reply = await _gemini.generateChatResponse(text, entries);
    }

    setState(() {
      _messages.add({'sender': 'ai', 'text': reply});
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('NeuroCore Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                      ),
                      border: isUser ? null : Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent)),
                  SizedBox(width: 12),
                  Text('Structuring & logging to SQLite...', style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFF1E293B)),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _handleVoiceTap,
                  child: CircleAvatar(
                    backgroundColor: _isListening ? Colors.redAccent : Colors.cyanAccent.withOpacity(0.2),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.white : Colors.cyanAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Type or speak a note...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF3B82F6)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
