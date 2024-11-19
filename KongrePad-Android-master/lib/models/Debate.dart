import 'package:kongrepad/Models/DebateTeam.dart';

class Debate {
  int? id;
  int? sortOrder;
  int? programId;
  String? code;
  String? title;
  String? description;
  String? votingStartedAt;
  String? votingFinishedAt;
  List<DebateTeam>? teams;
  int? onVote;
  int? status;

  Debate({
    this.id,
    this.sortOrder,
    this.programId,
    this.code,
    this.title,
    this.description,
    this.votingStartedAt,
    this.votingFinishedAt,
    this.teams,
    this.onVote,
    this.status,
  });

  factory Debate.fromJson(Map<String, dynamic> json) {
    return Debate(
      id: json['id'],
      sortOrder: json['sort_order'],
      programId: json['program_id'],
      code: json['code'],
      title: json['title'],
      description: json['description'],
      votingStartedAt: json['voting_started_at'],
      votingFinishedAt: json['voting_finished_at'],
      teams: json['teams'] != null ? List<DebateTeam>.from(json['teams'].map((x) => DebateTeam.fromJson(x))) : null,
      onVote: json['on_vote'],
      status: json['status'],
    );
  }
}

class DebatesJSON {
  List<Debate>? data;
  List<String>? errors;
  bool? status;

  DebatesJSON({
    this.data,
    this.errors,
    this.status,
  });

  factory DebatesJSON.fromJson(Map<String, dynamic> json) {
    return DebatesJSON(
      data: json['data'] != null ? List<Debate>.from(json['data'].map((x) => Debate.fromJson(x))) : null,
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
      status: json['status'],
    );
  }
}

class DebateJSON {
  Debate? data;
  List<String>? errors;
  bool? status;

  DebateJSON({
    this.data,
    this.errors,
    this.status,
  });

  factory DebateJSON.fromJson(Map<String, dynamic> json) {
    return DebateJSON(
      data: json['data'] != null ? Debate.fromJson(json['data']) : null,
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
      status: json['status'],
    );
  }
}
