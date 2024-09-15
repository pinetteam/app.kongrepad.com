import 'package:kongrepad/Models/Session.dart';

class Document {
  int? id;
  int? meetingId;
  String? fileName;
  String? fileExtension;
  String? title;
  int? allowedToReview;
  int? sharingViaEmail;
  int? status;
  bool? isRequested;
  Session? session;

  Document({
    this.id,
    this.meetingId,
    this.fileName,
    this.fileExtension,
    this.title,
    this.allowedToReview,
    this.sharingViaEmail,
    this.status,
    this.isRequested,
    this.session,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      meetingId: json['meeting_id'],
      fileName: json['file_name'],
      fileExtension: json['file_extension'],
      title: json['title'],
      allowedToReview: json['allowed_to_review'],
      sharingViaEmail: json['sharing_via_email'],
      status: json['status'],
      isRequested: json['is_requested'],
      session: json['session'] != null ? Session.fromJson(json['session']) : null,
    );
  }
}

class DocumentJSON {
  Document? data;
  List<String>? errors;
  bool? status;

  DocumentJSON({this.data, this.errors, this.status});

  factory DocumentJSON.fromJson(Map<String, dynamic> json) {
    return DocumentJSON(
      data: json['data'] != null ? Document.fromJson(json['data']) : null,
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
      status: json['status'],
    );
  }
}

class DocumentsJSON {
  List<Document>? data;
  List<String>? errors;
  bool? status;

  DocumentsJSON({this.data, this.errors, this.status});

  factory DocumentsJSON.fromJson(Map<String, dynamic> json) {
    return DocumentsJSON(
      data: json['data'] != null ? List<Document>.from(json['data'].map((x) => Document.fromJson(x))) : null,
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
      status: json['status'],
    );
  }
}
