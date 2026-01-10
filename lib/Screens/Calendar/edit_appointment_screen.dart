import 'package:flutter/material.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/model/appointment_model.dart';
import 'package:mobile_pos/services/appointment_service.dart';
import 'package:mobile_pos/model/saloon_service_model.dart';
import 'package:mobile_pos/services/saloon_service_service.dart';
import 'package:intl/intl.dart';

class EditAppointmentScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const EditAppointmentScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late List<ServiceItem> _services;

  List<SaloonServiceModel> _availableServices = [];

  @override
  void initState() {
    super.initState();
    _loadSaloonServices();
    _customerNameController =
        TextEditingController(text: widget.appointment.customerName);
    _customerPhoneController =
        TextEditingController(text: widget.appointment.customerPhone);
    _selectedDate = widget.appointment.appointmentDate;

    // Parse the time string to TimeOfDay
    final timeParts = widget.appointment.appointmentTime.split(':');
    int hour = 0;
    int minute = 0;

    if (timeParts.isNotEmpty) {
      // Handle both 12-hour and 24-hour formats
      if (widget.appointment.appointmentTime.contains('AM') ||
          widget.appointment.appointmentTime.contains('PM')) {
        // 12-hour format
        final timeFormat = DateFormat.jm();
        try {
          final parsedTime =
              timeFormat.parse(widget.appointment.appointmentTime);
          hour = parsedTime.hour;
          minute = parsedTime.minute;
        } catch (e) {
          hour = 9;
          minute = 0;
        }
      } else {
        // 24-hour format or simple format
        hour = int.tryParse(timeParts[0]) ?? 9;
        if (timeParts.length > 1) {
          minute =
              int.tryParse(timeParts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        }
      }
    }

    _selectedTime = TimeOfDay(hour: hour, minute: minute);
    _services = List.from(widget.appointment.services);
  }

  Future<void> _loadSaloonServices() async {
    final services = await SaloonServiceService.getAllServices();
    setState(() {
      _availableServices = services;
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  void _addService() {
    setState(() {
      _services.add(ServiceItem(name: '', price: '0', duration: 30));
    });
  }

  void _removeService(int index) {
    if (_services.length > 1) {
      setState(() {
        _services.removeAt(index);
      });
    }
  }

  String _calculateTotalPrice() {
    double total = 0;
    for (var service in _services) {
      total += double.tryParse(service.price) ?? 0;
    }
    return total.toStringAsFixed(2);
  }

  int _calculateTotalDuration() {
    int total = 0;
    for (var service in _services) {
      total += service.duration;
    }
    return total;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kMainColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kMainColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _updateAppointment() async {
    if (_formKey.currentState!.validate()) {
      // Validate that all services have names
      bool allServicesValid = true;
      for (var service in _services) {
        if (service.name.trim().isEmpty) {
          allServicesValid = false;
          break;
        }
      }

      if (!allServicesValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all service names'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Use Walk-in Customer if name is empty
      String customerName = _customerNameController.text.trim().isEmpty
          ? 'Walk-in Customer'
          : _customerNameController.text.trim();

      String customerPhone = _customerPhoneController.text.trim().isEmpty
          ? '0000000000'
          : _customerPhoneController.text
              .trim()
              .replaceAll(RegExp(r'[^0-9]'), '');

      final updatedAppointment = AppointmentModel(
        id: widget.appointment.id,
        customerName: customerName,
        customerPhone: customerPhone,
        appointmentDate: _selectedDate,
        appointmentTime: _selectedTime.format(context),
        services: _services,
        totalPrice: _calculateTotalPrice(),
        totalDuration: _calculateTotalDuration(),
      );

      await AppointmentService.updateAppointment(updatedAppointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Appointment updated successfully'),
            backgroundColor: kMainColor,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Appointment',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Customer Information Section
            _buildSectionTitle('Customer Information'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _customerNameController,
              label: 'Customer Name',
              icon: Icons.person,
              validator:
                  null, // Made optional - will use Walk-in Customer if empty
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _customerPhoneController,
              label: 'Phone Number (Optional)',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              validator: (value) {
                // Made optional
                if (value != null && value.trim().isNotEmpty) {
                  // Remove any spaces or special characters
                  String phoneNumber =
                      value.trim().replaceAll(RegExp(r'[^0-9]'), '');
                  if (phoneNumber.length != 10) {
                    return 'Phone number must be exactly 10 digits';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Date & Time Section
            _buildSectionTitle('Date & Time'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeCard(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: DateFormat('MMM dd, yyyy').format(_selectedDate),
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateTimeCard(
                    icon: Icons.access_time,
                    label: 'Time',
                    value: _selectedTime.format(context),
                    onTap: () => _selectTime(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Services Section
            _buildSectionTitle('Services'),
            const SizedBox(height: 12),
            ..._services.asMap().entries.map((entry) {
              final index = entry.key;
              final service = entry.value;
              return _buildServiceCard(index, service);
            }).toList(),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addService,
              icon: const Icon(Icons.add),
              label: const Text('Add Service'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kMainColor,
                side: BorderSide(color: kMainColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Summary Section
            _buildSummaryCard(),

            const SizedBox(height: 24),

            // Update Button
            ElevatedButton(
              onPressed: _updateAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Update Appointment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kMainColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kMainColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        counterText: maxLength != null ? null : '',
      ),
    );
  }

  Widget _buildDateTimeCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: kMainColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(int index, ServiceItem service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Service ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (_services.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeService(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Searchable dropdown for service name
          InkWell(
            onTap: () => _showServiceSelectionDialog(index, service),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      service.name.isEmpty ? 'Select Service' : service.name,
                      style: TextStyle(
                        fontSize: 16,
                        color: service.name.isEmpty
                            ? Colors.grey[600]
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: Key('price_${index}_${service.name}_${service.price}'),
                  initialValue: service.price,
                  readOnly: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price (₹)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: Key(
                      'duration_${index}_${service.name}_${service.duration}'),
                  initialValue: service.duration.toString(),
                  readOnly: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Duration (min)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showServiceSelectionDialog(int index, ServiceItem service) {
    final TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Filter services based on search
            List<SaloonServiceModel> filteredServices = _availableServices
                .where((s) => s.serviceName
                    .toLowerCase()
                    .contains(searchController.text.toLowerCase()))
                .toList();

            return AlertDialog(
              title: const Text('Select Service'),
              contentPadding: const EdgeInsets.all(16),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search field
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search services...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    // Services list
                    if (_availableServices.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.design_services_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No services available',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Please add services first',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    else if (filteredServices.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No services found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredServices.length,
                          itemBuilder: (context, i) {
                            final saloonService = filteredServices[i];
                            return ListTile(
                              title: Text(saloonService.serviceName),
                              subtitle: Text(
                                '₹${saloonService.price} • ${saloonService.duration} min',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              onTap: () {
                                setState(() {
                                  // Update the service with selected saloon service data
                                  service.name = saloonService.serviceName;
                                  service.price = saloonService.price;
                                  service.duration = saloonService.duration;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kMainColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kMainColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Price:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              Text(
                '₹${_calculateTotalPrice()}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kMainColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Duration:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              Text(
                '${_calculateTotalDuration()} min',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
