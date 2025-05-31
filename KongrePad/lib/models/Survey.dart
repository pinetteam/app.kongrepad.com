class Survey {
  int? sortOrder;
  int? id;
  int? meetingId;
  String? title;
  String? description;
  String? startAt;
  String? finishAt;
  int? status;
  bool? isCompleted;

  Survey({
    this.sortOrder,
    this.id,
    this.meetingId,
    this.title,
    this.description,
    this.startAt,
    this.finishAt,
    this.status,
    this.isCompleted,
  });

  factory Survey.fromJson(Map<String, dynamic> json) => Survey(
    sortOrder: json['sort_order'],
    id: json['id'],
    meetingId: json['meeting_id'],
    title: json['title'],
    description: json['description'],
    startAt: json['start_at'],
    finishAt: json['finish_at'],
    status: json['status'],
    isCompleted: json['is_completed'],
  );

  Map<String, dynamic> toJson() => {
    'sort_order': sortOrder,
    'id': id,
    'meeting_id': meetingId,
    'title': title,
    'description': description,
    'start_at': startAt,
    'finish_at': finishAt,
    'status': status,
    'is_completed': isCompleted,
  };
}

class SurveysJSON {
  List<Survey>? data;
  List<String>? errors;
  bool? status;

  SurveysJSON({this.data, this.errors, this.status});

  factory SurveysJSON.fromJson(Map<String, dynamic> json) => SurveysJSON(
    data: (json['data'] as List<dynamic>?)
        ?.map((e) => Survey.fromJson(e as Map<String, dynamic>))
        .toList(),
    errors: (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
    status: json['status'],
  );

  Map<String, dynamic> toJson() => {
    'data': data?.map((e) => e.toJson()).toList(),
    'errors': errors,
    'status': status,
  };
}

class SurveyJSON {
  Survey? data;
  List<String>? errors;
  bool? status;

  SurveyJSON({this.data, this.errors, this.status});

  factory SurveyJSON.fromJson(Map<String, dynamic> json) => SurveyJSON(
    data: json['data'] == null ? null : Survey.fromJson(json['data'] as Map<String, dynamic>),
    errors: (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
    status: json['status'],
  );

  Map<String, dynamic> toJson() => {
    'data': data?.toJson(),
    'errors': errors,
    'status': status,
  };
}
