import 'dart:async';
import 'dart:ui' as ui;

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:image/image.dart' as img;

import '../constant.dart';
import '../model/sale_transaction_model.dart';
import 'model/print_transaction_model.dart';

class MultilingualThermalPrinter {
  /// Enhanced thermal printer with Marathi and Hindi support
  
  Future<void> printMultilingualSalesTicket({
    required PrintTransactionModel printTransactionModel, 
    required List<SalesDetails>? productList
  }) async {
    bool? isConnected = await PrintBluetoothThermal.connectionStatus;
    if (isConnected == true) {
      List<int> bytes = await getMultilingualSalesTicket(
        printTransactionModel: printTransactionModel, 
        productList: productList
      );
      if (printTransactionModel.transitionModel?.salesDetails?.isNotEmpty ?? false) {
        await PrintBluetoothThermal.writeBytes(bytes);
        EasyLoading.showSuccess('Successfully Printed');
      } else {
        toast('No Product Found');
      }
    } else {
      EasyLoading.showError('Unable to connect with printer');
    }
  }

  Future<List<int>> getMultilingualSalesTicket({
    required PrintTransactionModel printTransactionModel, 
    required List<SalesDetails>? productList
  }) async {
    List<DateTime> returnedDates = [];
    
    String productName({required num detailsId}) {
      return productList!.where((element) => element.id == detailsId).first.product?.productName ?? '';
    }

    num getProductQuantity({required num detailsId}) {
      num totalQuantity = productList!.where((element) => element.id == detailsId).first.quantities ?? 0;
      if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ?? false) {
        for (var returns in printTransactionModel.transitionModel!.salesReturns!) {
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

    num getTotalForOldInvoice() {
      num total = 0;
      for (var element in productList!) {
        total += (element.price ?? 0) * getProductQuantity(detailsId: element.id ?? 0);
      }
      return total;
    }

    num productPrice({required num detailsId}) {
      return productList!.where((element) => element.id == detailsId).first.price ?? 0;
    }

    num getTotalReturndAmount() {
      num totalReturn = 0;
      if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ?? false) {
        for (var returns in printTransactionModel.transitionModel!.salesReturns!) {
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
      if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ?? false) {
        for (var returns in printTransactionModel.transitionModel!.salesReturns!) {
          if (returns.salesReturnDetails?.isNotEmpty ?? false) {
            for (var details in returns.salesReturnDetails!) {
              totalReturnDiscount += ((productPrice(detailsId: details.saleDetailId ?? 0) * (details.returnQty ?? 0)) - ((details.returnAmount ?? 0)));
            }
          }
        }
      }
      return totalReturnDiscount;
    }

    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    // Helper function to add multilingual text
    Future<void> addMultilingualText(String text, {PosStyles? styles, int linesAfter = 0}) async {
      if (_isAscii(text)) {
        bytes += generator.text(text, styles: styles ?? const PosStyles(), linesAfter: linesAfter);
      } else {
        // For Hindi/Marathi text, convert to transliterated text for thermal printer
        String processedText = _processHindiMarathiText(text);
        print('Original text: $text');
        print('Processed text: $processedText');
        print('Is ASCII: ${_isAscii(processedText)}');
        
        if (_isAscii(processedText)) {
          bytes += generator.text(processedText, styles: styles ?? const PosStyles(), linesAfter: linesAfter);
        } else {
          // If still non-ASCII, convert to image
          final imageBytes = await _textToImageBytes(generator, text, styles: styles);
          bytes += imageBytes;
          if (linesAfter > 0) {
            bytes += generator.feed(linesAfter);
          }
        }
      }
    }

    // Company name with multilingual support
    await addMultilingualText(
      printTransactionModel.personalInformationModel.companyName ?? '',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
      linesAfter: 1,
    );

    // Seller information
    await addMultilingualText(
      'Seller :${printTransactionModel.transitionModel?.user?.role == "shop-owner" ? 'Admin' : printTransactionModel.transitionModel!.user?.name}',
      styles: const PosStyles(align: PosAlign.center),
    );

    // Address
    if (printTransactionModel.personalInformationModel.address != null) {
      await addMultilingualText(
        printTransactionModel.personalInformationModel.address ?? '',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    // VAT information
    if (printTransactionModel.personalInformationModel.vatNumber != null) {
      await addMultilingualText(
        "${printTransactionModel.personalInformationModel.vatName ?? 'VAT No :'}${printTransactionModel.personalInformationModel.vatNumber ?? ''}",
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    // Phone number
    await addMultilingualText(
      'Tel: ${printTransactionModel.personalInformationModel.phoneNumber ?? ''}',
      styles: const PosStyles(align: PosAlign.center),
      linesAfter: 1,
    );

    // Customer information
    await addMultilingualText(
      'Name: ${printTransactionModel.transitionModel?.party?.name ?? 'Guest'}',
      styles: const PosStyles(align: PosAlign.left),
    );

    await addMultilingualText(
      'mobile: ${printTransactionModel.transitionModel?.party?.phone ?? 'Not Provided'}',
      styles: const PosStyles(align: PosAlign.left),
    );

    await addMultilingualText(
      'Invoice: ${printTransactionModel.transitionModel?.invoiceNumber ?? 'Not Provided'}',
      styles: const PosStyles(align: PosAlign.left),
      linesAfter: 1,
    );

    // Table headers
    bytes += generator.row([
      PosColumn(text: 'Item', width: 5, styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(text: 'Price', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(text: 'Amount', width: 3, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.hr();

    // Product list with multilingual product names
    List.generate(productList?.length ?? 1, (index) {
      final productName = productList?[index].product?.productName ?? '';
      final productPrice = productList?[index].price ?? 0;
      final quantity = getProductQuantity(detailsId: productList?[index].id ?? 0);
      final amount = productPrice * quantity;

      // Add product name as image if it contains non-ASCII characters
      if (!_isAscii(productName)) {
        _addProductRowAsImage(generator, productName, productPrice, quantity, amount);
      } else {
        bytes += generator.row([
          PosColumn(text: productName, width: 5, styles: const PosStyles(align: PosAlign.left)),
          PosColumn(text: '$productPrice', width: 2, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: formatPointNumber(quantity), width: 2, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: '$amount', width: 3, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    });

    bytes += generator.hr();

    // Summary section
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 8, styles: const PosStyles(align: PosAlign.left)),
      PosColumn(text: '${getTotalForOldInvoice()}', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Discount', width: 8, styles: const PosStyles(align: PosAlign.left)),
      PosColumn(text: ((printTransactionModel.transitionModel?.discountAmount ?? 0) + getReturndDiscountAmount()).toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: printTransactionModel.transitionModel?.vat?.name ?? 'VAT', width: 8, styles: const PosStyles(align: PosAlign.left)),
      PosColumn(text: '${printTransactionModel.transitionModel?.vatAmount ?? 0}', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Shipping Charge', width: 8, styles: const PosStyles(align: PosAlign.left)),
      PosColumn(text: '${printTransactionModel.transitionModel?.shippingCharge ?? 0}', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);

    if (printTransactionModel.transitionModel?.roundingAmount != 0) {
      bytes += generator.row([
        PosColumn(text: 'Total', width: 8, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: (formatPointNumber(printTransactionModel.transitionModel?.actualTotalAmount ?? 0)), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Rounding', width: 8, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: ("${!(printTransactionModel.transitionModel?.roundingAmount?.isNegative ?? true) ? '+' : ''}${formatPointNumber(printTransactionModel.transitionModel?.roundingAmount ?? 0)}"), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.row([
      PosColumn(text: 'Total Amount', width: 8, styles: const PosStyles(align: PosAlign.left)),
      PosColumn(text: ((printTransactionModel.transitionModel?.totalAmount ?? 0) + getTotalReturndAmount()).toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);

    // Return section
    if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ?? false) {
      List.generate(printTransactionModel.transitionModel?.salesReturns?.length ?? 0, (i) {
        bytes += generator.hr();
        if (!returnedDates.any((element) => element.isAtSameMomentAs(DateTime.tryParse(printTransactionModel.transitionModel?.salesReturns?[i].returnDate?.substring(0, 10) ?? '') ?? DateTime.now()))) {
          bytes += generator.row([
            PosColumn(text: 'Return-${DateFormat.yMd().format(DateTime.parse(printTransactionModel.transitionModel?.salesReturns?[i].returnDate ?? DateTime.now().toString()))}', width: 7, styles: const PosStyles(align: PosAlign.left, bold: true)),
            PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
            PosColumn(text: 'Total', width: 3, styles: const PosStyles(align: PosAlign.right, bold: true)),
          ]);
          bytes += generator.hr();
        }

        List.generate(printTransactionModel.transitionModel?.salesReturns?[i].salesReturnDetails?.length ?? 0, (index) {
          returnedDates.add(DateTime.tryParse(printTransactionModel.transitionModel?.salesReturns?[i].returnDate?.substring(0, 10) ?? '') ?? DateTime.now());
          final product = printTransactionModel.transitionModel?.salesReturns?[i].salesReturnDetails?[index];
          return bytes += generator.row([
            PosColumn(text: productName(detailsId: product?.saleDetailId ?? 0), width: 7, styles: const PosStyles(align: PosAlign.left)),
            PosColumn(text: product?.returnQty.toString() ?? 'Not Defined', width: 2, styles: const PosStyles(align: PosAlign.center)),
            PosColumn(text: "${(product?.returnAmount ?? 0)}", width: 3, styles: const PosStyles(align: PosAlign.right)),
          ]);
        });
      });
    }

    bytes += generator.hr();

    if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ?? false) {
      bytes += generator.row([
        PosColumn(text: 'Returned Amount', width: 8, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: '${getTotalReturndAmount()}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.row([
      PosColumn(text: 'Total Payable', width: 8, styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(text: printTransactionModel.transitionModel?.totalAmount.toString() ?? '', width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Payment Type', width: 8, styles: const PosStyles(align: PosAlign.left)),
      PosColumn(text: printTransactionModel.transitionModel?.paymentType?.name ?? 'N/A', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Received Amount', width: 8, styles: const PosStyles(align: PosAlign.left)),
      PosColumn(text: formatPointNumber(((printTransactionModel.transitionModel?.totalAmount ?? 0) - (printTransactionModel.transitionModel?.dueAmount ?? 0)) + (printTransactionModel.transitionModel?.changeAmount ?? 0)), width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);

    if ((printTransactionModel.transitionModel?.dueAmount ?? 0) > 0) {
      bytes += generator.row([
        PosColumn(text: 'Due Amount', width: 8, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: formatPointNumber(printTransactionModel.transitionModel?.dueAmount ?? 0), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    if ((printTransactionModel.transitionModel?.changeAmount ?? 0) > 0) {
      bytes += generator.row([
        PosColumn(text: 'Change Amount', width: 8, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: formatPointNumber(printTransactionModel.transitionModel?.changeAmount ?? 0), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr(ch: '=', linesAfter: 1);

    // Footer with multilingual support
    await addMultilingualText('Thank you!', styles: const PosStyles(align: PosAlign.center, bold: true));
    await addMultilingualText(printTransactionModel.transitionModel!.saleDate ?? '', styles: const PosStyles(align: PosAlign.center), linesAfter: 1);
    await addMultilingualText('Note: Goods once sold will not be taken back or exchanged.', styles: const PosStyles(align: PosAlign.center, bold: false), linesAfter: 1);

    bytes += generator.qrcode(companyWebsite);
    await addMultilingualText('Developed By: $companyName', styles: const PosStyles(align: PosAlign.center), linesAfter: 1);
    bytes += generator.cut();
    
    return bytes;
  }

  void _addProductRowAsImage(Generator generator, String productName, num price, num quantity, num amount) {
    // This method will be implemented to add product rows as images
    // For now, we'll add a placeholder
    // TODO: Implement image-based product row rendering
  }

  bool _isAscii(String input) {
    for (final c in input.runes) {
      if (c > 127) return false;
    }
    return true;
  }

  Future<List<int>> _textToImageBytes(
    Generator generator,
    String text, {
    PosStyles? styles,
  }) async {
    try {
      const double fontSize = 24.0;
      const double horizontalPadding = 10.0;
      const double lineSpacing = 1.2;

      const double printerWidthMm = 58.0;
      const double printerDpi = 203.0;

      final double printerWidthPx = (printerWidthMm * printerDpi / 25.4) - (horizontalPadding * 2);

      // Detect language and choose appropriate font
      String detectedLanguage = detectLanguageEnhanced(text);
      String fontFamily = _getFontFamilyForLanguage(detectedLanguage);
      
      print('Text: $text');
      print('Detected Language: $detectedLanguage');
      print('Font Family: $fontFamily');

      final textStyle = TextStyle(
        fontSize: fontSize,
        fontWeight: styles?.bold == true ? FontWeight.bold : FontWeight.normal,
        color: Colors.black,
        fontFamily: fontFamily,
        height: lineSpacing,
        // Ensure proper text rendering for Hindi/Marathi
        fontFeatures: [
          FontFeature.enable('liga'),
          FontFeature.enable('kern'),
        ],
        // Force text rendering for better Hindi/Marathi support
        textBaseline: TextBaseline.alphabetic,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        maxLines: 100,
        ellipsis: '...',
      );

      textPainter.layout(maxWidth: printerWidthPx);

      final double imageWidth = printerWidthPx + (horizontalPadding * 2);
      final double imageHeight = textPainter.height + 20.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
      );

      textPainter.paint(
        canvas,
        Offset(horizontalPadding, 10.0),
      );

      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(
        imageWidth.toInt(),
        imageHeight.toInt(),
      );

      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final image = img.decodePng(pngBytes)!;

      return generator.image(image);
    } catch (e) {
      print('Error in _textToImageBytes: $e');
      rethrow;
    }
  }

  String _getFontFamilyForLanguage(String language) {
    switch (language) {
      case 'hi':
      case 'mr':
        return 'NotoSans'; // Use existing NotoSans font for Hindi and Marathi
      case 'bn':
        return 'NotoSans'; // Bengali
      case 'ar':
        return 'NotoSans'; // Arabic
      case 'fr':
        return 'NotoSans'; // French
      default:
        return 'NotoSans'; // English and fallback
    }
  }

  /// Process Hindi/Marathi text for thermal printer compatibility
  String _processHindiMarathiText(String text) {
    // Common Hindi/Marathi words and their English transliterations
    Map<String, String> hindiMarathiTranslations = {
      // Company/Business terms
      'कंपनी': 'Company',
      'व्यापार': 'Business',
      'दुकान': 'Shop',
      'स्टोर': 'Store',
      
      // Invoice terms
      'बिल': 'Bill',
      'रसीद': 'Receipt',
      'चालान': 'Invoice',
      'खरीद': 'Purchase',
      'बिक्री': 'Sales',
      
      // Product terms
      'उत्पाद': 'Product',
      'सामान': 'Items',
      'माल': 'Goods',
      'वस्तु': 'Item',
      
      // Customer terms
      'ग्राहक': 'Customer',
      'खरीदार': 'Buyer',
      'ग्राहक नाम': 'Customer Name',
      
      // Amount terms
      'राशि': 'Amount',
      'कुल': 'Total',
      'जमा': 'Credit',
      'नामे': 'Debit',
      'शेष': 'Balance',
      'देय': 'Due',
      
      // Date/Time terms
      'तारीख': 'Date',
      'समय': 'Time',
      'दिनांक': 'Date',
      
      // Common words
      'नमस्ते': 'Namaste',
      'धन्यवाद': 'Thank You',
      'आभार': 'Thanks',
      'स्वागत': 'Welcome',
    };

    String processedText = text;
    
    // Replace common Hindi/Marathi words with English transliterations
    hindiMarathiTranslations.forEach((hindi, english) {
      processedText = processedText.replaceAll(hindi, english);
    });

    // If text still contains Devanagari characters, add a note
    if (RegExp(r'[\u0900-\u097F]').hasMatch(processedText)) {
      processedText = '[$processedText]'; // Wrap in brackets to indicate original text
    }

    return processedText;
  }
}
