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
    return SurveyQuestion(
      id: json['id'],
      sortOrder: json['sort_order'],
      surveyId: json['survey_id'],
      selectedOption: json['selected_option'],
      question: json['question'],
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => SurveyOption.fromJson(e))
          .toList(),
      status: json['status'],
      required: json['required'] ?? true, // Default zorunlu
    );
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