import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

// ignore: library_prefixes
import '../../GlobalComponents/glonal_popup.dart';
import '../../constant.dart' as mainConstant;
import '../../currency.dart';
import '../../invoice_constant.dart';
import '../../model/business_info_model.dart' as binfo;
import '../../thermal priting invoices/model/print_transaction_model.dart';
import '../../thermal priting invoices/provider/print_thermal_invoice_provider.dart';
import '../Purchase/Model/purchase_transaction_model.dart';

class PurchaseInvoiceDetails extends StatefulWidget {
  const PurchaseInvoiceDetails(
      {super.key,
      required this.transitionModel,
      required this.businessInfo,
      this.isFromPurchase});

  final PurchaseTransaction transitionModel;
  final binfo.BusinessInformation businessInfo;
  final bool? isFromPurchase;

  @override
  State<PurchaseInvoiceDetails> createState() => _PurchaseInvoiceDetailsState();
}

class _PurchaseInvoiceDetailsState extends State<PurchaseInvoiceDetails> {
  bool _isPrinting = false;
  
  num productPrice({required num detailsId}) {
    return widget.transitionModel.details!
            .where((element) => element.id == detailsId)
            .first
            .productPurchasePrice ??
        0;
  }

  num getReturndDiscountAmount() {
    num totalReturnDiscount = 0;
    if (widget.transitionModel.purchaseReturns?.isNotEmpty ?? false) {
      for (var returns in widget.transitionModel.purchaseReturns!) {
        if (returns.purchaseReturnDetails?.isNotEmpty ?? false) {
          for (var details in returns.purchaseReturnDetails!) {
            totalReturnDiscount +=
                ((productPrice(detailsId: details.purchaseDetailId ?? 0) *
                        (details.returnQty ?? 0)) -
                    ((details.returnAmount ?? 0)));
          }
        }
      }
    }
    return totalReturnDiscount;
  }

  String productName({required num detailsId}) {
    return widget
            .transitionModel
            .details?[widget.transitionModel.details!.indexWhere(
          (element) => element.id == detailsId,
        )]
            .product
            ?.productName ??
        '';
  }

  num getTotalReturndAmount() {
    num totalReturn = 0;
    if (widget.transitionModel.purchaseReturns?.isNotEmpty ?? false) {
      for (var returns in widget.transitionModel.purchaseReturns!) {
        if (returns.purchaseReturnDetails?.isNotEmpty ?? false) {
          for (var details in returns.purchaseReturnDetails!) {
            totalReturn += details.returnAmount ?? 0;
          }
        }
      }
    }
    return totalReturn;
  }

  // num getTotalForOldInvoice() {
  //   num total = 0;
  //   for (var element in widget.transitionModel.details!) {
  //     total += (element.productPurchasePrice ?? 0) * getProductQuantity(detailsId: element.id ?? 0);
  //   }
  //   return total + (widget.transitionModel.vatAmount ?? 0);
  // }
  num getTotalForOldInvoice() {
    num total = 0;
    for (var element in widget.transitionModel.details!) {
      // Calculate the total for each item without VAT
      num productPrice = element.productPurchasePrice ?? 0;
      num productQuantity = getProductQuantity(detailsId: element.id ?? 0);

      total += productPrice * productQuantity;
    }

    return total;
  }

  int serialNumber = 1;

