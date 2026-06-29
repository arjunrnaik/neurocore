import 'dart:convert';

class EntryItem {
  final int? id;
  final String domain; // "health", "finance", "task", "note", "reminder", "general"
  final String action; // "store", "query", "remind", "summarize"
  final String rawContent;
  final Map<String, dynamic> extractedJson;
  final String createdAt;
  final int synced; // 0 for false, 1 for true

  EntryItem({
    this.id,
    required this.domain,
    required this.action,
    required this.rawContent,
    required this.extractedJson,
    required this.createdAt,
    this.synced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'domain': domain,
      'action': action,
      'raw_content': rawContent,
      'extracted_json': jsonEncode(extractedJson),
      'created_at': createdAt,
      'synced': synced,
    };
  }

  factory EntryItem.fromMap(Map<String, dynamic> map) {
    return EntryItem(
      id: map['id'] as int?,
      domain: map['domain'] as String,
      action: map['action'] as String,
      rawContent: map['raw_content'] as String,
      extractedJson: jsonDecode(map['extracted_json'] as String) as Map<String, dynamic>,
      createdAt: map['created_at'] as String,
      synced: map['synced'] as int? ?? 0,
    );
  }
}

class ReminderItem {
  final int? id;
  final int? entryId;
  final String message;
  final String dueAt;
  final String status; // "pending", "completed", "snoozed"
  final String createdAt;

  ReminderItem({
    this.id,
    this.entryId,
    required this.message,
    required this.dueAt,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      'message': message,
      'due_at': dueAt,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory ReminderItem.fromMap(Map<String, dynamic> map) {
    return ReminderItem(
      id: map['id'] as int?,
      entryId: map['entry_id'] as int?,
      message: map['message'] as String,
      dueAt: map['due_at'] as String,
      status: map['status'] as String? ?? 'pending',
      createdAt: map['created_at'] as String,
    );
  }
}

class ExtractedIntent {
  final String domain;
  final String action;
  final Map<String, dynamic> entities;
  final String sentiment;
  final double confidence;

  ExtractedIntent({
    required this.domain,
    required this.action,
    required this.entities,
    this.sentiment = 'neutral',
    this.confidence = 1.0,
  });

  factory ExtractedIntent.fromJson(Map<String, dynamic> json) {
    return ExtractedIntent(
      domain: json['domain']?.toString().toLowerCase() ?? 'general',
      action: json['action']?.toString().toLowerCase() ?? 'store',
      entities: json['entities'] is Map<String, dynamic> ? json['entities'] : {},
      sentiment: json['sentiment']?.toString() ?? 'neutral',
      confidence: (json['confidence'] is num) ? (json['confidence'] as num).toDouble() : 1.0,
    );
  }
}
