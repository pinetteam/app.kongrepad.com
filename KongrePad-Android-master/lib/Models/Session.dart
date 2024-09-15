class Session {
  int? id;
  int? programId;
  int? speakerId;
  int? documentId;
  bool? isDocumentRequested;
  bool? documentSharingViaEmail;
  int? sortOrder;
  String? code;
  String? title;
  String? speakerName;
  String? description;
  String? startAt;
  String? finishAt;
  int? onAir;
  int? questionsAllowed;
  int? questionsLimit;
  int? questionAutoStart;
  int? status;

  Session({
    this.id,
    this.programId,
    this.speakerId,
    this.documentId,
    this.isDocumentRequested,
    this.documentSharingViaEmail,
    this.sortOrder,
    this.code,
    this.title,
    this.speakerName,
    this.description,
    this.startAt,
    this.finishAt,
    this.onAir,
    this.questionsAllowed,
    this.questionsLimit,
    this.questionAutoStart,
    this.status,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      programId: json['program_id'],
      speakerId: json['speaker_id'],
      documentId: json['document_id'],
      isDocumentRequested: json['is_document_requested'],
      documentSharingViaEmail: json['document_sharing_via_email'],
      sortOrder: json['sort_order'],
      code: json['code'],
      title: json['title'],
      speakerName: json['speaker_name'],
      description: json['description'],
      startAt: json['start_at'],
      finishAt: json['finish_at'],
      onAir: json['on_air'],
      questionsAllowed: json['questions_allowed'],
      questionsLimit: json['questions_limit'],
      questionAutoStart: json['question_auto_start'],
      status: json['status'],
    );
  }
}

class SessionJSON {
  Session? data;
  List<String>? errors;
  bool? status;

  SessionJSON({
    this.data,
    this.errors,
    this.status,
  });

  factory SessionJSON.fromJson(Map<String, dynamic> json) {
    return SessionJSON(
      data: json['data'] != null ? Session.fromJson(json['data']) : null,
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
      status: json['status'],
    );
  }
}
