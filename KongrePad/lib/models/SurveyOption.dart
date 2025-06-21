class SurveyOption {
  int? id;
  int? sortOrder;
  int? surveyId;
  int? questionId;
  String? option;
  int? status;
  bool? isSelected;

  SurveyOption({
    this.id,
    this.sortOrder,
    this.surveyId,
    this.questionId,
    this.option,
    this.status,
    this.isSelected = false,
  });

  factory SurveyOption.fromJson(Map<String, dynamic> json) {
    try {
      return SurveyOption(
        id: _parseIntSafely(json['id']),
        sortOrder: _parseIntSafely(json['sort_order']),
        surveyId: _parseIntSafely(json['survey_id']),
        questionId: _parseIntSafely(json['question_id']),
        option: json['option']?.toString() ?? '',
        status: _parseIntSafely(json['status']),
        isSelected: _parseBoolSafely(json['is_selected']),
      );
    } catch (e) {
      print('SurveyOption.fromJson - Parse hatası: $e');
      print('SurveyOption.fromJson - JSON data: $json');
      // Hata durumunda minimum geçerli option döndür
      return SurveyOption(
        id: _parseIntSafely(json['id']),
        option: json['option']?.toString() ?? 'Bilinmeyen Seçenek',
        isSelected: false,
      );
    }
  }

  // ✅ YENİ: Type safe parsing metodları
  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is bool) return value ? 1 : 0;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      // String'de "true"/"false" varsa bool'a çevir
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
      // String'de sayı varsa int'e çevir
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed != 0;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['sort_order'] = sortOrder;
    data['survey_id'] = surveyId;
    data['question_id'] = questionId;
    data['option'] = option;
    data['status'] = status;
    data['is_selected'] = isSelected;
    return data;
  }
}
