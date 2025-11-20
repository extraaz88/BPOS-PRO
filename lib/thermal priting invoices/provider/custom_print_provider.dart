import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode/barcode.dart' as barcode_pkg;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../constant.dart';
import '../model/print_transaction_model.dart';

final printerPurchaseProviderNotifier = ChangeNotifierProvider((ref) => PrinterPurchase());

class PrinterPurchase extends ChangeNotifier {
  List<BluetoothInfo> availableBluetoothDevices = [];

  Future<void> getBluetooth() async {
    final List<BluetoothInfo> bluetooths = await PrintBluetoothThermal.pairedBluetooths;
    availableBluetoothDevices = bluetooths;
    notifyListeners();
  }

  Future<bool> setConnect(String mac) async {
    bool status = false;
    final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    if (result == true) {
      status = true;
    }
    notifyListeners();
    return status;
  }

  Future<bool> printCustomTicket({required PrintPurchaseTransactionModel printTransactionModel, required String data}) async {
    bool isPrinted = false;
    bool? isConnected = await PrintBluetoothThermal.connectionStatus;
    if (isConnected == true) {
      List<int> bytes = await customPrintTicket(printTransactionModel: printTransactionModel, data: data);
      await PrintBluetoothThermal.writeBytes(bytes);
      isPrinted = true;
    } else {
      isPrinted = false;
    }
    notifyListeners();
    return isPrinted;
  }

  Future<List<int>> customPrintTicket({
    required PrintPurchaseTransactionModel printTransactionModel,
    required String data,
  }) async {
    List<int> bytes = [];

    try {
      CapabilityProfile profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);

      Future<void> addText(String text, {PosStyles? styles, int linesAfter = 0}) async {
        if (_isAscii(text)) {
          bytes += generator.text(
            text,
            linesAfter: linesAfter,
            styles: const PosStyles(
              align: PosAlign.center,
            ),
          );
        } else {
          final imageBytes = await _textToImageBytes(
            generator,
            text,
            styles: const PosStyles(
              align: PosAlign.center,
            ),
          );
          bytes += imageBytes;
          if (linesAfter > 0) {
            bytes += generator.feed(linesAfter);
          }
        }
      }

      // Add company name
      final companyNameText = printTransactionModel.personalInformationModel.companyName ?? '';
      bytes += generator.text(
        companyNameText,
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1,
      );

      // Add address
      final address = printTransactionModel.personalInformationModel.address ?? '';
      if (address.isNotEmpty) {
        bytes += generator.text(
          address,
          styles: const PosStyles(align: PosAlign.center),
        );
      }

      // Add phone number
      final phoneNumber = printTransactionModel.personalInformationModel.phoneNumber ?? '';
      if (phoneNumber.isNotEmpty) {
        bytes += generator.text(
          'Tel: $phoneNumber',
          styles: const PosStyles(align: PosAlign.center),
          linesAfter: printTransactionModel.personalInformationModel.vatNumber?.trim().isNotEmpty == true ? 0 : 1,
        );
      }

      // Add VAT information if available
      final vatNumber = printTransactionModel.personalInformationModel.vatNumber;
      if (vatNumber != null && vatNumber.trim().isNotEmpty) {
        final vatName = printTransactionModel.personalInformationModel.vatName;
        final label = vatName != null ? '$vatName:' : 'Shop GST:';
        bytes += generator.text(
          '$label $vatNumber',
          styles: const PosStyles(align: PosAlign.center),
          linesAfter: 1,
        );
      }

      await addText(
        data,
        styles: const PosStyles(
          align: PosAlign.center,
        ),
        linesAfter: 1,
      );

      // Add footer
      bytes += generator.text('Thank you!', styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text(
        'Note: Goods once sold will not be taken back or exchanged.',
        styles: const PosStyles(align: PosAlign.center, bold: false),
        linesAfter: 1,
      );

      bytes += generator.text(
        'Developed By: $companyName',
        styles: const PosStyles(align: PosAlign.center),
        linesAfter: 1,
      );

      bytes += generator.cut();
      return bytes;
    } catch (e) {
      print('Error generating print ticket: $e');
      rethrow;
    }
  }