  num getProductQuantity({required num detailsId}) {
    num totalQuantity = widget.transitionModel.details
            ?.where((element) => element.id == detailsId)
            .first
            .quantities ??
        0;
    if (widget.transitionModel.purchaseReturns?.isNotEmpty ?? false) {
      for (var returns in widget.transitionModel.purchaseReturns!) {
        if (returns.purchaseReturnDetails?.isNotEmpty ?? false) {
          for (var details in returns.purchaseReturnDetails!) {
            if (details.purchaseDetailId == detailsId) {
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
    return Consumer(builder: (context, ref, __) {
      final printerData = ref.watch(thermalPrinterProvider);
      final businessSettingData = ref.watch(businessSettingProvider);
      final _theme = Theme.of(context);
      final _lang = lang.S.of(context);
      List<String> returnedDates = [];
      return SafeArea(
        child: GlobalPopup(
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: businessSettingData.when(
                        data: (business) {
                          final isSvg = business.pictureUrl?.endsWith('.svg');
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
                              text: widget.businessInfo.phoneNumber.toString(),
                            )
                          ],
                        ),
                      ),
                      trailing: Container(
                        alignment: Alignment.center,
                        // height: 52,
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
                    ),
                    const SizedBox(height: 10.0),

                    //-----------------header data----------------------------
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          fit: FlexFit.tight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: '${lang.S.of(context).billTO} : ',
                                  children: [
                                    TextSpan(
                                      text:
                                          widget.transitionModel.party?.name ??
                                              '',
                                    )
                                  ],
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  text: '${_lang.mobiles} : ',
                                  children: [
                                    TextSpan(
                                      text:
                                          widget.transitionModel.party?.phone ??
                                              '',
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          fit: FlexFit.tight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: '${_lang.purchaseBy} ',
                                  children: [
                                    TextSpan(
                                      text: widget.transitionModel.user?.role ==
                                              "shop-owner"
                                          ? "Admin"
                                          : widget.transitionModel.user?.name ??
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
                                          '#${widget.transitionModel.invoiceNumber}',
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
                                          DateTime.parse(widget.transitionModel
                                                  .purchaseDate ??
                                              '')),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.end,
                              ),
                              Visibility(
                                visible: widget.businessInfo.vatNumber != null,
                                child: Text.rich(
                                  TextSpan(
                                    text:
                                        '${widget.businessInfo.vatName ?? 'VAT Number'} : ',
                                    children: [
                                      TextSpan(
                                        text:
                                            widget.businessInfo.vatNumber ?? '',
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

                    const SizedBox(height: 30.0),

                    //------------------------product table----------------------------
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        defaultColumnWidth: const FixedColumnWidth(100),
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
                          // Data rows from widget.transitionModel.details
                          ...widget.transitionModel.details!
                              .asMap()
                              .entries
                              .map((entry) {
                            final i = entry.key; // This is the index
                            final detail =
                                entry.value; // This is the detail object
                            final quantity =
                                getProductQuantity(detailsId: detail.id ?? 0);
                            final unitPrice = detail.productPurchasePrice ?? 0;
                            final totalPrice = unitPrice * quantity;

                            return TableRow(
                              decoration: i % 2 == 0
                                  ? const BoxDecoration(
                                      color: Colors.white,
                                    )
                                  : BoxDecoration(
                                      color: const Color(0xffF18A23)
                                          .withOpacity(0.07),
                                    ),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    (i + 1).toString(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    detail.product?.productName ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    quantity.toString(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    '$currency $unitPrice',
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    '$currency $totalPrice',
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    //_____________________subtotal______________________________
                    Row(
                      children: [
                        Text(
                          "${_lang.paidVia}: ${widget.transitionModel.paymentType?.name ?? 'N/A'}",
                        ),
                        const Spacer(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text.rich(
                            TextSpan(
                              text: '${lang.S.of(context).subTotal} : ',
                              children: [
                                TextSpan(
                                  text:
                                      '$currency ${mainConstant.formatPointNumber(getTotalForOldInvoice())}',
                                ),
                              ],
                            ),
                            style: _theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5.0),

                    //----------discount----------------------
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text.rich(
                        TextSpan(
                          text: '${lang.S.of(context).discount} : ',
                          children: [
                            TextSpan(
                              text:
                                  '$currency ${mainConstant.formatPointNumber((widget.transitionModel.discountAmount ?? 0) + getReturndDiscountAmount())}',
                            ),
                          ],
                        ),
                        style: _theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),

                    const SizedBox(height: 5.0),

                    ///__________service_charge______________
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text.rich(
                        TextSpan(
                          text: 'Service charge : ',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          children: [
                            TextSpan(
                              text:
                                  '$currency ${mainConstant.formatPointNumber(widget.transitionModel.serviceCharge ?? 0)}',
                            ),
                          ],
                        ),
                        style: _theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),

                    const SizedBox(height: 5.0),
                    //----------vat----------------------
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text.rich(
                        TextSpan(
                          text:
                              '${widget.transitionModel.vat?.name ?? lang.S.of(context).vat} : ',
                          children: [
                            TextSpan(
                              text:
                                  '$currency ${mainConstant.formatPointNumber((widget.transitionModel.vatAmount ?? 0))}',
                            ),
                          ],
                        ),
                        style: _theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),

                    const SizedBox(height: 5.0),

                    ///__________shipping_charge______________
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text.rich(
                        TextSpan(
                          text: 'Shipping charge : ',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          children: [
                            TextSpan(
                              text:
                                  '$currency ${mainConstant.formatPointNumber(widget.transitionModel.shippingCharge ?? 0)}',
                            ),
                          ],
                        ),
                        style: _theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 5.0),

                    //----------total amount-------------
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text.rich(
                        TextSpan(
                          text: '${lang.S.of(context).totalAmount} : ',
                          children: [
                            TextSpan(
                              text:
                                  '$currency ${mainConstant.formatPointNumber((widget.transitionModel.totalAmount ?? 0) + getTotalReturndAmount())}',
                            ),
                          ],
                        ),
                        style: _theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 5),
                    //______________Returned_Product_______________________________
                    if (widget.transitionModel.purchaseReturns!.isNotEmpty)
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
                                    (widget.transitionModel.purchaseReturns
                                            ?.length ??
                                        0);
                                i++)
                              for (var detailIndex = 0;
                                  detailIndex <
                                      (widget
                                              .transitionModel
                                              .purchaseReturns?[i]
                                              .purchaseReturnDetails
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
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
                                                    .transitionModel
                                                    .purchaseReturns?[i]
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
                                                    .transitionModel
                                                    .purchaseReturns?[i]
                                                    .purchaseReturnDetails?[
                                                        detailIndex]
                                                    .purchaseDetailId ??
                                                0),
                                        maxLines: 2,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        widget
                                                .transitionModel
                                                .purchaseReturns?[i]
                                                .purchaseReturnDetails?[
                                                    detailIndex]
                                                .returnQty
                                                .toString() ??
                                            '0',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        '$currency ${(widget.transitionModel.purchaseReturns?[i].purchaseReturnDetails?[detailIndex].returnAmount ?? 0)}',
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),

                    //__________Total Return amount______________________
                    if (widget.transitionModel.purchaseReturns!.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text.rich(
                          TextSpan(
                            text: '${lang.S.of(context).totalReturnAmount} : ',
                            children: [
                              TextSpan(
                                text: '$currency ${getTotalReturndAmount()}',
                              ),
                            ],
                          ),
                          style: _theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    const SizedBox(height: 5.0),

                    //-------------Total payable--------------------
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text.rich(
                        TextSpan(
                          text: '${lang.S.of(context).totalPayable} : ',
                          children: [
                            TextSpan(
                              text:
                                  '$currency ${mainConstant.formatPointNumber(widget.transitionModel.totalAmount ?? 0)}',
                            ),
                          ],
                        ),
                        style: _theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 5.0),

                    //----------------paid-------------------------
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text.rich(
                        TextSpan(
                          text: '${lang.S.of(context).paid} : ',
                          children: [
                            TextSpan(
                              text:
                                  '$currency ${mainConstant.formatPointNumber(widget.transitionModel.paidAmount ?? ((widget.transitionModel.totalAmount ?? 0) - (widget.transitionModel.dueAmount ?? 0)) + (widget.transitionModel.changeAmount ?? 0))}',
                            ),
                          ],
                        ),
                        style: _theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 5.0),

                    //-----------due--------------
                    // Always show Due Amount (even if 0)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text.rich(
                        TextSpan(
                          text: '${lang.S.of(context).due} : ',
                          children: [
                            TextSpan(
                              text:
                                  '$currency ${mainConstant.formatPointNumber(widget.transitionModel.dueAmount ?? 0)}',
                            ),
                          ],
                        ),
                        style: _theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 5.0),

                    ///-------------Payment Method---------------
                    Visibility(
                      visible: widget.transitionModel.paymentType?.name != null,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text.rich(
                          TextSpan(
                            text: '${lang.S.of(context).paymentTypes} : ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            children: [
                              TextSpan(
                                text:
                                    widget.transitionModel.paymentType?.name ??
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
                    if (widget.transitionModel.isSplitPayment == true) ...[
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
                                    'Cash: $currency${mainConstant.formatPointNumber(widget.transitionModel.splitCashAmount ?? 0)}',
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
                                    'Online: $currency${mainConstant.formatPointNumber(widget.transitionModel.splitOnlineAmount ?? 0)}',
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
                      visible: (widget.transitionModel.changeAmount ?? 0) > 0,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text.rich(
                          TextSpan(
                            text: 'Change Amount : ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            children: [
                              TextSpan(
                                text:
                                    '$currency${mainConstant.formatPointNumber(widget.transitionModel.changeAmount ?? 0)}',
                              ),
                            ],
                          ),
                          style: _theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Center(
                      child: Text(
                        lang.S.of(context).thakYouForYourPurchase,
                        maxLines: 1,
                        style: _theme.textTheme.titleMedium?.copyWith(
                            color: kTitleColor, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Print and Cancel buttons in a row
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Print button
                      GestureDetector(
                        onTap: _isPrinting ? null : () async {
                          if (_isPrinting) return;
                          
                          setState(() {
                            _isPrinting = true;
                          });

                          try {
                            // Use multilingual printer based on selected language
                            PrintPurchaseTransactionModel model =
                                PrintPurchaseTransactionModel(
                                    purchaseTransitionModel:
                                        widget.transitionModel,
                                    personalInformationModel:
                                        widget.businessInfo);

                            // Check if a non-English language is selected
                            if (mainConstant.selectedLanguage != null &&
                                mainConstant.selectedLanguage != 'en' &&
                                (mainConstant.selectedLanguage == 'hi' ||
                                    mainConstant.selectedLanguage == 'mr')) {
                              // Use multilingual printer for Hindi/Marathi
                              await printerData
                                  .printMultilingualPurchaseThermalInvoiceNow(
                                transaction: model,
                                productList:
                                    model.purchaseTransitionModel!.details,
                                context: context,
                              );
                            } else {
                              // Use regular printer for English
                              await printerData.printPurchaseThermalInvoiceNow(
                                transaction: model,
                                productList:
                                    model.purchaseTransitionModel!.details,
                                context: context,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Printing error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isPrinting = false;
                              });
                            }
                          }
                        },
                        child: Container(
                          height: 60,
                          width: context.width() / 3,
                          decoration: BoxDecoration(
                            color: _isPrinting 
                                ? mainConstant.kMainColor.withOpacity(0.7)
                                : mainConstant.kMainColor,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(30),
                            ),
                          ),
                          child: Center(
                            child: _isPrinting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Print',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      // Cancel button
                      GestureDetector(
                        onTap: () {
                          if (widget.isFromPurchase ?? false) {
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
                          width: context.width() / 3,
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
                                fontSize: 18,
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
                    await _printPurchaseWithSelectedLanguage(
                        selectedLang!, ref);
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

  // Print purchase invoice with selected language and loading animation
  Future<void> _printPurchaseWithSelectedLanguage(
      String languageCode, WidgetRef ref) async {
    // Show splash screen style loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: _PurchasePrintingLoadingDialog(languageCode: languageCode),
        );
      },
    );

    try {
      // Update the global language for printing
      mainConstant.updateSelectedLanguage(languageCode);

      // Wait a moment for the language to be updated
      await Future.delayed(const Duration(milliseconds: 500));

      // Print the purchase invoice
      PrintPurchaseTransactionModel model = PrintPurchaseTransactionModel(
          purchaseTransitionModel: widget.transitionModel,
          personalInformationModel: widget.businessInfo);

      final printerData = ref.read(thermalPrinterProvider);
      await printerData.printMultilingualPurchaseThermalInvoiceNow(
        transaction: model,
        productList: model.purchaseTransitionModel!.details,
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

// Custom loading dialog with splash screen style animation for purchase invoices
class _PurchasePrintingLoadingDialog extends StatefulWidget {
  final String languageCode;

  const _PurchasePrintingLoadingDialog({required this.languageCode});

  @override
  State<_PurchasePrintingLoadingDialog> createState() =>
      _PurchasePrintingLoadingDialogState();
}

class _PurchasePrintingLoadingDialogState
    extends State<_PurchasePrintingLoadingDialog>
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
