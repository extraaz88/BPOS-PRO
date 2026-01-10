class ComboModel {
  ComboModel({
    this.id,
    this.productId,
    this.comboName,
    this.comboImage,
    this.products,
    this.subtotal,
    this.discountType,
    this.discountValue,
    this.finalPrice,
    this.businessId,
    this.productStatus,
    this.createdAt,
    this.updatedAt,
  });

  ComboModel.fromJson(dynamic json) {
    if (json == null) return;

    // If API returned a plain id (int) or string, treat it as id-only
    if (json is num) {
      id = json;
      return;
    }
    if (json is String) {
      final parsed = num.tryParse(json);
      if (parsed != null) {
        id = parsed;
        return;
      }
      return;
    }

    // If not a Map, ignore to avoid NoSuchMethod errors
    if (json is! Map) return;

    id = json['id'];
    productId = json['product_id'] ?? json['productId'];
    comboName = json['combo_name'] ?? json['comboName'];
    comboImage = json['combo_image'] ?? json['comboImage'];
    businessId = json['business_id'] ?? json['businessId'];
    subtotal = json['subtotal'];
    discountType = json['discount_type'] ?? json['discountType'];
    discountValue = json['discount_value'] ?? json['discountValue'];
    finalPrice =
        json['combo_price'] ?? json['final_price'] ?? json['finalPrice'];
    createdAt = json['created_at'] ?? json['createdAt'];
    updatedAt = json['updated_at'] ?? json['updatedAt'];

    // Normalize status: prefer product_status, fallback to status
    final statusRaw = json['product_status'] ?? json['status'];
    String? normalizedStatus;
    if (statusRaw != null) {
      if (statusRaw is bool) {
        normalizedStatus = statusRaw ? 'active' : 'inactive';
      } else if (statusRaw is num) {
        normalizedStatus = statusRaw == 1 ? 'active' : 'inactive';
      } else {
        final s = statusRaw.toString().toLowerCase().trim();
        if (['true', '1', 'active', 'yes', 'enabled'].contains(s)) {
          normalizedStatus = 'active';
        } else if (['false', '0', 'inactive', 'no', 'disabled'].contains(s)) {
          normalizedStatus = 'inactive';
        } else {
          // keep original string if it's a different naming convention
          normalizedStatus = s.isNotEmpty ? s : null;
        }
      }
    }
    productStatus = normalizedStatus;

    final productsJson = json['products'];
    if (productsJson != null) {
      products = <ComboProduct>[];
      // If it's already a List, iterate normally
      if (productsJson is List) {
        for (var v in productsJson) {
          if (v != null) {
            products!.add(ComboProduct.fromJson(v));
          }
        }
      } else if (productsJson is Map) {
        // If API returned a Map (e.g. keyed by id), convert values to list
        for (var v in productsJson.values) {
          if (v != null) {
            products!.add(ComboProduct.fromJson(v));
          }
        }
      } else {
        // Fallback: try single item map-like object
        try {
          products!.add(ComboProduct.fromJson(productsJson));
        } catch (_) {
          // ignore malformed products field
        }
      }
    }
  }

  num? id; // combo_kit id
  num? productId; // outer product id (used for status updates)
  String? comboName;
  String? comboImage;
  num? businessId;
  num? subtotal;
  String? discountType; // 'flat' or 'percent'
  num? discountValue;
  num? finalPrice;
  String? productStatus; // 'active' or 'inactive'
  List<ComboProduct>? products;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['product_id'] = productId;
    map['combo_name'] = comboName;
    map['combo_image'] = comboImage;
    map['business_id'] = businessId;
    map['subtotal'] = subtotal;
    map['discount_type'] = discountType;
    map['discount_value'] = discountValue;
    map['final_price'] = finalPrice;
    map['product_status'] = productStatus;
    if (products != null) {
      map['products'] = products?.map((v) => v.toJson()).toList();
    }
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }
}

class ComboProduct {
  ComboProduct({
    this.id,
    this.comboId,
    this.productId,
    this.productName,
    this.productPrice,
    this.productImage,
    this.product,
    this.quantity,
  });

  ComboProduct.fromJson(dynamic json) {
    // Support MapEntry (from Map.forEach misuse) or a direct Map
    if (json is MapEntry) {
      json = json.value;
    }
    if (json is! Map) {
      // If it's not a Map, try to ignore and keep defaults
      return;
    }

    id = json['id'];
    comboId = json['combo_id'] ?? json['comboId'];
    productId = json['product_id'] ?? json['productId'];
    productName = json['product_name'] ?? json['productName'];
    productPrice = json['product_price'] ?? json['productPrice'];
    productImage = json['product_image'] ?? json['productImage'];
    quantity = json['quantity'] ?? 1; // Default to 1 if not provided

    if (json['product'] != null) {
      product = json['product'];
    }

    // If productId still null, try to extract from nested product object
    if (productId == null && product != null && product is Map) {
      final dynamic pid = product['id'] ?? product['product_id'] ?? product['productId'];
      if (pid != null) {
        if (pid is num) {
          productId = pid;
        } else {
          final parsed = num.tryParse(pid.toString());
          if (parsed != null) productId = parsed;
        }
      }
    }
  }

  num? id;
  num? comboId;
  num? productId;
  String? productName;
  num? productPrice;
  String? productImage;
  dynamic product; // Can contain full product object
  num? quantity; // Quantity of this product in the combo

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['combo_id'] = comboId;
    map['product_id'] = productId;
    map['product_name'] = productName;
    map['product_price'] = productPrice;
    map['product_image'] = productImage;
    map['quantity'] = quantity;
    return map;
  }
}