  /// 🔹 Print barcode products as images
  /// Label size: 28mm height x 25mm breadth
  /// Zero gap between labels (continuous print like rough23.dart)
  Future<bool> printBarcodeProductsAsImage({required List<Map<String, dynamic>> products, required String businessName}) async {
    bool printed = false;
    try {
      final bool? isConnected = await PrintBluetoothThermal.connectionStatus;
      if (isConnected != true) {
        print('Printer not connected');
        return false;
      }

      final CapabilityProfile profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);

      // Collect all label images first
      List<img.Image> labelImages = [];
      const double printerDpi = 203.0;
      const double labelHeightMm = 14.0;
      const double gapBetweenLabelsMm = 6.5; 
      final int labelHeightPx = ((labelHeightMm * printerDpi) / 25.4).round();
      final int labelWidthPx = ((25.0 * printerDpi) / 25.4).round();

      for (final item in products) {
        final String name = (item['name'] ?? '').toString();
        final String code = (item['code'] ?? '').toString();
        final String price = (item['price'] ?? '').toString();
        final int qty = (item['qty'] is int) ? item['qty'] as int : int.tryParse(item['qty'].toString()) ?? 1;

        for (int i = 0; i < qty; i++) {
          // Create label image with proper dimensoins
          final labelImage = await _generateProductBarcodeLayout(
            productName: name,
            barcode: code,
            price: price,
            businessName: businessName,
          );

          if (labelImage != null) {
            labelImages.add(labelImage);
          } else {
            // Fallback: create a simple image for text-based labelses
            final fallbackImage = img.Image(width: labelWidthPx, height: labelHeightPx);
            img.fillRect(fallbackImage, x1: 0, y1: 0, x2: labelWidthPx - 1, y2: labelHeightPx - 1, color: img.ColorUint8.rgb(255, 255, 255));
            labelImages.add(fallbackImage);
          }
        }
      }
      // Print each label individually with reseet after every 2 prints
      if (labelImages.isNotEmpty) {
        for (int i = 0; i < labelImages.length; i++) {
          print('Printing label ${i + 1} of ${labelImages.length}');
          
          List<int> labelBytes = [];
          
          // Reset printer after every 2 prints
          // Pattern: Reset on first print (i==0) and then after every 2 prints (i==2,4,6...)
          // This means: Reset when i % 2 == 0 (prints 1, 3, 5, 7...)
          // This ensures proper label positioning and prevents drift
          bool shouldReset = (i % 2 == 0);
          
          if (shouldReset) {
            print('🔄 Resetting printer - Print ${i + 1} of ${labelImages.length}');
            
            // Full printer reset sequeencae
            labelBytes += Uint8List.fromList([0x1B, 0x40]); // Initialize printer (ESC @)
            labelBytes += Uint8List.fromList([0x1B, 0x33, 0x00]); // ESC 3 0 - Line spacing = 0
            labelBytes += Uint8List.fromList([0x1B, 0x61, 0x00]); // ESC a 0 - Left alignment
            labelBytes += Uint8List.fromList([0x1D, 0x50, 0x00, 0x00]); // GS P 0 0 - Reset to default
            
            // Wait a bit after reset to ensure printer is ready
            await Future.delayed(const Duration(milliseconds: 300));
          } else {
            // For non-reset prints, just set line spacing
            labelBytes += Uint8List.fromList([0x1B, 0x33, 0x00]); // ESC 3 0 - Line spacing = 0
          }
          
          // Print single label image
          labelBytes += generator.image(labelImages[i]);
          
          // Add 2.1mm gap after label (except for last label)
          if (i < labelImages.length - 1) {
            final int gapHeightPx = ((gapBetweenLabelsMm * printerDpi) / 25.4).round();
            final gapImage = img.Image(width: labelWidthPx, height: gapHeightPx);
            img.fillRect(gapImage, x1: 0, y1: 0, x2: labelWidthPx - 1, y2: gapHeightPx - 1, color: img.ColorUint8.rgb(255, 255, 255));
            labelBytes += generator.image(gapImage);
          }
          
          // Send print command for this label
          await PrintBluetoothThermal.writeBytes(labelBytes);
          
          // Wait 2 seconds before next print (except for last label)
          if (i < labelImages.length - 1) {
            print('Waiting 2 seconds before next print...');
            await Future.delayed(const Duration(seconds: 2));
          }
        }
        
        // Final cut after all labels printed
        final cutBytes = Uint8List.fromList([0x1D, 0x56, 0x00]); // Partial cut (GS V 0)
        await PrintBluetoothThermal.writeBytes(cutBytes);
      }
      
      printed = true;
    } catch (e) {
      print('printBarcodeProductsAsImage error: $e');
    }

