import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/life_area.dart';
import '../models/habit.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/life_area_service.dart';
import '../services/habit_service.dart';

class AppState extends ChangeNotifier {
  UserProfile _userProfile = UserProfile();
  List<LifeArea> _lifeAreas = [];
  List<Habit> _habits = [];
  bool _isOnboarded = false;
  int _currentOnboardingStep = 0;
  bool _isLoggedIn = false;
  String _userEmail = '';
  String _userName = '';
  String? _userId;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  bool _isMongoObjectId(String value) {
    final objectIdRegex = RegExp(r'^[a-fA-F0-9]{24}$');
    return objectIdRegex.hasMatch(value);
  }

  UserProfile get userProfile => _userProfile;
  List<LifeArea> get lifeAreas => _lifeAreas;
  List<LifeArea> get activeLifeAreas =>
      _lifeAreas.where((area) => area.isActive).toList();
  List<Habit> get habits => _habits;
  List<Habit> get activeHabits =>
      _habits.where((habit) => habit.isActive).toList();
  bool get isOnboarded => _isOnboarded;
  int get currentOnboardingStep => _currentOnboardingStep;
  bool get isLoggedIn => _isLoggedIn;
  String get userEmail => _userEmail;
  String get userName => _userName;
  String? get userId => _userId;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  AppState() {
    _initialize();
  }

  /// Initialize app state — check for existing token and load user data.
  Future<void> _initialize() async {
    try {
      await ApiClient.loadToken();
      if (ApiClient.token != null) {
        await _loadUserData();
      }
    } catch (e) {
      // Token invalid or expired — clear and show login
      await ApiClient.clearToken();
      _isLoggedIn = false;
    }
    _isInitialized = true;
    notifyListeners();
  }

  /// Load all user data from the backend (user info, profile, life areas, habits).
  Future<void> _loadUserData() async {
    final userData = await AuthService.getMe();
    _userId = userData['id'];
    _userName = userData['name'] ?? '';
    _userEmail = userData['email'] ?? '';
    _isOnboarded = userData['isOnboarded'] ?? false;
    _isLoggedIn = true;

    if (_isOnboarded) {
      await _loadOnboardedData();
    }
  }

