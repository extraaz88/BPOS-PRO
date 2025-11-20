import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/Screens/Purchase/Model/purchase_transaction_model.dart';
import 'package:mobile_pos/Screens/Purchase/purchase_products.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/add_to_cart_purchase.dart';
import '../../Repository/API/future_invoice.dart';
import '../../constant.dart';
import '../../currency.dart';
import '../../widgets/split_payment_dialog.dart';
import '../../widgets/custom_payment_type_dropdown.dart';
import '../Customers/Model/parties_model.dart' as party;
import '../Customers/Provider/customer_provider.dart';
import '../Home/home.dart';
import '../Purchase List/purchase_list_screen.dart';
import '../invoice_details/purchase_invoice_details.dart';
import '../payment_type/provider/payment_type_provider.dart';
import 'Repo/purchase_repo.dart';
import '../../model/hold_order_model.dart';
import '../HoldOrders/hold_orders_provider.dart';
import '../../utils/payment_totals_helper.dart';

class AddAndUpdatePurchaseScreen extends ConsumerStatefulWidget {
  AddAndUpdatePurchaseScreen(
      {super.key,
      required this.supplierModel,
      this.transitionModel,
      this.dueAmount});

  final party.Party? supplierModel;
  final PurchaseTransaction? transitionModel;
  final double? dueAmount;

  @override
  AddSalesScreenState createState() => AddSalesScreenState();
}

class AddSalesScreenState extends ConsumerState<AddAndUpdatePurchaseScreen> {
  int? paymentType;

  bool isProcessing = false;

  DateTime selectedDate = DateTime.now();

  TextEditingController dateController =
      TextEditingController(text: DateTime.now().toString().substring(0, 10));
  TextEditingController phoneController = TextEditingController();
  TextEditingController recevedAmountController = TextEditingController();

  // Variables for supplier dropdown
  party.Party? selectedSupplier;

  // Split payment variables
  bool isSplitPayment = false;
  Map<int, double> splitPaymentAmounts = {}; // paymentTypeId -> amount

  // Flag to ensure payment type is auto-selected only once
  bool _hasAutoSelectedPayment = false;
  bool _restrictZeroStockTransactions = false;

