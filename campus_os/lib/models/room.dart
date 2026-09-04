class Booking {
  final String bookingId;
  final String bookedBy;
  final String date;
  final String startTime;
  final String endTime;
  final String purpose;

  Booking({
    required this.bookingId,
    required this.bookedBy,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.purpose,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    bookingId: json['booking_id'] as String,
    bookedBy: json['booked_by'] as String,
    date: json['date'] as String,
    startTime: json['start_time'] as String,
    endTime: json['end_time'] as String,
    purpose: json['purpose'] as String,
  );

  Map<String, dynamic> toJson() => {
    'booking_id': bookingId,
    'booked_by': bookedBy,
    'date': date,
    'start_time': startTime,
    'end_time': endTime,
    'purpose': purpose,
  };
}

class Room {
  final String id;
  final String roomNumber;
  final String type;
  final int capacity;
  final List<String> equipment;
  final int floor;
  final String status;
  final List<Booking> bookings;

  Room({
    required this.id,
    required this.roomNumber,
    required this.type,
    required this.capacity,
    required this.equipment,
    required this.floor,
    required this.status,
    required this.bookings,
  });

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: json['id'] as String,
    roomNumber: json['room_number'] as String,
    type: json['type'] as String,
    capacity: json['capacity'] as int,
    equipment: List<String>.from(json['equipment'] as List),
    floor: json['floor'] as int,
    status: json['status'] as String,
    bookings: (json['bookings'] as List)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'room_number': roomNumber,
    'type': type,
    'capacity': capacity,
    'equipment': equipment,
    'floor': floor,
    'status': status,
    'bookings': bookings.map((b) => b.toJson()).toList(),
  };

  Room copyWith({
    String? id,
    String? roomNumber,
    String? type,
    int? capacity,
    List<String>? equipment,
    int? floor,
    String? status,
    List<Booking>? bookings,
  }) => Room(
    id: id ?? this.id,
    roomNumber: roomNumber ?? this.roomNumber,
    type: type ?? this.type,
    capacity: capacity ?? this.capacity,
    equipment: equipment ?? this.equipment,
    floor: floor ?? this.floor,
    status: status ?? this.status,
    bookings: bookings ?? this.bookings,
  );
}
