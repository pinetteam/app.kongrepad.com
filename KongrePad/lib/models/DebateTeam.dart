class DebateTeam {
  int? id;
  int? debateId;
  String? code;
  String? logoName;
  String? logoExtension;
  String? title;
  String? description;

  DebateTeam({
    this.id,
    this.debateId,
    this.code,
    this.logoName,
    this.logoExtension,
    this.title,
    this.description,
  });

  factory DebateTeam.fromJson(Map<String, dynamic> json) {
    return DebateTeam(
      id: json['id'],
      debateId: json['debate_id'],
      code: json['code'],
      logoName: json['logo_name'],
      logoExtension: json['logo_extension'],
      title: json['title'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['debate_id'] = this.debateId;
    data['code'] = this.code;
    data['logo_name'] = this.logoName;
    data['logo_extension'] = this.logoExtension;
    data['title'] = this.title;
    data['description'] = this.description;
    return data;
  }
}
