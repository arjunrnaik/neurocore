import 'package:flutter/material.dart';
import '../models/intent.dart';
import '../services/db_service.dart';
import '../services/gemini_service.dart';
import '../services/voice_service.dart';
import '../widgets/neurocore_app_bar.dart';
import '../widgets/category_chip.dart';

class ChatMessage {
  final String sender; // 'ai' or 'user'
  final String text;
  final String? category;

  ChatMessage({required this.sender, required this.text, this.category});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final GeminiService _gemini = GeminiService();
  final DatabaseService _db = DatabaseService();
  final VoiceService _voice = VoiceService();

  bool _isProcessing = false;
  bool _isListening = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _messages.add(ChatMessage(
      sender: 'ai',
      text: 'Hello! I am NeuroCore. Tell me what you did, spent, or need to remember today.',
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    super.dispose();
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone access not available.')),
          );
        }
      }
    }
  }

  void _injectQuickChip(String prefix) {
    setState(() {
      _controller.text = "$prefix: ";
    });
  }

  IconData _getCategoryIcon(String? category) {
    if (category == null) return Icons.auto_awesome;
    switch (category.toLowerCase()) {
      case 'health':
      case 'fitness':
        return Icons.favorite;
      case 'finance':
      case 'expense':
        return Icons.account_balance_wallet;
      case 'task':
      case 'work':
        return Icons.check_circle;
      case 'reminder':
        return Icons.alarm;
      case 'learning':
      case 'study':
        return Icons.menu_book;
      case 'travel':
        return Icons.flight;
      default:
        return Icons.edit_note;
    }
  }

  Color _getCategoryColor(String? category, ThemeData theme) {
    if (category == null) return theme.colorScheme.primary;
    switch (category.toLowerCase()) {
      case 'health':
      case 'fitness':
        return theme.colorScheme.secondary;
      case 'finance':
      case 'expense':
        return theme.colorScheme.primary;
      case 'task':
      case 'work':
        return theme.colorScheme.tertiary;
      default:
        return theme.colorScheme.onSurfaceVariant;
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
      _messages.add(ChatMessage(sender: 'user', text: text));
      _isProcessing = true;
    });

    if (text.startsWith('/ask ') || text.toLowerCase().startsWith('what') || text.toLowerCase().startsWith('how much') || text.toLowerCase().startsWith('did i')) {
      final entries = await _db.getEntries();
      final answer = await _gemini.askQuestion(text, entries);
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(sender: 'ai', text: answer, category: 'Q&A'));
          _isProcessing = false;
        });
      }
      return;
    }

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

    if (intent.domain == 'reminder' || intent.action == 'remind') {
      final msg = intent.entities['message']?.toString() ?? text;
      final dueAt = intent.entities['due_at']?.toString() ?? DateTime.now().add(const Duration(hours: 4)).toIso8601String();
      await _db.insertReminder(ReminderItem(
        entryId: entryId,
        message: msg,
        dueAt: dueAt,
        createdAt: now,
      ));
      reply = "⏰ Scheduled reminder: \"$msg\" for $dueAt.";
    } else {
      final entries = await _db.getEntries();
      reply = await _gemini.generateChatResponse(text, entries);
    }

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(sender: 'ai', text: reply, category: intent.domain));
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const NeuroCoreAppBar(title: 'Assistant'),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.sender == 'user';
                final catColor = _getCategoryColor(msg.category, theme);

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUser ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                        bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser && msg.category != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getCategoryIcon(msg.category), size: 12, color: catColor),
                                const SizedBox(width: 4),
                                Text(
                                  msg.category!.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(color: catColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Text(
                          msg.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isUser ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary)),
                  const SizedBox(width: 10),
                  Text('Structuring intent to SQLite...', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          // Category Quick-Chips
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CategoryChip(label: 'Log Activity', icon: Icons.favorite_outline, isSelected: false, onTap: () => _injectQuickChip('Ran 5km')),
                  const SizedBox(width: 8),
                  CategoryChip(label: 'Expense', icon: Icons.account_balance_wallet_outlined, isSelected: false, onTap: () => _injectQuickChip('Spent \$25 on lunch')),
                  const SizedBox(width: 8),
                  CategoryChip(label: 'Journal', icon: Icons.edit_note, isSelected: false, onTap: () => _injectQuickChip('Feeling energized')),
                  const SizedBox(width: 8),
                  CategoryChip(label: 'Task', icon: Icons.check_circle_outline, isSelected: false, onTap: () => _injectQuickChip('Todo: finish presentation')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Input Bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 120, // extra padding for floating bottom nav
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: theme.textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Tell me something...',
                              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send, color: theme.colorScheme.primary, size: 20),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _handleVoiceTap,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isListening ? 1.0 + (_pulseController.value * 0.15) : 1.0,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: _isListening ? theme.colorScheme.error : theme.colorScheme.primary,
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? theme.colorScheme.onError : theme.colorScheme.onPrimary,
                            size: 22,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
