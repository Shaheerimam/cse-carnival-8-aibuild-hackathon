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

  Future<void> add(Announcement announcement) async {
    await _dataService.saveAnnouncement(announcement);
    notifyListeners();
  }

  Future<void> update(Announcement announcement) async {
    await _dataService.saveAnnouncement(announcement);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _dataService.deleteAnnouncement(id);
    notifyListeners();
  }

  String generateId() => _dataService.generateId('ann');
}
