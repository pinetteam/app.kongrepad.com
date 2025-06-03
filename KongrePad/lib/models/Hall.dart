class Hall {
  int? id;
  int? meetingId;
  String? code;
  String? title;
  bool? showOnSession;
  bool? showOnAskQuestion;
  bool? showOnViewProgram;
  bool? showOnSendMail;
  bool? status;

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
      showOnSession: json['show_on_session'] is bool
          ? json['show_on_session']
          : json['show_on_session'] == 1,
      showOnAskQuestion: json['show_on_ask_question'] is bool
          ? json['show_on_ask_question']
          : json['show_on_ask_question'] == 1,
      showOnViewProgram: json['show_on_view_program'] is bool
          ? json['show_on_view_program']
          : json['show_on_view_program'] == 1,
      showOnSendMail: json['show_on_send_mail'] is bool
          ? json['show_on_send_mail']
          : json['show_on_send_mail'] == 1,
      status: json['status'] is bool ? json['status'] : json['status'] == 1,
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
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
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
      data: json['data'] != null
          ? Hall.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      status: json['status'],
    );
  }
}
