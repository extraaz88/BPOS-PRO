class HoldOrderModel {
  String? id;
  String? orderType; // 'sale' or 'purchase'
  String? customerName;
  int? customerId;
  String? customerPhone;
  String? date;
  List<HoldOrderItem>? items;
  double? subtotal;
  double? discountAmount;
  double? discountPercent;
  String? discountType;
  double? vatAmount;
  double? shippingCharge;
  double? serviceCharge;
  double? totalAmount;
  double? paidAmount;
  double? dueAmount;
  int? paymentTypeId;
  String? selectedTaxType;
  String? note;
  DateTime? createdAt;
  
  // Split payment fields
  bool? isSplitPayment;
  double? splitCashAmount;
  double? splitOnlineAmount;

  HoldOrderModel({
    this.id,
    this.orderType,
    this.customerName,
    this.customerId,
    this.customerPhone,
    this.date,
    this.items,
    this.subtotal,
    this.discountAmount,
    this.discountPercent,
    this.discountType,
    this.vatAmount,
    this.shippingCharge,
    this.serviceCharge,
    this.totalAmount,
    this.paidAmount,
    this.dueAmount,
    this.paymentTypeId,
    this.selectedTaxType,
    this.note,
    this.createdAt,
    this.isSplitPayment,
    this.splitCashAmount,
    this.splitOnlineAmount,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderType': orderType,
      'customerName': customerName,
      'customerId': customerId,
      'customerPhone': customerPhone,
      'date': date,
      'items': items?.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'discountPercent': discountPercent,
      'discountType': discountType,
      'vatAmount': vatAmount,
      'shippingCharge': shippingCharge,
      'serviceCharge': serviceCharge,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'dueAmount': dueAmount,
      'paymentTypeId': paymentTypeId,
      'selectedTaxType': selectedTaxType,
      'note': note,
      'createdAt': createdAt?.toIso8601String(),
      'isSplitPayment': isSplitPayment,
      'splitCashAmount': splitCashAmount,
      'splitOnlineAmount': splitOnlineAmount,
    };
  }

  // Create from Map
  factory HoldOrderModel.fromMap(Map<String, dynamic> map) {
    return HoldOrderModel(
      id: map['id'],
      orderType: map['orderType'],
      customerName: map['customerName'],
      customerId: map['customerId'],
      customerPhone: map['customerPhone'],
      date: map['date'],
      items: map['items'] != null
          ? List<HoldOrderItem>.from(
              map['items'].map((item) => HoldOrderItem.fromMap(item)))
          : null,
      subtotal: map['subtotal']?.toDouble(),
      discountAmount: map['discountAmount']?.toDouble(),
      discountPercent: map['discountPercent']?.toDouble(),
      discountType: map['discountType'],
      vatAmount: map['vatAmount']?.toDouble(),
      shippingCharge: map['shippingCharge']?.toDouble(),
      serviceCharge: map['serviceCharge']?.toDouble(),
      totalAmount: map['totalAmount']?.toDouble(),
      paidAmount: map['paidAmount']?.toDouble(),
      dueAmount: map['dueAmount']?.toDouble(),
      paymentTypeId: map['paymentTypeId'],
      selectedTaxType: map['selectedTaxType'],
      note: map['note'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'])
          : null,
      isSplitPayment: map['isSplitPayment'],
      splitCashAmount: map['splitCashAmount']?.toDouble(),
      splitOnlineAmount: map['splitOnlineAmount']?.toDouble(),
    );
  }
}

class HoldOrderItem {
  String? productName;
  int? productId;
  double? quantity;
  double? unitPrice;
  double? purchasePrice;
  double? wholeSalePrice;
  double? dealerPrice;
  double? salePrice;
  String? productCode;
  int? stockId;
  double? stock;
  String? gstRateSelect;
  String? gstType;
  String? vatType;
  double? vatAmount;

  HoldOrderItem({
    this.productName,
    this.productId,
    this.quantity,
    this.unitPrice,
    this.purchasePrice,
    this.wholeSalePrice,
    this.dealerPrice,
    this.salePrice,
    this.productCode,
    this.stockId,
    this.stock,
    this.gstRateSelect,
    this.gstType,
    this.vatType,
    this.vatAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'purchasePrice': purchasePrice,
      'wholeSalePrice': wholeSalePrice,
      'dealerPrice': dealerPrice,
      'salePrice': salePrice,
      'productCode': productCode,
      'stockId': stockId,
      'stock': stock,
      'gstRateSelect': gstRateSelect,
      'gstType': gstType,
      'vatType': vatType,
      'vatAmount': vatAmount,
    };
  }

  factory HoldOrderItem.fromMap(Map<String, dynamic> map) {
    return HoldOrderItem(
      productName: map['productName'],
      productId: map['productId'],
      quantity: map['quantity']?.toDouble(),
      unitPrice: map['unitPrice']?.toDouble(),
      purchasePrice: map['purchasePrice']?.toDouble(),
      wholeSalePrice: map['wholeSalePrice']?.toDouble(),
      dealerPrice: map['dealerPrice']?.toDouble(),
      salePrice: map['salePrice']?.toDouble(),
      productCode: map['productCode'],
      stockId: map['stockId'],
      stock: map['stock']?.toDouble(),
      gstRateSelect: map['gstRateSelect'],
      gstType: map['gstType'],
      vatType: map['vatType'],
      vatAmount: map['vatAmount']?.toDouble(),
    );
  }
}

