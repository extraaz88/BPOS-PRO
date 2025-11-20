import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constant.dart';
import '../Screens/payment_type/model/payment_type_model.dart';
import '../Screens/payment_type/provider/payment_type_provider.dart';

class SplitPaymentDialog extends ConsumerStatefulWidget {
  final double totalAmount;
  final Function(Map<int, double> paymentAmounts) onConfirm;

  const SplitPaymentDialog({
    Key? key,
    required this.totalAmount,
    required this.onConfirm,
  }) : super(key: key);

  @override
  ConsumerState<SplitPaymentDialog> createState() => _SplitPaymentDialogState();
}

class _SplitPaymentDialogState extends ConsumerState<SplitPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, bool> _isUpdating = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers(List<PaymentTypeModel> paymentTypes) {
    // Initialize controllers for all payment types - all start with 0
    for (var paymentType in paymentTypes) {
      if (paymentType.id != null) {
        _controllers[paymentType.id!] = TextEditingController();
        _isUpdating[paymentType.id!] = false;
        // All fields start with 0
        _controllers[paymentType.id!]!.text = '0.00';
      }
    }
  }

  // Handle field focus - fill with remaining amount when tapped
  void _onFieldTapped(int paymentTypeId) {
    if (_isUpdating[paymentTypeId] == true) return;

    // Calculate remaining amount excluding current field
    double totalEntered = 0;
    for (var entry in _controllers.entries) {
      if (entry.key != paymentTypeId) {
        totalEntered += double.tryParse(entry.value.text) ?? 0;
      }
    }
    double remaining = widget.totalAmount - totalEntered;

    // Fill current field with remaining amount
    if (remaining > 0) {
      _isUpdating[paymentTypeId] = true;
      _controllers[paymentTypeId]?.text = remaining.toStringAsFixed(2);
      _isUpdating[paymentTypeId] = false;
      setState(() {});
    }
  }

  double _getAmount(int paymentTypeId) {
    return double.tryParse(_controllers[paymentTypeId]?.text ?? '0') ?? 0;
  }

  double get totalEntered {
    double total = 0;
    for (var controller in _controllers.values) {
      total += double.tryParse(controller.text) ?? 0;
    }
    return total;
  }

  double get remaining => widget.totalAmount - totalEntered;

  void _onAmountChanged(
      String value, int paymentTypeId, List<PaymentTypeModel> paymentTypes) {
    if (_isUpdating[paymentTypeId] == true) return;

    // Just update state - no auto-fill on change
    // User can manually edit, and next field will fill when tapped
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final paymentTypesAsync = ref.watch(paymentTypeProvider);

    return paymentTypesAsync.when(
      data: (paymentTypes) {
        // Filter out "Split" payment type if it exists and ensure IDs are not null
        final filteredTypes = paymentTypes
            .where((type) =>
                type.name?.toLowerCase() != 'split' && type.id != null)
            .toList();

        // Initialize controllers on first build
        if (_controllers.isEmpty && filteredTypes.isNotEmpty) {
          _initializeControllers(filteredTypes);
          // Force rebuild after initialization
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
        }

        if (_controllers.isEmpty || filteredTypes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Split Payment',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Total Amount Display
                    //  Container(
                    //   padding: const EdgeInsets.all(16),
                    //    decoration: BoxDecoration(
                    //     color: kMainColor.withOpacity(0.1),
                    //     borderRadius: BorderRadius.circular(8),
                    //   ),
                    // child: Column(
                    //   children: [
                    //     Row(
                    //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //       children: [
                    //         const Text(
                    //           'Total Amount:',
                    //           style: TextStyle(
                    //             fontSize: 16,
                    //             fontWeight: FontWeight.w600,
                    //           ),
                    //         ),
                    //         Text(
                    //           '₹${widget.totalAmount.toStringAsFixed(2)}',
                    //           style: const TextStyle(
                    //             fontSize: 18,
                    //             fontWeight: FontWeight.bold,
                    //             color: kMainColor,
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //     const SizedBox(height: 8),
                    //     Text(
                    //       '💡 Tap on any field to fill remaining amount. You can edit values manually.',
                    //       style: TextStyle(
                    //         fontSize: 12,
                    //         color: Colors.grey.shade700,
                    //         fontStyle: FontStyle.italic,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    //  ),
                    // const SizedBox(height: 20),

                    // Dynamic Payment Type Fields
                    ...filteredTypes.map((paymentType) {
                      if (paymentType.id == null)
                        return const SizedBox.shrink();

                      final controller = _controllers[paymentType.id!];
                      if (controller == null) return const SizedBox.shrink();

                      // Get icon based on payment type name
                      IconData getIcon() {
                        final name = paymentType.name?.toLowerCase() ?? '';
                        if (name.contains('cash')) return Icons.money;
                        if (name.contains('card') ||
                            name.contains('debit') ||
                            name.contains('credit')) return Icons.credit_card;
                        if (name.contains('online') ||
                            name.contains('upi') ||
                            name.contains('paytm') ||
                            name.contains('phonepe')) return Icons.payment;
                        if (name.contains('bank') || name.contains('transfer'))
                          return Icons.account_balance;
                        if (name.contains('check') || name.contains('cheque'))
                          return Icons.receipt;
                        return Icons.payment;
                      }

                      // Get color based on payment type
                      Color getColor() {
                        final name = paymentType.name?.toLowerCase() ?? '';
                        if (name.contains('cash')) return Colors.green;
                        if (name.contains('card')) return Colors.blue;
                        if (name.contains('online') || name.contains('upi'))
                          return Colors.purple;
                        return kMainColor;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          decoration: InputDecoration(
                            labelText: '${paymentType.name} Amount',
                            prefixIcon: Icon(getIcon(), color: getColor()),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: getColor(), width: 2),
                            ),
                            hintText: 'Tap to fill remaining',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          onTap: () {
                            // Fill with remaining amount when tapped
                            _onFieldTapped(paymentType.id!);
                          },
                          onChanged: (value) {
                            _onAmountChanged(
                                value, paymentType.id!, filteredTypes);
                          },
                          validator: (value) {
                            // Allow empty fields (0.00) - no validation needed
                            if (value == null ||
                                value.isEmpty ||
                                value == '0.00' ||
                                value == '0') {
                              return null;
                            }

                            final amount = double.tryParse(value);
                            if (amount == null || amount < 0) {
                              return 'Please enter valid amount';
                            }

                            // Calculate total entered amount from all fields
                            double totalEntered = 0;
                            for (var entry in _controllers.entries) {
                              final fieldValue =
                                  double.tryParse(entry.value.text) ?? 0;
                              if (entry.key == paymentType.id) {
                                totalEntered +=
                                    amount; // Use the new value being validated
                              } else {
                                totalEntered += fieldValue;
                              }
                            }

                            // Check if total is exactly equal to required amount
                            final difference =
                                (totalEntered - widget.totalAmount).abs();
                            if (difference > 0.01) {
                              // Allow small rounding differences
                              if (totalEntered > widget.totalAmount) {
                                return 'Total exceeds by ₹${difference.toStringAsFixed(2)}';
                              } else {
                                return 'Total is ₹${(widget.totalAmount - totalEntered).toStringAsFixed(2)} short';
                              }
                            }

                            return null;
                          },
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 20),

                    // Summary Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          ...filteredTypes.map((paymentType) {
                            if (paymentType.id == null)
                              return const SizedBox.shrink();
                            final amount = _getAmount(paymentType.id!);
                            if (amount == 0) return const SizedBox.shrink();
                            return Column(
                              children: [
                                _buildSummaryRow(
                                    paymentType.name ?? 'Unknown', amount),
                                const Divider(height: 16),
                              ],
                            );
                          }).toList(),
                          _buildSummaryRow('Total Entered', totalEntered,
                              isBold: true),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Remaining',
                            remaining,
                            color: remaining > 0.01 ? Colors.red : Colors.green,
                            isBold: true,
                          ),
                          const SizedBox(height: 8),
                          // Status indicator
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  (remaining.abs() < 0.01 && totalEntered > 0)
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color:
                                    (remaining.abs() < 0.01 && totalEntered > 0)
                                        ? Colors.green
                                        : Colors.red,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  (remaining.abs() < 0.01 && totalEntered > 0)
                                      ? Icons.check_circle
                                      : Icons.error_outline,
                                  color: (remaining.abs() < 0.01 &&
                                          totalEntered > 0)
                                      ? Colors.green
                                      : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  (remaining.abs() < 0.01 && totalEntered > 0)
                                      ? 'Payment Complete ✓'
                                      : totalEntered == 0
                                          ? 'Enter payment amounts'
                                          : 'Payment Incomplete',
                                  style: TextStyle(
                                    color: (remaining.abs() < 0.01 &&
                                            totalEntered > 0)
                                        ? Colors.green.shade900
                                        : Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Validate form first
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }

                              // Calculate total entered amount
                              double totalEntered = 0;
                              for (var controller in _controllers.values) {
                                totalEntered +=
                                    double.tryParse(controller.text) ?? 0;
                              }

                              // Check if total is exactly equal to required amount
                              final difference =
                                  (totalEntered - widget.totalAmount).abs();
                              if (difference > 0.01) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      totalEntered < widget.totalAmount
                                          ? 'Total amount incomplete! ₹${(widget.totalAmount - totalEntered).toStringAsFixed(2)} remaining'
                                          : 'Total amount exceeds by ₹${difference.toStringAsFixed(2)}',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                                return;
                              }

                              // Check if at least one payment method has amount
                              bool hasAnyAmount = false;
                              for (var controller in _controllers.values) {
                                final amount =
                                    double.tryParse(controller.text) ?? 0;
                                if (amount > 0) {
                                  hasAnyAmount = true;
                                  break;
                                }
                              }

                              if (!hasAnyAmount) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Please enter amount in at least one payment method'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              // Build map of payment type IDs to amounts
                              final Map<int, double> paymentAmounts = {};
                              for (var entry in _controllers.entries) {
                                final amount =
                                    double.tryParse(entry.value.text) ?? 0;
                                if (amount > 0) {
                                  paymentAmounts[entry.key] = amount;
                                }
                              }

                              // Debug: Print split payment amounts
                              print(
                                  '🔵 Split Payment Dialog - Amounts being sent:');
                              paymentAmounts.forEach((key, value) {
                                print(
                                    '  Payment Type ID: $key, Amount: ₹$value');
                              });
                              print('  Total Amount: ₹${widget.totalAmount}');
                              print('  Total Entered: ₹$totalEntered');

                              widget.onConfirm(paymentAmounts);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kMainColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Confirm',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading payment types: $error'),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount,
      {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}
