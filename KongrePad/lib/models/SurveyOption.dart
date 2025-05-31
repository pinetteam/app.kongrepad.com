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
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = this.id;
    data['sort_order'] = this.sortOrder;
    data['survey_id'] = this.surveyId;
    data['question_id'] = this.questionId;
    data['option'] = this.option;
    data['status'] = this.status;
    data['is_selected'] = this.isSelected;
    return data;
  }
}
