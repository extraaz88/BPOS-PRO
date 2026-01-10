import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant.dart';
import '../model/add_to_cart_model.dart';
import '../model/sale_transaction_model.dart';
import 'model/print_transaction_model.dart';
import 'multilingual_thermal_printer.dart';

class SalesThermalPrinterInvoice {
  ///________Sales____________________
  final MultilingualThermalPrinter _multilingualPrinter =
      MultilingualThermalPrinter();

  Future<void> printSalesTicket(
      {required PrintTransactionModel printTransactionModel,
      required List<SalesDetails>? productList,
      List<AddToCartModel>? cartItems}) async {
    bool? isConnected = await PrintBluetoothThermal.connectionStatus;
    if (isConnected == true) {
      List<int> bytes = await getSalesTicket(
          printTransactionModel: printTransactionModel,
          productList: productList,
          cartItems: cartItems);
      if (printTransactionModel.transitionModel?.salesDetails?.isNotEmpty ??
          false) {
        await PrintBluetoothThermal.writeBytes(bytes);
        EasyLoading.showSuccess('Successfully Printed');
      } else {
        toast('No Product Found');
      }
    } else {
      EasyLoading.showError('Unable to connect with printer');
    }
  }

  /// Print sales ticket with Marathi and Hindi support
  Future<void> printMultilingualSalesTicket(
      {required PrintTransactionModel printTransactionModel,
      required List<SalesDetails>? productList,
      List<AddToCartModel>? cartItems}) async {
    await _multilingualPrinter.printMultilingualSalesTicket(
      printTransactionModel: printTransactionModel,
      productList: productList,
      cartItems: cartItems,
    );
  }

