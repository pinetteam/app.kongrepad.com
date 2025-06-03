import 'SurveyOption.dart';

class SurveyQuestion {
  int? id;
  int? sortOrder;
  int? surveyId;
  int? selectedOption;
  String? question;
  List<SurveyOption>? options;
  int? status;

  SurveyQuestion({
    this.id,
    this.sortOrder,
    this.surveyId,
    this.selectedOption,
    this.question,
    this.options,
    this.status,
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
    return data;
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
}
