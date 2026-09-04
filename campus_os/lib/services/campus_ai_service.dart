import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/event.dart';
import '../models/room.dart';
import 'data_service.dart';

class CampusAiService {
  CampusAiService(this._dataService) : _model = _buildModel();

  final DataService _dataService;
  final GenerativeModel _model;

  static GenerativeModel _buildModel() {
    final ai = FirebaseAI.googleAI();

    return ai.generativeModel(
      model: 'gemini-3.1-flash-lite',
      tools: [
        Tool.functionDeclarations([
          // ── Schedule ──────────────────────────────────────────────────────
          FunctionDeclaration(
            'get_schedule',
            'Return the class timetable. '
                'Filter by day of the week, course code, or time window. '
                'Pass no arguments to get the entire schedule. '
                'Always call this tool when the user asks about classes, lectures, or their timetable.',
            parameters: {
              'day': Schema.string(
                  description:
                      'Day of the week (Sunday, Monday, Tuesday, Wednesday, Thursday).'),
              'course': Schema.string(
                  description:
                      'Course code or title keyword to filter by (e.g. "CSE 4113" or "Soft Computing").'),
              'afterTime': Schema.string(
                  description:
                      'Only return classes starting at or after this time (HH:mm, 24-hour).'),
              'beforeTime': Schema.string(
                  description:
                      'Only return classes starting before this time (HH:mm, 24-hour).'),
            },
            optionalParameters: const ['day', 'course', 'afterTime', 'beforeTime'],
          ),

          // ── Assignments ───────────────────────────────────────────────────
          FunctionDeclaration(
            'get_assignments',
            'Return the list of assignments. '
                'Filter by status (pending / submitted / overdue) or by a deadline window. '
                'Always call this tool when the user asks about assignments, homework, tasks, or deadlines.',
            parameters: {
              'status': Schema.enumString(
                enumValues: ['pending', 'submitted', 'overdue'],
                description: 'Assignment status filter.',
              ),
              'dueBefore': Schema.string(
                  description: 'Return assignments due before this date (YYYY-MM-DD).'),
              'dueAfter': Schema.string(
                  description: 'Return assignments due after this date (YYYY-MM-DD).'),
              'course': Schema.string(
                  description: 'Course code or title keyword filter.'),
            },
            optionalParameters: const ['status', 'dueBefore', 'dueAfter', 'course'],
          ),

          // ── Announcements ─────────────────────────────────────────────────
          FunctionDeclaration(
            'get_announcements',
            'Return announcements from the notice board. '
                'Filter by priority (high / medium / low) or include only active (non-expired) ones. '
                'Always call this tool when the user asks about announcements, notices, or updates.',
            parameters: {
              'priority': Schema.enumString(
                enumValues: ['high', 'medium', 'low'],
                description: 'Announcement priority filter.',
              ),
              'activeOnly': Schema.boolean(
                  description:
                      'If true, exclude expired announcements. Defaults to true.'),
            },
            optionalParameters: const ['priority', 'activeOnly'],
          ),

          // ── Events ────────────────────────────────────────────────────────
          FunctionDeclaration(
            'get_events',
            'Return campus events. '
                'Filter by date, status (upcoming / full / ongoing), or time window. '
                'Always call this when the user asks what is happening on campus, what they can attend, or about specific events.',
            parameters: {
              'date': Schema.string(description: 'Event date (YYYY-MM-DD).'),
              'status': Schema.enumString(
                enumValues: ['upcoming', 'full', 'ongoing'],
                description: 'Event status filter.',
              ),
              'beforeTime': Schema.string(
                  description:
                      'Only include events that start before this time (HH:mm). '
                      'Useful for "I am free until 2 PM" type queries.'),
              'afterTime': Schema.string(
                  description:
                      'Only include events that start at or after this time (HH:mm).'),
              'nameKeyword': Schema.string(
                  description: 'Keyword to match against event name or description.'),
            },
            optionalParameters: const [
              'date',
              'status',
              'beforeTime',
              'afterTime',
              'nameKeyword'
            ],
          ),

          // ── Register for event ────────────────────────────────────────────
          FunctionDeclaration(
            'register_for_event',
            'Register a student for a campus event if there are still open spots. '
                'Ask for the student name and ID if not provided.',
            parameters: {
              'eventId': Schema.string(
                  description: 'The unique id of the event (e.g. "evt-002").'),
              'eventName': Schema.string(
                  description:
                      'The name of the event (used to look up the event if id is unknown).'),
              'studentId': Schema.string(
                  description: 'The student\'s university ID (e.g. "20-40532").'),
              'studentName': Schema.string(
                  description: 'The full name of the student being registered.'),
            },
            optionalParameters: const ['eventId', 'eventName'],
          ),

          // ── Rooms ─────────────────────────────────────────────────────────
          FunctionDeclaration(
            'search_rooms',
            'Find rooms that match a request and show whether they are available for a time slot.',
            parameters: {
              'query': Schema.string(
                  description: 'Natural language search text from the user.'),
              'roomNumber': Schema.string(
                  description: 'Exact room number such as 7A02.'),
              'type': Schema.enumString(
                enumValues: ['classroom', 'lab', 'seminar'],
                description: 'Room type filter.',
              ),
              'minCapacity':
                  Schema.integer(description: 'Minimum seating capacity.'),
              'equipment': Schema.array(
                items: Schema.string(),
                description: 'Equipment or amenity keywords to match.',
              ),
              'floor': Schema.integer(description: 'Floor number filter.'),
              'date': Schema.string(description: 'Date in YYYY-MM-DD format.'),
              'startTime':
                  Schema.string(description: 'Start time in HH:mm format.'),
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

          // ── Book room ─────────────────────────────────────────────────────
          FunctionDeclaration(
            'book_room',
            'Book a room for a specific date and time if it is free.',
            parameters: {
              'roomNumber': Schema.string(
                  description: 'Exact room number to book.'),
              'date': Schema.string(
                  description: 'Booking date in YYYY-MM-DD format.'),
              'startTime': Schema.string(
                  description: 'Booking start time in HH:mm format.'),
              'endTime': Schema.string(
                  description: 'Booking end time in HH:mm format.'),
              'purpose':
                  Schema.string(description: 'Reason for the booking.'),
              'bookedBy': Schema.string(
                  description: 'Name of the person booking the room.'),
            },
            optionalParameters: const ['bookedBy'],
          ),

          // ── Cancel booking ────────────────────────────────────────────────
          FunctionDeclaration(
            'cancel_room_booking',
            'Cancel an existing room booking using the room number and booking details.',
            parameters: {
              'roomNumber': Schema.string(
                  description: 'Exact room number with the booking.'),
              'date': Schema.string(
                  description: 'Booking date in YYYY-MM-DD format.'),
              'startTime': Schema.string(
                  description: 'Booking start time in HH:mm format.'),
              'bookedBy': Schema.string(
                  description: 'Name of the person who booked the room.'),
            },
            optionalParameters: const ['date', 'startTime', 'bookedBy'],
          ),
        ]),
      ],
      toolConfig: ToolConfig(
        functionCallingConfig: FunctionCallingConfig.auto(),
      ),
      systemInstruction: Content.system(
        '''You are CampusOS, a helpful AI assistant for AUST (Ahsanullah University of Science and Technology) students.
Today's date and time is provided in each message. Always use it to reason about "today", "tomorrow", "this week", and "next class".
The campus week runs Sunday – Thursday.

Guidelines:
• Always call the appropriate tool(s) before giving an answer that depends on live data.
• For schedule queries: "next class" means the next class after the current time today, or the first class of the next working day.
• For "this week": use the current date to infer the week boundaries (Sunday to Thursday).
• For room bookings: ask for any missing details (date, time, purpose) before booking.
• For event registration: ask for student name and ID if not provided.
• Never claim an action succeeded unless the tool returns success: true.
• Format responses in a clear, friendly way using bullet points or numbered lists where helpful.
• When listing multiple items, group them logically (e.g., by day for schedules).''',
      ),
    );
  }

  /// Builds a context string with the current date/time to inject into every message.
  String _buildContextPrefix() {
    final now = DateTime.now();
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    // DateTime.weekday: Monday=1 … Sunday=7
    final dayName = days[now.weekday - 1];
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return '[Context: Today is $dayName, $dateStr. Current time is $timeStr (24-hour). Campus week: Sunday–Thursday.]\n\n';
  }

  Future<String> respond(String userText) async {
    // Always reload live data from Firestore before answering
    await _dataService.reloadData();

    final chat = _model.startChat();
    final fullMessage = _buildContextPrefix() + userText;
    GenerateContentResponse response =
        await chat.sendMessage(Content.text(fullMessage));

    for (var turn = 0; turn < 8; turn++) {
      final functionCalls = response.functionCalls;
      if (functionCalls.isEmpty) {
        final text = response.text?.trim();
        return text?.isNotEmpty == true
            ? text!
            : 'I could not generate a response for that request.';
      }

      final functionResponses = <FunctionResponse>[];
      for (final call in functionCalls) {
        functionResponses.add(await _handleFunctionCall(call));
      }

      response = await chat.sendMessage(
        Content.functionResponses(functionResponses),
      );
    }

    return response.text?.trim().isNotEmpty == true
        ? response.text!.trim()
        : 'I could not complete that request.';
  }

  Future<FunctionResponse> _handleFunctionCall(FunctionCall call) async {
    switch (call.name) {
      case 'get_schedule':
        return FunctionResponse(call.name, _getSchedule(call.args), id: call.id);
      case 'get_assignments':
        return FunctionResponse(call.name, _getAssignments(call.args), id: call.id);
      case 'get_announcements':
        return FunctionResponse(call.name, _getAnnouncements(call.args), id: call.id);
      case 'get_events':
        return FunctionResponse(call.name, _getEvents(call.args), id: call.id);
      case 'register_for_event':
        return FunctionResponse(
            call.name, await _registerForEvent(call.args), id: call.id);
      case 'search_rooms':
        return FunctionResponse(call.name, _searchRooms(call.args), id: call.id);
      case 'book_room':
        return FunctionResponse(call.name, await _bookRoom(call.args), id: call.id);
      case 'cancel_room_booking':
        return FunctionResponse(
            call.name, await _cancelBooking(call.args), id: call.id);
      default:
        return FunctionResponse(
          call.name,
          {'success': false, 'message': 'Unsupported function: ${call.name}'},
          id: call.id,
        );
    }
  }

  // ── Schedule handler ────────────────────────────────────────────────────────

  Map<String, Object?> _getSchedule(Map<String, Object?> args) {
    final day = _stringArg(args, 'day');
    final course = _stringArg(args, 'course')?.toLowerCase();
    final afterTime = _stringArg(args, 'afterTime');
    final beforeTime = _stringArg(args, 'beforeTime');

    final schedules = _dataService.schedules.where((s) {
      if (day != null && s.day.toLowerCase() != day.toLowerCase()) return false;
      if (course != null &&
          !s.course.toLowerCase().contains(course) &&
          !s.title.toLowerCase().contains(course)) return false;
      if (afterTime != null) {
        final start = _parseTime(s.startTime);
        final after = _parseTime(afterTime);
        if (start != null && after != null && start.isBefore(after)) return false;
      }
      if (beforeTime != null) {
        final start = _parseTime(s.startTime);
        final before = _parseTime(beforeTime);
        if (start != null && before != null && !start.isBefore(before)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final dayOrder = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'];
        final dayDiff = dayOrder.indexOf(a.day) - dayOrder.indexOf(b.day);
        if (dayDiff != 0) return dayDiff;
        return (a.startTime).compareTo(b.startTime);
      });

    return {
      'success': true,
      'count': schedules.length,
      'schedules': schedules
          .map((s) => {
                'id': s.id,
                'course': s.course,
                'title': s.title,
                'day': s.day,
                'start_time': s.startTime,
                'end_time': s.endTime,
                'room': s.room,
                'instructor': s.instructor,
                'section': s.section,
              })
          .toList(),
    };
  }

  // ── Assignment handler ──────────────────────────────────────────────────────

  Map<String, Object?> _getAssignments(Map<String, Object?> args) {
    final statusFilter = _stringArg(args, 'status');
    final dueBefore = _stringArg(args, 'dueBefore');
    final dueAfter = _stringArg(args, 'dueAfter');
    final course = _stringArg(args, 'course')?.toLowerCase();

    final assignments = _dataService.assignments.where((a) {
      if (course != null &&
          !a.course.toLowerCase().contains(course) &&
          !a.courseTitle.toLowerCase().contains(course)) return false;

      final effectiveStatus = a.isOverdue ? 'overdue' : a.status;
      if (statusFilter != null && effectiveStatus != statusFilter) return false;

      if (dueBefore != null) {
        final dl = DateTime.tryParse(a.deadline);
        final before = DateTime.tryParse(dueBefore);
        if (dl != null && before != null && dl.isAfter(before)) return false;
      }
      if (dueAfter != null) {
        final dl = DateTime.tryParse(a.deadline);
        final after = DateTime.tryParse(dueAfter);
        if (dl != null && after != null && dl.isBefore(after)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));

    return {
      'success': true,
      'count': assignments.length,
      'assignments': assignments
          .map((a) => {
                'id': a.id,
                'course': a.course,
                'course_title': a.courseTitle,
                'title': a.title,
                'description': a.description,
                'assigned_date': a.assignedDate,
                'deadline': a.deadline,
                'submission_platform': a.submissionPlatform,
                'status': a.isOverdue ? 'overdue' : a.status,
                'marks': a.marks,
                'days_until_due': a.daysUntilDue,
              })
          .toList(),
    };
  }

  // ── Announcement handler ────────────────────────────────────────────────────

  Map<String, Object?> _getAnnouncements(Map<String, Object?> args) {
    final priorityFilter = _stringArg(args, 'priority');
    final activeOnly = args['activeOnly'] is bool ? args['activeOnly'] as bool : true;

    final announcements = _dataService.announcements.where((a) {
      if (activeOnly && a.isExpired) return false;
      if (priorityFilter != null && a.priority.toLowerCase() != priorityFilter) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        const order = {'high': 0, 'medium': 1, 'low': 2};
        return (order[a.priority] ?? 3).compareTo(order[b.priority] ?? 3);
      });

    return {
      'success': true,
      'count': announcements.length,
      'announcements': announcements
          .map((a) => {
                'id': a.id,
                'title': a.title,
                'body': a.body,
                'date': a.date,
                'priority': a.priority,
                'posted_by': a.postedBy,
                'expires': a.expires,
                'is_expired': a.isExpired,
              })
          .toList(),
    };
  }

  // ── Event handler ───────────────────────────────────────────────────────────

  Map<String, Object?> _getEvents(Map<String, Object?> args) {
    final dateFilter = _stringArg(args, 'date');
    final statusFilter = _stringArg(args, 'status');
    final beforeTime = _stringArg(args, 'beforeTime');
    final afterTime = _stringArg(args, 'afterTime');
    final nameKeyword = _stringArg(args, 'nameKeyword')?.toLowerCase();

    final events = _dataService.events.where((e) {
      if (dateFilter != null && e.date != dateFilter) return false;
      if (statusFilter != null && e.status.toLowerCase() != statusFilter) return false;
      if (beforeTime != null) {
        final start = _parseTime(e.startTime);
        final before = _parseTime(beforeTime);
        if (start != null && before != null && !start.isBefore(before)) return false;
      }
      if (afterTime != null) {
        final start = _parseTime(e.startTime);
        final after = _parseTime(afterTime);
        if (start != null && after != null && start.isBefore(after)) return false;
      }
      if (nameKeyword != null &&
          !e.name.toLowerCase().contains(nameKeyword) &&
          !e.description.toLowerCase().contains(nameKeyword)) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        final dc = a.date.compareTo(b.date);
        if (dc != 0) return dc;
        return a.startTime.compareTo(b.startTime);
      });

    return {
      'success': true,
      'count': events.length,
      'events': events
          .map((e) => {
                'id': e.id,
                'name': e.name,
                'description': e.description,
                'date': e.date,
                'start_time': e.startTime,
                'end_time': e.endTime,
                'venue': e.venue,
                'organizer': e.organizer,
                'capacity': e.capacity,
                'registered': e.registered,
                'spots_remaining': e.capacity - e.registered,
                'status': e.status,
                'is_full': e.isFull,
              })
          .toList(),
    };
  }

  // ── Register for event handler ──────────────────────────────────────────────

  Future<Map<String, Object?>> _registerForEvent(
      Map<String, Object?> args) async {
    final eventId = _stringArg(args, 'eventId');
    final eventName = _stringArg(args, 'eventName')?.toLowerCase();
    final studentId = _stringArg(args, 'studentId');
    final studentName = _stringArg(args, 'studentName');

    if (studentId == null || studentName == null) {
      return {
        'success': false,
        'message': 'Student ID and name are required to register for an event.',
      };
    }

    // Find the event by id or by name keyword
    final event = _dataService.events.cast<dynamic>().firstWhere(
      (e) {
        if (eventId != null && e.id == eventId) return true;
        if (eventName != null && e.name.toLowerCase().contains(eventName)) {
          return true;
        }
        return false;
      },
      orElse: () => null,
    ) as dynamic;

    if (event == null) {
      return {
        'success': false,
        'message': 'Event not found. Please check the event name or ID.',
      };
    }

    if (event.isFull) {
      return {
        'success': false,
        'message':
            'Sorry, "${event.name}" is already full (${event.registered}/${event.capacity} registered).',
      };
    }

    // Check if already registered
    final alreadyRegistered = (event.registrations as List).any(
      (r) => (r as dynamic).studentId == studentId,
    );
    if (alreadyRegistered) {
      return {
        'success': false,
        'message': 'Student $studentId is already registered for "${event.name}".',
      };
    }

    final registration = Registration(studentId: studentId, name: studentName);
    await _dataService.registerForEvent(event.id as String, registration);

    return {
      'success': true,
      'message':
          'Successfully registered $studentName for "${event.name}" on ${event.date} at ${event.startTime}.',
      'event_id': event.id,
      'event_name': event.name,
      'venue': event.venue,
      'date': event.date,
      'start_time': event.startTime,
    };
  }

  // ── Room handlers ───────────────────────────────────────────────────────────

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
      if (roomNumber != null &&
          !room.roomNumber.toLowerCase().contains(roomNumber)) return false;
      if (type != null && room.type.toLowerCase() != type) return false;
      if (minCapacity != null && room.capacity < minCapacity) return false;
      if (floor != null && room.floor != floor) return false;
      if (equipment.isNotEmpty &&
          !equipment.every((item) => room.equipment
              .any((re) => re.toLowerCase().contains(item)))) return false;
      if (query != null && query.isNotEmpty) {
        final haystack = [
          room.roomNumber,
          room.type,
          room.capacity.toString(),
          room.floor.toString(),
          ...room.equipment,
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      return true;
    }).toList();

    return {
      'success': true,
      'count': rooms.length,
      'rooms': rooms.map((room) {
        final map = _roomToMap(room);
        if (date != null && startTime != null && endTime != null) {
          map['available_for_requested_slot'] =
              _isRoomFree(room, date, startTime, endTime);
        }
        return map;
      }).toList(),
    };
  }

  Future<Map<String, Object?>> _bookRoom(Map<String, Object?> args) async {
    final roomNumber = _stringArg(args, 'roomNumber');
    final date = _stringArg(args, 'date');
    final startTime = _stringArg(args, 'startTime');
    final endTime = _stringArg(args, 'endTime');
    final purpose = _stringArg(args, 'purpose');
    final bookedBy = _stringArg(args, 'bookedBy') ?? 'CampusOS User';

    if (roomNumber == null ||
        date == null ||
        startTime == null ||
        endTime == null ||
        purpose == null) {
      return {
        'success': false,
        'message':
            'Missing booking details. Room number, date, start time, end time, and purpose are required.',
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

    await _dataService.saveRoom(updatedRoom);

    return {
      'success': true,
      'message': 'Room $roomNumber has been booked successfully.',
      'room': _roomToMap(updatedRoom),
      'booking': booking.toJson(),
    };
  }

  Future<Map<String, Object?>> _cancelBooking(
      Map<String, Object?> args) async {
    final roomNumber = _stringArg(args, 'roomNumber');
    final date = _stringArg(args, 'date');
    final startTime = _stringArg(args, 'startTime');
    final bookedBy = _stringArg(args, 'bookedBy');

    if (roomNumber == null) {
      return {
        'success': false,
        'message': 'Room number is required to cancel a booking.',
      };
    }

    final room = _findRoom(roomNumber);
    if (room == null) {
      return {'success': false, 'message': 'Room $roomNumber was not found.'};
    }

    final matchingBookingIndex = room.bookings.indexWhere((booking) {
      if (date != null && booking.date != date) return false;
      if (startTime != null && booking.startTime != startTime) return false;
      if (bookedBy != null &&
          booking.bookedBy.toLowerCase() != bookedBy.toLowerCase()) return false;
      return true;
    });

    if (matchingBookingIndex == -1) {
      return {
        'success': false,
        'message': 'No matching booking was found for room $roomNumber.',
      };
    }

    final removedBooking = room.bookings[matchingBookingIndex];
    final newBookings = List<Booking>.from(room.bookings)
      ..removeAt(matchingBookingIndex);
    final updatedRoom = room.copyWith(bookings: newBookings);

    await _dataService.saveRoom(updatedRoom);

    return {
      'success': true,
      'message':
          'Booking ${removedBooking.bookingId} for room $roomNumber was cancelled.',
      'room': _roomToMap(updatedRoom),
      'cancelledBooking': removedBooking.toJson(),
    };
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Room? _findRoom(String roomNumber) {
    return _dataService.rooms.cast<Room?>().firstWhere(
          (room) =>
              room != null &&
              room.roomNumber.toLowerCase() == roomNumber.toLowerCase(),
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
      return value
          .whereType<String>()
          .map((item) => item.trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }
}