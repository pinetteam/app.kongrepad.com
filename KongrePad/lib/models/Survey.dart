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

  factory Survey.fromJson(Map<String, dynamic> json) {
    try {
      bool? isCompleted;
      if (json['participant_status'] != null) {
        final participantStatus =
            json['participant_status'] as Map<String, dynamic>;
        isCompleted = _parseBoolSafely(participantStatus['has_participated']);
      }

      return Survey(
        sortOrder: _parseIntSafely(json['sort_order']),
        id: _parseIntSafely(json['id']),
        meetingId: _parseIntSafely(json['meeting_id']),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        startAt: json['start_at']?.toString() ?? '',
        finishAt: json['finish_at']?.toString() ?? '',
        status: _parseIntSafely(json['status']),
        isCompleted: isCompleted,
      );
    } catch (e) {
      print('Survey.fromJson - Parse hatası: $e');
      print('Survey.fromJson - JSON data: $json');
      // Hata durumunda minimum geçerli survey döndür
      return Survey(
        id: _parseIntSafely(json['id']),
        title: json['title']?.toString() ?? 'Bilinmeyen Anket',
        description: json['description']?.toString() ?? '',
        status: 0,
        isCompleted: false,
      );
    }
  }

  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is bool) return value ? 1 : 0;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      if (value.toLowerCase() == 'true') return 1;
      if (value.toLowerCase() == 'false') return 0;
    }
    return null;
  }

  static bool? _parseBoolSafely(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed != 0;
    }
    return null;
  }

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
        errors: (json['errors'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
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
        data: json['data'] == null
            ? null
            : Survey.fromJson(json['data'] as Map<String, dynamic>),
        errors: (json['errors'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        status: json['status'],
      );

  Map<String, dynamic> toJson() => {
        'data': data?.toJson(),
        'errors': errors,
        'status': status,
      };
}
