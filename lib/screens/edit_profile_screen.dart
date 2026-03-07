import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late String _ageRange;
  late String _profession;
  late String _industry;
  late String _degree;
  late List<String> _lifestyleTypes;
  late List<String> _topValues;
  late List<String> _identityStatements;
  late String _energyPattern;
  late double _dailyFreeTime;
  late String _stressLevel;

  final _identityController = TextEditingController();

  final List<String> _lifestyleOptions = [
    'Student',
    'Working Professional',
    'Hybrid Work',
    'Caregiver',
    'Freelancer',
    'Entrepreneur',
  ];

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
  void initState() {
    super.initState();
    final profile = context.read<AppState>().userProfile;
    _ageRange = profile.ageRange;
    _profession = profile.profession;
    _industry = profile.industry;
    _degree = profile.degree;
    _lifestyleTypes = List.from(profile.lifestyleTypes);
    _topValues = List.from(profile.topValues);
    _identityStatements = List.from(profile.identityStatements);
    _energyPattern = profile.energyPattern;
    _dailyFreeTime = profile.dailyFreeTime.toDouble();
    _stressLevel = profile.stressBaseline;
  }

  @override
  void dispose() {
    _identityController.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final appState = context.read<AppState>();
    final profile = appState.userProfile;
    profile.ageRange = _ageRange;
    profile.profession = _profession;
    profile.industry = _industry;
    profile.degree = _degree;
    profile.lifestyleTypes = List.from(_lifestyleTypes);
    profile.topValues = List.from(_topValues);
    profile.identityStatements = List.from(_identityStatements);
    profile.energyPattern = _energyPattern;
    profile.dailyFreeTime = _dailyFreeTime.round();
    profile.stressBaseline = _stressLevel;
    await appState.updateUserProfile(profile);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Personal Info Section ---
            _buildSectionHeader('Personal Info'),
            const SizedBox(height: 16),
            _buildDropdown(
              'Age Range',
              _ageRange,
              ['18-24', '25-34', '35-44', '45-54', '55+'],
              (value) => setState(() => _ageRange = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _profession,
              decoration: const InputDecoration(
                labelText: 'Profession',
                border: OutlineInputBorder(),
                hintText: 'e.g., Software Engineer, Student',
              ),
              onChanged: (value) => _profession = value,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _industry,
              decoration: const InputDecoration(
                labelText: 'Industry (Optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Technology, Healthcare',
              ),
              onChanged: (value) => _industry = value,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _degree,
              decoration: const InputDecoration(
                labelText: 'Degree (Optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Bachelor\'s in Computer Science',
              ),
              onChanged: (value) => _degree = value,
            ),
            const SizedBox(height: 16),
            _buildMultiSelectChips(
              'Lifestyle Type',
              _lifestyleOptions,
              _lifestyleTypes,
              (option, selected) {
                setState(() {
                  if (selected) {
                    _lifestyleTypes.add(option);
                  } else {
                    _lifestyleTypes.remove(option);
                  }
                });
              },
            ),

            const SizedBox(height: 32),

            // --- Core Values Section ---
            _buildSectionHeader('Core Values'),
            const SizedBox(height: 8),
            Text(
              'Select up to 3 values',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonValues.map((value) {
                final isSelected = _topValues.contains(value);
                return FilterChip(
                  label: Text(value),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected && _topValues.length < 3) {
                        _topValues.add(value);
                      } else if (!selected) {
                        _topValues.remove(value);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF6366F1),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // --- Identity Statements Section ---
            _buildSectionHeader('Identity Statements'),
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
              const SizedBox(height: 12),
              ..._identityStatements.asMap().entries.map((entry) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(entry.value),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          setState(() {
                            _identityStatements.removeAt(entry.key);
                          });
                        },
                      ),
                    ),
                  )),
            ],

            const SizedBox(height: 32),

            // --- Energy & Capacity Section ---
            _buildSectionHeader('Energy & Capacity'),
            const SizedBox(height: 16),
            const Text(
              'When do you have the most energy?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'morning',
                  label: Text('Morning'),
                  icon: Icon(Icons.wb_sunny),
                ),
                ButtonSegment(
                  value: 'afternoon',
                  label: Text('Afternoon'),
                  icon: Icon(Icons.wb_cloudy),
                ),
                ButtonSegment(
                  value: 'evening',
                  label: Text('Evening'),
                  icon: Icon(Icons.nights_stay),
                ),
              ],
              selected: {_energyPattern},
              onSelectionChanged: (Set<String> selected) {
                setState(() {
                  _energyPattern = selected.first;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Daily free time for habits:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '${_dailyFreeTime.round()} minutes',
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: _dailyFreeTime,
              min: 15,
              max: 180,
              divisions: 11,
              label: '${_dailyFreeTime.round()} min',
              onChanged: (value) {
                setState(() {
                  _dailyFreeTime = value;
                });
              },
              activeColor: const Color(0xFF6366F1),
            ),
            const SizedBox(height: 24),
            const Text(
              'Current stress level:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'low', label: Text('Low')),
                ButtonSegment(value: 'medium', label: Text('Medium')),
                ButtonSegment(value: 'high', label: Text('High')),
              ],
              selected: {_stressLevel},
              onSelectionChanged: (Set<String> selected) {
                setState(() {
                  _stressLevel = selected.first;
                });
              },
            ),

            const SizedBox(height: 40),

            // --- Save Button ---
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildMultiSelectChips(
    String label,
    List<String> options,
    List<String> selectedItems,
    void Function(String option, bool selected) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedItems.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) => onChanged(option, selected),
              selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
              checkmarkColor: const Color(0xFF6366F1),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF6366F1) : Colors.black87,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      isSelected ? const Color(0xFF6366F1) : Colors.grey[400]!,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
