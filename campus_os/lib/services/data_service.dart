import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/schedule.dart';
import '../models/room.dart';
import '../models/event.dart';
import '../models/announcement.dart';
import '../models/assignment.dart';

class DataService {
  List<Schedule> schedules = [];
  List<Room> rooms = [];
  List<Event> events = [];
  List<Announcement> announcements = [];
  List<Assignment> assignments = [];

  bool _loaded = false;

  Future<void> loadSeedData() async {
    if (_loaded) return;

    final results = await Future.wait([
      rootBundle.loadString('assets/data/schedules.json'),
      rootBundle.loadString('assets/data/rooms.json'),
      rootBundle.loadString('assets/data/events.json'),
      rootBundle.loadString('assets/data/announcements.json'),
      rootBundle.loadString('assets/data/assignments.json'),
    ]);

    schedules = (jsonDecode(results[0]) as List)
        .map((e) => Schedule.fromJson(e as Map<String, dynamic>))
        .toList();

    rooms = (jsonDecode(results[1]) as List)
        .map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList();

    events = (jsonDecode(results[2]) as List)
        .map((e) => Event.fromJson(e as Map<String, dynamic>))
        .toList();

    announcements = (jsonDecode(results[3]) as List)
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();

    assignments = (jsonDecode(results[4]) as List)
        .map((e) => Assignment.fromJson(e as Map<String, dynamic>))
        .toList();

    _loaded = true;
  }

  String generateId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}';
}
