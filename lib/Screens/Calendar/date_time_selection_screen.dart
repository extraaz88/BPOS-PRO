import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/model/appointment_model.dart';
import 'package:mobile_pos/services/appointment_service.dart';
import 'package:mobile_pos/Screens/Home/home.dart';

class DateTimeSelectionScreen extends StatefulWidget {
  final List<String> selectedServices;
  final List<Map<String, dynamic>> servicesData;

  const DateTimeSelectionScreen({
    super.key,
    required this.selectedServices,
    required this.servicesData,
  });

  @override
  State<DateTimeSelectionScreen> createState() =>
      _DateTimeSelectionScreenState();
}

class _DateTimeSelectionScreenState extends State<DateTimeSelectionScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '';
  DateTime _focusedDate = DateTime.now();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<String> _timeSlots = [
    '9:00 am',
    '10:00 am',
    '11:00 am',
    '12:00 pm',
    '1:00 pm',
    '2:00 pm',
    '3:00 pm',
    '4:00 pm',
    '5:00 pm',
    '6:00 pm',
    '7:00 pm',
    '8:00 pm',
  ];

  @override
  void initState() {
    super.initState();
    // Set default selected time to first available slot
    if (_timeSlots.isNotEmpty) {
      _selectedTime = _timeSlots[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth > 600;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: isTablet ? 28 : 24,
              ),
            ),
            title: Text(
              'Select Date & Time',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 22 : 18,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Calendar Section
                Container(
                  margin: EdgeInsets.all(isTablet ? 24 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    child: _buildCalendar(isTablet),
                  ),
                ),

                // Time Selection Section
                Container(
                  margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Time',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: isTablet ? 16 : 12),
                      Container(
                        height: isTablet ? 60 : 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _timeSlots.length,
                          itemBuilder: (context, index) {
                            final time = _timeSlots[index];
                            final isSelected = _selectedTime == time;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTime = time;
                                });
                              },
                              child: Container(
                                margin:
                                    EdgeInsets.only(right: isTablet ? 16 : 12),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 20 : 16,
                                  vertical: isTablet ? 12 : 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected ? kMainColor : Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 30 : 25),
                                  border: Border.all(
                                    color: isSelected
                                        ? kMainColor
                                        : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    time,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isTablet ? 16 : 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isTablet ? 24 : 20),

                // Service Summary Card
                Container(
                  margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Services (${widget.selectedServices.length})',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: isTablet ? 16 : 12),
                      // Services list
                      ...widget.servicesData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final service = entry.value;
                        final colors = [
                          kMainColor,
                          Colors.blue,
                          Colors.green,
                          Colors.orange,
                          Colors.purple,
                          Colors.teal,
                          Colors.pink,
                          Colors.indigo,
                        ];
                        final color = colors[index % colors.length];

                        return Container(
                          margin: EdgeInsets.only(bottom: isTablet ? 8 : 6),
                          padding: EdgeInsets.all(isTablet ? 12 : 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(isTablet ? 8 : 6),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: isTablet ? 12 : 8),
                              Expanded(
                                child: Text(
                                  service['name'],
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ),
                              Text(
                                service['price'],
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      // Total price
                      Container(
                        margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
                        padding: EdgeInsets.all(isTablet ? 12 : 8),
                        decoration: BoxDecoration(
                          color: kMainColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                          border:
                              Border.all(color: kMainColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.bold,
                                color: kMainColor,
                              ),
                            ),
                            Text(
                              '₹${_calculateTotalPrice()}',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.bold,
                                color: kMainColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isTablet ? 16 : 12),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.grey[600],
                            size: isTablet ? 20 : 18,
                          ),
                          SizedBox(width: isTablet ? 12 : 8),
                          Text(
                            'Date',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: isTablet ? 8 : 4),
                          Text(
                            '${_getMonthName(_selectedDate.month)}, ${_selectedDate.day}',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 12 : 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.grey[600],
                            size: isTablet ? 20 : 18,
                          ),
                          SizedBox(width: isTablet ? 12 : 8),
                          Text(
                            'Time',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: isTablet ? 8 : 4),
                          Text(
                            _selectedTime,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: isTablet ? 8 : 4),
                          GestureDetector(
                            onTap: () {
                              // Show time picker or scroll to time selection
                            },
                            child: Icon(
                              Icons.edit,
                              color: Colors.grey[600],
                              size: isTablet ? 18 : 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isTablet ? 24 : 20),

                // Customer Information Card
                Container(
                  margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Information',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: isTablet ? 16 : 12),
                      TextField(
                        controller: _customerNameController,
                        decoration: InputDecoration(
                          labelText: 'Customer Name *',
                          hintText: 'Enter customer name',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(isTablet ? 12 : 8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 12,
                            vertical: isTablet ? 16 : 12,
                          ),
                        ),
                      ),
                      SizedBox(height: isTablet ? 16 : 12),
                      TextField(
                        controller: _customerPhoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number *',
                          hintText: 'Enter 10-digit phone number',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(isTablet ? 12 : 8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 12,
                            vertical: isTablet ? 16 : 12,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        onChanged: (value) {
                          // Only allow digits
                          if (value.length > 10) {
                            _customerPhoneController.text =
                                value.substring(0, 10);
                            _customerPhoneController.selection =
                                TextSelection.collapsed(
                              offset: _customerPhoneController.text.length,
                            );
                          }
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      SizedBox(height: isTablet ? 16 : 12),
                      TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Any additional notes',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(isTablet ? 12 : 8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 12,
                            vertical: isTablet ? 16 : 12,
                          ),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isTablet ? 24 : 20),

                // Book Appointment Button
                Container(
                  margin: EdgeInsets.all(isTablet ? 24 : 16),
                  width: double.infinity,
                  height: isTablet ? 60 : 50,
                  child: ElevatedButton(
                    onPressed: () {
                      _showBookingConfirmation();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMainColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Book Appointment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Add extra padding at bottom to ensure button is not cut off
                SizedBox(height: isTablet ? 24 : 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendar(bool isTablet) {
    return Column(
      children: [
        // Month header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _focusedDate = DateTime(
                    _focusedDate.year,
                    _focusedDate.month - 1,
                  );
                });
              },
              icon: Icon(
                Icons.chevron_left,
                color: Colors.grey,
                size: isTablet ? 28 : 24,
              ),
            ),
            Text(
              '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}',
              style: TextStyle(
                fontSize: isTablet ? 22 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _focusedDate = DateTime(
                    _focusedDate.year,
                    _focusedDate.month + 1,
                  );
                });
              },
              icon: Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: isTablet ? 28 : 24,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 20 : 16),
        // Calendar grid
        _buildCalendarGrid(isTablet),
      ],
    );
  }

  Widget _buildCalendarGrid(bool isTablet) {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    // Day headers
    final dayHeaders = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return Column(
      children: [
        // Day headers
        Row(
          children: dayHeaders.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            final isWeekend = index == 0 || index == 6; // Sunday or Saturday

            return Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isWeekend ? Colors.red : Colors.black,
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        // Calendar days
        Column(
          children: List.generate(6, (weekIndex) {
            return Row(
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - firstDayOfWeek + 1;
                final isCurrentMonth =
                    dayNumber > 0 && dayNumber <= daysInMonth;
                final isSelected = isCurrentMonth &&
                    dayNumber == _selectedDate.day &&
                    _focusedDate.month == _selectedDate.month &&
                    _focusedDate.year == _selectedDate.year;
                final isWeekend =
                    dayIndex == 0 || dayIndex == 6; // Sunday or Saturday

                return Expanded(
                  child: GestureDetector(
                    onTap: isCurrentMonth
                        ? () {
                            setState(() {
                              _selectedDate = DateTime(
                                _focusedDate.year,
                                _focusedDate.month,
                                dayNumber,
                              );
                            });
                          }
                        : null,
                    child: Container(
                      height: isTablet ? 50 : 40,
                      margin: EdgeInsets.all(isTablet ? 2 : 1),
                      decoration: BoxDecoration(
                        color: isSelected ? kMainColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                      ),
                      child: Center(
                        child: Text(
                          isCurrentMonth ? dayNumber.toString() : '',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isWeekend && isCurrentMonth
                                    ? Colors.red
                                    : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: isTablet ? 18 : 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  String _calculateTotalPrice() {
    double total = 0.0;
    for (var service in widget.servicesData) {
      final price =
          service['price'].toString().replaceAll(RegExp(r'[^\d.]'), '');
      total += double.tryParse(price) ?? 0.0;
    }
    return total.toStringAsFixed(0);
  }

  void _showBookingConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isTablet = screenWidth > 600;

            return AlertDialog(
              title: Text(
                'Confirm Booking',
                style: TextStyle(fontSize: isTablet ? 20 : 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Services: ${widget.selectedServices.join(", ")}',
                    style: TextStyle(fontSize: isTablet ? 16 : 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Date: ${_getMonthName(_selectedDate.month)}, ${_selectedDate.day}',
                    style: TextStyle(fontSize: isTablet ? 16 : 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Time: $_selectedTime',
                    style: TextStyle(fontSize: isTablet ? 16 : 14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: isTablet ? 16 : 14),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);

                    // Validate customer name
                    if (_customerNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter customer name'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Validate phone number (required)
                    final phoneNumber = _customerPhoneController.text.trim();
                    if (phoneNumber.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter phone number'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (phoneNumber.length != 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Phone number must be exactly 10 digits'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Create appointment with multiple services
                    final services = widget.servicesData
                        .map((serviceData) => ServiceItem(
                              name: serviceData['name'],
                              price: serviceData['price'],
                              duration: serviceData['duration'] ?? 30,
                            ))
                        .toList();

                    // Calculate total price and duration
                    double totalPrice = 0;
                    int totalDuration = 0;
                    for (var service in services) {
                      totalPrice += double.tryParse(service.price
                              .toString()
                              .replaceAll(RegExp(r'[^\d.]'), '')) ??
                          0;
                      totalDuration += service.duration;
                    }

                    final appointment = AppointmentModel(
                      services: services,
                      appointmentDate: _selectedDate,
                      appointmentTime: _selectedTime,
                      customerName: _customerNameController.text.trim(),
                      customerPhone: _customerPhoneController.text.trim(),
                      totalPrice: totalPrice.toStringAsFixed(2),
                      totalDuration: totalDuration,
                    );

                    // Save appointment
                    await AppointmentService.addAppointment(appointment);

                    // Navigate back to home screen (which has bottom navigation)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const Home()),
                      (route) => false,
                    );

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Appointment booked successfully!'),
                        backgroundColor: kMainColor,
                      ),
                    );
                  },
                  child: Text(
                    'Confirm',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: kMainColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
