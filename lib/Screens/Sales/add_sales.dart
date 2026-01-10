import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_pos/Provider/add_to_cart.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/Screens/Sales/Repo/sales_repo.dart';
import 'package:mobile_pos/Screens/Sales/sales_add_to_cart_sales_widget.dart';
import 'package:mobile_pos/Screens/Sales/sales_contact.dart';
import 'package:mobile_pos/Screens/Sales/sales_products_list_screen.dart';
import 'package:mobile_pos/Screens/Sales/sale_bill_summary_screen.dart';
import 'package:mobile_pos/Screens/Settings/sales%20settings/model/amount_rounding_dropdown_model.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Const/api_config.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../Repository/API/future_invoice.dart';
import '../../constant.dart';
import '../../currency.dart';
import '../../model/add_to_cart_model.dart';
import '../../model/sale_transaction_model.dart';
import '../../widgets/split_payment_dialog.dart';
import '../../widgets/custom_payment_type_dropdown.dart';
import '../Customers/Model/parties_model.dart';
import '../payment_type/provider/payment_type_provider.dart';
import '../Customers/Provider/customer_provider.dart'
    show partiesProvider, walkInCustomer;
import '../Home/home.dart';
import '../invoice_details/sales_invoice_details_screen.dart';
import '../../model/hold_order_model.dart';
import '../HoldOrders/hold_orders_provider.dart';
import 'package:mobile_pos/utils/payment_totals_helper.dart';
import '../../model/business_info_model.dart' as binfo;

class AddSalesScreen extends ConsumerStatefulWidget {
  AddSalesScreen({
    super.key,
    required this.customerModel,
    this.transitionModel,
    this.dueAmount,
  });

  final Party? customerModel;
  final SalesTransactionModel? transitionModel;
  final double? dueAmount;

  @override
  AddSalesScreenState createState() => AddSalesScreenState();
}

class AddSalesScreenState extends ConsumerState<AddSalesScreen> {
  int? paymentType;

  bool isProcessing = false;

  DateTime selectedDate = DateTime.now();

  TextEditingController dateController =
      TextEditingController(text: DateTime.now().toString().substring(0, 10));
  TextEditingController phoneController = TextEditingController();
  TextEditingController recevedAmountController = TextEditingController();

  TextEditingController noteController = TextEditingController();

  // Split payment variables
  bool isSplitPayment = false;
  Map<int, double> splitPaymentAmounts = {}; // paymentTypeId -> amount

  // Flag to ensure payment type is auto-selected only once
  bool _hasAutoSelectedPayment = false;

  // Payment Type (Full Payment / Installment)
  String selectedPaymentOption = 'Full Payment';

  // Installment fields
  TextEditingController downPaymentController = TextEditingController();
  TextEditingController installmentDurationController = TextEditingController();
  TextEditingController installmentInterestController = TextEditingController();

  // Installment calculation variables
  double remainingAmount = 0.0;
  double monthlyInstallment = 0.0;
  double totalPayableWithInterest = 0.0;

  // Variables for searchable dropdown
  Party? selectedCustomer;
  double _height = 100;

  // Showcase keys for Add Sale screen
  final GlobalKey _addItemKey = GlobalKey();
  final GlobalKey _saveButtonKey = GlobalKey();
  bool _showcaseStarted = false;

