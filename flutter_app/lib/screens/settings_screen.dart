import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_service.dart';
import '../services/persona_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/neurocore_app_bar.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _selectedPersonaId = 'zen';
  bool _mindfulReminders = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final personaId = await PersonaService.getSelectedPersonaId();
    setState(() {
      _apiKeyController.text = prefs.getString('gemini_api_key') ?? '';
      _nameController.text = prefs.getString('user_name') ?? 'Alex';
      _selectedPersonaId = personaId;
      _mindfulReminders = prefs.getBool('mindful_reminders') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _apiKeyController.text.trim());
    await prefs.setString('user_name', _nameController.text.trim());
    await PersonaService.setSelectedPersona(_selectedPersonaId);
    await prefs.setBool('mindful_reminders', _mindfulReminders);

    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  Future<void> _showPersonaPicker() async {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select AI Core Persona',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Chooses how NeuroCore communicates and guides you.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ...PersonaService.personas.map((p) {
                final isSelected = p.id == _selectedPersonaId;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      isSelected ? Icons.check : Icons.auto_awesome,
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ),
                  title: Text(p.name, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                  subtitle: Text(p.description, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                  onTap: () {
                    setState(() => _selectedPersonaId = p.id);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _backupData() async {
    final jsonStr = await DatabaseService().exportAllDataJson();
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        title: const Text('✅ Backup Copied!'),
        content: const Text(
          'All your SQLite entries and reminders have been exported as raw JSON and copied to your clipboard.\n\nYou can now paste it into notes or email to keep it safe!',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _confirmClearData() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        title: const Text('⚠️ Permanently Delete Data?'),
        content: const Text(
          'Are you sure you want to erase all stored entries, reminders, and streak counters from your device? This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              await DatabaseService().clearAllData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🗑️ All local SQLite data erased.')),
              );
            },
            child: Text('Delete All', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = NeuroCoreApp.of(context);
    final isDark = appState?.isDarkMode ?? true;

    final currentPersona = PersonaService.personas.firstWhere(
      (p) => p.id == _selectedPersonaId,
      orElse: () => PersonaService.personas.first,
    );

    return Scaffold(
      appBar: const NeuroCoreAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 120),
        children: [
          // Profile Section
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'A',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(
                          hintText: 'Your Name',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Personal AI OS User',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: AI Personality
          _buildSectionHeader('AI PERSONALITY', theme),
          GlassCard(
            padding: const EdgeInsets.all(16),
            onTap: _showPersonaPicker,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.psychology, color: theme.colorScheme.onPrimaryContainer, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Core Persona', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      Text(currentPersona.name, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Gemini API Key
          _buildSectionHeader('AI CONFIGURATION', theme),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Google Gemini API Key', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Stored strictly on device. Needed for intelligent conversational Q&A.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'AIzaSy...',
                      hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Appearance & Notifications
          _buildSectionHeader('PREFERENCES', theme),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Dark Mode', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text('Frosted obsidian aesthetics', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  value: isDark,
                  onChanged: (val) {
                    appState?.toggleTheme(val);
                  },
                ),
                Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Mindful Reminders', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text('Gentle daily nudges', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  value: _mindfulReminders,
                  onChanged: (val) => setState(() => _mindfulReminders = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save Configuration Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _saved ? Colors.green : theme.colorScheme.primary,
                foregroundColor: _saved ? Colors.white : const Color(0xFF111411),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
              onPressed: _saveSettings,
              child: Text(
                _saved ? '✅ Settings Saved!' : 'Save Changes',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Section 4: Data Management & Backup
          _buildSectionHeader('DATA & PRIVACY VAULT', theme),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local-First SQLite Storage',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Export your logs before uninstalling or clear everything anytime.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: theme.colorScheme.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _backupData,
                        icon: Icon(Icons.copy, size: 18, color: theme.colorScheme.primary),
                        label: Text('Backup JSON', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: theme.colorScheme.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _confirmClearData,
                        icon: Icon(Icons.delete_forever, size: 18, color: theme.colorScheme.error),
                        label: Text('Erase All', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.secondary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
