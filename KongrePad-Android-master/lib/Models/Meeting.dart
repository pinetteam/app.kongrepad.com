class Meeting {
  int? id;
  String? bannerName;
  String? bannerExtension;
  String? code;
  String? title;
  String? startAt;
  String? finishAt;
  int? sessionHallCount;
  int? sessionFirstHallId;
  int? questionHallCount;
  int? questionFirstHallId;
  int? programHallCount;
  int? programFirstHallId;
  int? mailHallCount;
  int? mailFirstHallId;

  Meeting({
    this.id,
    this.bannerName,
    this.bannerExtension,
    this.code,
    this.title,
    this.startAt,
    this.finishAt,
    this.sessionHallCount,
    this.sessionFirstHallId,
    this.questionHallCount,
    this.questionFirstHallId,
    this.programHallCount,
    this.programFirstHallId,
    this.mailHallCount,
    this.mailFirstHallId,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) => Meeting(
    id: json['id'],
    bannerName: json['banner_name'],
    bannerExtension: json['banner_extension'],
    code: json['code'],
    title: json['title'],
    startAt: json['start_at'],
    finishAt: json['finish_at'],
    sessionHallCount: json['session_hall_count'],
    sessionFirstHallId: json['session_first_hall_id'],
    questionHallCount: json['question_hall_count'],
    questionFirstHallId: json['question_first_hall_id'],
    programHallCount: json['program_hall_count'],
    programFirstHallId: json['program_first_hall_id'],
    mailHallCount: json['mail_hall_count'],
    mailFirstHallId: json['mail_first_hall_id'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'banner_name': bannerName,
    'banner_extension': bannerExtension,
    'code': code,
    'title': title,
    'start_at': startAt,
    'finish_at': finishAt,
    'session_hall_count': sessionHallCount,
    'session_first_hall_id': sessionFirstHallId,
    'question_hall_count': questionHallCount,
    'question_first_hall_id': questionFirstHallId,
    'program_hall_count': programHallCount,
    'program_first_hall_id': programFirstHallId,
    'mail_hall_count': mailHallCount,
    'mail_first_hall_id': mailFirstHallId,
  };
}

class MeetingJSON {
  Meeting? data;
  List<String>? errors;
  bool? status;

  MeetingJSON({this.data, this.errors, this.status});

  factory MeetingJSON.fromJson(Map<String, dynamic> json) => MeetingJSON(
    data: json['data'] != null ? Meeting.fromJson(json['data']) : null,
    errors: json['errors'] != null
        ? List<String>.from(json['errors'].map((x) => x))
        : null,
    status: json['status'],
  );

  Map<String, dynamic> toJson() => {
    'data': data?.toJson(),
    'errors': errors,
    'status': status,
  };
}