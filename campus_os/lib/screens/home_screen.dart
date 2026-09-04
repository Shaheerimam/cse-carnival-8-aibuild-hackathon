import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/schedule_provider.dart';
import '../providers/event_provider.dart';
import '../providers/announcement_provider.dart';
import '../providers/assignment_provider.dart';
import '../widgets/shared_widgets.dart';
import 'main_shell.dart';
import 'announcements_screen.dart';
import 'assignments_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    // Logo
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'C',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const Text(
                            'CampusOS',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_outlined),
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Quick Stats ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Consumer4<ScheduleProvider, AssignmentProvider, EventProvider, AnnouncementProvider>(
                  builder: (context, schedules, assignments, events, announcements, _) {
                    final today = _todayName();
                    final todayClasses = schedules.getByDay(today).length;
                    final pendingAssignments = assignments.getByStatus('pending').length;
                    final upcomingEvents = events.upcomingEvents.length;

                    return Row(
                      children: [
                        _StatCard(
                          icon: Icons.calendar_today_rounded,
                          value: '$todayClasses',
                          label: 'Classes Today',
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.assignment_outlined,
                          value: '$pendingAssignments',
                          label: 'Pending',
                          color: AppTheme.warning,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.event_outlined,
                          value: '$upcomingEvents',
                          label: 'Events',
                          color: AppTheme.success,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ── Today's Classes ──
            SliverToBoxAdapter(
              child: SectionHeader(
                title: "Today's Classes",
                onSeeAll: () => _navigateToTab(context, 1),
              ),
            ),
            SliverToBoxAdapter(
              child: Consumer<ScheduleProvider>(
                builder: (context, provider, _) {
                  final todayClasses = provider.getByDay(_todayName());
                  if (todayClasses.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.cardDecoration,
                        child: const Row(
                          children: [
                            Icon(Icons.beach_access_rounded,
                                color: AppTheme.primary, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'No classes today! Enjoy your day 🎉',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 130,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: todayClasses.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final cls = todayClasses[index];
                        return Container(
                          width: 220,
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.cardDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      cls.course,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    cls.section,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                cls.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded,
                                      size: 14, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cls.startTime} – ${cls.endTime}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.room_outlined,
                                      size: 14, color: AppTheme.textSecondary),
                                  const SizedBox(width: 2),
                                  Text(
                                    cls.room,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // ── Due This Week ──
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Due This Week',
                onSeeAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AssignmentsScreen()),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Consumer<AssignmentProvider>(
                builder: (context, provider, _) {
                  final dueItems = provider.dueThisWeek;
                  if (dueItems.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.cardDecoration,
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: AppTheme.success, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'Nothing due this week! 🥳',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: dueItems.map((a) {
                        final days = a.daysUntilDue;
                        final urgentColor = days <= 2 ? AppTheme.error : AppTheme.warning;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.cardDecoration.copyWith(
                            border: Border(
                              left: BorderSide(color: urgentColor, width: 3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.course,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: urgentColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      a.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: urgentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  days <= 0 ? 'Today!' : '${days}d left',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: urgentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),

            // ── Announcements ──
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Announcements',
                onSeeAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Consumer<AnnouncementProvider>(
                builder: (context, provider, _) {
                  final items = provider.sorted.take(3).toList();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: items.map((a) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.cardDecoration,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                child: PriorityDot(priority: a.priority),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      a.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),

            // ── Upcoming Events ──
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Upcoming Events',
                onSeeAll: () => _navigateToTab(context, 3),
              ),
            ),
            SliverToBoxAdapter(
              child: Consumer<EventProvider>(
                builder: (context, provider, _) {
                  final items = provider.upcomingEvents.take(3).toList();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      children: items.map((e) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.cardDecoration,
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      e.date.split('-').last,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                    Text(
                                      _monthShort(e.date),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${e.startTime} – ${e.endTime} · ${e.venue}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(label: e.status),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _todayName() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[DateTime.now().weekday - 1];
  }

  String _monthShort(String date) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final parts = date.split('-');
    if (parts.length >= 2) {
      final m = int.tryParse(parts[1]) ?? 0;
      return months[m];
    }
    return '';
  }

  void _navigateToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<State<MainShell>>();
    if (state != null) {
      (state as dynamic).setTab(index);
    }
  }
}

// ── Stat Card Widget ──
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
