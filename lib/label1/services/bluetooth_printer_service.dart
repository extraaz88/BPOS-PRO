import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/print_settings.dart';
import '../models/printer_device.dart';

class BluetoothPrinterService {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  Future<void> ensureBluetoothEnabled() async {
    // bluetooth_print does not expose an enable API; rely on system state.
    // We keep this for symmetry if we later add an implementation.
  }

  Future<void> ensurePermissions() async {
    // Request necessary runtime permissions on Android 12+
    final List<Permission> toRequest = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse, // legacy for Android <= 11 scanning
    ];
    final statuses = await toRequest.request();
    // If any is permanently denied, we can't proceed; but we'll not throw here.
    if (statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied)) {
      // Best-effort: prompt app settings if needed.
      // ignore: unawaited_futures
      openAppSettings();
    }
  }

  Future<List<PrinterDevice>> listBondedDevices() async {
    await ensurePermissions();
    await ensureBluetoothEnabled();
    final devices = await _bluetooth.getBondedDevices();
    devices.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    return devices
        .map((d) => PrinterDevice(address: d.address, name: d.name ?? 'Unknown'))
        .toList();
  }

  Future<void> printLabelTspl(PrintSettings settings) async {
    // Backwards compatibility: route to generic method.
    return printLabel(settings);
  }

  Future<void> printLabel(PrintSettings settings) async {
    if (settings.printerAddress.isEmpty) {
      throw StateError('No printer selected');
    }
    await ensurePermissions();
    await ensureBluetoothEnabled();

    final Uint8List bytes;
    switch (settings.printerLanguage) {
      case PrinterLanguage.tspl:
        bytes = Uint8List.fromList(utf8.encode(_buildTspl(settings)));
        break;
      case PrinterLanguage.cpcl:
        bytes = Uint8List.fromList(utf8.encode(_buildCpcl(settings)));
        break;
      case PrinterLanguage.zpl:
        bytes = Uint8List.fromList(utf8.encode(_buildZpl(settings)));
        break;
      case PrinterLanguage.escpos:
        bytes = _buildEscPos(settings);
        break;
    }

    try {
      BluetoothConnection? connection;
      connection = await BluetoothConnection.toAddress(settings.printerAddress)
          .timeout(const Duration(seconds: 8));
      final output = connection.output;
      output.add(bytes);
      await output.allSent;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await connection.finish();
    } on TimeoutException catch (e) {
      throw PlatformException(code: 'timeout', message: 'Connection timeout: ${e.message}');
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Bluetooth print error: $e\n$st');
      }
      rethrow;
    }
  }

  String _buildTspl(PrintSettings s) {
    final buffer = StringBuffer();
    // Use CRLF for TSPL. Many printers require \r\n line endings.
    void add(String line) => buffer.write('$line\r\n');

    // Label setup (mm-based)
    add('SIZE ${_fmtMm(s.labelWidthMm)},${_fmtMm(s.labelHeightMm)}');
    add('GAP ${_fmtMm(s.gapMm)},0');
    add('DENSITY ${_clamp(s.density, 0, 15)}');
    add('SPEED 4');
    add('DIRECTION 1');
    add('CLS');

    // Add brand and product name in one line (if provided)
    int currentY = 10;
    String labelText = '';
    
    // Build label text: Brand: name, Product: name (price removed from top)
    if (s.productBrand != null && s.productBrand!.isNotEmpty) {
      labelText = 'Brand: ${s.productBrand!}';
    }
    
    if (s.productName != null && s.productName!.isNotEmpty) {
      if (labelText.isNotEmpty) {
        labelText += ', Product: ${s.productName!}';
      } else {
        labelText = 'Product: ${s.productName!}';
      }
    }
    
    if (labelText.isNotEmpty) {
      add('TEXT ${s.x},${currentY},"3",0,1,1,"${_escapeContent(labelText)}"');
      currentY += 30; // Gap before barcode
    }

    // Adjust barcode position based on text above
    final barcodeY = currentY + 5; // Very small gap

    switch (s.barcodeType) {
      case BarcodeType.code128:
        add('BARCODE ${s.x},${barcodeY},"128",${_clamp(s.barcodeHeight, 10, 320)},'
            '${s.humanReadable ? 1 : 0},${_rotationIndex(s.rotation)},2,2,"${_escapeContent(s.data)}"');
        break;
      case BarcodeType.code39:
        add('BARCODE ${s.x},${barcodeY},"39",${_clamp(s.barcodeHeight, 10, 320)},'
            '${s.humanReadable ? 1 : 0},${_rotationIndex(s.rotation)},2,2,"${_escapeContent(s.data)}"');
        break;
      case BarcodeType.ean13:
        add('BARCODE ${s.x},${barcodeY},"EAN13",${_clamp(s.barcodeHeight, 10, 320)},'
            '1,${_rotationIndex(s.rotation)},2,2,"${_escapeContent(s.data)}"');
        break;
      case BarcodeType.qrcode:
        add('QRCODE ${s.x},${barcodeY},${s.qrErrorLevel},${_clamp(s.qrUnitSize, 1, 10)},A,${_rotationIndex(s.rotation)},"${_escapeContent(s.data)}"');
        break;
    }

    // Calculate barcode width (more accurate for chipak printing - no gap)
    int barcodeWidth;
    if (s.barcodeType == BarcodeType.qrcode) {
      // QR code width is approximately unitSize * 25 (for version 1 QR)
      barcodeWidth = s.qrUnitSize * 25;
    } else {
      // 1D barcode width: Code128 uses ~11 dots per character, Code39 uses ~13 dots per character
      // For chipak printing (no gap), we use more accurate calculation
      if (s.barcodeType == BarcodeType.code128) {
        barcodeWidth = (s.data.length * 11).round();
      } else if (s.barcodeType == BarcodeType.code39) {
        barcodeWidth = (s.data.length * 13).round();
      } else {
        // EAN13 is fixed width
        barcodeWidth = 95; // Standard EAN13 width
      }
    }
    
    // Product code to the right bottom of barcode (chipak - no gap)
    final rightX = s.x + barcodeWidth; // Directly after barcode, no gap
    final rightY = barcodeY + _clamp(s.barcodeHeight, 10, 320); // Bottom of barcode
    add('TEXT ${rightX},${rightY},"3",0,1,1,"${_escapeContent(s.data)}"');
    
    // Product price below barcode (bold, left side)
    if (s.productPrice != null && s.productPrice!.isNotEmpty && s.productPrice != '0' && s.productPrice != '0.0') {
      final priceY = barcodeY + _clamp(s.barcodeHeight, 10, 320) + 0; // Below barcode, no gap (chipak)
      final priceText = 'Rs.${s.productPrice!}';
      // Font "4" is bold in TSPL, size 2,2 for larger bold text
      add('TEXT ${s.x},${priceY},"4",0,2,2,"${_escapeContent(priceText)}"');
    }

    add('PRINT ${_clamp(s.copies, 1, 999)}');
    // Final CRLF
    add('');
    return buffer.toString();
  }
  Uint8List _buildEscPos(PrintSettings s) {
    // Build one copy worth of ESC/POS commands
    Uint8List _oneCopy() {
      final bytes = BytesBuilder();
      void add(List<int> list) => bytes.add(list);
      void textLn(String t) => add(utf8.encode('$t\n'));

      // Initialize
      add([0x1B, 0x40]); // ESC @

    // Alignment
      final align = s.escposAlign.clamp(0, 2);
      add([0x1B, 0x61, align]);

    // Left margin
      final lm = s.escposLeftMargin.clamp(0, 65535);
      final lmL = lm & 0xFF;
      final lmH = (lm >> 8) & 0xFF;
      if (lm > 0) {
        add([0x1B, 0x24, lmL, lmH]);
        add([0x1D, 0x4C, lmL, lmH]);
      }

    // BRAND + NAME (Single Line) - Price removed from top
      String labelText = '';
      
      // Build label text: Brand: name, Product: name
      if (s.productBrand != null && s.productBrand!.isNotEmpty) {
        labelText = 'Brand: ${s.productBrand!}';
      }
      
      if (s.productName != null && s.productName!.isNotEmpty) {
        if (labelText.isNotEmpty) {
          labelText += ', Product: ${s.productName!}';
        } else {
          labelText = 'Product: ${s.productName!}';
        }
      }
      
      if (labelText.isNotEmpty) {
        add([0x1B, 0x45, 0x01]); // Bold ON
        textLn(labelText);
        add([0x1B, 0x45, 0x00]); // Bold OFF
      }

    // BARCODE PRINT
      if (s.barcodeType == BarcodeType.qrcode) {
        final data = utf8.encode(s.data);

      add([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x41, 0x32]); // Model 2
        final unit = _clamp(s.qrUnitSize, 1, 10);
      add([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, unit]); // Size
        final err = _escposQrError(s.qrErrorLevel);
      add([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, err]); // Error

        final storeLen = data.length + 3;
        final pL = storeLen & 0xFF;
        final pH = (storeLen >> 8) & 0xFF;
        add([0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30]);
        add(data);

        add([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);
        add([0x0A]);
      } else {
      // ----- 1D BARCODE -----

      add([0x1D, 0x48, 0x00]); // HRI OFF (IMPORTANT – duplicate रोकता है)
        add([0x1D, 0x68, _clamp(s.barcodeHeight, 10, 255)]);
      add([0x1D, 0x77, 0x02]); // module width

        switch (s.barcodeType) {
        case BarcodeType.code128:
            final data = ascii.encode(s.data);
            final length = data.length;
            add([0x1D, 0x6B, 0x49, length]);
            add(data);
            add([0x0A]);
            break;

        case BarcodeType.code39:
          final data39 = ascii.encode(s.data);
            add([0x1D, 0x6B, 0x04]);
          add(data39);
            add([0x00, 0x0A]);
            break;

        case BarcodeType.ean13:
          final dataStr =
              s.data.replaceAll(RegExp(r'[^0-9]'), '').trim();
          final data13 = ascii.encode(dataStr);

          if (data13.length < 12) {
              textLn('EAN13 needs 12 digits: ${s.data}');
            } else {
              add([0x1D, 0x6B, 0x02]);
            add(data13.take(12).toList());
              add([0x00, 0x0A]);
            }
            break;

          case BarcodeType.qrcode:
            break;
        }
      }

    // Product code to the right bottom of barcode (chipak - no gap)
    // Calculate barcode width in characters (more accurate for chipak printing)
    int barcodeWidthChars;
    if (s.barcodeType == BarcodeType.qrcode) {
      barcodeWidthChars = (s.qrUnitSize * 25) ~/ 8;
    } else {
      // 1D barcode width: Code128 uses ~11 dots per character, Code39 uses ~13 dots per character
      // Assuming 1 char = 8 dots for thermal printer
      if (s.barcodeType == BarcodeType.code128) {
        barcodeWidthChars = ((s.data.length * 11) ~/ 8).round();
      } else if (s.barcodeType == BarcodeType.code39) {
        barcodeWidthChars = ((s.data.length * 13) ~/ 8).round();
      } else {
        // EAN13 is fixed width
        barcodeWidthChars = (95 ~/ 8).round(); // Standard EAN13 width
      }
    }
    // After barcode print, cursor is at the bottom line of barcode
    // Add spaces to position to the right (barcode width - chipak, no gap)
    String spaces = ' ' * barcodeWidthChars;
    add([0x1B, 0x61, 0x00]); // Left align
    add(utf8.encode('$spaces${s.data}\n')); // Product code to the right bottom (chipak)
    
    // Product price below barcode (bold, left side, chipak)
    if (s.productPrice != null && s.productPrice!.isNotEmpty && s.productPrice != '0' && s.productPrice != '0.0') {
      add([0x1B, 0x61, 0x00]); // Left align
      add([0x1B, 0x45, 0x01]); // Bold ON
      final priceText = 'Rs.${s.productPrice!}';
      textLn(priceText); // Print on same line (chipak - no gap)
      add([0x1B, 0x45, 0x00]); // Bold OFF
    }

    // Gap between copies
    add([0x1B, 0x64, 0x02]);

      return bytes.toBytes();
    }

    final builder = BytesBuilder();
    final copies = _clamp(s.copies, 1, 255);

    for (int i = 0; i < copies; i++) {
      builder.add(_oneCopy());
    }

    return builder.toBytes();
  }


  int _escposQrError(String level) {
    switch (level.toUpperCase()) {
      case 'L':
        return 0x30; // '0'
      case 'M':
        return 0x31; // '1'
      case 'Q':
        return 0x32; // '2'
      case 'H':
      default:
        return 0x33; // '3'
    }
  }

  String _buildCpcl(PrintSettings s) {
    // Assume 203 dpi (8 dots/mm)
    final int pageWidth = (s.labelWidthMm * 8).round();
    final int pageHeight = (s.labelHeightMm * 8).round();
    final buffer = StringBuffer();
    void add(String line) => buffer.write('$line\r\n');

    add('! 0 200 200 $pageHeight ${_clamp(s.copies, 1, 999)}');
    add('PW $pageWidth');
    add('SETBOLD 0');
    add('SPEED 4');
    add('SETMAG 0 0');
    add('TONE 0');

    // Add brand and product name in one line (if provided)
    int currentY = 10;
    String labelText = '';
    
    // Build label text: Brand: name, Product: name (price removed from top)
    if (s.productBrand != null && s.productBrand!.isNotEmpty) {
      labelText = 'Brand: ${s.productBrand!}';
    }
    
    if (s.productName != null && s.productName!.isNotEmpty) {
      if (labelText.isNotEmpty) {
        labelText += ', Product: ${s.productName!}';
      } else {
        labelText = 'Product: ${s.productName!}';
      }
    }
    
    if (labelText.isNotEmpty) {
      add('SETBOLD 1');
      add('TEXT 4 0 ${s.x} ${currentY} ${_escapeContent(labelText)}');
      add('SETBOLD 0');
      currentY += 0;
    }

    final barcodeY = currentY + 5; // Very small gap

    switch (s.barcodeType) {
      case BarcodeType.code128:
        // B 128 rotation narrow wide x y data
        add('B 128 ${_cpclRotation(s.rotation)} 2 4 ${s.x} ${barcodeY} ${_escapeContent(s.data)}');
        break;
      case BarcodeType.code39:
        add('B 39 ${_cpclRotation(s.rotation)} 2 4 ${s.x} ${barcodeY} ${_escapeContent(s.data)}');
        break;
      case BarcodeType.ean13:
        add('B EAN13 ${_cpclRotation(s.rotation)} 2 4 ${s.x} ${barcodeY} ${_escapeContent(s.data)}');
        break;
      case BarcodeType.qrcode:
        // CPCL QR
        final unit = _clamp(s.qrUnitSize, 1, 10);
        add('B QR ${s.x} ${barcodeY} M 2 U $unit');
        add('${_escapeContent(s.data)}');
        add('ENDQR');
        break;
    }
    
    // Calculate barcode width (more accurate for chipak printing - no gap)
    int barcodeWidth;
    if (s.barcodeType == BarcodeType.qrcode) {
      barcodeWidth = s.qrUnitSize * 25;
    } else {
      // 1D barcode width: Code128 uses ~11 dots per character, Code39 uses ~13 dots per character
      if (s.barcodeType == BarcodeType.code128) {
        barcodeWidth = (s.data.length * 11).round();
      } else if (s.barcodeType == BarcodeType.code39) {
        barcodeWidth = (s.data.length * 13).round();
      } else {
        // EAN13 is fixed width
        barcodeWidth = 95; // Standard EAN13 width
      }
    }
    
    // Product code to the right bottom of barcode (chipak - no gap)
    final rightX = s.x + barcodeWidth; // Directly after barcode, no gap
    final rightY = barcodeY + s.barcodeHeight; // Bottom of barcode
    add('TEXT 4 0 ${rightX} ${rightY} ${_escapeContent(s.data)}');
    
    // Product price below barcode (bold, left side, chipak)
    if (s.productPrice != null && s.productPrice!.isNotEmpty && s.productPrice != '0' && s.productPrice != '0.0') {
      final priceY = barcodeY + s.barcodeHeight + 0; // Below barcode, no gap (chipak)
      final priceText = 'Rs.${s.productPrice!}';
      add('SETBOLD 1'); // Bold ON
      add('TEXT 4 0 ${s.x} ${priceY} ${_escapeContent(priceText)}');
      add('SETBOLD 0'); // Bold OFF
    }
    
    // Human readable for 1D barcodes (keep existing if enabled)
    if (s.barcodeType != BarcodeType.qrcode && s.humanReadable) {
      // Already added above, so skip duplicate
    }
    add('PRINT');
    return buffer.toString();
  }

  String _buildZpl(PrintSettings s) {
    // Assume 203 dpi (8 dots/mm)
    final int pw = (s.labelWidthMm * 8).round();
    final buffer = StringBuffer();
    void add(String line) => buffer.write('$line\r\n');

    add('^XA');
    add('^PW$pw');
    add('^LH0,0');
    add('^PR4');

    // Add brand and product name in one line (if provided)
    int currentY = 10;
    String labelText = '';
    
    // Build label text: Brand: name, Product: name (price removed from top)
    if (s.productBrand != null && s.productBrand!.isNotEmpty) {
      labelText = 'Brand: ${s.productBrand!}';
    }
    
    if (s.productName != null && s.productName!.isNotEmpty) {
      if (labelText.isNotEmpty) {
        labelText += ', Product: ${s.productName!}';
      } else {
        labelText = 'Product: ${s.productName!}';
      }
    }
    
    if (labelText.isNotEmpty) {
      add('^FO${s.x},${currentY}^A0N,30,30^FD${_escapeContent(labelText)}^FS');
      currentY += 30;
    }

    final barcodeY = currentY + 5; // Very small gap

    switch (s.barcodeType) {
      case BarcodeType.code128:
        // ^BCN,height,printText,checkDigit,mode
        final printText = s.humanReadable ? 'Y' : 'N';
        add('^FO${s.x},${barcodeY}^BY2,3,${_clamp(s.barcodeHeight, 10, 320)}^BCN,${_clamp(s.barcodeHeight, 10, 320)},$printText,N,N^FD${_escapeContent(s.data)}^FS');
        break;
      case BarcodeType.code39:
        // ^B3N (Code39)
        final printText39 = s.humanReadable ? 'Y' : 'N';
        add('^FO${s.x},${barcodeY}^BY2,3,${_clamp(s.barcodeHeight, 10, 320)}^B3N,N,${_clamp(s.barcodeHeight, 10, 320)},$printText39,N^FD${_escapeContent(s.data)}^FS');
        break;
      case BarcodeType.ean13:
        // ^BEN (EAN-13)
        final printTextE = s.humanReadable ? 'Y' : 'N';
        add('^FO${s.x},${barcodeY}^BY2,3,${_clamp(s.barcodeHeight, 10, 320)}^BEN,${_clamp(s.barcodeHeight, 10, 320)},$printTextE^FD${_escapeContent(s.data)}^FS');
        break;
      case BarcodeType.qrcode:
        // ^BQN,2,unit  then ^FDLA,data^FS
        final unit = _clamp(s.qrUnitSize, 1, 10);
        add('^FO${s.x},${barcodeY}^BQN,2,$unit^FDLA,${_escapeContent(s.data)}^FS');
        break;
    }
    
    // Calculate barcode width (more accurate for chipak printing - no gap)
    int barcodeWidth;
    if (s.barcodeType == BarcodeType.qrcode) {
      barcodeWidth = s.qrUnitSize * 25;
    } else {
      // 1D barcode width: Code128 uses ~11 dots per character, Code39 uses ~13 dots per character
      if (s.barcodeType == BarcodeType.code128) {
        barcodeWidth = (s.data.length * 11).round();
      } else if (s.barcodeType == BarcodeType.code39) {
        barcodeWidth = (s.data.length * 13).round();
      } else {
        // EAN13 is fixed width
        barcodeWidth = 95; // Standard EAN13 width
      }
    }
    
    // Product code to the right bottom of barcode (chipak - no gap)
    final rightX = s.x + barcodeWidth; // Directly after barcode, no gap
    final rightY = barcodeY + _clamp(s.barcodeHeight, 10, 320); // Bottom of barcode
    add('^FO${rightX},${rightY}^A0N,20,20^FD${_escapeContent(s.data)}^FS');
    
    // Product price below barcode (bold, left side, chipak)
    if (s.productPrice != null && s.productPrice!.isNotEmpty && s.productPrice != '0' && s.productPrice != '0.0') {
      final priceY = barcodeY + _clamp(s.barcodeHeight, 10, 320) + 0; // Below barcode, no gap (chipak)
      final priceText = 'Rs.${s.productPrice!}';
      // ^A0B = bold font, larger size for bold effect
      add('^FO${s.x},${priceY}^A0B,30,30^FD${_escapeContent(priceText)}^FS');
    }
    
    add('^PQ${_clamp(s.copies, 1, 999)},0,0,N');
    add('^XZ');
    return buffer.toString();
  }

  String _cpclRotation(int rotation) {
    final normalized = ((rotation % 360) + 360) % 360;
    // CPCL rotation: 0,90,180,270
    switch (normalized) {
      case 0:
        return '0';
      case 90:
        return '90';
      case 180:
        return '180';
      case 270:
        return '270';
      default:
        return '0';
    }
  }

  String _fmtMm(double mm) {
    // TSPL accepts decimal mm values
    return (mm.toStringAsFixed(mm.truncateToDouble() == mm ? 0 : 1));
  }

  int _rotationIndex(int rotation) {
    final normalized = ((rotation % 360) + 360) % 360;
    switch (normalized) {
      case 0:
        return 0;
      case 90:
        return 1;
      case 180:
        return 2;
      case 270:
        return 3;
      default:
        return 0;
    }
  }

  int _clamp(int v, int min, int max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }

  String _escapeContent(String input) {
    // Basic escaping for quotes in TSPL string
    return input.replaceAll('"', r'\"');
  }
}


