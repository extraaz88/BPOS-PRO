import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import 'thermal priting invoices/provider/custom_print_provider.dart';

class DemoPrintScreen extends ConsumerStatefulWidget {
  const DemoPrintScreen({super.key});

  @override
  ConsumerState<DemoPrintScreen> createState() => _DemoPrintScreenState();
}

class _DemoPrintScreenState extends ConsumerState<DemoPrintScreen> {
  bool _isPrinting = false;

  Future<void> _printDemo() async {
    setState(() {
      _isPrinting = true;
    });

    try {
      // Check printer connection
      bool? isConnected = await PrintBluetoothThermal.connectionStatus;
      
      if (isConnected != true) {
        // Try to get available printers
        final printerProvider = ref.read(printerPurchaseProviderNotifier);
        await printerProvider.getBluetooth();
        
        if (printerProvider.availableBluetoothDevices.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No Bluetooth printer found. Please connect a printer first.')),
            );
          }
          return;
        }
        
        // Connect to first available printer (you can modify this to show a selection dialog)
        final firstPrinter = printerProvider.availableBluetoothDevices.first;
        final connected = await printerProvider.setConnect(firstPrinter.macAdress);
        
        if (!connected) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to connect to printer.')),
            );
          }
          return;
        }
      }

      // Generate print bytes
      List<int> bytes = await _generatePrintBytes();
      
      // Send to printer
      await PrintBluetoothThermal.writeBytes(bytes);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Print successful!')),
        );
      }
    } catch (e) {
      print('Print error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Print failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  Future<List<int>> _generatePrintBytes() async {
    List<int> bytes = [];
    
    try {
      CapabilityProfile profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      
      // ============================================
      // WHY 1 CM SPACE WAS APPEARING:
      // ============================================
      // 1. generator.reset() command automatically feeds some lines (adds top spacing)
      // 2. Printer's default top margin setting (usually 3-4mm or ~1cm)
      // 3. Automatic line feed after initialization
      // 4. PrintBluetoothThermal library might add buffer spacing
      //
      // SOLUTION: Skip reset() and use direct ESC/POS commands to:
      // - Set absolute vertical position to 0 (start from top)
      // - Set all margins to 0
      // - Cancel automatic feeds
      // - Use PosStyles with height property to control line spacing
      // ============================================
      
      // Initialize printer without reset (to avoid automatic spacing)
      bytes += Uint8List.fromList([0x1B, 0x40]); // Initialize printer (ESC @)
      
      // 1. Set top margin to 0 using ESC ( c command
      // ESC ( c nL nH [Function] [pL pH] - Set top and bottom margins
      // Function = 0x01 for top margin, pL pH = margin value in dots (0 = no margin)
      bytes += Uint8List.fromList([0x1B, 0x28, 0x63, 0x02, 0x00, 0x01, 0x00, 0x00]); // Top margin = 0
      
      // 2. Set bottom margin to 0
      bytes += Uint8List.fromList([0x1B, 0x28, 0x63, 0x02, 0x00, 0x02, 0x00, 0x00]); // Bottom margin = 0
      
      // 3. Set left margin to 0 (ESC l nL nH - Set left margin in dots)
      bytes += Uint8List.fromList([0x1B, 0x6C, 0x00, 0x00]); // Left margin = 0 dots
      
      // 4. Set line spacing to 0 (ESC 3 n - Set line spacing in dots)
      bytes += Uint8List.fromList([0x1B, 0x33, 0x00]); // Line spacing = 0 dots
      
      // 5. Set left alignment (ESC a n - 0=left, 1=center, 2=right)
      bytes += Uint8List.fromList([0x1B, 0x61, 0x00]); // Left align
      
      // 6. Cancel automatic line feed (ESC i - Cancel automatic feed)
      bytes += Uint8List.fromList([0x1B, 0x69]);
      
      // 7. Set absolute horizontal position to 0 (ESC $ nL nH - for left edge)
      bytes += Uint8List.fromList([0x1B, 0x24, 0x00, 0x00]); // Horizontal position = 0
      
      // 8. Disable automatic paper cutting (GS V - Select cut mode and cut paper)
      // This prevents any automatic spacing before cut
      
      // Print "hello extraaz" with zero starting space using PosStyles
      // Using PosStyles with height property to control line height and minimize spacing
      bytes += generator.text(
        'hello extraaz',
        styles: const PosStyles(
          align: PosAlign.left, // Left align for zero starting space
          bold: true,
          height: PosTextSize.size1, // Control line height to minimize spacing
          width: PosTextSize.size1,  // Control character width
        ),
        linesAfter: 0, // No extra lines after text to avoid spacing
      );
      
      // Generate barcode with 0 spacing
      // Using a demo barcode value
      const String barcodeValue = 'HELLOEXTRAZ123';
      
      bytes += generator.barcode(
        Barcode.code128(barcodeValue.codeUnits),
        width: 1,        // Bar width (minimum for 0 spacing)
        height: 50,      // Barcode height
        font: BarcodeFont.fontA,
        textPos: BarcodeText.below, // Text below barcode
      );
      
      bytes += generator.cut();
      
      return bytes;
    } catch (e) {
      print('Error generating print bytes: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Print'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isPrinting ? null : _printDemo,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: _isPrinting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Demo'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Click to print "hello extraaz" with zero spacing\nand generate a barcode with 0 spacing',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

