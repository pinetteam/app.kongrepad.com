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
  bool? enrolled;    // int'den bool'a değiştir
  bool? gdprConsent; // int'den bool'a değiştir
  bool? status;      // int'den bool'a değiştir

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
    print('Parsing participant JSON: $json'); // Debug için

    return Participant(
      id: json['id'],
      meetingId: json['meeting_id'],
      username: json['username'],
      title: json['title'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      fullName: json['full_name'],
      identificationNumber: json['identification_number'],
      organisation: json['organisation'],
      email: json['email'],
      phoneCountryId: json['phone_country_id'],
      phone: json['phone'],
      password: json['password'],
      lastLoginIp: json['last_login_ip'],
      lastLoginAgent: json['last_login_agent'],
      lastLoginDatetime: json['last_login_datetime'],
      lastActivity: json['last_activity'],
      type: json['type'],
      enrolled: json['enrolled'],       // API'dan bool geliyor
      gdprConsent: json['gdpr_consent'], // API'dan bool geliyor
      status: json['status'],           // API'dan bool geliyor
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

  factory ParticipantJSON.fromJson(Map<String, dynamic> json) => ParticipantJSON(
    data: json['data'] != null ? Participant.fromJson(json['data']) : null,
    errors: json['errors'] != null ? List<String>.from(json['errors'].map((x) => x)) : null,
    status: json['status'],
  );

  Map<String, dynamic> toJson() => {
    'data': data?.toJson(),
    'errors': errors,
    'status': status,
  };
}