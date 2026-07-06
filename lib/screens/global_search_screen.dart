import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../database/lodge_provider.dart';
import '../models/room.dart';
import '../models/guest.dart';
import '../models/booking.dart';
import 'guests_screen.dart';
import 'bookings_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();

  List<Guest> _guests = [];
  List<Room> _rooms = [];
  List<Booking> _bookings = [];
  bool _searching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _guests = [];
        _rooms = [];
        _bookings = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() => _searching = true);
    final provider = context.read<LodgeProvider>();
    final results = await Future.wait([
      provider.searchGuests(query.trim()),
      provider.searchRooms(query.trim()),
      provider.searchBookings(query.trim()),
    ]);
    if (!mounted) return;
    setState(() {
      _guests = results[0] as List<Guest>;
      _rooms = results[1] as List<Room>;
      _bookings = results[2] as List<Booking>;
      _searching = false;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _guests.length + _rooms.length + _bookings.length;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          focusNode: _focusNode,
          onChanged: _search,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Search guests, rooms, bookings...',
            hintStyle: TextStyle(color: Colors.white60),
            border: InputBorder.none,
            filled: false,
          ),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchCtrl.clear();
                _search('');
              },
            ),
        ],
      ),
      body: _buildBody(total),
    );
  }

  Widget _buildBody(int total) {
    if (_searching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Search across guests, rooms & bookings',
                style: TextStyle(color: Colors.grey[500], fontSize: 15)),
            const SizedBox(height: 8),
            Text('Type a name, phone, or room number',
                style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ],
        ),
      );
    }

    if (total == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No results found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            Text('Try a different search term', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Results count header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text('$total result${total != 1 ? 's' : ''}',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ),
        if (_guests.isNotEmpty) _buildSection('Guests', _guests.length, Icons.person, _buildGuestList()),
        if (_rooms.isNotEmpty) _buildSection('Rooms', _rooms.length, Icons.meeting_room, _buildRoomList()),
        if (_bookings.isNotEmpty) _buildSection('Bookings', _bookings.length, Icons.book_online, _buildBookingList()),
      ],
    );
  }

  Widget _buildSection(String title, int count, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  List<Widget> _buildGuestList() {
    return _guests.map((g) => ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        child: Text(g.name[0].toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
      ),
      title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${g.phone}${g.address != null ? ' · ${g.address}' : ''}'),
      trailing: const Icon(Icons.chevron_right, size: 18),
      dense: true,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuestsScreen())),
    )).toList();
  }

  List<Widget> _buildRoomList() {
    return _rooms.map((r) => ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: r.status == 'vacant' ? Colors.green.withValues(alpha: 0.15) : r.status == 'occupied' ? Colors.red.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.meeting_room, color: r.status == 'vacant' ? Colors.green[700] : r.status == 'occupied' ? Colors.red[700] : Colors.orange[700], size: 20),
      ),
      title: Text('Room ${r.roomNumber}', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${r.roomType} · ₹${r.price.toStringAsFixed(0)}/night · ${r.status}'),
      trailing: Text(r.status.toUpperCase(), style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.bold,
        color: r.status == 'vacant' ? Colors.green : r.status == 'occupied' ? Colors.red : Colors.orange,
      )),
      dense: true,
    )).toList();
  }

  List<Widget> _buildBookingList() {
    return _bookings.map((b) => ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: b.status == 'active' ? Colors.green.withValues(alpha: 0.15) : b.status == 'checked_out' ? Colors.blue.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
        child: Icon(
          b.status == 'active' ? Icons.check_circle_outline : b.status == 'checked_out' ? Icons.exit_to_app : Icons.cancel,
          color: b.status == 'active' ? Colors.green : b.status == 'checked_out' ? Colors.blue : Colors.red,
          size: 20,
        ),
      ),
      title: Text('${b.guestName} · Room ${b.roomNumber}', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${b.roomType} · ${DateFormat('dd/MM/yy').format(b.checkInDate)}${b.totalAmount != null ? ' · ₹${b.totalAmount!.toStringAsFixed(0)}' : ''}'),
      trailing: Text(b.status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.bold,
        color: b.status == 'active' ? Colors.green : b.status == 'checked_out' ? Colors.blue : Colors.red,
      )),
      dense: true,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen())),
    )).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
