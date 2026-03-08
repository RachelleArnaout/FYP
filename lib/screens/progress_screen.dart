import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _isWeekly = true; // true = weekly, false = monthly

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Progress',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildConsistencyChart(appState),
              const SizedBox(height: 24),
              _buildLifeAreaBreakdown(appState),
              const SizedBox(height: 24),
              _buildHabitsList(appState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConsistencyChart(AppState appState) {
    final days = _isWeekly ? 7 : 30;
    final data = <FlSpot>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final consistency = appState.getDailyConsistency(date) * 100;
      data.add(FlSpot((days - 1 - i).toDouble(), consistency));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isWeekly ? 'Weekly Consistency' : 'Monthly Consistency',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Week')),
                    ButtonSegment(value: false, label: Text('Month')),
                  ],
                  selected: {_isWeekly},
                  onSelectionChanged: (Set<bool> selected) {
                    setState(() {
                      _isWeekly = selected.first;
                    });
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isWeekly ? 'Last 7 days' : 'Last 30 days',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%',
                              style: const TextStyle(fontSize: 11));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _isWeekly ? 1 : 5,
                        getTitlesWidget: (value, meta) {
                          if (_isWeekly) {
                            final days = [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun'
                            ];
                            final idx = value.toInt();
                            if (idx >= 0 && idx < days.length) {
                              final date = DateTime.now()
                                  .subtract(Duration(days: 6 - idx));
                              final weekday = date.weekday; // 1=Mon
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(days[weekday - 1],
                                    style: const TextStyle(fontSize: 11)),
                              );
                            }
                          } else {
                            final idx = value.toInt();
                            if (idx % 5 == 0 && idx < 30) {
                              final date = DateTime.now()
                                  .subtract(Duration(days: 29 - idx));
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('${date.day}/${date.month}',
                                    style: const TextStyle(fontSize: 10)),
                              );
                            }
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: (days - 1).toDouble(),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data,
                      isCurved: true,
                      color: const Color(0xFF6366F1),
                      barWidth: 2,
                      dotData: FlDotData(show: _isWeekly),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildConsistencySummary(appState),
          ],
        ),
      ),
    );
  }

  Widget _buildConsistencySummary(AppState appState) {
    final days = _isWeekly ? 7 : 30;
    final overall = (appState.getOverallConsistency(days) * 100).round();
    final label = _isWeekly ? 'this week' : 'this month';

    return Row(
      children: [
        Icon(
          overall >= 70
              ? Icons.trending_up
              : overall >= 40
                  ? Icons.trending_flat
                  : Icons.trending_down,
          color: overall >= 70
              ? Colors.green
              : overall >= 40
                  ? Colors.orange
                  : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          '$overall% average consistency $label',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: overall >= 70
                ? Colors.green[700]
                : overall >= 40
                    ? Colors.orange[700]
                    : Colors.red[700],
          ),
        ),
      ],
    );
  }

  Widget _buildLifeAreaBreakdown(AppState appState) {
    final days = _isWeekly ? 7 : 30;
    final stats = appState.getLifeAreaStats(days);
    final periodLabel = _isWeekly ? 'this week' : 'this month';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Life Area Breakdown ($periodLabel)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Completion rate per life area',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (appState.activeLifeAreas.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No active life areas',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              ...appState.activeLifeAreas.map((area) {
                final stat = stats[area.id];
                final totalCompletions = stat?['completed'] ?? 0;
                final totalPossible = stat?['total'] ?? 0;
                final habitCount = stat?['habitCount'] ?? 0;
                final rate =
                    totalPossible > 0 ? totalCompletions / totalPossible : 0.0;
                final pct = (rate * 100).round();

                final barColor = pct >= 70
                    ? Colors.green
                    : pct >= 40
                        ? Colors.orange
                        : pct > 0
                            ? Colors.red
                            : Colors.grey;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Row(
                    children: [
                      Text(area.icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    area.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '$pct%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: barColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: rate,
                                minHeight: 8,
                                backgroundColor: Colors.grey[200],
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(barColor),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              habitCount == 0
                                  ? 'No habits'
                                  : '$totalCompletions / $totalPossible completions · $habitCount habit${habitCount == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsList(AppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Habit Streaks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...appState.activeHabits.map((habit) {
              final consistency = (habit.getConsistencyRate(7) * 100).round();

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  child: Text(
                    '${habit.currentStreak}',
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  habit.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('$consistency% this week'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department,
                        size: 20, color: Colors.orange[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${habit.longestStreak} best',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }),
            if (appState.activeHabits.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No habits to track yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
