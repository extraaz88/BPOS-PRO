import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Provider/add_to_cart.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/Screens/Customers/Model/parties_model.dart';
import 'package:mobile_pos/Screens/Sales/Repo/sales_repo.dart';
import 'package:mobile_pos/Screens/payment_type/model/payment_type_model.dart';
import 'package:mobile_pos/Screens/payment_type/provider/payment_type_provider.dart';
import 'package:mobile_pos/Screens/vat_&_tax/model/vat_model.dart';
import 'package:mobile_pos/currency.dart';
import 'package:mobile_pos/model/add_to_cart_model.dart';
import 'package:mobile_pos/model/sale_transaction_model.dart';
import 'package:mobile_pos/utils/payment_totals_helper.dart';

class _SummaryLabels {
  const _SummaryLabels();

  final String billSummary = 'Bill Summary';
  final String edit = 'Edit';
  final String customerDetails = 'Customer Details';
  final String customer = 'Customer';
  final String walkInCustomer = 'Walk-in Customer';
  final String phoneNumber = 'Phone Number';
  final String date = 'Date';
  final String orderItems = 'Order Items';
  final String paymentSummary = 'Payment Summary';
  final String subTotal = 'Subtotal';
  final String discount = 'Discount';
  final String tax = 'GST Amount';
  final String vat = 'Additional VAT';
  final String shippingCharge = 'Shipping Charge';
  final String serviceCharge = 'Service Charge';
  final String roundingAmount = 'Rounding Adjustment';
  final String totalAmount = 'Total Payable';
  final String paidAmount = 'Paid Amount';
  final String change = 'Change';
  final String dueAmount = 'Due Amount';
  final String paymentType = 'Payment Mode';
  final String splitPaymentDetails = 'Split Payment Details';
  final String note = 'Note';
  final String addNoteOptional = 'Add note (optional)';
  final String attachment = 'Attachment';
  final String saveAndGenerateInvoice = 'Save & Generate Invoice';
  final String selectPaymentType = 'Select payment Mode';
  final String loading = 'Loading...';
  final String saving = 'Saving sale...';
  final String saleSaveFailed = 'Failed to save sale';
  final String saleSaveFailedDetailed = 'Failed to save sale';
  final String quantity = 'Quantity';
}

const _labels = _SummaryLabels();

class SaleBillSummaryArguments {
  const SaleBillSummaryArguments({
    required this.customer,
    required this.customerPhone,
    required this.saleDate,
    required this.cartItems,
    required this.cartSaleProducts,
    required this.totalAmount,
    required this.discountAmount,
    required this.discountPercent,
    required this.totalPayableAmount,
    required this.dueAmount,
    required this.changeAmount,
    required this.vatAmount,
    required this.vatModel,
    required this.isFullPaid,
    required this.discountType,
    required this.note,
    required this.shippingCharge,
    required this.serviceCharge,
    required this.taxType,
    required this.isSplitPayment,
    required this.splitPaymentAmounts,
    required this.paymentTypeId,
    required this.roundedOption,
    required this.roundingAmount,
    required this.actualTotalAmount,
    required this.receiveAmount,
    required this.roundOffEnabled,
    this.imageFile,
    this.transitionModel,
  });

  final Party? customer;
  final String? customerPhone;
  final DateTime saleDate;
  final List<AddToCartModel> cartItems;
  final List<CartSaleProducts> cartSaleProducts;
  final num totalAmount;
  final num discountAmount;
  final num discountPercent;
  final num totalPayableAmount;
  final num dueAmount;
  final num changeAmount;
  final num vatAmount;
  final VatModel? vatModel;
  final bool isFullPaid;
  final String discountType;
  final String note;
  final num shippingCharge;
  final num serviceCharge;
  final String? taxType;
  final bool isSplitPayment;
  final Map<int, double> splitPaymentAmounts;
  final int? paymentTypeId;
  final String roundedOption;
  final num roundingAmount;
  final num actualTotalAmount;
  final num receiveAmount;
  final bool roundOffEnabled;
  final File? imageFile;
  final SalesTransactionModel? transitionModel;
}

class SaleSummaryResult {
  const SaleSummaryResult({
    this.editRequested = false,
    this.saleTransaction,
  });

  final bool editRequested;
  final SalesTransactionModel? saleTransaction;
}

class SaleBillSummaryScreen extends ConsumerStatefulWidget {
  const SaleBillSummaryScreen({
    super.key,
    required this.arguments,
  });

  final SaleBillSummaryArguments arguments;

  @override
  ConsumerState<SaleBillSummaryScreen> createState() =>
      _SaleBillSummaryScreenState();
}

