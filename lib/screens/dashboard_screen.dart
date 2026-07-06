import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../database/lodge_provider.dart';
import 'rooms_screen.dart';
import 'bookings_screen.dart';
import 'guests_screen.dart';
import 'add_booking_screen.dart';
import 'global_search_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SRI LAKSHMI NARASIMHA LODGE'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen())),
          ),
        ],
      ),
      body: Consumer<LodgeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = provider.stats;
          return RefreshIndicator(
            onRefresh: () => provider.loadAll(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Welcome header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Welcome to',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const Text(
                        'Sri Lakshmi Narasimha Lodge',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Quick action button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _newBooking(context),
                    icon: const Icon(Icons.add_circle_outline, size: 28),
                    label: const Text('New Booking', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Stats grid
                Text('Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatCard(
                      title: 'Total Rooms',
                      value: '${stats['totalRooms'] ?? 0}',
                      icon: Icons.meeting_room,
                      color: Colors.blue,
                      flex: 1,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      title: 'Vacant',
                      value: '${stats['vacantRooms'] ?? 0}',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      flex: 1,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      title: 'Occupied',
                      value: '${stats['occupiedRooms'] ?? 0}',
                      icon: Icons.person_pin,
                      color: Colors.orange,
                      flex: 1,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatCard(
                      title: 'Active Bookings',
                      value: '${stats['activeBookings'] ?? 0}',
                      icon: Icons.book_online,
                      color: Colors.purple,
                      flex: 1,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      title: "Today's Check-ins",
                      value: '${stats['todayCheckIns'] ?? 0}',
                      icon: Icons.login,
                      color: Colors.teal,
                      flex: 1,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Revenue section
                Text('Revenue', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatCard(
                      title: "Today's Revenue",
                      value: '₹${NumberFormat('#,##0').format(stats['todayRevenue'] ?? 0)}',
                      icon: Icons.today,
                      color: Colors.green,
                      flex: 1,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      title: 'Total Advance',
                      value: '₹${NumberFormat('#,##0').format(stats['totalAdvance'] ?? 0)}',
                      icon: Icons.account_balance_wallet,
                      color: Colors.indigo,
                      flex: 1,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Quick links
                Text('Quick Access', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _QuickLink(
                  icon: Icons.meeting_room,
                  title: 'Manage Rooms',
                  subtitle: 'Add, edit or view rooms',
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomsScreen())),
                ),
                _QuickLink(
                  icon: Icons.book_online,
                  title: 'All Bookings',
                  subtitle: 'View and manage bookings',
                  color: Colors.purple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen())),
                ),
                _QuickLink(
                  icon: Icons.people,
                  title: 'Guests',
                  subtitle: 'View guest history',
                  color: Colors.teal,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuestsScreen())),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _newBooking(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBookingScreen()));
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int flex;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
