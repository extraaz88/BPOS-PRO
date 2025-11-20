import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../Screens/Purchase/Model/purchase_transaction_model.dart';
import '../../constant.dart';
import '../../model/sale_transaction_model.dart';
import '../model/print_transaction_model.dart';
import '../thermal_invoice_due.dart';
import '../thermal_invoice_purchase.dart';
import '../thermal_invoice_sales.dart';

final thermalPrinterProvider =
    ChangeNotifierProvider((ref) => ThermalPrinter());

class ThermalPrinter extends ChangeNotifier {
  List<BluetoothInfo> availableBluetoothDevices = [];
  bool isBluetoothConnected = false;

  /// 🔹 Get paired devices + connection status
  Future<void> getBluetooth() async {
    try {
      availableBluetoothDevices = await PrintBluetoothThermal.pairedBluetooths;
      isBluetoothConnected = await PrintBluetoothThermal.connectionStatus;
      notifyListeners();
    } catch (e) {
      print("Error getting Bluetooth devices: $e");
    }
  }

  /// 🔹 Connect to selected printer
  Future<bool> setConnect(String mac) async {
    bool status = false;
    try {
      final bool result =
          await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      if (result == true) {
        isBluetoothConnected = true;
        status = true;
      }
    } catch (e) {
      print("Bluetooth connection error: $e");
    }
    notifyListeners();
    return status;
  }

  /// 🔹 Bluetooth Device List Dialog
  Future<dynamic> listOfBluDialog({required BuildContext context}) async {
    return showCupertinoDialog(
      context: context,
      builder: (dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: CupertinoAlertDialog(
              insetAnimationCurve: Curves.bounceInOut,
              content: Container(
                height: availableBluetoothDevices.isNotEmpty
                    ? (availableBluetoothDevices.length * 80).toDouble()
                    : 150,
                width: double.maxFinite,
                child: availableBluetoothDevices.isNotEmpty
                    ? ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: availableBluetoothDevices.length,
                        itemBuilder: (context1, index) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () async {
                              BluetoothInfo select =
                                  availableBluetoothDevices[index];
                              bool isConnect =
                                  await setConnect(select.macAdress);
                              if (isConnect) {
                                if (context1.mounted) {
                                  Navigator.pop(context1);
                                }
                              } else {
                                toast(lang.S.of(context1).tryAgain);
                              }
                            },
                            title: Text(
                              availableBluetoothDevices[index].name,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              lang.S.of(context1).clickToConnect,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bluetooth_disabled,
                              size: 40,
                              color: kMainColor,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Not available',
                              style: TextStyle(
                                  fontSize: 14, color: kGreyTextColor),
                            )
                          ],
                        ),
                      ),
              ),
              title: const Text(
                'Connect Your Device',
                textAlign: TextAlign.start,
              ),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: Text(
                    lang.S.of(dialogContext).cancel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onPressed: () {
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🔹 Print Sales Invoice
  Future<void> printSalesThermalInvoiceNow({
    required PrintTransactionModel transaction,
    required List<SalesDetails>? productList,
    required BuildContext context,
  }) async {
    await getBluetooth();
    isBluetoothConnected
        ? SalesThermalPrinterInvoice().printSalesTicket(
            printTransactionModel: transaction, productList: productList)
        : listOfBluDialog(context: context);
  }

  /// 🔹 Print Sales Invoice (Multilingual)
  Future<void> printMultilingualSalesThermalInvoiceNow({
    required PrintTransactionModel transaction,
    required List<SalesDetails>? productList,
    required BuildContext context,
  }) async {
    await getBluetooth();
    isBluetoothConnected
        ? SalesThermalPrinterInvoice().printMultilingualSalesTicket(
            printTransactionModel: transaction, productList: productList)
        : listOfBluDialog(context: context);
  }

  /// 🔹 Print Purchase Invoice
  Future<void> printPurchaseThermalInvoiceNow({
    required PrintPurchaseTransactionModel transaction,
    required List<PurchaseDetails>? productList,
    required BuildContext context,
  }) async {
    await getBluetooth();
    isBluetoothConnected
        ? PurchaseThermalPrinterInvoice().printPurchaseThermalInvoice(
            printTransactionModel: transaction, productList: productList)
        : listOfBluDialog(context: context);
  }

  /// 🔹 Print Purchase Invoice (Multilingual)
  Future<void> printMultilingualPurchaseThermalInvoiceNow({
    required PrintPurchaseTransactionModel transaction,
    required List<PurchaseDetails>? productList,
    required BuildContext context,
  }) async {
    await getBluetooth();
    isBluetoothConnected
        ? PurchaseThermalPrinterInvoice().printMultilingualPurchaseInvoice(
            printTransactionModel: transaction, productList: productList)
        : listOfBluDialog(context: context);
  }

  /// 🔹 Print Due Invoice
  Future<void> printDueThermalInvoiceNow({
    required PrintDueTransactionModel transaction,
    required BuildContext context,
  }) async {
    await getBluetooth();
    isBluetoothConnected
        ? DueThermalPrinterInvoice()
            .printDueTicket(printDueTransactionModel: transaction)
        : listOfBluDialog(context: context);
  }

  /// 🔹 Print Due Invoice (Multilingual)
  Future<void> printMultilingualDueThermalInvoiceNow({
    required PrintDueTransactionModel transaction,
    required BuildContext context,
  }) async {
    await getBluetooth();
    isBluetoothConnected
        ? DueThermalPrinterInvoice()
            .printDueTicket(printDueTransactionModel: transaction)
        : listOfBluDialog(context: context);
  }

  /// 🔹 Print PDF/Image bytes to Thermal Printer (Fixed)
  Future<void> printPdfBytes(Uint8List bytes) async {
    await getBluetooth();

    if (!isBluetoothConnected) {
      toast("Please connect to a Bluetooth printer first");
      return;
    }

    try {
      // ✅ Convert Uint8List to List<int> so the platform channel marshals a Java List
      final List<int> listBytes = bytes.toList();

      await PrintBluetoothThermal.writeBytes(listBytes);
      toast("Printing successful");
    } catch (e) {
      print("Thermal print failed: $e");
      toast("Printing failed: $e");
    }
  }
}
