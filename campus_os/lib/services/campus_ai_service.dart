import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/room.dart';
import 'data_service.dart';

class CampusAiService {
  CampusAiService(this._dataService) : _model = _buildModel();

  final DataService _dataService;
  final GenerativeModel _model;

  static GenerativeModel _buildModel() {
    final ai = FirebaseAI.googleAI();

    return ai.generativeModel(
      model: 'gemini-3.7-flash',
      tools: [
        Tool.functionDeclarations([
          FunctionDeclaration(
            'search_rooms',
            'Find rooms that match a request and show whether they are available for a time slot.',
            parameters: {
              'query': Schema.string(description: 'Natural language search text from the user.'),
              'roomNumber': Schema.string(description: 'Exact room number such as 7A02.'),
              'type': Schema.enumString(
                enumValues: ['classroom', 'lab', 'seminar'],
                description: 'Room type filter.',
              ),
              'minCapacity': Schema.integer(description: 'Minimum seating capacity.'),
              'equipment': Schema.array(
                items: Schema.string(),
                description: 'Equipment or amenity keywords to match.',
              ),
              'floor': Schema.integer(description: 'Floor number filter.'),
              'date': Schema.string(description: 'Date in YYYY-MM-DD format.'),
              'startTime': Schema.string(description: 'Start time in HH:mm format.'),
              'endTime': Schema.string(description: 'End time in HH:mm format.'),
            },
            optionalParameters: const [
              'query',
              'roomNumber',
              'type',
              'minCapacity',
              'equipment',
              'floor',
              'date',
              'startTime',
              'endTime',
            ],
          ),
          FunctionDeclaration(
            'book_room',
            'Book a room for a specific date and time if it is free.',
            parameters: {
              'roomNumber': Schema.string(description: 'Exact room number to book.'),
              'date': Schema.string(description: 'Booking date in YYYY-MM-DD format.'),
              'startTime': Schema.string(description: 'Booking start time in HH:mm format.'),
              'endTime': Schema.string(description: 'Booking end time in HH:mm format.'),
              'purpose': Schema.string(description: 'Reason for the booking.'),
              'bookedBy': Schema.string(description: 'Name of the person booking the room.'),
            },
            optionalParameters: const ['bookedBy'],
          ),
          FunctionDeclaration(
            'cancel_room_booking',
            'Cancel an existing room booking using the room number and booking details.',
            parameters: {
              'roomNumber': Schema.string(description: 'Exact room number with the booking.'),
              'date': Schema.string(description: 'Booking date in YYYY-MM-DD format.'),
              'startTime': Schema.string(description: 'Booking start time in HH:mm format.'),
              'bookedBy': Schema.string(description: 'Name of the person who booked the room.'),
            },
            optionalParameters: const ['date', 'startTime', 'bookedBy'],
          ),
        ]),
      ],
      toolConfig: ToolConfig(
        functionCallingConfig: FunctionCallingConfig.auto(),
      ),
      systemInstruction: Content.system(
        'You are CampusOS, a helpful campus assistant for AUST students. Use the available tools to answer questions about rooms and bookings. Ask a clarifying question when room number, date, time, or purpose is missing for a booking request. Never claim a room is booked unless the booking tool succeeds.',
      ),
    );
  }

  Future<String> respond(String userText) async {
    final chat = _model.startChat();
    GenerateContentResponse response = await chat.sendMessage(Content.text(userText));

    for (var turn = 0; turn < 5; turn++) {
      final functionCalls = response.functionCalls;
      if (functionCalls.isEmpty) {
        final text = response.text?.trim();
        return text?.isNotEmpty == true
            ? text!
            : 'I could not generate a response for that request.';
      }

      final functionResponses = <FunctionResponse>[];
      for (final call in functionCalls) {
        functionResponses.add(_handleFunctionCall(call));
      }

      response = await chat.sendMessage(
        Content.functionResponses(functionResponses),
      );
    }

    return response.text?.trim().isNotEmpty == true
        ? response.text!.trim()
        : 'I could not complete that request.';
  }

  FunctionResponse _handleFunctionCall(FunctionCall call) {
    switch (call.name) {
      case 'search_rooms':
        return FunctionResponse(call.name, _searchRooms(call.args), id: call.id);
      case 'book_room':
        return FunctionResponse(call.name, _bookRoom(call.args), id: call.id);
      case 'cancel_room_booking':
        return FunctionResponse(call.name, _cancelBooking(call.args), id: call.id);
      default:
        return FunctionResponse(
          call.name,
          {'success': false, 'message': 'Unsupported function: ${call.name}'},
          id: call.id,
        );
    }
  }

  Map<String, Object?> _searchRooms(Map<String, Object?> args) {
    final query = _stringArg(args, 'query')?.toLowerCase();
    final roomNumber = _stringArg(args, 'roomNumber')?.toLowerCase();
    final type = _stringArg(args, 'type')?.toLowerCase();
    final minCapacity = _intArg(args, 'minCapacity');
    final equipment = _stringListArg(args, 'equipment');
    final floor = _intArg(args, 'floor');
    final date = _stringArg(args, 'date');
    final startTime = _stringArg(args, 'startTime');
    final endTime = _stringArg(args, 'endTime');

    final rooms = _dataService.rooms.where((room) {
      if (roomNumber != null && !room.roomNumber.toLowerCase().contains(roomNumber)) {
        return false;
      }
      if (type != null && room.type.toLowerCase() != type) {
        return false;
      }
      if (minCapacity != null && room.capacity < minCapacity) {
        return false;
      }
      if (floor != null && room.floor != floor) {
        return false;
      }
      if (equipment.isNotEmpty && !equipment.every((item) =>
          room.equipment.any((roomEquipment) => roomEquipment.toLowerCase().contains(item)))) {
        return false;
      }
      if (query != null && query.isNotEmpty) {
        final haystack = [
          room.roomNumber,
          room.type,
          room.capacity.toString(),
          room.floor.toString(),
          ...room.equipment,
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) {
          return false;
        }
      }
      if (date != null && startTime != null && endTime != null) {
        return _isRoomFree(room, date, startTime, endTime);
      }
      return true;
    }).toList();

    return {
      'success': true,
      'count': rooms.length,
      'rooms': rooms.map(_roomToMap).toList(),
    };
  }

