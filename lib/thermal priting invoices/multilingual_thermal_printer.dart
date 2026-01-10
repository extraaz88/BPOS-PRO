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
import '../model/add_to_cart_model.dart';
import '../model/sale_transaction_model.dart';
import 'model/print_transaction_model.dart';

// Helper class to represent text segments
class _TextSegment {
  final String text;
  final bool isDevanagari;

  _TextSegment(this.text, this.isDevanagari);
}

// Helper class for batched text
class _BatchedTextLine {
  final String text;
  final PosStyles? styles;
  final int linesAfter;

  _BatchedTextLine(this.text, this.styles, this.linesAfter);
}

class MultilingualThermalPrinter {
  /// Enhanced thermal printer with Marathi and Hindi support

  // Batch text lines for faster conversion
  final List<_BatchedTextLine> _textBatch = [];

  Future<void> printMultilingualSalesTicket(
      {required PrintTransactionModel printTransactionModel,
      required List<SalesDetails>? productList,
      List<AddToCartModel>? cartItems}) async {
    // Load language from SharedPreferences to ensure it's up to date
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString('lang') ?? 'en';
    updateSelectedLanguage(savedLanguageCode);

    print('🚀 Starting multilingual sales ticket printing...');
    print('🌐 Selected Language: $selectedLanguage');

    bool? isConnected = await PrintBluetoothThermal.connectionStatus;
    if (isConnected == true) {
      print('✅ Printer connected, generating ticket...');
      List<int> bytes = await getMultilingualSalesTicket(
          printTransactionModel: printTransactionModel,
          productList: productList,
          cartItems: cartItems);
      if (printTransactionModel.transitionModel?.salesDetails?.isNotEmpty ??
          false) {
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

  Future<List<int>> getMultilingualSalesTicket(
      {required PrintTransactionModel printTransactionModel,
      required List<SalesDetails>? productList,
      List<AddToCartModel>? cartItems}) async {
    print('📋 Generating multilingual sales ticket...');
    print('🌐 Language: $selectedLanguage');
    print('📦 Products: ${productList?.length ?? 0}');

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

    // Split bilingual text into Hindi/Marathi and ASCII segments
    List<_TextSegment> _splitBilingualText(String text) {
      List<_TextSegment> segments = [];
      StringBuffer currentSegment = StringBuffer();
      bool? currentIsDevanagari;

      for (int i = 0; i < text.length; i++) {
        String char = text[i];
        bool isDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(char);

        // Check for separator " / " between Hindi and English
        if (i < text.length - 3 && text.substring(i, i + 3) == ' / ') {
          // Save current segment if not empty
          if (currentSegment.isNotEmpty) {
            segments.add(_TextSegment(
                currentSegment.toString(), currentIsDevanagari ?? false));
            currentSegment.clear();
          }
          // Add separator as ASCII
          segments.add(_TextSegment(' / ', false));
          i += 2; // Skip the separator characters
          continue;
        }

        // If character type matches current segment, add to it
        if (currentIsDevanagari == null ||
            currentIsDevanagari == isDevanagari) {
          currentSegment.write(char);
          currentIsDevanagari = isDevanagari;
        } else {
          // Type changed - save current segment and start new one
          if (currentSegment.isNotEmpty) {
            segments.add(
                _TextSegment(currentSegment.toString(), currentIsDevanagari));
            currentSegment.clear();
          }
          currentSegment.write(char);
          currentIsDevanagari = isDevanagari;
        }
      }

      // Add remaining segment
      if (currentSegment.isNotEmpty) {
        segments.add(_TextSegment(
            currentSegment.toString(), currentIsDevanagari ?? false));
      }

      return segments;
    }

    // Helper function to flush batched text lines
    Future<void> _flushTextBatch(Generator generator) async {
      if (_textBatch.isEmpty) return;

      // Check if batch contains any Devanagari text
      bool hasDevanagari = _textBatch
          .any((line) => RegExp(r'[\u0900-\u097F]').hasMatch(line.text));

      if (!hasDevanagari) {
        // All ASCII - print directly
        for (var line in _textBatch) {
          bytes += generator.text(line.text,
              styles: line.styles ?? const PosStyles(),
              linesAfter: line.linesAfter);
        }
      } else {
        // Convert batch to single image for faster processing
        try {
          final batchedImageBytes =
              await _batchTextToImageBytes(generator, _textBatch);
          bytes += batchedImageBytes;
        } catch (e) {
          // Fallback: convert individually
          for (var line in _textBatch) {
            final processedText = _processHindiTextSpacing(line.text);
            bool hasDev = RegExp(r'[\u0900-\u097F]').hasMatch(processedText);
            if (hasDev) {
              try {
                final imageBytes = await _textToImageBytes(
                    generator, processedText,
                    styles: line.styles);
                bytes += imageBytes;
                if (line.linesAfter > 0) {
                  bytes += generator.feed(line.linesAfter);
                }
              } catch (e2) {
                String fallback = _getEnglishFallback(processedText);
                bytes += generator.text(fallback,
                    styles: line.styles ?? const PosStyles(),
                    linesAfter: line.linesAfter);
              }
            } else {
              bytes += generator.text(processedText,
                  styles: line.styles ?? const PosStyles(),
                  linesAfter: line.linesAfter);
            }
          }
        }
      }

      _textBatch.clear();
    }

    // Helper function to add multilingual text
    // This function intelligently splits text into ASCII (numbers, English) and non-ASCII (Hindi/Marathi) parts
    Future<void> addMultilingualText(String text,
        {PosStyles? styles, int linesAfter = 0}) async {
      // Pre-process Hindi text to reduce word spacing
      String processedText = _processHindiTextSpacing(text);

      // Check if text contains Hindi/Marathi characters
      bool hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(processedText);

      if (!hasDevanagari) {
        // Pure ASCII text - print directly (no batching needed)
        bytes += generator.text(processedText,
            styles: styles ?? const PosStyles(), linesAfter: linesAfter);
      } else {
        // Add to batch for grouped conversion
        _textBatch.add(_BatchedTextLine(processedText, styles, linesAfter));

        // Flush batch if it gets too large (max 20 lines per batch for maximum performance)
        if (_textBatch.length >= 20) {
          await _flushTextBatch(generator);
        }
      }
    }

    // Helper function to create column-aligned image for label and value
    Future<List<int>> _createColumnAlignedImage(
        String label, String value, PosStyles? styles) async {
      const double printerWidthMm = 58.0;
      // Use slightly lower DPI for faster processing (180 instead of 203)
      const double printerDpi = 180.0;
      // Slightly smaller font to prevent clipping for Marathi/Hindi headers/rows
      const double fontSize = 22.0;
      const double horizontalPadding = 10.0;

      final double printerWidthPx = (printerWidthMm * printerDpi / 25.4);
      final double imageWidth = printerWidthPx;

      // Calculate column widths (8:4 ratio from PosColumn)
      final double labelColumnWidth = (imageWidth * 8 / 12) - horizontalPadding;
      final double valueColumnWidth = (imageWidth * 4 / 12);

      String fontFamily = _getFontFamilyForLanguage(selectedLanguage ?? 'hi');

      final labelStyle = TextStyle(
        fontSize: fontSize,
        fontWeight: styles?.bold == true ? FontWeight.bold : FontWeight.normal,
        color: Colors.black,
        fontFamily: fontFamily,
        fontFamilyFallback: [
          'NotoSans',
          'Arial Unicode MS'
        ], // Add fallback fonts for better Marathi support
        fontFeatures: [
          FontFeature.disable('liga'),
          FontFeature.disable('kern'),
        ],
        letterSpacing: -1.0,
        wordSpacing: -4.0,
      );

      final valueStyle = TextStyle(
        fontSize: fontSize,
        fontWeight: styles?.bold == true ? FontWeight.bold : FontWeight.normal,
        color: Colors.black,
        fontFamily: fontFamily,
        fontFamilyFallback: [
          'NotoSans',
          'Arial Unicode MS'
        ], // Add fallback fonts for better Marathi support
        fontFeatures: [
          FontFeature.disable('liga'),
          FontFeature.disable('kern'),
        ],
        letterSpacing: -1.0,
        wordSpacing: -4.0,
      );

      // Layout label and value separately
      final labelPainter = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textAlign: TextAlign.left,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      );
      labelPainter.layout(maxWidth: labelColumnWidth);

      final valuePainter = TextPainter(
        text: TextSpan(text: value, style: valueStyle),
        textAlign: TextAlign.right,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      );
      valuePainter.layout(maxWidth: valueColumnWidth);

      final double imageHeight = (labelPainter.height > valuePainter.height
              ? labelPainter.height
              : valuePainter.height) +
          4.0;

      // Create canvas and paint both texts
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
      );

      canvas.drawRect(
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
        Paint()..color = Colors.white,
      );

      // Paint label at left
      labelPainter.paint(canvas, Offset(horizontalPadding, 1.0));

      // Paint value at right (aligned to value column)
      final valueX = imageWidth - valueColumnWidth - horizontalPadding;
      valuePainter.paint(canvas, Offset(valueX, 1.0));

      final picture = recorder.endRecording();
      final uiImage =
          await picture.toImage(imageWidth.toInt(), imageHeight.toInt());

      // Skip PNG, go directly to RGBA for faster processing
      final byteData =
          await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        throw Exception('Failed to convert image to byte data');
      }

      final rgbaBytes = byteData.buffer.asUint8List();
      final image = img.Image(
        width: imageWidth.toInt(),
        height: imageHeight.toInt(),
      );

      // Ultra-fast grayscale conversion - simplified threshold
      final int pixelCount = image.width * image.height;
      final int length = rgbaBytes.length;
      for (int i = 0; i < pixelCount; i++) {
        final int index = i * 4;
        if (index + 2 >= length) break;

        // Simplified: use green channel as approximation (faster than full luminance)
        final int g = rgbaBytes[index + 1];
        final int a = rgbaBytes[index + 3];

        // Simple threshold: if green channel * alpha is dark enough, make it black
        final int pixelValue = ((g * a) ~/ 255) < 128 ? 0 : 255;

        final int x = i % image.width;
        final int y = i ~/ image.width;
        image.setPixel(x, y, img.ColorRgb8(pixelValue, pixelValue, pixelValue));
      }

      return generator.image(image);
    }

    // Helper function to add a row with label and value, handling Devanagari text
    // Ensures consistent spacing between label and value (matching PosColumn 8:4 ratio)
    Future<void> addMultilingualRow(String label, String value,
        {bool bold = false}) async {
      // Check if label contains Devanagari
      bool hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(label);

      if (hasDevanagari) {
        // Use column-aligned image for proper spacing
        final imageBytes = await _createColumnAlignedImage(
          label,
          value,
          PosStyles(align: PosAlign.left, bold: bold),
        );
        bytes += imageBytes;
      } else {
        // Use PosColumn for ASCII-only labels
        bytes += generator.row([
          PosColumn(
              text: label,
              width: 8,
              styles: PosStyles(
                align: PosAlign.left,
                bold: bold,
              )),
          PosColumn(
              text: value,
              width: 4,
              styles: PosStyles(
                align: PosAlign.right,
                bold: bold,
              )),
        ]);
      }
    }

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
    String sellerLabel = getBilingualPrintText('Seller');
    String adminLabel =
        printTransactionModel.transitionModel?.user?.role == "shop-owner"
            ? getBilingualPrintText('Admin')
            : '';
    await addMultilingualText(
      '$sellerLabel :${adminLabel.isNotEmpty ? adminLabel : printTransactionModel.transitionModel!.user?.name}',
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
      String vatLabel =
          printTransactionModel.personalInformationModel.vatName ??
              getBilingualPrintText('VAT No :');
      await addMultilingualText(
        "$vatLabel${printTransactionModel.personalInformationModel.vatNumber ?? ''}",
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    // Phone number
    await addMultilingualText(
      '${getBilingualPrintText('Tel:')} ${printTransactionModel.personalInformationModel.phoneNumber ?? ''}',
      styles: const PosStyles(align: PosAlign.center),
      linesAfter: 1,
    );

    // Customer information
    String nameLabel = getBilingualPrintText('Name');
    String guestLabel = printTransactionModel.transitionModel?.party?.name ??
        getBilingualPrintText('Guest');
    await addMultilingualText(
      '$nameLabel: $guestLabel',
      styles: const PosStyles(align: PosAlign.left),
    );

    String mobileLabel = getBilingualPrintText('mobile');
    String notProvidedLabel =
        printTransactionModel.transitionModel?.party?.phone ??
            getBilingualPrintText('Not Provided');
    await addMultilingualText(
      '$mobileLabel: $notProvidedLabel',
      styles: const PosStyles(align: PosAlign.left),
    );

    String invoiceLabel = getBilingualPrintText('Invoice');
    String invoiceNotProvided =
        printTransactionModel.transitionModel?.invoiceNumber ??
            getBilingualPrintText('Not Provided');
    await addMultilingualText(
      '$invoiceLabel: $invoiceNotProvided',
      styles: const PosStyles(align: PosAlign.left),
    );

    final prefsForGst = await SharedPreferences.getInstance();
    final String gstNumber = prefsForGst.getString("gst") ?? "";
    final String ifscCode = prefsForGst.getString("ifsc") ?? "";

    if (gstNumber.isNotEmpty) {
      await addMultilingualText(
        'GST: $gstNumber',
        styles: const PosStyles(align: PosAlign.left),
      );
    }
    if (ifscCode.isNotEmpty) {
      await addMultilingualText(
        'IFSC: $ifscCode',
        styles: const PosStyles(align: PosAlign.left),
      );
    }

    // Flush any batched text before printing header row
    // This ensures company name and other info prints before the header
    await _flushTextBatch(generator);

    // Helper function to create header row with 4 columns (Item, RS., Qty, Amount)
    Future<List<int>> _createHeaderRowImage(
        String item, String rs, String qty, String amount) async {
      const double printerWidthMm = 58.0;
      // Use slightly lower DPI for faster processing (180 instead of 203)
      const double printerDpi = 180.0;
      // Slightly smaller font to prevent clipping
      const double fontSize = 22.0;
      const double horizontalPadding = 10.0;

      final double printerWidthPx = (printerWidthMm * printerDpi / 25.4);
      final double imageWidth = printerWidthPx;

      // Calculate column widths (5:2:2:3 ratio from PosColumn, total = 12)
      // Account for horizontal padding on both sides
      final double availableWidth = imageWidth - (horizontalPadding * 2);
      final double itemColumnWidth = (availableWidth * 5 / 12);
      final double rsColumnWidth = (availableWidth * 2 / 12);
      final double qtyColumnWidth = (availableWidth * 2 / 12);
      final double amountColumnWidth = (availableWidth * 3 / 12);

      String fontFamily = _getFontFamilyForLanguage(selectedLanguage ?? 'hi');

      final textStyle = TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontFamily: fontFamily,
        fontFamilyFallback: [
          'NotoSans',
          'Arial Unicode MS'
        ], // Add fallback fonts for better Marathi support
        fontFeatures: [
          FontFeature.disable('liga'),
          FontFeature.disable('kern'),
        ],
        // Loosen spacing to avoid character clipping (e.g., रक्कम)
        letterSpacing: -0.3,
        wordSpacing: -1.0,
      );

      // Layout each column text with proper max width
      final itemPainter = TextPainter(
        text: TextSpan(text: item, style: textStyle),
        textAlign: TextAlign.left,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      );
      itemPainter.layout(maxWidth: itemColumnWidth);

      final rsPainter = TextPainter(
        text: TextSpan(text: rs, style: textStyle),
        textAlign: TextAlign.center,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      );
      rsPainter.layout(maxWidth: rsColumnWidth);

      final qtyPainter = TextPainter(
        text: TextSpan(text: qty, style: textStyle),
        textAlign: TextAlign.center,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      );
      qtyPainter.layout(maxWidth: qtyColumnWidth);

      final amountPainter = TextPainter(
        text: TextSpan(text: amount, style: textStyle),
        textAlign: TextAlign.right,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      );
      amountPainter.layout(maxWidth: amountColumnWidth);

      final double imageHeight = [
            itemPainter.height,
            rsPainter.height,
            qtyPainter.height,
            amountPainter.height
          ].reduce((a, b) => a > b ? a : b) +
          4.0;

      // Create canvas and paint all texts
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
      );

      canvas.drawRect(
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
        Paint()..color = Colors.white,
      );

      // Calculate column start positions
      // Match English print alignment - no extra spacing adjustment
      const double columnSpacing =
          0.0; // No spacing adjustment to match English format
      double currentX = horizontalPadding;

      // Paint Item (left aligned in first column)
      itemPainter.paint(canvas, Offset(currentX, 1.0));
      currentX +=
          itemColumnWidth + columnSpacing; // Reduce gap after Item column

      // Paint RS. (center aligned in second column, moved left)
      final rsX = currentX + (rsColumnWidth - rsPainter.width) / 2;
      rsPainter.paint(canvas, Offset(rsX, 1.0));
      currentX += rsColumnWidth + columnSpacing; // Reduce gap after RS. column

      // Paint Qty (center aligned in third column, moved left)
      final qtyX = currentX + (qtyColumnWidth - qtyPainter.width) / 2;
      qtyPainter.paint(canvas, Offset(qtyX, 1.0));
      currentX += qtyColumnWidth + columnSpacing; // Reduce gap after Qty column

      // Paint Amount (right aligned in fourth column, moved left)
      final amountX = currentX + amountColumnWidth - amountPainter.width;
      amountPainter.paint(canvas, Offset(amountX, 1.0));

      final picture = recorder.endRecording();
      final uiImage =
          await picture.toImage(imageWidth.toInt(), imageHeight.toInt());

      // Skip PNG, go directly to RGBA for faster processing
      final byteData =
          await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        throw Exception('Failed to convert image to byte data');
      }

      final rgbaBytes = byteData.buffer.asUint8List();
      final image = img.Image(
        width: imageWidth.toInt(),
        height: imageHeight.toInt(),
      );

      // Ultra-fast grayscale conversion - simplified threshold
      final int pixelCount = image.width * image.height;
      final int length = rgbaBytes.length;
      for (int i = 0; i < pixelCount; i++) {
        final int index = i * 4;
        if (index + 2 >= length) break;

        // Simplified: use green channel as approximation (faster than full luminance)
        final int g = rgbaBytes[index + 1];
        final int a = rgbaBytes[index + 3];

        // Simple threshold: if green channel * alpha is dark enough, make it black
        final int pixelValue = ((g * a) ~/ 255) < 128 ? 0 : 255;

        final int x = i % image.width;
        final int y = i ~/ image.width;
        image.setPixel(x, y, img.ColorRgb8(pixelValue, pixelValue, pixelValue));
      }

      return generator.image(image);
    }

