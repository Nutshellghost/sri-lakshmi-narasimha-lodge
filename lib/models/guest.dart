class Guest {
  final int? id;
  final String name;
  final String phone;
  final String? address;
  final String? idProofType; // Aadhar, Voter ID, Driving License, Pan Card
  final String? idProofNumber;
  final DateTime createdAt;

  Guest({
    this.id,
    required this.name,
    required this.phone,
    this.address,
    this.idProofType,
    this.idProofNumber,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'id_proof_type': idProofType,
      'id_proof_number': idProofNumber,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Guest.fromMap(Map<String, dynamic> map) {
    return Guest(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String?,
      idProofType: map['id_proof_type'] as String?,
      idProofNumber: map['id_proof_number'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get maskedPhone {
    if (phone.length >= 10) {
      return '${phone.substring(0, 3)}****${phone.substring(phone.length - 3)}';
    }
    return phone;
  }

  static const List<String> idProofTypes = [
    'Aadhar Card',
    'Voter ID',
    'Driving License',
    'Pan Card',
    'Passport',
    'Other',
  ];
}
