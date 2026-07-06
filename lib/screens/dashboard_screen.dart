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
                // Welcome header — Airbnb style
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5A5F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEE, MMM d, yyyy').format(DateTime.now()),
                                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Sri Lakshmi Narasimha Lodge',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.home_outlined, color: Colors.white, size: 24),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _newBooking(context),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('New Booking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5A5F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Overview stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Overview', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF222222))),
                    Text('${stats['totalRooms'] ?? 0} rooms', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _StatCard(
                      title: 'Vacant',
                      value: '${stats['vacantRooms'] ?? 0}',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      flex: 1,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      title: 'Occupied',
                      value: '${stats['occupiedRooms'] ?? 0}',
                      icon: Icons.person_pin,
                      color: Colors.orange,
                      flex: 1,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      title: 'Active',
                      value: '${stats['activeBookings'] ?? 0}',
                      icon: Icons.book_online,
                      color: const Color(0xFFFF5A5F),
                      flex: 1,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Today
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Activity", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF222222))),
                    Text(DateFormat('d MMM').format(DateTime.now()), style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _StatCard(
                      title: "Check-ins",
                      value: '${stats['todayCheckIns'] ?? 0}',
                      icon: Icons.login,
                      color: Colors.teal,
                      flex: 1,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      title: "Today's Revenue",
                      value: '₹${NumberFormat('#,##0').format(stats['todayRevenue'] ?? 0)}',
                      icon: Icons.today,
                      color: Colors.green,
                      flex: 1,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      title: 'Advance',
                      value: '₹${NumberFormat('#,##0').format(stats['totalAdvance'] ?? 0)}',
                      icon: Icons.account_balance_wallet,
                      color: Colors.indigo,
                      flex: 1,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quick links
                Text('Quick Access', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF222222))),
                const SizedBox(height: 14),
                _QuickLink(
                  icon: Icons.meeting_room,
                  title: 'Manage Rooms',
                  subtitle: 'Add, edit or view rooms',
                  color: const Color(0xFFFF5A5F),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomsScreen())),
                ),
                _QuickLink(
                  icon: Icons.book_online,
                  title: 'All Bookings',
                  subtitle: 'View and manage bookings',
                  color: const Color(0xFFFF5A5F),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen())),
                ),
                _QuickLink(
                  icon: Icons.people,
                  title: 'Guests',
                  subtitle: 'View guest history',
                  color: const Color(0xFFFF5A5F),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
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
