import 'package:kongrepad/Models/KeypadOption.dart';

class Keypad {
  int? id;
  int? sortOrder;
  int? sessionId;
  String? code;
  String? title;
  String? keypad;
  String? votingStartedAt;
  String? votingFinishedAt;
  List<KeypadOption>? options;
  int? onVote;

  Keypad({
    this.id,
    this.sortOrder,
    this.sessionId,
    this.code,
    this.title,
    this.keypad,
    this.votingStartedAt,
    this.votingFinishedAt,
    this.options,
    this.onVote,
  });

  factory Keypad.fromJson(Map<String, dynamic> json) {
    return Keypad(
      id: json['id'],
      sortOrder: json['sort_order'],
      sessionId: json['session_id'],
      code: json['code'],
      title: json['title'],
      keypad: json['keypad'],
      votingStartedAt: json['voting_started_at'],
      votingFinishedAt: json['voting_finished_at'],
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => KeypadOption.fromJson(e))
          .toList(),
      onVote: json['on_vote'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['sort_order'] = this.sortOrder;
    data['session_id'] = this.sessionId;
    data['code'] = this.code;
    data['title'] = this.title;
    data['keypad'] = this.keypad;
    data['voting_started_at'] = this.votingStartedAt;
    data['voting_finished_at'] = this.votingFinishedAt;
    data['options'] = this.options?.map((e) => e.toJson()).toList();
    data['on_vote'] = this.onVote;
    return data;
  }
}

class KeypadsJSON {
  List<Keypad>? data;
  List<String>? errors;
  bool? status;

  KeypadsJSON({this.data, this.errors, this.status});

  factory KeypadsJSON.fromJson(Map<String, dynamic> json) {
    return KeypadsJSON(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => Keypad.fromJson(e))
          .toList(),
      errors: json['errors']?.cast<String>(),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['data'] = this.data?.map((e) => e.toJson()).toList();
    data['errors'] = this.errors;
    data['status'] = this.status;
    return data;
  }
}

class KeypadJSON {
  Keypad? data;
  List<String>? errors;
  bool? status;

  KeypadJSON({this.data, this.errors, this.status});

  factory KeypadJSON.fromJson(Map<String, dynamic> json) {
    return KeypadJSON(
      data: json['data'] != null ? Keypad.fromJson(json['data']) : null,
      errors: json['errors']?.cast<String>(),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['data'] = this.data?.toJson();
    data['errors'] = this.errors;
    data['status'] = this.status;
    return data;
  }
}
