class AppointmentModel {
  int? id;
  String customerName;
  String customerPhone;
  DateTime appointmentDate;
  String appointmentTime;
  List<ServiceItem> services;
  String totalPrice;
  int totalDuration;

  AppointmentModel({
    this.id,
    required this.customerName,
    required this.customerPhone,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.services,
    required this.totalPrice,
    required this.totalDuration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'appointmentDate': appointmentDate.toIso8601String(),
      'appointmentTime': appointmentTime,
      'services': services.map((s) => s.toMap()).toList(),
      'totalPrice': totalPrice,
      'totalDuration': totalDuration,
    };
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'],
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      appointmentDate: DateTime.parse(map['appointmentDate']),
      appointmentTime: map['appointmentTime'] ?? '',
      services:
          (map['services'] as List).map((s) => ServiceItem.fromMap(s)).toList(),
      totalPrice: map['totalPrice'] ?? '0',
      totalDuration: map['totalDuration'] ?? 0,
    );
  }
}

class ServiceItem {
  String name;
  String price;
  int duration;

  ServiceItem({
    required this.name,
    required this.price,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'duration': duration,
    };
  }

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      name: map['name'] ?? '',
      price: map['price'] ?? '0',
      duration: map['duration'] ?? 0,
    );
  }
}
