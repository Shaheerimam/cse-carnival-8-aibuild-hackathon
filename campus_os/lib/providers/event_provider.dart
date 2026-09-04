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

  void add(Event event) {
    _dataService.events.add(event);
    notifyListeners();
  }

  void update(Event event) {
    final index = _dataService.events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _dataService.events[index] = event;
      notifyListeners();
    }
  }

  void delete(String id) {
    _dataService.events.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void register(String eventId, Registration registration) {
    final index = _dataService.events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      final event = _dataService.events[index];
      if (event.isFull) return;
      _dataService.events[index] = event.copyWith(
        registered: event.registered + 1,
        registrations: [...event.registrations, registration],
        status: event.registered + 1 >= event.capacity ? 'full' : event.status,
      );
      notifyListeners();
    }
  }

  void cancelRegistration(String eventId, String studentId) {
    final index = _dataService.events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      final event = _dataService.events[index];
      _dataService.events[index] = event.copyWith(
        registered: (event.registered - 1).clamp(0, event.capacity),
        registrations: event.registrations
            .where((r) => r.studentId != studentId)
            .toList(),
        status: event.status == 'full' ? 'upcoming' : event.status,
      );
      notifyListeners();
    }
  }

  String generateId() => _dataService.generateId('evt');
}
