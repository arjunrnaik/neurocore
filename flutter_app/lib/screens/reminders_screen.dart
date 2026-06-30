import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/neurocore_app_bar.dart';
import '../widgets/category_chip.dart';

class ReminderUIModel {
  final String id;
  final int? dbId;
  final String title;
  final String description;
  final String category;
  final String time;
  bool isDone;

  ReminderUIModel({
    required this.id,
    this.dbId,
    required this.title,
    required this.description,
    required this.category,
    required this.time,
    this.isDone = false,
  });
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final DatabaseService _db = DatabaseService();
  String _selectedCategory = 'All';
  List<ReminderUIModel> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final dbReminders = await _db.getReminders(status: 'pending');
    
    final List<ReminderUIModel> items = [
      ReminderUIModel(
        id: '1',
        title: 'Morning Hydration',
        description: 'Drink 500ml of warm water with lemon',
        category: 'Health',
        time: '08:00 AM',
      ),
      ReminderUIModel(
        id: '2',
        title: 'Deep Work Sprint',
        description: 'Review architecture roadmap and Q3 targets',
        category: 'Work',
        time: '10:30 AM',
      ),
      ReminderUIModel(
        id: '3',
        title: 'Evening Reflection & Meditation',
        description: 'Unwind with 10 mins breathing exercise',
        category: 'Personal',
        time: '09:00 PM',
      ),
    ];

    for (final r in dbReminders) {
      final timeStr = r.dueAt.replaceAll('T', ' ').length >= 16
          ? r.dueAt.replaceAll('T', ' ').substring(11, 16)
          : 'Soon';
      items.insert(0, ReminderUIModel(
        id: 'db_${r.id}',
        dbId: r.id,
        title: 'Scheduled Reminder',
        description: r.message,
        category: 'AI Task',
        time: timeStr,
      ));
    }

    if (mounted) {
      setState(() {
        _reminders = items;
        _loading = false;
      });
    }
  }

  Future<void> _toggleDone(ReminderUIModel item) async {
    setState(() => item.isDone = !item.isDone);
    if (item.dbId != null && item.isDone) {
      await _db.toggleReminderStatus(item.dbId!, 'completed');
    }
  }

  Color _getCategoryColor(String category, ThemeData theme) {
    switch (category.toLowerCase()) {
      case 'health':
        return theme.colorScheme.primary;
      case 'work':
        return theme.colorScheme.tertiary;
      case 'ai task':
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return Icons.favorite_outline;
      case 'work':
        return Icons.work_outline;
      case 'ai task':
        return Icons.auto_awesome;
      default:
        return Icons.self_improvement;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _selectedCategory == 'All'
        ? _reminders
        : _reminders.where((r) => r.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();

    return Scaffold(
      appBar: const NeuroCoreAppBar(title: 'Reminders'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReminders,
              child: ListView(
                padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 120),
                children: [
                  Text(
                    'Your Mindful Day',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gentle nudges to keep your rhythm aligned.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'AI Task', 'Health', 'Work', 'Personal'].map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CategoryChip(
                            label: cat,
                            isSelected: _selectedCategory == cat,
                            onTap: () => setState(() => _selectedCategory = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Reminders List
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No reminders in this category.',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ...filtered.map((item) {
                      final accentColor = _getCategoryColor(item.category, theme);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: item.isDone ? 0.6 : 1.0,
                          child: GlassCard(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_getCategoryIcon(item.category), color: accentColor, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: accentColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item.category.toUpperCase(),
                                              style: theme.textTheme.labelSmall?.copyWith(color: accentColor),
                                            ),
                                          ),
                                          Text(
                                            item.time,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item.title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          decoration: item.isDone ? TextDecoration.lineThrough : null,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Snoozed "${item.title}" for 1 hour')),
                                              );
                                            },
                                            child: Text(
                                              'Snooze',
                                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: item.isDone ? theme.colorScheme.surfaceContainerHigh : accentColor,
                                              foregroundColor: item.isDone ? theme.colorScheme.onSurface : const Color(0xFF111411),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            ),
                                            onPressed: () => _toggleDone(item),
                                            child: Text(item.isDone ? 'Completed' : 'Done'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
