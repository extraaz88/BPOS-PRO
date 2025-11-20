class SaloonServiceModel {
  int? id;
  String serviceName;
  String price;
  int duration; // in minutes

  SaloonServiceModel({
    this.id,
    required this.serviceName,
    required this.price,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceName': serviceName,
      'price': price,
      'duration': duration,
    };
  }

  factory SaloonServiceModel.fromMap(Map<String, dynamic> map) {
    return SaloonServiceModel(
      id: map['id'],
      serviceName: map['serviceName'] ?? '',
      price: map['price'] ?? '0',
      duration: map['duration'] ?? 0,
    );
  }
}
