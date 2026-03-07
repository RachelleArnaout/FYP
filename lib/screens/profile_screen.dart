import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final profile = appState.userProfile;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Personal Info',
                [
                  _buildInfoRow('Age Range', profile.ageRange),
                  _buildInfoRow('Profession', profile.profession),
                  if (profile.industry.isNotEmpty)
                    _buildInfoRow('Industry', profile.industry),
                  if (profile.degree.isNotEmpty)
                    _buildInfoRow('Degree', profile.degree),
                  _buildInfoRow('Lifestyle', profile.lifestyleTypes.join(', ')),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Core Values',
                profile.topValues.isEmpty
                    ? [const Text('Not set yet')]
                    : profile.topValues
                        .map((value) => Chip(
                              label: Text(value),
                              backgroundColor:
                                  const Color(0xFF6366F1).withOpacity(0.1),
                            ))
                        .toList(),
              ),
              const SizedBox(height: 24),
              if (profile.identityStatements.isNotEmpty) ...[
                _buildSection(
                  'Identity Statements',
                  profile.identityStatements
                      .map((statement) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(fontSize: 16)),
                                Expanded(child: Text(statement)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
              ],
              _buildSection(
                'Energy & Capacity',
                [
                  _buildInfoRow('Energy Pattern', profile.energyPattern),
                  _buildInfoRow(
                      'Daily Free Time', '${profile.dailyFreeTime} min'),
                  _buildInfoRow('Stress Level', profile.stressBaseline),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Active Life Areas',
                appState.activeLifeAreas
                    .map((area) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Text(area.icon,
                              style: const TextStyle(fontSize: 24)),
                          title: Text(area.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              appState.toggleLifeArea(area.id);
                            },
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Log Out'),
                        content: const Text(
                            'Are you sure you want to log out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              context.read<AppState>().logout();
                            },
                            child: const Text(
                              'Log Out',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
