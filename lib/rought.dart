// import 'package:flutter/material.dart';
// import 'package:barcode_widget/barcode_widget.dart' as bw;
// import 'package:mobile_scanner/mobile_scanner.dart' as ms;
// import 'package:animated_text_kit/animated_text_kit.dart';

// class BarcodeGeneratorScreen extends StatefulWidget {
//   const BarcodeGeneratorScreen({super.key});

//   @override
//   State<BarcodeGeneratorScreen> createState() => _BarcodeGeneratorScreenState();
// }

// class _BarcodeGeneratorScreenState extends State<BarcodeGeneratorScreen> {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController priceController = TextEditingController();
//   final TextEditingController createDateController = TextEditingController();
//   final TextEditingController expireDateController = TextEditingController();

//   String? barcodeData;
//   bool showScanner = false;
//   String? scannedData;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.blue.shade50,
//       appBar: AppBar(
//         backgroundColor: Colors.blue.shade700,
//         title: const Text(
//           'Barcode Creator & Scanner',
//           style: TextStyle(color: Colors.white),
//         ),
//         centerTitle: true,
//       ),
//       body: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 500),
//         child: showScanner ? buildScannerView() : buildFormView(),
//       ),
//     );
//   }

//   /// ================= FORM VIEW =====================
//   Widget buildFormView() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           AnimatedTextKit(
//             animatedTexts: [
//               ColorizeAnimatedText(
//                 'Enter Product Details',
//                 textStyle:
//                     const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                 colors: [Colors.blue, Colors.deepPurple, Colors.cyan],
//               ),
//             ],
//             repeatForever: true,
//           ),
//           const SizedBox(height: 20),

//           buildTextField(nameController, 'Product Name'),
//           buildTextField(priceController, 'Product Price'),
//           buildTextField(createDateController, 'Create Date (DD/MM/YYYY)'),
//           buildTextField(expireDateController, 'Expire Date (DD/MM/YYYY)'),

//           const SizedBox(height: 20),

//           ElevatedButton.icon(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue.shade700,
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12)),
//               padding:
//                   const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
//             ),
//             onPressed: () {
//               if (nameController.text.isNotEmpty) {
//                 final data =
//                     "Name: ${nameController.text}\nPrice: ${priceController.text}\nCreated: ${createDateController.text}\nExpire: ${expireDateController.text}";
//                 setState(() => barcodeData = data);
//               }
//             },
//             icon: const Icon(Icons.qr_code_2, color: Colors.white),
//             label: const Text(
//               "Generate Barcode",
//               style: TextStyle(color: Colors.white),
//             ),
//           ),

//           const SizedBox(height: 20),

//           if (barcodeData != null)
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 500),
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
//               ),
//               child: Column(
//                 children: [
//                   bw.BarcodeWidget(
//                     data: barcodeData!,
//                     barcode: bw.Barcode.code128(),
//                     width: 250,
//                     height: 100,
//                   ),
//                   const SizedBox(height: 10),
//                   const Text(
//                     'Scan this barcode to view details',
//                     style: TextStyle(fontSize: 14),
//                   ),
//                 ],
//               ),
//             ),

//           const SizedBox(height: 30),

//           ElevatedButton.icon(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.deepPurple,
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12)),
//               padding:
//                   const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
//             ),
//             onPressed: () => setState(() => showScanner = true),
//             icon: const Icon(Icons.camera_alt, color: Colors.white),
//             label: const Text(
//               "Open Scanner",
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// ================= SCANNER VIEW =====================
//   Widget buildScannerView() {
//     return Stack(
//       children: [
//         ms.MobileScanner(
//           onDetect: (capture) {
//             final List<ms.Barcode> barcodes = capture.barcodes;
//             for (final barcode in barcodes) {
//               if (barcode.rawValue != null) {
//                 setState(() {
//                   scannedData = barcode.rawValue;
//                   showScanner = false;
//                 });
//                 break;
//               }
//             }
//           },
//         ),
//         Positioned(
//           top: 40,
//           left: 10,
//           child: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.white),
//             onPressed: () => setState(() => showScanner = false),
//           ),
//         ),
//       ],
//     );
//   }

//   /// ================= Text Field UI =====================
//   Widget buildTextField(TextEditingController controller, String label) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 15),
//       child: TextField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           filled: true,
//           fillColor: Colors.white,
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       ),
//     );
//   }

//   /// ================= SCANNED RESULT DIALOG =====================
//   @override
//   void didUpdateWidget(covariant BarcodeGeneratorScreen oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (scannedData != null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             title: const Text('Scanned Product Details'),
//             content: Text(scannedData!),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Close'),
//               ),
//             ],
//           ),
//         );
//       });
//     }
//   }
// }
