class ProductModel {
  ProductModel({
    this.id,
    this.productName,
    this.businessId,
    this.unitId,
    this.brandId,
    this.categoryId,
    this.productCode,
    this.productPicture,
    this.productDealerPrice,
    this.productPurchasePrice,
    this.productSalePrice,
    this.productWholeSalePrice,
    this.productStock,
    this.alertQty,
    this.expireDate,
    this.productDiscount,
    this.size,
    this.vatType,
    this.gstRateSelect,
    this.gstType,
    this.type,
    this.color,
    this.weight,
    this.capacity,
    this.productManufacturer,
    this.createdAt,
    this.updatedAt,
    this.unit,
    this.brand,
    this.category,
    this.vatId,
    this.vatAmount,
    this.profitMargin,
    this.stocks,
    this.variants,
    this.productStatus,
    this.productType,
  });

  ProductModel.fromJson(dynamic json) {
    id = json['id'];
    productName = json['productName'];
    businessId = json['business_id'];
    unitId = json['unit_id'];
    vatId = json['vat_id'];
    brandId = json['brand_id'];
    categoryId = json['category_id'];
    productCode = json['productCode'];
    productPicture = json['productPicture'];
    productDealerPrice = json['productDealerPrice'];
    productPurchasePrice = json['productPurchasePrice'];
    productSalePrice = json['productSalePrice'];
    productWholeSalePrice = json['productWholeSalePrice'];
    productStock = json['productStock'];
    alertQty = json['alert_qty'];
    expireDate = json['expire_date'];
    productDiscount = json['productDiscount'];
    profitMargin = json['profit_percent'];
    vatAmount = json['vat_amount'];
    size = json['size'];
    type = json['type'];
    color = json['color'];
    weight = json['weight'];
    capacity = json['capacity'];
    vatType = json['vat_type'];
    gstRateSelect = json['gst_rate_select'];
    gstType = json['gst_type'];
    productManufacturer = json['productManufacturer'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    productStatus = json['product_status'] ?? json['productStatus'];
    productType = json['product_type'] ?? json['productType'];
    unit = json['unit'] != null ? Unit.fromJson(json['unit']) : null;
    brand = json['brand'] != null ? Brand.fromJson(json['brand']) : null;
    category =
        json['category'] != null ? Category.fromJson(json['category']) : null;

    // Parse stocks array
    if (json['stocks'] != null) {
      stocks = <StockModel>[];
      json['stocks'].forEach((v) {
        stocks!.add(StockModel.fromJson(v));
      });
    }
    if (json['variants'] != null) {
      variants = <ProductVariant>[];
      json['variants'].forEach((v) {
        variants!.add(ProductVariant.fromJson(v));
      });
    }
  }

  num? id;
  String? productName;
  num? businessId;
  num? unitId;
  num? brandId;
  num? vatId;
  num? categoryId;
  String? productCode;
  String? productPicture;
  num? productDealerPrice;
  num? productPurchasePrice;
  num? productSalePrice;
  num? productWholeSalePrice;
  num? productStock;
  num? alertQty;
  String? expireDate;
  num? productDiscount;
  String? size;
  String? type;
  String? color;
  String? weight;
  String? capacity;
  String? productManufacturer;
  String? createdAt;
  String? updatedAt;
  String? vatType;
  String? gstRateSelect;
  String? gstType;
  num? vatAmount;
  num? profitMargin;
  Unit? unit;
  Brand? brand;
  Category? category;
  List<StockModel>? stocks;
  List<ProductVariant>? variants;
  String? productStatus; // 'active' or 'inactive'
  String? productType; // 'combo' or regular product

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['productName'] = productName;
    map['business_id'] = businessId;
    map['unit_id'] = unitId;
    map['vat_id'] = vatId;
    map['vat_type'] = vatType;
    map['gst_rate_select'] = gstRateSelect;
    map['gst_type'] = gstType;
    map['brand_id'] = brandId;
    map['category_id'] = categoryId;
    map['productCode'] = productCode;
    map['productPicture'] = productPicture;
    map['productDealerPrice'] = productDealerPrice;
    map['productPurchasePrice'] = productPurchasePrice;
    map['productSalePrice'] = productSalePrice;
    map['productWholeSalePrice'] = productWholeSalePrice;
    map['productStock'] = productStock;
    map['alert_qty'] = alertQty;
    map['expire_date'] = expireDate;
    map['productDiscount'] = productDiscount;
    map['size'] = size;
    map['type'] = type;
    map['color'] = color;
    map['weight'] = weight;
    map['capacity'] = capacity;
    map['productManufacturer'] = productManufacturer;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    if (unit != null) {
      map['unit'] = unit?.toJson();
    }
    if (brand != null) {
      map['brand'] = brand?.toJson();
    }
    if (category != null) {
      map['category'] = category?.toJson();
    }
    if (stocks != null) {
      map['stocks'] = stocks?.map((v) => v.toJson()).toList();
    }
    if (variants != null) {
      map['variants'] = variants?.map((v) => v.toJson()).toList();
    }
    map['product_status'] = productStatus;
    map['product_type'] = productType;
    return map;
  }

