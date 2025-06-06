class ScoreGame {
  int? id;
  int? meetingId;
  int? totalPoint;
  int? userTotalPoint;
  String? logo;
  String? startAt;
  String? finishAt;
  String? title;
  int? status;

  ScoreGame({this.id, this.meetingId, this.totalPoint, this.userTotalPoint, this.logo, this.startAt, this.finishAt, this.title, this.status});

  factory ScoreGame.fromJson(Map<String, dynamic> json) {
    return ScoreGame(
      id: json['id'],
      meetingId: json['meeting_id'],
      totalPoint: json['total_point'],
      userTotalPoint: json['user_total_point'],
      logo: json['logo'],
      startAt: json['start_at'],
      finishAt: json['finish_at'], // Typo düzeltildi
      title: json['title'],
      status: json['status'],
    );
  }
}

class ScoreGameJSON {
  ScoreGame? data;
  List<String>? errors;
  bool? status;
  bool? success; // Yeni API için

  ScoreGameJSON({this.data, this.errors, this.status, this.success});

  factory ScoreGameJSON.fromJson(Map<String, dynamic> json) {
    return ScoreGameJSON(
      data: json['data'] != null ? ScoreGame.fromJson(json['data']) : null,
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
      status: json['status'],
      success: json['success'],
    );
  }
}