  @override
  void initState() {
    // Reset auto-selection flag for new transactions
    _hasAutoSelectedPayment = false;

    if (widget.transitionModel != null) {
      final editedSales = widget.transitionModel;
      dateController.text = editedSales?.purchaseDate?.substring(0, 10) ?? '';
      recevedAmountController.text = editedSales?.paidAmount.toString() ?? '';
      // Don't set selectedSupplier here - let it be set from the dropdown items
      if (widget.transitionModel?.discountType == 'flat') {
        discountType = 'Flat';
      } else {
        discountType = 'Percent';
      }
      paymentType = widget.transitionModel?.paymentTypeId;
      addProductsInCartFromEditList();
    }

    // Set initial supplier if provided
    if (widget.supplierModel != null) {
      selectedSupplier = widget.supplierModel;
      phoneController.text = widget.supplierModel?.phone ?? '';
    }

    super.initState();
    _loadZeroStockRestriction();

    // Check if restoring from hold order
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRestoreHoldOrder();
    });
  }

  Future<void> _loadZeroStockRestriction() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _restrictZeroStockTransactions =
          prefs.getBool(kZeroStockRestrictionKey) ?? false;
    });
  }

  // Method to check and restore hold order if available
  void _checkAndRestoreHoldOrder() {
    final holdOrder = ref.read(holdOrderRestoreProvider);
    if (holdOrder != null && holdOrder.orderType == 'purchase') {
      _restoreFromHoldOrder(holdOrder);
      // Clear the hold order from provider
      ref.read(holdOrderRestoreProvider.notifier).clearHoldOrder();
    }
  }

  // Method to restore data from hold order
  void _restoreFromHoldOrder(HoldOrderModel holdOrder) {
    final cart = ref.read(cartNotifierPurchaseNew);

    // Restore date
    if (holdOrder.date != null) {
      dateController.text = holdOrder.date!;
    }

    // Restore paid amount
    if (holdOrder.paidAmount != null) {
      recevedAmountController.text = holdOrder.paidAmount.toString();
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
          cartItem: CartProductModelPurchase(
            productName: item.productName ?? '',
            productId: (item.productId ?? 0).toInt(),
            quantities: item.quantity ?? 0,
            productWholeSalePrice: item.wholeSalePrice ?? 0,
            productSalePrice: item.salePrice ?? 0,
            productPurchasePrice: item.purchasePrice ?? 0,
            productDealerPrice: item.dealerPrice ?? 0,
            stock: item.stock ?? 0,
            gstRateSelect: item.gstRateSelect,
            vatType: item.vatType,
            vatAmount: item.vatAmount,
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

  @override
  void dispose() {
    dateController.dispose();
    phoneController.dispose();
    recevedAmountController.dispose();
    super.dispose();
  }

  void addProductsInCartFromEditList() {
    final cart = ref.read(cartNotifierPurchaseNew);

    if (widget.transitionModel?.details?.isNotEmpty ?? false) {
      for (var detail in widget.transitionModel!.details!) {
        cart.addToCartRiverPod(
            cartItem: CartProductModelPurchase(
              productName: detail.product?.productName ?? '',
              productId: detail.productId ?? 0,
              quantities: detail.quantities,
              productWholeSalePrice: detail.product?.productWholeSalePrice ?? 0,
              // detail.productWholeSalePrice,
              productSalePrice: detail.product?.productSalePrice ?? 0,
              // detail.productSalePrice,
              productPurchasePrice: detail.productPurchasePrice,
              productDealerPrice: detail.product?.productDealerPrice ?? 0,
              stock: detail.product?.productStock ?? 0, // detail,
            ),
            fromEditSales: true);
      }
    }

    cart.discountAmount = widget.transitionModel?.discountAmount ?? 0;
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
    cart.finalServiceCharge = widget.transitionModel?.serviceCharge ?? 0;
    cart.serviceChargeController.text =
        widget.transitionModel?.serviceCharge.toString() ?? '';
    // cart.discountTextControllerFlat.text = widget.transitionModel?.discountAmount.toString() ?? '';
    cart.vatAmountController.text =
        widget.transitionModel?.vatAmount.toString() ?? '';
    cart.calculatePrice(
        receivedAmount: widget.transitionModel?.paidAmount.toString(),
        stopRebuild: true);
  }

  bool hasPreselected = false; // Flag to ensure preselection happens only once
  String discountType = 'Flat';

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    final providerData = ref.watch(cartNotifierPurchaseNew);

    // Compute GST / SGST / CGST totals locally for Purchase screen
    num purchaseTotalGst = 0;
    num purchaseTotalSgst = 0;
    num purchaseTotalCgst = 0;
    if (providerData.cartItemList.isNotEmpty) {
      for (var item in providerData.cartItemList) {
        final gstStr = item.gstRateSelect;
        if (gstStr != null && gstStr != 'N/A' && gstStr != '0') {
          final rate = double.tryParse(gstStr.toString()) ?? 0.0;
          final qty = (item.quantities ?? 0);
          final unitPrice = (item.productPurchasePrice ?? 0);
          final itemTotal = qty * unitPrice;
          final itemGst = (itemTotal * rate) / 100;
          purchaseTotalGst += itemGst;
        }
      }
      purchaseTotalSgst = purchaseTotalGst / 2;
      purchaseTotalCgst = purchaseTotalGst / 2;
    }

    // Calculate displayed total - use totalPayableAmount from provider (same as sales)
    // This ensures displayedTotal matches the actual totalPayableAmount used for due/change calculations
    // totalPayableAmount = subtotal - discount + GST + VAT + shipping + service
    final double displayedTotal = providerData.totalPayableAmount.toDouble();

    final personalData = ref.watch(businessInfoProvider);
    return personalData.when(data: (data) {
      return GlobalPopup(
        child: Scaffold(
          backgroundColor: kWhite,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              lang.S.of(context).addPurchase,
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
                                  .getFutureInvoice(tag: 'purchases'),
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
                            selectedSupplier?.due == null
                                ? '$currency 0'
                                : '$currency${selectedSupplier?.due}',
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
                              // Filter only suppliers
                              final suppliers = parties
                                  .where((party) => party.type == 'Supplier')
                                  .toList();

                              // Find matching supplier from the list when editing
                              party.Party? dropdownValue = selectedSupplier;
                              if (widget.transitionModel != null &&
                                  suppliers.isNotEmpty) {
                                try {
                                  final foundSupplier = suppliers.firstWhere(
                                    (supplier) =>
                                        supplier.id ==
                                        widget.transitionModel?.party?.id,
                                  );
                                  dropdownValue = foundSupplier;
                                  // Update selectedSupplier if we found a match
                                  if (selectedSupplier == null) {
                                    selectedSupplier = foundSupplier;
                                    phoneController.text =
                                        foundSupplier.phone ?? '';
                                  }
                                } catch (e) {
                                  // Supplier not found in the list, keep selectedSupplier as null
                                  dropdownValue = null;
                                }
                              }

                              return DropdownButtonFormField<party.Party>(
                                value: dropdownValue,
                                decoration: InputDecoration(
                                  labelText: lang.S.of(context).supplierName,
                                  border: const OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                hint: Text('Select Supplier'),
                                items: suppliers
                                    .map<DropdownMenuItem<party.Party>>(
                                        (party.Party partyItem) {
                                  return DropdownMenuItem<party.Party>(
                                    value: partyItem,
                                    child: Text(partyItem.name ?? 'Unknown'),
                                  );
                                }).toList(),
                                onChanged: (party.Party? newValue) {
                                  setState(() {
                                    selectedSupplier = newValue;
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
                            //labelText: 'Supplier Phone Number',
                            labelText: lang.S.of(context).supplierPhoneNumber,
                            //hintText: 'Enter supplier phone number',
                            hintText:
                                lang.S.of(context).enterSupplierPhoneNumber,
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
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            lang.S.of(context).itemAdded,
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                          Text(
                                            lang.S.of(context).quantity,
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )),
                            ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: providerData.cartItemList.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        left: 10, right: 10),
                                    child: ListTile(
                                      onTap: () => showDialog(
                                          context: context,
                                          builder: (_) {
                                            return purchaseProductAddBottomSheet(
                                                context: context,
                                                product: providerData
                                                    .cartItemList[index],
                                                ref: ref,
                                                fromUpdate: true,
                                                selectedTaxType: providerData
                                                    .selectedTaxType,
                                                restrictZeroStockTransactions:
                                                    _restrictZeroStockTransactions);
                                          }),
                                      contentPadding: const EdgeInsets.all(0),
                                      title: Text(providerData
                                          .cartItemList[index].productName
                                          .toString()),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '${providerData.cartItemList[index].quantities} X ${providerData.cartItemList[index].productPurchasePrice} = ${formatPointNumber((providerData.cartItemList[index].quantities ?? 0) * (providerData.cartItemList[index].productPurchasePrice ?? 0))}'),
                                          if (providerData.cartItemList[index]
                                                      .gstRateSelect !=
                                                  null &&
                                              providerData.cartItemList[index]
                                                      .gstRateSelect !=
                                                  'N/A' &&
                                              providerData.cartItemList[index]
                                                      .gstRateSelect !=
                                                  '0') ...[
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 4,
                                              runSpacing: 2,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 4,
                                                      vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: kMainColor
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3),
                                                  ),
                                                  child: Text(
                                                    providerData
                                                        .selectedTaxType,
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: kMainColor,
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
                                                    'SGST ${(double.tryParse(providerData.cartItemList[index].gstRateSelect ?? '0') ?? 0) / 2} %',
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
                                                    'CGST ${(double.tryParse(providerData.cartItemList[index].gstRateSelect ?? '0') ?? 0) / 2} %',
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.purple,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                if (providerData
                                                            .cartItemList[index]
                                                            .vatAmount !=
                                                        null &&
                                                    providerData
                                                            .cartItemList[index]
                                                            .vatAmount! >
                                                        0)
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
                                                      'Total Tax: ₹${providerData.cartItemList[index].vatAmount?.toStringAsFixed(2) ?? '0'}',
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 80,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    providerData
                                                        .quantityDecrease(
                                                            index);
                                                  },
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
                                                  width: 30,
                                                  child: Center(
                                                    child: Text(
                                                      providerData
                                                          .cartItemList[index]
                                                          .quantities
                                                          .toString(),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                GestureDetector(
                                                  onTap: () {
                                                    providerData
                                                        .quantityIncrease(
                                                            index);
                                                  },
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
                                            onTap: () {
                                              providerData.deleteToCart(index);
                                            },
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
                  GestureDetector(
                    onTap: () {
                      PurchaseProducts(
                        supplierModel: widget.supplierModel,
                        selectedTaxType: providerData.selectedTaxType,
                      ).launch(context);
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
                          style:
                              const TextStyle(color: kMainColor, fontSize: 20),
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
                              // GST/CGST/SGST Amount Display
                              if (providerData.cartItemList.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(
                                    height: 1, color: Color(0xffDDDDDD)),
                                const SizedBox(height: 8),
                                // GST Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      providerData.cartItemList.isNotEmpty &&
                                              providerData.cartItemList[0]
                                                      .gstRateSelect !=
                                                  null
                                          ? 'GST ${providerData.cartItemList[0].gstRateSelect}%'
                                          : 'GST',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      formatPointNumber(purchaseTotalGst),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
// SGST Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      providerData.cartItemList.isNotEmpty &&
                                              providerData.cartItemList[0]
                                                      .gstRateSelect !=
                                                  null
                                          ? 'SGST ${(double.tryParse(providerData.cartItemList[0].gstRateSelect ?? '0') ?? 0) / 2}%'
                                          : 'SGST',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      formatPointNumber(purchaseTotalSgst),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
// CGST Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      providerData.cartItemList.isNotEmpty &&
                                              providerData.cartItemList[0]
                                                      .gstRateSelect !=
                                                  null
                                          ? 'CGST ${(double.tryParse(providerData.cartItemList[0].gstRateSelect ?? '0') ?? 0) / 2}%'
                                          : 'CGST',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      formatPointNumber(purchaseTotalCgst),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        ///_________Discount___________________________________
                        Padding(
                          padding: const EdgeInsets.only(right: 10, left: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.S.of(context).discount,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: context.width() / 4,
                                height: 30,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color: kBorder, width: 1)),
                                  ),
                                  child: DropdownButton<String?>(
                                    dropdownColor: Colors.white,
                                    isExpanded: true,
                                    isDense: true,
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.keyboard_arrow_down,
                                        color: kGreyTextColor),
                                    hint: Text(
                                      'Select',
                                      style:
                                          _theme.textTheme.bodyMedium?.copyWith(
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
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color: kNeutralColor),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        discountType = value!;
                                        providerData.calculateDiscount(
                                          value: providerData
                                              .discountTextControllerFlat.text,
                                          selectedTaxType: discountType,
                                        );
                                        print(providerData.discountPercent);
                                        print(providerData.discountAmount);
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: context.width() / 4,
                                height: 30,
                                child: TextField(
                                  controller:
                                      providerData.discountTextControllerFlat,
                                  onChanged: (value) {
                                    setState(() {
                                      providerData.calculateDiscount(
                                        value: value,
                                        selectedTaxType: discountType,
                                      );
                                    });
                                  },
                                  // onChanged: (value) => providerData.calculateDiscount(value: value),
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(color: kNeutralColor),
                                    border: UnderlineInputBorder(
                                        borderSide: BorderSide(color: kBorder)),
                                    enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: kBorder)),
                                    focusedBorder: UnderlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 8),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ///_________Tax_Type_and_Vat_Dropdown_______________________________
                        // Padding(
                        //   padding: const EdgeInsets.only(right: 10, left: 10),
                        //   child: Row(
                        //     children: [
                        //       Expanded(
                        //         flex: 2,
                        //         child: Text(
                        //           selectedTaxType != null ? '$selectedTaxType Tax' : 'VAT',
                        //           style: const TextStyle(fontSize: 16),
                        //         ),
                        //       ),
                        //       if (selectedTaxType != null && providerData.cartItemList.isNotEmpty) ...[
                        //         Expanded(
                        //           flex: 1,
                        //           child: Text(
                        //             'Rate: ${providerData.cartItemList.first.gstRateSelect ?? 'N/A'}%',
                        //             style: TextStyle(
                        //               fontSize: 12,
                        //               color: Colors.blue,
                        //               fontWeight: FontWeight.w600,
                        //             ),
                        //             textAlign: TextAlign.center,
                        //           ),
                        //         ),
                        //       ],
                        //       Expanded(
                        //         flex: 2,
                        //         child: taxesData.when(
                        //         data: (data) {
                        //           List<VatModel> dataList = data
                        //               .where((tax) => tax.status == true)
                        //               .toList();
                        //           if (widget.transitionModel != null &&
                        //               widget.transitionModel?.vatId != null &&
                        //               !hasPreselected) {
                        //             VatModel matched = dataList.firstWhere(
                        //               (element) =>
                        //                   element.id ==
                        //                   widget.transitionModel?.vatId,
                        //               orElse: () => VatModel(),
                        //             );
                        //             if (matched.id != null) {
                        //               hasPreselected = true;
                        //               providerData.selectedVat = matched;
                        //               // providerData.calculatePrice();
                        //             }
                        //           }
                        //           return SizedBox(
                        //             width: context.width() / 4,
                        //             height: 30,
                        //             child: Container(
                        //               decoration: const BoxDecoration(
                        //                 border: Border(
                        //                     bottom: BorderSide(
                        //                         color: kBorder, width: 1)),
                        //               ),
                        //               child: DropdownButton<VatModel?>(
                        //                 icon: providerData.selectedVat != null
                        //                     ? GestureDetector(
                        //                         onTap: () => providerData
                        //                             .changeSelectedVat(
                        //                                 data: null),
                        //                         child: const Icon(
                        //                           Icons.close,
                        //                           color: Colors.red,
                        //                           size: 16,
                        //                         ),
                        //                       )
                        //                     : const Icon(
                        //                         Icons.keyboard_arrow_down,
                        //                         color: kGreyTextColor),
                        //                 dropdownColor: Colors.white,
                        //                 isExpanded: true,
                        //                 isDense: true,
                        //                 padding: EdgeInsets.zero,
                        //                 hint: Text(
                        //                   'Select',
                        //                   style: _theme.textTheme.bodyMedium
                        //                       ?.copyWith(
                        //                     color: kGreyTextColor,
                        //                   ),
                        //                 ),
                        //                 value: providerData.selectedVat,
                        //                 items: dataList.map((VatModel tax) {
                        //                   return DropdownMenuItem<VatModel>(
                        //                     value: tax,
                        //                     child: Text(
                        //                       tax.name ?? '',
                        //                       maxLines: 1,
                        //                       overflow: TextOverflow.ellipsis,
                        //                       style: _theme.textTheme.bodyMedium
                        //                           ?.copyWith(
                        //                         color: kGreyTextColor,
                        //                       ),
                        //                     ),
                        //                   );
                        //                 }).toList(),
                        //                 onChanged: (VatModel? newValue) {
                        //                   providerData.changeSelectedVat(
                        //                       data: newValue);
                        //                 },
                        //               ),
                        //             ),
                        //           );
                        //         },
                        //         error: (error, stackTrace) {
                        //           return Text(error.toString());
                        //         },
                        //         loading: () {
                        //           return const SizedBox.shrink();
                        //         },
                        //       ),
                        //       ),
                        //     ],
                        //   ),
                        //),
                        Padding(
                          padding: const EdgeInsets.only(right: 10, left: 10),
                          child: Row(
                            children: [
                              const Spacer(),
                              SizedBox(
                                width: context.width() / 4,
                                height: 30,
                                child: TextFormField(
                                  controller: providerData.vatAmountController,
                                  readOnly: true,
                                  onChanged: (value) =>
                                      providerData.calculateDiscount(
                                          value: value,
                                          selectedTaxType:
                                              discountType.toString()),
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(color: kNeutralColor),
                                    border: UnderlineInputBorder(
                                        borderSide: BorderSide(color: kBorder)),
                                    enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: kBorder)),
                                    focusedBorder: UnderlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 8),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
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
                              const Text(
                                'Shipping Charge',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(
                                width: context.width() / 4,
                                height: 30,
                                child: TextFormField(
                                  controller:
                                      providerData.shippingChargeController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) =>
                                      providerData.calculatePrice(
                                          shippingCharge:
                                              value.isEmpty ? '0' : value),
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(color: kNeutralColor),
                                    border: UnderlineInputBorder(
                                        borderSide: BorderSide(color: kBorder)),
                                    enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: kBorder)),
                                    focusedBorder: UnderlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        ///_________Service_Charge__________________________________
                        Padding(
                          padding: const EdgeInsets.only(
                              right: 10, left: 10, top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Service Charge',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(
                                width: context.width() / 4,
                                height: 30,
                                child: TextFormField(
                                  controller:
                                      providerData.serviceChargeController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) =>
                                      providerData.calculatePrice(
                                          serviceCharge:
                                              value.isEmpty ? '0' : value),
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(color: kNeutralColor),
                                    border: UnderlineInputBorder(
                                        borderSide: BorderSide(color: kBorder)),
                                    enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: kBorder)),
                                    focusedBorder: UnderlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 8),
                                  ),
                                ),
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
                                formatPointNumber(displayedTotal),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),

                        ///________paid_Amount__________________________________
                        Padding(
                          padding: const EdgeInsets.only(
                              right: 10, left: 10, top: 10),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    lang.S.of(context).paidAmount,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(
                                    width: context.width() / 4,
                                    height: 30,
                                    child: TextField(
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
                                  ),
                                ],
                              ),
                              // Pay Full Amount button (same as Add Sale screen)
                              if (providerData.totalPayableAmount > 0) ...[
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () {
                                          // Set received amount to displayed total (subtotal + GST + charges - discount)
                                          recevedAmountController.text =
                                              displayedTotal.toString();
                                          providerData.calculatePrice(
                                              receivedAmount:
                                                  recevedAmountController.text);
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Pay Full Amount',
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        ///________Change Amount_________________________________
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
                          visible: providerData.dueAmount > 0 ||
                              (providerData.changeAmount == 0 &&
                                  providerData.dueAmount == 0),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                right: 10, left: 10, top: 13, bottom: 13),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lang.S.of(context).dueAmount,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  formatPointNumber(providerData.dueAmount),
                                  style: const TextStyle(fontSize: 16),
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
                  const SizedBox(height: 5),
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
                            totalAmount: displayedTotal.toDouble(),
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
                          totalAmount: displayedTotal.toDouble(),
                          onChanged: (value) =>
                              setState(() => paymentType = value),
                        ),
                        error: (error, stack) => CustomPaymentTypeDropdown(
                          value: paymentType,
                          totalAmount: displayedTotal.toDouble(),
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
                                      if (displayedTotal <= 0) {
                                        EasyLoading.showError(
                                            'Please add products first');
                                        return;
                                      }
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) =>
                                            SplitPaymentDialog(
                                          totalAmount:
                                              displayedTotal.toDouble(),
                                          onConfirm: (paymentAmounts) {
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

                  const SizedBox(height: 24),

                  ///_____Action_Button_____________________________________
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

                                ///_______ Prevent multiple clicks________________
                                if (isProcessing) return;

                                setState(() {
                                  isProcessing =
                                      true; // Disable button while processing
                                });

                                try {
                                  // CRITICAL FIX: Ensure the latest paid amount is calculated before hold
                                  if (recevedAmountController.text.isNotEmpty) {
                                    providerData.calculatePrice(
                                      receivedAmount:
                                          recevedAmountController.text,
                                      stopRebuild: true,
                                    );
                                  }

                                  // Debug: Print payment details before holding
                                  print(
                                      '=== PURCHASE HOLD DEBUG (Before Hold) ===');
                                  print(
                                      'Paid Amount Controller: ${recevedAmountController.text}');
                                  print(
                                      'Provider Receive Amount: ${providerData.receiveAmount}');
                                  print(
                                      'Provider Due Amount: ${providerData.dueAmount}');
                                  print(
                                      'Provider Change Amount: ${providerData.changeAmount}');
                                  print(
                                      'Provider Total Payable: ${providerData.totalPayableAmount}');
                                  print(
                                      'Calculated Paid Amount (to API): ${providerData.totalPayableAmount - providerData.dueAmount}');
                                  print(
                                      '=============================================');

                                  EasyLoading.show(
                                      status: 'Holding purchase...',
                                      dismissOnTap: false);

                                  // Prepare the list of selected products
                                  List<CartProductModelPurchase>
                                      selectedProductList =
                                      providerData.cartItemList.map((element) {
                                    // Calculate product tax amount
                                    num productTaxAmount = 0;
                                    if (element.vatAmount != null) {
                                      productTaxAmount = element.vatAmount!;
                                    }

                                    CartProductModelPurchase cartProduct =
                                        CartProductModelPurchase(
                                      productId: element.productId,
                                      productName: element.productName,
                                      productDealerPrice:
                                          element.productDealerPrice,
                                      productPurchasePrice:
                                          element.productPurchasePrice,
                                      productSalePrice:
                                          element.productSalePrice,
                                      productWholeSalePrice:
                                          element.productWholeSalePrice,
                                      quantities: element.quantities,
                                      vatType: element.vatType,
                                      vatAmount: productTaxAmount,
                                      gstRateSelect: element.gstRateSelect,
                                    );

                                    print(
                                        'Created CartProductModelPurchase: ${cartProduct.toJson()}');

                                    return cartProduct;
                                  }).toList();

                                  // Hold the purchase using the new API endpoint
                                  PurchaseRepo repo = PurchaseRepo();
                                  PurchaseTransaction? purchaseData =
                                      await repo.holdPurchase(
                                    ref: ref,
                                    context: context,
                                    partyId: selectedSupplier?.id ?? 0,
                                    purchaseDate: selectedDate.toString(),
                                    discountAmount: providerData.discountAmount,
                                    discountPercent:
                                        providerData.discountPercent,
                                    vatId: providerData.selectedVat?.id,
                                    totalAmount:
                                        providerData.totalPayableAmount,
                                    vatAmount: providerData.vatAmount,
                                    vatPercent:
                                        providerData.selectedVat?.rate ?? 0,
                                    dueAmount: providerData.dueAmount,
                                    changeAmount: providerData.changeAmount,
                                    isPaid: providerData.dueAmount <= 0,
                                    paymentType: paymentType?.toString() ?? '',
                                    products: selectedProductList,
                                    discountType: discountType.toLowerCase(),
                                    shippingCharge:
                                        providerData.finalShippingCharge,
                                    serviceCharge:
                                        providerData.finalServiceCharge,
                                    taxType: providerData.selectedTaxType,
                                    isSplitPayment: isSplitPayment,
                                    splitPaymentAmounts: splitPaymentAmounts,
                                  );

                                  if (purchaseData != null) {
                                    // Clear cart and form after successful hold
                                    if (mounted) {
                                      providerData.clearCart();
                                      recevedAmountController.clear();
                                      phoneController.clear();
                                      setState(() {
                                        selectedSupplier = null;
                                        paymentType = null;
                                        discountType = 'Flat';
                                      });

                                      // Success message is already shown by holdPurchase method
                                      // No navigation needed - user stays on current screen
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Failed to hold purchase: $e')));
                                  }
                                } finally {
                                  if (mounted) {
                                    EasyLoading.dismiss();
                                    setState(() {
                                      isProcessing =
                                          false; // Re-enable button after processing
                                    });
                                  }
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
                              )),
                        ),
                        const SizedBox(width: 8),
                        // ---- Inserted Save button ----
                        Expanded(
                          child: ElevatedButton(
                            style: OutlinedButton.styleFrom(
                              maximumSize: const Size(double.infinity, 48),
                              minimumSize: const Size(double.infinity, 48),
                              disabledBackgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.15),
                            ),
                            onPressed: () async {
                              if (providerData.cartItemList.isEmpty) {
                                EasyLoading.showError(
                                    lang.S.of(context).addProductFirst);
                                return;
                              }
                              // Prevent walk-in suppliers from making credit purchases (due amount > 0)
                              if (selectedSupplier == null &&
                                  providerData.dueAmount > 0) {
                                EasyLoading.showError(
                                    'Walk-in suppliers cannot make credit purchases. Please select a supplier or pay the full amount.');
                                return;
                              }
                              if (paymentType == null) {
                                EasyLoading.showError(
                                    'Please select a payment type');
                                return;
                              }

                              // Prevent multiple clicks
                              if (isProcessing) return;
                              setState(() => isProcessing = true);

                              try {
                                // Ensure latest paid amount is calculated
                                if (recevedAmountController.text.isNotEmpty) {
                                  providerData.calculatePrice(
                                    receivedAmount:
                                        recevedAmountController.text,
                                    stopRebuild: true,
                                  );
                                }

                                EasyLoading.show(
                                    status: lang.S.of(context).loading,
                                    dismissOnTap: false);

                                if (widget.transitionModel == null) {
                                  PurchaseRepo repo = PurchaseRepo();
                                  PurchaseTransaction? purchaseData =
                                      await repo.createPurchase(
                                    ref: ref,
                                    context: context,
                                    vatId: providerData.selectedVat?.id,
                                    totalAmount:
                                        providerData.totalPayableAmount,
                                    purchaseDate: selectedDate.toString(),
                                    products: providerData.cartItemList,
                                    vatAmount: providerData.vatAmount,
                                    vatPercent:
                                        providerData.selectedVat?.rate ?? 0,
                                    paymentType: paymentType?.toString() ?? '',
                                    partyId: selectedSupplier?.id ?? 0,
                                    isPaid: providerData.dueAmount <= 0
                                        ? true
                                        : false,
                                    dueAmount: providerData.dueAmount <= 0
                                        ? 0
                                        : providerData.dueAmount,
                                    discountAmount: providerData.discountAmount,
                                    changeAmount: providerData.changeAmount,
                                    shippingCharge:
                                        providerData.finalShippingCharge,
                                    serviceCharge:
                                        providerData.finalServiceCharge,
                                    discountPercent:
                                        providerData.discountPercent,
                                    discountType: discountType.toLowerCase(),
                                    taxType: providerData.selectedTaxType,
                                    isSplitPayment: isSplitPayment,
                                    splitPaymentAmounts: splitPaymentAmounts,
                                  );

                                  if (purchaseData != null) {
                                    // Clear local provider data (avoid notify issues)
                                    providerData.cartItemList.clear();
                                    providerData.totalAmount = 0;
                                    providerData.discountAmount = 0;
                                    providerData.totalPayableAmount = 0;
                                    providerData.dueAmount = 0;

                                    await PaymentTotalsHelper
                                        .updatePaymentTotals(
                                      paymentTypeId: purchaseData.paymentTypeId,
                                      paidAmount:
                                          purchaseData.paidAmount?.toDouble(),
                                      isSplitPayment:
                                          purchaseData.isSplitPayment,
                                      splitPaymentAmounts:
                                          purchaseData.isSplitPayment == true
                                              ? splitPaymentAmounts
                                              : null,
                                    );

                                    PurchaseInvoiceDetails(
                                      businessInfo: personalData.value!,
                                      transitionModel: purchaseData,
                                      isFromPurchase: true,
                                    ).launch(context);
                                  }
                                } else {
                                  PurchaseRepo repo = PurchaseRepo();
                                  PurchaseTransaction? purchaseData =
                                      await repo.updatePurchase(
                                    id: widget.transitionModel!.id!,
                                    ref: ref,
                                    context: context,
                                    vatId: providerData.selectedVat?.id,
                                    totalAmount:
                                        providerData.totalPayableAmount,
                                    purchaseDate: selectedDate.toString(),
                                    products: providerData.cartItemList,
                                    vatAmount: providerData.vatAmount,
                                    vatPercent:
                                        providerData.selectedVat?.rate ?? 0,
                                    paymentType: paymentType?.toString() ?? '',
                                    changeAmount: providerData.changeAmount,
                                    partyId:
                                        widget.transitionModel?.party?.id ?? 0,
                                    isPaid: providerData.dueAmount <= 0
                                        ? true
                                        : false,
                                    dueAmount: providerData.dueAmount <= 0
                                        ? 0
                                        : providerData.dueAmount,
                                    discountAmount: providerData.discountAmount,
                                    shippingCharge:
                                        providerData.finalShippingCharge,
                                    serviceCharge:
                                        providerData.finalServiceCharge,
                                    discountType: discountType.toLowerCase(),
                                    taxType: providerData.selectedTaxType,
                                    isSplitPayment: isSplitPayment,
                                    splitPaymentAmounts: splitPaymentAmounts,
                                  );

                                  if (purchaseData != null) {
                                    providerData.cartItemList.clear();
                                    providerData.totalAmount = 0;
                                    providerData.discountAmount = 0;
                                    providerData.totalPayableAmount = 0;
                                    providerData.dueAmount = 0;

                                    const PurchaseListScreen().launch(context);
                                  }
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())));
                              } finally {
                                EasyLoading.dismiss();
                                if (mounted)
                                  setState(() => isProcessing = false);
                              }
                            },
                            child: Text(
                              lang.S.of(context).save,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                            ),
                          ),
                        ),
                        // ---- end Save button ----
                      ],
                    ),
                  )
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
}
