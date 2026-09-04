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

  Future<void> add(Assignment assignment) async {
    await _dataService.saveAssignment(assignment);
    notifyListeners();
  }

  Future<void> update(Assignment assignment) async {
    await _dataService.saveAssignment(assignment);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _dataService.deleteAssignment(id);
    notifyListeners();
  }

  String generateId() => _dataService.generateId('asgn');
}
