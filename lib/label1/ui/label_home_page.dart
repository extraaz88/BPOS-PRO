import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../models/printer_device.dart';

import '../models/print_settings.dart';
import '../services/bluetooth_printer_service.dart';
import '../services/settings_service.dart';
import '../../Provider/product_provider.dart';
import '../../Screens/Products/Model/product_model.dart';
import '../../constant.dart';

class LabelHomePage extends ConsumerStatefulWidget {
  const LabelHomePage({super.key});

  @override
  ConsumerState<LabelHomePage> createState() => _LabelHomePageState();
}

class _LabelHomePageState extends ConsumerState<LabelHomePage> {
  final SettingsService _settingsService = SettingsService();
  final BluetoothPrinterService _printerService = BluetoothPrinterService();

  PrintSettings _settings = PrintSettings.defaults();
  bool _isLoading = true;
  bool _isPrinting = false;
  bool _devicesLoading = false;
  List<PrinterDevice> _devices = <PrinterDevice>[];
  List<ProductModel> _products = [];
  List<SelectedProduct> _selectedProducts = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final loaded = await _settingsService.load();
    List<PrinterDevice> devices = <PrinterDevice>[];
    if (Platform.isAndroid) {
      devices = await _printerService.listBondedDevices();
    }
    setState(() {
      _settings = loaded;
      _devices = devices;
      _isLoading = false;
    });
  }

  Future<void> _refreshDevices() async {
    if (!Platform.isAndroid) return;
    setState(() {
      _devicesLoading = true;
    });
    try {
      final devices = await _printerService.listBondedDevices();
      setState(() {
        _devices = devices;
      });
    } finally {
      setState(() {
        _devicesLoading = false;
      });
    }
  }

  Future<void> _saveSettings(PrintSettings updated) async {
    setState(() {
      _settings = updated;
    });
    await _settingsService.save(updated);
  }

  Future<void> _print() async {
    if (!Platform.isAndroid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth printing supported on Android only in this demo')),
      );
      return;
    }

    if (_selectedProducts.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product to print')),
      );
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      int totalPrinted = 0;
      
      for (var selectedProduct in _selectedProducts) {
        final productCode = selectedProduct.product.productCode ?? '';
        if (productCode.trim().isEmpty) continue;

        // Print each quantity
        for (int i = 0; i < selectedProduct.quantity; i++) {
          await _printerService.printLabel(
            _settings.copyWith(
              data: productCode, // Use exact product code from API
              humanReadable: false, // Barcode ke neeche text nahi dikhana
              productName: selectedProduct.product.productName ?? '',
              productPrice: selectedProduct.product.productSalePrice?.toString() ?? '',
              productBrand: selectedProduct.product.brand?.brandName ?? '',
            ),
          );
          totalPrinted++;
          
          // Small delay between prints to avoid overwhelming the printer
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Successfully sent $totalPrinted label(s) to printer')),
      );
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

  void _addProduct(ProductModel product) {
    setState(() {
      final existingProduct = _selectedProducts.firstWhere(
        (p) => p.product.productCode == product.productCode,
        orElse: () => SelectedProduct(product: product, quantity: 0),
      );

      if (existingProduct.quantity > 0) {
        existingProduct.quantity++;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.productName} quantity increased to ${existingProduct.quantity}')),
        );
      } else {
        _selectedProducts.add(SelectedProduct(product: product, quantity: 1));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added: ${product.productName}')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final productData = ref.watch(productProvider);
    
    return productData.when(
      data: (products) {
        _products = products;
        
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
        
    return Scaffold(
      appBar: AppBar(
        title: const Text('Label Barcode Printing'),
        actions: [
          IconButton(
            onPressed: _devicesLoading ? null : _refreshDevices,
            tooltip: 'Refresh devices',
            icon: _devicesLoading ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ) : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth > 600 ? 24.0 : 12.0;
                return ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 12,
                  ),
          children: [
                _buildProductSearchCard(),
                const SizedBox(height: 12),
                if (_selectedProducts.isNotEmpty) ...[
                  _buildSelectedProductsCard(),
                  const SizedBox(height: 12),
                ],
            _buildPrinterCard(),
            const SizedBox(height: 12),
            _buildLabelCard(),
            const SizedBox(height: 12),
            _buildBarcodeCard(),
            const SizedBox(height: 20),
                Container(
              width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: _selectedProducts.isEmpty
                        ? null
                        : const LinearGradient(
                            colors: [Colors.blue, Colors.blueAccent],
                          ),
                    color: _selectedProducts.isEmpty ? Colors.grey : null,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _selectedProducts.isEmpty
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
              child: ElevatedButton.icon(
                    onPressed: _isPrinting || _selectedProducts.isEmpty ? null : _print,
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.print, size: 22, color: Colors.white),
                    label: Text(
                      _isPrinting
                          ? 'Printing...'
                          : _selectedProducts.isEmpty
                              ? 'Add Products to Print'
                              : 'Print ${_selectedProducts.fold<int>(0, (sum, item) => sum + item.quantity)} Label(s)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Label Barcode Printing')),
        body: Center(
          child: Text('Error loading products: $error'),
        ),
      ),
    );
  }

  Widget _buildProductSearchCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.search, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Select Product',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_selectedProducts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedProducts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
              onSelected: (value) => _addProduct(value),
            ),
            const SizedBox(height: 8),
            Text(
              'Selected: ${_selectedProducts.length} product(s)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tip: Search and add products. Set quantity for each product below.',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedProductsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Selected Products',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedProducts.clear();
                    });
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 56,
                ),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                  showBottomBorder: true,
                  columnSpacing: 12,
                  horizontalMargin: 8,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 60,
                  columns: const [
                    DataColumn(
                      label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    DataColumn(
                      label: Text('Brand', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    DataColumn(
                      label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    DataColumn(
                      label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text('', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                  rows: _selectedProducts.map((selectedProduct) {
                    return DataRow(
                      cells: [
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120, minWidth: 80),
                            child: Text(
                              selectedProduct.product.productName ?? 'N/A',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            selectedProduct.product.brand?.brandName ?? '-',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            selectedProduct.product.productCode ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '₹${selectedProduct.product.productSalePrice ?? 0}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 110,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (selectedProduct.quantity > 1) {
                                        selectedProduct.quantity--;
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: const Icon(Icons.remove, size: 16, color: Colors.red),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Text(
                                      '${selectedProduct.quantity}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedProduct.quantity++;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: const Icon(Icons.add, size: 16, color: Colors.green),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _selectedProducts.remove(selectedProduct);
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.label, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Total Labels to Print: ${_selectedProducts.fold<int>(0, (sum, item) => sum + item.quantity)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bluetooth, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('Bluetooth Printer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _settings.printerAddress.isEmpty ? null : _settings.printerAddress,
              items: _devices.map((d) {
                final addr = d.address;
                final name = d.name;
                return DropdownMenuItem<String>(
                  value: addr,
                  child: Text('$name ($addr)'),
                );
              }).toList(),
              onChanged: (value) {
                PrinterDevice? selected;
                for (final d in _devices) {
                  if (d.address == value) {
                    selected = d;
                    break;
                  }
                }
                _saveSettings(_settings.copyWith(
                  printerAddress: value ?? '',
                  printerName: selected?.name ?? '',
                ));
              },
              decoration: const InputDecoration(
                labelText: 'Select bonded printer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: Pair your label printer in Android Bluetooth settings first. '
              'This app lists bonded devices.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('Label Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PrinterLanguage>(
              value: _settings.printerLanguage,
              items: PrinterLanguage.values.map((t) {
                return DropdownMenuItem<PrinterLanguage>(
                  value: t,
                  child: Text(_languageLabel(t)),
                );
              }).toList(),
              onChanged: (v) {
                if (v == null) return;
                _saveSettings(_settings.copyWith(printerLanguage: v));
              },
              decoration: const InputDecoration(
                labelText: 'Printer language',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;
                return Column(
                  children: [
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    label: 'Width (mm)',
                    value: _settings.labelWidthMm.toString(),
                    onChanged: (v) => _saveSettings(_settings.copyWith(
                      labelWidthMm: double.tryParse(v) ?? _settings.labelWidthMm,
                    )),
                  ),
                ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: _numberField(
                    label: 'Height (mm)',
                    value: _settings.labelHeightMm.toString(),
                    onChanged: (v) => _saveSettings(_settings.copyWith(
                      labelHeightMm: double.tryParse(v) ?? _settings.labelHeightMm,
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    label: 'Gap (mm)',
                    value: _settings.gapMm.toString(),
                    onChanged: (v) => _saveSettings(_settings.copyWith(
                      gapMm: double.tryParse(v) ?? _settings.gapMm,
                    )),
                  ),
                ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: _numberField(
                    label: 'Copies',
                    value: _settings.copies.toString(),
                    onChanged: (v) => _saveSettings(_settings.copyWith(
                      copies: int.tryParse(v) ?? _settings.copies,
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    label: 'Density (0-15)',
                    value: _settings.density.toString(),
                    onChanged: (v) => _saveSettings(_settings.copyWith(
                      density: int.tryParse(v) ?? _settings.density,
                    )),
                  ),
                ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: _numberField(
                            label: 'Rotation',
                    value: _settings.rotation.toString(),
                    onChanged: (v) => _saveSettings(_settings.copyWith(
                      rotation: int.tryParse(v) ?? _settings.rotation,
                    )),
                  ),
                ),
              ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            if (_settings.printerLanguage == PrinterLanguage.escpos) ...[
              DropdownButtonFormField<int>(
                value: _settings.escposAlign,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Left')),
                  DropdownMenuItem(value: 1, child: Text('Center')),
                  DropdownMenuItem(value: 2, child: Text('Right')),
                ],
                onChanged: (v) => _saveSettings(_settings.copyWith(escposAlign: v ?? 1)),
                decoration: const InputDecoration(
                  labelText: 'ESC/POS Align',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              _numberField(
                label: 'ESC/POS Left margin (dots)',
                value: _settings.escposLeftMargin.toString(),
                onChanged: (v) => _saveSettings(_settings.copyWith(
                  escposLeftMargin: int.tryParse(v) ?? _settings.escposLeftMargin,
                )),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.qr_code_2, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('Barcode Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<BarcodeType>(
              value: _settings.barcodeType,
              items: BarcodeType.values.map((t) {
                return DropdownMenuItem<BarcodeType>(
                  value: t,
                  child: Text(_barcodeTypeLabel(t)),
                );
              }).toList(),
              onChanged: (v) {
                if (v == null) return;
                _saveSettings(_settings.copyWith(barcodeType: v));
              },
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
              children: [
                  const Icon(Icons.check_circle, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                Expanded(
                    child: Text(
                      _selectedProducts.isEmpty
                          ? 'Add products above to print their barcodes'
                          : 'Product codes from API will be printed exactly as received',
                      style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
              ),
            if (_settings.barcodeType == BarcodeType.qrcode) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      label: 'QR unit (1-10)',
                      value: _settings.qrUnitSize.toString(),
                      onChanged: (v) => _saveSettings(_settings.copyWith(
                        qrUnitSize: int.tryParse(v) ?? _settings.qrUnitSize,
                      )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _settings.qrErrorLevel,
                      items: const [
                        DropdownMenuItem(value: 'L', child: Text('L (7%)', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'M', child: Text('M (15%)', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'Q', child: Text('Q (25%)', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'H', child: Text('H (30%)', style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (v) => _saveSettings(_settings.copyWith(qrErrorLevel: v ?? 'M')),
                      decoration: const InputDecoration(
                        labelText: 'QR error level',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _numberField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: value,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }

  String _barcodeTypeLabel(BarcodeType t) {
    switch (t) {
      case BarcodeType.code128:
        return 'CODE128';
      case BarcodeType.code39:
        return 'CODE39';
      case BarcodeType.ean13:
        return 'EAN13';
      case BarcodeType.qrcode:
        return 'QRCODE';
    }
  }

  String _languageLabel(PrinterLanguage t) {
    switch (t) {
      case PrinterLanguage.tspl:
        return 'TSPL (TSC)';
      case PrinterLanguage.cpcl:
        return 'CPCL (Zebra/others)';
      case PrinterLanguage.zpl:
        return 'ZPL (Zebra)';
      case PrinterLanguage.escpos:
        return 'ESC/POS (receipt)';
    }
  }
}

class SelectedProduct {
  final ProductModel product;
  int quantity;

  SelectedProduct({
    required this.product,
    required this.quantity,
  });
}
