class Hall {
  int? id;
  int? meetingId;
  String? code;
  String? title;
  int? showOnSession;
  int? showOnAskQuestion;
  int? showOnViewProgram;
  int? showOnSendMail;
  int? status;

  Hall({
    this.id,
    this.meetingId,
    this.code,
    this.title,
    this.showOnSession,
    this.showOnAskQuestion,
    this.showOnViewProgram,
    this.showOnSendMail,
    this.status,
  });

  factory Hall.fromJson(Map<String, dynamic> json) {
    return Hall(
      id: json['id'],
      meetingId: json['meeting_id'],
      code: json['code'],
      title: json['title'],
      showOnSession: json['show_on_session'],
      showOnAskQuestion: json['show_on_ask_question'],
      showOnViewProgram: json['show_on_view_program'],
      showOnSendMail: json['show_on_send_mail'],
      status: json['status'],
    );
  }
}

class HallsJSON {
  List<Hall>? data;
  List<String>? errors;
  bool? status;

  HallsJSON({
    this.data,
    this.errors,
    this.status,
  });

  factory HallsJSON.fromJson(Map<String, dynamic> json) {
    return HallsJSON(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => Hall.fromJson(e as Map<String, dynamic>))
          .toList(),
      errors: (json['errors'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      status: json['status'],
    );
  }
}

class HallJSON {
  Hall? data;
  List<String>? errors;
  bool? status;

  HallJSON({
    this.data,
    this.errors,
    this.status,
  });

  factory HallJSON.fromJson(Map<String, dynamic> json) {
    return HallJSON(
      data: json['data'] != null ? Hall.fromJson(json['data'] as Map<String, dynamic>) : null,
      errors: (json['errors'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      status: json['status'],
    );
  }
}
