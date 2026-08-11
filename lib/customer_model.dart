class Customer {
  final int id;
  final String name;
  final String phone;
  final String area;
  final String callTime;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.area,
    required this.callTime,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      area: json['area'] ?? '',
      callTime: json['call_time'] ?? '',
    );
  }
}
