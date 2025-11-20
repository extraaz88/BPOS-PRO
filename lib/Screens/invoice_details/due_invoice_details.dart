import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/currency.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../Const/api_config.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/profile_provider.dart';
import '../../constant.dart' as mainConstant;
import '../../model/business_info_model.dart';
import '../../thermal priting invoices/model/print_transaction_model.dart';
import '../../thermal priting invoices/provider/print_thermal_invoice_provider.dart';
import '../Due Calculation/Model/due_collection_model.dart';
import '../Due Calculation/Model/due_collection_invoice_model.dart';
import '../Due Calculation/Repo/due_repo.dart';
import '../Sales/add_sales.dart';
import '../Purchase/add_and_edit_purchase.dart';

class DueInvoiceDetails extends StatefulWidget {
  const DueInvoiceDetails(
      {super.key,
      required this.dueCollection,
      required this.personalInformationModel,
      this.isFromDue});

  final DueCollection dueCollection;
  final BusinessInformation personalInformationModel;
  final bool? isFromDue;

  @override
  State<DueInvoiceDetails> createState() => _DueInvoiceDetailsState();
}

class _DueInvoiceDetailsState extends State<DueInvoiceDetails> {
  
  // Provider to fetch invoice details
  late FutureProvider<DueCollectionInvoice> invoiceDetailsProvider;
  
  @override
  void initState() {
    super.initState();
    // Initialize the provider to fetch invoice details for this party
    invoiceDetailsProvider = FutureProvider<DueCollectionInvoice>((ref) async {
      final repo = DueRepo();
      return await repo.fetchDueInvoiceList(id: widget.dueCollection.partyId?.toInt() ?? 0);
    });
  }
  
