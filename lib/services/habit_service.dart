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
    final response =
        await ApiClient.get('/habits/analytics/overview?days=$days');
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

  /// Generate AI habit suggestions based on user profile.
  static Future<AIGeneratedHabitsResponse> generateAIHabits({
    List<String>? focusAreas,
    int count = 5,
  }) async {
    final body = <String, dynamic>{
      'count': count,
    };
    if (focusAreas != null && focusAreas.isNotEmpty) {
      body['focusAreas'] = focusAreas;
    }
    final response = await ApiClient.post('/habits/ai/generate', body: body);
    final data = response['data'] as Map<String, dynamic>;
    return AIGeneratedHabitsResponse.fromJson(data);
  }

  /// Approve and save selected AI-generated habits.
  static Future<List<Habit>> approveAIHabits(
      List<Map<String, dynamic>> habits) async {
    final response = await ApiClient.post('/habits/ai/approve', body: {
      'habits': habits,
    });
    final data = response['data'] as List<dynamic>;
    return data.map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// A single AI-generated habit suggestion.
class AIGeneratedHabit {
  final String name;
  final String description;
  final String lifeAreaName;
  final String goalStatement;
  final String valueAlignment;
  final int targetFrequency;
  final int durationMinutes;
  final String difficultyLevel;
  final bool isBuildingHabit;
  final String reason;

  AIGeneratedHabit({
    required this.name,
    required this.description,
    required this.lifeAreaName,
    required this.goalStatement,
    required this.valueAlignment,
    required this.targetFrequency,
    required this.durationMinutes,
    required this.difficultyLevel,
    required this.isBuildingHabit,
    required this.reason,
  });

  factory AIGeneratedHabit.fromJson(Map<String, dynamic> json) {
    return AIGeneratedHabit(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      lifeAreaName: json['lifeAreaName'] ?? '',
      goalStatement: json['goalStatement'] ?? '',
      valueAlignment: json['valueAlignment'] ?? '',
      targetFrequency: json['targetFrequency'] ?? 7,
      durationMinutes: json['durationMinutes'] ?? 15,
      difficultyLevel: json['difficultyLevel'] ?? 'easy',
      isBuildingHabit: json['isBuildingHabit'] ?? true,
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'lifeAreaName': lifeAreaName,
      'goalStatement': goalStatement,
      'valueAlignment': valueAlignment,
      'targetFrequency': targetFrequency,
      'durationMinutes': durationMinutes,
      'difficultyLevel': difficultyLevel,
      'isBuildingHabit': isBuildingHabit,
      'reason': reason,
    };
  }
}

/// Response from the AI habit generation endpoint.
class AIGeneratedHabitsResponse {
  final List<AIGeneratedHabit> habits;
  final String summary;

  AIGeneratedHabitsResponse({
    required this.habits,
    required this.summary,
  });

  factory AIGeneratedHabitsResponse.fromJson(Map<String, dynamic> json) {
    return AIGeneratedHabitsResponse(
      habits: (json['habits'] as List<dynamic>)
          .map((e) => AIGeneratedHabit.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] ?? '',
    );
  }
}
