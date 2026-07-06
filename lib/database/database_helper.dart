import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import '../models/room.dart';
import '../models/guest.dart';
import '../models/booking.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  /// Helper: extract int value from first row, first column of a rawQuery result.
  int _firstInt(List<Map<String, dynamic>>? result) {
    if (result == null || result.isEmpty) return 0;
    return (result.first.values.first as num?)?.toInt() ?? 0;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Web uses IndexedDB — logical path name only. Native uses filesystem path.
    final dbName = 'sri_lakshmi_narasimha_lodge.db';
    final path = kIsWeb ? dbName : p.join(await getDatabasesPath(), dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_number TEXT NOT NULL UNIQUE,
        room_type TEXT NOT NULL,
        price REAL NOT NULL,
        capacity INTEGER NOT NULL DEFAULT 2,
        status TEXT NOT NULL DEFAULT 'vacant',
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE guests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        id_proof_type TEXT,
        id_proof_number TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_id INTEGER NOT NULL,
        guest_id INTEGER NOT NULL,
        guest_name TEXT NOT NULL,
        guest_phone TEXT NOT NULL,
        room_number TEXT NOT NULL,
        room_type TEXT NOT NULL,
        room_price REAL NOT NULL,
        check_in_date TEXT NOT NULL,
        check_out_date TEXT,
        advance_amount REAL NOT NULL DEFAULT 0,
        total_amount REAL,
        status TEXT NOT NULL DEFAULT 'active',
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (room_id) REFERENCES rooms(id),
        FOREIGN KEY (guest_id) REFERENCES guests(id)
      )
    ''');

    // Insert some default rooms
    final now = DateTime.now().toIso8601String();
    final defaultRooms = [
      {'room_number': '101', 'room_type': 'Non-AC', 'price': 800.0, 'capacity': 2, 'status': 'vacant', 'description': 'Standard Non-AC Room', 'created_at': now},
      {'room_number': '102', 'room_type': 'Non-AC', 'price': 800.0, 'capacity': 2, 'status': 'vacant', 'description': 'Standard Non-AC Room', 'created_at': now},
      {'room_number': '103', 'room_type': 'Non-AC', 'price': 800.0, 'capacity': 2, 'status': 'vacant', 'description': 'Standard Non-AC Room', 'created_at': now},
      {'room_number': '104', 'room_type': 'AC', 'price': 1200.0, 'capacity': 2, 'status': 'vacant', 'description': 'AC Room', 'created_at': now},
      {'room_number': '105', 'room_type': 'AC', 'price': 1200.0, 'capacity': 2, 'status': 'vacant', 'description': 'AC Room', 'created_at': now},
      {'room_number': '201', 'room_type': 'Deluxe', 'price': 1800.0, 'capacity': 3, 'status': 'vacant', 'description': 'Deluxe Room with extra space', 'created_at': now},
      {'room_number': '202', 'room_type': 'Deluxe', 'price': 1800.0, 'capacity': 3, 'status': 'vacant', 'description': 'Deluxe Room with extra space', 'created_at': now},
    ];
    for (final room in defaultRooms) {
      await db.insert('rooms', room);
    }
  }

  // ========== ROOMS ==========

  Future<int> insertRoom(Room room) async {
    final db = await database;
    return await db.insert('rooms', room.toMap());
  }

  Future<List<Room>> getRooms({String? statusFilter}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (statusFilter != null) {
      maps = await db.query('rooms', where: 'status = ?', whereArgs: [statusFilter], orderBy: 'room_number ASC');
    } else {
      maps = await db.query('rooms', orderBy: 'room_number ASC');
    }
    return maps.map((m) => Room.fromMap(m)).toList();
  }

  Future<Room?> getRoom(int id) async {
    final db = await database;
    final maps = await db.query('rooms', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Room.fromMap(maps.first);
  }

  Future<int> updateRoom(Room room) async {
    final db = await database;
    return await db.update('rooms', room.toMap(), where: 'id = ?', whereArgs: [room.id]);
  }

  Future<int> deleteRoom(int id) async {
    final db = await database;
    return await db.delete('rooms', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getVacantRoomCount() async {
    final db = await database;
    final result = await db.rawQuery("SELECT COUNT(*) as count FROM rooms WHERE status = 'vacant'");
    return _firstInt(result);
  }

  Future<int> getTotalRoomCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM rooms');
    return _firstInt(result);
  }

  // ========== GUESTS ==========

  Future<int> insertGuest(Guest guest) async {
    final db = await database;
    return await db.insert('guests', guest.toMap());
  }

  Future<List<Guest>> getGuests() async {
    final db = await database;
    final maps = await db.query('guests', orderBy: 'created_at DESC');
    return maps.map((m) => Guest.fromMap(m)).toList();
  }

  Future<Guest?> getGuest(int id) async {
    final db = await database;
    final maps = await db.query('guests', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Guest.fromMap(maps.first);
  }

  Future<List<Guest>> searchGuests(String query) async {
    final db = await database;
    final maps = await db.query(
      'guests',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Guest.fromMap(m)).toList();
  }

  Future<List<Room>> searchRooms(String query) async {
    final db = await database;
    final maps = await db.query(
      'rooms',
      where: 'room_number LIKE ? OR room_type LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'room_number ASC',
    );
    return maps.map((m) => Room.fromMap(m)).toList();
  }

  Future<List<Booking>> searchBookings(String query) async {
    final db = await database;
    final maps = await db.query(
      'bookings',
      where: 'guest_name LIKE ? OR room_number LIKE ? OR guest_phone LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  Future<int> updateGuest(Guest guest) async {
    final db = await database;
    return await db.update('guests', guest.toMap(), where: 'id = ?', whereArgs: [guest.id]);
  }

  // ========== BOOKINGS ==========

  Future<int> insertBooking(Booking booking) async {
    final db = await database;
    final id = await db.insert('bookings', booking.toMap());
    // Update room status to occupied
    await db.update('rooms', {'status': 'occupied'}, where: 'id = ?', whereArgs: [booking.roomId]);
    return id;
  }

  Future<List<Booking>> getBookings({String? statusFilter}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (statusFilter != null) {
      maps = await db.query('bookings', where: 'status = ?', whereArgs: [statusFilter], orderBy: 'created_at DESC');
    } else {
      maps = await db.query('bookings', orderBy: 'created_at DESC');
    }
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  Future<List<Booking>> getActiveBookings() async {
    final db = await database;
    final maps = await db.query(
      'bookings',
      where: "status = 'active'",
      orderBy: 'check_in_date DESC',
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  Future<List<Booking>> getTodayCheckIns() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final maps = await db.query(
      'bookings',
      where: 'check_in_date >= ? AND check_in_date < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'check_in_date DESC',
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  Future<Booking?> getBooking(int id) async {
    final db = await database;
    final maps = await db.query('bookings', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Booking.fromMap(maps.first);
  }

  Future<int> updateBooking(Booking booking) async {
    final db = await database;
    return await db.update('bookings', booking.toMap(), where: 'id = ?', whereArgs: [booking.id]);
  }

  Future<void> checkoutBooking(int bookingId, int roomId, DateTime checkOutDate, double totalAmount) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'bookings',
        {
          'status': 'checked_out',
          'check_out_date': checkOutDate.toIso8601String(),
          'total_amount': totalAmount,
        },
        where: 'id = ?',
        whereArgs: [bookingId],
      );
      await txn.update('rooms', {'status': 'vacant'}, where: 'id = ?', whereArgs: [roomId]);
    });
  }

  Future<void> cancelBooking(int bookingId, int roomId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'bookings',
        {'status': 'cancelled'},
        where: 'id = ?',
        whereArgs: [bookingId],
      );
      await txn.update('rooms', {'status': 'vacant'}, where: 'id = ?', whereArgs: [roomId]);
    });
  }

  Future<void> extendBooking(int bookingId, DateTime newCheckOutDate, double newTotalAmount) async {
    final db = await database;
    await db.update(
      'bookings',
      {
        'check_out_date': newCheckOutDate.toIso8601String(),
        'total_amount': newTotalAmount,
      },
      where: 'id = ?',
      whereArgs: [bookingId],
    );
  }

  Future<List<Booking>> getGuestBookings(int guestId) async {
    final db = await database;
    final maps = await db.query(
      'bookings',
      where: 'guest_id = ?',
      whereArgs: [guestId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  // ========== AVAILABILITY ==========

  /// Returns all active bookings that overlap with [date] (any time during that day).
  Future<List<Booking>> getBookingsForDate(DateTime date) async {
    final db = await database;
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final maps = await db.rawQuery('''
      SELECT * FROM bookings
      WHERE status = 'active'
        AND check_in_date < ?
        AND (check_out_date IS NULL OR check_out_date > ?)
      ORDER BY room_number ASC
    ''', [dayEnd.toIso8601String(), dayStart.toIso8601String()]);
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  /// Returns a map of room_id → Booking for all rooms occupied on [date].
  Future<Map<int, Booking>> getOccupiedRoomsForDate(DateTime date) async {
    final bookings = await getBookingsForDate(date);
    return {for (final b in bookings) b.roomId: b};
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final totalRooms = _firstInt(
      await db.rawQuery('SELECT COUNT(*) FROM rooms'),
    );

    final vacantRooms = _firstInt(
      await db.rawQuery("SELECT COUNT(*) FROM rooms WHERE status = 'vacant'"),
    );

    final occupiedRooms = _firstInt(
      await db.rawQuery("SELECT COUNT(*) FROM rooms WHERE status = 'occupied'"),
    );

    final activeBookings = _firstInt(
      await db.rawQuery("SELECT COUNT(*) FROM bookings WHERE status = 'active'"),
    );

    // Today's check-ins
    final todayCheckIns = _firstInt(
      await db.rawQuery(
        "SELECT COUNT(*) FROM bookings WHERE status = 'active' AND check_in_date >= ? AND check_in_date < ?",
        [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      ),
    );

    // Today's revenue (checked out today)
    final todayRevenue = await db.rawQuery(
      "SELECT COALESCE(SUM(total_amount), 0) as revenue FROM bookings WHERE status = 'checked_out' AND check_out_date >= ? AND check_out_date < ?",
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    // Total advance collected (active bookings)
    final totalAdvance = await db.rawQuery(
      "SELECT COALESCE(SUM(advance_amount), 0) as advance FROM bookings WHERE status = 'active'",
    );

    return {
      'totalRooms': totalRooms,
      'vacantRooms': vacantRooms,
      'occupiedRooms': occupiedRooms,
      'activeBookings': activeBookings,
      'todayCheckIns': todayCheckIns,
      'todayRevenue': (todayRevenue.isNotEmpty ? todayRevenue.first['revenue'] : 0) ?? 0,
      'totalAdvance': (totalAdvance.isNotEmpty ? totalAdvance.first['advance'] : 0) ?? 0,
    };
  }
}
