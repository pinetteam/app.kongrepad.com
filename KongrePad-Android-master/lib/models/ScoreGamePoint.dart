class ScoreGamePoint {
  int? id;
  int? qrCodeId;
  int? participantId;
  int? point;
  String? title;
  String? createdAt;

  ScoreGamePoint({this.id, this.qrCodeId, this.participantId, this.point, this.title, this.createdAt});

  factory ScoreGamePoint.fromJson(Map<String, dynamic> json) {
    return ScoreGamePoint(
      id: json['id'],
      qrCodeId: json['qr_code_id'],
      participantId: json['participant_id'],
      point: json['point'],
      title: json['title'],
      createdAt: json['created_at'],
    );
  }
}

class ScoreGamePointsJSON {
  List<ScoreGamePoint>? data;
  List<String>? errors;
  bool? status;

  ScoreGamePointsJSON({this.data, this.errors, this.status});

  factory ScoreGamePointsJSON.fromJson(Map<String, dynamic> json) {
    return ScoreGamePointsJSON(
      data: json['data'] != null ? (json['data'] as List).map((e) => ScoreGamePoint.fromJson(e)).toList() : null,
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
      status: json['status'],
    );
  }
}

class ScoreGamePointsResponseJSON {
  bool? data;
  List<String>? errors;
  bool? status;

  ScoreGamePointsResponseJSON({this.data, this.errors, this.status});

  factory ScoreGamePointsResponseJSON.fromJson(Map<String, dynamic> json) {
    return ScoreGamePointsResponseJSON(
      data: json['data'],
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
      status: json['status'],
    );
  }
}
