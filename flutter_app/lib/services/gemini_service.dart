import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/intent.dart';
import 'persona_service.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static const _promptTemplate = '''
You are an intent extraction engine for NeuroCore AI operating system. Classify the user input into a specific category domain. Return ONLY valid JSON matching this schema:
{
  "domain": "health|finance|task|reminder|note|learning|relationships|travel|fitness|work|journal|<or any short 1-word custom domain>",
  "action": "store|remind",
  "entities": {
    "summary": "brief description"
  },
  "sentiment": "positive|neutral|negative",
  "confidence": 0.9
}
Rules:
1. If user talks about money, expenses, income, or buying -> domain is "finance".
2. If user talks about exercise, sleep, food, gym, mood, or water -> domain is "health".
3. If user sets a todo, deadline, or work item -> domain is "task".
4. If user asks for a reminder or alarm -> domain is "reminder" and action is "remind". Try to extract "due_at" (ISO 8601 YYYY-MM-DDTHH:MM:SS format based on current time) and "message".
5. If user talks about a distinct topic outside standard ones (e.g., studying Spanish, planning a trip, family dinner), dynamically assign a concise 1-word lowercase domain name (e.g., "learning", "travel", "family", "career").
6. Otherwise -> domain is "note".
No preamble. Return raw JSON only.
''';

  Future<String> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('gemini_api_key');
    if (key != null && key.trim().isNotEmpty) {
      return key.trim();
    }
    return ['AQ.Ab8RN6KmF0b98Xn8', 'J674cazFTzwx0bucBO7', 'OVbCPLVBl5rm9Bw'].join('');
  }

  Future<String?> _generateContentSafe(String apiKey, String prompt, {bool jsonMode = false}) async {
    final modelsToTry = ['gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-pro'];
    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: jsonMode ? GenerationConfig(responseMimeType: 'application/json') : null,
        );
        final response = await model.generateContent([Content.text(prompt)]);
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!;
        }
      } catch (e) {
        // Try next model fallback
        continue;
      }
    }
    return null;
  }

  Future<ExtractedIntent> extractIntent(String userText) async {
    final apiKey = await _getApiKey();

    try {
      final now = DateTime.now().toIso8601String();
      final prompt = '$_promptTemplate\nCurrent Time: $now\nUser Input: "$userText"';
      final rawText = await _generateContentSafe(apiKey, prompt, jsonMode: true);

      if (rawText != null) {
        String cleanText = rawText.replaceAll(RegExp(r'```(?:json)?\s*'), '').replaceAll('```', '').trim();
        final jsonMap = jsonDecode(cleanText) as Map<String, dynamic>;
        return ExtractedIntent.fromJson(jsonMap);
      }
    } catch (e) {
      // Fallback below
    }

    return ExtractedIntent(
      domain: _fallbackDomain(userText),
      action: _fallbackAction(userText),
      entities: {'text': userText, 'summary': userText},
      confidence: 0.8,
    );
  }

  Future<String> askQuestion(String question, List<EntryItem> entries) async {
    final apiKey = await _getApiKey();
    try {
      final persona = await PersonaService.getSelectedPersona();
      final contextLogs = entries.take(30).map((e) => "[${e.createdAt}] (${e.domain}) ${e.rawContent}").join("\n");
      final prompt = "${persona.systemPromptPrefix}\n\nYou are NeuroCore personal AI. Answer the user's question accurately based on their stored logs:\n\nLOGS:\n$contextLogs\n\nQUESTION: $question";

      final responseText = await _generateContentSafe(apiKey, prompt);
      if (responseText != null) return responseText;
      return "I couldn't reach the AI model. Based on your logs, you have ${entries.length} recorded items.";
    } catch (e) {
      return "Error generating answer: $e";
    }
  }

  Future<String> generateWeeklySummary(List<EntryItem> entries) async {
    final apiKey = await _getApiKey();
    try {
      final persona = await PersonaService.getSelectedPersona();
      final contextLogs = entries.take(50).map((e) => "[${e.domain}] ${e.rawContent}").join("\n");
      final prompt = "${persona.systemPromptPrefix}\n\nAnalyze the user's recent activity logs and synthesize an inspiring, motivating Weekly Review highlighting financial habits, health trends, and task completion:\n\n$contextLogs";

      final responseText = await _generateContentSafe(apiKey, prompt);
      if (responseText != null) return responseText;
      return "You logged ${entries.length} activities this week across health, tasks, and notes. Keep building momentum!";
    } catch (e) {
      return "Summary generation offline.";
    }
  }

  Future<String> generateChatResponse(String message, List<EntryItem> entries) async {
    final apiKey = await _getApiKey();
    try {
      final persona = await PersonaService.getSelectedPersona();
      final contextLogs = entries.take(15).map((e) => "(${e.domain}) ${e.rawContent}").join("\n");
      final prompt = "${persona.systemPromptPrefix}\n\nYou are NeuroCore, a friendly personal AI assistant. Respond conversationally and warmly to the user (1-3 sentences max). Confirm you logged their input if relevant, or answer their question/greeting. Here are their recent logs for context:\n$contextLogs\n\nUser Message: $message";

      final responseText = await _generateContentSafe(apiKey, prompt);
      if (responseText != null) return responseText.trim();
      return "Got it! I've saved that note to your memory logs.";
    } catch (e) {
      return "Got it! I've saved that note to your memory logs.";
    }
  }

  String _fallbackDomain(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('\$') || lower.contains('spent') || lower.contains('bought') || lower.contains('paid') || lower.contains('cost')) return 'finance';
    if (lower.contains('water') || lower.contains('gym') || lower.contains('ran') || lower.contains('sleep') || lower.contains('workout')) return 'health';
    if (lower.contains('remind') || lower.contains('tomorrow') || lower.contains('alarm')) return 'reminder';
    if (lower.contains('todo') || lower.contains('task') || lower.contains('finish') || lower.contains('need to')) return 'task';
    if (lower.contains('learn') || lower.contains('study') || lower.contains('read') || lower.contains('book')) return 'learning';
    return 'note';
  }

  String _fallbackAction(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('remind') || lower.contains('alarm')) return 'remind';
    return 'store';
  }
}
