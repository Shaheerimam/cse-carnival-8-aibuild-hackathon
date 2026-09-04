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

  Future<void> add(Schedule schedule) async {
    await _dataService.saveSchedule(schedule);
    notifyListeners();
  }

  Future<void> update(Schedule schedule) async {
    await _dataService.saveSchedule(schedule);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _dataService.deleteSchedule(id);
    notifyListeners();
  }

  String generateId() => _dataService.generateId('sch');
}