    // Helper function to create product row as image (5:2:2:3) for Devanagari
    Future<List<int>> _createProductRowImage(
        String item, String price, String qty, String amount) async {
      const double printerWidthMm = 58.0;
      const double printerDpi = 180.0;
      const double fontSize = 22.0;
      const double horizontalPadding = 10.0;

      final double printerWidthPx = (printerWidthMm * printerDpi / 25.4);
      final double imageWidth = printerWidthPx;

      // Column ratios 5:2:2:3 to match header and English layout
      final double availableWidth = imageWidth - (horizontalPadding * 2);
      final double itemColumnWidth = (availableWidth * 5 / 12);
      final double priceColumnWidth = (availableWidth * 2 / 12);
      final double qtyColumnWidth = (availableWidth * 2 / 12);
      final double amountColumnWidth = (availableWidth * 3 / 12);

      String fontFamily = _getFontFamilyForLanguage(selectedLanguage ?? 'hi');

      final textStyle = TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: Colors.black,
        fontFamily: fontFamily,
        fontFamilyFallback: ['NotoSans', 'Arial Unicode MS'],
        fontFeatures: [
          FontFeature.disable('liga'),
          FontFeature.disable('kern'),
        ],
        letterSpacing: -0.3,
        wordSpacing: -1.0,
      );

