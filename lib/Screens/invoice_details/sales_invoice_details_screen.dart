import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Const/api_config.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../constant.dart' as mainConstant;
import '../../currency.dart';
import '../../invoice_constant.dart';
import '../../model/business_info_model.dart' as binfo;
import '../../model/sale_transaction_model.dart';
import '../../thermal priting invoices/model/print_transaction_model.dart';
import '../../thermal priting invoices/provider/print_thermal_invoice_provider.dart';
import '../../PDF Invoice/sales_invoice_pdf.dart';
import '../Sales/add_sales.dart';

class SalesInvoiceDetails extends StatefulWidget {
  const SalesInvoiceDetails(
      {super.key,
      required this.saleTransaction,
      required this.businessInfo,
      this.fromSale});

  final SalesTransactionModel saleTransaction;
  final binfo.BusinessInformation businessInfo;
  final bool? fromSale;

  @override
  State<SalesInvoiceDetails> createState() => _SalesInvoiceDetailsState();
}

class _SalesInvoiceDetailsState extends State<SalesInvoiceDetails> {
  bool _invoiceEditEnabled = false;
  bool _roundOffEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  String productName({required num detailsId}) {
    return widget.saleTransaction.salesDetails!
            .where((element) => element.id == detailsId)
            .first
            .product
            ?.productName ??
        '';
  }

  num productPrice({required num detailsId}) {
    return widget.saleTransaction.salesDetails!
            .where((element) => element.id == detailsId)
            .first
            .price ??
        0;
  }

  num getTotalReturndAmount() {
    num totalReturn = 0;
    if (widget.saleTransaction.salesReturns?.isNotEmpty ?? false) {
      for (var returns in widget.saleTransaction.salesReturns!) {
        if (returns.salesReturnDetails?.isNotEmpty ?? false) {
          for (var details in returns.salesReturnDetails!) {
            totalReturn += details.returnAmount ?? 0;
          }
        }
      }
    }
    return totalReturn;
  }

  int serialNumber = 1;

