import 'dart:async';
import 'dart:ui' as ui;

import 'package:barcode/barcode.dart' as barcode_pkg;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import '../constant.dart';
import '../model/sale_transaction_model.dart';
import 'model/print_transaction_model.dart';

class MultilingualThermalPrinter {
  /// Enhanced thermal printer with Marathi and Hindi support
  
  Future<void> printMultilingualSalesTicket({
    required PrintTransactionModel printTransactionModel, 
    required List<SalesDetails>? productList
  }) async {
    print('🚀 Starting multilingual sales ticket printing...');
    print('🌐 Selected Language: $selectedLanguage');
    
    bool? isConnected = await PrintBluetoothThermal.connectionStatus;
    if (isConnected == true) {
      print('✅ Printer connected, generating ticket...');
      List<int> bytes = await getMultilingualSalesTicket(
        printTransactionModel: printTransactionModel, 
        productList: productList
      );
      if (printTransactionModel.transitionModel?.salesDetails?.isNotEmpty ?? false) {
        print('📄 Sending ${bytes.length} bytes to printer...');
        await PrintBluetoothThermal.writeBytes(bytes);
        print('✅ Print job completed successfully');
        EasyLoading.showSuccess('Successfully Printed');
      } else {
        print('❌ No products found to print');
        toast('No Product Found');
      }
    } else {
      print('❌ Printer not connected');
      EasyLoading.showError('Unable to connect with printer');
    }
  }

  Future<List<int>> getMultilingualSalesTicket({
    required PrintTransactionModel printTransactionModel, 
    required List<SalesDetails>? productList
  }) async {
    print('📋 Generating multilingual sales ticket...');
    print('🌐 Language: $selectedLanguage');
    print('📦 Products: ${productList?.length ?? 0}');
    
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
    // Pre-process Hindi text to reduce word spacing
    String processedText = _processHindiTextSpacing(text);
    
    print('🌐 Processing text: "$processedText"');
    print('🔤 Is ASCII: ${_isAscii(processedText)}');
    
    if (_isAscii(processedText)) {
      print('✅ Using ASCII text directly');
      bytes += generator.text(processedText, styles: styles ?? const PosStyles(), linesAfter: linesAfter);
    } else {
        print('🔄 Converting non-ASCII text to image...');
        print('📝 Original text: $text');
        
        // For Hindi/Marathi text, convert directly to image
        try {
          print('🖼️ Converting to image with selected language: $selectedLanguage');
          final imageBytes = await _textToImageBytes(generator, processedText, styles: styles);
          print('✅ Image conversion successful, adding to print data');
          bytes += imageBytes;
          if (linesAfter > 0) {
            bytes += generator.feed(linesAfter);
          }
        } catch (e) {
          print('❌ Error in image conversion: $e');
          print('🔄 Falling back to English text...');
          // Fallback to English text
          String fallbackText = _getEnglishFallback(processedText);
          print('📝 Fallback text: $fallbackText');
          bytes += generator.text(fallbackText, styles: styles ?? const PosStyles(), linesAfter: linesAfter);
        }
      }
    }

    // Print invoice logo if available (above company name)
    final invoiceLogo = printTransactionModel.personalInformationModel.invoiceLogo;
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
      '${getLocalizedPrintText('Seller')} :${printTransactionModel.transitionModel?.user?.role == "shop-owner" ? getLocalizedPrintText('Admin') : printTransactionModel.transitionModel!.user?.name}',
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
        "${printTransactionModel.personalInformationModel.vatName ?? getLocalizedPrintText('VAT No :')}${printTransactionModel.personalInformationModel.vatNumber ?? ''}",
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    // Phone number
    await addMultilingualText(
      '${getLocalizedPrintText('Tel:')} ${printTransactionModel.personalInformationModel.phoneNumber ?? ''}',
      styles: const PosStyles(align: PosAlign.center),
      linesAfter: 1,
    );

