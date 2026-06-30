import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/neurocore_app_bar.dart';

class TaskItem {
  final String title;
  bool isDone;
  TaskItem(this.title, {this.isDone = false});
}

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onStartConversation;
  const DashboardScreen({super.key, this.onStartConversation});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService();
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  String _userName = 'Alex';

  final List<TaskItem> _tasks = [
    TaskItem('Morning meditation (10 min)', isDone: true),
    TaskItem('Review quarterly budget'),
    TaskItem('Hydration target 2.5L'),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'Alex';
    final stats = await _db.getStats();
    if (mounted) {
      setState(() {
        _userName = name;
        _stats = stats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: const NeuroCoreAppBar(title: 'NeuroCore'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final streaks = (_stats['streaks'] as Map<String, int>?) ?? {};
    final maxStreak = streaks.values.isEmpty ? 12 : (streaks.values.reduce((a, b) => a > b ? a : b));
    final displayStreak = maxStreak > 0 ? maxStreak : 12; // default placeholder

    return Scaffold(
      appBar: const NeuroCoreAppBar(title: 'NeuroCore'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 4,
        onPressed: widget.onStartConversation ?? () {},
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 130),
          children: [
            // Greeting Section
            Text(
              'Good morning, $_userName.',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Your mindful sanctuary is ready.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Start Conversation CTA Card
            GlassCard(
              padding: const EdgeInsets.all(20),
              backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.7),
              onTap: widget.onStartConversation,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chat_bubble, color: theme.colorScheme.onPrimary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Conversation',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Log activity, ask questions, or reflect.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: theme.colorScheme.onPrimaryContainer),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bento Grid Section
            Text(
              'TODAY\'S OVERVIEW',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // Streak Card (Full Width / 2-Col Span)
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_fire_department, color: theme.colorScheme.secondary, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            '$displayStreak Day Streak',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Active 🔥',
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(7, (index) {
                      final isActive = index < (displayStreak % 7 == 0 ? 7 : displayStreak % 7);
                      return Expanded(
                        child: Container(
                          height: 8,
                          margin: EdgeInsets.only(right: index < 6 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: isActive ? theme.colorScheme.secondary : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2-Column Bento Grid Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Health Snapshot Card
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.favorite_outline, color: theme.colorScheme.primary, size: 22),
                        const SizedBox(height: 12),
                        Text('Health Snapshot', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 8),
                        Text('6,432', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text('Steps today', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 12),
                        Text('7h 20m', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                        Text('Sleep (84%)', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Tasks Checklist Card
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.check_circle_outline, color: theme.colorScheme.tertiary, size: 22),
                            Text('${_tasks.where((t) => t.isDone).length}/${_tasks.length}', style: theme.textTheme.labelSmall),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Mindful Tasks', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 8),
                        ..._tasks.map((task) {
                          return GestureDetector(
                            onTap: () => setState(() => task.isDone = !task.isDone),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    task.isDone ? Icons.check_box : Icons.check_box_outline_blank,
                                    size: 16,
                                    color: task.isDone ? theme.colorScheme.tertiary : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                                        color: task.isDone ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Finance Summary & Focus Insight Row
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.secondary),
                        const SizedBox(height: 8),
                        Text('Daily Spend', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Text('\$42.50', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        Text('Budget: \$60', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(18),
                    backgroundColor: theme.colorScheme.tertiaryContainer.withOpacity(0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, color: theme.colorScheme.tertiary),
                        const SizedBox(height: 8),
                        Text('Focus Insight', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Deep work peaks at 10 AM.',
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
