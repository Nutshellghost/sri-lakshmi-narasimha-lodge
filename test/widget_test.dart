import 'package:flutter_test/flutter_test.dart';
import 'package:sri_lakshmi_narasimha_lodge/models/room.dart';
import 'package:sri_lakshmi_narasimha_lodge/models/guest.dart';
import 'package:sri_lakshmi_narasimha_lodge/models/booking.dart';

void main() {
  group('Room model', () {
    test('create room with defaults', () {
      final room = Room(
        roomNumber: '101',
        roomType: 'AC',
        price: 1200.0,
      );
      expect(room.roomNumber, '101');
      expect(room.roomType, 'AC');
      expect(room.price, 1200.0);
      expect(room.status, 'vacant');
      expect(room.capacity, 2);
    });

    test('room toMap and fromMap roundtrip', () {
      final room = Room(
        id: 1,
        roomNumber: '101',
        roomType: 'AC',
        price: 1200.0,
        capacity: 2,
        status: 'occupied',
        description: 'Corner room',
      );
      final map = room.toMap();
      final restored = Room.fromMap(map);
      expect(restored.id, 1);
      expect(restored.roomNumber, '101');
      expect(restored.price, 1200.0);
      expect(restored.status, 'occupied');
    });
  });

  group('Guest model', () {
    test('create guest', () {
      final guest = Guest(
        name: 'John Doe',
        phone: '9876543210',
        address: 'Test Address',
        idProofType: 'Aadhar Card',
        idProofNumber: '1234-5678-9012',
      );
      expect(guest.name, 'John Doe');
      expect(guest.phone, '9876543210');
      expect(guest.maskedPhone.contains('****'), true);
    });
  });

  group('Booking model', () {
    test('create booking', () {
      final booking = Booking(
        roomId: 1,
        guestId: 1,
        guestName: 'John Doe',
        guestPhone: '9876543210',
        roomNumber: '101',
        roomType: 'AC',
        roomPrice: 1200.0,
        checkInDate: DateTime(2026, 7, 6),
        advanceAmount: 500.0,
        totalAmount: 1200.0,
      );
      expect(booking.status, 'active');
      expect(booking.balanceAmount, 700.0);
    });
  });
}
