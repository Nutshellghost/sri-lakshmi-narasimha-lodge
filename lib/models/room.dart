class Room {
  final int? id;
  final String roomNumber;
  final String roomType; // AC, Non-AC, Deluxe, Standard, Dormitory
  final double price;
  final int capacity;
  final String status; // vacant, occupied, maintenance
  final String? description;
  final DateTime createdAt;

  Room({
    this.id,
    required this.roomNumber,
    required this.roomType,
    required this.price,
    this.capacity = 2,
    this.status = 'vacant',
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'room_number': roomNumber,
      'room_type': roomType,
      'price': price,
      'capacity': capacity,
      'status': status,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] as int?,
      roomNumber: map['room_number'] as String,
      roomType: map['room_type'] as String,
      price: (map['price'] as num).toDouble(),
      capacity: map['capacity'] as int,
      status: map['status'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Room copyWith({
    int? id,
    String? roomNumber,
    String? roomType,
    double? price,
    int? capacity,
    String? status,
    String? description,
  }) {
    return Room(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      roomType: roomType ?? this.roomType,
      price: price ?? this.price,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt,
    );
  }

  static const List<String> roomTypes = ['Non-AC', 'AC', 'Deluxe', 'Standard', 'Dormitory'];
  static const List<String> statuses = ['vacant', 'occupied', 'maintenance'];
}
