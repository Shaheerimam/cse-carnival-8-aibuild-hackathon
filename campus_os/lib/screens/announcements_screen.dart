import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/announcement.dart';
import '../providers/announcement_provider.dart';
import '../widgets/shared_widgets.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Announcements')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
      body: Consumer<AnnouncementProvider>(
        builder: (context, provider, _) {
          final items = provider.sorted;
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.campaign_outlined,
              title: 'No announcements',
              subtitle: 'Notices will appear here',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _AnnouncementCard(
              announcement: items[index],
              onEdit: () => _showForm(context, items[index]),
              onDelete: () {
                provider.delete(items[index].id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Announcement deleted')),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showForm(BuildContext context, Announcement? existing) {
    final provider = context.read<AnnouncementProvider>();
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final bodyCtrl = TextEditingController(text: existing?.body ?? '');
    final postedByCtrl = TextEditingController(text: existing?.postedBy ?? '');
    final expiresCtrl = TextEditingController(text: existing?.expires ?? '');
    String priority = existing?.priority ?? 'medium';

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
                  existing == null ? 'Post Announcement' : 'Edit Announcement',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Body', alignLabelWithHint: true),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: [
                    DropdownMenuItem(value: 'high', child: Row(children: [PriorityDot(priority: 'high'), SizedBox(width: 8), Text('High')])),
                    DropdownMenuItem(value: 'medium', child: Row(children: [PriorityDot(priority: 'medium'), SizedBox(width: 8), Text('Medium')])),
                    DropdownMenuItem(value: 'low', child: Row(children: [PriorityDot(priority: 'low'), SizedBox(width: 8), Text('Low')])),
                  ],
                  onChanged: (v) => setModalState(() => priority = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: postedByCtrl, decoration: const InputDecoration(labelText: 'Posted By')),
                const SizedBox(height: 12),
                TextField(controller: expiresCtrl, decoration: const InputDecoration(labelText: 'Expires', hintText: '2026-09-15')),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.isEmpty) return;
                    final now = DateTime.now();
                    final item = Announcement(
                      id: existing?.id ?? provider.generateId(),
                      title: titleCtrl.text,
                      body: bodyCtrl.text,
                      date: existing?.date ?? '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                      priority: priority,
                      postedBy: postedByCtrl.text,
                      expires: expiresCtrl.text,
                    );
                    if (existing == null) {
                      provider.add(item);
                    } else {
                      provider.update(item);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(existing == null ? 'Post' : 'Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatefulWidget {
  final Announcement announcement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.announcement,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<_AnnouncementCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.announcement;
    final priorityColor = AppTheme.priorityColor(a.priority);

    return Dismissible(
      key: Key(a.id),
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
      onDismissed: (_) => widget.onDelete(),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        onLongPress: widget.onEdit,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border(
              left: BorderSide(color: priorityColor, width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              StatusBadge(label: a.priority, color: priorityColor),
                              if (a.isExpired) ...[
                                const SizedBox(width: 8),
                                const StatusBadge(label: 'expired'),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            a.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20, color: AppTheme.textSecondary),
                      onSelected: (v) {
                        if (v == 'edit') widget.onEdit();
                        if (v == 'delete') widget.onDelete();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.error))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedCrossFade(
                  firstChild: Text(
                    a.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  secondChild: Text(
                    a.body,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(a.postedBy, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const Spacer(),
                    const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(a.date, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
