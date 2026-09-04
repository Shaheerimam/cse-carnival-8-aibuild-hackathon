import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/room.dart';
import '../providers/room_provider.dart';
import '../widgets/shared_widgets.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  String? _selectedType;
  final _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Rooms')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRoomDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<RoomProvider>(
        builder: (context, provider, _) {
          var rooms = _searchCtrl.text.isNotEmpty
              ? provider.search(_searchCtrl.text)
              : provider.getByType(_selectedType);

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search rooms...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => setState(() => _searchCtrl.clear()),
                          )
                        : null,
                  ),
                ),
              ),

              // Filter chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _selectedType == null,
                      onTap: () => setState(() => _selectedType = null),
                    ),
                    _FilterChip(
                      label: 'Classroom',
                      icon: Icons.class_rounded,
                      selected: _selectedType == 'classroom',
                      onTap: () => setState(() => _selectedType = 'classroom'),
                    ),
                    _FilterChip(
                      label: 'Lab',
                      icon: Icons.computer_rounded,
                      selected: _selectedType == 'lab',
                      onTap: () => setState(() => _selectedType = 'lab'),
                    ),
                    _FilterChip(
                      label: 'Seminar',
                      icon: Icons.groups_rounded,
                      selected: _selectedType == 'seminar',
                      onTap: () => setState(() => _selectedType = 'seminar'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Room list
              Expanded(
                child: rooms.isEmpty
                    ? const EmptyState(
                        icon: Icons.meeting_room_outlined,
                        title: 'No rooms found',
                        subtitle: 'Try adjusting your filters',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        itemCount: rooms.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _RoomCard(
                          room: rooms[index],
                          onTap: () => _showRoomDetail(context, rooms[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRoomDetail(BuildContext context, Room room) {
    final provider = context.read<RoomProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollCtrl) => StatefulBuilder(
          builder: (ctx, setModalState) {
            // Re-read room from provider to get latest state
            final currentRoom = provider.rooms.firstWhere((r) => r.id == room.id, orElse: () => room);
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _roomIcon(currentRoom.type),
                        color: AppTheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Room ${currentRoom.roomNumber}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${currentRoom.type[0].toUpperCase()}${currentRoom.type.substring(1)} · Floor ${currentRoom.floor}',
                            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(label: currentRoom.status),
                  ],
                ),
                const SizedBox(height: 20),
                // Stats row
                Row(
                  children: [
                    _DetailChip(icon: Icons.people_outline, label: '${currentRoom.capacity} seats'),
                    const SizedBox(width: 8),
                    ...currentRoom.equipment.take(3).map((e) =>
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _DetailChip(icon: _equipIcon(e), label: e),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Bookings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showBookingForm(context, currentRoom);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Book'),
                    ),
                  ],
                ),
                if (currentRoom.bookings.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'No bookings yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                else
                  ...currentRoom.bookings.map((b) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.purpose, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                '${b.date} · ${b.startTime} – ${b.endTime}',
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                              ),
                              Text(
                                'By ${b.bookedBy}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined, color: AppTheme.error, size: 22),
                          onPressed: () {
                            provider.cancelBooking(currentRoom.id, b.bookingId);
                            setModalState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Booking cancelled')),
                            );
                          },
                        ),
                      ],
                    ),
                  )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showEditRoomDialog(context, currentRoom);
                        },
                        child: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                        onPressed: () {
                          provider.delete(currentRoom.id);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Room deleted')),
                          );
                        },
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showBookingForm(BuildContext context, Room room) {
    final provider = context.read<RoomProvider>();
    final nameCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();

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
              Text('Book Room ${room.roomNumber}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Your Name')),
              const SizedBox(height: 12),
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date', hintText: '2026-09-10')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start', hintText: '14:00'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End', hintText: '16:00'))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: purposeCtrl, decoration: const InputDecoration(labelText: 'Purpose')),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isEmpty || dateCtrl.text.isEmpty) return;
                  provider.addBooking(room.id, Booking(
                    bookingId: provider.generateBookingId(),
                    bookedBy: nameCtrl.text,
                    date: dateCtrl.text,
                    startTime: startCtrl.text,
                    endTime: endCtrl.text,
                    purpose: purposeCtrl.text,
                  ));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Room ${room.roomNumber} booked!')),
                  );
                },
                child: const Text('Confirm Booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddRoomDialog(BuildContext context) {
    _showRoomForm(context, null, (room) {
      context.read<RoomProvider>().add(room.copyWith(id: context.read<RoomProvider>().generateId()));
    });
  }

  void _showEditRoomDialog(BuildContext context, Room room) {
    _showRoomForm(context, room, (updated) {
      context.read<RoomProvider>().update(updated);
    });
  }

  void _showRoomForm(BuildContext context, Room? existing, Function(Room) onSave) {
    final numberCtrl = TextEditingController(text: existing?.roomNumber ?? '');
    final capCtrl = TextEditingController(text: existing?.capacity.toString() ?? '');
    final floorCtrl = TextEditingController(text: existing?.floor.toString() ?? '7');
    final equipCtrl = TextEditingController(text: existing?.equipment.join(', ') ?? '');
    String type = existing?.type ?? 'classroom';
    String status = existing?.status ?? 'available';

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
                Text(existing == null ? 'Add Room' : 'Edit Room', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(controller: numberCtrl, decoration: const InputDecoration(labelText: 'Room Number', hintText: '7A01')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['classroom', 'lab', 'seminar'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setModalState(() => type = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: capCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacity'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: floorCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Floor'))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: equipCtrl, decoration: const InputDecoration(labelText: 'Equipment', hintText: 'projector, AC, whiteboard')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['available', 'unavailable'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setModalState(() => status = v!),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (numberCtrl.text.isEmpty) return;
                    onSave(Room(
                      id: existing?.id ?? '',
                      roomNumber: numberCtrl.text,
                      type: type,
                      capacity: int.tryParse(capCtrl.text) ?? 0,
                      equipment: equipCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                      floor: int.tryParse(floorCtrl.text) ?? 7,
                      status: status,
                      bookings: existing?.bookings ?? [],
                    ));
                    Navigator.pop(ctx);
                  },
                  child: Text(existing == null ? 'Add Room' : 'Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _roomIcon(String type) => switch (type) {
    'lab' => Icons.computer_rounded,
    'seminar' => Icons.groups_rounded,
    _ => Icons.class_rounded,
  };

  IconData _equipIcon(String equip) => switch (equip.toLowerCase()) {
    'projector' => Icons.videocam_outlined,
    'ac' => Icons.ac_unit_rounded,
    'whiteboard' => Icons.dashboard_outlined,
    'computers' => Icons.desktop_windows_outlined,
    'microphone' => Icons.mic_outlined,
    'smart board' => Icons.smart_screen_outlined,
    'podium' => Icons.record_voice_over_outlined,
    'document camera' => Icons.camera_alt_outlined,
    _ => Icons.devices_other,
  };
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border,
            ),
            boxShadow: selected ? [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: selected ? Colors.white : AppTheme.textSecondary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;

  const _RoomCard({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  room.roomNumber,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Room ${room.roomNumber}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        room.type[0].toUpperCase() + room.type.substring(1),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const Text(' · ', style: TextStyle(color: AppTheme.textSecondary)),
                      const Icon(Icons.people_outline, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        '${room.capacity}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      if (room.bookings.isNotEmpty) ...[
                        const Text(' · ', style: TextStyle(color: AppTheme.textSecondary)),
                        Text(
                          '${room.bookings.length} booking${room.bookings.length > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            StatusBadge(label: room.status),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
