import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/neurocore_app_bar.dart';
import '../services/db_service.dart';
import '../services/gemini_service.dart';
import '../models/intent.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _aiSummary = 'Analyzing your weekly activity rhythms...';
  bool _isLoadingSummary = true;
  int _totalLogsThisWeek = 0;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final entries = await DatabaseService().getAllEntries();
    setState(() {
      _totalLogsThisWeek = entries.length;
    });

    final summary = await GeminiService().generateWeeklySummary(entries);
    if (mounted) {
      setState(() {
        _aiSummary = summary;
        _isLoadingSummary = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const NeuroCoreAppBar(title: 'Weekly Insights'),
      body: RefreshIndicator(
        onRefresh: _loadInsights,
        child: ListView(
          padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 120),
          children: [
            Text(
              'OCTOBER 21 – OCTOBER 27',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Weekly Insights',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // AI Summary Glass Card
            GlassCard(
              padding: const EdgeInsets.all(22),
              backgroundColor: theme.colorScheme.surfaceContainerHigh.withOpacity(0.9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'AI WEEKLY SYNTHESIS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isLoadingSummary
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Text(
                          '"$_aiSummary"',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                  const SizedBox(height: 16),
                  Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Logs Recorded',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '$_totalLogsThisWeek entries',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Movement / Consistency Ring Section
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Consistency & Movement',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: 0.85,
                          strokeWidth: 14,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '6/7',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            'Days Active',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bento Stats Grid (2 Columns)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bedtime_outlined, color: theme.colorScheme.tertiary),
                      const SizedBox(height: 8),
                      Text('Sleep Quality', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Text('88%', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text('+5% vs avg', style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
                    ],
                  ),
                ),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.psychology_outlined, color: theme.colorScheme.secondary),
                      const SizedBox(height: 8),
                      Text('Deep Work', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Text('18.5h', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text('Goal: 15h', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Weekly Spend Full-width Bento Card
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weekly Spend', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('\$420.00', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text('On track with budget', style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
