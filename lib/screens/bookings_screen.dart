import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../database/lodge_provider.dart';
import '../models/booking.dart';
import 'add_booking_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBookingScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Checked Out'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: Consumer<LodgeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _BookingList(statusFilter: 'active'),
              _BookingList(statusFilter: 'checked_out'),
              _BookingList(statusFilter: null),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _BookingList extends StatelessWidget {
  final String? statusFilter;
  const _BookingList({this.statusFilter});

  @override
  Widget build(BuildContext context) {
    return Consumer<LodgeProvider>(
      builder: (context, provider, _) {
        final bookings = statusFilter == 'active'
            ? provider.activeBookings
            : statusFilter == 'checked_out'
                ? provider.allBookings.where((Booking b) => b.status == 'checked_out').toList()
                : provider.allBookings;

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_online_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  statusFilter == 'active'
                      ? 'No active bookings'
                      : statusFilter == 'checked_out'
                          ? 'No checked-out bookings'
                          : 'No bookings yet',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadAll(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _BookingCard(
                booking: booking,
                onTap: () => _showBookingDetails(context, booking),
                onCheckout: booking.status == 'active'
                    ? () => _checkoutBooking(context, booking)
                    : null,
                onCancel: booking.status == 'active'
                    ? () => _cancelBooking(context, booking)
                    : null,
                onExtend: booking.status == 'active'
                    ? () => _extendBooking(context, booking)
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  void _showBookingDetails(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Room ${booking.roomNumber} - ${booking.guestName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Guest', booking.guestName),
              _row('Phone', booking.guestPhone),
              _row('Room', '${booking.roomNumber} (${booking.roomType})'),
              _row('Check-in', DateFormat('dd/MM/yyyy HH:mm').format(booking.checkInDate)),
              if (booking.checkOutDate != null)
                _row('Check-out', DateFormat('dd/MM/yyyy HH:mm').format(booking.checkOutDate!)),
              _row('Room Price', '₹${booking.roomPrice.toStringAsFixed(0)}/night'),
              _row('Advance', '₹${booking.advanceAmount.toStringAsFixed(0)}'),
              if (booking.totalAmount != null)
                _row('Total Amount', '₹${booking.totalAmount!.toStringAsFixed(0)}'),
              if (booking.totalAmount != null)
                _row('Balance', '₹${booking.balanceAmount.toStringAsFixed(0)}',
                    valueColor: booking.balanceAmount > 0 ? Colors.red : Colors.green),
              _row('Status', booking.status.toUpperCase()),
              if (booking.notes != null) _row('Notes', booking.notes!),
              _row('Booked', DateFormat('dd/MM/yyyy HH:mm').format(booking.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _checkoutBooking(BuildContext context, Booking booking) async {
    final checkOutDate = DateTime.now();
    final nights = checkOutDate.difference(booking.checkInDate).inDays;
    final defaultTotal = booking.roomPrice * (nights > 0 ? nights : 1);

    final totalCtrl = TextEditingController(text: defaultTotal.toStringAsFixed(0));

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Check-out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Room ${booking.roomNumber} - ${booking.guestName}'),
            const SizedBox(height: 12),
            Text('Check-in: ${DateFormat('dd/MM/yyyy').format(booking.checkInDate)}'),
            Text('Check-out: ${DateFormat('dd/MM/yyyy').format(checkOutDate)}'),
            Text('Nights: ${nights > 0 ? nights : 1}'),
            const SizedBox(height: 8),
            Text('Advance Paid: ₹${booking.advanceAmount.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            TextField(
              controller: totalCtrl,
              decoration: const InputDecoration(
                labelText: 'Total Amount (₹)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final total = double.tryParse(totalCtrl.text.trim()) ?? defaultTotal;
              Navigator.pop(ctx, {'total': total, 'date': checkOutDate});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Check Out'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      final provider = context.read<LodgeProvider>();
      await provider.checkoutBooking(
        booking.id!,
        booking.roomId,
        result['date'] as DateTime,
        result['total'] as double,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room ${booking.roomNumber} checked out'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _cancelBooking(BuildContext context, Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text('Cancel booking for Room ${booking.roomNumber} (${booking.guestName})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final provider = context.read<LodgeProvider>();
      await provider.cancelBooking(booking.id!, booking.roomId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking for Room ${booking.roomNumber} cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _extendBooking(BuildContext context, Booking booking) async {
    final now = DateTime.now();
    final currentCheckOut = booking.checkOutDate ?? now;
    DateTime newCheckOut = currentCheckOut.add(const Duration(days: 1));

    // Calculate current total if not set yet
    final nightsSoFar = currentCheckOut.difference(booking.checkInDate).inDays;
    final currentTotal = booking.totalAmount ?? (booking.roomPrice * (nightsSoFar > 0 ? nightsSoFar : 1));

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        DateTime selectedDate = newCheckOut;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text('Extend Stay - Room ${booking.roomNumber}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Guest', booking.guestName),
                  _row('Check-in', DateFormat('dd/MM/yyyy').format(booking.checkInDate)),
                  _row('Current Check-out', booking.checkOutDate != null
                      ? DateFormat('dd/MM/yyyy').format(booking.checkOutDate!)
                      : 'Not set'),
                  _row('Room Rate', '₹${booking.roomPrice.toStringAsFixed(0)}/night'),
                  if (booking.totalAmount != null)
                    _row('Current Total', '₹${booking.totalAmount!.toStringAsFixed(0)}'),
                  const Divider(height: 20),
                  // New checkout date picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: currentCheckOut,
                        lastDate: currentCheckOut.add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'New Check-out Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Calculations
                  ..._buildExtendCalc(booking, selectedDate, currentTotal),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final additionalNights = _calcAdditionalNights(booking, selectedDate);
                  final additionalCharge = booking.roomPrice * additionalNights;
                  final newTotal = currentTotal + additionalCharge;
                  Navigator.pop(ctx, {'newDate': selectedDate, 'newTotal': newTotal});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm Extension'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null && context.mounted) {
      final provider = context.read<LodgeProvider>();
      await provider.extendBooking(
        booking.id!,
        result['newDate'] as DateTime,
        result['newTotal'] as double,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking extended successfully'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  double _calcAdditionalNights(Booking booking, DateTime newCheckOut) {
    final baseDate = booking.checkOutDate ?? booking.checkInDate;
    final diff = newCheckOut.difference(baseDate).inDays;
    return diff > 0 ? diff.toDouble() : 0;
  }

  List<Widget> _buildExtendCalc(Booking booking, DateTime newDate, double currentTotal) {
    final additionalNights = _calcAdditionalNights(booking, newDate);
    final additionalCharge = booking.roomPrice * additionalNights;
    final newTotal = currentTotal + additionalCharge;

    return [
      if (additionalNights > 0) ...[
        _row('Additional Nights', '${additionalNights.toInt()} night${additionalNights > 1 ? 's' : ''}'),
        _row('Additional Charges', '₹${additionalCharge.toStringAsFixed(0)}'),
      ] else
        _row('Note', 'New checkout must be after current', valueColor: Colors.red),
      const Divider(height: 16),
      _row('New Total', '₹${newTotal.toStringAsFixed(0)}', valueColor: Colors.blue[700]),
    ];
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback? onCheckout;
  final VoidCallback? onCancel;
  final VoidCallback? onExtend;

  const _BookingCard({
    required this.booking,
    required this.onTap,
    this.onCheckout,
    this.onCancel,
    this.onExtend,
  });

  Color _statusColor() {
    switch (booking.status) {
      case 'active':
        return Colors.green;
      case 'checked_out':
        return Colors.blue;
      case 'cancelled':
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.person, color: _statusColor()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.guestName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Room ${booking.roomNumber} - ${booking.roomType}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(color: _statusColor(), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(DateFormat('dd/MM/yy').format(booking.checkInDate), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const Spacer(),
                  Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(booking.guestPhone, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const Spacer(),
                  Icon(Icons.monetization_on, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('₹${booking.advanceAmount.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              if (onCheckout != null || onCancel != null || onExtend != null) ...[
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onCancel != null)
                      TextButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Cancel'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 8)),
                      ),
                    if (onExtend != null)
                      TextButton.icon(
                        onPressed: onExtend,
                        icon: const Icon(Icons.date_range, size: 18),
                        label: const Text('Extend'),
                        style: TextButton.styleFrom(foregroundColor: Colors.blue[700], padding: const EdgeInsets.symmetric(horizontal: 8)),
                      ),
                    const SizedBox(width: 4),
                    if (onCheckout != null)
                      ElevatedButton.icon(
                        onPressed: onCheckout,
                        icon: const Icon(Icons.exit_to_app, size: 18),
                        label: const Text('Check Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
              ];
            ],
          ),
        ),
      ),
    );
  }
}
