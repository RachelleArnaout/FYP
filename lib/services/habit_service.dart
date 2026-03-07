import '../models/habit.dart';
import 'api_client.dart';

class HabitService {
  /// Get all habits for the current user.
  static Future<List<Habit>> getAll() async {
    final response = await ApiClient.get('/habits');
    final data = response['data'] as List<dynamic>;
    return data.map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get only active habits.
  static Future<List<Habit>> getActive() async {
    final response = await ApiClient.get('/habits/active');
    final data = response['data'] as List<dynamic>;
    return data.map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get habits for a specific life area.
  static Future<List<Habit>> getByLifeArea(String lifeAreaId) async {
    final response = await ApiClient.get('/habits/life-area/$lifeAreaId');
    final data = response['data'] as List<dynamic>;
    return data.map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get a single habit by ID.
  static Future<Habit> getById(String id) async {
    final response = await ApiClient.get('/habits/$id');
    final data = response['data'] as Map<String, dynamic>;
    return Habit.fromJson(data);
  }

  /// Create a new habit.
  static Future<Habit> create(Habit habit) async {
    final response = await ApiClient.post('/habits', body: {
      'name': habit.name,
      'description': habit.description,
      'lifeAreaId': habit.lifeAreaId,
      'goalStatement': habit.goalStatement,
      'valueAlignment': habit.valueAlignment,
      'targetFrequency': habit.targetFrequency,
      'durationMinutes': habit.durationMinutes,
      'difficultyLevel': habit.difficultyLevel,
      'isActive': habit.isActive,
      'reminderTime': habit.reminderTime,
      'isBuildingHabit': habit.isBuildingHabit,
    });
    final data = response['data'] as Map<String, dynamic>;
    return Habit.fromJson(data);
  }

  /// Update an existing habit.
  static Future<Habit> update(String id, Habit habit) async {
    final response = await ApiClient.put('/habits/$id', body: {
      'name': habit.name,
      'description': habit.description,
      'lifeAreaId': habit.lifeAreaId,
      'goalStatement': habit.goalStatement,
      'valueAlignment': habit.valueAlignment,
      'targetFrequency': habit.targetFrequency,
      'durationMinutes': habit.durationMinutes,
      'difficultyLevel': habit.difficultyLevel,
      'isActive': habit.isActive,
      'reminderTime': habit.reminderTime,
      'isBuildingHabit': habit.isBuildingHabit,
    });
    final data = response['data'] as Map<String, dynamic>;
    return Habit.fromJson(data);
  }

  /// Delete a habit.
  static Future<void> delete(String id) async {
    await ApiClient.delete('/habits/$id');
  }

  /// Toggle habit completion for a specific date.
  static Future<Habit> toggleCompletion(
    String id, {
    required String date,
    required bool completed,
  }) async {
    final response = await ApiClient.patch('/habits/$id/completion', body: {
      'date': date,
      'completed': completed,
    });
    final data = response['data'] as Map<String, dynamic>;
    return Habit.fromJson(data);
  }

  /// Get analytics overview.
  static Future<Map<String, dynamic>> getAnalytics({int days = 30}) async {
    final response = await ApiClient.get('/habits/analytics/overview?days=$days');
    return response['data'] as Map<String, dynamic>;
  }

  /// Get consistency for a specific habit.
  static Future<Map<String, dynamic>> getConsistency(
    String id, {
    int days = 30,
  }) async {
    final response = await ApiClient.get('/habits/$id/consistency?days=$days');
    return response['data'] as Map<String, dynamic>;
  }
}
