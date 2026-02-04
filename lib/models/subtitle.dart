class Subtitle {
  final String text;
  final Duration startTime;
  final Duration endTime;

  const Subtitle({
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  bool isActiveAt(Duration position) {
    return position >= startTime && position <= endTime;
  }

  List<String> get words => text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  Duration get duration => endTime - startTime;

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'startTime': startTime.inMilliseconds,
      'endTime': endTime.inMilliseconds,
    };
  }

  factory Subtitle.fromJson(Map<String, dynamic> json) {
    return Subtitle(
      text: json['text'] as String,
      startTime: Duration(milliseconds: json['startTime'] as int),
      endTime: Duration(milliseconds: json['endTime'] as int),
    );
  }

  @override
  String toString() => 'Subtitle(text: $text, start: $startTime, end: $endTime)';
}
