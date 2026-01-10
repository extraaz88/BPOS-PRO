import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../Provider/product_provider.dart';
import '../../Screens/Products/Model/product_model.dart';
import '../../constant.dart';

class LabelPrinterScreen extends ConsumerStatefulWidget {
  const LabelPrinterScreen({super.key});

  @override
  ConsumerState<LabelPrinterScreen> createState() => _LabelPrinterScreenState();
}

class _LabelPrinterScreenState extends ConsumerState<LabelPrinterScreen> {
  BluetoothDevice? selectedDevice;
  BluetoothConnection? connection;
  List<BluetoothDevice> devices = [];

  bool isConnected = false;
  List<ProductModel> _products = [];

  final TextEditingController itemCtrl = TextEditingController();
  final TextEditingController barcodeCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController sizeCtrl = TextEditingController();
  final TextEditingController breCtrl = TextEditingController();
  final TextEditingController subcCtrl = TextEditingController();
  final TextEditingController mixCtrl = TextEditingController();
  final TextEditingController quantityCtrl = TextEditingController(text: '1');
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    setState(() {});
  }

  Future<void> connectPrinter() async {
    if (selectedDevice == null) return;

    try {
      connection = await BluetoothConnection.toAddress(selectedDevice!.address);
      setState(() => isConnected = true);
      print("✔ Printer Connected");
    } catch (e) {
      print("❌ Connection Failed: $e");
    }
  }

  // ================= ESC/POS FULL LABEL ==================
  Uint8List buildEscPosLabel({
    required String barcode,
    required String itemName,
    required String size,
    required String price,
    required String bre,
    required String subc,
    required String mix,
    bool addExtraGap = false, // For ~0.3mm extra gap between groups
  }) {
    final bytes = BytesBuilder();

    bytes.add([0x1B, 0x40]); // Reset printer
// TOP (PRICE INSTEAD OF OM)
bytes.add([0x1B, 0x61, 0]); // left align

// Check item name length - if long, use smaller font to fit in one line
final itemNameLength = itemName.trim().length;
// Use smaller font + condensed mode if item name is longer than 18 characters to fit in one line
final isLongItemName = itemNameLength > 18;

// Set larger font size for price (double width only - slightly bigger)
bytes.add([0x1D, 0x21, 0x10]); // GS ! - Double width only (0x10 = 16 decimal)
bytes.add([0x1B, 0x45, 0x01]); // 🔥 bold ON
//bytes.add(utf8.encode(" RS.$price")); // 🔥 PRICE instead of OM
bytes.add([0x1B, 0x45, 0x00]); // bold OFF
bytes.add([0x1D, 0x21, 0x00]); // GS ! - Reset to normal size

// If item name is long, use smaller font + condensed mode to fit in one line
if (isLongItemName) {
  bytes.add([0x1B, 0x4D, 0x01]); // ESC M 1 - Select small font
  bytes.add([0x0F]); // SI - Select condensed mode (compresses text horizontally)
}// ---------------- TOP (BOLD + BIGGER TEXT FOR PRICE + ITEM NAME) ----------------
bytes.add([0x1B, 0x61, 0]); // left align

bytes.add([0x1B, 0x61, 0]); // left align

// PRICE (Bold + Bigger)
bytes.add([0x1D, 0x21, 0x01]);  
bytes.add([0x1B, 0x45, 0x01]);
bytes.add(utf8.encode(" RS. $price  $itemName "));  
// bytes.add(utf8.encode(" R S.$price  $itemName  "));  
bytes.add([0x1B, 0x45, 0x00]);  
bytes.add([0x1D, 0x21, 0x00]);  

// PRODUCT NAME (normal font, next line)
bytes.add([0x0A]);  // NEW LINE
bytes.add(utf8.encode("Brand.$bre       Size.$size"));

// bytes.add([0x1B, 0x61, 0]);

// // SMALLER FONT (double height band, only bold + slight width)
// bytes.add([0x1D, 0x21, 0x00]);   // Normal size 
// bytes.add([0x1B, 0x45, 0x01]);   // Bold ON

// bytes.add(utf8.encode(" RS.$price  $itemName "));

// bytes.add([0x1B, 0x45, 0x00]);   // Bold OFF
//           // Another small gap

// // PRODUCT NAME (normal font, next line)
// bytes.add([0x0A]);  // NEW LINE
// bytes.add(utf8.encode("Brand.$bre       Size.$size"));


if (isLongItemName) {
  bytes.add([0x12]); // DC2 - Cancel condensed mode
  bytes.add([0x1B, 0x4D, 0x00]); // ESC M 0 - Select normal font
}

//bytes.add(utf8.encode("     Name   $itemName  ")); // Item name
bytes.add([0x1B, 0x45, 0x01]);  // bold ON
//bytes.add(utf8.encode("     SIZE. $size"));  // size bold
bytes.add([0x1B, 0x45, 0x00]); // bold OFF
bytes.add([0x0A]);


    // BARCODE
    bytes.add([0x1B, 0x61, 1]); // center
    bytes.add([0x1D, 0x68, 40]); // height
    bytes.add([0x1D, 0x48, 2]); // HRI text
    bytes.add([0x1D, 0x6B, 0x49, barcode.length]);
    bytes.add(utf8.encode(barcode)); // Print actual barcode
    bytes.add([0x0A]);

    // RS. PRICE (Bottom - Large font, properly formatted)
    bytes.add([0x1B, 0x61, 0]); // left align
    bytes.add([0x1D, 0x21, 0x10]); // GS ! - Double width only
    bytes.add([0x1B, 0x45, 0x01]); // bold ON
    //bytes.add(utf8.encode("RS. $price")); // Properly formatted price
    bytes.add([0x1B, 0x45, 0x00]); // bold OFF
    bytes.add([0x1D, 0x21, 0x00]); // GS ! - Reset to normal size
    bytes.add([0x0A]);

    // Optional extra feed / gap after a label when requested
    // ESC J n  => feed paper by n dots (small precise gap)
    // Yahan 0.3mm se thoda zyada (approx 0.5mm ke aas‑paas) gap ke liye value badha di hai
    // Aap baad me is value ko 24 / 28 / 36 karke fine‑tune kar sakte ho (printer ke DPI par depend karta hai)
    if (addExtraGap) {
      bytes.add([0x1B, 0x4A, 0x20]); // Thoda bada vertical feed between groups (~0.5mm approx)
    }


    // // PRICE
    // bytes.add([0x1B, 0x45, 0x01]); // bold
    // bytes.add([0x1D, 0x21, 0x11]); // double size
    // bytes.add(utf8.encode("RS. $price"));
    // bytes.add([0x1D, 0x21, 0x00]);

    // // Extra Right
    // bytes.add(utf8.encode("        BRE $bre"));
    // bytes.add([0x0A]);
    // bytes.add(utf8.encode("        SUBC $subc     $mix"));
    // bytes.add([0x0A, 0x0A]);

    return bytes.toBytes();
  }

  // PRINT
  Future<void> printLabel() async {
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect to printer first')),
      );
      return;
    }

    // Get quantity, default to 1 if empty or invalid
    // Maximum limit: 18 prints
    final quantity = int.tryParse(quantityCtrl.text.trim()) ?? 1;
    if (quantity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity (minimum 1)')),
      );
      return;
    }
    if (quantity > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 prints allowed. Please enter quantity between 1-10')),
      );
      return;
    }

    if (barcodeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product or enter barcode')),
      );
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      int totalPrinted = 0;

      for (int i = 0; i < quantity; i++) {
        // Check if this is the 6th label in a group (6, 12, 18, 24, etc.)
        // Add extra ~0.3mm gap after every 6th label
        // Example: for quantity 10, gap will be between 6 & 7; for 13, between 6 & 7 and 12 & 13
        bool addExtraGap = (i > 0 && (i + 1) % 6 == 0);
        
        Uint8List data = buildEscPosLabel(
          barcode: barcodeCtrl.text.trim(),
          itemName: itemCtrl.text.trim(),
          size: sizeCtrl.text.trim(),
          price: priceCtrl.text.trim(),
          bre: breCtrl.text.trim(),
          subc: subcCtrl.text.trim(),
          mix: mixCtrl.text.trim(),
          addExtraGap: addExtraGap,
        );

        connection!.output.add(data);
        totalPrinted++;
        
        // Small delay between prints to avoid overwhelming the printer
        if (i < quantity - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Successfully printed $totalPrinted label(s)')),
      );
      print("✔ ESC/POS LABEL PRINTED: $totalPrinted copies");
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  void _onProductSelected(ProductModel product) {
    setState(() {
      itemCtrl.text = product.productName ?? '';
      barcodeCtrl.text = product.productCode ?? '';
      sizeCtrl.text = product.size ?? '';
      priceCtrl.text = product.productSalePrice?.toString() ?? '';
      breCtrl.text = product.brand?.brandName ?? '';
      subcCtrl.text = product.category?.categoryName ?? '';
      mixCtrl.text = product.color ?? '';
      // Keep quantity as is, don't reset it
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Product selected: ${product.productName ?? ''}')),
    );
  }

  @override
  void dispose() {
    itemCtrl.dispose();
    barcodeCtrl.dispose();
    priceCtrl.dispose();
    sizeCtrl.dispose();
    breCtrl.dispose();
    subcCtrl.dispose();
    mixCtrl.dispose();
    quantityCtrl.dispose();
    connection?.dispose();
    super.dispose();
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final productData = ref.watch(productProvider);
    
    return productData.when(
      data: (products) {
        _products = products;
        
        return Scaffold(
          appBar: AppBar(title: const Text("ESC/POS Label Printer")),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Product Search Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.search, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Search Product',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TypeAheadField<ProductModel>(
                          hideOnEmpty: false,
                          hideOnLoading: false,
                          builder: (context, controller, focusNode) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: kInputDecoration.copyWith(
                                fillColor: Colors.white,
                                border: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                                hintText: 'Click to see all products or type to search...',
                                hintStyle: const TextStyle(fontSize: 13),
                                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                              ),
                            );
                          },
                          suggestionsCallback: (pattern) {
                            // Show all products if pattern is empty (when user clicks)
                            if (pattern.isEmpty) {
                              return _products.take(50).toList(); // Show first 50 products
                            }
                            // Filter products based on search pattern
                            return _products
                                .where((product) => 
                                    product.productName!
                                        .toLowerCase()
                                        .contains(pattern.toLowerCase()) ||
                                    (product.productCode ?? '')
                                        .toLowerCase()
                                        .contains(pattern.toLowerCase()))
                                .take(50) // Limit to 50 results for performance
                                .toList();
                          },
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              leading: const Icon(Icons.qr_code_2, color: Colors.blue),
                              title: Text(suggestion.productName ?? ''),
                              subtitle: RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                  children: [
                                    if (suggestion.brand?.brandName != null && suggestion.brand!.brandName!.isNotEmpty) ...[
                                      TextSpan(
                                        text: suggestion.brand!.brandName!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' • ',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                    TextSpan(
                                      text: 'Code: ',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    TextSpan(
                                      text: suggestion.productCode ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' • ₹${suggestion.productSalePrice ?? 0}',
                                      style: const TextStyle(color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          onSelected: (value) => _onProductSelected(value),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tip: Search and select a product to auto-fill the fields below.',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),

                DropdownButton<BluetoothDevice>(
                  isExpanded: true,
                  hint: const Text("Select Printer"),
                  value: selectedDevice,
                  items: devices.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text(d.name ?? d.address),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedDevice = val),
                ),

                ElevatedButton(
                  onPressed: connectPrinter,
                  child: Text(isConnected ? "Connected" : "Connect"),
                ),

                const SizedBox(height: 20),

                _input(itemCtrl, "Item Name"),
                _input(barcodeCtrl, "Barcode"),
                //_input(sizeCtrl, "Size"),
                _input(priceCtrl, "Price"),
               
                
                // Quantity/Copy Field
                Card(
                  elevation: 1,
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.copy, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Label Copies (Quantity) - Max 10',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: quantityCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 2, // Max 2 digits (18)
                            onChanged: (value) {
                              // Restrict to max 18
                              if (value.isNotEmpty) {
                                final num = int.tryParse(value);
                                if (num != null && num > 10) {
                                  quantityCtrl.text = '10';
                                  quantityCtrl.selection = TextSelection.fromPosition(
                                    TextPosition(offset: quantityCtrl.text.length),
                                  );
                                }
                              }
                              setState(() {}); // Update button text
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              hintText: '1-10',
                              counterText: '', // Hide character counter
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: (_isPrinting || !isConnected) ? null : printLabel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  icon: _isPrinting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.print, color: Colors.white),
                  label: Text(
                    _isPrinting
                        ? 'Printing...'
                        : 'Print ${quantityCtrl.text.isEmpty || int.tryParse(quantityCtrl.text) == null ? "1" : quantityCtrl.text} Label(s)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text("ESC/POS Label Printer")),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text("ESC/POS Label Printer")),
        body: Center(
          child: Text('Error loading products: $error'),
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}