import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../GlobalComponents/glonal_popup.dart';
import '../../../Provider/add_to_cart.dart';
import '../../../Provider/profile_provider.dart';
import '../../../Repository/API/business_info_update_repo.dart';
import '../../../constant.dart';
import 'model/amount_rounding_dropdown_model.dart';

class SalesSettingsScreen extends ConsumerStatefulWidget {
  const SalesSettingsScreen({super.key});

  @override
  ConsumerState<SalesSettingsScreen> createState() =>
      _PrintingInvoiceScreenState();
}

class _PrintingInvoiceScreenState extends ConsumerState<SalesSettingsScreen> {
  bool _invoiceEditEnabled = false;
  bool _roundOffEnabled = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadToggleSettings();
    ref.read(businessInfoProvider).when(
          data: (data) {
            setState(() {
              selectedMethod = roundingMethods.firstWhere(
                (element) => element.value == data.saleRoundingOption,
              );
            });
          },
          error: (error, stackTrace) {},
          loading: () {},
        );
  }

  AmountRoundingDropdownModel? selectedMethod = roundingMethods[0];

  Future<void> _loadToggleSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _invoiceEditEnabled = prefs.getBool(kSalesInvoiceEditToggleKey) ?? false;
      _roundOffEnabled = prefs.getBool(kSalesRoundOffToggleKey) ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _lang = lang.S.of(context);
    return GlobalPopup(
      child: Scaffold(
        backgroundColor: kWhite,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.black),
          title: Text(
            _lang.salesSetting,
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0.0,
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: SafeArea(
              child: ElevatedButton(
                child: Text(lang.S.of(context).save),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(
                      kSalesInvoiceEditToggleKey, _invoiceEditEnabled);
                  await prefs.setBool(kSalesRoundOffToggleKey, _roundOffEnabled);
                  try {
                    ref.read(cartNotifier).updateRoundOffEnabled(_roundOffEnabled);
                  } catch (e) {
                    // Ignore - cart notifier might not be initialized in some contexts
                  }
              
                  ref.watch(businessInfoProvider).when(
                        data: (data) async {
                          final businessRepository = BusinessUpdateRepository();
                          final isProfileUpdated =
                              await businessRepository.updateSalesSettings(
                            id: data.id.toString(),
                            ref: ref,
                            context: context,
                            saleRoundingOption: selectedMethod?.value,
                          );
              
                          if (isProfileUpdated) {
                            ref.invalidate(businessInfoProvider);
                            ref.invalidate(businessSettingProvider);
                            Navigator.pop(context);
                          }
                        },
                        error: (error, stackTrace) {},
                        loading: () {},
                      );
                },
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 15,
            children: [
              SwitchListTile.adaptive(
                value: _invoiceEditEnabled,
                onChanged: (value) {
                  setState(() {
                    _invoiceEditEnabled = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Allow invoice edit from invoice screen',
                  style: const TextStyle(fontSize: 16),
                ),
                subtitle: const Text(
                  'Show edit option on invoice immediately after sale',
                ),
              ),
              SwitchListTile.adaptive(
                value: _roundOffEnabled,
                onChanged: (value) {
                  setState(() {
                    _roundOffEnabled = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Enable sale amount round off',
                  style: const TextStyle(fontSize: 16),
                ),
                subtitle: const Text(
                  'Round total amount when saving or printing invoices',
                ),
              ),
              Text(
                '${_lang.amountRoundingMethod}:',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              DropdownButtonFormField<AmountRoundingDropdownModel>(
                decoration: InputDecoration(
                  labelText: _lang.amountRoundingMethod,
                  border: OutlineInputBorder(),
                ),
                value: selectedMethod,
                items: roundingMethods.map((method) {
                  return DropdownMenuItem<AmountRoundingDropdownModel>(
                    value: method,
                    child: Text(method.option),
                  );
                }).toList(),
                onChanged: _roundOffEnabled
                    ? (value) {
                        setState(() {
                          selectedMethod = value;
                        });
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
