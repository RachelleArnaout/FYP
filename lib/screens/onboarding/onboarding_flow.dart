import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'welcome_step.dart';
import 'profile_step.dart';
import 'life_areas_step.dart';
import 'values_step.dart';
import 'energy_step.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  bool _lifeAreasCreated = false;

  @override
  void initState() {
    super.initState();
    _ensureLifeAreasExist();
  }

  Future<void> _ensureLifeAreasExist() async {
    if (_lifeAreasCreated) return;
    final appState = context.read<AppState>();
    if (appState.lifeAreas.isEmpty) {
      await appState.createDefaultLifeAreas();
    }
    _lifeAreasCreated = true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final steps = [
          const WelcomeStep(),
          const ProfileStep(),
          const LifeAreasStep(),
          const ValuesStep(),
          const EnergyStep(),
        ];

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Progress indicator
                if (appState.currentOnboardingStep > 0)
                  LinearProgressIndicator(
                    value: appState.currentOnboardingStep / (steps.length - 1),
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF6366F1),
                    ),
                  ),

                // Current step
                Expanded(
                  child: steps[appState.currentOnboardingStep],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
