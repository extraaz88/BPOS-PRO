import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Screens/payment_type/provider/payment_type_provider.dart';
import 'package:mobile_pos/widgets/qr_payment_dialog.dart';

import '../../generated/l10n.dart' as lang;

class CustomPaymentTypeDropdown extends ConsumerWidget {
  const CustomPaymentTypeDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.isFormField = false,
    required this.totalAmount,
  });

  final int? value;
  final ValueChanged<int?>? onChanged;
  final bool isFormField;
  final double totalAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentTypes = ref.watch(paymentTypeProvider);

    return paymentTypes.when(
      data: (data) {
        final _data = [...data.where((element) => element.status == 1)];

        // Filter out Split from regular payment types
        final regularTypes = _data
            .where((element) => element.name?.toLowerCase() != 'split')
            .toList();

        // Add Split Payment and QR Payment as special options
        final List<Map<String, dynamic>> allOptions = [
          ...regularTypes.map((item) => {
                'id': item.id,
                'name': item.name,
                'isQR': false,
                'isSplit': false,
              }),
          {
            'id': -2, // Special ID for Split payment
            'name': 'Split Payment',
            'isQR': false,
            'isSplit': true,
          },
          {
            'id': -1, // Special ID for QR payment
            'name': 'QR Payment',
            'isQR': true,
            'isSplit': false,
          }
        ];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (value == null) {
            // Try to find Cash payment type first, otherwise use first available
            final cashType = _data.firstWhere(
              (element) => element.name?.toLowerCase() == 'cash',
              orElse: () => _data.first,
            );
            onChanged?.call(cashType.id);
          }
        });

        if (isFormField) {
          return DropdownButtonFormField<int>(
            hint: const Text('Select a payment type'),
            decoration: InputDecoration(
              labelText: lang.S.of(context).paymentTypes,
            ),
            value: value,
            items: allOptions.map((item) {
              return DropdownMenuItem<int>(
                value: item['id'] as int,
                child: Row(
                  children: [
                    if (item['isSplit']) ...[
                      const Icon(Icons.account_balance_wallet,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                    ] else if (item['isQR']) ...[
                      const Icon(Icons.qr_code, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                    ],
                    Text(item['name']),
                  ],
                ),
              );
            }).toList(),
            onChanged: (selectedValue) {
              if (selectedValue == -2) {
                // Split Payment selected - let parent handle it
                onChanged?.call(selectedValue);
              } else if (selectedValue == -1) {
                // Show QR Payment dialog
                showDialog(
                  context: context,
                  builder: (context) => QRPaymentDialog(
                    amount: totalAmount,
                    upiId: '8857981579@fam',
                    onPaymentComplete: () {
                      // Only set payment type to Cash AFTER payment is actually received
                      final cashType = _data.firstWhere(
                        (element) => element.name?.toLowerCase() == 'cash',
                        orElse: () => _data.first,
                      );
                      onChanged?.call(cashType.id);

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Payment received! Invoice will be generated.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                );
              } else {
                onChanged?.call(selectedValue);
              }
            },
            validator: (value) {
              if (value == null || value < 0) {
                return 'Please select a payment type';
              }
              return null;
            },
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  lang.S.of(context).paymentMode,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.wallet,
                  color: Colors.green,
                )
              ],
            ),
            _data.isEmpty
                ? SizedBox(
                    width: 100,
                    height: 45,
                    child: DropdownButton<int?>(
                      value: value,
                      menuMaxHeight: 350,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: allOptions.map((item) {
                        return DropdownMenuItem<int?>(
                          value: item['id'],
                          child: Row(
                            children: [
                              if (item['isSplit']) ...[
                                const Icon(Icons.account_balance_wallet,
                                    size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                              ] else if (item['isQR']) ...[
                                const Icon(Icons.qr_code,
                                    size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                              ],
                              Text(item['name']),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (selectedValue) {
                        if (selectedValue == -2) {
                          // Split Payment selected - let parent handle it
                          onChanged?.call(selectedValue);
                        } else if (selectedValue == -1) {
                          // Show QR Payment dialog
                          showDialog(
                            context: context,
                            builder: (context) => QRPaymentDialog(
                              amount: totalAmount,
                              upiId: '8857981579@fam',
                              onPaymentComplete: () {
                                // Only set payment type to Cash AFTER payment is actually received
                                final cashType = _data.firstWhere(
                                  (element) =>
                                      element.name?.toLowerCase() == 'cash',
                                  orElse: () => _data.first,
                                );
                                onChanged?.call(cashType.id);

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Payment received! Invoice will be generated.'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          );
                        } else {
                          onChanged?.call(selectedValue);
                        }
                      },
                    ),
                  )
                : DropdownButton<int?>(
                    value: value,
                    menuMaxHeight: 350,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: allOptions.map((item) {
                      return DropdownMenuItem<int?>(
                        value: item['id'],
                        child: Row(
                          children: [
                            if (item['isSplit']) ...[
                              const Icon(Icons.account_balance_wallet,
                                  size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                            ] else if (item['isQR']) ...[
                              const Icon(Icons.qr_code,
                                  size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                            ],
                            Text(item['name']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (selectedValue) {
                      if (selectedValue == -2) {
                        // Split Payment selected - let parent handle it
                        onChanged?.call(selectedValue);
                      } else if (selectedValue == -1) {
                        // Show QR Payment dialog
                        showDialog(
                          context: context,
                          builder: (context) => QRPaymentDialog(
                            amount: totalAmount,
                            upiId: '8857981579@fam',
                            onPaymentComplete: () {
                              // Only set payment type to Cash AFTER payment is actually received
                              final cashType = _data.firstWhere(
                                (element) =>
                                    element.name?.toLowerCase() == 'cash',
                                orElse: () => _data.first,
                              );
                              onChanged?.call(cashType.id);

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Payment received! Invoice will be generated.'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        );
                      } else {
                        onChanged?.call(selectedValue);
                      }
                    },
                  ),
          ],
        );
      },
      error: (error, stackTrace) {
        return Center(child: Text(error.toString()));
      },
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
