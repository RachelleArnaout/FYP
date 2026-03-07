import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class ProfileStep extends StatefulWidget {
  const ProfileStep({super.key});

  @override
  State<ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<ProfileStep> {
  final _formKey = GlobalKey<FormState>();
  String _selectedAgeRange = '18-24';
  List<String> _selectedLifestyles = [];
  String _profession = '';
  String _industry = '';
  String _degree = '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us about yourself',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This helps us personalize your experience',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            _buildDropdown(
              'Age Range',
              _selectedAgeRange,
              ['18-24', '25-34', '35-44', '45-54', '55+'],
              (value) => setState(() => _selectedAgeRange = value!),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Profession',
                border: OutlineInputBorder(),
                hintText: 'e.g., Software Engineer, Student',
              ),
              onChanged: (value) => _profession = value,
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Industry (Optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Technology, Healthcare',
              ),
              onChanged: (value) => _industry = value,
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Degree (Optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Bachelor\'s in Computer Science',
              ),
              onChanged: (value) => _degree = value,
            ),
            const SizedBox(height: 20),
            _buildMultiSelectChips(
              'Lifestyle Type',
              [
                'Student',
                'Working Professional',
                'Hybrid Work',
                'Caregiver',
                'Freelancer',
                'Entrepreneur',
              ],
            ),
            const SizedBox(height: 40),
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
                    onPressed: () {
                      final appState = context.read<AppState>();
                      final profile = appState.userProfile;
                      profile.ageRange = _selectedAgeRange;
                      profile.profession = _profession;
                      profile.industry = _industry;
                      profile.degree = _degree;
                      profile.lifestyleTypes = List.from(_selectedLifestyles);
                      appState.updateUserProfile(profile);
                      appState.nextOnboardingStep();
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
      value: value,
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

  Widget _buildMultiSelectChips(String label, List<String> options) {
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
            final isSelected = _selectedLifestyles.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedLifestyles.add(option);
                  } else {
                    _selectedLifestyles.remove(option);
                  }
                });
              },
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
