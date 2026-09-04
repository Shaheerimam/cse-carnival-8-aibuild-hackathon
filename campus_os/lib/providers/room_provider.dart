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

  Future<void> add(Room room) async {
    await _dataService.saveRoom(room);
    notifyListeners();
  }

  Future<void> update(Room room) async {
    await _dataService.saveRoom(room);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _dataService.deleteRoom(id);
    notifyListeners();
  }

  Future<void> addBooking(String roomId, Booking booking) async {
    await _dataService.addBooking(roomId, booking);
    notifyListeners();
  }

  Future<void> cancelBooking(String roomId, String bookingId) async {
    await _dataService.cancelBooking(roomId, bookingId);
    notifyListeners();
  }

  String generateId() => _dataService.generateId('room');
  String generateBookingId() => _dataService.generateId('bk');
}
