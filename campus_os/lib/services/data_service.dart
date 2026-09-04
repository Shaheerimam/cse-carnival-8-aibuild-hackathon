import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../models/schedule.dart';
import '../models/room.dart';
import '../models/event.dart';
import '../models/announcement.dart';
import '../models/assignment.dart';

class DataService {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Schedule> schedules = [];
  List<Room> rooms = [];
  List<Event> events = [];
  List<Announcement> announcements = [];
  List<Assignment> assignments = [];

  bool _loaded = false;

  /// Reload all collections from Firestore regardless of cache state.
  /// Call this before every AI response to ensure live data.
  Future<void> reloadData() async {
      schedules = await _loadCollection(
          collectionName: 'schedules',
          fromJson: Schedule.fromJson,
      );
      rooms = await _loadCollection(
          collectionName: 'rooms',
          fromJson: Room.fromJson,
      );
      events = await _loadCollection(
          collectionName: 'events',
          fromJson: Event.fromJson,
      );
      announcements = await _loadCollection(
          collectionName: 'announcements',
          fromJson: Announcement.fromJson,
      );
      assignments = await _loadCollection(
          collectionName: 'assignments',
          fromJson: Assignment.fromJson,
      );
  }

  Future<void> loadSeedData() async {
    if (_loaded) return;

        await Future.wait([
            _seedCollectionIfEmpty(
                collectionName: 'schedules',
                assetPath: 'assets/data/schedules.json',
                fromJson: Schedule.fromJson,
            ),
            _seedCollectionIfEmpty(
                collectionName: 'rooms',
                assetPath: 'assets/data/rooms.json',
                fromJson: Room.fromJson,
            ),
            _seedCollectionIfEmpty(
                collectionName: 'events',
                assetPath: 'assets/data/events.json',
                fromJson: Event.fromJson,
            ),
            _seedCollectionIfEmpty(
                collectionName: 'announcements',
                assetPath: 'assets/data/announcements.json',
                fromJson: Announcement.fromJson,
            ),
            _seedCollectionIfEmpty(
                collectionName: 'assignments',
                assetPath: 'assets/data/assignments.json',
                fromJson: Assignment.fromJson,
            ),
        ]);

        schedules = await _loadCollection(
            collectionName: 'schedules',
            fromJson: Schedule.fromJson,
        );

        rooms = await _loadCollection(
            collectionName: 'rooms',
            fromJson: Room.fromJson,
        );

        events = await _loadCollection(
            collectionName: 'events',
            fromJson: Event.fromJson,
        );

        announcements = await _loadCollection(
            collectionName: 'announcements',
            fromJson: Announcement.fromJson,
        );

        assignments = await _loadCollection(
            collectionName: 'assignments',
            fromJson: Assignment.fromJson,
        );

    _loaded = true;
  }

    Future<void> saveSchedule(Schedule schedule) =>
            _save('schedules', schedule.id, schedule.toJson(), schedules);

    Future<void> deleteSchedule(String id) =>
            _delete('schedules', id, schedules);

    Future<void> saveRoom(Room room) =>
            _save('rooms', room.id, room.toJson(), rooms);

    Future<void> deleteRoom(String id) => _delete('rooms', id, rooms);

    Future<void> saveEvent(Event event) =>
            _save('events', event.id, event.toJson(), events);

    Future<void> deleteEvent(String id) => _delete('events', id, events);

    Future<void> saveAnnouncement(Announcement announcement) =>
            _save('announcements', announcement.id, announcement.toJson(), announcements);

    Future<void> deleteAnnouncement(String id) =>
            _delete('announcements', id, announcements);

    Future<void> saveAssignment(Assignment assignment) =>
            _save('assignments', assignment.id, assignment.toJson(), assignments);

    Future<void> deleteAssignment(String id) =>
            _delete('assignments', id, assignments);

    Future<void> addBooking(String roomId, Booking booking) async {
        final room = rooms.firstWhere((room) => room.id == roomId);
        final updatedRoom = room.copyWith(
            bookings: [...room.bookings, booking],
        );
        await saveRoom(updatedRoom);
    }

    Future<void> cancelBooking(String roomId, String bookingId) async {
        final room = rooms.firstWhere((room) => room.id == roomId);
        final updatedRoom = room.copyWith(
            bookings: room.bookings.where((booking) => booking.bookingId != bookingId).toList(),
        );
        await saveRoom(updatedRoom);
    }

    Future<void> registerForEvent(String eventId, Registration registration) async {
        final event = events.firstWhere((event) => event.id == eventId);
        if (event.isFull) return;
        final updatedRegistered = event.registered + 1;
        final updatedEvent = event.copyWith(
            registered: updatedRegistered,
            registrations: [...event.registrations, registration],
            status: updatedRegistered >= event.capacity ? 'full' : event.status,
        );
        await saveEvent(updatedEvent);
    }

    Future<void> cancelEventRegistration(String eventId, String studentId) async {
        final event = events.firstWhere((event) => event.id == eventId);
        final remainingRegistrations = event.registrations
                .where((registration) => registration.studentId != studentId)
                .toList();
        final updatedEvent = event.copyWith(
            registered: (event.registered - 1).clamp(0, event.capacity),
            registrations: remainingRegistrations,
            status: event.status == 'full' ? 'upcoming' : event.status,
        );
        await saveEvent(updatedEvent);
    }

    Future<void> _seedCollectionIfEmpty<T>({
        required String collectionName,
        required String assetPath,
        required T Function(Map<String, dynamic>) fromJson,
    }) async {
        final collection = _firestore.collection(collectionName);
        final existing = await collection.limit(1).get();
        if (existing.docs.isNotEmpty) return;

        final rawJson = await rootBundle.loadString(assetPath);
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        final batch = _firestore.batch();

        for (final item in decoded) {
            final entity = fromJson(item as Map<String, dynamic>);
            final data = (entity as dynamic).toJson() as Map<String, dynamic>;
            batch.set(collection.doc(data['id'] as String), data);
        }

        await batch.commit();
    }

    Future<List<T>> _loadCollection<T>({
        required String collectionName,
        required T Function(Map<String, dynamic>) fromJson,
    }) async {
        final snapshot = await _firestore.collection(collectionName).get();
        return snapshot.docs
                .map((doc) => fromJson(doc.data()))
                .toList();
    }

    Future<void> _save<T>(
        String collectionName,
        String id,
        Map<String, dynamic> data,
        List<T> cache,
    ) async {
        await _firestore.collection(collectionName).doc(id).set(data);
        _replaceById(cache, data['id'] as String, data);
    }

    Future<void> _delete<T>(
        String collectionName,
        String id,
        List<T> cache,
    ) async {
        await _firestore.collection(collectionName).doc(id).delete();
        cache.removeWhere((item) => (item as dynamic).id == id);
    }

    void _replaceById<T>(List<T> cache, String id, Map<String, dynamic> data) {
        final index = cache.indexWhere((item) => (item as dynamic).id == id);
        if (index == -1) {
            cache.add(_entityFromJson<T>(data));
            return;
        }
        cache[index] = _entityFromJson<T>(data);
    }

    T _entityFromJson<T>(Map<String, dynamic> data) {
        if (T == Schedule) return Schedule.fromJson(data) as T;
        if (T == Room) return Room.fromJson(data) as T;
        if (T == Event) return Event.fromJson(data) as T;
        if (T == Announcement) return Announcement.fromJson(data) as T;
        if (T == Assignment) return Assignment.fromJson(data) as T;
        throw UnsupportedError('Unsupported entity type: $T');
    }

  String generateId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}';
}
