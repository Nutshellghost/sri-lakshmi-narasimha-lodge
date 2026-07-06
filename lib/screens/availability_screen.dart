import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../database/lodge_provider.dart';
import '../models/room.dart';
import '../models/booking.dart';
import 'add_booking_screen.dart';
import 'bookings_screen.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _viewMonth = DateTime.now();
  Map<int, Booking> _occupied = {};
  List<Room> _rooms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<LodgeProvider>();
    setState(() => _loading = true);
    await provider.loadRooms();
    final occupied = await provider.getOccupiedRoomsForDate(_selectedDate);
    setState(() {
      _rooms = provider.rooms;
      _occupied = occupied;
      _loading = false;
    });
  }

  Future<void> _selectDate(DateTime date) async {
    setState(() => _selectedDate = date);
    final provider = context.read<LodgeProvider>();
    final occupied = await provider.getOccupiedRoomsForDate(date);
    setState(() => _occupied = occupied);
  }

  void _prevMonth() => setState(() {
    _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
    if (_selectedDate.month != _viewMonth.month) _selectedDate = _viewMonth;
  });

  void _nextMonth() => setState(() {
    _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
    if (_selectedDate.month != _viewMonth.month) _selectedDate = _viewMonth;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Availability'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => _selectDate(DateTime.now()),
            tooltip: 'Today',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildMonthHeader(),
                  _buildCalendarGrid(),
                  const Divider(height: 1),
                  _buildRoomList(),
                ],
              ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _prevMonth,
          ),
          Text(
            DateFormat('MMMM yyyy').format(_viewMonth),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final lastDay = DateTime(_viewMonth.year, _viewMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // Sunday = 0
    final daysInMonth = lastDay.day;
    final today = DateTime.now();

    const dayHeaders = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: dayHeaders.map((d) => Expanded(
              child: Center(
                child: Text(d, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 4),
          ...List.generate(_getWeeksCount(daysInMonth, startWeekday), (weekIndex) {
            return Row(
              children: List.generate(7, (dayIndex) {
                final dayNum = weekIndex * 7 + dayIndex - startWeekday + 1;
                final validDay = dayNum >= 1 && dayNum <= daysInMonth;
                final date = validDay
                    ? DateTime(_viewMonth.year, _viewMonth.month, dayNum)
                    : null;

                final isSelected = date != null &&
                    date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;

                final isToday = date != null &&
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;

                return Expanded(
                  child: GestureDetector(
                    onTap: validDay ? () => _selectDate(date!) : null,
                    child: Container(
                      margin: const EdgeInsets.all(1.5),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : isToday
                                ? Colors.orange.withValues(alpha: 0.15)
                                : null,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          validDay ? '$dayNum' : '',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? Colors.orange
                                    : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  int _getWeeksCount(int daysInMonth, int startWeekday) {
    return ((daysInMonth + startWeekday + 6) ~/ 7).clamp(4, 6);
  }

  Widget _buildRoomList() {
    if (_rooms.isEmpty) {
      return const Expanded(
        child: Center(child: Text('No rooms added yet')),
      );
    }

    // Stats bar
    final vacant = _rooms.where((r) => !_occupied.containsKey(r.id)).toList();
    final occupied = _rooms.where((r) => _occupied.containsKey(r.id)).toList();
    final maintenance = _rooms.where((r) => r.status == 'maintenance').toList();

    return Expanded(
      child: Column(
        children: [
          // Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(Colors.green, '${vacant.length} Free'),
                const SizedBox(width: 16),
                _legendDot(Colors.red, '${occupied.length} Booked'),
                const SizedBox(width: 16),
                _legendDot(Colors.orange, '${maintenance.length} Maint'),
                const SizedBox(width: 16),
                Text(
                  DateFormat('d MMM, EEE').format(_selectedDate),
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Room grid
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: _rooms.map((room) {
                final booking = _occupied[room.id];
                final isOccupied = booking != null;
                final isMaint = room.status == 'maintenance';

                Color bgColor;
                Color textColor;
                IconData icon;
                String label;
                VoidCallback? onTap;

                if (isMaint) {
                  bgColor = Colors.orange.withValues(alpha: 0.12);
                  textColor = Colors.orange[800]!;
                  icon = Icons.build;
                  label = 'Under Maintenance';
                  onTap = null;
                } else if (isOccupied) {
                  bgColor = Colors.red.withValues(alpha: 0.1);
                  textColor = Colors.red[700]!;
                  icon = Icons.person;
                  label = '${booking.guestName} · ${booking.guestPhone}';
                  onTap = () => _showBookingDetail(booking);
                } else {
                  bgColor = Colors.green.withValues(alpha: 0.08);
                  textColor = Colors.green[700]!;
                  icon = Icons.check_circle_outline;
                  label = 'Vacant · ₹${room.price.toStringAsFixed(0)}';
                  onTap = () => _createBooking(room);
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  elevation: isOccupied ? 2 : 0.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: textColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Room ${room.roomNumber}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(room.roomType, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(label, style: TextStyle(fontSize: 12, color: textColor)),
                              ],
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isMaint
                                  ? Colors.orange
                                  : isOccupied
                                      ? Colors.red[400]
                                      : Colors.green[400],
                            ),
                          ),
                          if (!isOccupied && !isMaint) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.add_circle_outline, color: Colors.green[400], size: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  void _showBookingDetail(Booking booking) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen()));
  }

  void _createBooking(Room room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddBookingScreen(preselectedRoomId: room.id),
      ),
    ).then((_) => _loadData());
  }
}
