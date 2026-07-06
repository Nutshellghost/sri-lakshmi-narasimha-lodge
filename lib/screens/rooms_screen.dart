import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/lodge_provider.dart';
import '../models/room.dart';

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRoomDialog(context),
          ),
        ],
      ),
      body: Consumer<LodgeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = provider.rooms;
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No rooms added yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddRoomDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Room'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadRooms(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                return _RoomCard(
                  room: room,
                  onTap: () => _showRoomDetails(context, room),
                  onEdit: () => _showEditRoomDialog(context, room),
                  onDelete: () => _deleteRoom(context, room),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddRoomDialog(BuildContext context) {
    _showRoomForm(context, null);
  }

  void _showEditRoomDialog(BuildContext context, Room room) {
    _showRoomForm(context, room);
  }

  void _showRoomForm(BuildContext context, Room? existing) {
    final numberCtrl = TextEditingController(text: existing?.roomNumber ?? '');
    final priceCtrl = TextEditingController(text: existing?.price.toString() ?? '');
    final capacityCtrl = TextEditingController(text: existing?.capacity.toString() ?? '2');
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    String selectedType = existing?.roomType ?? Room.roomTypes[0];
    String selectedStatus = existing?.status ?? 'vacant';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'Add Room' : 'Edit Room'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: numberCtrl,
                  decoration: const InputDecoration(labelText: 'Room Number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Room Type', border: OutlineInputBorder()),
                  items: Room.roomTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price per Night (₹)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capacityCtrl,
                  decoration: const InputDecoration(labelText: 'Capacity (persons)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                if (existing != null)
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    items: Room.statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => selectedStatus = v!),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (numberCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                final room = Room(
                  id: existing?.id,
                  roomNumber: numberCtrl.text.trim(),
                  roomType: selectedType,
                  price: double.parse(priceCtrl.text.trim()),
                  capacity: int.tryParse(capacityCtrl.text.trim()) ?? 2,
                  status: existing?.status ?? selectedStatus,
                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                );
                if (existing == null) {
                  await context.read<LodgeProvider>().addRoom(room);
                } else {
                  await context.read<LodgeProvider>().updateRoom(room);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoomDetails(BuildContext context, Room room) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Room ${room.roomNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Type', room.roomType),
            _detailRow('Price', '₹${room.price.toStringAsFixed(0)}/night'),
            _detailRow('Capacity', '${room.capacity} persons'),
            _detailRow('Status', room.status.toUpperCase()),
            if (room.description != null) _detailRow('Description', room.description!),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _deleteRoom(BuildContext context, Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Delete Room ${room.roomNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<LodgeProvider>().deleteRoom(room.id!);
    }
  }
}

class _RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoomCard({
    required this.room,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor() {
    switch (room.status) {
      case 'vacant':
        return Colors.green;
      case 'occupied':
        return Colors.orange;
      case 'maintenance':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.meeting_room, color: _statusColor()),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room ${room.roomNumber}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(room.roomType, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                        ),
                        const SizedBox(width: 8),
                        Text('₹${room.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Text('| ${room.capacity}p', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  room.status.toUpperCase(),
                  style: TextStyle(
                    color: _statusColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton(
                itemBuilder: (_) => [
                  PopupMenuItem(onTap: onEdit, child: const Text('Edit')),
                  PopupMenuItem(onTap: onDelete, child: Text('Delete', style: TextStyle(color: Colors.red[700]))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
