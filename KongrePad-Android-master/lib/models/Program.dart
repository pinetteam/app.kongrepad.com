import 'package:kongrepad/Models/Debate.dart';
import 'package:kongrepad/Models/Participant.dart';
import 'package:kongrepad/Models/Session.dart';

class ProgramDay {
  String? day;
  List<Program>? programs;

  ProgramDay({this.day, this.programs});

  factory ProgramDay.fromJson(Map<String, dynamic> json) {
    return ProgramDay(
      day: json['day'],
      programs: (json['programs'] as List<dynamic>?)
          ?.map((e) => Program.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Program {
  int? id;
  int? hallId;
  int? sortOrder;
  String? code;
  String? title;
  String? description;
  String? logoName;
  String? logoExtension;
  String? startAt;
  String? finishAt;
  String? type;
  int? onAir;
  int? status;
  List<Participant>? chairs;
  List<Session>? sessions;
  List<Debate>? debates;
//todo open after makine debate and session classes

  Program({
    this.id,
    this.hallId,
    this.sortOrder,
    this.code,
    this.title,
    this.description,
    this.logoName,
    this.logoExtension,
    this.startAt,
    this.finishAt,
    this.type,
    this.onAir,
    this.status,
    this.chairs,
    this.sessions,
    this.debates,

  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'],
      hallId: json['hall_id'],
      sortOrder: json['sort_order'],
      code: json['code'],
      title: json['title'],
      description: json['description'],
      logoName: json['logo_name'],
      logoExtension: json['logo_extension'],
      startAt: json['start_at'],
      finishAt: json['finish_at'],
      type: json['type'],
      onAir: json['on_air'],
      status: json['status'],
      chairs: (json['chairs'] as List<dynamic>?)
          ?.map((e) => Participant.fromJson(e as Map<String, dynamic>))
          .toList(),
      sessions: (json['sessions'] as List<dynamic>?)
          ?.map((e) => Session.fromJson(e as Map<String, dynamic>))
          .toList(),
      debates: (json['debates'] as List<dynamic>?)
          ?.map((e) => Debate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProgramsJson {
  List<ProgramDay>? data;
  List<String>? errors;
  bool? status;

  ProgramsJson({this.data, this.errors, this.status});

  factory ProgramsJson.fromJson(Map<String, dynamic> json) {
    return ProgramsJson(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => ProgramDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      errors: (json['errors'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      status: json['status'],
    );
  }
}
