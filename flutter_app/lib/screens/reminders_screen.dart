import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/neurocore_app_bar.dart';
import '../widgets/category_chip.dart';

class ReminderItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String time;
  bool isDone;

  ReminderItem({
    required this.id,
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
  String _selectedCategory = 'All';

  final List<ReminderItem> _reminders = [
    ReminderItem(
      id: '1',
      title: 'Morning Hydration',
      description: 'Drink 500ml of warm water with lemon',
      category: 'Health',
      time: '08:00 AM',
    ),
    ReminderItem(
      id: '2',
      title: 'Deep Work Sprint',
      description: 'Review architecture roadmap and Q3 targets',
      category: 'Work',
      time: '10:30 AM',
    ),
    ReminderItem(
      id: '3',
      title: 'Evening Reflection & Meditation',
      description: 'Unwind with 10 mins breathing exercise',
      category: 'Personal',
      time: '09:00 PM',
    ),
  ];

  Color _getCategoryColor(String category, ThemeData theme) {
    switch (category.toLowerCase()) {
      case 'health':
        return theme.colorScheme.primary;
      case 'work':
        return theme.colorScheme.tertiary;
      default:
        return theme.colorScheme.secondary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return Icons.favorite_outline;
      case 'work':
        return Icons.work_outline;
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
      body: ListView(
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
          const SizedBox(height: 20),

          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Health', 'Work', 'Personal'].map((cat) {
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
          const SizedBox(height: 24),

          // NeuroTip Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.6),
            child: Row(
              children: [
                Icon(Icons.spa, size: 32, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Routine builds resilience',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Consistent small habits compound into profound life transformation.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Reminders list
          ...filtered.map((item) {
            final accentColor = _getCategoryColor(item.category, theme);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(item.category),
                                  size: 14,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.category.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: accentColor,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
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
                                  onPressed: () {
                                    setState(() => item.isDone = !item.isDone);
                                  },
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
    );
  }
}
