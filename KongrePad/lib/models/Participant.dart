class Participant {
  int? id;
  int? meetingId;
  String? username;
  String? title;
  String? firstName;
  String? lastName;
  String? fullName;
  String? identificationNumber;
  String? organisation;
  String? email;
  int? phoneCountryId;
  String? phone;
  String? password;
  String? lastLoginIp;
  String? lastLoginAgent;
  String? lastLoginDatetime;
  String? lastActivity;
  String? type;
  bool? enrolled;
  bool? gdprConsent;
  bool? status;

  Participant({
    this.id,
    this.meetingId,
    this.username,
    this.title,
    this.firstName,
    this.lastName,
    this.fullName,
    this.identificationNumber,
    this.organisation,
    this.email,
    this.phoneCountryId,
    this.phone,
    this.password,
    this.lastLoginIp,
    this.lastLoginAgent,
    this.lastLoginDatetime,
    this.lastActivity,
    this.type,
    this.enrolled,
    this.gdprConsent,
    this.status,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    // Eğer participant key'i varsa, içindeki veriyi kullan
    final participantData =
        json.containsKey('participant') ? json['participant'] : json;

    print('Processing participant data: $participantData');

    return Participant(
      id: participantData['id'],
      meetingId: participantData['meeting_id'],
      username: participantData['username'],
      title: participantData['title'],
      firstName: participantData['first_name'],
      lastName: participantData['last_name'],
      fullName: participantData['full_name'],
      identificationNumber: participantData['identification_number'],
      organisation: participantData['organisation'],
      email: participantData['email'],
      phoneCountryId: participantData['phone_country_id'],
      phone: participantData['phone'],
      password: participantData['password'],
      lastLoginIp: participantData['last_login_ip'],
      lastLoginAgent: participantData['last_login_agent'],
      lastLoginDatetime: participantData['last_login_datetime'],
      lastActivity: participantData['last_activity'],
      type: participantData['type'],
      enrolled:
          participantData['enrolled'] == 1 ? true : participantData['enrolled'],
      gdprConsent: participantData['gdpr_consent'] == 1
          ? true
          : participantData['gdpr_consent'],
      status: participantData['status'] == 1 ? true : participantData['status'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'meeting_id': meetingId,
        'username': username,
        'title': title,
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName,
        'identification_number': identificationNumber,
        'organisation': organisation,
        'email': email,
        'phone_country_id': phoneCountryId,
        'phone': phone,
        'password': password,
        'last_login_ip': lastLoginIp,
        'last_login_agent': lastLoginAgent,
        'last_login_datetime': lastLoginDatetime,
        'last_activity': lastActivity,
        'type': type,
        'enrolled': enrolled,
        'gdpr_consent': gdprConsent,
        'status': status,
      };
}

class ParticipantJSON {
  Participant? data;
  List<String>? errors;
  bool? status;

  ParticipantJSON({this.data, this.errors, this.status});

  factory ParticipantJSON.fromJson(Map<String, dynamic> json) =>
      ParticipantJSON(
        data: json['data'] != null ? Participant.fromJson(json['data']) : null,
        errors: json['errors'] != null
            ? List<String>.from(json['errors'].map((x) => x))
            : null,
        status: json['status'],
      );

  Map<String, dynamic> toJson() => {
        'data': data?.toJson(),
        'errors': errors,
        'status': status,
      };
}
