import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/life_area.dart';
import '../services/habit_service.dart';
import '../services/api_client.dart';

class AIHabitsScreen extends StatefulWidget {
  const AIHabitsScreen({super.key});

  @override
  State<AIHabitsScreen> createState() => _AIHabitsScreenState();
}

class _AIHabitsScreenState extends State<AIHabitsScreen>
    with SingleTickerProviderStateMixin {
  // State
  bool _isGenerating = false;
  bool _isApproving = false;
  String? _error;
  AIGeneratedHabitsResponse? _response;
  final Set<int> _selectedIndices = {};
  final Map<int, _EditableHabit> _editedHabits = {};

  // Animation
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _isGenerating = true;
      _error = null;
      _response = null;
      _selectedIndices.clear();
      _editedHabits.clear();
    });

    try {
      final result = await HabitService.generateAIHabits(count: 5);
      setState(() {
        _response = result;
        // Pre-select all habits
        for (int i = 0; i < result.habits.length; i++) {
          _selectedIndices.add(i);
        }
        _isGenerating = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to generate habits. Please try again.';
        _isGenerating = false;
      });
    }
  }

  Future<void> _approveSelected() async {
    if (_selectedIndices.isEmpty) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final lifeAreas = appState.lifeAreas;

    setState(() {
      _isApproving = true;
      _error = null;
    });

    try {
      final habitsToApprove = <Map<String, dynamic>>[];

      for (final index in _selectedIndices) {
        final original = _response!.habits[index];
        final edited = _editedHabits[index];

        final name = edited?.name ?? original.name;
        final description = edited?.description ?? original.description;
        final goalStatement = edited?.goalStatement ?? original.goalStatement;
        final areaName = edited?.lifeAreaName ?? original.lifeAreaName;
        final targetFrequency =
            edited?.targetFrequency ?? original.targetFrequency;
        final durationMinutes =
            edited?.durationMinutes ?? original.durationMinutes;
        final difficultyLevel =
            edited?.difficultyLevel ?? original.difficultyLevel;

        // Map life area name to ID
        final area = lifeAreas.cast<LifeArea?>().firstWhere(
              (a) => a!.name == areaName,
              orElse: () => lifeAreas.isNotEmpty ? lifeAreas.first : null,
            );

        if (area == null) continue;

        habitsToApprove.add({
          'name': name,
          'description': description,
          'lifeAreaId': area.id,
          'goalStatement': goalStatement,
          'valueAlignment': edited?.valueAlignment ?? original.valueAlignment,
          'targetFrequency': targetFrequency,
          'durationMinutes': durationMinutes,
          'difficultyLevel': difficultyLevel,
          'isBuildingHabit': original.isBuildingHabit,
        });
      }

      if (habitsToApprove.isEmpty) {
        setState(() {
          _error = 'No valid habits to approve.';
          _isApproving = false;
        });
        return;
      }

      final created = await HabitService.approveAIHabits(habitsToApprove);

      // Update local state
      for (final habit in created) {
        appState.habits.add(habit);
      }
      appState.refreshData();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${created.length} habit${created.length > 1 ? 's' : ''} added!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isApproving = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to save habits. Please try again.';
        _isApproving = false;
      });
    }
  }

  void _toggleSelect(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIndices.length == _response!.habits.length) {
        _selectedIndices.clear();
      } else {
        _selectedIndices.clear();
        for (int i = 0; i < _response!.habits.length; i++) {
          _selectedIndices.add(i);
        }
      }
    });
  }

  void _removeHabit(int index) {
    setState(() {
      _selectedIndices.remove(index);
      _editedHabits.remove(index);
      _response!.habits.removeAt(index);

      // Rebuild indices
      final newSelected = <int>{};
      final newEdited = <int, _EditableHabit>{};
      for (final i in _selectedIndices) {
        newSelected.add(i > index ? i - 1 : i);
      }
      for (final entry in _editedHabits.entries) {
        final newKey = entry.key > index ? entry.key - 1 : entry.key;
        newEdited[newKey] = entry.value;
      }
      _selectedIndices
        ..clear()
        ..addAll(newSelected);
      _editedHabits
        ..clear()
        ..addAll(newEdited);
    });
  }

  void _editHabit(int index) {
    final habit = _response!.habits[index];
    final existing = _editedHabits[index];
    final appState = Provider.of<AppState>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditHabitSheet(
        habit: habit,
        edited: existing,
        lifeAreas: appState.activeLifeAreas,
        onSave: (edited) {
          setState(() {
            _editedHabits[index] = edited;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('AI Habit Generator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
        actions: [
          if (_response != null && _response!.habits.isNotEmpty)
            TextButton.icon(
              onPressed: _selectAll,
              icon: Icon(
                _selectedIndices.length == _response!.habits.length
                    ? Icons.deselect
                    : Icons.select_all,
                size: 20,
              ),
              label: Text(
                _selectedIndices.length == _response!.habits.length
                    ? 'Deselect'
                    : 'Select All',
              ),
            ),
        ],
      ),
      body: _isGenerating
          ? _buildLoadingState()
          : _response == null
              ? _buildInitialState()
              : _buildResultsState(),
      bottomNavigationBar: _response != null && _response!.habits.isNotEmpty
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Hero illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Generate Smart Habits',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Our AI analyzes your profile, values, energy patterns, and lifestyle to suggest personalized habits that fit your life.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // Feature pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildFeaturePill(Icons.psychology, 'Profile-based'),
              _buildFeaturePill(Icons.favorite, 'Value-aligned'),
              _buildFeaturePill(Icons.bolt, 'Energy-aware'),
              _buildFeaturePill(Icons.tune, 'Customizable'),
            ],
          ),
          const SizedBox(height: 40),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.auto_awesome, size: 22),
              label: const Text(
                'Generate My Habits',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6366F1)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1)
                          .withOpacity(0.6 + 0.4 * _shimmerController.value),
                      const Color(0xFF8B5CF6).withOpacity(
                          0.6 + 0.4 * (1 - _shimmerController.value)),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Analyzing your profile...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crafting personalized habits just for you',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsState() {
    if (_response!.habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No habits generated'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generate,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary card
        if (_response!.summary.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.08),
                  const Color(0xFF8B5CF6).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFF6366F1).withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: Color(0xFF6366F1), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _response!.summary,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: TextStyle(color: Colors.red[700], fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        // Selection info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_selectedIndices.length} of ${_response!.habits.length} selected',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Regenerate'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        // Habits list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _response!.habits.length,
            itemBuilder: (context, index) {
              return _buildHabitCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHabitCard(int index) {
    final habit = _response!.habits[index];
    final edited = _editedHabits[index];
    final isSelected = _selectedIndices.contains(index);

    final displayName = edited?.name ?? habit.name;
    final displayDesc = edited?.description ?? habit.description;
    final displayArea = edited?.lifeAreaName ?? habit.lifeAreaName;
    final displayDuration = edited?.durationMinutes ?? habit.durationMinutes;
    final displayDifficulty = edited?.difficultyLevel ?? habit.difficultyLevel;
    final displayFreq = edited?.targetFrequency ?? habit.targetFrequency;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF6366F1).withOpacity(0.1)
                : Colors.black.withOpacity(0.04),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggleSelect(index),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Title & area
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF6366F1).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  displayArea,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                              if (edited != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Edited',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.amber[700],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert,
                          size: 20, color: Colors.grey[400]),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Remove',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') _editHabit(index);
                        if (value == 'delete') _removeHabit(index);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Description
                if (displayDesc.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: Text(
                      displayDesc,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                // Meta chips
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildMetaChip(
                          Icons.timer_outlined, '${displayDuration}min'),
                      _buildMetaChip(
                          Icons.calendar_today_outlined, '${displayFreq}x/wk'),
                      _buildMetaChip(
                        Icons.signal_cellular_alt,
                        displayDifficulty[0].toUpperCase() +
                            displayDifficulty.substring(1),
                      ),
                      if (!habit.isBuildingHabit)
                        _buildMetaChip(Icons.block, 'Breaking',
                            isWarning: true),
                    ],
                  ),
                ),
                // Reason
                if (habit.reason.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 14, color: Colors.amber[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              habit.reason,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isWarning ? Colors.orange[50] : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: isWarning ? Colors.orange[700] : Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isWarning ? Colors.orange[700] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _selectedIndices.isEmpty || _isApproving
              ? null
              : _approveSelected,
          icon: _isApproving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle_outline, size: 22),
          label: Text(
            _isApproving
                ? 'Adding Habits...'
                : 'Add ${_selectedIndices.length} Habit${_selectedIndices.length != 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF6366F1).withOpacity(0.4),
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

// ─── Editable Habit Data ─────────────────────────────────────────────────────

class _EditableHabit {
  String? name;
  String? description;
  String? lifeAreaName;
  String? goalStatement;
  String? valueAlignment;
  int? targetFrequency;
  int? durationMinutes;
  String? difficultyLevel;

  _EditableHabit({
    this.name,
    this.description,
    this.lifeAreaName,
    this.goalStatement,
    this.valueAlignment,
    this.targetFrequency,
    this.durationMinutes,
    this.difficultyLevel,
  });
}

// ─── Edit Habit Bottom Sheet ─────────────────────────────────────────────────

class _EditHabitSheet extends StatefulWidget {
  final AIGeneratedHabit habit;
  final _EditableHabit? edited;
  final List<dynamic> lifeAreas;
  final ValueChanged<_EditableHabit> onSave;

  const _EditHabitSheet({
    required this.habit,
    required this.edited,
    required this.lifeAreas,
    required this.onSave,
  });

  @override
  State<_EditHabitSheet> createState() => _EditHabitSheetState();
}

class _EditHabitSheetState extends State<_EditHabitSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _goalController;
  late String _selectedArea;
  late int _duration;
  late int _frequency;
  late String _difficulty;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.edited?.name ?? widget.habit.name);
    _descController = TextEditingController(
        text: widget.edited?.description ?? widget.habit.description);
    _goalController = TextEditingController(
        text: widget.edited?.goalStatement ?? widget.habit.goalStatement);
    _selectedArea = widget.edited?.lifeAreaName ?? widget.habit.lifeAreaName;
    _duration = widget.edited?.durationMinutes ?? widget.habit.durationMinutes;
    _frequency = widget.edited?.targetFrequency ?? widget.habit.targetFrequency;
    _difficulty =
        widget.edited?.difficultyLevel ?? widget.habit.difficultyLevel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Text(
                  'Edit Habit',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
          const Divider(),
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Habit Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _goalController,
                    decoration: InputDecoration(
                      labelText: 'Goal Statement',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue:
                        widget.lifeAreas.any((a) => a.name == _selectedArea)
                            ? _selectedArea
                            : null,
                    decoration: InputDecoration(
                      labelText: 'Life Area',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: widget.lifeAreas.map((area) {
                      return DropdownMenuItem(
                        value: area.name as String,
                        child: Row(
                          children: [
                            Text(area.icon),
                            const SizedBox(width: 8),
                            Text(area.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedArea = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Duration',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _duration.toDouble(),
                          min: 5,
                          max: 120,
                          divisions: 23,
                          label: '$_duration min',
                          activeColor: const Color(0xFF6366F1),
                          onChanged: (v) =>
                              setState(() => _duration = v.round()),
                        ),
                      ),
                      SizedBox(
                        width: 55,
                        child: Text('$_duration min',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Frequency (days/week)',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _frequency.toDouble(),
                          min: 1,
                          max: 7,
                          divisions: 6,
                          label: '$_frequency days',
                          activeColor: const Color(0xFF6366F1),
                          onChanged: (v) =>
                              setState(() => _frequency = v.round()),
                        ),
                      ),
                      SizedBox(
                        width: 55,
                        child: Text('$_frequency/wk',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Difficulty',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'micro', label: Text('Micro')),
                      ButtonSegment(value: 'easy', label: Text('Easy')),
                      ButtonSegment(value: 'medium', label: Text('Med')),
                      ButtonSegment(value: 'challenging', label: Text('Hard')),
                    ],
                    selected: {_difficulty},
                    onSelectionChanged: (s) =>
                        setState(() => _difficulty = s.first),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSave(_EditableHabit(
                          name: _nameController.text,
                          description: _descController.text,
                          goalStatement: _goalController.text,
                          lifeAreaName: _selectedArea,
                          valueAlignment: widget.habit.valueAlignment,
                          durationMinutes: _duration,
                          targetFrequency: _frequency,
                          difficultyLevel: _difficulty,
                        ));
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).viewInsets.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