  @override
  void initState() {
    // Reset auto-selection flag for new transactions
    _hasAutoSelectedPayment = false;

    if (widget.transitionModel != null) {
      final editedSales = widget.transitionModel;
      dateController.text = editedSales?.saleDate?.substring(0, 10) ?? '';
      recevedAmountController.text = editedSales?.paidAmount.toString() ?? '';
      // Don't set selectedCustomer here - let it be set from the dropdown items
      if (widget.transitionModel?.discountType == 'flat') {
        discountType = 'Flat';
      } else {
        discountType = 'Percent';
      }
      paymentType = widget.transitionModel?.paymentTypeId;
      addProductsInCartFromEditList();
    }

    // Set initial customer if provided, otherwise use walk-in customer

    // Start showcase after screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check if showcase was already shown
      final prefs = await SharedPreferences.getInstance();
      final showcaseShown = prefs.getBool('add_sales_showcase_shown') ?? false;

      if (showcaseShown) {
        print('📌 Add Sales showcase already shown, skipping...');
        return;
      }

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted && !_showcaseStarted) {
        try {
          ShowCaseWidget.of(context).startShowCase([
            _addItemKey,
            _saveButtonKey,
          ]);
          print('✅ Add Sale screen showcase started');

          // Mark showcase as shown
          await prefs.setBool('add_sales_showcase_shown', true);
        } catch (e) {
          print('❌ Add Sale showcase error: $e');
        }
        _showcaseStarted = true;
      }
    });
    if (widget.customerModel != null) {
      selectedCustomer = widget.customerModel;
      phoneController.text = widget.customerModel?.phone ?? '';
    } else {
      // Set walk-in customer as default
      selectedCustomer = walkInCustomer;
      phoneController.text = walkInCustomer.phone ?? '';
    }

    // Set due amount if provided from due completion
    if (widget.dueAmount != null && widget.dueAmount! > 0) {
      // This will be handled in the provider initialization
      print('Due amount passed: ${widget.dueAmount}');
      // Set the due amount in the provider after the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(cartNotifier.notifier).setDueAmount(widget.dueAmount!);
      });
    }

    super.initState();

    // Check if restoring from hold order
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRestoreHoldOrder();
    });
  }

  // Method to check and restore hold order if available
  void _checkAndRestoreHoldOrder() {
    final holdOrder = ref.read(holdOrderRestoreProvider);
    if (holdOrder != null && holdOrder.orderType == 'sale') {
      _restoreFromHoldOrder(holdOrder);
      // Clear the hold order from provider
      ref.read(holdOrderRestoreProvider.notifier).clearHoldOrder();
    }
  }

  // Method to restore data from hold order
  void _restoreFromHoldOrder(HoldOrderModel holdOrder) {
    final cart = ref.read(cartNotifier);

    // Restore date
    if (holdOrder.date != null) {
      dateController.text = holdOrder.date!;
    }

    // Restore paid amount
    if (holdOrder.paidAmount != null) {
      recevedAmountController.text = holdOrder.paidAmount.toString();
    }

    // Restore note
    if (holdOrder.note != null) {
      noteController.text = holdOrder.note!;
    }

    // Restore discount type
    if (holdOrder.discountType != null) {
      setState(() {
        discountType = holdOrder.discountType == 'flat' ? 'Flat' : 'Percent';
      });
    }

    // Restore payment type
    if (holdOrder.paymentTypeId != null) {
      setState(() {
        paymentType = holdOrder.paymentTypeId;
      });
    }

    // Restore split payment data
    if (holdOrder.isSplitPayment == true) {
      setState(() {
        isSplitPayment = true;
        // Restore split payment amounts (if needed, convert from old format)
        if (holdOrder.splitCashAmount != null &&
            holdOrder.splitCashAmount! > 0) {
          // Try to find cash payment type ID
          final paymentTypes = ref.read(paymentTypeProvider);
          paymentTypes.whenData((types) {
            final cashType = types.firstWhere(
              (type) => type.name?.toLowerCase() == 'cash',
              orElse: () => types.first,
            );
            if (cashType.id != null) {
              splitPaymentAmounts[cashType.id!] = holdOrder.splitCashAmount!;
            }
          });
        }
        if (holdOrder.splitOnlineAmount != null &&
            holdOrder.splitOnlineAmount! > 0) {
          // Try to find online payment type ID
          final paymentTypes = ref.read(paymentTypeProvider);
          paymentTypes.whenData((types) {
            final onlineType = types.firstWhere(
              (type) => type.name?.toLowerCase().contains('online') ?? false,
              orElse: () => types.firstWhere(
                (type) => type.name?.toLowerCase().contains('card') ?? false,
                orElse: () => types.isNotEmpty ? types[1] : types.first,
              ),
            );
            if (onlineType.id != null) {
              splitPaymentAmounts[onlineType.id!] =
                  holdOrder.splitOnlineAmount!;
            }
          });
        }
      });
    }

    // Restore products to cart
    if (holdOrder.items != null && holdOrder.items!.isNotEmpty) {
      cart.cartItemList.clear();
      for (var item in holdOrder.items!) {
        cart.addToCartRiverPod(
          cartItem: AddToCartModel(
            productName: item.productName,
            unitPrice: item.unitPrice?.toString() ?? '0',
            productCode: item.productCode,
            productPurchasePrice: item.purchasePrice,
            stock: item.stock ?? 0,
            productId: item.productId ?? 0,
            quantity: item.quantity ?? 0,
            stockId: item.stockId,
            gstRateSelect: item.gstRateSelect,
            gstType: item.gstType,
            vatType: item.vatType,
          ),
          fromEditSales: true,
        );
      }
    }

    // Restore discount
    if (holdOrder.discountAmount != null) {
      cart.discountAmount = holdOrder.discountAmount!;
      if (holdOrder.discountType == 'flat') {
        cart.discountTextControllerFlat.text =
            holdOrder.discountAmount.toString();
      } else if (holdOrder.discountPercent != null) {
        cart.discountTextControllerFlat.text =
            holdOrder.discountPercent.toString();
      }
    }

    // Restore charges
    if (holdOrder.shippingCharge != null) {
      cart.finalShippingCharge = holdOrder.shippingCharge!;
      cart.shippingChargeController.text = holdOrder.shippingCharge.toString();
    }

    if (holdOrder.serviceCharge != null) {
      cart.finalServiceCharge = holdOrder.serviceCharge!;
      cart.serviceChargeController.text = holdOrder.serviceCharge.toString();
    }

    if (holdOrder.vatAmount != null) {
      cart.vatAmountController.text = holdOrder.vatAmount.toString();
    }

    // Recalculate prices
    cart.calculatePrice(
      receivedAmount: holdOrder.paidAmount?.toString(),
      stopRebuild: true,
    );

    EasyLoading.showSuccess('Hold order restored!');
  }

  // Helper method to recreate controllers if disposed
  void _recreateControllersIfDisposed() {
    try {
      // Try to access phoneController
      phoneController.text;
    } catch (e) {
      print('phoneController disposed, recreating...');
      phoneController = TextEditingController();
    }

    try {
      // Try to access noteController
      noteController.text;
    } catch (e) {
      print('noteController disposed, recreating...');
      noteController = TextEditingController();
    }

    try {
      // Try to access recevedAmountController
      recevedAmountController.text;
    } catch (e) {
      print('recevedAmountController disposed, recreating...');
      recevedAmountController = TextEditingController();
    }

    try {
      // Try to access downPaymentController
      downPaymentController.text;
    } catch (e) {
      print('downPaymentController disposed, recreating...');
      downPaymentController = TextEditingController();
    }

    try {
      // Try to access installmentDurationController
      installmentDurationController.text;
    } catch (e) {
      print('installmentDurationController disposed, recreating...');
      installmentDurationController = TextEditingController();
    }

    try {
      // Try to access installmentInterestController
      installmentInterestController.text;
    } catch (e) {
      print('installmentInterestController disposed, recreating...');
      installmentInterestController = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Safe dispose to avoid double disposal
    try {
      dateController.dispose();
    } catch (e) {
      print('dateController already disposed: $e');
    }
    try {
      phoneController.dispose();
    } catch (e) {
      print('phoneController already disposed: $e');
    }
    try {
      recevedAmountController.dispose();
    } catch (e) {
      print('recevedAmountController already disposed: $e');
    }
    try {
      noteController.dispose();
    } catch (e) {
      print('noteController already disposed: $e');
    }
    try {
      downPaymentController.dispose();
    } catch (e) {
      print('downPaymentController already disposed: $e');
    }
    try {
      installmentDurationController.dispose();
    } catch (e) {
      print('installmentDurationController already disposed: $e');
    }
    try {
      installmentInterestController.dispose();
    } catch (e) {
      print('installmentInterestController already disposed: $e');
    }
    super.dispose();
  }

  // Calculate installment details
  void calculateInstallment(double totalAmount) {
    setState(() {
      double downPayment = double.tryParse(downPaymentController.text) ?? 0;
      int duration = int.tryParse(installmentDurationController.text) ?? 0;
      double interestRate =
          double.tryParse(installmentInterestController.text) ?? 0;

      // Calculate remaining amount after down payment
      remainingAmount = totalAmount - downPayment;

      if (duration > 0 && remainingAmount > 0) {
        // Calculate interest amount
        double interestAmount =
            (remainingAmount * interestRate * duration) / 100;

        // Total amount to be paid in installments (principal + interest)
        totalPayableWithInterest = remainingAmount + interestAmount;

        // Calculate monthly installment
        monthlyInstallment = totalPayableWithInterest / duration;
      } else {
        totalPayableWithInterest = remainingAmount;
        monthlyInstallment = 0;
      }
    });
  }

  void addProductsInCartFromEditList() {
    final cart = ref.read(cartNotifier);
    cart.roundedOption =
        widget.transitionModel?.roundingOption ?? roundingMethods[0].value;

    if (widget.transitionModel?.salesDetails?.isNotEmpty ?? false) {
      for (var detail in widget.transitionModel!.salesDetails!) {
        AddToCartModel cartItem = AddToCartModel(
          productName: detail.product?.productName,
          unitPrice: detail.price.toString(),
          quantity: detail.quantities ?? 0,
          productCode: detail.product?.productCode,
          productPurchasePrice: detail.product?.productPurchasePrice,
          stock: detail.product?.productStock,
          productId: detail.productId!,
          stockId:
              null, // SalesProduct doesn't have stock info, will use product ID as fallback
          unitName: null, // SalesProduct doesn't have unit information
        );
        cart.addToCartRiverPod(cartItem: cartItem, fromEditSales: true);
      }
    }

    cart.discountAmount = widget.transitionModel?.discountAmount ?? 0;
    noteController.text = widget.transitionModel?.meta?.note?.toString() ?? '';
    if (widget.transitionModel?.discountType == 'flat') {
      cart.discountTextControllerFlat.text =
          widget.transitionModel?.discountAmount.toString() ?? '';
    } else {
      cart.discountTextControllerFlat.text =
          widget.transitionModel?.discountPercent?.toString() ?? '';
    }

    cart.finalShippingCharge = widget.transitionModel?.shippingCharge ?? 0;
    cart.shippingChargeController.text =
        widget.transitionModel?.shippingCharge.toString() ?? '';
    cart.vatAmountController.text =
        widget.transitionModel?.vatAmount.toString() ?? '';

    cart.calculatePrice(
        receivedAmount: widget.transitionModel?.paidAmount.toString(),
        stopRebuild: true);
  }

  bool hasPreselected = false; // Flag to ensure preselection happens only once

  String discountType = 'Flat';

  File? _imageFile;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    final providerData = ref.watch(cartNotifier);
    final personalData = ref.watch(businessInfoProvider);
    return personalData.when(data: (data) {
      return GlobalPopup(
        child: Scaffold(
          backgroundColor: kWhite,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              //lang.S.of(context).addSales,
              'Add Sales',
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.black),
            elevation: 2.0,
            surfaceTintColor: kWhite,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  ///_______Invoice_And_Date_____________________________________________________
                  Row(
                    children: [
                      widget.transitionModel == null
                          ? FutureBuilder(
                              future: FutureInvoice()
                                  .getFutureInvoice(tag: 'sales'),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Expanded(
                                    child: AppTextField(
                                      textFieldType: TextFieldType.NAME,
                                      initialValue: snapshot.data.toString(),
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.always,
                                        labelText: lang.S.of(context).inv,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  );
                                } else {
                                  return Expanded(
                                    child: TextFormField(
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.always,
                                        labelText: lang.S.of(context).inv,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  );
                                }
                              },
                            )
                          : Expanded(
                              child: AppTextField(
                                textFieldType: TextFieldType.NAME,
                                initialValue:
                                    widget.transitionModel?.invoiceNumber,
                                readOnly: true,
                                decoration: InputDecoration(
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  labelText: lang.S.of(context).inv,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          controller: dateController,
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            labelText: lang.S.of(context).date,
                            suffixIcon: IconButton(
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2015, 8),
                                  lastDate: DateTime(2101),
                                  context: context,
                                );
                                if (picked != null && picked != selectedDate) {
                                  setState(() {
                                    selectedDate = picked;
                                    dateController.text = selectedDate
                                        .toString()
                                        .substring(0, 10);
                                  });
                                }
                              },
                              icon: const Icon(FeatherIcons.calendar),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  ///______Selected_Due_And_Customer___________________________________________
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(lang.S.of(context).dueAmount),
                          Text(
                            selectedCustomer?.due == null
                                ? '$currency 0'
                                : '$currency${selectedCustomer?.due}',
                            style: const TextStyle(color: Color(0xFFFF8C34)),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final partiesAsync = ref.watch(partiesProvider);
                          return partiesAsync.when(
                            data: (parties) {
                              // Filter only customers (Customer)
                              final customers = parties
                                  .where((party) => party.type == 'Customer')
                                  .toList();

                              // Find matching customer from the list when editing
                              Party? dropdownValue = selectedCustomer;
                              if (widget.transitionModel != null &&
                                  customers.isNotEmpty) {
                                try {
                                  final foundCustomer = customers.firstWhere(
                                    (customer) =>
                                        customer.id ==
                                        widget.transitionModel?.party?.id,
                                  );
                                  dropdownValue = foundCustomer;
                                  // Update selectedCustomer if we found a match
                                  if (selectedCustomer == null) {
                                    selectedCustomer = foundCustomer;
                                    phoneController.text =
                                        foundCustomer.phone ?? '';
                                  }
                                } catch (e) {
                                  // Customer not found in the list, keep selectedCustomer as null
                                  dropdownValue = null;
                                }
                              }

                              return DropdownButtonFormField<Party>(
                                value: dropdownValue,
                                decoration: InputDecoration(
                                  labelText: lang.S.of(context).customerName,
                                  border: const OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                hint: Text('Select Customer'),
                                items: customers.map<DropdownMenuItem<Party>>(
                                    (Party party) {
                                  return DropdownMenuItem<Party>(
                                    value: party,
                                    child: Text(party.name ?? 'Unknown'),
                                  );
                                }).toList(),
                                onChanged: (Party? newValue) {
                                  setState(() {
                                    selectedCustomer = newValue;
                                    // Auto-fill phone number
                                    if (newValue?.phone != null) {
                                      phoneController.text = newValue!.phone!;
                                    } else {
                                      phoneController.clear();
                                    }
                                  });
                                },
                                isExpanded: true,
                              );
                            },
                            loading: () => const CircularProgressIndicator(),
                            error: (error, stack) => Text('Error: $error'),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: AppTextField(
                          controller: phoneController,
                          textFieldType: TextFieldType.PHONE,
                          decoration: kInputDecoration.copyWith(
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            //labelText: 'Customer Phone Number',
                            labelText: lang.S.of(context).customerPhoneNumber,
                            //hintText: 'Enter customer phone number',
                            hintText:
                                lang.S.of(context).enterCustomerPhoneNumber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  ///_______Added_Items_List_________________________________________________
                  Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10)),
                          border: Border.all(
                              width: 1, color: const Color(0xffEAEFFA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  color: Color(0xffEAEFFA),
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: SizedBox(
                                    width: context.width() / 1.35,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          lang.S.of(context).itemAdded,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          lang.S.of(context).quantity,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          'Unit',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                            ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: providerData.cartItemList.length,
                                itemBuilder: (context, index) {
                                  // providerData.controllers[index].text = (providerData.cartItemList[index].quantity.toString());
                                  // providerData.focus[index].addListener(
                                  //   () {
                                  //     if (!providerData.focus[index].hasFocus) {
                                  //       setState(() {
                                  //         vatAmount = (vatPercentageEditingController.text.toDouble() / 100) * providerData.getTotalAmount().toDouble();
                                  //         vatAmountEditingController.text = vatAmount.toStringAsFixed(2);
                                  //       });
                                  //     }
                                  //   },
                                  // );
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        left: 10, right: 10),
                                    child: ListTile(
                                      onTap: () => showModalBottomSheet(
                                        context: context,
                                        isScrollControlled:
                                            true, // 👈 Makes modal full height & scrollable
                                        backgroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(16)),
                                        ),
                                        builder: (context2) {
                                          return DraggableScrollableSheet(
                                            expand: false,
                                            initialChildSize:
                                                0.8, // 👈 initial height (80% of screen)
                                            minChildSize:
                                                0.5, // 👈 minimum height
                                            maxChildSize:
                                                0.95, // 👈 maximum drag height
                                            builder:
                                                (context3, scrollController) {
                                              return SafeArea(
                                                child: SingleChildScrollView(
                                                  controller: scrollController,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // ===== Header Section =====
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    10.0),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              lang.S
                                                                  .of(context)
                                                                  .updateProduct,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            CloseButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context2),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                      const Divider(
                                                          thickness: 1,
                                                          color:
                                                              kBorderColorTextField),

                                                      // ===== Form Section =====
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child:
                                                            SalesAddToCartForm(
                                                          batchWiseStockModel:
                                                              providerData
                                                                      .cartItemList[
                                                                  index],
                                                          previousContext:
                                                              context2,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 20),

                                                      // ===== Optional Bottom Action Buttons =====
                                                      Align(
                                                        alignment:
                                                            Alignment.center,
                                                        child:
                                                            ElevatedButton.icon(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                kMainColor,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        24,
                                                                    vertical:
                                                                        12),
                                                          ),
                                                          icon: const Icon(
                                                              Icons.save,
                                                              color:
                                                                  Colors.white),
                                                          label: const Text(
                                                            "Save Changes",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context2);
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 30),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      contentPadding: const EdgeInsets.all(0),
                                      title: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(providerData
                                                .cartItemList[index].productName
                                                .toString()),
                                          ),
                                          Text(
                                            formatPointNumber(
                                              providerData.cartItemList[index]
                                                      .displayQuantity ??
                                                  providerData
                                                      .cartItemList[index]
                                                      .quantity,
                                            ),
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            providerData.cartItemList[index]
                                                    .displayUnit ??
                                                providerData.cartItemList[index]
                                                    .unitName ??
                                                '',
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '${formatPointNumber(providerData.cartItemList[index].displayQuantity ?? providerData.cartItemList[index].quantity)} X ${providerData.cartItemList[index].displayPrice ?? providerData.cartItemList[index].unitPrice} = ${formatPointNumber((double.parse(providerData.cartItemList[index].unitPrice.toString()) * providerData.cartItemList[index].quantity))}'),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 2,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: kMainColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                                child: Text(
                                                  providerData.selectedTaxType,
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: kMainColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              if (providerData
                                                          .cartItemList[index]
                                                          .gstRateSelect !=
                                                      null &&
                                                  providerData
                                                          .cartItemList[index]
                                                          .gstRateSelect !=
                                                      'N/A') ...[
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 4,
                                                      vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3),
                                                  ),
                                                  child: Text(
                                                    'GST ${providerData.cartItemList[index].gstRateSelect}%',
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.blue,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 4,
                                                      vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3),
                                                  ),
                                                  child: Text(
                                                    'SGST ${(double.parse(providerData.cartItemList[index].gstRateSelect!) / 2).toStringAsFixed(1)}%',
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.orange,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 4,
                                                      vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: Colors.purple
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3),
                                                  ),
                                                  child: Text(
                                                    'CGST ${(double.parse(providerData.cartItemList[index].gstRateSelect!) / 2).toStringAsFixed(1)}%',
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.purple,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 4,
                                                      vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3),
                                                  ),
                                                  child: Text(
                                                    'Total: ₹${providerData.cartItemList[index].calculateGstAmount(providerData.selectedTaxType).toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 90,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                GestureDetector(
                                                  onTap: () => providerData
                                                      .quantityDecrease(index),
                                                  child: Container(
                                                    height: 20,
                                                    width: 20,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: kMainColor,
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  10)),
                                                    ),
                                                    child: const Center(
                                                      child: Text(
                                                        '-',
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                SizedBox(
                                                  width: 40,
                                                  child: Center(
                                                    child: Text(
                                                      formatPointNumber(
                                                          providerData
                                                              .cartItemList[
                                                                  index]
                                                              .quantity),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.copyWith(
                                                            color:
                                                                kGreyTextColor,
                                                          ),
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                GestureDetector(
                                                  onTap: () => providerData
                                                      .quantityIncrease(index),
                                                  child: Container(
                                                    height: 20,
                                                    width: 20,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: kMainColor,
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  10)),
                                                    ),
                                                    child: const Center(
                                                        child: Text(
                                                      '+',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.white),
                                                    )),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          GestureDetector(
                                            onTap: () => providerData
                                                .deleteToCart(index),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              color:
                                                  Colors.red.withOpacity(0.1),
                                              child: const Icon(
                                                Icons.delete,
                                                size: 20,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                          ],
                        ),
                      )).visible(providerData.cartItemList.isNotEmpty),

                  ///_______Add_Button__________________________________________________
                  Showcase(
                    key: _addItemKey,
                    description: 'यहाँ से products add करें',
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SaleProductsList(
                              customerModel: widget.customerModel,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: kMainColor.withOpacity(0.1),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10))),
                        child: Center(
                          child: Text(
                            lang.S.of(context).addItems,
                            style: const TextStyle(
                                color: kMainColor, fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ///_____Total_Section_____________________________
                  Container(
                    decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1)),
                    child: Column(
                      children: [
                        ///________Total_title_reader_________________________
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                              color: Color(0xffFEF0F1),
                              borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(10),
                                  topLeft: Radius.circular(10))),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    lang.S.of(context).subTotal,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    formatPointNumber(providerData.totalAmount),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        ///_________Discount___________________________________
                        Padding(
                          padding: const EdgeInsets.only(
                              right: 10, left: 10, top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Text for "Discount"
                              Text(
                                lang.S.of(context).discount,
                                style: const TextStyle(fontSize: 16),
                              ),

                              const SizedBox(width: 10),

                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final screenWidth =
                                      MediaQuery.of(context).size.width;
                                  final dropdownWidth = screenWidth < 360
                                      ? 70.0
                                      : screenWidth < 400
                                          ? 80.0
                                          : 90.0;
                                  final inputWidth = screenWidth < 360
                                      ? 60.0
                                      : screenWidth < 400
                                          ? 70.0
                                          : 80.0;

                                  return Row(
                                    children: [
                                      Container(
                                        width: dropdownWidth,
                                        height: 30,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                              bottom: BorderSide(
                                                  color: kBorder, width: 1)),
                                        ),
                                        child: DropdownButton<String?>(
                                          icon: const Icon(
                                              Icons.keyboard_arrow_down,
                                              color: kGreyTextColor,
                                              size: 18),
                                          dropdownColor: Colors.white,
                                          isExpanded: true,
                                          isDense: true,
                                          padding: EdgeInsets.zero,
                                          hint: Text(
                                            'Select',
                                            style: _theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: kGreyTextColor,
                                            ),
                                          ),
                                          value: discountType,
                                          items: [
                                            "Flat",
                                            "Percent",
                                          ]
                                              .map((type) =>
                                                  DropdownMenuItem<String?>(
                                                    value: type,
                                                    child: Text(
                                                      type,
                                                      style: _theme
                                                          .textTheme.bodySmall
                                                          ?.copyWith(
                                                              color:
                                                                  kNeutralColor),
                                                    ),
                                                  ))
                                              .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              discountType = value!;
                                              providerData.calculateDiscount(
                                                value: providerData
                                                    .discountTextControllerFlat
                                                    .text,
                                                selectedTaxType: discountType,
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: inputWidth,
                                        height: 30,
                                        child: TextFormField(
                                          controller: providerData
                                              .discountTextControllerFlat,
                                          onChanged: (value) {
                                            setState(() {
                                              providerData.calculateDiscount(
                                                value: value,
                                                selectedTaxType: discountType,
                                              );
                                            });
                                          },
                                          textAlign: TextAlign.right,
                                          decoration: const InputDecoration(
                                            hintText: '0',
                                            hintStyle:
                                                TextStyle(color: kNeutralColor),
                                            border: UnderlineInputBorder(
                                                borderSide:
                                                    BorderSide(color: kBorder)),
                                            enabledBorder: UnderlineInputBorder(
                                                borderSide:
                                                    BorderSide(color: kBorder)),
                                            focusedBorder:
                                                UnderlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 0, vertical: 8),
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        ///_________GST_Details_______________________________
                        if (providerData.cartItemList.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'GST',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  formatPointNumber(
                                      providerData.totalGstAmount),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SGST',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  formatPointNumber(
                                      providerData.totalSgstAmount),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'CGST',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  formatPointNumber(
                                      providerData.totalCgstAmount),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.only(
                              right: 10, left: 10, top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: Text(
                                  'Shipping Charge',
                                  style: TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final screenWidth =
                                      MediaQuery.of(context).size.width;
                                  final inputWidth = screenWidth < 360
                                      ? 80.0
                                      : screenWidth < 400
                                          ? 90.0
                                          : 100.0;

                                  return SizedBox(
                                    width: inputWidth,
                                    height: 30,
                                    child: TextFormField(
                                      controller:
                                          providerData.shippingChargeController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) =>
                                          providerData.calculatePrice(
                                              shippingCharge: value,
                                              stopRebuild: false),
                                      textAlign: TextAlign.right,
                                      decoration: const InputDecoration(
                                        hintText: '0',
                                        hintStyle:
                                            TextStyle(color: kNeutralColor),
                                        border: UnderlineInputBorder(
                                            borderSide:
                                                BorderSide(color: kBorder)),
                                        enabledBorder: UnderlineInputBorder(
                                            borderSide:
                                                BorderSide(color: kBorder)),
                                        focusedBorder: UnderlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 0, vertical: 8),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              right: 10, left: 10, top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: Text(
                                  'Service Charge',
                                  style: TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final screenWidth =
                                      MediaQuery.of(context).size.width;
                                  final inputWidth = screenWidth < 360
                                      ? 80.0
                                      : screenWidth < 400
                                          ? 90.0
                                          : 100.0;

                                  return SizedBox(
                                    width: inputWidth,
                                    height: 30,
                                    child: TextFormField(
                                      controller:
                                          providerData.serviceChargeController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) =>
                                          providerData.calculatePrice(
                                              serviceCharge: value,
                                              stopRebuild: false),
                                      textAlign: TextAlign.right,
                                      decoration: const InputDecoration(
                                        hintText: '0',
                                        hintStyle:
                                            TextStyle(color: kNeutralColor),
                                        border: UnderlineInputBorder(
                                            borderSide:
                                                BorderSide(color: kBorder)),
                                        enabledBorder: UnderlineInputBorder(
                                            borderSide:
                                                BorderSide(color: kBorder)),
                                        focusedBorder: UnderlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 0, vertical: 8),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        ///________Total_______________________________________
                        Padding(
                          padding: const EdgeInsets.only(
                              right: 10, left: 10, top: 7),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.S.of(context).total,
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                formatPointNumber(
                                    providerData.actualTotalAmount),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),

                        ///________Rounded Total_______________________________________
                        Visibility(
                          visible: providerData.roundingAmount != 0,
                          child: Column(
                            children: [
                              ///________Rounded Amount_______________________________________
                              Padding(
                                padding: const EdgeInsets.only(
                                    right: 10, left: 10, top: 7),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rounding (+/-)',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      formatPointNumber(
                                          providerData.roundingAmount),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    right: 10, left: 10, top: 7),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rounded Total',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      formatPointNumber(
                                          providerData.totalPayableAmount),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        ///________paid_Amount__________________________________
                        Padding(
                          padding: const EdgeInsets.only(
                              right: 10, left: 10, top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  lang.S.of(context).receivedAmount,
                                  style: const TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final screenWidth =
                                      MediaQuery.of(context).size.width;
                                  final inputWidth = screenWidth < 360
                                      ? 80.0
                                      : screenWidth < 400
                                          ? 90.0
                                          : 100.0;

                                  return SizedBox(
                                    width: inputWidth,
                                    height: 30,
                                    child: TextFormField(
                                      controller: recevedAmountController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) =>
                                          providerData.calculatePrice(
                                              receivedAmount: value),
                                      textAlign: TextAlign.right,
                                      decoration: const InputDecoration(
                                        hintText: '0',
                                        hintStyle:
                                            TextStyle(color: kNeutralColor),
                                        border: UnderlineInputBorder(
                                            borderSide:
                                                BorderSide(color: kBorder)),
                                        enabledBorder: UnderlineInputBorder(
                                            borderSide:
                                                BorderSide(color: kBorder)),
                                        focusedBorder: UnderlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 0, vertical: 8),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        ///________Change amount_________________________________
                        Visibility(
                          visible: providerData.changeAmount > 0,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                right: 10, left: 10, top: 13, bottom: 13),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Change Amount',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  formatPointNumber(providerData.changeAmount),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),

                        ///_______Due_amount_____________________________________
                        Visibility(
                          visible: selectedCustomer != null &&
                              selectedCustomer!.id != -1 &&
                              recevedAmountController.text.isNotEmpty &&
                              ((widget.dueAmount != null &&
                                      widget.dueAmount! > 0) ||
                                  providerData.dueAmount > 0 ||
                                  (providerData.changeAmount == 0 &&
                                      providerData.dueAmount == 0)),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                right: 10, left: 10, top: 13, bottom: 13),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      lang.S.of(context).dueAmount,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      formatPointNumber(widget.dueAmount ??
                                          providerData.dueAmount),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                // Warning for walk-in customers with due amount
                                if (selectedCustomer == null &&
                                    (widget.dueAmount != null &&
                                            widget.dueAmount! > 0 ||
                                        providerData.dueAmount > 0))
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color:
                                              Colors.orange.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning,
                                            color: Colors.orange, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Walk-in customers cannot make credit sales.',
                                                style: TextStyle(
                                                  color: Colors.orange[700],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              const SalesContact(),
                                                        ),
                                                      ).then((customer) {
                                                        if (customer != null) {
                                                          setState(() {
                                                            selectedCustomer =
                                                                customer;
                                                          });
                                                        }
                                                      });
                                                    },
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                    child: Text(
                                                      'Select Customer',
                                                      style: TextStyle(
                                                        color: Colors.blue[700],
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'or',
                                                    style: TextStyle(
                                                      color: Colors.orange[700],
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  TextButton(
                                                    onPressed: () {
                                                      // Clear due amount by setting received amount to total
                                                      recevedAmountController
                                                              .text =
                                                          providerData
                                                              .totalPayableAmount
                                                              .toString();
                                                      providerData.calculatePrice(
                                                          receivedAmount:
                                                              recevedAmountController
                                                                  .text);
                                                    },
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                    child: Text(
                                                      'Pay Full Amount',
                                                      style: TextStyle(
                                                        color:
                                                            Colors.green[700],
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  ///_______Payment_Type_______________________________
                  const Divider(height: 0),
                  const SizedBox(height: 10),

                  // Payment Type Dropdown (Full Payment / Installment)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.S.of(context).paymentTypes,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedPaymentOption,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: 'Full Payment',
                              child: Text(lang.S.of(context).fullPayment),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Installment',
                              child: Text(lang.S.of(context).installment),
                            ),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedPaymentOption = newValue!;
                              // Clear installment fields when switching to Full Payment
                              if (selectedPaymentOption == 'Full Payment') {
                                downPaymentController.clear();
                                installmentDurationController.clear();
                                installmentInterestController.clear();
                                remainingAmount = 0.0;
                                monthlyInstallment = 0.0;
                                totalPayableWithInterest = 0.0;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Installment Fields (shown only when Installment is selected)
                  if (selectedPaymentOption == 'Installment') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          // Total Amount Display
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kMainColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: kMainColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lang.S.of(context).totalAmount,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: kMainColor,
                                  ),
                                ),
                                Text(
                                  formatPointNumber(
                                      providerData.totalPayableAmount),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: kMainColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Down Payment
                          TextFormField(
                            controller: downPaymentController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: lang.S.of(context).downPayment,
                              border: const OutlineInputBorder(),
                              hintText: lang.S.of(context).enterDownPayment,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) {
                              calculateInstallment(
                                  providerData.totalPayableAmount.toDouble());
                            },
                          ),
                          const SizedBox(height: 10),

                          // Interest Rate
                          TextFormField(
                            controller: installmentInterestController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: lang.S.of(context).interestRate,
                              border: const OutlineInputBorder(),
                              hintText: lang.S.of(context).enterInterestRate,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) {
                              calculateInstallment(
                                  providerData.totalPayableAmount.toDouble());
                            },
                          ),
                          const SizedBox(height: 10),

                          // Installment Duration (in months)
                          TextFormField(
                            controller: installmentDurationController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: lang.S.of(context).durationMonths,
                              border: const OutlineInputBorder(),
                              hintText:
                                  lang.S.of(context).enterDurationInMonths,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) {
                              calculateInstallment(
                                  providerData.totalPayableAmount.toDouble());
                            },
                          ),

                          // Monthly Installment Message (shown after duration is entered)
                          if (installmentDurationController.text.isNotEmpty &&
                              monthlyInstallment > 0) ...[
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.withOpacity(0.1),
                                    Colors.teal.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.green.withOpacity(0.4),
                                    width: 2),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Monthly Payment Required',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                            children: [
                                              const TextSpan(
                                                  text: 'You need to pay '),
                                              TextSpan(
                                                text:
                                                    '$currency${formatPointNumber(monthlyInstallment)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const TextSpan(
                                                  text: ' per month for '),
                                              TextSpan(
                                                text:
                                                    '${installmentDurationController.text} months',
                                                style: const TextStyle(
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
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 15),

                          // Calculation Results
                          if (downPaymentController.text.isNotEmpty ||
                              installmentDurationController.text.isNotEmpty ||
                              installmentInterestController
                                  .text.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.blue.withOpacity(0.2)),
                              ),
                              child: Column(
                                children: [
                                  // Remaining Amount
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        lang.S.of(context).remainingAmount,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        formatPointNumber(remainingAmount),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),

                                  // Monthly Installment
                                  if (monthlyInstallment > 0) ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          lang.S.of(context).monthlyInstallment,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          formatPointNumber(monthlyInstallment),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 16),
                                  ],

                                  // Total Payable
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${lang.S.of(context).totalPayable} (with interest)',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        formatPointNumber((double.tryParse(
                                                    downPaymentController
                                                        .text) ??
                                                0) +
                                            totalPayableWithInterest),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  const Divider(height: 0),
                  const SizedBox(height: 10),

                  // Payment Mode Dropdown (renamed from Payment Type)

                  Consumer(
                    builder: (context, ref, child) {
                      final paymentTypes = ref.watch(paymentTypeProvider);
                      return paymentTypes.when(
                        data: (types) {
                          // Auto-select "Cash" payment type by default (only once, when creating new transaction)
                          if (!_hasAutoSelectedPayment &&
                              paymentType == null &&
                              types.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && !_hasAutoSelectedPayment) {
                                final cashType = types.firstWhere(
                                  (type) => type.name?.toLowerCase() == 'cash',
                                  orElse: () => types.first,
                                );
                                setState(() {
                                  paymentType = cashType.id;
                                  _hasAutoSelectedPayment = true;
                                });
                              }
                            });
                          }

                          // Ensure Cash is selected if paymentType is still null
                          if (paymentType == null && types.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                final cashType = types.firstWhere(
                                  (type) => type.name?.toLowerCase() == 'cash',
                                  orElse: () => types.first,
                                );
                                setState(() {
                                  paymentType = cashType.id;
                                });
                              }
                            });
                          }

                          return CustomPaymentTypeDropdown(
                            value: isSplitPayment
                                ? -2
                                : paymentType, // Show -2 if split is active
                            totalAmount:
                                providerData.totalPayableAmount.toDouble(),
                            onChanged: (value) {
                              // Check if selected payment type is "Split" (ID -2)
                              if (value == -2) {
                                // Enable split payment mode but don't open dialog automatically
                                // Find Cash payment type for API (but UI will show Split)
                                final cashType = types.firstWhere(
                                  (type) => type.name?.toLowerCase() == 'cash',
                                  orElse: () => types.first,
                                );
                                setState(() {
                                  isSplitPayment = true;
                                  paymentType = cashType
                                      .id; // Set Cash as payment type for API
                                });
                              } else {
                                setState(() => paymentType = value);
                                // If not split, disable split payment
                                if (isSplitPayment) {
                                  setState(() {
                                    isSplitPayment = false;
                                    splitPaymentAmounts.clear();
                                    recevedAmountController.clear();
                                    providerData.calculatePrice(
                                        receivedAmount: '0');
                                  });
                                }
                              }
                            },
                          );
                        },
                        loading: () => CustomPaymentTypeDropdown(
                          value: paymentType,
                          totalAmount:
                              providerData.totalPayableAmount.toDouble(),
                          onChanged: (value) =>
                              setState(() => paymentType = value),
                        ),
                        error: (error, stack) => CustomPaymentTypeDropdown(
                          value: paymentType,
                          totalAmount:
                              providerData.totalPayableAmount.toDouble(),
                          onChanged: (value) =>
                              setState(() => paymentType = value),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 5),
                  const Divider(height: 0),

                  ///_______Split_Payment_Info_Display_______________________________
                  if (isSplitPayment) ...[
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (context, ref, child) {
                        final paymentTypes = ref.watch(paymentTypeProvider);
                        return paymentTypes.when(
                          data: (types) {
                            // Build display text for split payment amounts
                            String buildSplitPaymentText() {
                              if (splitPaymentAmounts.isEmpty)
                                return 'No amounts set';

                              final List<String> parts = [];
                              for (var entry in splitPaymentAmounts.entries) {
                                final paymentType = types.firstWhere(
                                  (type) => type.id == entry.key,
                                  orElse: () => types.first,
                                );
                                final icon = paymentType.name
                                            ?.toLowerCase()
                                            .contains('cash') ??
                                        false
                                    ? '💵'
                                    : paymentType.name
                                                ?.toLowerCase()
                                                .contains('card') ??
                                            false
                                        ? '💳'
                                        : '💳';
                                parts.add(
                                    '$icon ${paymentType.name}: ₹${entry.value.toStringAsFixed(2)}');
                              }
                              return parts.join(' | ');
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.blue.shade200, width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Split Payment Active',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.blue.shade900,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                buildSplitPaymentText(),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade700,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      if (providerData.totalPayableAmount <=
                                          0) {
                                        EasyLoading.showError(
                                            'Please add products first');
                                        return;
                                      }
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) =>
                                            SplitPaymentDialog(
                                          totalAmount: providerData
                                              .totalPayableAmount
                                              .toDouble(),
                                          onConfirm: (paymentAmounts) {
                                            // Debug: Print received split payment amounts
                                            print(
                                                '🟢 Add Sales - Split Payment Received:');
                                            paymentAmounts
                                                .forEach((key, value) {
                                              print(
                                                  '  Payment Type ID: $key, Amount: ₹$value');
                                            });

                                            setState(() {
                                              splitPaymentAmounts =
                                                  paymentAmounts;
                                              // Calculate total received amount
                                              double totalReceived = 0;
                                              for (var amount
                                                  in paymentAmounts.values) {
                                                totalReceived += amount;
                                              }
                                              recevedAmountController.text =
                                                  totalReceived.toString();
                                              providerData.calculatePrice(
                                                receivedAmount:
                                                    recevedAmountController
                                                        .text,
                                              );
                                            });
                                          },
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Edit',
                                        style: TextStyle(fontSize: 13)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: kMainColor,
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 30),
                  SizedBox(
                    height: 56, // Set a fixed height for the Row
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          // Use Expanded to allow the TextFormField to take available space
                          child: Container(
                            height: _height,
                            constraints: const BoxConstraints(
                              maxHeight: 200,
                            ),
                            child: TextFormField(
                              controller: noteController,
                              maxLines: null,
                              decoration: const InputDecoration(
                                hintText: 'Enter your opinion',
                              ),
                              onChanged: (text) {
                                setState(() {
                                  _height =
                                      (text.split('\n').length * 24).toDouble();
                                });
                              },
                              style: _theme.textTheme.bodyMedium
                                  ?.copyWith(height: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _imageFile == null
                            ? widget.transitionModel?.image?.isNotEmpty ?? false
                                ? InkWell(
                                    onTap: () {
                                      showImagePickerDialog(
                                          context, _theme.textTheme);
                                    },
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        maxHeight: 48,
                                        minHeight: 48,
                                        maxWidth: 107,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: const Color(0xffF5F3F3),
                                        image: DecorationImage(
                                            image: NetworkImage(
                                              '${APIConfig.domain}${widget.transitionModel?.image.toString()}',
                                            ),
                                            fit: BoxFit.contain),
                                      ),
                                    ),
                                  )
                                : InkWell(
                                    onTap: () {
                                      showImagePickerDialog(
                                          context, _theme.textTheme);
                                    },
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        maxHeight: 48,
                                        minHeight: 48,
                                        maxWidth: 107,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        color: const Color(0xffF5F3F3),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(IconlyLight.camera),
                                          SizedBox(width: 4.0),
                                          Text('Image'),
                                        ],
                                      ),
                                    ),
                                  )
                            : InkWell(
                                onTap: () {
                                  showImagePickerDialog(
                                      context, _theme.textTheme);
                                },
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 48,
                                    minHeight: 48,
                                    maxWidth: 107,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    image: DecorationImage(
                                      image: FileImage(_imageFile!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),

                  ///_____Action_Button_____________________________________
                  const SizedBox(height: 24),
                  SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              maximumSize: const Size(double.infinity, 48),
                              minimumSize: const Size(double.infinity, 48),
                              disabledBackgroundColor: _theme
                                  .colorScheme.primary
                                  .withValues(alpha: 0.15),
                            ),
                            onPressed: () async {
                              const Home().launch(context, isNewTask: true);
                            },
                            child: Text(
                              lang.S.of(context).cancel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _theme.textTheme.bodyMedium?.copyWith(
                                color: _theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Showcase(
                            key: _saveButtonKey,
                            description:
                                'Sale को save करने के लिए यह button दबाएं',
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                maximumSize: const Size(double.infinity, 48),
                                minimumSize: const Size(double.infinity, 48),
                              ),
                              onPressed: () async {
                                if (providerData.cartItemList.isEmpty) {
                                  EasyLoading.showError(
                                      lang.S.of(context).addProductFirst);
                                  return;
                                }

                                // Validate customer name and phone number for hold sale
                                if (selectedCustomer == null ||
                                    selectedCustomer!.id == -1) {
                                  // For walk-in customers, ensure phone number is provided and valid
                                  // Phone number validation removed - any number will be accepted
                                  String phoneNumber =
                                      phoneController.text.trim();
                                  if (phoneNumber.isEmpty) {
                                    EasyLoading.showError(
                                        'Please enter customer phone number');
                                    return;
                                  }
                                } else {
                                  // For registered customers, phone number is optional
                                  // No validation needed
                                }

                                try {
                                  EasyLoading.show(status: 'Holding sale...');

                                  // Prepare products for API - expand combo products
                                  List<CartSaleProducts> products = [];

                                  for (final item
                                      in providerData.cartItemList) {
                                    // Check if this is a combo item
                                    if (item.productDetails != null &&
                                        item.productDetails is Map) {
                                      final details =
                                          item.productDetails as Map;
                                      final isCombo =
                                          details['is_combo']?.toString() ==
                                              'true';

                                      if (isCombo &&
                                          details['combo_products'] != null) {
                                        // This is a combo - expand its products
                                        final comboProducts =
                                            details['combo_products'] as List;

                                        for (final comboProduct
                                            in comboProducts) {
                                          if (comboProduct is Map) {
                                            final unitPrice = double.tryParse(
                                                    comboProduct['unitPrice']
                                                            ?.toString() ??
                                                        '0') ??
                                                0;
                                            final purchasePrice =
                                                double.tryParse(comboProduct[
                                                                'productPurchasePrice']
                                                            ?.toString() ??
                                                        '0') ??
                                                    0;
                                            final productQuantity =
                                                double.tryParse(
                                                        comboProduct['quantity']
                                                                ?.toString() ??
                                                            '0') ??
                                                    0;

                                            double productTaxAmount = 0.0;
                                            final gstRate =
                                                comboProduct['gstRateSelect']
                                                        ?.toString() ??
                                                    '0';

                                            // Calculate tax amount
                                            if (gstRate.isNotEmpty &&
                                                gstRate != '0') {
                                              final rate = double.tryParse(
                                                      gstRate.replaceAll(
                                                          '%', '')) ??
                                                  0.0;
                                              productTaxAmount =
                                                  (productQuantity *
                                                          unitPrice *
                                                          rate) /
                                                      100;
                                            }

                                            products.add(
                                              CartSaleProducts(
                                                productId: (comboProduct[
                                                            'productId'] ??
                                                        0)
                                                    .toInt(),
                                                quantities: productQuantity,
                                                price: unitPrice,
                                                lossProfit: (productQuantity *
                                                        unitPrice) -
                                                    (productQuantity *
                                                        purchasePrice),
                                                stockId: comboProduct['stockId']
                                                    ?.toInt(),
                                                gstRateSelect: gstRate,
                                                taxAmount: productTaxAmount,
                                                isComboProduct:
                                                    true, // Mark as combo product
                                              ),
                                            );
                                          }
                                        }
                                      } else {
                                        // Regular product - add as is
                                        products.add(
                                          CartSaleProducts(
                                            productId: item.productId.toInt(),
                                            price: double.tryParse(
                                                    item.unitPrice ?? '0') ??
                                                0,
                                            lossProfit:
                                                item.lossProfit?.toDouble() ??
                                                    0,
                                            quantities:
                                                item.quantity.toDouble(),
                                            stockId: item.stockId?.toInt(),
                                            gstRateSelect: item.gstRateSelect,
                                            taxAmount: item.calculateGstAmount(
                                                providerData.selectedTaxType),
                                          ),
                                        );
                                      }
                                    } else {
                                      // Regular product without productDetails
                                      products.add(
                                        CartSaleProducts(
                                          productId: item.productId.toInt(),
                                          price: double.tryParse(
                                                  item.unitPrice ?? '0') ??
                                              0,
                                          lossProfit:
                                              item.lossProfit?.toDouble() ?? 0,
                                          quantities: item.quantity.toDouble(),
                                          stockId: item.stockId?.toInt(),
                                          gstRateSelect: item.gstRateSelect,
                                          taxAmount: item.calculateGstAmount(
                                              providerData.selectedTaxType),
                                        ),
                                      );
                                    }
                                  }

                                  // Call API to hold sale
                                  final saleRepo = SaleRepo();
                                  final response = await saleRepo.holdSale(
                                    ref: ref,
                                    context: context,
                                    partyId: selectedCustomer?.id,
                                    customerPhone: phoneController.text,
                                    purchaseDate: dateController.text,
                                    discountAmount: providerData.discountAmount,
                                    discountPercent:
                                        providerData.discountPercent,
                                    totalAmount:
                                        providerData.totalPayableAmount,
                                    dueAmount: providerData.dueAmount,
                                    vatAmount: providerData.vatAmount,
                                    vatPercent:
                                        providerData.selectedVat?.rate ?? 0,
                                    vatId: providerData.selectedVat?.id,
                                    changeAmount: providerData.changeAmount,
                                    isPaid: providerData.dueAmount <= 0,
                                    paymentType: paymentType?.toString() ?? '1',
                                    products: products,
                                    discountType: discountType.toLowerCase(),
                                    shippingCharge:
                                        providerData.finalShippingCharge,
                                    serviceCharge:
                                        providerData.finalServiceCharge,
                                    taxType: providerData.selectedTaxType,
                                    note: noteController.text,
                                    isSplitPayment: isSplitPayment,
                                    splitPaymentAmounts: splitPaymentAmounts,
                                  );

                                  EasyLoading.dismiss();

                                  if (response != null) {
                                    // Success - Clear cart
                                    providerData.cartItemList.clear();
                                    providerData.totalAmount = 0;
                                    providerData.discountAmount = 0;
                                    providerData.totalPayableAmount = 0;
                                    providerData.dueAmount = 0;

                                    // Show success message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('✅ Sale held successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    Navigator.pop(context);
                                  } else {
                                    // Error - API call failed
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('❌ Failed to hold sale'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  EasyLoading.dismiss();
                                  print('❌ Hold Sale Exception: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                'Hold',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: OutlinedButton.styleFrom(
                              maximumSize: const Size(double.infinity, 48),
                              minimumSize: const Size(double.infinity, 48),
                              disabledBackgroundColor: _theme
                                  .colorScheme.primary
                                  .withValues(alpha: 0.15),
                            ),
                            onPressed: () async {
                              if (providerData.cartItemList.isEmpty) {
                                EasyLoading.showError(
                                    lang.S.of(context).addProductFirst);
                                return;
                              }
                              // Prevent walk-in customers from making credit sales (due amount > 0)
                              // This matches the server-side validation
                              if (selectedCustomer == null &&
                                  providerData.dueAmount > 0) {
                                EasyLoading.showError(
                                    'Walk-in customers cannot make credit sales. Please select a customer or pay the full amount.');
                                return;
                              }
                              if (paymentType == null) {
                                EasyLoading.showError(
                                    'Please select a payment type');
                                return;
                              }

                              // Validate customer name and phone number
                              if (selectedCustomer == null ||
                                  selectedCustomer!.id == -1) {
                                // For walk-in customers, ensure phone number is provided and valid
                                // Phone number validation removed - any number will be accepted
                                String phoneNumber =
                                    phoneController.text.trim();
                                if (phoneNumber.isEmpty) {
                                  EasyLoading.showError(
                                      'Please enter customer phone number');
                                  return;
                                }
                              } else {
                                // For registered customers, phone number is optional
                                // No validation needed
                              }

                              ///_______ Prevent multiple clicks________________
                              if (isProcessing) return;

                              setState(() {
                                isProcessing =
                                    true; // Disable button while processing
                              });

                              try {
                                print('=== SALE SAVE DEBUG ===');
                                print(
                                    'Customer Model: ${selectedCustomer?.id}');
                                print(
                                    'Cart Items: ${providerData.cartItemList.length}');
                                print(
                                    'Total Payable: ${providerData.totalPayableAmount}');
                                print('Due Amount: ${providerData.dueAmount}');
                                print('Payment Type: $paymentType');
                                print(
                                    'Is Full Paid: ${providerData.isFullPaid}');
                                print('Selected Date: $selectedDate');

                                // Prepare the list of selected products
                                // Expand combo products individually
                                List<CartSaleProducts> selectedProductList = [];

                                for (final element
                                    in providerData.cartItemList) {
                                  // Check if this is a combo item
                                  if (element.productDetails != null &&
                                      element.productDetails is Map) {
                                    final details =
                                        element.productDetails as Map;
                                    final isCombo =
                                        details['is_combo']?.toString() ==
                                            'true';

                                    if (isCombo &&
                                        details['combo_products'] != null) {
                                      // This is a combo - expand its products
                                      final comboProducts =
                                          details['combo_products'] as List;

                                      for (final comboProduct
                                          in comboProducts) {
                                        if (comboProduct is Map) {
                                          final unitPrice = num.tryParse(
                                                  comboProduct['unitPrice']
                                                          ?.toString() ??
                                                      '0') ??
                                              0;
                                          final purchasePrice = num.tryParse(
                                                  comboProduct[
                                                              'productPurchasePrice']
                                                          ?.toString() ??
                                                      '0') ??
                                              0;
                                          final productQuantity = num.tryParse(
                                                  comboProduct['quantity']
                                                          ?.toString() ??
                                                      '0') ??
                                              0;

                                          double productTaxAmount = 0.0;
                                          final gstRate =
                                              comboProduct['gstRateSelect']
                                                      ?.toString() ??
                                                  '0';

                                          // Calculate tax amount
                                          if (gstRate.isNotEmpty &&
                                              gstRate != '0') {
                                            final rate = num.tryParse(gstRate
                                                    .replaceAll('%', '')) ??
                                                0.0;
                                            productTaxAmount =
                                                (productQuantity *
                                                        unitPrice *
                                                        rate) /
                                                    100;
                                          }

                                          selectedProductList.add(
                                            CartSaleProducts(
                                              productId:
                                                  (comboProduct['productId'] ??
                                                          0)
                                                      .toInt(),
                                              quantities: productQuantity,
                                              price: unitPrice,
                                              lossProfit: (productQuantity *
                                                      unitPrice) -
                                                  (productQuantity *
                                                      purchasePrice),
                                              stockId: comboProduct['stockId']
                                                  ?.toInt(),
                                              gstRateSelect: gstRate,
                                              taxAmount: productTaxAmount,
                                              isComboProduct:
                                                  true, // Mark as combo product
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      // Regular product - add as is
                                      final unitPrice = num.tryParse(
                                              element.unitPrice.toString()) ??
                                          0;
                                      final purchasePrice = num.tryParse(element
                                              .productPurchasePrice
                                              .toString()) ??
                                          0;
                                      double productTaxAmount = 0.0;
                                      if (element.gstRateSelect != null) {
                                        productTaxAmount =
                                            element.calculateGstAmount(
                                                providerData.selectedTaxType);
                                      }
                                      selectedProductList.add(
                                        CartSaleProducts(
                                          productId: element.productId.toInt(),
                                          quantities: element.quantity,
                                          price: unitPrice,
                                          lossProfit:
                                              (element.quantity * unitPrice) -
                                                  (element.quantity *
                                                      purchasePrice),
                                          stockId: element.stockId?.toInt(),
                                          gstRateSelect: element.gstRateSelect,
                                          taxAmount: productTaxAmount,
                                        ),
                                      );
                                    }
                                  } else {
                                    // Regular product without productDetails
                                    final unitPrice = num.tryParse(
                                            element.unitPrice.toString()) ??
                                        0;
                                    final purchasePrice = num.tryParse(element
                                            .productPurchasePrice
                                            .toString()) ??
                                        0;
                                    double productTaxAmount = 0.0;
                                    if (element.gstRateSelect != null) {
                                      productTaxAmount =
                                          element.calculateGstAmount(
                                              providerData.selectedTaxType);
                                    }
                                    selectedProductList.add(
                                      CartSaleProducts(
                                        productId: element.productId.toInt(),
                                        quantities: element.quantity,
                                        price: unitPrice,
                                        lossProfit: (element.quantity *
                                                unitPrice) -
                                            (element.quantity * purchasePrice),
                                        stockId: element.stockId?.toInt(),
                                        gstRateSelect: element.gstRateSelect,
                                        taxAmount: productTaxAmount,
                                      ),
                                    );
                                  }
                                }

                                File? imageFile;
                                if (_imageFile != null) {
                                  imageFile = File(_imageFile!.path);
                                }

                                _recreateControllersIfDisposed();

                                String customerPhone = '';
                                String noteText = '';
                                try {
                                  customerPhone = phoneController.text.trim();
                                  noteText = noteController.text;
                                } catch (controllerError) {
                                  print(
                                      'Controller access error before summary: $controllerError');
                                  customerPhone = '';
                                  noteText = '';
                                }

                                final cartItemsSnapshot =
                                    providerData.cartItemList.map((item) {
                                  // Preserve display unit info in productDetails
                                  final updatedProductDetails =
                                      item.productDetails != null
                                          ? Map<String, dynamic>.from(
                                              item.productDetails)
                                          : <String, dynamic>{};
                                  if (item.displayUnit != null) {
                                    updatedProductDetails['displayUnit'] =
                                        item.displayUnit;
                                  }
                                  if (item.displayQuantity != null) {
                                    updatedProductDetails['displayQuantity'] =
                                        item.displayQuantity;
                                  }

                                  return AddToCartModel(
                                    productId: item.productId,
                                    productCode: item.productCode,
                                    productName: item.productName,
                                    unitPrice: item.unitPrice,
                                    quantity: item.quantity,
                                    productDetails: updatedProductDetails,
                                    itemCartIndex: item.itemCartIndex,
                                    uniqueCheck: item.uniqueCheck,
                                    stock: item.stock,
                                    productPurchasePrice:
                                        item.productPurchasePrice,
                                    lossProfit: item.lossProfit,
                                    stockId: item.stockId,
                                    gstRateSelect: item.gstRateSelect,
                                    gstType: item.gstType,
                                    vatType: item.vatType,
                                    unitName: item.unitName,
                                    variantKey: item.variantKey,
                                    variantLabel: item.variantLabel,
                                    displayUnit: item.displayUnit,
                                    displayQuantity: item.displayQuantity,
                                    displayPrice: item.displayPrice,
                                  );
                                }).toList();

                                final summaryRoundedOption =
                                    providerData.roundOffEnabled
                                        ? (providerData.roundedOption.isEmpty ||
                                                providerData.roundedOption ==
                                                    roundingMethods[0].value
                                            ? 'nearest_whole_number'
                                            : providerData.roundedOption)
                                        : roundingMethods[0].value;

                                final summaryArguments =
                                    SaleBillSummaryArguments(
                                  customer: selectedCustomer,
                                  customerPhone: selectedCustomer == null ||
                                          selectedCustomer?.id == -1
                                      ? customerPhone
                                      : selectedCustomer?.phone,
                                  saleDate: selectedDate,
                                  cartItems: cartItemsSnapshot,
                                  cartSaleProducts: selectedProductList,
                                  totalAmount: providerData.totalAmount,
                                  discountAmount: providerData.discountAmount,
                                  discountPercent: providerData.discountPercent,
                                  totalPayableAmount:
                                      providerData.totalPayableAmount,
                                  dueAmount: providerData.dueAmount,
                                  changeAmount: providerData.changeAmount,
                                  vatAmount: providerData.vatAmount,
                                  vatModel: providerData.selectedVat,
                                  isFullPaid: providerData.isFullPaid,
                                  discountType: discountType,
                                  note: noteText,
                                  shippingCharge:
                                      providerData.finalShippingCharge,
                                  serviceCharge:
                                      providerData.finalServiceCharge,
                                  taxType: providerData.selectedTaxType,
                                  isSplitPayment: isSplitPayment,
                                  splitPaymentAmounts: Map<int, double>.from(
                                      splitPaymentAmounts),
                                  paymentTypeId: paymentType,
                                  roundedOption: summaryRoundedOption,
                                  roundingAmount: providerData.roundOffEnabled
                                      ? providerData.roundingAmount
                                      : 0,
                                  actualTotalAmount:
                                      providerData.actualTotalAmount,
                                  receiveAmount: providerData.receiveAmount,
                                  roundOffEnabled: providerData.roundOffEnabled,
                                  imageFile: imageFile,
                                  transitionModel: widget.transitionModel,
                                );

                                final prefs =
                                    await SharedPreferences.getInstance();
                                final bool billSummaryEnabled =
                                    prefs.getBool(kSalesBillSummaryToggleKey) ??
                                        true;

                                if (billSummaryEnabled) {
                                  final summaryResult =
                                      await Navigator.push<SaleSummaryResult>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SaleBillSummaryScreen(
                                        arguments: summaryArguments,
                                      ),
                                    ),
                                  );

                                  if (!mounted) return;

                                  if (summaryResult != null) {
                                    if (summaryResult.editRequested) {
                                      print(
                                          'Sale summary dismissed for additional edits.');
                                    } else if (summaryResult.saleTransaction !=
                                        null) {
                                      final saleData =
                                          summaryResult.saleTransaction!;
                                      _handleSaleCompletion(
                                        saleData,
                                        personalData.value!,
                                        summaryResult.cartItems,
                                      );
                                    }
                                  }
                                } else {
                                  final saleData =
                                      await _saveSaleDirectly(summaryArguments);
                                  if (!mounted) return;
                                  if (saleData != null) {
                                    _handleSaleCompletion(
                                      saleData,
                                      personalData.value!,
                                      cartItemsSnapshot,
                                    );
                                  }
                                }
                              } catch (e, stackTrace) {
                                print('=================================');
                                print('=== SALE SUMMARY ERROR ===');
                                print('=================================');
                                print('Error Type: ${e.runtimeType}');
                                print('Error Message: $e');
                                print('=================================');
                                print('Stack Trace:');
                                print(stackTrace);
                                print('=================================');

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Failed to prepare sale: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    isProcessing = false;
                                  });
                                }
                              }
                            },
                            child: Text(
                              lang.S.of(context).save,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _theme.textTheme.bodyMedium?.copyWith(
                                color: _theme.colorScheme.primaryContainer,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
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
          ),
        ),
      );
    }, error: (e, stack) {
      return Center(
        child: Text(e.toString()),
      );
    }, loading: () {
      return const Center(child: CircularProgressIndicator());
    });
  }

  Future<dynamic> showImagePickerDialog(
      BuildContext context, TextTheme textTheme) {
    return showCupertinoDialog(
      context: context,
      builder: (BuildContext contexts) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: CupertinoAlertDialog(
          insetAnimationCurve: Curves.bounceInOut,
          title: Text(
            'Upload Image',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          // content: const Text('Are you sure you want to delete this account? This will permanently erase this account.'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Column(
                children: [
                  const Icon(IconlyLight.image, size: 30.0),
                  Text(
                    'Use gallery',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  )
                ],
              ),
              onPressed: () async {
                _pickImage(ImageSource.gallery);
                Future.delayed(const Duration(milliseconds: 100), () {
                  Navigator.pop(context);
                });
              },
            ),
            CupertinoDialogAction(
              child: Column(
                children: [
                  const Icon(IconlyLight.camera, size: 30.0),
                  Text(
                    'Open Camera',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  )
                ],
              ),
              onPressed: () async {
                _pickImage(ImageSource.camera);
                Future.delayed(const Duration(milliseconds: 100), () {
                  Navigator.pop(context);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<SalesTransactionModel?> _saveSaleDirectly(
      SaleBillSummaryArguments args) async {
    final repo = SaleRepo();
    try {
      EasyLoading.show(status: 'Saving sale...');

      SalesTransactionModel? saleData;
      if (args.transitionModel == null) {
        saleData = await repo.createSale(
          ref: ref,
          context: context,
          partyId: (args.customer?.id == null || args.customer?.id == -1)
              ? null
              : args.customer?.id,
          customerPhone: (args.customer?.id == null ||
                  args.customer?.id == -1 ||
                  (args.customer?.phone?.isEmpty ?? true))
              ? args.customerPhone
              : args.customer?.phone,
          purchaseDate: args.saleDate.toString(),
          discountAmount: args.discountAmount,
          discountPercent: args.discountPercent,
          unRoundedTotalAmount: args.actualTotalAmount,
          totalAmount: args.totalPayableAmount,
          roundingAmount: args.roundingAmount,
          dueAmount: args.dueAmount,
          vatAmount: args.vatAmount,
          vatPercent: args.vatModel?.rate ?? 0,
          vatId: args.vatModel?.id,
          changeAmount: args.changeAmount,
          isPaid: args.isFullPaid,
          paymentType:
              args.paymentTypeId != null ? args.paymentTypeId.toString() : '',
          roundedOption: args.roundedOption,
          products: args.cartSaleProducts,
          discountType: args.discountType.toLowerCase(),
          shippingCharge: args.shippingCharge,
          serviceCharge: args.serviceCharge,
          taxType: args.taxType,
          note: args.note,
          image: args.imageFile,
          isSplitPayment: args.isSplitPayment,
          splitPaymentAmounts: args.splitPaymentAmounts.isEmpty
              ? null
              : args.splitPaymentAmounts,
        );
      } else {
        saleData = await repo.updateSale(
          id: args.transitionModel?.id ?? 0,
          ref: ref,
          context: context,
          partyId: args.transitionModel?.party?.id ??
              (args.customer?.id == -1 ? null : args.customer?.id),
          purchaseDate: args.saleDate.toString(),
          discountAmount: args.discountAmount,
          discountPercent: args.discountPercent,
          unRoundedTotalAmount: args.actualTotalAmount,
          totalAmount: args.totalPayableAmount,
          dueAmount: args.dueAmount,
          vatAmount: args.vatAmount,
          vatPercent: args.vatModel?.rate ?? 0,
          vatId: args.vatModel?.id,
          changeAmount: args.changeAmount,
          roundingAmount: args.roundingAmount,
          isPaid: args.isFullPaid,
          paymentType:
              args.paymentTypeId != null ? args.paymentTypeId.toString() : '',
          roundedOption: args.roundedOption,
          products: args.cartSaleProducts,
          discountType: args.discountType.toLowerCase(),
          shippingCharge: args.shippingCharge,
          serviceCharge: args.serviceCharge,
          taxType: args.taxType,
          note: args.note,
          image: args.imageFile,
          isSplitPayment: args.isSplitPayment,
          splitPaymentAmounts: args.splitPaymentAmounts.isEmpty
              ? null
              : args.splitPaymentAmounts,
        );
      }

      if (saleData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to save sale'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return null;
      }

      await PaymentTotalsHelper.updatePaymentTotals(
        paymentTypeId: saleData.paymentTypeId,
        paidAmount: saleData.paidAmount?.toDouble(),
        isSplitPayment: saleData.isSplitPayment,
        splitPaymentAmounts:
            saleData.isSplitPayment == true ? args.splitPaymentAmounts : null,
      );

      ref.read(cartNotifier.notifier).clearCart();

      return saleData;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save sale: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return null;
    } finally {
      EasyLoading.dismiss();
    }
  }

  void _handleSaleCompletion(
    SalesTransactionModel saleData,
    binfo.BusinessInformation businessInfo,
    List<AddToCartModel>? cartItems,
  ) {
    SalesInvoiceDetails(
      businessInfo: businessInfo,
      saleTransaction: saleData,
      fromSale: true,
      cartItems: cartItems, // Pass cart items for display unit info
    ).launch(context);

    noteController.clear();
    recevedAmountController.clear();
    if (selectedCustomer == null || selectedCustomer?.id == -1) {
      phoneController.clear();
    }
    setState(() {
      splitPaymentAmounts.clear();
      isSplitPayment = false;
    });
  }
}