class _SaleBillSummaryScreenState
    extends ConsumerState<SaleBillSummaryScreen> {
  late final TextEditingController _noteController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.arguments.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = widget.arguments;
    final paymentTypesAsync = ref.watch(paymentTypeProvider);
    final personalData = ref.watch(businessInfoProvider);

    final paymentTypes = paymentTypesAsync.asData?.value ?? <PaymentTypeModel>[];
    String paymentTypeLabel = _labels.selectPaymentType;
    if (paymentTypesAsync.isLoading) {
      paymentTypeLabel = _labels.loading;
    } else if (args.paymentTypeId != null) {
      for (final type in paymentTypes) {
        if (type.id == args.paymentTypeId) {
          paymentTypeLabel = type.name ?? _labels.selectPaymentType;
          break;
        }
      }
    }

    final subtotal = args.totalAmount;
    final totalTaxAmount = args.cartSaleProducts.fold<double>(
      0,
      (previousValue, element) =>
          previousValue + (element.taxAmount ?? 0.0),
    );
    final vatAmount = args.vatAmount;
    final num baseTotalAmount = args.actualTotalAmount;
    final bool shouldDisplayRoundOff =
        args.roundOffEnabled && args.roundedOption != 'none';
    final num roundedTotalAmount =
        shouldDisplayRoundOff ? args.totalPayableAmount : baseTotalAmount;
    final num roundingDifference = shouldDisplayRoundOff
        ? args.totalPayableAmount - baseTotalAmount
        : 0;
    final bool hasReceivedAmount = args.receiveAmount > 0;
    final num computedDueAmount = hasReceivedAmount
        ? (args.receiveAmount >= roundedTotalAmount
            ? 0
            : roundedTotalAmount - args.receiveAmount)
        : args.dueAmount;
    final num computedChangeAmount = hasReceivedAmount
        ? (args.receiveAmount > roundedTotalAmount
            ? args.receiveAmount - roundedTotalAmount
            : 0)
        : args.changeAmount;
    final num paidAmount = roundedTotalAmount - computedDueAmount;

    return personalData.when(
      data: (_) => Scaffold(
        appBar: AppBar(
          title: Text(_labels.billSummary),
          actions: [
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      Navigator.pop(
                        context,
                        const SaleSummaryResult(editRequested: true),
                      );
                    },
              child: Text(
                _labels.edit,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailSectionCard(
                title: _labels.customerDetails,
                children: [
                  _InfoRow(
                    label: _labels.customer,
                    value: args.customer?.name ?? _labels.walkInCustomer,
                  ),
                  if ((args.customerPhone?.trim().isNotEmpty ?? false) ||
                      (args.customer?.phone?.trim().isNotEmpty ?? false))
                    _InfoRow(
                      label: _labels.phoneNumber,
                      value: args.customerPhone?.trim().isNotEmpty == true
                          ? args.customerPhone!.trim()
                          : (args.customer?.phone ?? '-'),
                    ),
                  _InfoRow(
                    label: _labels.date,
                    value: args.saleDate.toString().substring(0, 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailSectionCard(
                title: _labels.orderItems,
                children: args.cartItems
                    .map(
                      (item) => _ItemTile(
                        item: item,
                        taxType: args.taxType ?? 'GST',
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _DetailSectionCard(
                title: _labels.paymentSummary,
                children: [
                  _InfoRow(
                    label: _labels.subTotal,
                    value: _formatCurrency(subtotal),
                  ),
                  _InfoRow(
                    label: _labels.discount,
                    value:
                        '${_formatCurrency(args.discountAmount)} (${args.discountType})',
                  ),
                  _InfoRow(
                    label: _labels.tax,
                    value: _formatCurrency(totalTaxAmount),
                  ),
                  if (vatAmount > 0)
                    _InfoRow(
                      label: _labels.vat,
                      value: _formatCurrency(vatAmount),
                    ),
                  if (args.shippingCharge != 0)
                    _InfoRow(
                      label: _labels.shippingCharge,
                      value: _formatCurrency(args.shippingCharge),
                    ),
                  if (args.serviceCharge != 0)
                    _InfoRow(
                      label: _labels.serviceCharge,
                      value: _formatCurrency(args.serviceCharge),
                    ),
                  if (shouldDisplayRoundOff && roundingDifference != 0)
                    _InfoRow(
                      label: _labels.roundingAmount,
                      value: _formatCurrency(roundingDifference),
                    ),
                  _InfoRow(
                    label: _labels.totalAmount,
                    value: shouldDisplayRoundOff
                        ? _formatWholeCurrency(roundedTotalAmount)
                        : _formatCurrency(roundedTotalAmount),
                    valueStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Divider(),
                  _InfoRow(
                    label: _labels.paidAmount,
                    value: _formatCurrency(paidAmount),
                  ),
                  if (computedChangeAmount != 0)
                    _InfoRow(
                      label: _labels.change,
                      value: _formatCurrency(computedChangeAmount),
                    ),
                  _InfoRow(
                    label: _labels.dueAmount,
                    value: _formatCurrency(computedDueAmount),
                    valueStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: computedDueAmount > 0
                          ? Colors.redAccent
                          : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: _labels.paymentType,
                    value: paymentTypeLabel,
                  ),
                  if (args.isSplitPayment &&
                      args.splitPaymentAmounts.isNotEmpty)
                    _buildSplitPaymentSection(
                      context,
                      paymentTypesAsync,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailSectionCard(
                title: _labels.note,
                children: [
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: _labels.addNoteOptional,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.arguments.imageFile != null) ...[
                const SizedBox(height: 16),
                _DetailSectionCard(
                  title: _labels.attachment,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        widget.arguments.imageFile!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => _handleConfirm(context),
              child: _isSaving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Text(_labels.saveAndGenerateInvoice),
            ),
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text(error.toString())),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildSplitPaymentSection(
    BuildContext context,
    AsyncValue<List<PaymentTypeModel>> paymentTypesAsync,
  ) {
    final theme = Theme.of(context);
    final paymentTypes = paymentTypesAsync.value ?? [];
    final rows = <Widget>[];

    widget.arguments.splitPaymentAmounts.forEach((key, value) {
      String label = '${_labels.paymentType} #$key';
      for (final type in paymentTypes) {
        if (type.id == key) {
          label = type.name ?? label;
          break;
        }
      }
      rows.add(
        _InfoRow(
          label: label,
          value: _formatCurrency(value),
          valueStyle: theme.textTheme.bodyMedium,
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          _labels.splitPaymentDetails,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }

  Future<void> _handleConfirm(BuildContext context) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final args = widget.arguments;
    final noteText = _noteController.text.trim();
    final repo = SaleRepo();

    try {
      EasyLoading.show(status: _labels.saving);

      SalesTransactionModel? saleData;
      if (args.transitionModel == null) {
        saleData = await repo.createSale(
          ref: ref,
          context: context,
          partyId:
              (args.customer?.id == null || args.customer?.id == -1)
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
          paymentType: args.paymentTypeId != null
              ? args.paymentTypeId.toString()
              : '',
          roundedOption: args.roundedOption,
          products: args.cartSaleProducts,
          discountType: args.discountType.toLowerCase(),
          shippingCharge: args.shippingCharge,
          serviceCharge: args.serviceCharge,
          taxType: args.taxType,
          note: noteText,
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
          paymentType: args.paymentTypeId != null
              ? args.paymentTypeId.toString()
              : '',
          roundedOption: args.roundedOption,
          products: args.cartSaleProducts,
          discountType: args.discountType.toLowerCase(),
          shippingCharge: args.shippingCharge,
          serviceCharge: args.serviceCharge,
          taxType: args.taxType,
          note: noteText,
          image: args.imageFile,
          isSplitPayment: args.isSplitPayment,
          splitPaymentAmounts: args.splitPaymentAmounts.isEmpty
              ? null
              : args.splitPaymentAmounts,
        );
      }

      if (saleData == null) {
        EasyLoading.dismiss();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_labels.saleSaveFailed),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      await PaymentTotalsHelper.updatePaymentTotals(
        paymentTypeId: saleData.paymentTypeId,
        paidAmount: saleData.paidAmount?.toDouble(),
        isSplitPayment: saleData.isSplitPayment,
        splitPaymentAmounts:
            saleData.isSplitPayment == true ? args.splitPaymentAmounts : null,
      );

      ref.read(cartNotifier.notifier).clearCart();

      EasyLoading.dismiss();
      if (!mounted) return;
      Navigator.pop(
        context,
        SaleSummaryResult(
          saleTransaction: saleData,
        ),
      );
    } catch (e) {
      EasyLoading.dismiss();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_labels.saleSaveFailedDetailed}: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ..._withSpacing(children),
          ],
        ),
      ),
    );
  }
}

List<Widget> _withSpacing(List<Widget> children) {
  if (children.isEmpty) return const <Widget>[];
  final List<Widget> result = [];
  for (var i = 0; i < children.length; i++) {
    result.add(children[i]);
    if (i != children.length - 1) {
      result.add(const SizedBox(height: 8));
    }
  }
  return result;
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.taxType,
  });

  final AddToCartModel item;
  final String taxType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitPrice = num.tryParse(item.unitPrice.toString()) ?? 0;
    final total = unitPrice * item.quantity;
    final gstInfo = item.getGstDisplayText(taxType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.productName ?? '-',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              _formatCurrency(total),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${_labels.quantity}: ${item.quantity} × ${_formatCurrency(unitPrice)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
        if (gstInfo.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              gstInfo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.right,
          style: valueStyle ??
              theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

String _formatCurrency(num value) {
  return '$currency ${value.toStringAsFixed(2)}';
}

String _formatWholeCurrency(num value) {
  return '$currency ${value.toStringAsFixed(0)}';
}

