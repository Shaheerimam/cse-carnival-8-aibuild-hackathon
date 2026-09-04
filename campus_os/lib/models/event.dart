class Registration {
  final String studentId;
  final String name;

  Registration({required this.studentId, required this.name});

  factory Registration.fromJson(Map<String, dynamic> json) => Registration(
    studentId: json['student_id'] as String,
    name: json['name'] as String,
  );

  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    'name': name,
  };
}

class Event {
  final String id;
  final String name;
  final String description;
  final String date;
  final String startTime;
  final String endTime;
  final String endDate;
  final String venue;
  final String organizer;
  final int capacity;
  final int registered;
  final List<Registration> registrations;
  final String status;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.endDate,
    required this.venue,
    required this.organizer,
    required this.capacity,
    required this.registered,
    required this.registrations,
    required this.status,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    date: json['date'] as String,
    startTime: json['start_time'] as String,
    endTime: json['end_time'] as String,
    endDate: json['end_date'] as String,
    venue: json['venue'] as String,
    organizer: json['organizer'] as String,
    capacity: json['capacity'] as int,
    registered: json['registered'] as int,
    registrations: (json['registrations'] as List)
        .map((e) => Registration.fromJson(e as Map<String, dynamic>))
        .toList(),
    status: json['status'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'date': date,
    'start_time': startTime,
    'end_time': endTime,
    'end_date': endDate,
    'venue': venue,
    'organizer': organizer,
    'capacity': capacity,
    'registered': registered,
    'registrations': registrations.map((r) => r.toJson()).toList(),
    'status': status,
  };

  Event copyWith({
    String? id,
    String? name,
    String? description,
    String? date,
    String? startTime,
    String? endTime,
    String? endDate,
    String? venue,
    String? organizer,
    int? capacity,
    int? registered,
    List<Registration>? registrations,
    String? status,
  }) => Event(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    date: date ?? this.date,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    endDate: endDate ?? this.endDate,
    venue: venue ?? this.venue,
    organizer: organizer ?? this.organizer,
    capacity: capacity ?? this.capacity,
    registered: registered ?? this.registered,
    registrations: registrations ?? this.registrations,
    status: status ?? this.status,
  );

  double get fillPercentage => capacity > 0 ? registered / capacity : 0;
  bool get isFull => registered >= capacity;
}
