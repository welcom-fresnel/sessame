import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GamificationReward {
  final int xp;
  final int level;
  final String? unlockedBadge;

  const GamificationReward({
    required this.xp,
    required this.level,
    this.unlockedBadge,
  });
}

class GamificationProvider extends ChangeNotifier {
  static const _xpKey = 'game_xp';
  static const _completedTaskIdsKey = 'game_completed_task_ids';
  static const _activityDatesKey = 'game_activity_dates';
  static const _badgesKey = 'game_badges';

  int _xp = 0;
  final Set<String> _completedTaskIds = {};
  final Set<String> _activityDates = {};
  final Set<String> _badges = {};
  bool _isLoaded = false;

  int get xp => _xp;
  bool get isLoaded => _isLoaded;
  int get level => (_xp ~/ 100) + 1;
  int get xpInCurrentLevel => _xp % 100;
  double get levelProgress => xpInCurrentLevel / 100;
  int get completedTaskCount => _completedTaskIds.length;
  int get streak => _calculateStreak();

  GamificationProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _xp = prefs.getInt(_xpKey) ?? 0;
      _completedTaskIds.addAll(_readStringList(prefs.getString(_completedTaskIdsKey)));
      _activityDates.addAll(_readStringList(prefs.getString(_activityDatesKey)));
      _badges.addAll(_readStringList(prefs.getString(_badgesKey)));
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<GamificationReward?> rewardTaskCompletion(String taskId) async {
    if (_completedTaskIds.contains(taskId)) return null;

    final previousLevel = level;
    _completedTaskIds.add(taskId);
    _activityDates.add(_dateKey(DateTime.now()));

    final earnedXp = streak >= 3 ? 15 : 10;
    _xp += earnedXp;
    final badge = _unlockNextBadge();
    await _save();
    notifyListeners();

    return GamificationReward(
      xp: earnedXp,
      level: level,
      unlockedBadge: badge ?? (level > previousLevel ? 'Niveau $level atteint !' : null),
    );
  }

  String? _unlockNextBadge() {
    final candidates = <({String id, String label, bool unlocked})>[
      (id: 'first_step', label: 'Premier pas', unlocked: completedTaskCount >= 1),
      (id: 'focus_10', label: 'Focus x10', unlocked: completedTaskCount >= 10),
      (id: 'momentum_50', label: 'Élan x50', unlocked: completedTaskCount >= 50),
      (id: 'streak_7', label: 'Régulier 7 jours', unlocked: streak >= 7),
    ];
    for (final badge in candidates) {
      if (badge.unlocked && _badges.add(badge.id)) return badge.label;
    }
    return null;
  }

  int _calculateStreak() {
    var day = DateUtils.dateOnly(DateTime.now());
    if (!_activityDates.contains(_dateKey(day))) {
      day = day.subtract(const Duration(days: 1));
    }

    var count = 0;
    while (_activityDates.contains(_dateKey(day))) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_xpKey, _xp);
    await prefs.setString(_completedTaskIdsKey, jsonEncode(_completedTaskIds.toList()));
    await prefs.setString(_activityDatesKey, jsonEncode(_activityDates.toList()));
    await prefs.setString(_badgesKey, jsonEncode(_badges.toList()));
  }

  List<String> _readStringList(String? value) {
    if (value == null) return [];
    try {
      return (jsonDecode(value) as List).map((item) => item.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