    // Customer information
    await addMultilingualText(
      '${getLocalizedPrintText('Name')}: ${printTransactionModel.transitionModel?.party?.name ?? getLocalizedPrintText('Guest')}',
      styles: const PosStyles(align: PosAlign.left),
    );

    await addMultilingualText(
      '${getLocalizedPrintText('mobile')}: ${printTransactionModel.transitionModel?.party?.phone ?? getLocalizedPrintText('Not Provided')}',
      styles: const PosStyles(align: PosAlign.left),
    );

    await addMultilingualText(
      '${getLocalizedPrintText('Invoice')}: ${printTransactionModel.transitionModel?.invoiceNumber ?? getLocalizedPrintText('Not Provided')}',
      styles: const PosStyles(align: PosAlign.left),
      linesAfter: 1,
    );

    // Table headers - convert to images for Hindi/Marathi support
    await addMultilingualText(
      '${getLocalizedPrintText('Item')} | ${getLocalizedPrintText('Price')} | ${getLocalizedPrintText('Qty')} | ${getLocalizedPrintText('Amount')}',
      styles: const PosStyles(align: PosAlign.center, bold: true),
      linesAfter: 1,
    );
    bytes += generator.hr();

    // Product list with multilingual product names
    for (int index = 0; index < (productList?.length ?? 0); index++) {
      final productName = productList?[index].product?.productName ?? '';
      final productPrice = productList?[index].price ?? 0;
      final quantity = getProductQuantity(detailsId: productList?[index].id ?? 0);
      final amount = productPrice * quantity;

      // Use multilingual text function for all product rows
      await addMultilingualText(
        '$productName | $productPrice | ${formatPointNumber(quantity)} | $amount',
        styles: const PosStyles(align: PosAlign.left),
        linesAfter: 0,
      );
    }

    bytes += generator.hr();

    // Summary section - convert to multilingual text
    await addMultilingualText(
      '${getLocalizedPrintText('Subtotal')}: ${getTotalForOldInvoice()}',
      styles: const PosStyles(align: PosAlign.left),
      linesAfter: 0,
    );

    await addMultilingualText(
      '${getLocalizedPrintText('Discount')}: ${((printTransactionModel.transitionModel?.discountAmount ?? 0) + getReturndDiscountAmount()).toStringAsFixed(2)}',
      styles: const PosStyles(align: PosAlign.left),
      linesAfter: 0,
    );

    await addMultilingualText(
      '${getLocalizedPrintText('Service Charge')}: ${printTransactionModel.transitionModel?.serviceCharge ?? 0}',
      styles: const PosStyles(align: PosAlign.left),
      linesAfter: 0,
    );

    await addMultilingualText(
      '${printTransactionModel.transitionModel?.vat?.name ?? getLocalizedPrintText('VAT')}: ${printTransactionModel.transitionModel?.vatAmount ?? 0}',
      styles: const PosStyles(align: PosAlign.left),
      linesAfter: 0,
    );

    await addMultilingualText(
      '${getLocalizedPrintText('Shipping Charge')}: ${printTransactionModel.transitionModel?.shippingCharge ?? 0}',
      styles: const PosStyles(align: PosAlign.left),
      linesAfter: 0,
    );

    if (printTransactionModel.transitionModel?.roundingAmount != 0) {
      await addMultilingualText(
        '${getLocalizedPrintText('Total')}: ${formatPointNumber(printTransactionModel.transitionModel?.actualTotalAmount ?? 0)}',
        styles: const PosStyles(align: PosAlign.left),
        linesAfter: 0,
      );
      await addMultilingualText(
        '${getLocalizedPrintText('Rounding')}: ${!(printTransactionModel.transitionModel?.roundingAmount?.isNegative ?? true) ? '+' : ''}${formatPointNumber(printTransactionModel.transitionModel?.roundingAmount ?? 0)}',
        styles: const PosStyles(align: PosAlign.left),
        linesAfter: 0,
      );
    }

    await addMultilingualText(
      '${getLocalizedPrintText('Total Amount')}: ${((printTransactionModel.transitionModel?.totalAmount ?? 0) + getTotalReturndAmount()).toStringAsFixed(2)}',
      styles: const PosStyles(align: PosAlign.left),
      linesAfter: 0,
    );

