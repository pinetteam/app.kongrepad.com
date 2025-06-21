import 'SurveyOption.dart';

class SurveyQuestion {
  int? id;
  int? sortOrder;
  int? surveyId;
  int? selectedOption;
  String? question;
  List<SurveyOption>? options;
  int? status;
  bool? required; // Zorunlu alan kontrolü için

  SurveyQuestion({
    this.id,
    this.sortOrder,
    this.surveyId,
    this.selectedOption,
    this.question,
    this.options,
    this.status,
    this.required,
  });

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    try {
      return SurveyQuestion(
        id: _parseIntSafely(json['id']),
        sortOrder: _parseIntSafely(json['sort_order']),
        surveyId: _parseIntSafely(json['survey_id']),
        selectedOption: _parseIntSafely(json['selected_option']),
        question: json['question']?.toString() ?? '',
        options: _parseOptionsSafely(json['options']),
        status: _parseIntSafely(json['status']),
        required: _parseBoolSafely(json['required']),
      );
    } catch (e) {
      print('SurveyQuestion.fromJson - Parse hatası: $e');
      print('SurveyQuestion.fromJson - JSON data: $json');
      // Hata durumunda minimum geçerli question döndür
      return SurveyQuestion(
        id: _parseIntSafely(json['id']),
        question: json['question']?.toString() ?? 'Bilinmeyen Soru',
        required: true,
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

  static List<SurveyOption>? _parseOptionsSafely(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;

    final options = <SurveyOption>[];
    for (final optionJson in value) {
      try {
        if (optionJson is Map<String, dynamic>) {
          final option = SurveyOption.fromJson(optionJson);
          options.add(option);
        }
      } catch (e) {
        print('SurveyQuestion - Option parse hatası: $e');
        continue;
      }
    }
    return options;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['sort_order'] = sortOrder;
    data['survey_id'] = surveyId;
    data['selected_option'] = selectedOption;
    data['question'] = question;
    data['options'] = options?.map((e) => e.toJson()).toList();
    data['status'] = status;
    data['required'] = required;
    return data;
  }

  /// Helper method to check if question has valid options
  bool get hasValidOptions => options != null && options!.isNotEmpty;

  /// Helper method to get selected option
  SurveyOption? get getSelectedOption {
    if (options == null || selectedOption == null) return null;
    try {
      return options!.firstWhere((option) => option.id == selectedOption);
    } catch (e) {
      return null;
    }
  }

  /// Helper method to check if an option is selected
  bool isOptionSelected(int optionId) {
    return selectedOption == optionId;
  }

  /// Helper method to select an option
  void selectOption(int optionId) {
    selectedOption = optionId;
    // Update options selection state
    if (options != null) {
      for (var option in options!) {
        option.isSelected = (option.id == optionId);
      }
    }
  }

  /// Helper method to clear selection
  void clearSelection() {
    selectedOption = null;
    if (options != null) {
      for (var option in options!) {
        option.isSelected = false;
      }
    }
  }
}

class SurveyQuestionsJSON {
  List<SurveyQuestion>? data;
  List<String>? errors;
  bool? status;

  SurveyQuestionsJSON({
    this.data,
    this.errors,
    this.status,
  });

  factory SurveyQuestionsJSON.fromJson(Map<String, dynamic> json) {
    return SurveyQuestionsJSON(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => SurveyQuestion.fromJson(e))
          .toList(),
      errors: (json['errors'] as List<dynamic>?)?.cast<String>(),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['data'] = this.data?.map((e) => e.toJson()).toList();
    data['errors'] = errors;
    data['status'] = status;
    return data;
  }

  /// Helper method to check if response is successful
  bool get isSuccess => status == true && data != null;

  /// Helper method to get error message
  String get errorMessage {
    if (errors != null && errors!.isNotEmpty) {
      return errors!.join(', ');
    }
    return 'Bilinmeyen hata';
  }
}

class SurveyQuestionJSON {
  SurveyQuestion? data;
  List<String>? errors;
  bool? status;

  SurveyQuestionJSON({
    this.data,
    this.errors,
    this.status,
  });

  factory SurveyQuestionJSON.fromJson(Map<String, dynamic> json) {
    return SurveyQuestionJSON(
      data: json['data'] != null ? SurveyQuestion.fromJson(json['data']) : null,
      errors: (json['errors'] as List<dynamic>?)?.cast<String>(),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['data'] = this.data?.toJson();
    data['errors'] = errors;
    data['status'] = status;
    return data;
  }

  /// Helper method to check if response is successful
  bool get isSuccess => status == true && data != null;

  /// Helper method to get error message
  String get errorMessage {
    if (errors != null && errors!.isNotEmpty) {
      return errors!.join(', ');
    }
    return 'Bilinmeyen hata';
  }
}