  Map<String, Object?> _bookRoom(Map<String, Object?> args) {
    final roomNumber = _stringArg(args, 'roomNumber');
    final date = _stringArg(args, 'date');
    final startTime = _stringArg(args, 'startTime');
    final endTime = _stringArg(args, 'endTime');
    final purpose = _stringArg(args, 'purpose');
    final bookedBy = _stringArg(args, 'bookedBy') ?? 'CampusOS User';

    if (roomNumber == null || date == null || startTime == null || endTime == null || purpose == null) {
      return {
        'success': false,
        'message': 'Missing booking details. Room number, date, start time, end time, and purpose are required.',
      };
    }

    final room = _findRoom(roomNumber);
    if (room == null) {
      return {'success': false, 'message': 'Room $roomNumber was not found.'};
    }

    if (!_isRoomFree(room, date, startTime, endTime)) {
      return {
        'success': false,
        'message': 'Room $roomNumber is already booked for that time slot.',
      };
    }

    final booking = Booking(
      bookingId: _dataService.generateId('bk'),
      bookedBy: bookedBy,
      date: date,
      startTime: startTime,
      endTime: endTime,
      purpose: purpose,
    );

    final updatedRoom = room.copyWith(
      bookings: [...room.bookings, booking],
    );

    _dataService.saveRoom(updatedRoom);

    return {
      'success': true,
      'message': 'Room $roomNumber has been booked successfully.',
      'room': _roomToMap(updatedRoom),
      'booking': booking.toJson(),
    };
  }

  Map<String, Object?> _cancelBooking(Map<String, Object?> args) {
    final roomNumber = _stringArg(args, 'roomNumber');
    final date = _stringArg(args, 'date');
    final startTime = _stringArg(args, 'startTime');
    final bookedBy = _stringArg(args, 'bookedBy');

    if (roomNumber == null) {
      return {'success': false, 'message': 'Room number is required to cancel a booking.'};
    }

    final room = _findRoom(roomNumber);
    if (room == null) {
      return {'success': false, 'message': 'Room $roomNumber was not found.'};
    }

    final matchingBookingIndex = room.bookings.indexWhere((booking) {
      if (date != null && booking.date != date) return false;
      if (startTime != null && booking.startTime != startTime) return false;
      if (bookedBy != null && booking.bookedBy.toLowerCase() != bookedBy.toLowerCase()) return false;
      return true;
    });

    if (matchingBookingIndex == -1) {
      return {
        'success': false,
        'message': 'No matching booking was found for room $roomNumber.',
      };
    }

    final removedBooking = room.bookings[matchingBookingIndex];
    final updatedRoom = room.copyWith(
      bookings: [
        ...room.bookings..removeAt(matchingBookingIndex),
      ],
    );

    _dataService.saveRoom(updatedRoom);

    return {
      'success': true,
      'message': 'Booking ${removedBooking.bookingId} for room $roomNumber was cancelled.',
      'room': _roomToMap(updatedRoom),
      'cancelledBooking': removedBooking.toJson(),
    };
  }

  Room? _findRoom(String roomNumber) {
    return _dataService.rooms.cast<Room?>().firstWhere(
          (room) => room != null && room.roomNumber.toLowerCase() == roomNumber.toLowerCase(),
          orElse: () => null,
        );
  }

  bool _isRoomFree(Room room, String date, String startTime, String endTime) {
    final requestedStart = _parseTime(startTime);
    final requestedEnd = _parseTime(endTime);
    if (requestedStart == null || requestedEnd == null) return true;

    for (final booking in room.bookings) {
      if (booking.date != date) continue;
      final bookingStart = _parseTime(booking.startTime);
      final bookingEnd = _parseTime(booking.endTime);
      if (bookingStart == null || bookingEnd == null) continue;
        final overlaps = requestedStart.compareTo(bookingEnd) < 0 &&
          requestedEnd.compareTo(bookingStart) > 0;
      if (overlaps) return false;
    }
    return true;
  }

  DateTime? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) return null;
    return DateTime(2000, 1, 1, hours, minutes);
  }

  Map<String, Object?> _roomToMap(Room room) => {
        'id': room.id,
        'roomNumber': room.roomNumber,
        'type': room.type,
        'capacity': room.capacity,
        'equipment': room.equipment,
        'floor': room.floor,
        'status': room.status,
        'bookings': room.bookings.map((booking) => booking.toJson()).toList(),
      };

  String? _stringArg(Map<String, Object?> args, String key) {
    final value = args[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  int? _intArg(Map<String, Object?> args, String key) {
    final value = args[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  List<String> _stringListArg(Map<String, Object?> args, String key) {
    final value = args[key];
    if (value is List) {
      return value.whereType<String>().map((item) => item.trim().toLowerCase()).where((item) => item.isNotEmpty).toList();
    }
    return const [];
  }
}