      final itemPainter = TextPainter(
        text: TextSpan(text: item, style: textStyle),
        textAlign: TextAlign.left,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: itemColumnWidth);

      final pricePainter = TextPainter(
        text: TextSpan(text: price, style: textStyle),
        textAlign: TextAlign.center,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: priceColumnWidth);

      final qtyPainter = TextPainter(
        text: TextSpan(text: qty, style: textStyle),
        textAlign: TextAlign.center,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: qtyColumnWidth);

      final amountPainter = TextPainter(
        text: TextSpan(text: amount, style: textStyle),
        textAlign: TextAlign.right,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: amountColumnWidth);

      final double imageHeight = [
            itemPainter.height,
            pricePainter.height,
            qtyPainter.height,
            amountPainter.height
          ].reduce((a, b) => a > b ? a : b) +
          4.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
      );

      canvas.drawRect(
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
        Paint()..color = Colors.white,
      );

      const double columnSpacing = 0.0;
      double currentX = horizontalPadding;

      itemPainter.paint(canvas, Offset(currentX, 1.0));
      currentX += itemColumnWidth + columnSpacing;

      final priceX = currentX + (priceColumnWidth - pricePainter.width) / 2;
      pricePainter.paint(canvas, Offset(priceX, 1.0));
      currentX += priceColumnWidth + columnSpacing;

      final qtyX = currentX + (qtyColumnWidth - qtyPainter.width) / 2;
      qtyPainter.paint(canvas, Offset(qtyX, 1.0));
      currentX += qtyColumnWidth + columnSpacing;

      final amountX = currentX + amountColumnWidth - amountPainter.width;
      amountPainter.paint(canvas, Offset(amountX, 1.0));

      final picture = recorder.endRecording();
      final uiImage =
          await picture.toImage(imageWidth.toInt(), imageHeight.toInt());

      final byteData =
          await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        throw Exception('Failed to convert image to byte data');
      }

      final rgbaBytes = byteData.buffer.asUint8List();
      final image = img.Image(
        width: imageWidth.toInt(),
        height: imageHeight.toInt(),
      );

      final int pixelCount = image.width * image.height;
      final int length = rgbaBytes.length;
      for (int i = 0; i < pixelCount; i++) {
        final int index = i * 4;
        if (index + 2 >= length) break;
        final int g = rgbaBytes[index + 1];
        final int a = rgbaBytes[index + 3];
        final int pixelValue = ((g * a) ~/ 255) < 128 ? 0 : 255;
        final int x = i % image.width;
        final int y = i ~/ image.width;
        image.setPixel(x, y, img.ColorRgb8(pixelValue, pixelValue, pixelValue));
      }

      return generator.image(image);
    }

    // Table header with proper column alignment
    // Check if any header text contains Devanagari
    final itemText = getBilingualPrintText('Item');
    // We no longer show the RS (price) column in print
    final rsText = ''; // getBilingualPrintText('RS.');
    final qtyText = getBilingualPrintText('Qty');
    final amountText = getBilingualPrintText('Amount');

    bool hasDevanagariInHeader =
        RegExp(r'[\u0900-\u097F]').hasMatch(itemText) ||
            RegExp(r'[\u0900-\u097F]').hasMatch(rsText) ||
            RegExp(r'[\u0900-\u097F]').hasMatch(qtyText) ||
            RegExp(r'[\u0900-\u097F]').hasMatch(amountText);

    if (hasDevanagariInHeader) {
      // Use custom header row image for proper column alignment
      final headerBytes =
          await _createHeaderRowImage(itemText, rsText, qtyText, amountText);
      bytes += headerBytes;
      bytes += generator.feed(1);
    } else {
      // Use PosColumn for ASCII-only headers (hide RS column)
      bytes += generator.row([
        PosColumn(
            text: itemText,
            width: 7,
            styles: const PosStyles(
                align: PosAlign.left,
                bold: true,
                height: PosTextSize.size1,
                width: PosTextSize.size1)),
        PosColumn(
            text: qtyText,
            width: 2,
            styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                height: PosTextSize.size1,
                width: PosTextSize.size1)),
        PosColumn(
            text: amountText,
            width: 3,
            styles: const PosStyles(
                align: PosAlign.right,
                bold: true,
                height: PosTextSize.size1,
                width: PosTextSize.size1)),
      ]);
    }
    bytes += generator.hr();

    // Product list with multilingual product names - using column-based alignment
    for (int index = 0; index < (productList?.length ?? 0); index++) {
      final productName = productList?[index].product?.productName ?? '';
      final productPrice = productList?[index].price ?? 0;
      final quantity =
          getProductQuantity(detailsId: productList?[index].id ?? 0);
      final amount = productPrice * quantity;

      // Check if product name contains Devanagari
      bool hasDevanagariInProduct =
          RegExp(r'[\u0900-\u097F]').hasMatch(productName);

      final quantityWithUnit = getQuantityWithUnit(
          detailsId: productList?[index].id ?? 0, quantity: quantity);

      if (hasDevanagariInProduct) {
        // Use image-based row for proper column alignment (5:2:2:3)
        final rowBytes = await _createProductRowImage(
            productName, '$productPrice', quantityWithUnit, '$amount');
        bytes += rowBytes;
      } else {
        // Use column-based layout for ASCII-only product names
        bytes += generator.row([
          PosColumn(
              text: productName,
              width: 5,
              styles: const PosStyles(
                align: PosAlign.left,
                height: PosTextSize.size1,
                width: PosTextSize.size1,
              )),
          PosColumn(
              text: '$productPrice',
              width: 2,
              styles: const PosStyles(
                align: PosAlign.center,
                height: PosTextSize.size1,
                width: PosTextSize.size1,
              )),
          PosColumn(
              text: quantityWithUnit,
              width: 2,
              styles: const PosStyles(
                align: PosAlign.center,
                height: PosTextSize.size1,
                width: PosTextSize.size1,
              )),
          PosColumn(
              text: '$amount',
              width: 3,
              styles: const PosStyles(
                align: PosAlign.right,
                height: PosTextSize.size1,
                width: PosTextSize.size1,
              )),
        ]);
      }
    }

    // Flush any batched text before horizontal rule
    await _flushTextBatch(generator);
    bytes += generator.hr();

    // Summary section - using helper function that handles Devanagari text
    await addMultilingualRow(
      getBilingualPrintText('Subtotal'),
      '${getTotalForOldInvoice()}',
    );
    await addMultilingualRow(
      getBilingualPrintText('Discount'),
      ((printTransactionModel.transitionModel?.discountAmount ?? 0) +
              getReturndDiscountAmount())
          .toStringAsFixed(2),
    );
    await addMultilingualRow(
      getBilingualPrintText('Service Charge'),
      '${printTransactionModel.transitionModel?.serviceCharge ?? 0}',
    );
    String vatName = printTransactionModel.transitionModel?.vat?.name ??
        getBilingualPrintText('VAT');
    await addMultilingualRow(
      vatName,
      '${printTransactionModel.transitionModel?.vatAmount ?? 0}',
    );
    await addMultilingualRow(
      getBilingualPrintText('Shipping Charge'),
      '${printTransactionModel.transitionModel?.shippingCharge ?? 0}',
    );

    if (printTransactionModel.transitionModel?.roundingAmount != 0) {
      await addMultilingualRow(
        getBilingualPrintText('Total'),
        formatPointNumber(
            printTransactionModel.transitionModel?.actualTotalAmount ?? 0),
      );
      await addMultilingualRow(
        getBilingualPrintText('Rounding'),
        '${!(printTransactionModel.transitionModel?.roundingAmount?.isNegative ?? true) ? '+' : ''}${formatPointNumber(printTransactionModel.transitionModel?.roundingAmount ?? 0)}',
      );
    }

    await addMultilingualRow(
      getBilingualPrintText('Total Amount'),
      ((printTransactionModel.transitionModel?.totalAmount ?? 0) +
              getTotalReturndAmount())
          .toStringAsFixed(2),
    );

    // Return section - convert to multilingual text
    if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ??
        false) {
      for (int i = 0;
          i <
              (printTransactionModel.transitionModel?.salesReturns?.length ??
                  0);
          i++) {
        bytes += generator.hr();
        if (!returnedDates.any((element) => element.isAtSameMomentAs(
            DateTime.tryParse(printTransactionModel
                        .transitionModel?.salesReturns?[i].returnDate
                        ?.substring(0, 10) ??
                    '') ??
                DateTime.now()))) {
          await addMultilingualText(
            '${getBilingualPrintText('Return')}-${DateFormat.yMd().format(DateTime.parse(printTransactionModel.transitionModel?.salesReturns?[i].returnDate ?? DateTime.now().toString()))} | ${getBilingualPrintText('Qty')} | ${getBilingualPrintText('Total')}',
            styles: const PosStyles(align: PosAlign.center, bold: true),
            linesAfter: 1,
          );
          bytes += generator.hr();
        }

        for (int index = 0;
            index <
                (printTransactionModel.transitionModel?.salesReturns?[i]
                        .salesReturnDetails?.length ??
                    0);
            index++) {
          returnedDates.add(DateTime.tryParse(printTransactionModel
                      .transitionModel?.salesReturns?[i].returnDate
                      ?.substring(0, 10) ??
                  '') ??
              DateTime.now());
          final product = printTransactionModel
              .transitionModel?.salesReturns?[i].salesReturnDetails?[index];
          String notProvidedLabel = product?.returnQty.toString() ??
              getBilingualPrintText('Not Provided');
          await addMultilingualText(
            '${productName(detailsId: product?.saleDetailId ?? 0)} | $notProvidedLabel | ${(product?.returnAmount ?? 0)}',
            styles: const PosStyles(align: PosAlign.left),
            linesAfter: 0,
          );
        }
      }
    }

    bytes += generator.hr();

    if (printTransactionModel.transitionModel?.salesReturns?.isNotEmpty ??
        false) {
      await addMultilingualRow(
        getBilingualPrintText('Returned Amount'),
        '${getTotalReturndAmount()}',
      );
    }

    await addMultilingualRow(
      getBilingualPrintText('Total Payable'),
      printTransactionModel.transitionModel?.totalAmount.toString() ?? '',
      bold: true,
    );

    String paymentTypeLabel = getBilingualPrintText('Payment Type');
    String paymentTypeValue =
        (printTransactionModel.transitionModel?.isSplitPayment == true)
            ? getBilingualPrintText('Split')
            : (printTransactionModel.transitionModel?.paymentType?.name ??
                getBilingualPrintText('N/A'));
    await addMultilingualRow(
      paymentTypeLabel,
      paymentTypeValue,
    );

    await addMultilingualRow(
      getBilingualPrintText('Received Amount'),
      formatPointNumber(
          ((printTransactionModel.transitionModel?.totalAmount ?? 0) -
                  (printTransactionModel.transitionModel?.dueAmount ?? 0)) +
              (printTransactionModel.transitionModel?.changeAmount ?? 0)),
    );

    if ((printTransactionModel.transitionModel?.dueAmount ?? 0) > 0) {
      await addMultilingualRow(
        getBilingualPrintText('Due Amount'),
        formatPointNumber(
            printTransactionModel.transitionModel?.dueAmount ?? 0),
      );
    }

    if ((printTransactionModel.transitionModel?.changeAmount ?? 0) > 0) {
      await addMultilingualRow(
        getBilingualPrintText('Change Amount'),
        formatPointNumber(
            printTransactionModel.transitionModel?.changeAmount ?? 0),
      );
    }

    // Flush any batched text before footer
    await _flushTextBatch(generator);
    bytes += generator.hr(ch: '=', linesAfter: 1);

    // Footer with bilingual support
    await addMultilingualText(getBilingualPrintText('Thank you!'),
        styles: const PosStyles(align: PosAlign.center, bold: true));
    await addMultilingualText(
        printTransactionModel.transitionModel!.saleDate ?? '',
        styles: const PosStyles(align: PosAlign.center),
        linesAfter: 1);
    await addMultilingualText(
        getBilingualPrintText(
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
      // Flush any batched text before QR code
      await _flushTextBatch(generator);
      await addMultilingualText(
        getBilingualPrintText('Scan to Pay via UPI'),
        styles: const PosStyles(align: PosAlign.center, bold: true),
        linesAfter: 1,
      );
      await _flushTextBatch(generator);
      bytes += generator.qrcode(upiPaymentString);
      await addMultilingualText(
        upiId,
        styles: const PosStyles(align: PosAlign.center),
        linesAfter: 1,
      );
    }

    await addMultilingualText(
        '${getBilingualPrintText('Developed By:')} $companyName',
        styles: const PosStyles(align: PosAlign.center),
        linesAfter: 1);
    // Flush any remaining batched text before cutting
    await _flushTextBatch(generator);

    bytes += generator.cut();

    print('✅ Multilingual sales ticket generation completed');
    print('📄 Total bytes generated: ${bytes.length}');

    return bytes;
  }

  void _addProductRowAsImage(Generator generator, String productName, num price,
      num quantity, num amount) {
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

  // Batch convert multiple text lines into a single image for faster processing
  Future<List<int>> _batchTextToImageBytes(
    Generator generator,
    List<_BatchedTextLine> lines,
  ) async {
    try {
      const double fontSize = 24.0;
      const double horizontalPadding = 10.0;
      const double lineSpacing = 1.2;
      const double lineHeight = fontSize * lineSpacing;

      const double printerWidthMm = 58.0;
      // Use slightly lower DPI for faster processing (180 instead of 203)
      // Still looks good but processes faster
      const double printerDpi = 180.0;
      final double printerWidthPx =
          (printerWidthMm * printerDpi / 25.4) - (horizontalPadding * 2);
      final double imageWidth =
          (printerWidthMm * printerDpi / 25.4).clamp(1.0, 1000.0);

      String fontFamily = _getFontFamilyForLanguage(selectedLanguage ?? 'hi');

      // Create TextPainters for all lines
      final List<TextPainter> painters = [];
      double totalHeight = 2.0; // Start with small padding

      final bool isMarathi = (selectedLanguage == 'mr');

      for (var line in lines) {
        FontWeight fontWeight =
            line.styles?.bold == true ? FontWeight.w700 : FontWeight.w400;

        final textStyle = TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.black,
          fontFamily: fontFamily,
          fontFamilyFallback: ['NotoSans', 'Arial Unicode MS'],
          height: lineSpacing,
          fontFeatures: [
            FontFeature.disable('liga'),
            FontFeature.disable('kern'),
          ],
          textBaseline: TextBaseline.alphabetic,
          letterSpacing: isMarathi ? -0.3 : -1.0,
          wordSpacing: isMarathi ? -1.0 : -4.0,
        );

        final textPainter = TextPainter(
          text: TextSpan(text: line.text, style: textStyle),
          textAlign: TextAlign.left,
          maxLines: 100,
          textDirection: ui.TextDirection.ltr,
        );

        textPainter.layout(maxWidth: printerWidthPx);
        painters.add(textPainter);
        totalHeight += textPainter.height + (line.linesAfter * lineHeight);
      }

      final double imageHeight = totalHeight.clamp(1.0, 10000.0);

      // Create single canvas for all lines
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
      );

      canvas.drawRect(
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
        Paint()..color = Colors.white,
      );

      // Paint all lines
      double currentY = 1.0;
      for (int i = 0; i < painters.length; i++) {
        final painter = painters[i];
        final line = lines[i];

        double xOffset = horizontalPadding;
        if (line.styles?.align == PosAlign.center) {
          xOffset = (imageWidth - painter.width) / 2;
        } else if (line.styles?.align == PosAlign.right) {
          xOffset = imageWidth - painter.width - horizontalPadding;
        }

        painter.paint(canvas, Offset(xOffset, currentY));
        currentY += painter.height + (line.linesAfter * lineHeight);
      }

      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(
        imageWidth.toInt(),
        imageHeight.toInt(),
      );

      // Skip PNG, go directly to RGBA for faster processing
      final byteData =
          await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        throw Exception('Failed to convert image to byte data');
      }

      final rgbaBytes = byteData.buffer.asUint8List();
      final image = img.Image(
        width: imageWidth.toInt(),
        height: imageHeight.toInt(),
      );

      // Ultra-fast grayscale conversion - simplified threshold
      final int pixelCount = image.width * image.height;
      final int length = rgbaBytes.length;
      for (int i = 0; i < pixelCount; i++) {
        final int index = i * 4;
        if (index + 2 >= length) break;

        // Simplified: use green channel as approximation (faster than full luminance)
        final int g = rgbaBytes[index + 1];
        final int a = rgbaBytes[index + 3];

        // Simple threshold: if green channel * alpha is dark enough, make it black
        final int pixelValue = ((g * a) ~/ 255) < 128 ? 0 : 255;

        final int x = i % image.width;
        final int y = i ~/ image.width;
        image.setPixel(x, y, img.ColorRgb8(pixelValue, pixelValue, pixelValue));
      }

      return generator.image(image);
    } catch (e) {
      print('Error in _batchTextToImageBytes: $e');
      rethrow;
    }
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
      // Use slightly lower DPI for faster processing (180 instead of 203)
      // Still looks good but processes faster
      const double printerDpi = 180.0;

      final double printerWidthPx =
          (printerWidthMm * printerDpi / 25.4) - (horizontalPadding * 2);

      String fontFamily = _getFontFamilyForLanguage(selectedLanguage ?? 'hi');

      FontWeight fontWeight =
          styles?.bold == true ? FontWeight.w700 : FontWeight.w400;

      final bool isMarathi = (selectedLanguage == 'mr');

      final textStyle = TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: Colors.black,
        fontFamily: fontFamily,
        fontFamilyFallback: ['NotoSans', 'Arial Unicode MS'],
        height: lineSpacing,
        fontFeatures: [
          FontFeature.disable('liga'),
          FontFeature.disable('kern'),
        ],
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: isMarathi ? -0.3 : -1.0,
        wordSpacing: isMarathi ? -1.0 : -4.0,
      );

      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.left,
        maxLines: 100,
        textDirection: ui.TextDirection.ltr,
      );

      textPainter.layout(maxWidth: printerWidthPx);

      final double imageWidth =
          (printerWidthMm * printerDpi / 25.4).clamp(1.0, 1000.0);
      final double imageHeight = (textPainter.height + 2.0).clamp(1.0, 10000.0);

      if (imageWidth <= 0 || imageHeight <= 0) {
        throw Exception(
            'Invalid image dimensions: ${imageWidth}x${imageHeight}');
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
      );

      canvas.drawRect(
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
        Paint()..color = Colors.white,
      );

      double xOffset = horizontalPadding;
      if (styles?.align == PosAlign.center) {
        xOffset = (imageWidth - textPainter.width) / 2;
      } else if (styles?.align == PosAlign.right) {
        xOffset = imageWidth - textPainter.width - horizontalPadding;
      }

      const double yOffset = 1.0;
      textPainter.paint(canvas, Offset(xOffset, yOffset));

      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(
        imageWidth.toInt(),
        imageHeight.toInt(),
      );

      // Skip PNG, go directly to RGBA for faster processing
      final byteData =
          await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        throw Exception('Failed to convert image to byte data');
      }

      final rgbaBytes = byteData.buffer.asUint8List();
      final image = img.Image(
        width: imageWidth.toInt(),
        height: imageHeight.toInt(),
      );

      // Ultra-fast grayscale conversion - simplified threshold
      final int pixelCount = image.width * image.height;
      final int length = rgbaBytes.length;
      for (int i = 0; i < pixelCount; i++) {
        final int index = i * 4;
        if (index + 2 >= length) break;

        // Simplified: use green channel as approximation (faster than full luminance)
        final int g = rgbaBytes[index + 1];
        final int a = rgbaBytes[index + 3];

        // Simple threshold: if green channel * alpha is dark enough, make it black
        final int pixelValue = ((g * a) ~/ 255) < 128 ? 0 : 255;

        final int x = i % image.width;
        final int y = i ~/ image.width;
        image.setPixel(x, y, img.ColorRgb8(pixelValue, pixelValue, pixelValue));
      }

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
      processedText =
          '[$processedText]'; // Wrap in brackets to indicate original text
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