  bool get _canEditInvoice =>
      _invoiceEditEnabled &&
      !(widget.saleTransaction.salesReturns?.isNotEmpty ?? false);

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _invoiceEditEnabled =
          prefs.getBool(mainConstant.kSalesInvoiceEditToggleKey) ?? false;
      _roundOffEnabled =
          prefs.getBool(mainConstant.kSalesRoundOffToggleKey) ?? false;
    });
  }

  Future<void> _handleEditInvoice() async {
    final result = await AddSalesScreen(
      transitionModel: widget.saleTransaction,
      customerModel: null,
    ).launch(context);

    if (!mounted) return;

    if (result is SalesTransactionModel) {
      setState(() {
        _applyUpdatedSale(result);
      });
      await _loadSettings();
    }
  }

  void _applyUpdatedSale(SalesTransactionModel updated) {
    final current = widget.saleTransaction;
    current.discountAmount = updated.discountAmount;
    current.discountPercent = updated.discountPercent;
    current.shippingCharge = updated.shippingCharge;
    current.serviceCharge = updated.serviceCharge;
    current.dueAmount = updated.dueAmount;
    current.isPaid = updated.isPaid;
    current.vatAmount = updated.vatAmount;
    current.vatPercent = updated.vatPercent;
    current.vatId = updated.vatId;
    current.paidAmount = updated.paidAmount;
    current.changeAmount = updated.changeAmount;
    current.totalAmount = updated.totalAmount;
    current.paymentTypeId = updated.paymentTypeId;
    current.paymentType = updated.paymentType;
    current.discountType = updated.discountType;
    current.invoiceNumber = updated.invoiceNumber;
    current.saleDate = updated.saleDate;
    current.roundingOption = updated.roundingOption;
    current.roundingAmount = updated.roundingAmount;
    current.actualTotalAmount = updated.actualTotalAmount;
    current.salesDetails = updated.salesDetails;
    current.salesReturns = updated.salesReturns;
    current.party = updated.party;
    current.meta = updated.meta;
    current.image = updated.image;
    current.user = updated.user;
    current.vat = updated.vat;
    current.isSplitPayment = updated.isSplitPayment;
    current.splitCashAmount = updated.splitCashAmount;
    current.splitOnlineAmount = updated.splitOnlineAmount;
  }

  num getReturndDiscountAmount() {
    num totalReturnDiscount = 0;
    if (widget.saleTransaction.salesReturns?.isNotEmpty ?? false) {
      for (var returns in widget.saleTransaction.salesReturns!) {
        if (returns.salesReturnDetails?.isNotEmpty ?? false) {
          for (var details in returns.salesReturnDetails!) {
            totalReturnDiscount +=
                ((productPrice(detailsId: details.saleDetailId ?? 0) *
                        (details.returnQty ?? 0)) -
                    ((details.returnAmount ?? 0)));
          }
        }
      }
    }
    return totalReturnDiscount;
  }

  num getTotalForOldInvoice() {
    num total = 0;
    for (var element in widget.saleTransaction.salesDetails!) {
      total +=
          (element.price ?? 0) * getProductQuantity(detailsId: element.id ?? 0);
    }

    return total;
  }

  num getProductQuantity({required num detailsId}) {
    num totalQuantity = widget.saleTransaction.salesDetails
            ?.where((element) => element.id == detailsId)
            .first
            .quantities ??
        0;
    if (widget.saleTransaction.salesReturns?.isNotEmpty ?? false) {
      for (var returns in widget.saleTransaction.salesReturns!) {
        if (returns.salesReturnDetails?.isNotEmpty ?? false) {
          for (var details in returns.salesReturnDetails!) {
            if (details.saleDetailId == detailsId) {
              totalQuantity += details.returnQty ?? 0;
            }
          }
        }
      }
    }

    return totalQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final _lang = lang.S.of(context);
    final _theme = Theme.of(context);
    final sale = widget.saleTransaction;
    final num actualTotalAmount =
        sale.actualTotalAmount ?? getTotalForOldInvoice();
    final num storedRoundedAmount = sale.totalAmount ?? actualTotalAmount;
    final num rawRoundingAmount = sale.roundingAmount ?? 0;
    final bool shouldDisplayRoundOff =
        _roundOffEnabled && rawRoundingAmount != 0;
    final num roundingDifference =
        shouldDisplayRoundOff ? rawRoundingAmount : 0;
    final num totalReturnAmount = getTotalReturndAmount();
    final num totalAmountWithReturns =
        totalReturnAmount + storedRoundedAmount;
    return Consumer(builder: (context, ref, __) {
      final printerData = ref.watch(thermalPrinterProvider);
      final businessSettingData = ref.watch(businessSettingProvider);
      return SafeArea(
        child: GlobalPopup(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: SingleChildScrollView(
                    child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //header
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: businessSettingData.when(
                            data: (business) {
                              final isSvg =
                                  business.pictureUrl?.endsWith('.svg');
                              final imageUrl =
                                  '${APIConfig.domain}${business.pictureUrl}';
                              const placeholder = AssetImage(mainConstant.logo);
                              return business.pictureUrl.isEmptyOrNull
                                  ? _buildInvoiceLogo(image: placeholder)
                                  : (isSvg ?? false)
                                      ? SvgPicture.network(imageUrl,
                                          height: 54.12,
                                          width: 52,
                                          fit: BoxFit.cover)
                                      : _buildInvoiceLogo(
                                          image: NetworkImage(imageUrl),
                                        );
                            },
                            error: (e, stack) => Text(e.toString()),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          title: Text(
                            '${widget.businessInfo.companyName}',
                            style: _theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text.rich(
                            TextSpan(
                              text: '${lang.S.of(context).mobiles} : ',
                              children: [
                                TextSpan(
                                  text: widget.businessInfo.phoneNumber
                                      .toString(),
                                )
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                alignment: Alignment.center,
                                width: 110,
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(25),
                                    bottomLeft: Radius.circular(25),
                                  ),
                                ),
                                child: Text(
                                  lang.S.of(context).invoice,
                                  style: _theme.textTheme.titleLarge?.copyWith(
                                    color: white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_canEditInvoice)
                                IconButton(
                                  onPressed: _handleEditInvoice,
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.black54,
                                  ),
                                  tooltip: 'Edit invoice',
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 33.88),
                        //header data
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  //bill to
                                  Text.rich(
                                    TextSpan(
                                      text: '${lang.S.of(context).billTO} : ',
                                      children: [
                                        TextSpan(
                                          text: widget.saleTransaction.party
                                                  ?.name ??
                                              '',
                                        )
                                      ],
                                    ),
                                  ),
                                  //header mobile data
                                  Text.rich(
                                    TextSpan(
                                      text: '${lang.S.of(context).mobiles} : ',
                                      children: [
                                        TextSpan(
                                          text: widget.saleTransaction.party
                                                  ?.phone ??
                                              (widget.saleTransaction.meta
                                                      ?.customerPhone ??
                                                  'Guest'),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      text: '${lang.S.of(context).salesBy} ',
                                      children: [
                                        TextSpan(
                                          text: widget.saleTransaction.user
                                                      ?.role ==
                                                  "shop-owner"
                                              ? 'Admin'
                                              : widget.saleTransaction.user
                                                      ?.name ??
                                                  '',
                                        )
                                      ],
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                  Text.rich(
                                    TextSpan(
                                      text: '${_lang.inv} : ',
                                      children: [
                                        TextSpan(
                                          text:
                                              '#${widget.saleTransaction.invoiceNumber}',
                                        )
                                      ],
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                  Text.rich(
                                    TextSpan(
                                      text: '${lang.S.of(context).date} : ',
                                      children: [
                                        TextSpan(
                                          text: DateFormat.yMMMd().format(
                                              DateTime.parse(widget
                                                      .saleTransaction
                                                      .saleDate ??
                                                  DateTime.now().toString())),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                  Visibility(
                                    visible:
                                        widget.businessInfo.vatNumber != null,
                                    child: Text.rich(
                                      TextSpan(
                                        text:
                                            '${widget.businessInfo.vatName ?? 'VAT Number'} : ',
                                        children: [
                                          TextSpan(
                                            text:
                                                widget.businessInfo.vatNumber ??
                                                    '',
                                          )
                                        ],
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Table(
                            defaultColumnWidth: const FixedColumnWidth(
                                100), // Set a default fixed width for all columns
                            border: const TableBorder(
                              verticalInside: BorderSide(
                                color: Color(0xffD9D9D9),
                              ),
                              left: BorderSide(
                                color: Color(0xffD9D9D9),
                              ),
                              right: BorderSide(
                                color: Color(0xffD9D9D9),
                              ),
                              bottom: BorderSide(
                                color: Color(0xffD9D9D9),
                              ),
                            ),
                            children: [
                              // Table header row
                              TableRow(
                                children: [
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xffF18A23),
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      _lang.sl,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Container(
                                    color: const Color(0xffF18A23),
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      _lang.item,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  Container(
                                    color: const Color(0xff000000),
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      lang.S.of(context).quantity,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Container(
                                    color: const Color(0xff000000),
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      _lang.unitPrice,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Container(
                                    color: const Color(0xff000000),
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      lang.S.of(context).totalPrice,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              // Data rows from ListView.builder
                              ...widget.saleTransaction.salesDetails!
                                  .asMap()
                                  .entries
                                  .map(
                                (entry) {
                                  final i = entry.key; // This is the index
                                  final saleDetail = entry
                                      .value; // This is the saleDetail object

                                  final quantity = getProductQuantity(
                                      detailsId: saleDetail.id ?? 0);
                                  final totalPrice =
                                      (saleDetail.price ?? 0) * quantity;
                                  return TableRow(
                                    decoration: i % 2 == 0
                                        ? const BoxDecoration(
                                            color: Colors.white,
                                          ) // Odd row color
                                        : BoxDecoration(
                                            color: const Color(0xffF18A23)
                                                .withValues(alpha: 0.07),
                                          ),
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          (widget.saleTransaction.salesDetails!
                                                      .indexOf(saleDetail) +
                                                  1)
                                              .toString(),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          saleDetail.product?.productName ?? '',
                                          maxLines: 2,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          mainConstant
                                              .formatPointNumber(quantity),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          '$currency${mainConstant.formatPointNumber(saleDetail.price ?? 0)}',
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          '$currency${mainConstant.formatPointNumber(totalPrice)}',
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        //sub total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            //paid by
                            Text(
                              "${_lang.paidVia}: ${widget.saleTransaction.paymentType?.name ?? 'N/A'}",
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text.rich(
                                TextSpan(
                                  text: '${lang.S.of(context).subTotal} : ',
                                  children: [
                                    TextSpan(
                                      text:
                                          '$currency${mainConstant.formatPointNumber(getTotalForOldInvoice())}',
                                    ),
                                  ],
                                ),
                                style: _theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),

                        ///__________discount______________________
                        const SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text.rich(
                            TextSpan(
                              text: '${lang.S.of(context).discount} : ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                              children: [
                                TextSpan(
                                  text:
                                      '$currency${mainConstant.formatPointNumber((widget.saleTransaction.discountAmount ?? 0) + getReturndDiscountAmount())}',
                                ),
                              ],
                            ),
                            style: _theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),

                        ///__________service_charge______________
                        const SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text.rich(
                            TextSpan(
                              text: 'Service charge : ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                              children: [
                                TextSpan(
                                  text:
                                      '$currency${mainConstant.formatPointNumber(widget.saleTransaction.serviceCharge ?? 0)}',
                                ),
                              ],
                            ),
                            style: _theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),

                        ///-------vat-------------------
                        const SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text.rich(
                            TextSpan(
                              text:
                                  '${widget.saleTransaction.vat?.name ?? lang.S.of(context).vat} : ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                              children: [
                                TextSpan(
                                  text:
                                      '$currency${mainConstant.formatPointNumber(widget.saleTransaction.vatAmount ?? 0)}',
                                ),
                              ],
                            ),
                            style: _theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 5),

                        ///__________shipping_charge______________
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text.rich(
                            TextSpan(
                              text: 'Shipping charge : ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                              children: [
                                TextSpan(
                                  text:
                                      '$currency${mainConstant.formatPointNumber(widget.saleTransaction.shippingCharge ?? 0)}',
                                ),
                              ],
                            ),
                            style: _theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 5),

                        ///______Rounded_amount__________________________________
                        Visibility(
                          visible: shouldDisplayRoundOff,
                          child: Column(
                            children: [
                              ///------------Total Amount----------------
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Total :',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                    children: [
                                      TextSpan(
                                        text:
                                            '$currency${mainConstant.formatPointNumber(actualTotalAmount)}',
                                      ),
                                    ],
                                  ),
                                  style: _theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(height: 5),

                              ///------------rounding amount----------------
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Rounding : ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                    children: [
                                      TextSpan(
                                        text:
                                            '$currency${!(roundingDifference.isNegative) ? '+' : ''}${mainConstant.formatPointNumber(roundingDifference)}',
                                      ),
                                    ],
                                  ),
                                  style: _theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(height: 5),
                            ],
                          ),
                        ),

                        ///------------total amount----------------
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text.rich(
                            TextSpan(
                              text: '${lang.S.of(context).totalAmount} : ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                              children: [
                                TextSpan(
                                  text:
                                      '$currency${mainConstant.formatPointNumber(totalAmountWithReturns)}',
                                ),
                              ],
                            ),
                            style: _theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 20),

                        ///______________Returned_Product_______________________________
                        if (widget.saleTransaction.salesReturns!.isNotEmpty)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Table(
                              defaultColumnWidth: const FixedColumnWidth(120),
                              border: const TableBorder(
                                verticalInside:
                                    BorderSide(color: Color(0xffD9D9D9)),
                                left: BorderSide(color: Color(0xffD9D9D9)),
                                right: BorderSide(color: Color(0xffD9D9D9)),
                                bottom: BorderSide(color: Color(0xffD9D9D9)),
                              ),
                              children: [
                                // Table header row
                                TableRow(
                                  children: [
                                    Container(
                                      decoration: const BoxDecoration(
                                          color: Color(0xffF18A23)),
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        _lang.sl,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Container(
                                      decoration: const BoxDecoration(
                                          color: Color(0xffF18A23)),
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        _lang.returnedDate,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Container(
                                      decoration: const BoxDecoration(
                                          color: Color(0xff000000)),
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        _lang.returnedItem,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                    Container(
                                      decoration: const BoxDecoration(
                                          color: Color(0xff000000)),
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        _lang.quantity,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Container(
                                      decoration: const BoxDecoration(
                                          color: Color(0xff000000)),
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        _lang.totalPrice,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                                // Data rows
                                for (var i = 0;
                                    i <
                                        (widget.saleTransaction.salesReturns
                                                ?.length ??
                                            0);
                                    i++)
                                  for (var detailIndex = 0;
                                      detailIndex <
                                          (widget
                                                  .saleTransaction
                                                  .salesReturns?[i]
                                                  .salesReturnDetails
                                                  ?.length ??
                                              0);
                                      detailIndex++)
                                    TableRow(
                                      decoration: serialNumber.isOdd
                                          ? const BoxDecoration(
                                              color: Colors.white,
                                            ) // Odd row color
                                          : BoxDecoration(
                                              color: const Color(0xffF18A23)
                                                  .withValues(alpha: 0.07),
                                            ),
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            (serialNumber++).toString(),
                                            style: _theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: kGreyTextColor,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            DateFormat.yMMMd().format(
                                                DateTime.parse(widget
                                                        .saleTransaction
                                                        .salesReturns?[i]
                                                        .returnDate ??
                                                    DateTime.now().toString())),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            productName(
                                                detailsId: widget
                                                        .saleTransaction
                                                        .salesReturns?[i]
                                                        .salesReturnDetails?[
                                                            detailIndex]
                                                        .saleDetailId ??
                                                    0),
                                            maxLines: 2,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            mainConstant.formatPointNumber(
                                                widget
                                                        .saleTransaction
                                                        .salesReturns?[i]
                                                        .salesReturnDetails?[
                                                            detailIndex]
                                                        .returnQty ??
                                                    0),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            '$currency${(widget.saleTransaction.salesReturns?[i].salesReturnDetails?[detailIndex].returnAmount ?? 0)}',
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 10),

                        ///__________Total Return amount______________________
                        if (widget.saleTransaction.salesReturns!.isNotEmpty)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text.rich(
                              TextSpan(
                                text:
                                    '${lang.S.of(context).totalReturnAmount} : ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                                children: [
                                  TextSpan(
                                    text:
                                        '$currency${mainConstant.formatPointNumber(getTotalReturndAmount())}',
                                  ),
                                ],
                              ),
                              style: _theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        const SizedBox(height: 5),

                        ///-----------total payable-------------------
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text.rich(
                            TextSpan(
                              text: '${lang.S.of(context).totalPayable} : ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                              children: [
                                TextSpan(
                                  text:
                                            '$currency${mainConstant.formatPointNumber(storedRoundedAmount)}',
                                ),
                              ],
                            ),
                            style: _theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 5.0),

                        ///-------paid-----------------
                        Visibility(
                          visible: (widget.saleTransaction.dueAmount ?? 0) >
                                  0 ||
                              (widget.saleTransaction.changeAmount ?? 0) > 0,
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text.rich(
                                  TextSpan(
                                    text:
                                        '${lang.S.of(context).receivedAmount} : ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                    children: [
                                      TextSpan(
                                        text:
                                            '$currency${mainConstant.formatPointNumber(() {
                                          num totalAmount = storedRoundedAmount;
                                          num dueAmount = widget
                                                  .saleTransaction.dueAmount ??
                                              0;
                                          num changeAmount = widget
                                                  .saleTransaction
                                                  .changeAmount ??
                                              0;
                                          num receivedAmount =
                                              (totalAmount - dueAmount) +
                                                  changeAmount;
                                          return receivedAmount <= 0
                                              ? totalAmount
                                              : receivedAmount;
                                        }())}',
                                      ),
                                    ],
                                  ),
                                  style: _theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(height: 5.0),
                            ],
                          ),
                        ),

                        ///-------------due---------------
                        Visibility(
                          visible: (widget.saleTransaction.dueAmount ?? 0) > 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text.rich(
                                  TextSpan(
                                    text: '${lang.S.of(context).due} : ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                    children: [
                                      TextSpan(
                                        text:
                                            '$currency${mainConstant.formatPointNumber(widget.saleTransaction.dueAmount ?? 0)}',
                                      ),
                                    ],
                                  ),
                                  style: _theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(height: 5.0),
                            ],
                          ),
                        ),

                        ///-------------Payment Method---------------
                        Visibility(
                          visible:
                              widget.saleTransaction.paymentType?.name != null,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text.rich(
                              TextSpan(
                                text: '${lang.S.of(context).paymentTypes} : ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                                children: [
                                  TextSpan(
                                    text: widget.saleTransaction.paymentType
                                            ?.name ??
                                        'N/A',
                                  ),
                                ],
                              ),
                              style: _theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5.0),

                        ///-------------Split Payment Details---------------
                        if (widget.saleTransaction.isSplitPayment == true) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Split Payment Details:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.money,
                                          size: 16, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Cash: $currency${mainConstant.formatPointNumber(widget.saleTransaction.splitCashAmount ?? 0)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.credit_card,
                                          size: 16, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Online: $currency${mainConstant.formatPointNumber(widget.saleTransaction.splitOnlineAmount ?? 0)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8.0),
                        ],

                        ///-------------Change Amount---------------
                        Visibility(
                          visible:
                              (widget.saleTransaction.changeAmount ?? 0) > 0,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text.rich(
                              TextSpan(
                                text: 'Change Amount : ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                                children: [
                                  TextSpan(
                                    text:
                                        '$currency${mainConstant.formatPointNumber(widget.saleTransaction.changeAmount ?? 0)}',
                                  ),
                                ],
                              ),
                              style: _theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        Visibility(
                          visible:
                              widget.saleTransaction.image?.isNotEmpty ?? false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attachment',
                                style: _theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 100,
                                width: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: const Color(0xffF5F3F3),
                                  image: DecorationImage(
                                      image: NetworkImage(
                                        '${APIConfig.domain}${widget.saleTransaction.image}',
                                      ),
                                      fit: BoxFit.contain),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible:
                              widget.saleTransaction.meta?.note?.isNotEmpty ??
                                  false,
                          child: Text(
                            'Note: ${widget.saleTransaction.meta?.note.toString() ?? ''}',
                            maxLines: 1,
                            style: _theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        Center(
                          child: Text(
                            lang.S.of(context).thakYouForYourPurchase,
                            maxLines: 1,
                            style: _theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ]),
                )),
                bottomNavigationBar: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Print, WhatsApp Share, and Cancel buttons in a row
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Print button
                          GestureDetector(
                            onTap: () async {
                              // Use multilingual printer based on selected language
                              PrintTransactionModel model =
                                  PrintTransactionModel(
                                      transitionModel: widget.saleTransaction,
                                      personalInformationModel:
                                          widget.businessInfo);

                              // Check if a non-English language is selected
                              if (mainConstant.selectedLanguage != null &&
                                  mainConstant.selectedLanguage != 'en' &&
                                  (mainConstant.selectedLanguage == 'hi' ||
                                      mainConstant.selectedLanguage == 'mr')) {
                                // Use multilingual printer for Hindi/Marathi
                                await printerData
                                    .printMultilingualSalesThermalInvoiceNow(
                                  transaction: model,
                                  productList:
                                      model.transitionModel!.salesDetails,
                                  context: context,
                                );
                              } else {
                                // Use regular printer for English
                                await printerData.printSalesThermalInvoiceNow(
                                  transaction: model,
                                  productList:
                                      model.transitionModel!.salesDetails,
                                  context: context,
                                );
                              }
                            },
                            child: Container(
                              height: 60,
                              width: context.width() / 3.5,
                              decoration: const BoxDecoration(
                                color: mainConstant.kMainColor,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Print',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // WhatsApp Share button
                          GestureDetector(
                            onTap: () async {
                              await SalesInvoicePdf.generateSaleDocument(
                                widget.saleTransaction,
                                widget.businessInfo,
                                context,
                                businessSettingData.value!,
                                share: true,
                              );
                            },
                            child: Container(
                              height: 60,
                              width: context.width() / 3.5,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF25D366),
                                    Color(0xFF128C7E)
                                  ],
                                ),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(30),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF25D366)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.share,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Share',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Cancel button
                          GestureDetector(
                            onTap: () async {
                              if (widget.fromSale ?? false) {
                                int count = 0;
                                Navigator.popUntil(context, (route) {
                                  return count++ == 2;
                                });
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            child: Container(
                              height: 60,
                              width: context.width() / 3.5,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  lang.S.of(context).cancel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildInvoiceLogo({required ImageProvider image}) {
    return Container(
      height: 54.12,
      width: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          fit: BoxFit.cover,
          image: image,
        ),
      ),
    );
  }

  // Language selection dialog for Hindi/Marathi printing
  // ignore: unused_element
  Future<void> _showLanguageSelectionDialog(
      BuildContext context, WidgetRef ref) async {
    String? selectedLang = 'hi'; // Default to Hindi

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'प्रिंटिंग भाषा चुनें',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'कृपया प्रिंटिंग के लिए भाषा चुनें',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  // Hindi option
                  ListTile(
                    leading: Radio<String>(
                      value: 'hi',
                      groupValue: selectedLang,
                      onChanged: (String? value) {
                        setState(() {
                          selectedLang = value;
                        });
                      },
                    ),
                    title: const Text(
                      'हिंदी',
                      style: TextStyle(fontSize: 16),
                    ),
                    onTap: () {
                      setState(() {
                        selectedLang = 'hi';
                      });
                    },
                  ),
                  // Marathi option
                  ListTile(
                    leading: Radio<String>(
                      value: 'mr',
                      groupValue: selectedLang,
                      onChanged: (String? value) {
                        setState(() {
                          selectedLang = value;
                        });
                      },
                    ),
                    title: const Text(
                      'मराठी',
                      style: TextStyle(fontSize: 16),
                    ),
                    onTap: () {
                      setState(() {
                        selectedLang = 'mr';
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'रद्द करें',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _printWithSelectedLanguage(selectedLang!, ref);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'प्रिंट करें',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Print with selected language and loading animation
  Future<void> _printWithSelectedLanguage(
      String languageCode, WidgetRef ref) async {
    // Show splash screen style loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: _PrintingLoadingDialog(languageCode: languageCode),
        );
      },
    );

    try {
      print('🌐 Language selection: $languageCode');
      print('🔄 Updating global language...');

      // Update the global language for printing
      mainConstant.updateSelectedLanguage(languageCode);

      print('✅ Language updated to: ${mainConstant.selectedLanguage}');

      // Wait a moment for the language to be updated
      await Future.delayed(const Duration(milliseconds: 500));

      // Print the invoice
      PrintTransactionModel model = PrintTransactionModel(
          transitionModel: widget.saleTransaction,
          personalInformationModel: widget.businessInfo);

      final printerData = ref.read(thermalPrinterProvider);
      await printerData.printMultilingualSalesThermalInvoiceNow(
        transaction: model,
        productList: model.transitionModel!.salesDetails,
        context: context,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close loading dialog on error
      if (mounted) {
        Navigator.of(context).pop();
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageCode == 'hi'
                ? 'प्रिंटिंग में त्रुटि हुई: $e'
                : 'प्रिंटिंगमध्ये त्रुटी: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Custom loading dialog with splash screen style animation
class _PrintingLoadingDialog extends StatefulWidget {
  final String languageCode;

  const _PrintingLoadingDialog({required this.languageCode});

  @override
  State<_PrintingLoadingDialog> createState() => _PrintingLoadingDialogState();
}

class _PrintingLoadingDialogState extends State<_PrintingLoadingDialog>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Fade controller for text and loading
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Rotation controller for loading spinner
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade animation for text
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Scale animation for loading spinner
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    // Rotation animation for loading spinner
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Start animations
    _fadeController.forward();
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Premium Loading Animation (same as splash screen)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer ring
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: AnimatedBuilder(
                              animation: _rotationAnimation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _rotationAnimation.value * 2 * 3.14159,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      kMainColor.withOpacity(0.3),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Inner ring
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: AnimatedBuilder(
                              animation: _rotationAnimation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle:
                                      -_rotationAnimation.value * 2 * 3.14159,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      kMainColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Center dot
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: kMainColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Text with fade animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        widget.languageCode == 'hi'
                            ? 'हिंदी में प्रिंट हो रहा है...'
                            : 'मराठीत प्रिंट होत आहे...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'कृपया प्रतीक्षा करें...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
