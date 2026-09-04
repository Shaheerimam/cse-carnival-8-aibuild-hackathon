import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/data_service.dart';

class EventProvider extends ChangeNotifier {
  final DataService _dataService;
  EventProvider(this._dataService);

  List<Event> get events => _dataService.events;

  List<Event> get upcomingEvents =>
      events.where((e) => e.status == 'upcoming').toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  Future<void> add(Event event) async {
    await _dataService.saveEvent(event);
    notifyListeners();
  }

  Future<void> update(Event event) async {
    await _dataService.saveEvent(event);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _dataService.deleteEvent(id);
    notifyListeners();
  }

  Future<void> register(String eventId, Registration registration) async {
    await _dataService.registerForEvent(eventId, registration);
    notifyListeners();
  }

  Future<void> cancelRegistration(String eventId, String studentId) async {
    await _dataService.cancelEventRegistration(eventId, studentId);
    notifyListeners();
  }

  String generateId() => _dataService.generateId('evt');
}
