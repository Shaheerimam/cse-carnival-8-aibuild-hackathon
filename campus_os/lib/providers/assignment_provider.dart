import 'package:flutter/material.dart';
import '../models/assignment.dart';
import '../services/data_service.dart';

class AssignmentProvider extends ChangeNotifier {
  final DataService _dataService;
  AssignmentProvider(this._dataService);

  List<Assignment> get assignments => _dataService.assignments;

  List<Assignment> getByStatus(String? status) => status == null
      ? assignments
      : assignments.where((a) => a.status == status).toList();

  List<Assignment> get dueThisWeek {
    final now = DateTime.now();
    final weekEnd = now.add(const Duration(days: 7));
    return assignments.where((a) {
      final dl = DateTime.tryParse(a.deadline);
      return dl != null &&
          dl.isAfter(now.subtract(const Duration(days: 1))) &&
          dl.isBefore(weekEnd) &&
          a.status == 'pending';
    }).toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  void add(Assignment assignment) {
    _dataService.assignments.add(assignment);
    notifyListeners();
  }

  void update(Assignment assignment) {
    final index = _dataService.assignments.indexWhere((a) => a.id == assignment.id);
    if (index != -1) {
      _dataService.assignments[index] = assignment;
      notifyListeners();
    }
  }

  void delete(String id) {
    _dataService.assignments.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  String generateId() => _dataService.generateId('asgn');
}
