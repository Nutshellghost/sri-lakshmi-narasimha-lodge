class Booking {
  final int? id;
  final int roomId;
  final int guestId;
  final String guestName;
  final String guestPhone;
  final String roomNumber;
  final String roomType;
  final double roomPrice;
  final DateTime checkInDate;
  final DateTime? checkOutDate;
  final double advanceAmount;
  final double? totalAmount;
  final String status; // active, checked_out, cancelled
  final String? notes;
  final DateTime createdAt;

  Booking({
    this.id,
    required this.roomId,
    required this.guestId,
    required this.guestName,
    required this.guestPhone,
    required this.roomNumber,
    required this.roomType,
    required this.roomPrice,
    required this.checkInDate,
    this.checkOutDate,
    this.advanceAmount = 0.0,
    this.totalAmount,
    this.status = 'active',
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get balanceAmount {
    if (totalAmount == null) return 0;
    return totalAmount! - advanceAmount;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'room_id': roomId,
      'guest_id': guestId,
      'guest_name': guestName,
      'guest_phone': guestPhone,
      'room_number': roomNumber,
      'room_type': roomType,
      'room_price': roomPrice,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate?.toIso8601String(),
      'advance_amount': advanceAmount,
      'total_amount': totalAmount,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as int?,
      roomId: map['room_id'] as int,
      guestId: map['guest_id'] as int,
      guestName: map['guest_name'] as String,
      guestPhone: map['guest_phone'] as String,
      roomNumber: map['room_number'] as String,
      roomType: map['room_type'] as String,
      roomPrice: (map['room_price'] as num).toDouble(),
      checkInDate: DateTime.parse(map['check_in_date'] as String),
      checkOutDate: map['check_out_date'] != null
          ? DateTime.parse(map['check_out_date'] as String)
          : null,
      advanceAmount: (map['advance_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['total_amount'] as num?)?.toDouble(),
      status: map['status'] as String? ?? 'active',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static const List<String> statuses = ['active', 'checked_out', 'cancelled'];
}
