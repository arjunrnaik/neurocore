import 'package:flutter/material.dart';
import '../models/intent.dart';
import '../services/db_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/neurocore_app_bar.dart';
import '../widgets/category_chip.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<EntryItem> _allEntries = [];
  List<String> _domains = ['All'];
  String _selectedDomain = 'All';
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    final entries = await _db.getEntries();
    
    final uniqueDomains = entries.map((e) => e.domain.toLowerCase()).toSet();
    final domainList = ['All', ...uniqueDomains.map((d) => d[0].toUpperCase() + d.substring(1))];

    if (mounted) {
      setState(() {
        _allEntries = entries;
        _domains = domainList;
        _loading = false;
      });
    }
  }

  Future<void> _deleteEntry(int id) async {
    await _db.deleteEntry(id);
    _loadEntries();
  }

  Color _getCategoryColor(String domain, ThemeData theme) {
    switch (domain.toLowerCase()) {
      case 'finance': return theme.colorScheme.primary;
      case 'health': return theme.colorScheme.secondary;
      case 'task': return theme.colorScheme.tertiary;
      case 'reminder': return Colors.amberAccent;
      default: return theme.colorScheme.onSurfaceVariant;
    }
  }

  IconData _getCategoryIcon(String domain) {
    switch (domain.toLowerCase()) {
      case 'finance': return Icons.account_balance_wallet;
      case 'health': return Icons.favorite;
      case 'task': return Icons.check_circle;
      case 'reminder': return Icons.alarm;
      case 'learning': return Icons.menu_book;
      case 'travel': return Icons.flight;
      default: return Icons.edit_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filtered = _allEntries.where((item) {
      final matchesDomain = _selectedDomain == 'All' || item.domain.toLowerCase() == _selectedDomain.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty || item.rawContent.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDomain && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: const NeuroCoreAppBar(title: 'Timeline Logs'),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search stored memories & logs...',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                ],
              ),
            ),
          ),

          // Dynamic Category Filter Chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _domains.length,
              itemBuilder: (context, index) {
                final d = _domains[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryChip(
                    label: d,
                    isSelected: d == _selectedDomain,
                    onTap: () => setState(() => _selectedDomain = d),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Timeline List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No logs found in this category.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEntries,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 130),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final catColor = _getCategoryColor(item.domain, theme);
                            final timeStr = item.createdAt.replaceAll('T', ' ').length >= 16
                                ? item.createdAt.replaceAll('T', ' ').substring(0, 16)
                                : item.createdAt;

                            return Stack(
                              children: [
                                // Vertical timeline line
                                if (index < filtered.length - 1)
                                  Positioned(
                                    left: 18,
                                    top: 38,
                                    bottom: 0,
                                    child: Container(
                                      width: 2,
                                      color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: catColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(_getCategoryIcon(item.domain), color: catColor, size: 18),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: GlassCard(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          item.domain.toUpperCase(),
                                                          style: theme.textTheme.labelSmall?.copyWith(
                                                            color: catColor,
                                                            letterSpacing: 1.0,
                                                          ),
                                                        ),
                                                        Text(
                                                          timeStr,
                                                          style: theme.textTheme.labelSmall?.copyWith(
                                                            color: theme.colorScheme.onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      item.rawContent,
                                                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () => _deleteEntry(item.id!),
                                                child: Icon(
                                                  Icons.delete_outline,
                                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                                                  size: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
