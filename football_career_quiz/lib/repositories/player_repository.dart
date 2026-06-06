import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/player_model.dart';

class PlayerRepository {
  static Future<List<PlayerModel>> loadPlayers() async {
    final jsonString = await rootBundle.loadString('assets/data/players.json');
    final decoded = jsonDecode(jsonString);

    if (decoded is! List) {
      throw Exception('players.json must contain a list of players');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(PlayerModel.fromJson)
        .where((player) => player.name.isNotEmpty && player.clubs.isNotEmpty)
        .toList();
  }
}