  void _navigateToOriginalTransaction(BuildContext context) {
    // Debug: Print party information
    print('Party Type: ${widget.dueCollection.party?.type}');
    print('Party Name: ${widget.dueCollection.party?.name}');
    print('Due Amount: ${widget.dueCollection.dueAmountAfterPay}');
    
    // Check if this is a sale or purchase transaction based on party type
    if (widget.dueCollection.party?.type == 'Customer') {
      // Navigate to Sales screen for customers with due amount
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddSalesScreen(
            customerModel: widget.dueCollection.party,
            dueAmount: widget.dueCollection.dueAmountAfterPay?.toDouble() ?? 0.0,
          ),
        ),
      );
    } else if (widget.dueCollection.party?.type == 'Supplier') {
      // Navigate to Purchase screen for suppliers with due amount
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddAndUpdatePurchaseScreen(
            supplierModel: widget.dueCollection.party,
            dueAmount: widget.dueCollection.dueAmountAfterPay?.toDouble() ?? 0.0,
          ),
        ),
      );
    } else {
      // Show error message if party type cannot be determined
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to determine transaction type. Party type: ${widget.dueCollection.party?.type ?? 'null'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _lang = lang.S.of(context);
    return Consumer(builder: (context, ref, __) {
      final printerData = ref.watch(thermalPrinterProvider);
      final businessSettingData = ref.watch(businessSettingProvider);
      return GlobalPopup(
        child: SafeArea(
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
                      visualDensity: const VisualDensity(horizontal: -4),
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
                        '${widget.personalInformationModel.companyName}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text.rich(
                        TextSpan(
                          text: '${_lang.mobiles} : ',
                          children: [
                            TextSpan(
                              text:
                                  '${widget.personalInformationModel.phoneNumber}',
                            )
                          ],
                        ),
                      ),
                      trailing: Container(
                        alignment: Alignment.center,
                        height: 52,
                        width: 110,
                        // padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            bottomLeft: Radius.circular(25),
                          ),
                        ),
                        child: Text(
                          _lang.moneyReceipt,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // ListTile(
                    //   contentPadding: EdgeInsets.zero,
                    //   title: Text(
                    //     '${widget.personalInformationModel.companyName}',
                    //     style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                    //   ),
                    //   subtitle: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       Text(
                    //         widget.personalInformationModel.address.toString(),
                    //         style: kTextStyle.copyWith(
                    //           color: kGreyTextColor,
                    //         ),
                    //       ),
                    //       Text(
                    //         widget.personalInformationModel.phoneNumber.toString(),
                    //         style: kTextStyle.copyWith(
                    //           color: kGreyTextColor,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    //   isThreeLine: true,
                    // ),
                    const SizedBox(height: 10.0),

                    ///-----------------header data----------------------------
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
                                      text: widget.dueCollection.party?.name ??
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
                                      text: widget.dueCollection.party?.phone ??
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
                                  text: '${_lang.receipt} : ',
                                  children: [
                                    TextSpan(
                                      text:
                                          '#${widget.dueCollection.invoiceNumber}',
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
                                                  .dueCollection.paymentDate ??
                                              '')),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.end,
                              ),
                              Text.rich(
                                TextSpan(
                                  text: '${_lang.collectedBys} : ',
                                  children: [
                                    TextSpan(
                                      text: widget.dueCollection.user?.role ==
                                              "shop-owner"
                                          ? 'Admin'
                                          : widget.dueCollection.user?.name ??
                                              '',
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.end,
                              ),
                              Text.rich(
                                TextSpan(
                                  text:
                                      '${widget.personalInformationModel.vatName ?? 'VAT Number'} : ',
                                  children: [
                                    TextSpan(
                                      text: widget.personalInformationModel
                                              .vatNumber ??
                                          '',
                                    )
                                  ],
                                ),
                                textAlign: TextAlign.end,
                              ).visible(
                                  widget.personalInformationModel.vatNumber !=
                                      null),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30.0),
                    //Invoice Details Section
                    Consumer(
                      builder: (context, ref, __) {
                        final invoiceData = ref.watch(invoiceDetailsProvider);
                        return invoiceData.when(
                          data: (data) {
                            if (data.salesDues?.isNotEmpty ?? false) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Invoice Details',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ...data.salesDues!.map((invoice) => 
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Invoice: ${invoice.invoiceNumber ?? 'N/A'}',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                'Total: $currency${invoice.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Paid: $currency${invoice.paidAmount?.toStringAsFixed(2) ?? '0.00'}'),
                                              Text(
                                                'Due: $currency${invoice.dueAmount?.toStringAsFixed(2) ?? '0.00'}',
                                                style: TextStyle(
                                                  color: (invoice.dueAmount ?? 0) > 0 ? Colors.red : Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ).toList(),
                                ],
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => Text('Error loading invoice details: $error'),
                        );
                      },
                    ),
                    const SizedBox(height: 30.0),
                    //Product data
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        defaultColumnWidth: const FixedColumnWidth(150),
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
                          TableRow(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xffF18A23), // Red background
                                ),
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  _lang.sl,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              Container(
                                color:
                                    const Color(0xffF18A23), // Red background
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  _lang.totalDue,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              Container(
                                color:
                                    const Color(0xff000000), // Black background
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  _lang.paymentsAmount,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              Container(
                                color:
                                    const Color(0xff000000), // Black background
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  _lang.remainingDue,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('1', textAlign: TextAlign.left),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "$currency${widget.dueCollection.totalDue?.toStringAsFixed(2)}",
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "$currency${(widget.dueCollection.totalDue!.toDouble() - widget.dueCollection.dueAmountAfterPay!).toStringAsFixed(2)}",
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "$currency${widget.dueCollection.dueAmountAfterPay?.toStringAsFixed(2)}",
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Row(
                      children: [
                        Text(
                          "${_lang.paidVia}: ${widget.dueCollection.paymentType?.name ?? 'N/A'}",
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${_lang.payableAmount}: $currency ${widget.dueCollection.totalDue?.toStringAsFixed(2) ?? '0.00'}",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${_lang.receivedAmount}: $currency ${(widget.dueCollection.totalDue!.toDouble() - widget.dueCollection.dueAmountAfterPay!.toDouble()).toStringAsFixed(2)}",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${_lang.dueAmount}: $currency 0.00",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    const SizedBox(height: 10.0),
                    Center(
                      child: Text(
                        'Due Payment Completed Successfully!',
                        maxLines: 1,
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.green, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Complete Due button
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: GestureDetector(
                    onTap: () {
                      _navigateToOriginalTransaction(context);
                    },
                    child: Container(
                      height: 60,
                      width: context.width() * 0.9,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.all(
                          Radius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Complete Due Payment',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Print and Cancel buttons in a row
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Print button
                      GestureDetector(
                        onTap: () async {
                          // Use multilingual printer based on selected language
                          PrintDueTransactionModel model = PrintDueTransactionModel(
                              dueTransactionModel: widget.dueCollection,
                              personalInformationModel:
                                  widget.personalInformationModel);
                          
                          // Check if a non-English language is selected
                          if (mainConstant.selectedLanguage != null && 
                              mainConstant.selectedLanguage != 'en' && 
                              (mainConstant.selectedLanguage == 'hi' || mainConstant.selectedLanguage == 'mr')) {
                            // Use multilingual printer for Hindi/Marathi
                            await printerData.printMultilingualDueThermalInvoiceNow(
                              transaction: model, 
                              context: context
                            );
                          } else {
                            // Use regular printer for English
                            await printerData.printDueThermalInvoiceNow(
                              transaction: model, 
                              context: context
                            );
                          }
                        },
                        child: Container(
                          height: 60,
                          width: context.width() / 3,
                          decoration: const BoxDecoration(
                            color: mainConstant.kMainColor,
                            borderRadius: BorderRadius.all(
                              Radius.circular(30),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              lang.S.of(context).print,
                              style: const TextStyle(
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
                          Navigator.pop(context);
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
}
