class AddToCartModel {
  AddToCartModel({
    required this.productId,
    this.productCode,
    this.productName,
    this.unitPrice,
    this.quantity = 1,
    this.productDetails,
    this.itemCartIndex = -1,
    this.uniqueCheck,
    this.stock,
    this.productPurchasePrice,
    this.lossProfit,
    this.stockId,
    this.gstRateSelect,
    this.gstType,
    this.vatType,
    this.unitName,
    this.variantKey,
    this.variantLabel,
    this.displayUnit,
    this.displayQuantity,
    this.displayPrice,
  }) {
    // Automatically set 18% GST if not provided
    gstRateSelect = gstRateSelect?.trim();
    if (gstRateSelect == null || gstRateSelect!.isEmpty) {
      gstRateSelect = '0';
    }
    gstType = gstType?.trim();
    if (gstType == null || gstType!.isEmpty) {
      gstType = 'Taxable';
    }
  }

  num productId;
  dynamic productCode;
  String? productName;
  dynamic unitPrice;
  dynamic productPurchasePrice;
  dynamic uniqueCheck;
  num quantity = 1;
  dynamic productDetails;
  int itemCartIndex;
  num? stock;
  num? lossProfit;
  num? stockId;
  String? gstRateSelect;
  String? gstType;
  String? vatType;
  String? unitName;
  String? variantKey;
  String? variantLabel;
  String? displayUnit; // The unit selected for display (e.g., 'g', 'kg')
  num? displayQuantity; // The quantity in display unit (e.g., 900 for 900g)
  num?
      displayPrice; // The price per display unit (e.g., 0.001 for price per gram)

  // Calculate GST amount for this product (always uses GST)
  double calculateGstAmount(String? selectedTaxType) {
    double productTotal =
        quantity * (num.tryParse(unitPrice.toString()) ?? 0).toDouble();

    // Parse GST rate (remove % if present)
    double gstRate = 0.0;
    if (gstRateSelect != null) {
      String rateString = gstRateSelect!.replaceAll('%', '');
      gstRate = num.tryParse(rateString)?.toDouble() ?? 0.0;
    }

    return (productTotal * gstRate) / 100;
  }

  // Get display text for GST info
  String getGstDisplayText(String? selectedTaxType) {
    if (selectedTaxType == null) return '';

    String taxLabel = selectedTaxType;
    String rateText = gstRateSelect ?? '0';
    double gstAmount = calculateGstAmount(selectedTaxType);

    return '$taxLabel ${rateText}% - ${gstAmount.toStringAsFixed(2)}';
  }
}
