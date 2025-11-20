import 'package:flutter/material.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/Screens/Calendar/new_appointment_screen.dart';
import 'package:mobile_pos/Screens/Calendar/edit_appointment_screen.dart';
import 'package:mobile_pos/model/appointment_model.dart';
import 'package:mobile_pos/services/appointment_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  List<AppointmentModel> _appointments = [];
  Map<String, int> _appointmentCounts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh appointments when screen comes back into focus
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final appointments = await AppointmentService.getAllAppointments();
    setState(() {
      _appointments = appointments;
      _updateAppointmentCounts();
    });
  }

  void _updateAppointmentCounts() {
    _appointmentCounts.clear();
    for (final appointment in _appointments) {
      final dateKey =
          '${appointment.appointmentDate.year}-${appointment.appointmentDate.month}-${appointment.appointmentDate.day}';
      _appointmentCounts[dateKey] = (_appointmentCounts[dateKey] ?? 0) + 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Calendar',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: _loadAppointments,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh appointments',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: kMainColor,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Month'),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Week'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMonthView(),
          _buildWeekView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to New Appointment screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewAppointmentScreen(),
            ),
          );
        },
        backgroundColor: kMainColor,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildMonthView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth > 600;

        return Container(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Column(
            children: [
              // Month header
              Container(
                padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                child: Row(
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
                      icon: Icon(Icons.chevron_left,
                          color: Colors.grey, size: isTablet ? 28 : 24),
                    ),
                    Flexible(
                      child: Text(
                        '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}',
                        style: TextStyle(
                          fontSize: isTablet ? 22 : 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
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
                      icon: Icon(Icons.chevron_right,
                          color: Colors.grey, size: isTablet ? 28 : 24),
                    ),
                  ],
                ),
              ),
              // Calendar grid
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    child: _buildCalendarGrid(isTablet),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth > 600;

        return Container(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Column(
            children: [
              // Week header
              Container(
                padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _focusedDate =
                              _focusedDate.subtract(const Duration(days: 7));
                        });
                      },
                      icon: Icon(Icons.chevron_left,
                          color: Colors.grey, size: isTablet ? 28 : 24),
                    ),
                    Flexible(
                      child: Text(
                        'Week of ${_getWeekRange()}',
                        style: TextStyle(
                          fontSize: isTablet ? 22 : 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _focusedDate =
                              _focusedDate.add(const Duration(days: 7));
                        });
                      },
                      icon: Icon(Icons.chevron_right,
                          color: Colors.grey, size: isTablet ? 28 : 24),
                    ),
                  ],
                ),
              ),
              // Week grid
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    child: _buildWeekGrid(isTablet),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarGrid([bool isTablet = false]) {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    // Day headers - starting with Sunday as shown in the image
    final dayHeaders = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return Column(
      children: [
        // Day headers
        Row(
          children: dayHeaders.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            final isSunday = index == 0; // Only Sunday

            return Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSunday ? Colors.red : Colors.black,
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Calendar days
        Expanded(
          child: Column(
            children: List.generate(6, (weekIndex) {
              return Expanded(
                child: Row(
                  children: List.generate(7, (dayIndex) {
                    // Calculate the actual day number for this position
                    final dayNumber =
                        weekIndex * 7 + dayIndex - firstDayOfWeek + 1;
                    final isCurrentMonth =
                        dayNumber > 0 && dayNumber <= daysInMonth;
                    final isToday = isCurrentMonth &&
                        dayNumber == DateTime.now().day &&
                        _focusedDate.month == DateTime.now().month &&
                        _focusedDate.year == DateTime.now().year;
                    final isSelected = isCurrentMonth &&
                        dayNumber == _selectedDate.day &&
                        _focusedDate.month == _selectedDate.month &&
                        _focusedDate.year == _selectedDate.year;
                    final isSunday = dayIndex == 0; // Only Sunday

                    return Expanded(
                      child: GestureDetector(
                        onTap: isCurrentMonth
                            ? () {
                                setState(() {
                                  _selectedDate = DateTime(_focusedDate.year,
                                      _focusedDate.month, dayNumber);
                                });
                              }
                            : null,
                        child: Container(
                          height: isTablet ? 60 : 50,
                          margin: EdgeInsets.all(isTablet ? 3 : 2),
                          decoration: BoxDecoration(
                            color: isSelected ? kMainColor : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(isTablet ? 12 : 8),
                          ),
                          child: Stack(
                            children: [
                              // Date number positioned at top
                              Positioned(
                                top: isTablet ? 8 : 6,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    isCurrentMonth ? dayNumber.toString() : '',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : isToday
                                              ? kMainColor
                                              : isSunday && isCurrentMonth
                                                  ? Colors.red
                                                  : Colors.black,
                                      fontWeight: isSelected || isToday
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: isTablet ? 18 : 16,
                                    ),
                                  ),
                                ),
                              ),
                              // Event indicator (small circle with number)
                              if (isCurrentMonth &&
                                  _getAppointmentCount(dayNumber) > 0)
                                Positioned(
                                  bottom: isTablet ? 6 : 4,
                                  right: isTablet ? 6 : 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      // Navigate to week view and select the date
                                      setState(() {
                                        _selectedDate = DateTime(
                                            _focusedDate.year,
                                            _focusedDate.month,
                                            dayNumber);
                                        _tabController.animateTo(
                                            1); // Switch to week view
                                      });
                                    },
                                    child: Container(
                                      width: isTablet ? 18 : 16,
                                      height: isTablet ? 18 : 16,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.3),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          _getAppointmentCount(dayNumber)
                                              .toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isTablet ? 9 : 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekGrid([bool isTablet = false]) {
    final startOfWeek =
        _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
    final weekDays =
        List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return Column(
      children: [
        // Day headers with dates
        Row(
          children: weekDays.map((day) {
            final isSunday = day.weekday == DateTime.sunday;
            final isSelected = day.day == _selectedDate.day &&
                day.month == _selectedDate.month &&
                day.year == _selectedDate.year;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = day;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kMainColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getDayName(day.weekday),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSunday ? Colors.red : Colors.black,
                          fontSize: isTablet ? 14 : 12,
                        ),
                      ),
                      SizedBox(height: isTablet ? 6 : 4),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? kMainColor
                              : isSunday
                                  ? Colors.red
                                  : Colors.black,
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Appointments for selected date
        Expanded(
          child: _buildAppointmentsForSelectedDate(),
        ),
      ],
    );
  }

  String _getDayName(int weekday) {
    const days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return days[weekday % 7];
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

  String _getWeekRange() {
    final startOfWeek =
        _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    if (startOfWeek.month == endOfWeek.month) {
      return '${_getMonthName(startOfWeek.month)} ${startOfWeek.day}-${endOfWeek.day}';
    } else {
      return '${_getMonthName(startOfWeek.month)} ${startOfWeek.day} - ${_getMonthName(endOfWeek.month)} ${endOfWeek.day}';
    }
  }

  int _getAppointmentCount(int dayNumber) {
    final dateKey = '${_focusedDate.year}-${_focusedDate.month}-$dayNumber';
    return _appointmentCounts[dateKey] ?? 0;
  }

  Widget _buildAppointmentsForSelectedDate() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth > 600;
        final isLargeScreen = screenWidth > 900;

        return FutureBuilder<List<AppointmentModel>>(
          future: AppointmentService.getAppointmentsForDate(_selectedDate),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final appointments = snapshot.data ?? [];

            if (appointments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No appointments for ${_getMonthName(_selectedDate.month)} ${_selectedDate.day}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 16 : 8, vertical: 16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return GestureDetector(
                  onTap: () => _showAppointmentDetails(appointment, isTablet),
                  child: Container(
                    margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Services and time row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Services list
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: appointment.services
                                        .asMap()
                                        .entries
                                        .map((entry) {
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
                                      final color =
                                          colors[index % colors.length];

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: color.withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          service.name,
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.w600,
                                            fontSize: isTablet ? 12 : 10,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  if (appointment.services.length > 1) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Total: ${appointment.totalPrice}',
                                      style: TextStyle(
                                        color: kMainColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isTablet ? 12 : 10,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              appointment.appointmentTime,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 18 : 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Customer name row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                appointment.customerName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isTablet ? 18 : 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Edit and Delete icons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      _editAppointment(appointment),
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                    size: isTablet ? 20 : 18,
                                  ),
                                  tooltip: 'Edit appointment',
                                  constraints: BoxConstraints(
                                    minWidth: isTablet ? 36 : 32,
                                    minHeight: isTablet ? 36 : 32,
                                  ),
                                  padding: EdgeInsets.all(isTablet ? 6 : 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                                SizedBox(width: isTablet ? 4 : 2),
                                IconButton(
                                  onPressed: () =>
                                      _deleteAppointment(appointment),
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: isTablet ? 20 : 18,
                                  ),
                                  tooltip: 'Delete appointment',
                                  constraints: BoxConstraints(
                                    minWidth: isTablet ? 36 : 32,
                                    minHeight: isTablet ? 36 : 32,
                                  ),
                                  padding: EdgeInsets.all(isTablet ? 6 : 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appointment.customerPhone,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isTablet ? 16 : 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '₹${appointment.totalPrice}',
                              style: TextStyle(
                                color: kMainColor,
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 18 : 16,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${appointment.totalDuration} min',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: isTablet ? 16 : 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAppointmentDetails(AppointmentModel appointment, bool isTablet) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 500 : 400,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kMainColor, kMainColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Appointment Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 22 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_getMonthName(appointment.appointmentDate.month)} ${appointment.appointmentDate.day}, ${appointment.appointmentDate.year}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: isTablet ? 14 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Information
                        _buildDetailSection(
                          icon: Icons.person,
                          title: 'Customer',
                          isTablet: isTablet,
                          children: [
                            _buildDetailRow(
                              'Name',
                              appointment.customerName,
                              isTablet,
                            ),
                            _buildDetailRow(
                              'Phone',
                              appointment.customerPhone,
                              isTablet,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Appointment Time
                        _buildDetailSection(
                          icon: Icons.access_time,
                          title: 'Time & Duration',
                          isTablet: isTablet,
                          children: [
                            _buildDetailRow(
                              'Time',
                              appointment.appointmentTime,
                              isTablet,
                            ),
                            _buildDetailRow(
                              'Duration',
                              '${appointment.totalDuration} minutes',
                              isTablet,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Services
                        _buildDetailSection(
                          icon: Icons.design_services,
                          title: 'Services (${appointment.services.length})',
                          isTablet: isTablet,
                          children:
                              appointment.services.asMap().entries.map((entry) {
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
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withOpacity(0.3),
                                  width: 1.5,
                                ),
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
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          service.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: isTablet ? 16 : 14,
                                            color: color,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${service.duration} min',
                                          style: TextStyle(
                                            fontSize: isTablet ? 13 : 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${service.price}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTablet ? 16 : 14,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Total Price
                        Container(
                          padding: EdgeInsets.all(isTablet ? 20 : 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                kMainColor.withOpacity(0.1),
                                kMainColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kMainColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '₹${appointment.totalPrice}',
                                style: TextStyle(
                                  fontSize: isTablet ? 24 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: kMainColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _editAppointment(appointment);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 16 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteAppointment(appointment);
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 16 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required bool isTablet,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kMainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: kMainColor,
                size: isTablet ? 22 : 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: isTablet ? 100 : 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 15 : 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editAppointment(AppointmentModel appointment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAppointmentScreen(appointment: appointment),
      ),
    );

    // If appointment was updated, refresh the list
    if (result == true) {
      _loadAppointments();
    }
  }

  void _deleteAppointment(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: Text(
            'Are you sure you want to delete the appointment for ${appointment.customerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await AppointmentService.deleteAppointment(appointment.id!);
              Navigator.pop(context);
              _loadAppointments(); // Refresh the list
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Appointment deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
