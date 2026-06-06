class ClubModel {
  final String name;
  final String country;
  final String badgeUrl;

  const ClubModel({
    required this.name,
    required this.country,
    this.badgeUrl = '',
  });

  String get displayName => '$name ($country)';

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    return ClubModel(
      name: json['name']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      badgeUrl: json['badgeUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'badgeUrl': badgeUrl,
    };
  }
}
