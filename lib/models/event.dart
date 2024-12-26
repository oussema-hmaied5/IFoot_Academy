class Event {
  final String title;
  final DateTime time;
  final String group;

  Event({required this.title, required this.time, required this.group});

  @override
  String toString() => '$title at ${time.hour}:${time.minute} for $group';
}
