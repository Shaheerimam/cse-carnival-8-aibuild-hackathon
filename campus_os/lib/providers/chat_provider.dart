import 'package:flutter/material.dart';

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

    // Simulate AI response delay — teammates will replace with real Gemini call
    await Future.delayed(const Duration(milliseconds: 1200));

    _messages.add(ChatMessage(
      text: _getMockResponse(text),
      isUser: false,
    ));
    _isTyping = false;
    notifyListeners();
  }

  String _getMockResponse(String query) {
    final q = query.toLowerCase();
    if (q.contains('class') || q.contains('schedule')) {
      return "📚 Let me check your schedule...\n\nYou have CSE 4113 (Pattern Recognition) today at 1:00 PM in Room 7A07 with Prof. Dr. Md. Shahriar Mahbub.\n\nWould you like to see your full schedule for today?";
    }
    if (q.contains('due') || q.contains('assignment') || q.contains('deadline')) {
      return "📝 Here are your upcoming deadlines:\n\n• CSE 4113 — Bayes Classifier Implementation\n  Due: Sep 9 (5 days left)\n\n• CSE 4130 — Lexical Analyzer using Flex\n  Due: Sep 10 (6 days left)\n\nWould you like more details on any of these?";
    }
    if (q.contains('book') || q.contains('room')) {
      return "🏫 I can help you book a room! To proceed, I'll need:\n\n1. Room number (or requirements like capacity/equipment)\n2. Date\n3. Time slot (start & end)\n4. Purpose\n\nWhich room are you interested in?";
    }
    if (q.contains('event') || q.contains('register')) {
      return "🎉 Here are upcoming events you can join:\n\n• AUST CSE Carnival 8.0 Planning Meeting — Sep 5\n• Soft Computing Mid-Term Review — Sep 6\n• Guest Lecture: Deep Learning — Sep 8\n\nWould you like to register for any of these?";
    }
    if (q.contains('announcement') || q.contains('notice')) {
      return "📢 Latest announcements:\n\n🔴 CSE 4113 Class Rescheduled — moved to Room 7A04 at 3:30 PM on Sunday\n🔴 Emergency: Water Supply Disruption — Building 7, Sep 6\n🟡 IPE 4111 Instructor Update — Mr. Md. Arif Hossain assigned\n\nAnything specific you'd like to know?";
    }
    return "I understand you're asking about \"$query\". Let me look into that for you.\n\n🔧 *AI agent integration in progress — this is a preview response.*\n\nOnce connected to the Gemini API, I'll be able to:\n• Query real-time campus data\n• Book rooms & register for events\n• Answer complex multi-source questions";
  }
}
