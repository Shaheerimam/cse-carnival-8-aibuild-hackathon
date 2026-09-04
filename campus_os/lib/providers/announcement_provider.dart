import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../services/data_service.dart';

class AnnouncementProvider extends ChangeNotifier {
  final DataService _dataService;
  AnnouncementProvider(this._dataService);

  List<Announcement> get announcements => _dataService.announcements;

  List<Announcement> get sorted => [...announcements]
    ..sort((a, b) => b.date.compareTo(a.date));

  List<Announcement> get highPriority =>
      announcements.where((a) => a.priority == 'high').toList();

  void add(Announcement announcement) {
    _dataService.announcements.add(announcement);
    notifyListeners();
  }

  void update(Announcement announcement) {
    final index = _dataService.announcements.indexWhere((a) => a.id == announcement.id);
    if (index != -1) {
      _dataService.announcements[index] = announcement;
      notifyListeners();
    }
  }

  void delete(String id) {
    _dataService.announcements.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  String generateId() => _dataService.generateId('ann');
}
