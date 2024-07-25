// ignore_for_file: non_constant_identifier_names

class Metadata {
  String shoot_day;
  String interview_day;
  String producer;
  DateTime timecode;
  String contestant;
  String camera;
  String audio;

  Metadata({
    this.shoot_day = '',
    this.interview_day = '',
    this.producer = '',
    DateTime? timecode,
    this.contestant = '',
    this.camera = '',
    this.audio = '',
  }) : timecode = timecode ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'shoot_day': shoot_day,
      'interview_day': interview_day,
      'producer': producer,
      'timecode': timecode.toIso8601String(),
      'contestant': contestant,
      'camera': camera,
      'audio': audio,
    };
  }

  static Metadata fromMap(Map<String, dynamic> map) {
    return Metadata(
      shoot_day: map['shoot_day'],
      interview_day: map['interview_day'],
      producer: map['producer'],
      timecode: DateTime.parse(map['timecode']),
      contestant: map['contestant'],
      camera: map['camera'],
      audio: map['audio'],
    );
  }
}