  // Helper method to get the first stock ID
  num? getFirstStockId() {
    if (stocks != null && stocks!.isNotEmpty) {
      return stocks!.first.id;
    }
    return null;
  }
}

class Category {
  Category({
    this.id,
    this.categoryName,
  });

  Category.fromJson(dynamic json) {
    id = json['id'];
    categoryName = json['categoryName'];
  }

  num? id;
  String? categoryName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['categoryName'] = categoryName;
    return map;
  }
}

class Brand {
  Brand({
    this.id,
    this.brandName,
  });

  Brand.fromJson(dynamic json) {
    id = json['id'];
    brandName = json['brandName'];
  }

  num? id;
  String? brandName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['brandName'] = brandName;
    return map;
  }
}

class Unit {
  Unit({
    this.id,
    this.unitName,
  });

  Unit.fromJson(dynamic json) {
    id = json['id'];
    unitName = json['unitName'];
  }

  num? id;
  String? unitName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['unitName'] = unitName;
    return map;
  }
}

class StockModel {
  StockModel({
    this.id,
    this.businessId,
    this.productId,
    this.batchNo,
    this.productStock,
    this.productPurchasePrice,
    this.profitPercent,
    this.productSalePrice,
    this.productWholeSalePrice,
    this.productDealerPrice,
    this.lowStock,
    this.mfgDate,
    this.expireDate,
    this.createdAt,
    this.updatedAt,
  });

  StockModel.fromJson(dynamic json) {
    id = json['id'];
    businessId = json['business_id'];
    productId = json['product_id'];
    batchNo = json['batch_no'];
    productStock = json['productStock'];
    productPurchasePrice = json['productPurchasePrice'];
    profitPercent = json['profit_percent'];
    productSalePrice = json['productSalePrice'];
    productWholeSalePrice = json['productWholeSalePrice'];
    productDealerPrice = json['productDealerPrice'];
    lowStock = _parseNum(json['low_stock']);
    mfgDate = json['mfg_date'];
    expireDate = json['expire_date'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  num? id;
  num? businessId;
  num? productId;
  String? batchNo;
  num? productStock;
  num? productPurchasePrice;
  num? profitPercent;
  num? productSalePrice;
  num? productWholeSalePrice;
  num? productDealerPrice;
  num? lowStock;
  String? mfgDate;
  String? expireDate;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['business_id'] = businessId;
    map['product_id'] = productId;
    map['batch_no'] = batchNo;
    map['productStock'] = productStock;
    map['productPurchasePrice'] = productPurchasePrice;
    map['profit_percent'] = profitPercent;
    map['productSalePrice'] = productSalePrice;
    map['productWholeSalePrice'] = productWholeSalePrice;
    map['productDealerPrice'] = productDealerPrice;
    map['low_stock'] = lowStock;
    map['mfg_date'] = mfgDate;
    map['expire_date'] = expireDate;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }
}

class ProductVariant {
  ProductVariant({
    this.id,
    this.size,
    this.color,
    this.weight,
    this.capacity,
    this.type,
    this.purchasePrice,
    this.mrp,
    this.stock,
    this.lowStock,
  });

  ProductVariant.fromJson(dynamic json) {
    id = json['id'] ?? json['variant_id'];
    size = json['size'];
    color = json['color'];
    weight = json['weight'];
    capacity = json['capacity'];
    type = json['type'];
    purchasePrice = _parseNum(json['purchase_price']);
    mrp = _parseNum(json['mrp']) ?? _parseNum(json['sale_price']);
    stock = _parseNum(json['stock']);
    lowStock = _parseNum(json['low_stock']) ?? _parseNum(json['alert_qty']);
  }

  num? id;
  String? size;
  String? color;
  String? weight;
  String? capacity;
  String? type;
  num? purchasePrice;
  num? mrp;
  num? stock;
  num? lowStock;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['size'] = size;
    map['color'] = color;
    map['weight'] = weight;
    map['capacity'] = capacity;
    map['type'] = type;
    map['purchase_price'] = purchasePrice;
    map['mrp'] = mrp;
    map['stock'] = stock;
    map['low_stock'] = lowStock;
    return map;
  }

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }
}
