import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class EnergyStep extends StatefulWidget {
  const EnergyStep({super.key});

  @override
  State<EnergyStep> createState() => _EnergyStepState();
}

class _EnergyStepState extends State<EnergyStep> {
  String _energyPattern = 'morning';
  double _dailyFreeTime = 60;
  String _stressLevel = 'medium';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your energy & capacity',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us understand your daily rhythm',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'When do you have the most energy?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 32),
          const Text(
            'Daily free time for habits:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
          const SizedBox(height: 32),
          const Text(
            'Current stress level:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 48),
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
                  onPressed: () async {
                    final appState = context.read<AppState>();
                    final profile = appState.userProfile;
                    profile.energyPattern = _energyPattern;
                    profile.dailyFreeTime = _dailyFreeTime.round();
                    profile.stressBaseline = _stressLevel;
                    await appState.updateUserProfile(profile);
                    if (context.mounted) {
                      await appState.completeOnboarding();
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
                  child: const Text('Complete Setup'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
