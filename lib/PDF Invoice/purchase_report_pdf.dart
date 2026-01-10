import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/currency.dart';
import 'package:mobile_pos/generated/l10n.dart' as l;
import 'package:mobile_pos/model/business_setting_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../Screens/Purchase/Model/purchase_transaction_model.dart';
import '../model/business_info_model.dart';
import 'pdf_common_functions.dart';

class PurchaseReportPdf {
  static Future<void> generatePurchaseReport({
    required List<PurchaseTransaction> transactions,
    required BusinessInformation personalInformation,
    required BuildContext context,
    required BusinessSettingModel businessSetting,
    required DateTime fromDate,
    required DateTime toDate,
    bool? isShare,
  }) async {
    final pw.Document doc = pw.Document();
    final _lang = l.S.of(context);

    // Filter transactions by date range
    final filteredTransactions = transactions.where((element) {
      final transactionDate = DateTime.parse(element.purchaseDate ?? '');
      return (fromDate.isBefore(transactionDate) ||
              transactionDate.isAtSameMomentAs(fromDate)) &&
          (toDate.isAfter(transactionDate) ||
              transactionDate.isAtSameMomentAs(toDate));
    }).toList();

    // Calculate totals
    double totalPurchase = 0;
    double totalPaid = 0;
    double totalDue = 0;

    for (var transaction in filteredTransactions) {
      totalPurchase += transaction.totalAmount ?? 0;
      totalPaid += (transaction.totalAmount ?? 0) - (transaction.dueAmount ?? 0);
      totalDue += transaction.dueAmount ?? 0;
    }

    EasyLoading.show(status: _lang.generatingPdf);

    final String imageUrl = '${APIConfig.domain}${businessSetting.pictureUrl}';
    dynamic imageData = await PDFCommonFunctions().getNetworkImage(imageUrl);
    imageData ??= await PDFCommonFunctions().loadAssetImage('images/logo.png');

    final englishFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final banglaFont = pw.Font.ttf(await rootBundle.load('assets/fonts/siyam_rupali_ansi.ttf'));
    final arabicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Regular.ttf'));
    final hindiFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Hind-Regular.ttf'));
    final frenchFont = pw.Font.ttf(await rootBundle.load('assets/fonts/GFSDidot-Regular.ttf'));

    getFont() {
      if (selectedLanguage == 'en') {
        return englishFont;
      } else if (selectedLanguage == 'bn') {
        return banglaFont;
      } else if (selectedLanguage == 'ar') {
        return arabicFont;
      } else if (selectedLanguage == 'hi') {
        return hindiFont;
      } else if (selectedLanguage == 'mr') {
        return hindiFont;
      } else if (selectedLanguage == 'fr') {
        return frenchFont;
      } else {
        return englishFont;
      }
    }

    getFontWithLangMatching(String data) {
      String detectedLanguage = detectLanguageEnhanced(data);
      if (detectedLanguage == 'en') {
        return englishFont;
      } else if (detectedLanguage == 'bn') {
        return banglaFont;
      } else if (detectedLanguage == 'ar') {
        return arabicFont;
      } else if (detectedLanguage == 'hi') {
        return hindiFont;
      } else if (detectedLanguage == 'mr') {
        return hindiFont;
      } else if (detectedLanguage == 'fr') {
        return frenchFont;
      } else {
        return englishFont;
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.all(20),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      if (imageData is Uint8List)
                        pw.Container(
                          height: 50,
                          width: 50,
                          child: pw.Image(
                            pw.MemoryImage(imageData),
                            fit: pw.BoxFit.cover,
                          ),
                        )
                      else if (imageData is String)
                        pw.Container(
                          height: 50,
                          width: 50,
                          child: pw.SvgImage(
                            svg: imageData,
                            fit: pw.BoxFit.cover,
                          ),
                        )
                      else
                        pw.Container(
                          height: 50,
                          width: 50,
                          child: pw.Image(pw.MemoryImage(imageData)),
                        ),
                      pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          getLocalizedPdfTextWithLanguage(
                            personalInformation.companyName ?? '',
                            pw.TextStyle(
                              color: PdfColors.black,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              fontFallback: [englishFont],
                              font: getFontWithLangMatching(personalInformation.companyName ?? ''),
                            ),
                          ),
                          getLocalizedPdfText(
                            '${_lang.mobile}: ${personalInformation.phoneNumber ?? ''}',
                            pw.TextStyle(
                              color: PdfColors.black,
                              font: getFont(),
                              fontFallback: [englishFont],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xff2196F3),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: getLocalizedPdfText(
                      _lang.purchaseReport,
                      pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                        font: getFont(),
                        fontFallback: [englishFont],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  getLocalizedPdfText(
                    '${_lang.fromDate}: ${DateFormat.yMMMd().format(fromDate)}',
                    pw.TextStyle(
                      color: PdfColors.black,
                      fontSize: 12,
                      font: getFont(),
                      fontFallback: [englishFont],
                    ),
                  ),
                  getLocalizedPdfText(
                    '${_lang.toDate}: ${DateFormat.yMMMd().format(toDate)}',
                    pw.TextStyle(
                      color: PdfColors.black,
                      fontSize: 12,
                      font: getFont(),
                      fontFallback: [englishFont],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
              pw.Container(
                width: double.infinity,
                color: PdfColor.fromInt(0xff2196F3),
                padding: pw.EdgeInsets.all(10),
                child: pw.Center(
                  child: pw.Text(
                    'Powered by $companyName',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        build: (pw.Context context) => <pw.Widget>[
          // Summary Section
          pw.Container(
            padding: pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xffE3F2FD),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColor.fromInt(0xff2196F3)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    getLocalizedPdfText(
                      _lang.totalPurchase,
                      pw.TextStyle(
                        color: PdfColors.black,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        font: getFont(),
                        fontFallback: [englishFont],
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '$currency${totalPurchase.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        color: PdfColor.fromInt(0xff4CAF50),
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Container(width: 1, height: 40, color: PdfColor.fromInt(0xff2196F3)),
                pw.Column(
                  children: [
                    getLocalizedPdfText(
                      _lang.paid,
                      pw.TextStyle(
                        color: PdfColors.black,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        font: getFont(),
                        fontFallback: [englishFont],
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '$currency${totalPaid.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        color: PdfColor.fromInt(0xff2196F3),
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Container(width: 1, height: 40, color: PdfColor.fromInt(0xff2196F3)),
                pw.Column(
                  children: [
                    getLocalizedPdfText(
                      _lang.totalDue,
                      pw.TextStyle(
                        color: PdfColors.black,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        font: getFont(),
                        fontFallback: [englishFont],
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '$currency${totalDue.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        color: PdfColor.fromInt(0xffF44336),
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Container(width: 1, height: 40, color: PdfColor.fromInt(0xff2196F3)),
                pw.Column(
                  children: [
                    pw.Text(
                      'Total Transactions',
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        font: getFont(),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '${filteredTransactions.length}',
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Transactions Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromInt(0xffD9D9D9)),
            columnWidths: {
              0: pw.FlexColumnWidth(0.5),
              1: pw.FlexColumnWidth(1.5),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(1.5),
              4: pw.FlexColumnWidth(1.2),
              5: pw.FlexColumnWidth(1),
              6: pw.FlexColumnWidth(1),
              7: pw.FlexColumnWidth(1),
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xff2196F3)),
                children: [
                  _buildHeaderCell(_lang.sl, getFont(), englishFont),
                  _buildHeaderCell(_lang.date, getFont(), englishFont),
                  _buildHeaderCell(_lang.supplierName, getFont(), englishFont),
                  _buildHeaderCell(_lang.invoiceNumber, getFont(), englishFont),
                  _buildHeaderCell(_lang.paymentTypes, getFont(), englishFont),
                  _buildHeaderCell(_lang.total, getFont(), englishFont),
                  _buildHeaderCell(_lang.paid, getFont(), englishFont),
                  _buildHeaderCell(_lang.due, getFont(), englishFont),
                ],
              ),
              // Data Rows
              for (int i = 0; i < filteredTransactions.length; i++)
                pw.TableRow(
                  decoration: i % 2 == 0
                      ? pw.BoxDecoration(color: PdfColors.white)
                      : pw.BoxDecoration(color: PdfColor.fromInt(0xffF5F5F5)),
                  children: [
                    _buildDataCell('${i + 1}', getFont(), englishFont),
                    _buildDataCell(
                      DateFormat.yMMMd().format(DateTime.parse(filteredTransactions[i].purchaseDate ?? '')),
                      getFont(),
                      englishFont,
                    ),
                    _buildDataCellWithLanguage(
                      filteredTransactions[i].party?.name ?? 'N/A',
                      getFontWithLangMatching(filteredTransactions[i].party?.name ?? 'N/A'),
                      englishFont,
                    ),
                    _buildDataCell(
                      '#${filteredTransactions[i].invoiceNumber ?? ''}',
                      getFont(),
                      englishFont,
                    ),
                    _buildDataCell(
                      filteredTransactions[i].paymentType?.name ?? 'N/A',
                      getFont(),
                      englishFont,
                    ),
                    _buildDataCell(
                      '${filteredTransactions[i].totalAmount?.toStringAsFixed(2) ?? '0'}',
                      getFont(),
                      englishFont,
                    ),
                    _buildDataCell(
                      '${((filteredTransactions[i].totalAmount ?? 0) - (filteredTransactions[i].dueAmount ?? 0)).toStringAsFixed(2)}',
                      getFont(),
                      englishFont,
                    ),
                    _buildDataCell(
                      '${filteredTransactions[i].dueAmount?.toStringAsFixed(2) ?? '0'}',
                      getFont(),
                      englishFont,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    await PDFCommonFunctions.savePdfAndShowPdf(
      context: context,
      shopName: personalInformation.companyName ?? '',
      invoice: 'PurchaseReport_${DateFormat('yyyyMMdd').format(fromDate)}_${DateFormat('yyyyMMdd').format(toDate)}',
      doc: doc,
      isShare: isShare,
    );
  }

  static pw.Widget _buildHeaderCell(String text, pw.Font font, pw.Font fallbackFont) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      child: getLocalizedPdfText(
        text,
        pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
          font: font,
          fontFallback: [fallbackFont],
        ),
        textAlignment: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildDataCell(String text, pw.Font font, pw.Font fallbackFont) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      child: getLocalizedPdfText(
        text,
        pw.TextStyle(
          color: PdfColors.black,
          fontSize: 9,
          font: font,
          fontFallback: [fallbackFont],
        ),
        textAlignment: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildDataCellWithLanguage(String text, pw.Font font, pw.Font fallbackFont) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      child: getLocalizedPdfTextWithLanguage(
        text,
        pw.TextStyle(
          color: PdfColors.black,
          fontSize: 9,
          font: font,
          fontFallback: [fallbackFont],
        ),
        textAlignment: pw.TextAlign.center,
      ),
    );
  }
}

