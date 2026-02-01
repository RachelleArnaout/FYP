class Habit {
  String id;
  String name;
  String description;
  String lifeAreaId;
  String goalStatement;
  String valueAlignment;
  int targetFrequency; // times per week
  int durationMinutes;
  String difficultyLevel; // 'micro', 'easy', 'medium', 'challenging'
  bool isActive;
  DateTime createdAt;
  Map<String, bool> completionRecord; // date string -> completed
  int currentStreak;
  int longestStreak;
  String? reminderTime;
  bool isBuildingHabit; // true for building, false for letting go

  Habit({
    required this.id,
    required this.name,
    this.description = '',
    required this.lifeAreaId,
    this.goalStatement = '',
    this.valueAlignment = '',
    this.targetFrequency = 7,
    this.durationMinutes = 15,
    this.difficultyLevel = 'easy',
    this.isActive = true,
    DateTime? createdAt,
    Map<String, bool>? completionRecord,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.reminderTime,
    this.isBuildingHabit = true,
  })  : createdAt = createdAt ?? DateTime.now(),
        completionRecord = completionRecord ?? {};

  double getConsistencyRate(int days) {
    final now = DateTime.now();
    int completed = 0;
    int total = days;

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _dateKey(date);
      if (completionRecord[dateKey] == true) {
        completed++;
      }
    }

    return total > 0 ? completed / total : 0.0;
  }

  void markComplete(DateTime date) {
    completionRecord[_dateKey(date)] = true;
    _updateStreak();
  }

  void markIncomplete(DateTime date) {
    completionRecord[_dateKey(date)] = false;
    _updateStreak();
  }

  bool isCompletedOn(DateTime date) {
    return completionRecord[_dateKey(date)] ?? false;
  }

  void _updateStreak() {
    int streak = 0;
    final now = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      if (isCompletedOn(date)) {
        streak++;
      } else {
        break;
      }
    }

    currentStreak = streak;
    if (streak > longestStreak) {
      longestStreak = streak;
    }
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'lifeAreaId': lifeAreaId,
      'goalStatement': goalStatement,
      'valueAlignment': valueAlignment,
      'targetFrequency': targetFrequency,
      'durationMinutes': durationMinutes,
      'difficultyLevel': difficultyLevel,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'completionRecord': completionRecord,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'reminderTime': reminderTime,
      'isBuildingHabit': isBuildingHabit,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      lifeAreaId: json['lifeAreaId'],
      goalStatement: json['goalStatement'] ?? '',
      valueAlignment: json['valueAlignment'] ?? '',
      targetFrequency: json['targetFrequency'] ?? 7,
      durationMinutes: json['durationMinutes'] ?? 15,
      difficultyLevel: json['difficultyLevel'] ?? 'easy',
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      completionRecord: Map<String, bool>.from(json['completionRecord'] ?? {}),
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      reminderTime: json['reminderTime'],
      isBuildingHabit: json['isBuildingHabit'] ?? true,
    );
  }
}
