import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class ValuesStep extends StatefulWidget {
  const ValuesStep({super.key});

  @override
  State<ValuesStep> createState() => _ValuesStepState();
}

class _ValuesStepState extends State<ValuesStep> {
  final List<String> _selectedValues = [];
  final _identityController = TextEditingController();
  final List<String> _identityStatements = [];

  final List<String> _commonValues = [
    'Growth',
    'Health',
    'Discipline',
    'Creativity',
    'Balance',
    'Connection',
    'Achievement',
    'Peace',
    'Purpose',
    'Freedom',
    'Kindness',
    'Courage',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Define your values & identity',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What matters most to you? Who do you want to become?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Select your top 3 values:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonValues.map((value) {
              final isSelected = _selectedValues.contains(value);
              return FilterChip(
                label: Text(value),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected && _selectedValues.length < 3) {
                      _selectedValues.add(value);
                    } else if (!selected) {
                      _selectedValues.remove(value);
                    }
                  });
                },
                selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
                checkmarkColor: const Color(0xFF6366F1),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          const Text(
            'Identity statements (Optional):',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'e.g., "I want to become someone who is more disciplined"',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _identityController,
                  decoration: const InputDecoration(
                    hintText: 'I want to become...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  if (_identityController.text.isNotEmpty) {
                    setState(() {
                      _identityStatements.add(_identityController.text);
                      _identityController.clear();
                    });
                  }
                },
                icon: const Icon(Icons.add_circle),
                color: const Color(0xFF6366F1),
              ),
            ],
          ),
          if (_identityStatements.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._identityStatements.map((statement) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(statement),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() {
                          _identityStatements.remove(statement);
                        });
                      },
                    ),
                  ),
                )),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.read<AppState>().previousOnboardingStep();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedValues.isEmpty
                      ? null
                      : () async {
                          final appState = context.read<AppState>();
                          final profile = appState.userProfile;
                          profile.topValues = List.from(_selectedValues);
                          profile.identityStatements =
                              List.from(_identityStatements);
                          await appState.updateUserProfile(profile);
                          if (context.mounted) {
                            appState.nextOnboardingStep();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
