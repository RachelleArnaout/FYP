import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';
import '../models/life_area.dart';
import '../models/habit.dart';

class AppState extends ChangeNotifier {
  UserProfile _userProfile = UserProfile();
  List<LifeArea> _lifeAreas = LifeArea.getDefaultAreas();
  List<Habit> _habits = [];
  bool _isOnboarded = false;
  int _currentOnboardingStep = 0;

  UserProfile get userProfile => _userProfile;
  List<LifeArea> get lifeAreas => _lifeAreas;
  List<LifeArea> get activeLifeAreas =>
      _lifeAreas.where((area) => area.isActive).toList();
  List<Habit> get habits => _habits;
  List<Habit> get activeHabits =>
      _habits.where((habit) => habit.isActive).toList();
  bool get isOnboarded => _isOnboarded;
  int get currentOnboardingStep => _currentOnboardingStep;

  AppState() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _isOnboarded = prefs.getBool('isOnboarded') ?? false;

    if (_isOnboarded) {
      final profileJson = prefs.getString('userProfile');
      if (profileJson != null) {
        _userProfile = UserProfile.fromJson(json.decode(profileJson));
      }

      final areasJson = prefs.getString('lifeAreas');
      if (areasJson != null) {
        final List<dynamic> areasList = json.decode(areasJson);
        _lifeAreas = areasList.map((area) => LifeArea.fromJson(area)).toList();
      }

      final habitsJson = prefs.getString('habits');
      if (habitsJson != null) {
        final List<dynamic> habitsList = json.decode(habitsJson);
        _habits = habitsList.map((habit) => Habit.fromJson(habit)).toList();
      }
    }

    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userProfile', json.encode(_userProfile.toJson()));
    await prefs.setString(
        'lifeAreas', json.encode(_lifeAreas.map((a) => a.toJson()).toList()));
    await prefs.setString(
        'habits', json.encode(_habits.map((h) => h.toJson()).toList()));
    await prefs.setBool('isOnboarded', _isOnboarded);
  }

  void updateUserProfile(UserProfile profile) {
    _userProfile = profile;
    _saveData();
    notifyListeners();
  }

  void updateLifeArea(LifeArea area) {
    final index = _lifeAreas.indexWhere((a) => a.id == area.id);
    if (index != -1) {
      _lifeAreas[index] = area;
      _saveData();
      notifyListeners();
    }
  }

  void toggleLifeArea(String id) {
    final area = _lifeAreas.firstWhere((a) => a.id == id);
    area.isActive = !area.isActive;
    _saveData();
    notifyListeners();
  }

  void addHabit(Habit habit) {
    _habits.add(habit);
    _saveData();
    notifyListeners();
  }

  void updateHabit(Habit habit) {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      _habits[index] = habit;
      _saveData();
      notifyListeners();
    }
  }

  void deleteHabit(String id) {
    _habits.removeWhere((h) => h.id == id);
    _saveData();
    notifyListeners();
  }

  void toggleHabitCompletion(String habitId, DateTime date) {
    final habit = _habits.firstWhere((h) => h.id == habitId);
    if (habit.isCompletedOn(date)) {
      habit.markIncomplete(date);
    } else {
      habit.markComplete(date);
    }
    _saveData();
    notifyListeners();
  }

  void completeOnboarding() {
    _isOnboarded = true;
    _saveData();
    notifyListeners();
  }

  void setOnboardingStep(int step) {
    _currentOnboardingStep = step;
    notifyListeners();
  }

  void nextOnboardingStep() {
    _currentOnboardingStep++;
    notifyListeners();
  }

  void previousOnboardingStep() {
    if (_currentOnboardingStep > 0) {
      _currentOnboardingStep--;
      notifyListeners();
    }
  }

  // Analytics methods
  Map<String, int> getLifeAreaCompletionCounts(int days) {
    final counts = <String, int>{};
    final now = DateTime.now();

    for (var habit in _habits) {
      if (!habit.isActive) continue;

      int completed = 0;
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        if (habit.isCompletedOn(date)) {
          completed++;
        }
      }

      counts[habit.lifeAreaId] = (counts[habit.lifeAreaId] ?? 0) + completed;
    }

    return counts;
  }

  double getOverallConsistency(int days) {
    if (_habits.isEmpty) return 0.0;

    double total = 0.0;
    for (var habit in _habits.where((h) => h.isActive)) {
      total += habit.getConsistencyRate(days);
    }

    return total / _habits.where((h) => h.isActive).length;
  }
}
