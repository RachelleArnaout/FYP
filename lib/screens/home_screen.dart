import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/habit_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AIMotivationalResponse? _motivationalMessage;
  bool _isLoadingMotivation = false;
  bool _motivationLoaded = false;

  void _loadMotivationalMessage(AppState appState) {
    if (_isLoadingMotivation || _motivationLoaded) return;
    if (appState.activeHabits.isEmpty) return;

    _isLoadingMotivation = true;

    final today = DateTime.now();
    final todayHabits = appState.activeHabits;
    final completed = todayHabits.where((h) => h.isCompletedOn(today)).length;
    final consistency = (appState.getOverallConsistency(7) * 100);
    final streaks = todayHabits
        .where((h) => h.currentStreak > 0)
        .map((h) => {'name': h.name, 'streak': h.currentStreak})
        .toList();

    HabitService.getMotivationalMessage(
      overallConsistency: consistency,
      completedToday: completed,
      totalToday: todayHabits.length,
      currentStreaks: streaks,
      totalActiveHabits: todayHabits.length,
    ).then((response) {
      if (mounted) {
        setState(() {
          _motivationalMessage = response;
          _isLoadingMotivation = false;
          _motivationLoaded = true;
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _isLoadingMotivation = false;
          _motivationLoaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final today = DateTime.now();
        final todayHabits = appState.activeHabits;

        // Trigger AI message load once
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadMotivationalMessage(appState);
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, appState),
              const SizedBox(height: 24),
              _buildDailyProgress(todayHabits, today),
              const SizedBox(height: 16),
              _buildTimeAllocation(appState),
              const SizedBox(height: 16),
              _buildMotivationalCard(),
              const SizedBox(height: 24),
              _buildTodayHabits(context, appState, todayHabits, today),
              const SizedBox(height: 24),
              _buildQuickStats(appState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppState appState) {
    final hour = DateTime.now().hour;
    String greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, MMMM d').format(DateTime.now()),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyProgress(List habits, DateTime today) {
    final completed = habits.where((h) => h.isCompletedOn(today)).length;
    final total = habits.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$completed / $total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (completed == total && total > 0) ...[
            const SizedBox(height: 12),
            const Text(
              '🎉 Amazing! You completed all habits today!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeAllocation(AppState appState) {
    final dailyGoal = appState.userProfile.dailyFreeTime;
    final allocated = appState.totalHabitMinutesPerDay;
    final remaining = dailyGoal - allocated;
    final ratio = dailyGoal > 0 ? (allocated / dailyGoal).clamp(0.0, 1.0) : 0.0;
    final isOverAllocated = allocated > dailyGoal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverAllocated
            ? Colors.red.withOpacity(0.08)
            : const Color(0xFF6366F1).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverAllocated
              ? Colors.red.withOpacity(0.3)
              : const Color(0xFF6366F1).withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 18,
                color: isOverAllocated ? Colors.red : const Color(0xFF6366F1),
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Time Budget',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isOverAllocated ? Colors.red[700] : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverAllocated ? Colors.red : const Color(0xFF6366F1),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${allocated} min allocated',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isOverAllocated ? Colors.red[700] : Colors.black87,
                ),
              ),
              Text(
                isOverAllocated
                    ? '${-remaining} min over budget!'
                    : '${remaining} min remaining',
                style: TextStyle(
                  fontSize: 13,
                  color: isOverAllocated ? Colors.red[600] : Colors.grey[600],
                  fontWeight:
                      isOverAllocated ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Daily goal: $dailyGoal min · ${appState.activeHabits.length} active habit${appState.activeHabits.length == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalCard() {
    if (_isLoadingMotivation) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.08),
              Colors.blue.withOpacity(0.08)
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Getting your personalized insight...',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    if (_motivationalMessage == null) return const SizedBox.shrink();

    final msg = _motivationalMessage!;
    final isEncouragement = msg.type == 'encouragement';

    final gradientColors = isEncouragement
        ? [Colors.green.withOpacity(0.08), Colors.teal.withOpacity(0.08)]
        : [Colors.purple.withOpacity(0.08), Colors.blue.withOpacity(0.08)];

    final icon = isEncouragement
        ? Icons.celebration
        : msg.type == 'reminder'
            ? Icons.notifications_active
            : Icons.auto_awesome;

    final iconColor = isEncouragement ? Colors.green : const Color(0xFF8B5CF6);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                isEncouragement ? 'Keep it up!' : 'Daily Motivation',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                ),
              ),
              const Spacer(),
              Icon(Icons.auto_awesome, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text('AI',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            msg.message,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          if (msg.quote != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"',
                      style: TextStyle(
                          fontSize: 24,
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                          height: 0.8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.quote!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            height: 1.3,
                          ),
                        ),
                        if (msg.quoteAuthor != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '— ${msg.quoteAuthor}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (msg.tip != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 16, color: Colors.orange[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    msg.tip!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayHabits(
    BuildContext context,
    AppState appState,
    List habits,
    DateTime today,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Today\'s Habits',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/ai-habits');
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('AI'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/add-habit');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (habits.isEmpty)
          Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.track_changes, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No habits yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/add-habit');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Your First Habit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/ai-habits');
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate with AI'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6),
                    side: const BorderSide(color: Color(0xFF8B5CF6)),
                  ),
                ),
              ],
            ),
          )
        else
          ...habits.map((habit) {
            final isCompleted = habit.isCompletedOn(today);
            final lifeArea = appState.lifeAreas.cast<dynamic>().firstWhere(
                  (area) => area.id == habit.lifeAreaId,
                  orElse: () => null,
                );

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Checkbox(
                  value: isCompleted,
                  onChanged: (value) {
                    appState.toggleHabitCompletion(habit.id, today);
                  },
                  activeColor: const Color(0xFF6366F1),
                ),
                title: Text(
                  habit.name,
                  style: TextStyle(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Text(lifeArea?.icon ?? '📌'),
                    const SizedBox(width: 4),
                    Text(lifeArea?.name ?? 'Unknown'),
                    const SizedBox(width: 8),
                    Text('• ${habit.durationMinutes} min'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (habit.currentStreak > 0) ...[
                      Icon(Icons.local_fire_department,
                          size: 16, color: Colors.orange[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${habit.currentStreak}',
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) async {
                        if (value != 'delete') return;

                        final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Delete Habit'),
                                  content: const Text(
                                    'Are you sure you want to delete this habit? This action cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            ) ??
                            false;

                        if (!confirmed) return;

                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          await appState.deleteHabit(habit.id);
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Habit deleted.')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Unable to delete habit. Please try again.'),
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildQuickStats(AppState appState) {
    final consistency = (appState.getOverallConsistency(7) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This Week',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Consistency',
                '$consistency%',
                Icons.trending_up,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Active Habits',
                '${appState.activeHabits.length}',
                Icons.track_changes,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
