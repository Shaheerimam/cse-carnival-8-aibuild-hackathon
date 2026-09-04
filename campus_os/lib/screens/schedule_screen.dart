import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/schedule.dart';
import '../providers/schedule_provider.dart';
import '../widgets/shared_widgets.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _days = const ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'];

  @override
  void initState() {
    super.initState();
    // Default to today's tab if it's a weekday
    final today = DateTime.now().weekday; // 1=Mon, 7=Sun
    final dayIndex = today == 7 ? 0 : today; // Sun=0, Mon=1...Thu=4
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: dayIndex.clamp(0, 4),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Schedule'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: _days.map((d) => Tab(text: d.substring(0, 3))).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          return TabBarView(
            controller: _tabController,
            children: _days.map((day) {
              final classes = provider.getByDay(day);
              if (classes.isEmpty) {
                return const EmptyState(
                  icon: Icons.free_breakfast_rounded,
                  title: 'No classes',
                  subtitle: 'Enjoy your free day!',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: classes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _ScheduleCard(
                  schedule: classes[index],
                  onEdit: () => _showEditDialog(context, classes[index]),
                  onDelete: () => _confirmDelete(context, provider, classes[index].id),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final provider = context.read<ScheduleProvider>();
    _showScheduleForm(context, null, (schedule) {
      provider.add(schedule.copyWith(id: provider.generateId()));
    });
  }

  void _showEditDialog(BuildContext context, Schedule schedule) {
    final provider = context.read<ScheduleProvider>();
    _showScheduleForm(context, schedule, (updated) {
      provider.update(updated);
    });
  }

  void _confirmDelete(BuildContext context, ScheduleProvider provider, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Class'),
        content: const Text('Are you sure you want to remove this class from the schedule?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.delete(id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Class removed')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showScheduleForm(BuildContext context, Schedule? existing, Function(Schedule) onSave) {
    final courseCtrl = TextEditingController(text: existing?.course ?? '');
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final startCtrl = TextEditingController(text: existing?.startTime ?? '');
    final endCtrl = TextEditingController(text: existing?.endTime ?? '');
    final roomCtrl = TextEditingController(text: existing?.room ?? '');
    final instructorCtrl = TextEditingController(text: existing?.instructor ?? '');
    final sectionCtrl = TextEditingController(text: existing?.section ?? '');
    String selectedDay = existing?.day ?? _days[_tabController.index];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  existing == null ? 'Add Class' : 'Edit Class',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(controller: courseCtrl, decoration: const InputDecoration(labelText: 'Course Code', hintText: 'e.g. CSE 4113')),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Course Title')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedDay,
                  decoration: const InputDecoration(labelText: 'Day'),
                  items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) => setModalState(() => selectedDay = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Time', hintText: '08:00'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Time', hintText: '09:40'))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'Room', hintText: '7A03'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: sectionCtrl, decoration: const InputDecoration(labelText: 'Section', hintText: 'B'))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: instructorCtrl, decoration: const InputDecoration(labelText: 'Instructor')),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (courseCtrl.text.isEmpty || titleCtrl.text.isEmpty) return;
                    onSave(Schedule(
                      id: existing?.id ?? '',
                      course: courseCtrl.text,
                      title: titleCtrl.text,
                      day: selectedDay,
                      startTime: startCtrl.text,
                      endTime: endCtrl.text,
                      room: roomCtrl.text,
                      instructor: instructorCtrl.text,
                      section: sectionCtrl.text,
                    ));
                    Navigator.pop(ctx);
                  },
                  child: Text(existing == null ? 'Add Class' : 'Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleCard({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(schedule.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.error),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration,
          child: Row(
            children: [
              // Time column
              Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      schedule.startTime,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 16,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppTheme.primaryLight,
                    ),
                    Text(
                      schedule.endTime,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 3,
                height: 60,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            schedule.course,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sec ${schedule.section}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      schedule.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            schedule.instructor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ),
                        const Icon(Icons.room_outlined, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 2),
                        Text(
                          schedule.room,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
