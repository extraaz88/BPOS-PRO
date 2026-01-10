import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos/model/appointment_model.dart';

class AppointmentService {
  static const String _appointmentsKey = 'appointments';

  // Get all appointments
  static Future<List<AppointmentModel>> getAllAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? appointmentsJson = prefs.getString(_appointmentsKey);

    if (appointmentsJson == null) {
      return [];
    }

    final List<dynamic> appointmentsList = json.decode(appointmentsJson);
    return appointmentsList
        .map((json) => AppointmentModel.fromMap(json))
        .toList();
  }

  // Get appointments for a specific date
  static Future<List<AppointmentModel>> getAppointmentsForDate(
      DateTime date) async {
    final allAppointments = await getAllAppointments();
    return allAppointments.where((appointment) {
      return appointment.appointmentDate.year == date.year &&
          appointment.appointmentDate.month == date.month &&
          appointment.appointmentDate.day == date.day;
    }).toList();
  }

  // Add a new appointment
  static Future<void> addAppointment(AppointmentModel appointment) async {
    final appointments = await getAllAppointments();

    // Generate a new ID
    final newId = appointments.isEmpty
        ? 1
        : appointments.map((a) => a.id ?? 0).reduce((a, b) => a > b ? a : b) +
            1;

    appointment.id = newId;
    appointments.add(appointment);

    await _saveAppointments(appointments);
  }

  // Update an existing appointment
  static Future<void> updateAppointment(AppointmentModel appointment) async {
    final appointments = await getAllAppointments();
    final index = appointments.indexWhere((a) => a.id == appointment.id);

    if (index != -1) {
      appointments[index] = appointment;
      await _saveAppointments(appointments);
    }
  }

  // Delete an appointment
  static Future<void> deleteAppointment(int id) async {
    final appointments = await getAllAppointments();
    appointments.removeWhere((appointment) => appointment.id == id);
    await _saveAppointments(appointments);
  }

  // Save appointments to shared preferences
  static Future<void> _saveAppointments(
      List<AppointmentModel> appointments) async {
    final prefs = await SharedPreferences.getInstance();
    final appointmentsJson =
        json.encode(appointments.map((a) => a.toMap()).toList());
    await prefs.setString(_appointmentsKey, appointmentsJson);
  }
}
