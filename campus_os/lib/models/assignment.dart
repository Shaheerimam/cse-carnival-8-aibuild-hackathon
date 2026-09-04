class Assignment {
  final String id;
  final String course;
  final String courseTitle;
  final String title;
  final String description;
  final String assignedDate;
  final String deadline;
  final String submissionPlatform;
  final String status;
  final int marks;

  Assignment({
    required this.id,
    required this.course,
    required this.courseTitle,
    required this.title,
    required this.description,
    required this.assignedDate,
    required this.deadline,
    required this.submissionPlatform,
    required this.status,
    required this.marks,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
    id: json['id'] as String,
    course: json['course'] as String,
    courseTitle: json['course_title'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    assignedDate: json['assigned_date'] as String,
    deadline: json['deadline'] as String,
    submissionPlatform: json['submission_platform'] as String,
    status: json['status'] as String,
    marks: json['marks'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'course': course,
    'course_title': courseTitle,
    'title': title,
    'description': description,
    'assigned_date': assignedDate,
    'deadline': deadline,
    'submission_platform': submissionPlatform,
    'status': status,
    'marks': marks,
  };

  Assignment copyWith({
    String? id,
    String? course,
    String? courseTitle,
    String? title,
    String? description,
    String? assignedDate,
    String? deadline,
    String? submissionPlatform,
    String? status,
    int? marks,
  }) => Assignment(
    id: id ?? this.id,
    course: course ?? this.course,
    courseTitle: courseTitle ?? this.courseTitle,
    title: title ?? this.title,
    description: description ?? this.description,
    assignedDate: assignedDate ?? this.assignedDate,
    deadline: deadline ?? this.deadline,
    submissionPlatform: submissionPlatform ?? this.submissionPlatform,
    status: status ?? this.status,
    marks: marks ?? this.marks,
  );

  int get daysUntilDue {
    final dl = DateTime.tryParse(deadline);
    if (dl == null) return 0;
    return dl.difference(DateTime.now()).inDays;
  }

  bool get isOverdue => daysUntilDue < 0 && status == 'pending';
}
