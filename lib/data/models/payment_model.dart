class PricingPlan {
  final String id;
  final String description;
  final int priceInPaise;
  final int? originalPriceInPaise;
  final int? usdOriginalPrice;
  final int? usdDiscountPrice;

  PricingPlan({
    required this.id,
    required this.description,
    required this.priceInPaise,
    this.originalPriceInPaise,
    this.usdOriginalPrice,
    this.usdDiscountPrice,
  });

  factory PricingPlan.fromJson(Map<String, dynamic> json) => PricingPlan(
        id: json['id'] as String? ?? '',
        description: json['description'] as String? ?? '',
        priceInPaise: (json['price_in_paise'] as num?)?.toInt() ?? 0,
        originalPriceInPaise: (json['original_price_in_paise'] as num?)?.toInt(),
        usdOriginalPrice: (json['usd_original_price'] as num?)?.toInt(),
        usdDiscountPrice: (json['usd_discount_price'] as num?)?.toInt(),
      );

  String get name => description;

  /// Returns the payment amount in smallest unit (paise for INR, cents for USD).
  int paymentAmountFor(bool isIndia) {
    if (isIndia) return priceInPaise;
    return (usdDiscountPrice ?? usdOriginalPrice ?? 0) * 100;
  }

  /// Returns the original (before-discount) amount, or null if no discount.
  int? originalAmountFor(bool isIndia) {
    if (isIndia) return originalPriceInPaise;
    return usdOriginalPrice != null ? usdOriginalPrice! * 100 : null;
  }

  bool hasDiscount(bool isIndia) {
    final orig = originalAmountFor(isIndia);
    return orig != null && orig > paymentAmountFor(isIndia);
  }
}

class PremiumPriceResponse {
  final List<PricingPlan> plans;

  PremiumPriceResponse({required this.plans});

  factory PremiumPriceResponse.fromJson(Map<String, dynamic> json) {
    final rawPlans = json['plans'] as List<dynamic>? ?? [];
    return PremiumPriceResponse(
      plans: rawPlans.map((e) => PricingPlan.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class CalculatePriceRequest {
  final String? couponCode;
  final int price;
  final int discountablePrice;
  final String country;

  CalculatePriceRequest({
    this.couponCode,
    required this.price,
    required this.discountablePrice,
    required this.country,
  });

  Map<String, dynamic> toJson() => {
        if (couponCode != null && couponCode!.isNotEmpty) 'coupon_code': couponCode,
        'price': price,
        'discountable_price': discountablePrice,
        'country': country,
      };
}

class CalculatePriceResponse {
  final int baseAmount;
  final int discountAmount;
  final int amountAfterDiscount;
  final int gstPercentage;
  final int gstAmount;
  final int finalAmount;
  final String currency;

  CalculatePriceResponse({
    required this.baseAmount,
    required this.discountAmount,
    required this.amountAfterDiscount,
    required this.gstPercentage,
    required this.gstAmount,
    required this.finalAmount,
    required this.currency,
  });

  factory CalculatePriceResponse.fromJson(Map<String, dynamic> json) =>
      CalculatePriceResponse(
        baseAmount: (json['base_amount'] as num?)?.toInt() ?? 0,
        discountAmount: (json['discount_amount'] as num?)?.toInt() ?? 0,
        amountAfterDiscount: (json['amount_after_discount'] as num?)?.toInt() ?? 0,
        gstPercentage: (json['gst_percentage'] as num?)?.toInt() ?? 0,
        gstAmount: (json['gst_amount'] as num?)?.toInt() ?? 0,
        finalAmount: (json['final_amount'] as num?)?.toInt() ?? 0,
        currency: json['currency'] as String? ?? 'INR',
      );

  double get finalAmountInRupees => finalAmount / 100.0;
}

class CreateOrderRequest {
  final String? couponCode;
  final int price;
  final int discountablePrice;
  final String country;
  final String? planId;

  CreateOrderRequest({
    this.couponCode,
    required this.price,
    required this.discountablePrice,
    required this.country,
    this.planId,
  });

  Map<String, dynamic> toJson() => {
        if (couponCode != null && couponCode!.isNotEmpty) 'coupon_code': couponCode,
        'price': price,
        'discountable_price': discountablePrice,
        'country': country,
        if (planId != null) 'plan_id': planId,
      };
}

class CreateOrderResponse {
  final String paymentId;
  final String razorpayOrderId;
  final int amount;
  final String currency;
  final String key;

  CreateOrderResponse({
    required this.paymentId,
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
    required this.key,
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) =>
      CreateOrderResponse(
        paymentId: json['payment_id'] as String? ?? '',
        razorpayOrderId: json['razorpay_order_id'] as String? ?? '',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        currency: json['currency'] as String? ?? 'INR',
        key: json['key'] as String? ?? '',
      );
}

class VerifyPaymentRequest {
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  VerifyPaymentRequest({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  Map<String, dynamic> toJson() => {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      };
}

class ValidateCouponResponse {
  final String code;
  final String discountType;
  final int discountValue;
  final bool isValid;

  ValidateCouponResponse({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.isValid,
  });

  factory ValidateCouponResponse.fromJson(Map<String, dynamic> json) =>
      ValidateCouponResponse(
        code: json['code'] as String? ?? '',
        discountType: json['discount_type'] as String? ?? '',
        discountValue: (json['discount_value'] as num?)?.toInt() ?? 0,
        isValid: json['valid'] as bool? ?? false,
      );
}
