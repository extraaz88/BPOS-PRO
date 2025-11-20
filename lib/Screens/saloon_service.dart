import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/model/saloon_service_model.dart';
import 'package:mobile_pos/services/saloon_service_service.dart';

class SaloonServiceScreen extends StatefulWidget {
  final SaloonServiceModel? service; // For editing existing service

  const SaloonServiceScreen({
    Key? key,
    this.service,
  }) : super(key: key);

  @override
  State<SaloonServiceScreen> createState() => _SaloonServiceScreenState();
}

class _SaloonServiceScreenState extends State<SaloonServiceScreen> {
  final TextEditingController serviceNameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // If editing, populate the fields
    if (widget.service != null) {
      serviceNameController.text = widget.service!.serviceName;
      priceController.text = widget.service!.price;
      durationController.text = widget.service!.duration.toString();
    }
  }

  @override
  void dispose() {
    serviceNameController.dispose();
    priceController.dispose();
    durationController.dispose();
    super.dispose();
  }

  bool validateAndSave() {
    final form = formKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  Future<void> saveService() async {
    if (validateAndSave()) {
      EasyLoading.show(status: 'Saving...');

      try {
        final service = SaloonServiceModel(
          id: widget.service?.id,
          serviceName: serviceNameController.text.trim(),
          price: priceController.text.trim(),
          duration: int.parse(durationController.text.trim()),
        );

        if (widget.service == null) {
          // Add new service
          await SaloonServiceService.addService(service);
          EasyLoading.showSuccess('Service added successfully');
        } else {
          // Update existing service
          await SaloonServiceService.updateService(service);
          EasyLoading.showSuccess('Service updated successfully');
        }

        // Return to previous screen
        Navigator.pop(context, true);
      } catch (e) {
        EasyLoading.showError('Failed to save service');
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
        title: Text(
          widget.service == null ? 'Add Service' : 'Edit Service',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Name Field
                TextFormField(
                  controller: serviceNameController,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Service Name',
                    hintText: 'Enter service name',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter service name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Price Field
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Price',
                    hintText: 'Enter price',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    contentPadding: const EdgeInsets.all(16),
                    prefixText: '₹ ',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter price';
                    }
                    final price = double.tryParse(value.trim());
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Duration Field
                TextFormField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Duration (minutes)',
                    hintText: 'Enter duration in minutes',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    contentPadding: const EdgeInsets.all(16),
                    suffixText: 'min',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter duration';
                    }
                    final duration = int.tryParse(value.trim());
                    if (duration == null || duration <= 0) {
                      return 'Please enter a valid duration';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: saveService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMainColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.service == null
                          ? 'Save Service'
                          : 'Update Service',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
