class PaymentCredentialModel {
  PaymentCredentialModel({
    required this.shurjopayserverUrl,
    required this.merchantuserName,
    required this.merchantPassword,
    required this.merchantkeyPrefix,
    this.razorpayKey,
    this.razorpaySecret,
  });

  PaymentCredentialModel.fromJson(dynamic json) {
    shurjopayserverUrl = json['SHURJOPAY_SERVER_URL'] ?? '';
    merchantuserName = json['MERCHANT_USERNAME'] ?? '';
    merchantPassword = json['MERCHANT_PASSWORD'] ?? '';
    merchantkeyPrefix = json['MERCHANT_KEY_PREFIX'] ?? '';
    razorpayKey = json['RAZORPAY_KEY'];
    razorpaySecret = json['RAZORPAY_SECRET'];
  }

  late String shurjopayserverUrl;
  late String merchantuserName;
  late String merchantPassword;
  late String merchantkeyPrefix;
  String? razorpayKey;
  String? razorpaySecret;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['SHURJOPAY_SERVER_URL'] = shurjopayserverUrl;
    map['MERCHANT_USERNAME'] = merchantuserName;
    map['MERCHANT_PASSWORD'] = merchantPassword;
    map['MERCHANT_KEY_PREFIX'] = merchantkeyPrefix;
    if (razorpayKey != null) map['RAZORPAY_KEY'] = razorpayKey;
    if (razorpaySecret != null) map['RAZORPAY_SECRET'] = razorpaySecret;
    return map;
  }
}
