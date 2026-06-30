import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/habit.dart';
import '../models/life_area.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? habit;
  const AddHabitScreen({super.key, this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalController = TextEditingController();

  String? _selectedLifeAreaId;
  String? _selectedValue;
  int _durationMinutes = 15;
  String _difficulty = 'easy';

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    if (habit != null) {
      _nameController.text = habit.name;
      _descriptionController.text = habit.description;
      _goalController.text = habit.goalStatement;
      _selectedLifeAreaId = habit.lifeAreaId;
      _selectedValue =
          habit.valueAlignment.isNotEmpty ? habit.valueAlignment : null;
      _durationMinutes = habit.durationMinutes;
      _difficulty = habit.difficultyLevel;
    }
  }

  Widget _buildTimeBudgetIndicator(AppState appState) {
    final dailyGoal = appState.userProfile.dailyFreeTime;
    final currentlyAllocated = appState.totalHabitMinutesPerDay;
    final afterAdding = currentlyAllocated + _durationMinutes;
    final remaining = dailyGoal - afterAdding;
    final ratio =
        dailyGoal > 0 ? (afterAdding / dailyGoal).clamp(0.0, 1.0) : 0.0;
    final isOver = afterAdding > dailyGoal;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOver
            ? Colors.orange.withOpacity(0.08)
            : const Color(0xFF6366F1).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOver
              ? Colors.orange.withOpacity(0.3)
              : const Color(0xFF6366F1).withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule,
                  size: 16,
                  color: isOver ? Colors.orange : const Color(0xFF6366F1)),
              const SizedBox(width: 6),
              const Text('Daily Time Budget',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? Colors.orange : const Color(0xFF6366F1),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentlyAllocated} min used + ${_durationMinutes} min new',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                isOver ? '${-remaining} min over' : '${remaining} min left',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOver ? Colors.orange[700] : Colors.grey[600],
                ),
              ),
            ],
          ),
          Text(
            'Daily goal: $dailyGoal min',
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit != null ? 'Edit Habit' : 'Add New Habit'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final availableAreas = <LifeArea>[...appState.activeLifeAreas];
          if (widget.habit != null) {
            final currentArea = appState.lifeAreas
                .where((area) => area.id == widget.habit!.lifeAreaId)
                .toList();
            if (currentArea.isNotEmpty &&
                !availableAreas
                    .any((area) => area.id == currentArea.first.id)) {
              availableAreas.add(currentArea.first);
            }
          }

          final validSelectedValue =
              appState.userProfile.topValues.contains(_selectedValue)
                  ? _selectedValue
                  : null;

          if (availableAreas.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No active life areas',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please activate at least one life area before creating habits.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeBudgetIndicator(appState),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Habit Name',
                      hintText: 'e.g., Morning meditation',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a habit name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLifeAreaId,
                    decoration: const InputDecoration(
                      labelText: 'Life Area',
                      border: OutlineInputBorder(),
                    ),
                    items: availableAreas.map((area) {
                      return DropdownMenuItem(
                        value: area.id,
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
                      setState(() {
                        _selectedLifeAreaId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a life area';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _goalController,
                    decoration: const InputDecoration(
                      labelText: 'Goal Statement (Optional)',
                      hintText: 'What do you want to achieve?',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  if (appState.userProfile.topValues.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: validSelectedValue,
                      decoration: const InputDecoration(
                        labelText: 'Align with Value (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: appState.userProfile.topValues.map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedValue = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    'Duration:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _durationMinutes.toDouble(),
                          min: 5,
                          max: 120,
                          divisions: 23,
                          label: '$_durationMinutes min',
                          onChanged: (value) {
                            setState(() {
                              _durationMinutes = value.round();
                            });
                          },
                          activeColor: const Color(0xFF6366F1),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '$_durationMinutes min',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Difficulty Level:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'micro',
                          label: SizedBox(
                            width: 56,
                            child: Text('Micro', textAlign: TextAlign.center),
                          ),
                        ),
                        ButtonSegment(
                          value: 'easy',
                          label: SizedBox(
                            width: 56,
                            child: Text('Easy', textAlign: TextAlign.center),
                          ),
                        ),
                        ButtonSegment(
                          value: 'medium',
                          label: SizedBox(
                            width: 56,
                            child: Text('Medium', textAlign: TextAlign.center),
                          ),
                        ),
                        ButtonSegment(
                          value: 'challenging',
                          label: SizedBox(
                            width: 56,
                            child: Text('Hard', textAlign: TextAlign.center),
                          ),
                        ),
                      ],
                      selected: {_difficulty},
                      onSelectionChanged: (Set<String> selected) {
                        setState(() {
                          _difficulty = selected.first;
                        });
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _isSubmitting = true);

                                final existingHabit = widget.habit;
                                final habit = Habit(
                                  id: existingHabit?.id ?? '',
                                  name: _nameController.text,
                                  description: _descriptionController.text,
                                  lifeAreaId: _selectedLifeAreaId!,
                                  goalStatement: _goalController.text,
                                  valueAlignment: _selectedValue ?? '',
                                  targetFrequency:
                                      existingHabit?.targetFrequency ?? 7,
                                  durationMinutes: _durationMinutes,
                                  difficultyLevel: _difficulty,
                                  isActive: existingHabit?.isActive ?? true,
                                  reminderTime: existingHabit?.reminderTime,
                                  isBuildingHabit:
                                      existingHabit?.isBuildingHabit ?? true,
                                );

                                try {
                                  if (existingHabit != null) {
                                    await appState.updateHabit(habit);
                                  } else {
                                    await appState.addHabit(habit);
                                  }

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(existingHabit != null
                                            ? 'Habit updated successfully!'
                                            : 'Habit added successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    setState(() => _isSubmitting = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to save habit: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.habit != null ? 'Update Habit' : 'Create Habit',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
