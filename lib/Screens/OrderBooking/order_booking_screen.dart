import 'package:flutter/material.dart';
import 'order_booking_controller.dart';

class OrderBookingScreen extends StatefulWidget {
  const OrderBookingScreen({Key? key}) : super(key: key);

  @override
  State<OrderBookingScreen> createState() => _OrderBookingScreenState();
}

class _OrderBookingScreenState extends State<OrderBookingScreen> {
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _orderDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default values
    _orderIdController.text = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
    _customerNameController.text = 'John Doe';
    _totalAmountController.text = '1000.00';
    _orderDateController.text = DateTime.now().toString().split(' ')[0];
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _customerNameController.dispose();
    _totalAmountController.dispose();
    _orderDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Booking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order ID Field
            TextField(
              controller: _orderIdController,
              decoration: const InputDecoration(
                labelText: 'Order ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt),
              ),
            ),
            const SizedBox(height: 16),
            
            // Customer Name Field
            TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            
            // Total Amount Field
            TextField(
              controller: _totalAmountController,
              decoration: const InputDecoration(
                labelText: 'Total Amount',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Order Date Field
            TextField(
              controller: _orderDateController,
              decoration: const InputDecoration(
                labelText: 'Order Date',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  _orderDateController.text = date.toString().split(' ')[0];
                }
              },
            ),
            const SizedBox(height: 32),
            
            // Simple Order Booking Button
            ElevatedButton(
              onPressed: () {
                OrderBookingController.handleOrderBooking();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Simple Order Booking',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            
            // Order Booking with Parameters Button
            ElevatedButton(
              onPressed: () {
                OrderBookingController.handleOrderBookingWithParams(
                  orderId: _orderIdController.text,
                  customerName: _customerNameController.text,
                  totalAmount: double.tryParse(_totalAmountController.text) ?? 0.0,
                  orderDate: _orderDateController.text,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Order Booking with Parameters',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            
            // Order Booking with Context Button
            ElevatedButton(
              onPressed: () {
                OrderBookingController.handleOrderBookingWithContext(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Order Booking with Context',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            
            // Async Order Booking Button
            ElevatedButton(
              onPressed: () async {
                await OrderBookingController.handleOrderBookingAsync();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Async Order Booking',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            
            // Order Booking with Error Handling Button
            ElevatedButton(
              onPressed: () {
                OrderBookingController.handleOrderBookingWithErrorHandling();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Order Booking with Error Handling',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
