class Announcement {
  int? id;
  int? meetingId;
  String? title;
  String? createdAt;
  int? status;

  Announcement({this.id, this.meetingId, this.title, this.createdAt, this.status});

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      meetingId: json['meeting_id'],
      title: json['title'],
      createdAt: json['created_at'],
      status: json['status'],
    );
  }
}

class AnnouncementsJSON {
  List<Announcement>? data;
  List<String>? errors;
  bool? status;

  AnnouncementsJSON({this.data, this.errors, this.status});

  factory AnnouncementsJSON.fromJson(Map<String, dynamic> json) {
    return AnnouncementsJSON(
      data: (json['data'] as List<dynamic>?)?.map((e) => Announcement.fromJson(e as Map<String, dynamic>)).toList(),
      errors: (json['errors'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      status: json['status'],
    );
  }
}
