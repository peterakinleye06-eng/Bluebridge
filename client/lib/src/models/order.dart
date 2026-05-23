class Order {
  final int id;
  final int? userId;
  final String status;
  final double totalAmount;
  final String deliveryAddress;
  final String? deliveryNotes;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    this.userId,
    required this.status,
    required this.totalAmount,
    required this.deliveryAddress,
    this.deliveryNotes,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      status: json['status'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      deliveryAddress: json['delivery_address'],
      deliveryNotes: json['delivery_notes'],
      paymentMethod: json['payment_method'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'total_amount': totalAmount,
      'delivery_address': deliveryAddress,
      'delivery_notes': deliveryNotes,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}