    // Return section - convert to multilingual text
    if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ?? false) {
      for (int i = 0; i < (printTransactionModel.transitionModel?.salesReturns?.length ?? 0); i++) {
        bytes += generator.hr();
        if (!returnedDates.any((element) => element.isAtSameMomentAs(DateTime.tryParse(printTransactionModel.transitionModel?.salesReturns?[i].returnDate?.substring(0, 10) ?? '') ?? DateTime.now()))) {
          await addMultilingualText(
            '${getLocalizedPrintText('Return')}-${DateFormat.yMd().format(DateTime.parse(printTransactionModel.transitionModel?.salesReturns?[i].returnDate ?? DateTime.now().toString()))} | ${getLocalizedPrintText('Qty')} | ${getLocalizedPrintText('Total')}',
            styles: const PosStyles(align: PosAlign.center, bold: true),
            linesAfter: 1,
          );
          bytes += generator.hr();
        }

        for (int index = 0; index < (printTransactionModel.transitionModel?.salesReturns?[i].salesReturnDetails?.length ?? 0); index++) {
          returnedDates.add(DateTime.tryParse(printTransactionModel.transitionModel?.salesReturns?[i].returnDate?.substring(0, 10) ?? '') ?? DateTime.now());
          final product = printTransactionModel.transitionModel?.salesReturns?[i].salesReturnDetails?[index];
          await addMultilingualText(
            '${productName(detailsId: product?.saleDetailId ?? 0)} | ${product?.returnQty.toString() ?? getLocalizedPrintText('Not Provided')} | ${(product?.returnAmount ?? 0)}',
            styles: const PosStyles(align: PosAlign.left),
            linesAfter: 0,
          );
        }
      }
    }

    bytes += generator.hr();

    if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ?? false) {
      await addMultilingualText(
        '${getLocalizedPrintText('Returned Amount')}: ${getTotalReturndAmount()}',
        styles: const PosStyles(align: PosAlign.left),
        linesAfter: 0,
      );
    }

    await addMultilingualText(
      '${getLocalizedPrintText('Total Payable')}: ${printTransactionModel.transitionModel?.totalAmount.toString() ?? ''}',
      styles: const PosStyles(align: PosAlign.left, bold: true),
      linesAfter: 0,
    );

    await addMultilingualText(
      '${getLocalizedPrintText('Payment Type')}: ${(printTransactionModel.transitionModel?.isSplitPayment == true) ? getLocalizedPrintText('Split') : (printTransactionModel.transitionModel?.paymentType?.name ?? getLocalizedPrintText('N/A'))}',
      styles: const PosStyles(align: PosAlign.left),
      linesAfter: 0,
    );

    await addMultilingualText(
      '${getLocalizedPrintText('Received Amount')}: ${formatPointNumber(((printTransactionModel.transitionModel?.totalAmount ?? 0) - (printTransactionModel.transitionModel?.dueAmount ?? 0)) + (printTransactionModel.transitionModel?.changeAmount ?? 0))}',
      styles: const PosStyles(align: PosAlign.left),
      linesAfter: 0,
    );

    if ((printTransactionModel.transitionModel?.dueAmount ?? 0) > 0) {
      await addMultilingualText(
        '${getLocalizedPrintText('Due Amount')}: ${formatPointNumber(printTransactionModel.transitionModel?.dueAmount ?? 0)}',
        styles: const PosStyles(align: PosAlign.left),
        linesAfter: 0,
      );
    }

    if ((printTransactionModel.transitionModel?.changeAmount ?? 0) > 0) {
      await addMultilingualText(
        '${getLocalizedPrintText('Change Amount')}: ${formatPointNumber(printTransactionModel.transitionModel?.changeAmount ?? 0)}',
        styles: const PosStyles(align: PosAlign.left),
        linesAfter: 0,
      );
    }

    bytes += generator.hr(ch: '=', linesAfter: 1);

    // Footer with multilingual support
    await addMultilingualText(getLocalizedPrintText('Thank you!'), styles: const PosStyles(align: PosAlign.center, bold: true));
    await addMultilingualText(printTransactionModel.transitionModel!.saleDate ?? '', styles: const PosStyles(align: PosAlign.center), linesAfter: 1);
    await addMultilingualText(getLocalizedPrintText('Note: Goods once sold will not be taken back or exchanged.'), styles: const PosStyles(align: PosAlign.center, bold: false), linesAfter: 1);

    // Print UPI QR code if UPI ID is configured (center aligned)
    final prefs = await SharedPreferences.getInstance();
    final upiId = prefs.getString('upi_id') ?? '';
    
    if (upiId.isNotEmpty) {
      // Generate UPI payment string
      final totalAmount = printTransactionModel.transitionModel?.totalAmount ?? 0;
      final upiPaymentString = 'upi://pay?pa=$upiId&pn=${printTransactionModel.personalInformationModel.companyName ?? "Merchant"}&am=${totalAmount.toStringAsFixed(2)}&cu=INR&tn=Payment';
      
      // Print UPI QR code (center aligned)
      await addMultilingualText(
        getLocalizedPrintText('Scan to Pay via UPI'),
        styles: const PosStyles(align: PosAlign.center, bold: true),
        linesAfter: 1,
      );
      bytes += generator.qrcode(upiPaymentString);
      await addMultilingualText(
        upiId,
        styles: const PosStyles(align: PosAlign.center),
        linesAfter: 1,
      );
    }
    
    await addMultilingualText('${getLocalizedPrintText('Developed By:')} $companyName', styles: const PosStyles(align: PosAlign.center), linesAfter: 1);
    bytes += generator.cut();
    
    print('✅ Multilingual sales ticket generation completed');
    print('📄 Total bytes generated: ${bytes.length}');
    
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

      // Use the selected language instead of detecting
      String fontFamily = _getFontFamilyForLanguage(selectedLanguage ?? 'hi');
      
      print('🖼️ Starting image conversion for text: "$text"');
      print('🌐 Selected Language: $selectedLanguage');
      print('🔤 Font Family: $fontFamily');
      print('📏 Printer width in pixels: $printerWidthPx');

      final textStyle = TextStyle(
        fontSize: fontSize,
        fontWeight: styles?.bold == true ? FontWeight.bold : FontWeight.normal,
        color: Colors.black,
        fontFamily: fontFamily,
        height: lineSpacing,
        // Fix Hindi text spacing by disabling problematic font features
        fontFeatures: [
          FontFeature.disable('liga'), // Disable ligatures to prevent spacing issues
          FontFeature.disable('kern'), // Disable kerning to prevent spacing issues
        ],
        // Force text rendering for better Hindi/Marathi support
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: -0.5, // Reduce letter spacing for Hindi text
        wordSpacing: -2.0,   // Reduce word spacing significantly for Hindi text
      );

      print('🎨 Creating TextPainter...');
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        maxLines: 100,
        ellipsis: '...',
      );

      // Set textDirection before layout - using ui.TextDirection
      textPainter.textDirection = ui.TextDirection.ltr;
      
      print('📐 Laying out text...');
      textPainter.layout(maxWidth: printerWidthPx);

      final double imageWidth = printerWidthPx + (horizontalPadding * 2);
      final double imageHeight = textPainter.height + 20.0;
      print('📏 Image dimensions: ${imageWidth}x${imageHeight}');

      print('🎨 Creating canvas...');
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
      );

      // Fill background with white
      canvas.drawRect(
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
        Paint()..color = Colors.white,
      );

      print('🖌️ Painting text on canvas...');
      textPainter.paint(
        canvas,
        Offset(horizontalPadding, 10.0),
      );

      print('🖼️ Converting to image...');
      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(
        imageWidth.toInt(),
        imageHeight.toInt(),
      );

      print('💾 Converting to byte data...');
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final image = img.decodePng(pngBytes)!;

      print('✅ Image conversion completed successfully');
      return generator.image(image);
    } catch (e) {
      print('Error in _textToImageBytes: $e');
      rethrow;
    }
  }

  /// Process Hindi text to reduce word spacing
  String _processHindiTextSpacing(String text) {
    if (text.isEmpty) return text;
    
    // Check if text contains Hindi/Devanagari characters
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
      // For Hindi text, reduce spaces between words
      // Replace multiple spaces with single space
      String processed = text.replaceAll(RegExp(r'\s+'), ' ');
      
      // For specific Hindi phrases, reduce spacing further
      Map<String, String> spacingFixes = {
        'विक्रेता :': 'विक्रेता:',
        'नाम:': 'नाम:',
        'मोबाइल:': 'मोबाइल:',
        'चालान:': 'चालान:',
        'कुल राशि:': 'कुल राशि:',
        'कुल देय:': 'कुल देय:',
        'प्राप्त राशि:': 'प्राप्त राशि:',
        'भुगतान प्रकार:': 'भुगतान प्रकार:',
        'शिपिंग शुल्क:': 'शिपिंग शुल्क:',
        'उप-योग:': 'उप-योग:',
        'छूट:': 'छूट:',
        'वैट:': 'वैट:',
      };
      
      spacingFixes.forEach((original, fixed) {
        processed = processed.replaceAll(original, fixed);
      });
      
      return processed;
    }
    
    return text;
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

  /// Get English fallback text for Hindi/Marathi text
  String _getEnglishFallback(String hindiMarathiText) {
    // Map common Hindi/Marathi words to English equivalents
    Map<String, String> fallbackMap = {
      'विक्रेता': 'Seller',
      'प्रशासक': 'Admin',
      'नाम': 'Name',
      'मोबाइल': 'Mobile',
      'चालान': 'Invoice',
      'वस्तु': 'Item',
      'कीमत': 'Price',
      'मात्रा': 'Qty',
      'राशि': 'Amount',
      'उप-योग': 'Subtotal',
      'छूट': 'Discount',
      'वैट': 'VAT',
      'शिपिंग शुल्क': 'Shipping Charge',
      'कुल': 'Total',
      'गोलाई': 'Rounding',
      'कुल राशि': 'Total Amount',
      'वापसी': 'Return',
      'वापसी राशि': 'Returned Amount',
      'कुल देय': 'Total Payable',
      'भुगतान प्रकार': 'Payment Type',
      'प्राप्त राशि': 'Received Amount',
      'बकाया राशि': 'Due Amount',
      'बदलाव राशि': 'Change Amount',
      'धन्यवाद!': 'Thank you!',
      'विकसित:': 'Developed By:',
      'टेल:': 'Tel:',
      'वैट नंबर:': 'VAT No :',
      'अतिथि': 'Guest',
      'उपलब्ध नहीं': 'Not Provided',
      'नाव': 'Name',
      'वस्तू': 'Item',
      'किंमत': 'Price',
      'प्रमाण': 'Qty',
      'रक्कम': 'Amount',
      'सवलत': 'Discount',
      'व्हॅट': 'VAT',
      'एकूण': 'Total',
      'एकूण रक्कम': 'Total Amount',
      'परतावा': 'Return',
      'परतावा रक्कम': 'Returned Amount',
      'एकूण देय': 'Total Payable',
      'पेमेंट प्रकार': 'Payment Type',
      'मिळालेली रक्कम': 'Received Amount',
      'बाकी रक्कम': 'Due Amount',
      'बदल रक्कम': 'Change Amount',
      'पाहुणा': 'Guest',
      'उपलब्ध नाही': 'Not Provided',
    };

    String result = hindiMarathiText;
    fallbackMap.forEach((hindi, english) {
      result = result.replaceAll(hindi, english);
    });

    // If still contains Hindi/Marathi characters, return a generic message
    if (RegExp(r'[\u0900-\u097F]').hasMatch(result)) {
      return 'Multilingual Text';
    }

    return result;
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