    notifyListeners();
    return printed;
  }

  /// 🔹 Generate label layout matching image format
  /// Label size: 28mm height x 25mm width (2.5cm breadth)
  /// Format: Product name - Price -> Barcode (business name removed)
  Future<img.Image?> _generateProductBarcodeLayout({
    required String productName,
    required String barcode,
    required String price,
    String? businessName,
  }) async {
    try {
      // Label size
      const double printerDpi = 203.0;
      const double labelWidthMm = 25.0;
      const double labelHeightMm = 14.0;

      final int layoutWidth = ((labelWidthMm * printerDpi) / 25.4).round();
      final int layoutHeight = ((labelHeightMm * printerDpi) / 25.4).round();

      // Create layout
      final img.Image layout = img.Image(width: layoutWidth, height: layoutHeight);

      // ---- ADD BORDER (required layout) ----
      const int border = 3;

      // Top border
      img.fillRect(layout,
          x1: 0, y1: 0, x2: layoutWidth - 1, y2: border, color: img.ColorRgb8(0, 0, 0));

      // Bottom border
      img.fillRect(layout,
          x1: 0,
          y1: layoutHeight - border,
          x2: layoutWidth - 1,
          y2: layoutHeight - 1,
          color: img.ColorRgb8(0, 0, 0));

      // Left border
      img.fillRect(layout,
          x1: 0, y1: 0, x2: border, y2: layoutHeight - 1, color: img.ColorRgb8(0, 0, 0));

      // Right border
      img.fillRect(layout,
          x1: layoutWidth - border,
          y1: 0,
          x2: layoutWidth - 1,
          y2: layoutHeight - 1,
          color: img.ColorRgb8(0, 0, 0));

      // ---- LOAD BARCODE ----
      if (barcode.trim().isEmpty) {
        print('[_generateProductBarcodeLayout] WARNING: Barcode code is empty for product: $productName');
        return layout; // Return layout with border only if barcode is empty
      }

      final barcodeImg = await _generateBarcodeImage(barcode);
      if (barcodeImg == null) {
        print('[_generateProductBarcodeLayout] ERROR: Failed to generate barcode image for code: $barcode');
        return layout; // Return layout with border only if barcode generation fails
      }

      // Resize barcode to fit inside border
      final int innerWidth = layoutWidth - (border * 2);
      final int innerHeight = layoutHeight - (border * 2);

      final resizedBarcode = img.copyResize(
        barcodeImg,
        width: innerWidth,
        height: innerHeight,
        interpolation: img.Interpolation.linear,
      );

      // Center the barcode inside border
      final barcodeX = border;
      final barcodeY = border;

      img.compositeImage(layout, resizedBarcode, dstX: barcodeX, dstY: barcodeY);

      return layout;
    } catch (e) {
      print('_generateProductBarcodeLayout Error: $e');
      return null;
    }
  }

  /// Helper: Draws Flutter text to img.Image
  Future<img.Image?> _textToImageUi(
    String text, {
    required int width,
    required int height,
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.normal,
    bool alignCenter = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bgPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: 'Arial',
          height: 1.3,
        ),
      ),
      textAlign: alignCenter ? TextAlign.center : TextAlign.left,
      textDirection: TextDirection.ltr,
      maxLines: 10,
    );

    textPainter.layout(maxWidth: width.toDouble());
    // Proper center alignment
    final offsetX = alignCenter ? (width - textPainter.width) / 2 : 0.0;
    final offsetY = (height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(offsetX, offsetY));

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(width, height);
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    return img.decodePng(pngBytes);
  }

  /// 🔹 Generate barcode as image using barcode package
  /// Generates barcode suitable for 25mm width label, fits in 14mm height label
  Future<img.Image?> _generateBarcodeImage(String code) async {
    try {
      final bc = barcode_pkg.Barcode.code128();

      // For 25mm width label, calculate appropriate barcode size
      // Label width: 25mm = ~200 pixels at 203 DPI
      // Full width for barcode (no padding)
      // Height: ~10mm for barcode bars (fits in 14mm label after text)
      const double printerDpi = 203.0;
      const double barcodeWidthMm = 25.0; // Full width
      const double barcodeHeightMm = 10.0; // Height for barcode bars (fits in 14mm label)
      
      final int imgW = ((barcodeWidthMm * printerDpi) / 25.4).round();
      final int imgH = ((barcodeHeightMm * printerDpi) / 25.4).round();

      // Generate SVG string with proper dimensions
      final svgString = bc.toSvg(code, width: imgW.toDouble(), height: imgH.toDouble(), drawText: false);

      print('[_generateBarcodeImage] Generating barcode for code=$code, size=${imgW}x${imgH}');

      // Create image with white background
      final image = img.Image(width: imgW, height: imgH);
      img.fillRect(
        image,
        x1: 0,
        y1: 0,
        x2: image.width - 1,
        y2: image.height - 1,
        color: img.ColorUint8.rgb(255, 255, 255),
      );

      // Parse SVG string and draw barcode rects onto the image
      final rectsParsed = _drawBarcodesFromSvg(image, svgString);

      if (rectsParsed == 0) {
        print('[_generateBarcodeImage] No <rect> elements parsed from SVG for code=$code. SVG preview:\n${svgString.substring(0, svgString.length > 1000 ? 1000 : svgString.length)}');
      } else {
        print('[_generateBarcodeImage] Parsed $rectsParsed rects for code=$code');
      }

      return image;
    } catch (e) {
      print('_generateBarcodeImage error: $e');
      return null;
    }
  }

  /// 🔹 Draw barcode pattern on image by parsing SVG rect or path elements
  /// Returns number of rects parsed (0 means nothing found)
  int _drawBarcodesFromSvg(img.Image image, String svgString) {
    try {
      int rectCount = 0;

      // First try to parse explicit <rect ... /> elements
      final rectRegExp = RegExp(
        r'<rect[^>]*x="([\d.\-]+)"[^>]*y="([\d.\-]+)"[^>]*width="([\d.\-]+)"[^>]*height="([\d.\-]+)"[^>]*/?>',
        caseSensitive: false,
      );

      for (final match in rectRegExp.allMatches(svgString)) {
        rectCount++;
        final x = double.tryParse(match.group(1) ?? '') ?? 0.0;
        final y = double.tryParse(match.group(2) ?? '') ?? 0.0;
        final w = double.tryParse(match.group(3) ?? '') ?? 0.0;
        final h = double.tryParse(match.group(4) ?? '') ?? 0.0;

        int ix = x.round();
        int iy = y.round();
        int iw = w.round();
        int ih = h.round();

        if (iw <= 0 || ih <= 0) continue;

        if (ix < 0) {
          iw += ix;
          ix = 0;
        }
        if (iy < 0) {
          ih += iy;
          iy = 0;
        }
        if (ix >= image.width) continue;
        if (iy >= image.height) continue;

        if (ix + iw > image.width) iw = image.width - ix;
        if (iy + ih > image.height) ih = image.height - iy;

        if (iw > 0 && ih > 0) {
          final x1 = ix;
          final y1 = iy;
          final x2 = ix + iw - 1;
          final y2 = iy + ih - 1;
          img.fillRect(image, x1: x1, y1: y1, x2: x2, y2: y2, color: img.ColorUint8.rgb(0, 0, 0));
        }
      }

      // If no <rect> found, try parsing path segments like:
      // M 0.00000 0.00000 h 5.94059 v 80.00000 h -5.94059 z ...
      if (rectCount == 0) {
        final pathRegExp = RegExp(
          r'M\s*([\-0-9.]+)\s+([\-0-9.]+)\s*h\s*([\-0-9.]+)\s*v\s*([\-0-9.]+)\s*h\s*([\-0-9.]+)\s*z',
          caseSensitive: false,
        );

        for (final match in pathRegExp.allMatches(svgString)) {
          // Each match represents one rectangular bar
          final x = double.tryParse(match.group(1) ?? '') ?? 0.0;
          final y = double.tryParse(match.group(2) ?? '') ?? 0.0;
          final w = double.tryParse(match.group(3) ?? '') ?? 0.0; // positive horizontal length
          final h = double.tryParse(match.group(4) ?? '') ?? 0.0; // vertical length (height)

          int ix = x.round();
          int iy = y.round();
          int iw = w.abs().round();
          int ih = h.abs().round();

          if (iw <= 0 || ih <= 0) continue;

          if (ix < 0) {
            iw += ix;
            ix = 0;
          }
          if (iy < 0) {
            ih += iy;
            iy = 0;
          }
          if (ix >= image.width) continue;
          if (iy >= image.height) continue;

          if (ix + iw > image.width) iw = image.width - ix;
          if (iy + ih > image.height) ih = image.height - iy;

          if (iw > 0 && ih > 0) {
            final x1 = ix;
            final y1 = iy;
            final x2 = ix + iw - 1;
            final y2 = iy + ih - 1;
            img.fillRect(image, x1: x1, y1: y1, x2: x2, y2: y2, color: img.ColorUint8.rgb(0, 0, 0));
            rectCount++;
          }
        }
      }

      print('Parsed $rectCount rectangles from SVG (rect/path)');
      return rectCount;
    } catch (e) {
      print('_drawBarcodesFromSvg error: $e');
      return 0;
    }
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
      const double fontSize = 26.0;
      const double horizontalPadding = 10.0;
      const double lineSpacing = 1.2;

      const double printerWidthMm = 58.0;
      const double printerDpi = 203.0;

      final double printerWidthPx = (printerWidthMm * printerDpi / 25.4) - (horizontalPadding * 2);
      const String fallbackFont = 'Arial Unicode MS';

      final textStyle = TextStyle(
        fontSize: fontSize,
        fontWeight: styles?.bold == true ? FontWeight.bold : FontWeight.normal,
        color: Colors.black,
        fontFamily: fallbackFont,
        height: lineSpacing,
        fontFeatures: [
          FontFeature.disable('liga'),
          FontFeature.disable('kern'),
        ],
        letterSpacing: -0.5,
        wordSpacing: -2.0,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: 100,
        ellipsis: '...',
      );

      textPainter.layout(maxWidth: printerWidthPx);

      final double imageWidth = printerWidthPx + (horizontalPadding * 2);
      final double imageHeight = textPainter.height + 20.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, imageWidth, imageHeight));

      textPainter.paint(canvas, Offset(horizontalPadding, 10.0));

      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(imageWidth.toInt(), imageHeight.toInt());

      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final image = img.decodePng(pngBytes)!;

      return generator.image(image);
    } catch (e) {
      print('Error in _textToImageBytes: $e');
      rethrow;
    }
  }
}   