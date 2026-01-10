import 'dart:convert';

enum BarcodeType {
  code128,
  code39,
  ean13,
  qrcode,
}

enum PrinterLanguage {
  tspl,
  cpcl,
  zpl,
  escpos,
}

class PrintSettings {
  final String printerName;
  final String printerAddress;

  // Label size in millimeters
  final double labelWidthMm;
  final double labelHeightMm;
  final double gapMm; // Gap/spacing in millimeters

  // Print parameters
  final int density; // 0..15
  final int copies; // >= 1
  final int rotation; // 0, 90, 180, 270 (maps to TSPL rotation 0..3)
  final PrinterLanguage printerLanguage;
  // ESC/POS-only adjustments
  final int escposAlign; // 0 left, 1 center, 2 right
  final int escposLeftMargin; // dots

  // Content
  final BarcodeType barcodeType;
  final String data;
  final bool humanReadable; // For 1D barcodes
  
  // Product information
  final String? productName;
  final String? productPrice;
  final String? productBrand;

  // Position and size
  final int x; // dots
  final int y; // dots
  final int barcodeHeight; // dots (for 1D)
  final int qrUnitSize; // 1..10 (for QR)
  final String qrErrorLevel; // L, M, Q, H

  const PrintSettings({
    required this.printerName,
    required this.printerAddress,
    required this.labelWidthMm,
    required this.labelHeightMm,
    required this.gapMm,
    required this.density,
    required this.copies,
    required this.rotation,
    required this.printerLanguage,
    required this.escposAlign,
    required this.escposLeftMargin,
    required this.barcodeType,
    required this.data,
    required this.humanReadable,
    required this.x,
    required this.y,
    required this.barcodeHeight,
    required this.qrUnitSize,
    required this.qrErrorLevel,
    this.productName,
    this.productPrice,
    this.productBrand,
  });

  PrintSettings copyWith({
    String? printerName,
    String? printerAddress,
    double? labelWidthMm,
    double? labelHeightMm,
    double? gapMm,
    int? density,
    int? copies,
    int? rotation,
    PrinterLanguage? printerLanguage,
    int? escposAlign,
    int? escposLeftMargin,
    BarcodeType? barcodeType,
    String? data,
    bool? humanReadable,
    int? x,
    int? y,
    int? barcodeHeight,
    int? qrUnitSize,
    String? qrErrorLevel,
    String? productName,
    String? productPrice,
    String? productBrand,
  }) {
    return PrintSettings(
      printerName: printerName ?? this.printerName,
      printerAddress: printerAddress ?? this.printerAddress,
      labelWidthMm: labelWidthMm ?? this.labelWidthMm,
      labelHeightMm: labelHeightMm ?? this.labelHeightMm,
      gapMm: gapMm ?? this.gapMm,
      density: density ?? this.density,
      copies: copies ?? this.copies,
      rotation: rotation ?? this.rotation,
      printerLanguage: printerLanguage ?? this.printerLanguage,
      escposAlign: escposAlign ?? this.escposAlign,
      escposLeftMargin: escposLeftMargin ?? this.escposLeftMargin,
      barcodeType: barcodeType ?? this.barcodeType,
      data: data ?? this.data,
      humanReadable: humanReadable ?? this.humanReadable,
      x: x ?? this.x,
      y: y ?? this.y,
      barcodeHeight: barcodeHeight ?? this.barcodeHeight,
      qrUnitSize: qrUnitSize ?? this.qrUnitSize,
      qrErrorLevel: qrErrorLevel ?? this.qrErrorLevel,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      productBrand: productBrand ?? this.productBrand,
    );
  }

  static PrintSettings defaults() {
    return const PrintSettings(
      printerName: '',
      printerAddress: '',
      labelWidthMm: 60.0,
      labelHeightMm: 40.0,
      gapMm: 2.0,
      density: 10,
      copies: 1,
      rotation: 0,
      printerLanguage: PrinterLanguage.tspl,
      escposAlign: 1,
      escposLeftMargin: 0,
      barcodeType: BarcodeType.code128,
      data: '123456789012',
      humanReadable: true,
      x: 40,
      y: 40,
      barcodeHeight: 120,
      qrUnitSize: 6,
      qrErrorLevel: 'M',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'printerName': printerName,
      'printerAddress': printerAddress,
      'labelWidthMm': labelWidthMm,
      'labelHeightMm': labelHeightMm,
      'gapMm': gapMm,
      'density': density,
      'copies': copies,
      'rotation': rotation,
      'printerLanguage': printerLanguage.name,
      'escposAlign': escposAlign,
      'escposLeftMargin': escposLeftMargin,
      'barcodeType': barcodeType.name,
      'data': data,
      'humanReadable': humanReadable,
      'x': x,
      'y': y,
      'barcodeHeight': barcodeHeight,
      'qrUnitSize': qrUnitSize,
      'qrErrorLevel': qrErrorLevel,
      'productName': productName,
      'productPrice': productPrice,
      'productBrand': productBrand,
    };
  }

  factory PrintSettings.fromJson(Map<String, dynamic> json) {
    final typeString = json['barcodeType'] as String? ?? BarcodeType.code128.name;
    final BarcodeType type = BarcodeType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => BarcodeType.code128,
    );
    final langString = json['printerLanguage'] as String? ?? PrinterLanguage.tspl.name;
    final PrinterLanguage lang = PrinterLanguage.values.firstWhere(
      (e) => e.name == langString,
      orElse: () => PrinterLanguage.tspl,
    );
    return PrintSettings(
      printerName: json['printerName'] as String? ?? '',
      printerAddress: json['printerAddress'] as String? ?? '',
      labelWidthMm: (json['labelWidthMm'] as num?)?.toDouble() ?? 60.0,
      labelHeightMm: (json['labelHeightMm'] as num?)?.toDouble() ?? 40.0,
      gapMm: (json['gapMm'] as num?)?.toDouble() ?? 2.0,
      density: (json['density'] as num?)?.toInt() ?? 10,
      copies: (json['copies'] as num?)?.toInt() ?? 1,
      rotation: (json['rotation'] as num?)?.toInt() ?? 0,
      printerLanguage: lang,
      escposAlign: (json['escposAlign'] as num?)?.toInt() ?? 1,
      escposLeftMargin: (json['escposLeftMargin'] as num?)?.toInt() ?? 0,
      barcodeType: type,
      data: json['data'] as String? ?? '',
      humanReadable: json['humanReadable'] as bool? ?? true,
      x: (json['x'] as num?)?.toInt() ?? 40,
      y: (json['y'] as num?)?.toInt() ?? 40,
      barcodeHeight: (json['barcodeHeight'] as num?)?.toInt() ?? 120,
      qrUnitSize: (json['qrUnitSize'] as num?)?.toInt() ?? 6,
      qrErrorLevel: json['qrErrorLevel'] as String? ?? 'M',
      productName: json['productName'] as String?,
      productPrice: json['productPrice'] as String?,
      productBrand: json['productBrand'] as String?,
    );
  }

  String toEncoded() => jsonEncode(toJson());
  factory PrintSettings.fromEncoded(String encoded) =>
      PrintSettings.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
}


