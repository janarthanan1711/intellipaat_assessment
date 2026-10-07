import 'package:equatable/equatable.dart';

class Lesson extends Equatable {
  const Lesson({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
    id: json['id'] as int,
    title: json['title'] as String,
    isCompleted: json['completed'] as bool? ?? false,
  );

  final int id;
  final String title;
  final bool isCompleted;

  @override
  List<Object?> get props => [id, title, isCompleted];
}