  Future<List<int>> getSalesTicket(
      {required PrintTransactionModel printTransactionModel,
      required List<SalesDetails>? productList,
      List<AddToCartModel>? cartItems}) async {
    List<DateTime> returnedDates = [];
    String productName({required num detailsId}) {
      return productList!
              .where((element) => element.id == detailsId)
              .first
              .product
              ?.productName ??
          '';
    }

    num getProductQuantity({required num detailsId}) {
      num totalQuantity = productList!
              .where((element) => element.id == detailsId)
              .first
              .quantities ??
          0;
      if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ??
          false) {
        for (var returns
            in printTransactionModel.transitionModel!.salesReturns!) {
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

    String getQuantityWithUnit(
        {required num detailsId, required num quantity}) {
      if (cartItems != null && cartItems!.isNotEmpty) {
        try {
          final saleDetail =
              productList!.firstWhere((element) => element.id == detailsId);
          final cartItem = cartItems!.firstWhere(
            (item) => item.productId == saleDetail.productId,
            orElse: () => AddToCartModel(productId: -1),
          );

          if (cartItem.productId != -1) {
            if (cartItem.displayQuantity != null &&
                cartItem.displayUnit != null) {
              return '${formatPointNumber(cartItem.displayQuantity!)} ${cartItem.displayUnit}';
            }
            if (cartItem.unitName != null && cartItem.unitName!.isNotEmpty) {
              return '${formatPointNumber(quantity)} ${cartItem.unitName}';
            }
          }
        } catch (e) {
          // Cart item not found, continue to fallback
        }
      }
      return formatPointNumber(quantity);
    }

    num getTotalForOldInvoice() {
      num total = 0;
      for (var element in productList!) {
        total += (element.price ?? 0) *
            getProductQuantity(detailsId: element.id ?? 0);
      }

      return total;
    }

    num productPrice({required num detailsId}) {
      return productList!
              .where((element) => element.id == detailsId)
              .first
              .price ??
          0;
    }

    num getTotalReturndAmount() {
      num totalReturn = 0;
      if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ??
          false) {
        for (var returns
            in printTransactionModel.transitionModel!.salesReturns!) {
          if (returns.salesReturnDetails?.isNotEmpty ?? false) {
            for (var details in returns.salesReturnDetails!) {
              totalReturn += details.returnAmount ?? 0;
            }
          }
        }
      }
      return totalReturn;
    }

    num getReturndDiscountAmount() {
      num totalReturnDiscount = 0;
      if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ??
          false) {
        for (var returns
            in printTransactionModel.transitionModel!.salesReturns!) {
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

    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    // Print invoice logo if available (above company name)
    final invoiceLogo =
        printTransactionModel.personalInformationModel.invoiceLogo;
    if (invoiceLogo != null && invoiceLogo.isNotEmpty) {
      try {
        final imageUrl = '${APIConfig.domain}$invoiceLogo';
        final logoImage = await _loadNetworkImage(imageUrl);
        if (logoImage != null) {
          bytes += generator.image(logoImage);
        }
      } catch (e) {
        print('Error loading invoice logo: $e');
        // Continue without logo if loading fails
      }
    }

    bytes += generator.text(
        printTransactionModel.personalInformationModel.companyName ?? '',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1);

    bytes += generator.text(
        '${getLocalizedPrintText('Seller')} :${printTransactionModel.transitionModel?.user?.role == "shop-owner" ? getLocalizedPrintText('Admin') : printTransactionModel.transitionModel!.user?.name}',
        styles: const PosStyles(align: PosAlign.center));
    if (printTransactionModel.personalInformationModel.address != null) {
      bytes += generator.text(
          printTransactionModel.personalInformationModel.address ?? '',
          styles: const PosStyles(align: PosAlign.center));
    }
    if (printTransactionModel.personalInformationModel.vatNumber != null) {
      bytes += generator.text(
          "${printTransactionModel.personalInformationModel.vatName ?? getLocalizedPrintText('VAT No :')}${printTransactionModel.personalInformationModel.vatNumber ?? ''}",
          styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.text(
        '${getLocalizedPrintText('Tel:')} ${printTransactionModel.personalInformationModel.phoneNumber ?? ''}',
        styles: const PosStyles(align: PosAlign.center),
        linesAfter: 1);

    bytes += generator.text(
        '${getLocalizedPrintText('Name')}: ${printTransactionModel.transitionModel?.party?.name ?? getLocalizedPrintText('Guest')}',
        styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text(
        '${getLocalizedPrintText('mobile')}: ${printTransactionModel.transitionModel?.party?.phone ?? getLocalizedPrintText('Not Provided')}',
        styles: const PosStyles(align: PosAlign.left));
    // bytes += generator.text('Sales By: ${printTransactionModel.transitionModel?.user?.name ?? 'Not Provided'}', styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text(
      '${getLocalizedPrintText('Invoice')}: ${printTransactionModel.transitionModel?.invoiceNumber ?? getLocalizedPrintText('Not Provided')}',
      styles: const PosStyles(align: PosAlign.left),
    );

    // Retrieve and print GST and IFSC from SharedPreferences (second occurrence - left aligned)
    final prefsForGst2 = await SharedPreferences.getInstance();
    final String gstNumber2 = prefsForGst2.getString("gst") ?? "";
    final String ifscCode2 = prefsForGst2.getString("ifsc") ?? "";

    if (gstNumber2.isNotEmpty) {
      bytes += generator.text('GST: $gstNumber2',
          styles: const PosStyles(align: PosAlign.left));
    }
    if (ifscCode2.isNotEmpty) {
      bytes += generator.text('FSSAI: $ifscCode2',
          styles: const PosStyles(align: PosAlign.left), linesAfter: 1);
    }

    // Header row: hide the RS (price) column from print and give Qty more space
    bytes += generator.row([
      PosColumn(
          text: getLocalizedPrintText('Item'),
          width: 6,
          styles: const PosStyles(
              align: PosAlign.left,
              bold: true,
              height: PosTextSize.size1,
              width: PosTextSize.size1)),
      PosColumn(
          text: getLocalizedPrintText('Qty'),
          width: 3,
          styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size1,
              width: PosTextSize.size1)),
      PosColumn(
          text: getLocalizedPrintText('Amount'),
          width: 3,
          styles: const PosStyles(
              align: PosAlign.right,
              bold: true,
              height: PosTextSize.size1,
              width: PosTextSize.size1)),
    ]);
    bytes += generator.hr();
    List.generate(productList?.length ?? 1, (index) {
      return bytes += generator.row([
        PosColumn(
            text: productList?[index].product?.productName ?? '',
            width: 6,
            styles: const PosStyles(
              align: PosAlign.left,
              height: PosTextSize.size1,
              width: PosTextSize.size1,
            )),
        PosColumn(
            text: getQuantityWithUnit(
                detailsId: productList?[index].id ?? 0,
                quantity:
                    getProductQuantity(detailsId: productList?[index].id ?? 0)),
            width: 3,
            styles: const PosStyles(
              align: PosAlign.center,
              height: PosTextSize.size1,
              width: PosTextSize.size1,
            )),
        PosColumn(
            text:
                "${(productList?[index].price ?? 0) * getProductQuantity(detailsId: productList?[index].id ?? 0)}",
            width: 3,
            styles: const PosStyles(
              align: PosAlign.right,
              height: PosTextSize.size1,
              width: PosTextSize.size1,
            )),
      ]);
    });
    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
          text: getLocalizedPrintText('Subtotal'),
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: '${getTotalForOldInvoice()}',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: getLocalizedPrintText('Discount'),
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: ((printTransactionModel.transitionModel?.discountAmount ?? 0) +
                  getReturndDiscountAmount())
              .toStringAsFixed(2),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: getLocalizedPrintText('Service Charge'),
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: '${printTransactionModel.transitionModel?.serviceCharge ?? 0}',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: printTransactionModel.transitionModel?.vat?.name ??
              getLocalizedPrintText('VAT'),
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: '${printTransactionModel.transitionModel?.vatAmount ?? 0}',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: getLocalizedPrintText('Shipping Charge'),
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: '${printTransactionModel.transitionModel?.shippingCharge ?? 0}',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);

    if (printTransactionModel.transitionModel?.roundingAmount != 0) {
      bytes += generator.row([
        PosColumn(
            text: getLocalizedPrintText('Total'),
            width: 8,
            styles: const PosStyles(
              align: PosAlign.left,
            )),
        PosColumn(
            text: (formatPointNumber(
                printTransactionModel.transitionModel?.actualTotalAmount ?? 0)),
            width: 4,
            styles: const PosStyles(
              align: PosAlign.right,
            )),
      ]);
      bytes += generator.row([
        PosColumn(
            text: getLocalizedPrintText('Rounding'),
            width: 8,
            styles: const PosStyles(
              align: PosAlign.left,
            )),
        PosColumn(
            text:
                ("${!(printTransactionModel.transitionModel?.roundingAmount?.isNegative ?? true) ? '+' : ''}${formatPointNumber(printTransactionModel.transitionModel?.roundingAmount ?? 0)}"),
            width: 4,
            styles: const PosStyles(
              align: PosAlign.right,
            )),
      ]);
    }

    bytes += generator.row([
      PosColumn(
          text: getLocalizedPrintText('Total Amount'),
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: ((printTransactionModel.transitionModel?.totalAmount ?? 0) +
                  getTotalReturndAmount())
              .toStringAsFixed(2),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);

    ///_____Return_table_______________________________
    if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ??
        false) {
      List.generate(
          printTransactionModel.transitionModel?.salesReturns?.length ?? 0,
          (i) {
        bytes += generator.hr();
        if (!returnedDates.any((element) => element.isAtSameMomentAs(
            DateTime.tryParse(printTransactionModel
                        .transitionModel?.salesReturns?[i].returnDate
                        ?.substring(0, 10) ??
                    '') ??
                DateTime.now()))) {
          bytes += generator.row([
            PosColumn(
                text:
                    '${getLocalizedPrintText('Return')}-${DateFormat.yMd().format(DateTime.parse(printTransactionModel.transitionModel?.salesReturns?[i].returnDate ?? DateTime.now().toString()))}',
                width: 7,
                styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(
                text: getLocalizedPrintText('Qty'),
                width: 2,
                styles: const PosStyles(align: PosAlign.center, bold: true)),
            PosColumn(
                text: getLocalizedPrintText('Total'),
                width: 3,
                styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          bytes += generator.hr();
        }

        List.generate(
            printTransactionModel.transitionModel?.salesReturns?[i]
                    .salesReturnDetails?.length ??
                0, (index) {
          returnedDates.add(DateTime.tryParse(printTransactionModel
                      .transitionModel?.salesReturns?[i].returnDate
                      ?.substring(0, 10) ??
                  '') ??
              DateTime.now());
          final product = printTransactionModel
              .transitionModel?.salesReturns?[i].salesReturnDetails?[index];
          return bytes += generator.row([
            PosColumn(
                text: productName(detailsId: product?.saleDetailId ?? 0),
                width: 7,
                styles: const PosStyles(align: PosAlign.left)),
            PosColumn(
                text: product?.returnQty.toString() ??
                    getLocalizedPrintText('Not Provided'),
                width: 2,
                styles: const PosStyles(align: PosAlign.center)),
            PosColumn(
                text: "${(product?.returnAmount ?? 0)}",
                width: 3,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
        });
        //
      });
    }
    bytes += generator.hr();

    ///_____Total Returned Amount_______________________________
    if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ??
        false) {
      bytes += generator.row([
        PosColumn(
            text: getLocalizedPrintText('Returned Amount'),
            width: 8,
            styles: const PosStyles(
              align: PosAlign.left,
            )),
        PosColumn(
            text: '${getTotalReturndAmount()}',
            width: 4,
            styles: const PosStyles(
              align: PosAlign.right,
            )),
      ]);
    }
    bytes += generator.row([
      PosColumn(
          text: getLocalizedPrintText('Total Payable'),
          width: 8,
          styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(
          text: printTransactionModel.transitionModel?.totalAmount.toString() ??
              '',
          width: 4,
          styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    bytes += generator.row([
      PosColumn(
          text: getLocalizedPrintText('Payment Type'),
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: (printTransactionModel.transitionModel?.isSplitPayment == true)
              ? getLocalizedPrintText('Split')
              : (printTransactionModel.transitionModel?.paymentType?.name ??
                  getLocalizedPrintText('N/A')),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    if ((printTransactionModel.transitionModel?.dueAmount ?? 0) > 0 ||
        (printTransactionModel.transitionModel?.changeAmount ?? 0) > 0) {
      bytes += generator.row([
        PosColumn(
            text: getLocalizedPrintText('Received Amount'),
            width: 8,
            styles: const PosStyles(
              align: PosAlign.left,
            )),
        PosColumn(
            text: formatPointNumber(
                ((printTransactionModel.transitionModel?.totalAmount ?? 0) -
                        (printTransactionModel.transitionModel?.dueAmount ??
                            0)) +
                    (printTransactionModel.transitionModel?.changeAmount ?? 0)),
            width: 4,
            styles: const PosStyles(
              align: PosAlign.right,
            )),
      ]);
    }
    if ((printTransactionModel.transitionModel?.dueAmount ?? 0) > 0) {
      bytes += generator.row([
        PosColumn(
            text: getLocalizedPrintText('Due Amount'),
            width: 8,
            styles: const PosStyles(
              align: PosAlign.left,
            )),
        PosColumn(
            text: formatPointNumber(
                printTransactionModel.transitionModel?.dueAmount ?? 0),
            width: 4,
            styles: const PosStyles(
              align: PosAlign.right,
            )),
      ]);
    }
    if ((printTransactionModel.transitionModel?.changeAmount ?? 0) > 0) {
      bytes += generator.row([
        PosColumn(
            text: getLocalizedPrintText('Change Amount'),
            width: 8,
            styles: const PosStyles(
              align: PosAlign.left,
            )),
        PosColumn(
            text: formatPointNumber(
                printTransactionModel.transitionModel?.changeAmount ?? 0),
            width: 4,
            styles: const PosStyles(
              align: PosAlign.right,
            )),
      ]);
    }
    bytes += generator.hr(ch: '=', linesAfter: 1);

    // ticket.feed(2);
    bytes += generator.text(getLocalizedPrintText('Thank you!'),
        styles: const PosStyles(align: PosAlign.center, bold: true));

    bytes += generator.text(
        printTransactionModel.transitionModel!.saleDate ?? '',
        styles: const PosStyles(align: PosAlign.center),
        linesAfter: 1);

    bytes += generator.text(
        getLocalizedPrintText(
            'Note: Goods once sold will not be taken back or exchanged.'),
        styles: const PosStyles(align: PosAlign.center, bold: false),
        linesAfter: 1);

    // Print UPI QR code if UPI ID is configured (center aligned)
    final prefs = await SharedPreferences.getInstance();
    final upiId = prefs.getString('upi_id') ?? '';

    if (upiId.isNotEmpty) {
      // Generate UPI payment string
      final totalAmount =
          printTransactionModel.transitionModel?.totalAmount ?? 0;
      final upiPaymentString =
          'upi://pay?pa=$upiId&pn=${printTransactionModel.personalInformationModel.companyName ?? "Merchant"}&am=${totalAmount.toStringAsFixed(2)}&cu=INR&tn=Payment';

      // Print UPI QR code (center aligned)
      bytes += generator.text(
        getLocalizedPrintText('Scan to Pay via UPI'),
        styles: const PosStyles(align: PosAlign.center, bold: true),
        linesAfter: 1,
      );
      bytes += generator.qrcode(upiPaymentString);
      bytes += generator.text(
        upiId,
        styles: const PosStyles(align: PosAlign.center),
        linesAfter: 1,
      );
    }

    bytes += generator.text(
        '${getLocalizedPrintText('Developed By:')} $companyName',
        styles: const PosStyles(align: PosAlign.center),
        linesAfter: 1);
    bytes += generator.cut();
    return bytes;
  }

  /// Load network image and convert to thermal printer format
  Future<img.Image?> _loadNetworkImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;
        final image = img.decodeImage(imageBytes);

        if (image != null) {
          // Resize image to fit thermal printer width (58mm)
          const double printerWidthMm = 58.0;
          const double printerDpi = 203.0;
          final int maxWidthPx = ((printerWidthMm * printerDpi) / 25.4).round();

          // Maintain aspect ratio
          if (image.width > maxWidthPx) {
            final aspectRatio = image.height / image.width;
            final newHeight = (maxWidthPx * aspectRatio).round();
            return img.copyResize(image, width: maxWidthPx, height: newHeight);
          }

          return image;
        }
      }
      return null;
    } catch (e) {
      print('Error loading network image: $e');
      return null;
    }
  }
}