  /// Load profile, life areas, and habits for an onboarded user.
  Future<void> _loadOnboardedData() async {
    try {
      final results = await Future.wait([
        ProfileService.getProfile(),
        LifeAreaService.getAll(),
        HabitService.getAll(),
      ]);
      _userProfile = results[0] as UserProfile;
      _lifeAreas = results[1] as List<LifeArea>;
      _habits = results[2] as List<Habit>;
    } catch (e) {
      // If profile doesn't exist yet, use defaults
      _userProfile = UserProfile();
      _lifeAreas = [];
      _habits = [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setAuthState({
    required bool isLoggedIn,
    required bool isOnboarded,
    String? userId,
    String? userName,
    String? userEmail,
  }) {
    _isLoggedIn = isLoggedIn;
    _isOnboarded = isOnboarded;
    _userId = userId;
    _userName = userName ?? _userName;
    _userEmail = userEmail ?? _userEmail;
    notifyListeners();
  }

  // ─── Auth Methods ──────────────────────────────────────────────────────────

  Future<bool> signup(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await AuthService.register(
        name: name,
        email: email,
        password: password,
      );
      final user = data['user'] as Map<String, dynamic>;
      setAuthState(
        isLoggedIn: true,
        isOnboarded: user['isOnboarded'] ?? false,
        userId: user['id'],
        userName: user['name'] ?? name,
        userEmail: user['email'] ?? email,
      );
      _lifeAreas = [];
      _habits = [];
      _userProfile = UserProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection failed. Please check your network.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await AuthService.login(email: email, password: password);
      final user = data['user'] as Map<String, dynamic>;
      setAuthState(
        isLoggedIn: true,
        isOnboarded: user['isOnboarded'] ?? false,
        userId: user['id'],
        userName: user['name'] ?? '',
        userEmail: user['email'] ?? email,
      );

      if (_isOnboarded) {
        await _loadOnboardedData();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection failed. Please check your network.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _userProfile = UserProfile();
    _lifeAreas = [];
    _habits = [];
    _currentOnboardingStep = 0;
    setAuthState(
      isLoggedIn: false,
      isOnboarded: false,
      userId: null,
      userName: '',
      userEmail: '',
    );
  }

  // ─── Profile Methods ───────────────────────────────────────────────────────

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      _userProfile = await ProfileService.updateProfile(profile);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      // Optimistic update — keep local copy
      _userProfile = profile;
      notifyListeners();
    }
  }

  // ─── Life Area Methods ─────────────────────────────────────────────────────

  Future<void> loadLifeAreas() async {
    try {
      _lifeAreas = await LifeAreaService.getAll();
      notifyListeners();
    } catch (e) {
      // Keep existing data
    }
  }

  void updateLifeArea(LifeArea area) {
    final index = _lifeAreas.indexWhere((a) => a.id == area.id);
    if (index != -1) {
      _lifeAreas[index] = area;
      notifyListeners();
      // Fire-and-forget backend update
      LifeAreaService.update(area.id, area).ignore();
    }
  }

  Future<void> toggleLifeArea(String id) async {
    // Optimistic local toggle
    final index = _lifeAreas.indexWhere((a) => a.id == id);
    if (index != -1) {
      _lifeAreas[index].isActive = !_lifeAreas[index].isActive;
      notifyListeners();
    }

    // Local fallback areas use non-ObjectId keys (e.g. "academic").
    // Keep onboarding selection working locally in that case.
    if (!_isMongoObjectId(id)) {
      return;
    }

    try {
      final updated = await LifeAreaService.toggleActive(id);
      if (index != -1) {
        _lifeAreas[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      // Revert on error
      if (index != -1) {
        _lifeAreas[index].isActive = !_lifeAreas[index].isActive;
        notifyListeners();
      }
    }
  }

  /// Create default life areas on the backend for a new user during onboarding.
  Future<void> createDefaultLifeAreas() async {
    if (_lifeAreas.isNotEmpty) {
      return;
    }

    try {
      final existing = await LifeAreaService.getAll();
      if (existing.isNotEmpty) {
        _lifeAreas = existing;
        notifyListeners();
        return;
      }
    } catch (e) {
      // Recover from duplicates/races by reloading backend before local fallback.
      try {
        final existing = await LifeAreaService.getAll();
        if (existing.isNotEmpty) {
          _lifeAreas = existing;
          notifyListeners();
          return;
        }
      } catch (_) {
        // Ignore and keep local fallback below.
      }
    }
  }

  // ─── Habit Methods ─────────────────────────────────────────────────────────

  Future<void> addHabit(Habit habit) async {
    try {
      final created = await HabitService.create(habit);
      _habits.add(created);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateHabit(Habit habit) async {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      try {
        final updated = await HabitService.update(habit.id, habit);
        _habits[index] = updated;
        notifyListeners();
      } on ApiException catch (e) {
        _error = e.message;
        notifyListeners();
      }
    }
  }

  Future<void> deleteHabit(String id) async {
    final index = _habits.indexWhere((h) => h.id == id);
    final backup = index != -1 ? _habits[index] : null;

    _habits.removeWhere((h) => h.id == id);
    notifyListeners();

    try {
      await HabitService.delete(id);
    } catch (e) {
      // Revert on error
      if (backup != null) {
        _habits.insert(index, backup);
        notifyListeners();
      }
    }
  }

  Future<void> toggleHabitCompletion(String habitId, DateTime date) async {
    final habit = _habits.firstWhere((h) => h.id == habitId);
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final wasCompleted = habit.isCompletedOn(date);

    // Optimistic local toggle
    if (wasCompleted) {
      habit.markIncomplete(date);
    } else {
      habit.markComplete(date);
    }
    notifyListeners();

    try {
      final updated = await HabitService.toggleCompletion(
        habitId,
        date: dateKey,
        completed: !wasCompleted,
      );
      final index = _habits.indexWhere((h) => h.id == habitId);
      if (index != -1) {
        _habits[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      // Revert on error
      if (wasCompleted) {
        habit.markComplete(date);
      } else {
        habit.markIncomplete(date);
      }
      notifyListeners();
    }
  }

  // ─── Onboarding Methods ────────────────────────────────────────────────────

  Future<bool> completeOnboarding() async {
    try {
      await AuthService.completeOnboarding();
      _isOnboarded = true;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to complete onboarding. Please try again.';
      notifyListeners();
      return false;
    }
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

  // ─── Analytics Methods ─────────────────────────────────────────────────────

  /// Get consistency for a single day (what fraction of active habits were completed).
  double getDailyConsistency(DateTime date) {
    final active = _habits.where((h) => h.isActive).toList();
    if (active.isEmpty) return 0.0;

    int completed = 0;
    for (var habit in active) {
      if (habit.isCompletedOn(date)) completed++;
    }
    return completed / active.length;
  }

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

    final activeHabitsList = _habits.where((h) => h.isActive).toList();
    if (activeHabitsList.isEmpty) return 0.0;

    double total = 0.0;
    for (var habit in activeHabitsList) {
      total += habit.getConsistencyRate(days);
    }

    return total / activeHabitsList.length;
  }

  /// Get per-life-area stats: completed, total possible, habit count.
  Map<String, Map<String, int>> getLifeAreaStats(int days) {
    final result = <String, Map<String, int>>{};
    final now = DateTime.now();

    for (var area in _lifeAreas) {
      if (!area.isActive) continue;

      final areaHabits =
          _habits.where((h) => h.lifeAreaId == area.id && h.isActive).toList();
      int completed = 0;
      int total = areaHabits.length * days;

      for (var habit in areaHabits) {
        for (int i = 0; i < days; i++) {
          final date = now.subtract(Duration(days: i));
          if (habit.isCompletedOn(date)) completed++;
        }
      }

      result[area.id] = {
        'completed': completed,
        'total': total,
        'habitCount': areaHabits.length,
      };
    }

    return result;
  }

  /// Total time allocated to active habits per day (in minutes).
  int get totalHabitMinutesPerDay {
    return activeHabits.fold(0, (sum, h) => sum + h.durationMinutes);
  }

  /// Refresh all data from the backend.
  Future<void> refreshData() async {
    if (!_isLoggedIn) return;
    try {
      await _loadOnboardedData();
      notifyListeners();
    } catch (e) {
      // Silently fail — keep existing data
    }
  }
}
