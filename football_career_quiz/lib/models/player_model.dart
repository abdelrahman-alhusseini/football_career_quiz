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

  final String position;
  final String imageUrl;
  final String nationalTeamNumber;
  final Map<String, String> knownClubNumbers;
  final List<String> hints;

  const PlayerModel({
    required this.id,
    required this.name,
    required this.nationality,
    required this.status,
    required this.difficulty,
    required this.tags,
    required this.acceptedAnswers,
    required this.clubs,
    this.position = '',
    this.imageUrl = '',
    this.nationalTeamNumber = '',
    this.knownClubNumbers = const {},
    this.hints = const [],
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';

    final answers = (json['acceptedAnswers'] as List?)
            ?.map((e) => e.toString().toLowerCase().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [name.toLowerCase().trim()];

    final clubNumbersJson = json['knownClubNumbers'];

    return PlayerModel(
      id: json['id']?.toString() ?? name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      nationality: json['nationality']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      difficulty: json['difficulty']?.toString() ?? 'pro',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      acceptedAnswers: answers,
      clubs: (json['clubs'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ClubModel.fromJson)
              .where((club) => club.name.isNotEmpty)
              .toList() ??
          [],
      position: json['position']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      nationalTeamNumber: json['nationalTeamNumber']?.toString() ?? '',
      knownClubNumbers: clubNumbersJson is Map
          ? clubNumbersJson.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const {},
      hints: (json['hints'] as List?)?.map((e) => e.toString()).toList() ?? [],
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
      if (position.isNotEmpty) 'position': position,
      if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      if (nationalTeamNumber.isNotEmpty)
        'nationalTeamNumber': nationalTeamNumber,
      if (knownClubNumbers.isNotEmpty) 'knownClubNumbers': knownClubNumbers,
      if (hints.isNotEmpty) 'hints': hints,
    };
  }
}
