class Schedule {
  final String id;
  final String course;
  final String title;
  final String day;
  final String startTime;
  final String endTime;
  final String room;
  final String instructor;
  final String section;

  Schedule({
    required this.id,
    required this.course,
    required this.title,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.instructor,
    required this.section,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
    id: json['id'] as String,
    course: json['course'] as String,
    title: json['title'] as String,
    day: json['day'] as String,
    startTime: json['start_time'] as String,
    endTime: json['end_time'] as String,
    room: json['room'] as String,
    instructor: json['instructor'] as String,
    section: json['section'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'course': course,
    'title': title,
    'day': day,
    'start_time': startTime,
    'end_time': endTime,
    'room': room,
    'instructor': instructor,
    'section': section,
  };

  Schedule copyWith({
    String? id,
    String? course,
    String? title,
    String? day,
    String? startTime,
    String? endTime,
    String? room,
    String? instructor,
    String? section,
  }) => Schedule(
    id: id ?? this.id,
    course: course ?? this.course,
    title: title ?? this.title,
    day: day ?? this.day,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    room: room ?? this.room,
    instructor: instructor ?? this.instructor,
    section: section ?? this.section,
  );
}
