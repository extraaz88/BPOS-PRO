import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:mobile_pos/constant.dart';

import '../../GlobalComponents/glonal_popup.dart';

class DisposalForm extends StatefulWidget {
  final String? productName;
  final String? productSku;
  final int? productId;
  final int? currentStock;

  const DisposalForm({
    super.key,
    this.productName,
    this.productSku,
    this.productId,
    this.currentStock,
  });

  @override
  State<DisposalForm> createState() => _DisposalFormState();
}

class _DisposalFormState extends State<DisposalForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _dateController = TextEditingController();

  String? _selectedReason;
  String? _selectedResponsiblePerson;
  DateTime? _selectedDate;

  final List<String> _disposalReasons = [
    'Damaged',
    'Expired',
    'Defective',
    'Lost',
    'Stolen',
    'Other',
  ];

  final List<String> _responsiblePersons = [
    'Manager',
    'Staff',
    'Admin',
  ];

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
    _dateController.text = _formatDate(DateTime.now());
    _selectedDate = DateTime.now();
    _selectedReason = 'Damaged';
    _selectedResponsiblePerson = 'Manager';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  void _disposeItem() {
    if (_formKey.currentState!.validate()) {
      if (int.parse(_quantityController.text) > (widget.currentStock ?? 0)) {
        EasyLoading.showError('Quantity cannot exceed current stock');
        return;
      }

      EasyLoading.show(status: 'Disposing...');

      // TODO: Implement actual disposal logic
      // This would typically:
      // 1. Create disposal record in database
      // 2. Reduce product stock
      // 3. Update inventory
      // 4. Add disposal tracking to product model

      Future.delayed(const Duration(seconds: 2), () {
        EasyLoading.dismiss();
        EasyLoading.showSuccess('Item disposed successfully!');

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context, true);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalPopup(
      child: Scaffold(
        backgroundColor: kWhite,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: kWhite,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text(
            'Waste Management',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Item Name (Read-only)
                  _buildTextField(
                    controller:
                        TextEditingController(text: widget.productName ?? ''),
                    label: 'Item Name',
                    hint: 'Product name',
                    readOnly: true,
                  ),

                  // SKU (Read-only)
                  _buildTextField(
                    controller:
                        TextEditingController(text: widget.productSku ?? ''),
                    label: 'SKU',
                    hint: 'Product SKU',
                    readOnly: true,
                  ),

                  // Quantity
                  _buildTextField(
                    controller: _quantityController,
                    label: 'Quantity',
                    hint: 'Enter quantity to dispose',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter quantity';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter valid number';
                      }
                      if (int.parse(value) <= 0) {
                        return 'Quantity must be greater than 0';
                      }
                      if (int.parse(value) > (widget.currentStock ?? 0)) {
                        return 'Quantity cannot exceed current stock (${widget.currentStock ?? 0})';
                      }
                      return null;
                    },
                  ),

                  // Date
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        suffixIcon: Icon(Icons.calendar_month),
                      ),
                      readOnly: true,
                      onTap: _selectDate,
                    ),
                  ),

                  // Reason Dropdown
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: DropdownButtonFormField<String>(
                      value: _selectedReason,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      items: _disposalReasons.map((String reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(reason),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedReason = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a reason';
                        }
                        return null;
                      },
                    ),
                  ),

                  // Responsible Person Dropdown
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: DropdownButtonFormField<String>(
                      value: _selectedResponsiblePerson,
                      decoration: const InputDecoration(
                        labelText: 'Responsible Person',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: _responsiblePersons.map((String person) {
                        return DropdownMenuItem<String>(
                          value: person,
                          child: Text(person),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedResponsiblePerson = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select responsible person';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Dispose Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _disposeItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMainColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Dispose',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
