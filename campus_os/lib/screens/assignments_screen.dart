import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/assignment.dart';
import '../providers/assignment_provider.dart';
import '../widgets/shared_widgets.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Assignments'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Submitted'),
            Tab(text: 'Graded'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
      body: Consumer<AssignmentProvider>(
        builder: (context, provider, _) {
          final filters = [null, 'pending', 'submitted', 'graded'];
          return TabBarView(
            controller: _tabController,
            children: filters.map((status) {
              final items = provider.getByStatus(status);
              if (items.isEmpty) {
                return EmptyState(
                  icon: Icons.assignment_outlined,
                  title: status == null ? 'No assignments' : 'No $status assignments',
                  subtitle: 'Assignments will appear here',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _AssignmentCard(
                  assignment: items[index],
                  onEdit: () => _showForm(context, items[index]),
                  onDelete: () {
                    provider.delete(items[index].id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Assignment deleted')),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _showForm(BuildContext context, Assignment? existing) {
    final provider = context.read<AssignmentProvider>();
    final courseCtrl = TextEditingController(text: existing?.course ?? '');
    final courseTitleCtrl = TextEditingController(text: existing?.courseTitle ?? '');
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final deadlineCtrl = TextEditingController(text: existing?.deadline ?? '');
    final platformCtrl = TextEditingController(text: existing?.submissionPlatform ?? '');
    final marksCtrl = TextEditingController(text: existing?.marks.toString() ?? '');
    String status = existing?.status ?? 'pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  existing == null ? 'Add Assignment' : 'Edit Assignment',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: TextField(controller: courseCtrl, decoration: const InputDecoration(labelText: 'Course Code', hintText: 'CSE 4113'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: marksCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Marks'))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: courseTitleCtrl, decoration: const InputDecoration(labelText: 'Course Title')),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Assignment Title')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: deadlineCtrl, decoration: const InputDecoration(labelText: 'Deadline', hintText: '2026-09-15'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: ['pending', 'submitted', 'graded', 'late']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setModalState(() => status = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: platformCtrl, decoration: const InputDecoration(labelText: 'Submission Platform', hintText: 'Google Classroom')),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.isEmpty || courseCtrl.text.isEmpty) return;
                    final now = DateTime.now();
                    final item = Assignment(
                      id: existing?.id ?? provider.generateId(),
                      course: courseCtrl.text,
                      courseTitle: courseTitleCtrl.text,
                      title: titleCtrl.text,
                      description: descCtrl.text,
                      assignedDate: existing?.assignedDate ??
                          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                      deadline: deadlineCtrl.text,
                      submissionPlatform: platformCtrl.text,
                      status: status,
                      marks: int.tryParse(marksCtrl.text) ?? 0,
                    );
                    if (existing == null) {
                      provider.add(item);
                    } else {
                      provider.update(item);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(existing == null ? 'Add Assignment' : 'Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssignmentCard({
    required this.assignment,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final days = assignment.daysUntilDue;
    final isOverdue = assignment.isOverdue;
    final deadlineColor = isOverdue
        ? AppTheme.error
        : days <= 3
            ? AppTheme.warning
            : AppTheme.textSecondary;

    return Dismissible(
      key: Key(assignment.id),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      assignment.course,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(label: assignment.status),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${assignment.marks} marks',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                assignment.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                assignment.courseTitle,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule_outlined, size: 14, color: deadlineColor),
                  const SizedBox(width: 4),
                  Text(
                    isOverdue
                        ? 'Overdue'
                        : days == 0
                            ? 'Due today!'
                            : '$days day${days == 1 ? '' : 's'} left',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: deadlineColor,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    assignment.deadline,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              if (assignment.submissionPlatform.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.upload_outlined, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      assignment.submissionPlatform,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
