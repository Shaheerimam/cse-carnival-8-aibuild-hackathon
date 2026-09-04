class Announcement {
  final String id;
  final String title;
  final String body;
  final String date;
  final String priority;
  final String postedBy;
  final String expires;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.priority,
    required this.postedBy,
    required this.expires,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    id: json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    date: json['date'] as String,
    priority: json['priority'] as String,
    postedBy: json['posted_by'] as String,
    expires: json['expires'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'date': date,
    'priority': priority,
    'posted_by': postedBy,
    'expires': expires,
  };

  Announcement copyWith({
    String? id,
    String? title,
    String? body,
    String? date,
    String? priority,
    String? postedBy,
    String? expires,
  }) => Announcement(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    date: date ?? this.date,
    priority: priority ?? this.priority,
    postedBy: postedBy ?? this.postedBy,
    expires: expires ?? this.expires,
  );

  bool get isExpired => DateTime.tryParse(expires)?.isBefore(DateTime.now()) ?? false;
}
