import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/lodge_provider.dart';
import '../models/guest.dart';

class GuestsScreen extends StatelessWidget {
  const GuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guests'),
      ),
      body: Consumer<LodgeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final guests = provider.guests;
          if (guests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No guests yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadGuests(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: guests.length,
              itemBuilder: (context, index) {
                final guest = guests[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      child: Text(
                        guest.name[0].toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(guest.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(guest.phone),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showGuestDetails(context, guest),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showGuestDetails(BuildContext context, Guest guest) async {
    final provider = context.read<LodgeProvider>();
    final bookings = await provider.getGuestBookings(guest.id!);

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      guest.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(guest.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(guest.phone, style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
              if (guest.address != null || guest.idProofType != null) ...[
                const Divider(height: 24),
                if (guest.address != null) _infoRow('Address', guest.address!),
                if (guest.idProofType != null) _infoRow('ID Proof', '${guest.idProofType}: ${guest.idProofNumber ?? ''}'),
              ],
              const Divider(height: 24),
              Text('Booking History (${bookings.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: bookings.isEmpty
                    ? Center(child: Text('No bookings', style: TextStyle(color: Colors.grey[500])))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: bookings.length,
                        itemBuilder: (ctx, i) {
                          final b = bookings[i];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              b.status == 'active'
                                  ? Icons.check_circle
                                  : b.status == 'checked_out'
                                      ? Icons.exit_to_app
                                      : Icons.cancel,
                              color: b.status == 'active'
                                  ? Colors.green
                                  : b.status == 'checked_out'
                                      ? Colors.blue
                                      : Colors.red,
                            ),
                            title: Text('Room ${b.roomNumber} - ${b.roomType}'),
                            subtitle: Text(
                              '${b.checkInDate.day}/${b.checkInDate.month}/${b.checkInDate.year}'
                              '${b.checkOutDate != null ? ' to ${b.checkOutDate!.day}/${b.checkOutDate!.month}/${b.checkOutDate!.year}' : ''}'
                              '  |  ₹${b.totalAmount?.toStringAsFixed(0) ?? '-'}',
                            ),
                            trailing: Text(b.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: b.status == 'active'
                                      ? Colors.green
                                      : b.status == 'checked_out'
                                          ? Colors.blue
                                          : Colors.red,
                                )),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
