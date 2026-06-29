import 'package:flutter/material.dart';
import '../models/intent.dart';
import '../services/db_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _db = DatabaseService();
  List<EntryItem> _entries = [];
  String _selectedDomain = 'all';
  bool _loading = true;

  final List<String> _domains = ['all', 'health', 'finance', 'task', 'reminder', 'note'];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    final entries = await _db.getEntries(domain: _selectedDomain == 'all' ? null : _selectedDomain);
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _deleteEntry(int id) async {
    await _db.deleteEntry(id);
    _loadEntries();
  }

  Color _getBadgeColor(String domain) {
    switch (domain) {
      case 'finance': return Colors.greenAccent;
      case 'health': return Colors.pinkAccent;
      case 'task': return Colors.purpleAccent;
      case 'reminder': return Colors.amberAccent;
      default: return Colors.cyanAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Knowledge Logs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _domains.length,
              itemBuilder: (context, index) {
                final d = _domains[index];
                final isSelected = d == _selectedDomain;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDomain = d);
                    _loadEntries();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? Colors.white : Colors.white12),
                    ),
                    child: Center(
                      child: Text(
                        d.toUpperCase(),
                        style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? const Center(child: Text('No logs found.', style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final item = _entries[index];
                          final color = _getBadgeColor(item.domain);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                  child: Text(item.domain.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.rawContent, style: const TextStyle(color: Colors.white, fontSize: 15)),
                                      const SizedBox(height: 6),
                                      Text(item.createdAt.replaceAll('T', ' ').substring(0, 16), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
                                  onPressed: () => _deleteEntry(item.id!),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
