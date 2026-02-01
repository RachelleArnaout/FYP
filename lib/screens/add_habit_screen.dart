import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/habit.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Habit'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final activeAreas = appState.activeLifeAreas;

          if (activeAreas.isEmpty) {
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
                    items: activeAreas.map((area) {
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
                      initialValue: _selectedValue,
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
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'micro', label: Text('Micro')),
                      ButtonSegment(value: 'easy', label: Text('Easy')),
                      ButtonSegment(value: 'medium', label: Text('Medium')),
                      ButtonSegment(value: 'challenging', label: Text('Hard')),
                    ],
                    selected: {_difficulty},
                    onSelectionChanged: (Set<String> selected) {
                      setState(() {
                        _difficulty = selected.first;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final habit = Habit(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            name: _nameController.text,
                            description: _descriptionController.text,
                            lifeAreaId: _selectedLifeAreaId!,
                            goalStatement: _goalController.text,
                            valueAlignment: _selectedValue ?? '',
                            durationMinutes: _durationMinutes,
                            difficultyLevel: _difficulty,
                          );

                          appState.addHabit(habit);
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Habit added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Create Habit',
                        style: TextStyle(
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
