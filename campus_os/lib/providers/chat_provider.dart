import 'package:flutter/material.dart';

import '../services/campus_ai_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatProvider extends ChangeNotifier {
  final CampusAiService _aiService;

  ChatProvider(this._aiService);

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hi! I'm CampusOS 👋\n\nI can help you with your class schedule, room bookings, events, announcements, and assignments.\n\nTry asking me something like:\n• \"When is my next class?\"\n• \"Book Room 7A02 tomorrow 3-5 PM\"\n• \"What's due this week?\"",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  List<ChatMessage> get messages => _messages;
  bool _isTyping = false;
  bool get isTyping => _isTyping;

  Future<void> sendMessage(String text) async {
    _messages.add(ChatMessage(text: text, isUser: true));
    _isTyping = true;
    notifyListeners();

    try {
      final response = await _aiService.respond(text);
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
      ));
    } catch (error) {
      _messages.add(ChatMessage(
        text: 'I could not reach Firebase AI right now. Please try again in a moment.\n\n$error',
        isUser: false,
      ));
    }
    _isTyping = false;
    notifyListeners();
  }
}
