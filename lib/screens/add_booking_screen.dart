import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../database/lodge_provider.dart';
import '../models/booking.dart';
import '../models/guest.dart';
import '../models/room.dart';

class AddBookingScreen extends StatefulWidget {
  final int? preselectedRoomId;
  const AddBookingScreen({super.key, this.preselectedRoomId});

  @override
  State<AddBookingScreen> createState() => _AddBookingScreenState();
}

class _AddBookingScreenState extends State<AddBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Guest fields
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  String _idProofType = Guest.idProofTypes[0];

  // Booking fields
  Room? _selectedRoom;
  DateTime _checkInDate = DateTime.now();
  final _advanceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<Room> _vacantRooms = [];
  bool _isLoading = true;
  bool _isExistingGuest = false;
  List<Guest> _searchResults = [];
  Guest? _selectedGuest;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadVacantRooms();
  }

  Future<void> _loadVacantRooms() async {
    final provider = context.read<LodgeProvider>();
    await provider.loadRooms(statusFilter: 'vacant');
    final allRooms = provider.rooms;

    setState(() {
      _vacantRooms = allRooms.where((Room r) => r.status == 'vacant').toList();
      _isLoading = false;
      if (widget.preselectedRoomId != null) {
        _selectedRoom = _vacantRooms.cast<Room?>().firstWhere(
          (r) => r?.id == widget.preselectedRoomId,
          orElse: () => null,
        );
      }
    });
  }

  void _searchGuest(String query) async {
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    final results = await context.read<LodgeProvider>().searchGuests(query);
    setState(() {
      _searchResults = results;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Booking')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Existing guest toggle
                    SwitchListTile(
                      title: const Text('Existing Guest?'),
                      subtitle: Text(_isExistingGuest ? 'Search from records' : 'Enter new guest details'),
                      value: _isExistingGuest,
                      onChanged: (v) => setState(() {
                        _isExistingGuest = v;
                        _selectedGuest = null;
                        _searchResults = [];
                      }),
                      contentPadding: EdgeInsets.zero,
                    ),

                    if (_isExistingGuest) ...[
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search Guest by Name or Phone',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: _searchGuest,
                      ),
                      if (_searching) const Padding(
                        padding: EdgeInsets.all(8),
                        child: LinearProgressIndicator(),
                      ),
                      if (_searchResults.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (ctx, i) {
                              final g = _searchResults[i];
                              return RadioListTile<Guest>(
                                title: Text(g.name),
                                subtitle: Text(g.phone),
                                value: g,
                                groupValue: _selectedGuest,
                                onChanged: (v) => setState(() {
                                  _selectedGuest = v;
                                  _searchResults = [];
                                }),
                              );
                            },
                          ),
                        ),
                      if (_selectedGuest != null)
                        Card(
                          color: Colors.green[50],
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(_selectedGuest!.name[0].toUpperCase()),
                            ),
                            title: Text(_selectedGuest!.name),
                            subtitle: Text(_selectedGuest!.phone),
                            trailing: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _selectedGuest = null),
                            ),
                          ),
                        ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text('Guest Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Guest Name *', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Phone Number *', border: OutlineInputBorder()),
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(labelText: 'Address (optional)', border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _idProofType,
                        decoration: const InputDecoration(labelText: 'ID Proof Type', border: OutlineInputBorder()),
                        items: Guest.idProofTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _idProofType = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _idNumberCtrl,
                        decoration: const InputDecoration(labelText: 'ID Proof Number', border: OutlineInputBorder()),
                      ),
                    ],

                    const Divider(height: 32),

                    // Room selection
                    Text('Room Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    if (_vacantRooms.isEmpty)
                      Card(
                        color: Colors.orange[50],
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.orange),
                              SizedBox(width: 12),
                              Expanded(child: Text('No vacant rooms available!', style: TextStyle(fontWeight: FontWeight.w500))),
                            ],
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<Room>(
                        value: _selectedRoom,
                        decoration: const InputDecoration(labelText: 'Select Room *', border: OutlineInputBorder()),
                        items: _vacantRooms.map((r) => DropdownMenuItem(
                          value: r,
                          child: Text('Room ${r.roomNumber} - ${r.roomType} (₹${r.price.toStringAsFixed(0)})'),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedRoom = v),
                        validator: (v) => v == null ? 'Select a room' : null,
                      ),

                    const SizedBox(height: 16),

                    // Check-in date
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _checkInDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _checkInDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Check-in Date *',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(_checkInDate)),
                      ),
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _advanceCtrl,
                      decoration: InputDecoration(
                        labelText: 'Advance Amount (₹)',
                        border: const OutlineInputBorder(),
                        hintText: _selectedRoom != null ? 'Suggested: ₹${_selectedRoom!.price.toStringAsFixed(0)}' : null,
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Create Booking', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<LodgeProvider>();

    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a room')),
      );
      return;
    }

    try {
      int guestId;
      String guestName;
      String guestPhone;

      if (_isExistingGuest && _selectedGuest != null) {
        guestId = _selectedGuest!.id!;
        guestName = _selectedGuest!.name;
        guestPhone = _selectedGuest!.phone;
      } else if (_nameCtrl.text.isNotEmpty && _phoneCtrl.text.isNotEmpty) {
        // Create guest
        final guest = Guest(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          idProofType: _idProofType,
          idProofNumber: _idNumberCtrl.text.trim().isEmpty ? null : _idNumberCtrl.text.trim(),
        );
        guestId = await provider.addGuest(guest);
        guestName = guest.name;
        guestPhone = guest.phone;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter guest details or select an existing guest')),
        );
        return;
      }

      final advance = double.tryParse(_advanceCtrl.text.trim()) ?? 0.0;

      final booking = Booking(
        roomId: _selectedRoom!.id!,
        guestId: guestId,
        guestName: guestName,
        guestPhone: guestPhone,
        roomNumber: _selectedRoom!.roomNumber,
        roomType: _selectedRoom!.roomType,
        roomPrice: _selectedRoom!.price,
        checkInDate: _checkInDate,
        advanceAmount: advance,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      await provider.addBooking(booking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking created for Room ${_selectedRoom!.roomNumber}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _idNumberCtrl.dispose();
    _advanceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
