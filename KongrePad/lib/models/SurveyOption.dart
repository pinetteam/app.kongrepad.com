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
    return SurveyOption(
      id: json['id'],
      sortOrder: json['sort_order'],
      surveyId: json['survey_id'],
      questionId: json['question_id'],
      option: json['option'],
      status: json['status'],
      isSelected: json['is_selected'] ?? false,
    );
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
