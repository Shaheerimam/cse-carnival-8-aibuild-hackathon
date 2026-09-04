import 'package:flutter/material.dart';
import '../models/room.dart';
import '../services/data_service.dart';

class RoomProvider extends ChangeNotifier {
  final DataService _dataService;
  RoomProvider(this._dataService);

  List<Room> get rooms => _dataService.rooms;

  List<Room> getByType(String? type) => type == null
      ? rooms
      : rooms.where((r) => r.type == type).toList();

  List<Room> search(String query) {
    final q = query.toLowerCase();
    return rooms.where((r) =>
      r.roomNumber.toLowerCase().contains(q) ||
      r.type.toLowerCase().contains(q) ||
      r.equipment.any((e) => e.toLowerCase().contains(q))
    ).toList();
  }

  void add(Room room) {
    _dataService.rooms.add(room);
    notifyListeners();
  }

  void update(Room room) {
    final index = _dataService.rooms.indexWhere((r) => r.id == room.id);
    if (index != -1) {
      _dataService.rooms[index] = room;
      notifyListeners();
    }
  }

  void delete(String id) {
    _dataService.rooms.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void addBooking(String roomId, Booking booking) {
    final index = _dataService.rooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      final room = _dataService.rooms[index];
      _dataService.rooms[index] = room.copyWith(
        bookings: [...room.bookings, booking],
      );
      notifyListeners();
    }
  }

  void cancelBooking(String roomId, String bookingId) {
    final index = _dataService.rooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      final room = _dataService.rooms[index];
      _dataService.rooms[index] = room.copyWith(
        bookings: room.bookings.where((b) => b.bookingId != bookingId).toList(),
      );
      notifyListeners();
    }
  }

  String generateId() => _dataService.generateId('room');
  String generateBookingId() => _dataService.generateId('bk');
}
