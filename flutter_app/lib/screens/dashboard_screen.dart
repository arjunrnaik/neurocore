import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../services/gemini_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService();
  final GeminiService _gemini = GeminiService();
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  String _summaryText = '';
  bool _generatingSummary = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _db.getStats();
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  Future<void> _generateSummary() async {
    setState(() => _generatingSummary = true);
    final entries = await _db.getEntries();
    final summary = await _gemini.generateWeeklySummary(entries);
    setState(() {
      _summaryText = summary;
      _generatingSummary = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final streaks = (_stats['streaks'] as Map<String, int>?) ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('NeuroCore OS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingCard(),
              const SizedBox(height: 20),
              const Text('SYSTEM OVERVIEW', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Total Logs', '${_stats['total_entries'] ?? 0}', Icons.storage, Colors.blueAccent)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Active Reminders', '${_stats['pending_reminders'] ?? 0}', Icons.alarm, Colors.amberAccent)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('HABIT STREAKS', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              _buildStreakRow('Health & Fitness', streaks['health'] ?? 0, Icons.favorite, Colors.pinkAccent),
              const SizedBox(height: 8),
              _buildStreakRow('Finance & Spending', streaks['finance'] ?? 0, Icons.attach_money, Colors.greenAccent),
              const SizedBox(height: 8),
              _buildStreakRow('Task Execution', streaks['task'] ?? 0, Icons.check_circle_outline, Colors.purpleAccent),
              const SizedBox(height: 24),
              _buildSummarySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal AI Operating System', style: TextStyle(color: Colors.white70, fontSize: 14)),
          SizedBox(height: 6),
          Text('Everything logged.\nAlways structured.', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStreakRow(String title, int days, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('$days Day Streak 🔥', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AI Weekly Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                onPressed: _generatingSummary ? null : _generateSummary,
                icon: _generatingSummary ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_generatingSummary ? 'Synthesizing...' : 'Generate'),
              ),
            ],
          ),
          if (_summaryText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_summaryText, style: const TextStyle(color: Colors.white70, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
