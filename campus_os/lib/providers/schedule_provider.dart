import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../services/data_service.dart';

class ScheduleProvider extends ChangeNotifier {
  final DataService _dataService;
  ScheduleProvider(this._dataService);

  List<Schedule> get schedules => _dataService.schedules;

  List<Schedule> getByDay(String day) =>
      schedules.where((s) => s.day == day).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

  List<String> get days => ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'];

  void add(Schedule schedule) {
    _dataService.schedules.add(schedule);
    notifyListeners();
  }

  void update(Schedule schedule) {
    final index = _dataService.schedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      _dataService.schedules[index] = schedule;
      notifyListeners();
    }
  }

  void delete(String id) {
    _dataService.schedules.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  String generateId() => _dataService.generateId('sch');
}
