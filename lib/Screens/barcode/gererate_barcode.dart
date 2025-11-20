import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:iconly/iconly.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:mobile_pos/thermal%20priting%20invoices/provider/print_thermal_invoice_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/product_provider.dart';
import '../../thermal priting invoices/provider/custom_print_provider.dart';
import '../Products/Model/product_model.dart';

class BarcodeGeneratorScreen extends StatefulWidget {
  const BarcodeGeneratorScreen({super.key});

  @override
  _BarcodeGeneratorScreenState createState() => _BarcodeGeneratorScreenState();
}

class _BarcodeGeneratorScreenState extends State<BarcodeGeneratorScreen> {
  List<ProductModel> products = [];
  List<SelectedProduct> selectedProducts = [];
  bool showCode = true;
  bool showPrice = true;
  bool showName = true;

  void _addProduct(ProductModel product) {
    setState(() {
      final existingProduct = selectedProducts.firstWhere(
        (p) => p.product.productCode == product.productCode,
        orElse: () => SelectedProduct(product: product, quantity: 0),
      );

      if (existingProduct.quantity > 0) {
        existingProduct.quantity++;
        _showSnackBar('${product.productName} quantity increased.');
      } else {
        selectedProducts.add(SelectedProduct(product: product, quantity: 1));
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
Future<Uint8List?> _generatePdfBytes(String? companyName) async {
  final pdf = pw.Document();

  // LABEL SIZE EXACT (No extra margin)
  const double labelWidth = 48 * PdfPageFormat.mm;
  const double labelHeight = 30 * PdfPageFormat.mm;

  for (var sp in selectedProducts) {
    final code = sp.product.productCode ?? '';
    if (code.trim().isEmpty) continue;

    final price = sp.product.productSalePrice?.toString() ?? "";
    final productName = sp.product.productName ?? "";

    for (int i = 0; i < sp.quantity; i++) {
      pdf.addPage(
        pw.Page(
          margin: pw.EdgeInsets.zero,        // No GAP
          pageFormat: PdfPageFormat(labelWidth, labelHeight),
          build: (context) {
            return pw.Container(
              width: labelWidth,
              height: labelHeight,
              padding: pw.EdgeInsets.zero,
              margin: pw.EdgeInsets.zero,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [

                  // Company Name (optional)
                  if (companyName != null && companyName.trim().isNotEmpty)
                    pw.Text(
                      companyName,
                      style: pw.TextStyle(
                        fontSize: 6,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      maxLines: 1,
                      textAlign: pw.TextAlign.center,
                    ),

                  // Product Name
                  pw.SizedBox(height: 1),
                  pw.Text(
                    productName,
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                    maxLines: 2,
                  ),

                  // Price
                  pw.SizedBox(height: 1),
                  pw.Text(
                    "₹$price",
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),

                  // Barcode Without Expanded
                  pw.SizedBox(height: 2),
                  pw.Container(
                    width: 45 * PdfPageFormat.mm,
                    height: 12 * PdfPageFormat.mm,
                    alignment: pw.Alignment.center,
                    child: pw.BarcodeWidget(
                      data: code,
                      barcode: pw.Barcode.code128(),
                      drawText: false,
                      width: 45 * PdfPageFormat.mm,
                      height: 12 * PdfPageFormat.mm,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
  }

  return pdf.save();
}

  Future<void> _printToThermal(WidgetRef ref) async {
    try {
      final businessInfo = ref.read(businessInfoProvider);
      final businessData = businessInfo.asData?.value;
      final companyName = businessData?.companyName ?? '';

      final List<Map<String, dynamic>> payload = selectedProducts.map((sp) {
        return {
          'name': sp.product.productName ?? '',
          'code': sp.product.productCode ?? '',
          'price': sp.product.productSalePrice?.toString() ?? '',
          'qty': sp.quantity,
        };
      }).toList();

      final hasValid =
          payload.any((p) => (p['code'] ?? '').toString().trim().isNotEmpty);
      if (!hasValid) {
        _showSnackBar('No valid product codes available to print.');
        return;
      }

      final thermalPrinter = ref.read(thermalPrinterProvider);
      await thermalPrinter.getBluetooth();

      if (!thermalPrinter.isBluetoothConnected) {
        await thermalPrinter.listOfBluDialog(context: context);
        await thermalPrinter.getBluetooth();
      }

      if (!thermalPrinter.isBluetoothConnected) {
        _showSnackBar('Please connect to a Bluetooth printer.');
        return;
      }

      _showSnackBar('🔄 Connecting to printer...');
      final bool success = await ref
          .read(printerPurchaseProviderNotifier)
          .printBarcodeProductsAsImage(
            products: payload,
            businessName: companyName,
          );

      if (!success) {
        _showSnackBar('❌ Thermal print failed. Ensure printer is connected.');
      } else {
        _showSnackBar('✅ Barcode(s) sent to printer successfully!');
      }
    } catch (e) {
      _showSnackBar('Thermal print error: $e');
    }
  }

  Future<void> _preview(WidgetRef ref) async {
    try {
      final businessInfo = ref.read(businessInfoProvider);
      final businessData = businessInfo.asData?.value;
      final companyName = businessData?.companyName;

      final pdfBytes = await _generatePdfBytes(companyName);
      if (pdfBytes == null) {
        _showSnackBar('No valid product codes available to generate barcodes.');
        return;
      }

      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
      await ref.read(thermalPrinterProvider).printPdfBytes(pdfBytes);
    } catch (e) {
      _showSnackBar('Error generating/printing barcode: $e');
    }
  }

  void _toggleCheckbox(bool value, Function(bool) updateFunction) {
    setState(() => updateFunction(value));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, __) {
        final productData = ref.watch(productProvider);
        final businessInfo = ref.watch(businessInfoProvider);
        return GlobalPopup(
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              centerTitle: true,
              title: Text(lang.S.of(context).barcodeGenerator),
              backgroundColor: Colors.white,
            ),
            body: productData.when(
              data: (snapshot) {
                products = snapshot;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        /// 🔍 Search bar
                        TypeAheadField<ProductModel>(
                          builder: (context, controller, focusNode) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: kInputDecoration.copyWith(
                                fillColor: kWhite,
                                border: const OutlineInputBorder(
                                  borderSide: BorderSide(color: kMainColor),
                                ),
                                hintText: lang.S.of(context).searchProduct,
                                suffixIcon: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: kMainColor,
                                  ),
                                  child: const Icon(Icons.search,
                                      color: Colors.white),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                              ),
                            );
                          },
                          suggestionsCallback: (pattern) {
                            return products
                                .where((product) => product.productName!
                                    .toLowerCase()
                                    .startsWith(pattern.toLowerCase()))
                                .toList();
                          },
                          itemBuilder: (context, suggestion) => ListTile(
                            title: Text(suggestion.productName ?? ''),
                            subtitle:
                                Text('Code: ${suggestion.productCode ?? ''}'),
                            trailing:
                                Text('₹${suggestion.productSalePrice ?? 0}'),
                          ),
                          onSelected: (value) => _addProduct(value),
                        ),
                        const SizedBox(height: 14),

                        /// 🧾 Checkboxes
                        Row(
                          children: [
                            Checkbox(
                              activeColor: kMainColor,
                              value: showCode,
                              onChanged: (v) =>
                                  _toggleCheckbox(v!, (val) => showCode = val),
                            ),
                            Text(lang.S.of(context).showCode),
                            Checkbox(
                              activeColor: kMainColor,
                              value: showPrice,
                              onChanged: (v) =>
                                  _toggleCheckbox(v!, (val) => showPrice = val),
                            ),
                            Text(lang.S.of(context).showPrice),
                            Checkbox(
                              activeColor: kMainColor,
                              value: showName,
                              onChanged: (v) =>
                                  _toggleCheckbox(v!, (val) => showName = val),
                            ),
                            Text(lang.S.of(context).showName),
                          ],
                        ),
                        const SizedBox(height: 20),

                        /// 📋 Data Table
                        selectedProducts.isNotEmpty
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                      Colors.red.shade50),
                                  showBottomBorder: true,
                                  columns: [
                                    DataColumn(
                                        label: Text(lang.S.of(context).name)),
                                    DataColumn(
                                        label: Text(lang.S.of(context).stock)),
                                    DataColumn(
                                        label:
                                            Text(lang.S.of(context).quantity)),
                                    DataColumn(
                                        label:
                                            Text(lang.S.of(context).actions)),
                                  ],
                                  rows: selectedProducts.map((selectedProduct) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(selectedProduct
                                                    .product.productName ??
                                                'N/A'),
                                            Text(
                                                selectedProduct
                                                        .product.productCode ??
                                                    '',
                                                style: const TextStyle(
                                                    color: Colors.grey)),
                                          ],
                                        )),
                                        DataCell(Text(selectedProduct
                                                .product.productStock
                                                ?.toString() ??
                                            '0')),
                                        DataCell(TextFormField(
                                          initialValue: selectedProduct.quantity
                                              .toString(),
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          onChanged: (v) {
                                            setState(() {
                                              selectedProduct.quantity =
                                                  int.tryParse(v) ?? 1;
                                            });
                                          },
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    vertical: 6),
                                          ),
                                        )),
                                        DataCell(IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: kMainColor),
                                          onPressed: () {
                                            setState(() => selectedProducts
                                                .remove(selectedProduct));
                                          },
                                        )),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              )
                            : const Center(
                                child: Column(
                                  children: [
                                    SizedBox(height: 50),
                                    Icon(IconlyLight.document,
                                        color: kMainColor, size: 70),
                                    Text("No items selected",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),
                );
              },
              error: (e, stack) => Text(e.toString()),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
            bottomNavigationBar: businessInfo.when(
              data: (details) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kMainColor,
                              minimumSize: const Size(double.maxFinite, 48),
                            ),
                            onPressed: () async {
                              if (selectedProducts.isNotEmpty) {
                                await _preview(ref);
                              } else {
                                _showSnackBar(
                                    lang.S.of(context).noProductSelected);
                              }
                            },
                            icon: const Icon(Icons.preview),
                            label: Text(lang.S.of(context).previewPdf,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size(double.maxFinite, 48),
                            ),
                            onPressed: () async {
                              if (selectedProducts.isNotEmpty) {
                                await _printToThermal(ref);
                              } else {
                                _showSnackBar(
                                    lang.S.of(context).noProductSelected);
                              }
                            },
                            icon: const Icon(Icons.print),
                            label: const Text('Print (Thermal)',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              error: (e, stack) => Text(e.toString()),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        );
      },
    );
  }
}

class SelectedProduct {
  final ProductModel product;
  int quantity;
  SelectedProduct({required this.product, required this.quantity});
}
