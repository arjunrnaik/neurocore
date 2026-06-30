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

  Future<String?> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('gemini_api_key');
  }

  Future<ExtractedIntent> extractIntent(String userText) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return ExtractedIntent(
        domain: _fallbackDomain(userText),
        action: 'store',
        entities: {'text': userText},
        confidence: 0.7,
      );
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );

      final now = DateTime.now().toIso8601String();
      final prompt = '$_promptTemplate\nCurrent Time: $now\nUser Input: "$userText"';

      final response = await model.generateContent([Content.text(prompt)]);
      if (response.text != null) {
        String cleanText = response.text!.replaceAll(RegExp(r'```(?:json)?\s*'), '').replaceAll('```', '').trim();
        final jsonMap = jsonDecode(cleanText) as Map<String, dynamic>;
        return ExtractedIntent.fromJson(jsonMap);
      }
    } catch (e) {
      print('Gemini Extraction Error: $e');
    }

    return ExtractedIntent(
      domain: _fallbackDomain(userText),
      action: 'store',
      entities: {'text': userText},
      confidence: 0.5,
    );
  }

  Future<String> askQuestion(String question, List<EntryItem> entries) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return "Please enter your Google Gemini API Key in the Settings tab to use AI Q&A.";
    }

    try {
      final persona = await PersonaService.getSelectedPersona();
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final contextLogs = entries.take(30).map((e) => "[${e.createdAt}] (${e.domain}) ${e.rawContent}").join("\n");
      final prompt = "${persona.systemPromptPrefix}\n\nYou are NeuroCore personal AI. Answer the user's question accurately based ONLY on their stored logs:\n\nLOGS:\n$contextLogs\n\nQUESTION: $question";

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? "No answer generated.";
    } catch (e) {
      return "Error contacting AI: $e";
    }
  }

  Future<String> generateWeeklySummary(List<EntryItem> entries) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return "Please configure your Gemini API Key in Settings to generate weekly insights.";
    }

    try {
      final persona = await PersonaService.getSelectedPersona();
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final contextLogs = entries.take(50).map((e) => "[${e.domain}] ${e.rawContent}").join("\n");
      final prompt = "${persona.systemPromptPrefix}\n\nAnalyze the user's recent activity logs and synthesize an inspiring, motivating Weekly Review highlighting financial habits, health trends, and task completion:\n\n$contextLogs";

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? "No summary generated.";
    } catch (e) {
      return "Summary generation failed: $e";
    }
  }

  Future<String> generateChatResponse(String message, List<EntryItem> entries) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return "Hello! Please save your Gemini API Key in Settings to enable voice/chat response.";
    }

    try {
      final persona = await PersonaService.getSelectedPersona();
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final contextLogs = entries.take(15).map((e) => "(${e.domain}) ${e.rawContent}").join("\n");
      final prompt = "${persona.systemPromptPrefix}\n\nYou are NeuroCore, a friendly personal AI operating system. Respond briefly and conversationally (1-2 sentences max). Confirm you logged their input if relevant, or answer their greeting/message. Here are their recent logs for context:\n$contextLogs\n\nUser: $message";

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? "Logged.";
    } catch (e) {
      return "Logged your entry.";
    }
  }

  String _fallbackDomain(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('\$') || lower.contains('spent') || lower.contains('bought') || lower.contains('paid')) return 'finance';
    if (lower.contains('water') || lower.contains('gym') || lower.contains('ran') || lower.contains('sleep')) return 'health';
    if (lower.contains('remind') || lower.contains('tomorrow') || lower.contains('alarm')) return 'reminder';
    if (lower.contains('todo') || lower.contains('task') || lower.contains('finish')) return 'task';
    if (lower.contains('learn') || lower.contains('study') || lower.contains('read')) return 'learning';
    return 'note';
  }
}
