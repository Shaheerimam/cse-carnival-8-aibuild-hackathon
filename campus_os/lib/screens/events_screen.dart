import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../widgets/shared_widgets.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Events')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEventForm(context, null),
        child: const Icon(Icons.add),
      ),
      body: Consumer<EventProvider>(
        builder: (context, provider, _) {
          final events = provider.events;
          if (events.isEmpty) {
            return const EmptyState(
              icon: Icons.event_outlined,
              title: 'No events',
              subtitle: 'Events will appear here',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) => _EventCard(
              event: events[index],
              onTap: () => _showEventDetail(context, events[index]),
            ),
          );
        },
      ),
    );
  }

  void _showEventDetail(BuildContext context, Event event) {
    final provider = context.read<EventProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                StatusBadge(label: event.status),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(icon: Icons.calendar_today_outlined, label: '${event.date} · ${event.startTime} – ${event.endTime}'),
            if (event.date != event.endDate)
              _InfoRow(icon: Icons.date_range_outlined, label: 'Ends: ${event.endDate}'),
            _InfoRow(icon: Icons.room_outlined, label: 'Venue: ${event.venue}'),
            _InfoRow(icon: Icons.person_outlined, label: 'Organizer: ${event.organizer}'),
            const SizedBox(height: 16),
            Text(
              event.description,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            // Registration progress
            Row(
              children: [
                const Text('Registrations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(
                  '${event.registered}/${event.capacity}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: event.fillPercentage,
                backgroundColor: AppTheme.primaryLight,
                valueColor: AlwaysStoppedAnimation(
                  event.isFull ? AppTheme.warning : AppTheme.primary,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            if (event.status == 'upcoming' && !event.isFull)
              ElevatedButton.icon(
                onPressed: () {
                  provider.register(event.id, Registration(
                    studentId: '20-40532',
                    name: 'Student User',
                  ));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Registered for ${event.name}!')),
                  );
                },
                icon: const Icon(Icons.how_to_reg_outlined),
                label: const Text('Register'),
              )
            else if (event.isFull)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
                    SizedBox(width: 8),
                    Text('This event is full', style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEventForm(context, event);
                    },
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                    onPressed: () {
                      provider.delete(event.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Event deleted')),
                      );
                    },
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEventForm(BuildContext context, Event? existing) {
    final provider = context.read<EventProvider>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final dateCtrl = TextEditingController(text: existing?.date ?? '');
    final startCtrl = TextEditingController(text: existing?.startTime ?? '');
    final endCtrl = TextEditingController(text: existing?.endTime ?? '');
    final endDateCtrl = TextEditingController(text: existing?.endDate ?? '');
    final venueCtrl = TextEditingController(text: existing?.venue ?? '');
    final orgCtrl = TextEditingController(text: existing?.organizer ?? '');
    final capCtrl = TextEditingController(text: existing?.capacity.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? 'Create Event' : 'Edit Event',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Event Name')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Start Date', hintText: '2026-09-10'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: endDateCtrl, decoration: const InputDecoration(labelText: 'End Date', hintText: '2026-09-10'))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Time', hintText: '09:00'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Time', hintText: '17:00'))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: venueCtrl, decoration: const InputDecoration(labelText: 'Venue', hintText: '7C01'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: capCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacity'))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: orgCtrl, decoration: const InputDecoration(labelText: 'Organizer')),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isEmpty) return;
                  final event = Event(
                    id: existing?.id ?? provider.generateId(),
                    name: nameCtrl.text,
                    description: descCtrl.text,
                    date: dateCtrl.text,
                    startTime: startCtrl.text,
                    endTime: endCtrl.text,
                    endDate: endDateCtrl.text.isEmpty ? dateCtrl.text : endDateCtrl.text,
                    venue: venueCtrl.text,
                    organizer: orgCtrl.text,
                    capacity: int.tryParse(capCtrl.text) ?? 0,
                    registered: existing?.registered ?? 0,
                    registrations: existing?.registrations ?? [],
                    status: existing?.status ?? 'upcoming',
                  );
                  if (existing == null) {
                    provider.add(event);
                  } else {
                    provider.update(event);
                  }
                  Navigator.pop(ctx);
                },
                child: Text(existing == null ? 'Create Event' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date box
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        event.date.split('-').last,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                      Text(
                        _monthShort(event.date),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary),
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
                        event.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${event.startTime} – ${event.endTime}',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.room_outlined, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 2),
                          Text(event.venue, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                StatusBadge(label: event.status),
              ],
            ),
            const SizedBox(height: 14),
            // Registration bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: event.fillPercentage,
                      backgroundColor: AppTheme.primaryLight,
                      valueColor: AlwaysStoppedAnimation(
                        event.isFull ? AppTheme.warning : AppTheme.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${event.registered}/${event.capacity}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _monthShort(String date) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final parts = date.split('-');
    if (parts.length >= 2) return months[int.tryParse(parts[1]) ?? 0];
    return '';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}
