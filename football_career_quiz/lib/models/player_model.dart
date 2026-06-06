import 'club_model.dart';

class PlayerModel {
  final String id;
  final String name;
  final String nationality;
  final String status;
  final String difficulty;
  final List<String> tags;
  final List<String> acceptedAnswers;
  final List<ClubModel> clubs;

  const PlayerModel({
    required this.id,
    required this.name,
    required this.nationality,
    required this.status,
    required this.difficulty,
    required this.tags,
    required this.acceptedAnswers,
    required this.clubs,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';

    final answers = (json['acceptedAnswers'] as List<dynamic>?)
            ?.map((e) => e.toString().toLowerCase().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [name.toLowerCase().trim()];

    return PlayerModel(
      id: json['id']?.toString() ?? name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      nationality: json['nationality']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      difficulty: json['difficulty']?.toString() ?? 'medium',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      acceptedAnswers: answers,
      clubs: (json['clubs'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ClubModel.fromJson)
              .where((club) => club.name.isNotEmpty)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nationality': nationality,
      'status': status,
      'difficulty': difficulty,
      'tags': tags,
      'acceptedAnswers': acceptedAnswers,
      'clubs': clubs.map((club) => club.toJson()).toList(),
    };
  }
}
