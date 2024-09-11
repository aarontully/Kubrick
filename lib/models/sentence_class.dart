class Sentence {
  final String text;
  final double startTime;
  final double endTime;

  Sentence({
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  factory Sentence.fromMap(Map<String, dynamic> map) {
    return Sentence(
      text: map['text'] as String,
      startTime: map['start'] as double,
      endTime: map['end'] as double,
    );
  }
}