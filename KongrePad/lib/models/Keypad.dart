import 'KeypadOption.dart';

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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['sort_order'] = sortOrder;
    data['session_id'] = sessionId;
    data['code'] = code;
    data['title'] = title;
    data['keypad'] = keypad;
    data['voting_started_at'] = votingStartedAt;
    data['voting_finished_at'] = votingFinishedAt;
    data['options'] = options?.map((e) => e.toJson()).toList();
    data['on_vote'] = onVote;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['data'] = this.data?.map((e) => e.toJson()).toList();
    data['errors'] = errors;
    data['status'] = status;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['data'] = this.data?.toJson();
    data['errors'] = errors;
    data['status'] = status;
    return data;
  }
}
