import 'package:flutter/material.dart';
import 'database_helper.dart';
import '../models/room.dart';
import '../models/guest.dart';
import '../models/booking.dart';

class LodgeProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Room> _rooms = [];
  List<Room> get rooms => _rooms;

  List<Guest> _guests = [];
  List<Guest> get guests => _guests;

  List<Booking> _activeBookings = [];
  List<Booking> get activeBookings => _activeBookings;

  List<Booking> _allBookings = [];
  List<Booking> get allBookings => _allBookings;

  Map<String, dynamic> _stats = {};
  Map<String, dynamic> get stats => _stats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    await Future.wait([
      loadRooms(),
      loadGuests(),
      loadActiveBookings(),
      loadAllBookings(),
      loadStats(),
    ]);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRooms({String? statusFilter}) async {
    _rooms = await _db.getRooms(statusFilter: statusFilter);
    notifyListeners();
  }

  Future<void> loadGuests() async {
    _guests = await _db.getGuests();
    notifyListeners();
  }

  Future<void> loadActiveBookings() async {
    _activeBookings = await _db.getActiveBookings();
    notifyListeners();
  }

  Future<void> loadAllBookings() async {
    _allBookings = await _db.getBookings();
    notifyListeners();
  }

  Future<void> loadStats() async {
    _stats = await _db.getDashboardStats();
    notifyListeners();
  }

  Future<int> addRoom(Room room) async {
    final id = await _db.insertRoom(room);
    await loadRooms();
    await loadStats();
    return id;
  }

  Future<int> updateRoom(Room room) async {
    final result = await _db.updateRoom(room);
    await loadRooms();
    return result;
  }

  Future<int> deleteRoom(int id) async {
    final result = await _db.deleteRoom(id);
    await loadRooms();
    await loadStats();
    return result;
  }

  Future<int> addGuest(Guest guest) async {
    final id = await _db.insertGuest(guest);
    await loadGuests();
    return id;
  }

  Future<int> addBooking(Booking booking) async {
    final id = await _db.insertBooking(booking);
    await loadActiveBookings();
    await loadAllBookings();
    await loadRooms();
    await loadStats();
    return id;
  }

  Future<void> checkoutBooking(int bookingId, int roomId, DateTime checkOutDate, double totalAmount) async {
    await _db.checkoutBooking(bookingId, roomId, checkOutDate, totalAmount);
    await loadAll();
  }

  Future<void> cancelBooking(int bookingId, int roomId) async {
    await _db.cancelBooking(bookingId, roomId);
    await loadAll();
  }

  Future<void> extendBooking(int bookingId, DateTime newCheckOutDate, double newTotalAmount) async {
    await _db.extendBooking(bookingId, newCheckOutDate, newTotalAmount);
    await loadAll();
  }

  Future<List<Guest>> searchGuests(String query) async {
    return await _db.searchGuests(query);
  }

  Future<List<Room>> searchRooms(String query) async {
    return await _db.searchRooms(query);
  }

  Future<List<Booking>> searchBookings(String query) async {
    return await _db.searchBookings(query);
  }

  Future<List<Booking>> getGuestBookings(int guestId) async {
    return await _db.getGuestBookings(guestId);
  }

  Future<Room?> getRoom(int id) async => await _db.getRoom(id);
  Future<Guest?> getGuest(int id) async => await _db.getGuest(id);
  Future<Booking?> getBooking(int id) async => await _db.getBooking(id);
  Future<Map<int, Booking>> getOccupiedRoomsForDate(DateTime date) async =>
      await _db.getOccupiedRoomsForDate(date);
}
