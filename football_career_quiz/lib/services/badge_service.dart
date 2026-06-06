import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/badge_overrides.dart';
import '../data/generated_badge_overrides.dart';

class BadgeService {
  BadgeService._();

  static final Map<String, String> _memoryCache = {};

  static const Map<String, String> _searchNameOverrides = {
    'Manchester United': 'Manchester United',
    'Manchester City': 'Manchester City',
    'Real Madrid': 'Real Madrid',
    'Barcelona': 'Barcelona',
    'Bayern Munich': 'Bayern Munich',
    'Inter Milan': 'Inter Milan',
    'AC Milan': 'AC Milan',
    'PSG': 'Paris Saint-Germain',
    'Paris Saint-Germain': 'Paris Saint-Germain',
    'Paris Saint Germain': 'Paris Saint-Germain',
    'Sporting CP': 'Sporting Lisbon',
    'Al Nassr': 'Al-Nassr',
    'Al Hilal': 'Al-Hilal',
    'Borussia Dortmund': 'Borussia Dortmund',
    'Atletico Madrid': 'Atletico Madrid',
    'Atlético Madrid': 'Atletico Madrid',
    'Inter Miami': 'Inter Miami',
    'LA Galaxy': 'LA Galaxy',
    'Association sportive de Monaco Football Club': 'Monaco',
    'Paris Saint-Germain Football Club': 'Paris Saint-Germain',
  };

  static String _normalizeClubName(String value) {
    var text = value.trim().toLowerCase();

    text = text
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('í', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('&', 'and')
        .replaceAll('-', ' ');

    text = text.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');

    final removableWords = [
      'football club',
      'fc',
      'cf',
      'afc',
      'sc',
      'ac',
      'as',
      'rc',
      'club',
      'football',
      'association sportive de',
      'association sportive',
      'sporting club',
      'deportivo',
      'real club deportivo',
    ];

    for (final word in removableWords) {
      text = text.replaceAll(word, ' ');
    }

    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  static String? _findInMap(
    String clubName,
    Map<String, String> source,
  ) {
    final exact = source[clubName];
    if (exact != null && exact.trim().isNotEmpty) {
      return exact;
    }

    final normalizedClubName = _normalizeClubName(clubName);

    for (final entry in source.entries) {
      final normalizedKey = _normalizeClubName(entry.key);

      if (normalizedKey == normalizedClubName &&
          entry.value.trim().isNotEmpty) {
        return entry.value;
      }
    }

    for (final entry in source.entries) {
      final normalizedKey = _normalizeClubName(entry.key);

      if (normalizedClubName.contains(normalizedKey) &&
          normalizedKey.length >= 4 &&
          entry.value.trim().isNotEmpty) {
        return entry.value;
      }

      if (normalizedKey.contains(normalizedClubName) &&
          normalizedClubName.length >= 4 &&
          entry.value.trim().isNotEmpty) {
        return entry.value;
      }
    }

    return null;
  }

  static String? _findManualBadge(String clubName) {
    final overrideName = _searchNameOverrides[clubName];

    if (overrideName != null) {
      final fromManualOverride = _findInMap(overrideName, badgeOverrides);
      if (fromManualOverride != null) return fromManualOverride;

      final fromGeneratedOverride =
          _findInMap(overrideName, generatedBadgeOverrides);
      if (fromGeneratedOverride != null) return fromGeneratedOverride;
    }

    final fromManual = _findInMap(clubName, badgeOverrides);
    if (fromManual != null) return fromManual;

    final fromGenerated = _findInMap(clubName, generatedBadgeOverrides);
    if (fromGenerated != null) return fromGenerated;

    return null;
  }

  static Future<String?> getBadgeUrl(String clubName) async {
    final manualBadge = _findManualBadge(clubName);

    if (manualBadge != null && manualBadge.trim().isNotEmpty) {
      return manualBadge;
    }

    final cached = _memoryCache[clubName];
    if (cached != null) return cached.isEmpty ? null : cached;

    final searchName = _searchNameOverrides[clubName] ?? clubName;

    try {
      final uri = Uri.parse(
        'https://www.thesportsdb.com/api/v1/json/3/searchteams.php?t=${Uri.encodeComponent(searchName)}',
      );

      final response = await http.get(uri).timeout(
            const Duration(seconds: 8),
          );

      if (response.statusCode != 200) {
        _memoryCache[clubName] = '';
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final teams = decoded['teams'];

      if (teams == null || teams is! List || teams.isEmpty) {
        _memoryCache[clubName] = '';
        return null;
      }

      final soccerTeams = teams.where((team) {
        if (team is! Map<String, dynamic>) return false;

        final sport = team['strSport']?.toString().toLowerCase() ?? '';
        return sport == 'soccer';
      }).toList();

      final selectedTeam =
          soccerTeams.isNotEmpty ? soccerTeams.first : teams.first;

      if (selectedTeam is! Map<String, dynamic>) {
        _memoryCache[clubName] = '';
        return null;
      }

      final badgeUrl = selectedTeam['strBadge']?.toString();

      if (badgeUrl == null || badgeUrl.trim().isEmpty) {
        _memoryCache[clubName] = '';
        return null;
      }

      _memoryCache[clubName] = badgeUrl;
      return badgeUrl;
    } catch (_) {
      _memoryCache[clubName] = '';
      return null;
    }
  }
}
