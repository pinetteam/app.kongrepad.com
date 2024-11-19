class VirtualStand {
  int? id;
  int? meetingId;
  String? fileName;
  String? fileExtension;
  String? pdfName;
  String? title;
  int? status;
  bool? onHover;

  VirtualStand({
    this.id,
    this.meetingId,
    this.fileName,
    this.fileExtension,
    this.pdfName,
    this.title,
    this.status,
    this.onHover,
  });

  factory VirtualStand.fromJson(Map<String, dynamic> json) => VirtualStand(
    id: json['id'],
    meetingId: json['meeting_id'],
    fileName: json['file_name'],
    fileExtension: json['file_extension'],
    pdfName: json['pdf_name'],
    title: json['title'],
    status: json['status'],
    onHover: json['on_hover'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'meeting_id': meetingId,
    'file_name': fileName,
    'file_extension': fileExtension,
    'pdf_name': pdfName,
    'title': title,
    'status': status,
    'on_hover': onHover,
  };
}

class VirtualStandJSON {
  VirtualStand? data;
  List<String>? errors;
  bool? status;

  VirtualStandJSON({this.data, this.errors, this.status});

  factory VirtualStandJSON.fromJson(Map<String, dynamic> json) => VirtualStandJSON(
    data: json['data'] != null ? VirtualStand.fromJson(json['data']) : null,
    errors: json['errors'] != null ? List<String>.from(json['errors'].map((x) => x)) : null,
    status: json['status'],
  );

  Map<String, dynamic> toJson() => {
    'data': data?.toJson(),
    'errors': errors,
    'status': status,
  };
}

class VirtualStandsJSON {
  List<VirtualStand>? data;
  List<String>? errors;
  bool? status;

  VirtualStandsJSON({this.data, this.errors, this.status});

  factory VirtualStandsJSON.fromJson(Map<String, dynamic> json) => VirtualStandsJSON(
    data: json['data'] != null ? List<VirtualStand>.from(json['data'].map((x) => VirtualStand.fromJson(x))) : null,
    errors: json['errors'] != null ? List<String>.from(json['errors'].map((x) => x)) : null,
    status: json['status'],
  );

  Map<String, dynamic> toJson() => {
    'data': data != null ? List<dynamic>.from(data!.map((x) => x.toJson())) : null,
    'errors': errors,
    'status': status,
  };
}