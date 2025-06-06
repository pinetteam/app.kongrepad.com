class ScoreGamePoint {
  int? id;
  int? qrCodeId;
  int? participantId;
  int? point;
  String? title;
  String? createdAt;
  String? description; // Eklendi
  int? scoreGameId; // Eklendi
  int? gameId; // Eklendi (alternative field)

  ScoreGamePoint({this.id, this.qrCodeId, this.participantId, this.point, this.title, this.createdAt, this.description, this.scoreGameId, this.gameId});

  factory ScoreGamePoint.fromJson(Map<String, dynamic> json) {
    return ScoreGamePoint(
      id: json['id'],
      qrCodeId: json['qr_code_id'],
      participantId: json['participant_id'],
      point: json['point'],
      title: json['title'],
      createdAt: json['created_at'],
      description: json['description'],
      scoreGameId: json['score_game_id'],
      gameId: json['game_id'],
    );
  }
}

class ScoreGamePointsJSON {
  List<ScoreGamePoint>? data;
  List<String>? errors;
  bool? status;
  bool? success; // Eklendi

  ScoreGamePointsJSON({this.data, this.errors, this.status, this.success});

  factory ScoreGamePointsJSON.fromJson(Map<String, dynamic> json) {
    return ScoreGamePointsJSON(
      data: json['data'] != null ? (json['data'] as List).map((e) => ScoreGamePoint.fromJson(e)).toList() : null,
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
      status: json['status'],
      success: json['success'],
    );
  }
}

class ScoreGamePointsResponseJSON {
  bool? data;
  List<String>? errors;
  bool? status;
  bool? success; // Eklendi
  int? addedPoints; // QR scan için

  ScoreGamePointsResponseJSON({this.data, this.errors, this.status, this.success, this.addedPoints});

  factory ScoreGamePointsResponseJSON.fromJson(Map<String, dynamic> json) {
    return ScoreGamePointsResponseJSON(
      data: json['data'],
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
      status: json['status'],
      success: json['success'],
      addedPoints: json['added_points'] ?? json['points'],
    );
  }
}