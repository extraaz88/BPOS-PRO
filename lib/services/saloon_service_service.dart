import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos/model/saloon_service_model.dart';

class SaloonServiceService {
  static const String _servicesKey = 'saloon_services';

  // Get all services
  static Future<List<SaloonServiceModel>> getAllServices() async {
    final prefs = await SharedPreferences.getInstance();
    final String? servicesJson = prefs.getString(_servicesKey);

    if (servicesJson == null) {
      return [];
    }

    final List<dynamic> servicesList = json.decode(servicesJson);
    return servicesList
        .map((json) => SaloonServiceModel.fromMap(json))
        .toList();
  }

  // Add a new service
  static Future<void> addService(SaloonServiceModel service) async {
    final services = await getAllServices();

    // Generate a new ID
    final newId = services.isEmpty
        ? 1
        : services.map((s) => s.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;

    service.id = newId;
    services.add(service);

    await _saveServices(services);
  }

  // Update an existing service
  static Future<void> updateService(SaloonServiceModel service) async {
    final services = await getAllServices();
    final index = services.indexWhere((s) => s.id == service.id);

    if (index != -1) {
      services[index] = service;
      await _saveServices(services);
    }
  }

  // Delete a service
  static Future<void> deleteService(int id) async {
    final services = await getAllServices();
    services.removeWhere((service) => service.id == id);
    await _saveServices(services);
  }

  // Save services to shared preferences
  static Future<void> _saveServices(List<SaloonServiceModel> services) async {
    final prefs = await SharedPreferences.getInstance();
    final servicesJson = json.encode(services.map((s) => s.toMap()).toList());
    await prefs.setString(_servicesKey, servicesJson);
  }
}
