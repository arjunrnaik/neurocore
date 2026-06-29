import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/intent.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static const _promptTemplate = '''
You are an intent extraction engine for NeuroCore personal AI operating system. Given a user message and current timestamp, return ONLY a valid JSON object matching this exact schema:
{
  "domain": "health|finance|task|note|reminder|general",
  "action": "store|query|remind|summarize",
  "entities": {
    "key": "value"
  },
  "sentiment": "positive|neutral|negative",
  "confidence": 0.0-1.0
}
Rules:
1. If action is "remind" or domain is "reminder", try to include "message" and "due_at" (in ISO 8601 YYYY-MM-DDTHH:MM:SS format based on current time) in "entities".
2. No preamble. No explanation. Return JSON only.
''';

  Future<String?> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('gemini_api_key');
  }

  Future<ExtractedIntent> extractIntent(String userText) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      // Fallback local classification if API key not set
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
        final jsonMap = jsonDecode(response.text!) as Map<String, dynamic>;
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
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final contextLogs = entries.take(30).map((e) => "[${e.createdAt}] (${e.domain}) ${e.rawContent}").join("\n");
      final prompt = "You are NeuroCore personal AI. Answer the user's question accurately based ONLY on their stored logs:\n\nLOGS:\n$contextLogs\n\nQUESTION: $question";

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
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final contextLogs = entries.take(50).map((e) => "[${e.domain}] ${e.rawContent}").join("\n");
      final prompt = "Analyze the user's recent activity logs and synthesize an inspiring, motivating Weekly Review highlighting financial habits, health trends, and task completion:\n\n$contextLogs";

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? "No summary generated.";
    } catch (e) {
      return "Summary generation failed: $e";
    }
  }

  String _fallbackDomain(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('\$') || lower.contains('spent') || lower.contains('bought') || lower.contains('paid')) return 'finance';
    if (lower.contains('water') || lower.contains('gym') || lower.contains('ran') || lower.contains('sleep')) return 'health';
    if (lower.contains('remind') || lower.contains('tomorrow') || lower.contains('alarm')) return 'reminder';
    if (lower.contains('todo') || lower.contains('task') || lower.contains('finish')) return 'task';
    return 'note';
  }
}
