import 'package:shared_preferences/shared_preferences.dart';

class PersonaMode {
  final String id;
  final String name;
  final String description;
  final String systemPromptPrefix;

  const PersonaMode({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPromptPrefix,
  });
}

class PersonaService {
  static const String _personaKey = 'selected_core_persona';

  static const List<PersonaMode> personas = [
    PersonaMode(
      id: 'zen',
      name: 'Zen Master',
      description: 'Calm, mindful, encouraging, slow-living philosophy.',
      systemPromptPrefix: 'You are a calm, mindful, and gentle AI assistant. Use encouraging, thoughtful language focused on well-being and balance. Keep your tone reflective and supportive.',
    ),
    PersonaMode(
      id: 'hype',
      name: 'Hype Coach',
      description: 'High-energy, motivational, action-oriented.',
      systemPromptPrefix: 'You are an enthusiastic, high-energy motivational coach! Use punchy, inspiring language with emojis. Celebrate wins and push the user to take action and achieve their goals!',
    ),
    PersonaMode(
      id: 'analyst',
      name: 'Analyst',
      description: 'Data-driven, precise, factual, analytical.',
      systemPromptPrefix: 'You are a precise, analytical data assistant. Focus on exact figures, patterns, percentages, and actionable insights without unnecessary fluff.',
    ),
    PersonaMode(
      id: 'bestie',
      name: 'Bestie',
      description: 'Casual, warm, friendly, emoji-friendly.',
      systemPromptPrefix: 'You are the user\'s warm, empathetic best friend. Talk in a natural, casual, conversational tone. Use empathetic phrases and friendly emojis.',
    ),
    PersonaMode(
      id: 'minimalist',
      name: 'Minimalist',
      description: 'Ultra-brief, concise, zero fluff.',
      systemPromptPrefix: 'You are an ultra-concise assistant. Respond with maximum brevity. Use bullet points or short confirmations where possible. Do not include introductory or concluding filler.',
    ),
  ];

  static Future<String> getSelectedPersonaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_personaKey) ?? 'zen';
  }

  static Future<PersonaMode> getSelectedPersona() async {
    final id = await getSelectedPersonaId();
    return personas.firstWhere((p) => p.id == id, orElse: () => personas.first);
  }

  static Future<void> setSelectedPersona(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personaKey, id);
  }
}
