import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/env_config.dart';
import '../../data/models/payment_model.dart';
import '../../data/services/payment_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return PaymentService(
    baseUrl: EnvConfig.apiBaseUrl,
    authService: authService,
  );
});

enum PaymentStatus { idle, loadingPlans, calculatingPrice, creatingOrder, processingPayment, success, error }

class PaymentState {
  final PaymentStatus status;
  final List<PricingPlan> plans;
  final CalculatePriceResponse? priceBreakdown;
  final CreateOrderResponse? currentOrder;
  final String? errorMessage;
  final String? couponCode;
  final bool couponValid;

  const PaymentState({
    this.status = PaymentStatus.idle,
    this.plans = const [],
    this.priceBreakdown,
    this.currentOrder,
    this.errorMessage,
    this.couponCode,
    this.couponValid = false,
  });

  PaymentState copyWith({
    PaymentStatus? status,
    List<PricingPlan>? plans,
    CalculatePriceResponse? priceBreakdown,
    bool clearPriceBreakdown = false,
    CreateOrderResponse? currentOrder,
    bool clearOrder = false,
    String? errorMessage,
    String? couponCode,
    bool clearCoupon = false,
    bool? couponValid,
  }) =>
      PaymentState(
        status: status ?? this.status,
        plans: plans ?? this.plans,
        priceBreakdown: clearPriceBreakdown ? null : (priceBreakdown ?? this.priceBreakdown),
        currentOrder: clearOrder ? null : (currentOrder ?? this.currentOrder),
        errorMessage: errorMessage,
        couponCode: clearCoupon ? null : (couponCode ?? this.couponCode),
        couponValid: couponValid ?? this.couponValid,
      );
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentService _service;
  final Ref _ref;

  PaymentNotifier(this._service, this._ref) : super(const PaymentState());

  Future<void> loadPlans() async {
    state = state.copyWith(status: PaymentStatus.loadingPlans, errorMessage: null);
    try {
      final result = await _service.fetchPremiumPrice();
      state = state.copyWith(status: PaymentStatus.idle, plans: result.plans);
    } catch (e) {
      state = state.copyWith(status: PaymentStatus.error, errorMessage: _parseError(e));
    }
  }

  /// Calculates price and updates priceBreakdown.
  /// [price] = total of all selected plans in smallest unit.
  /// [discountablePrice] = worksheet-only price (coupon applies only to worksheet).
  Future<void> calculatePrice({
    required int price,
    required int discountablePrice,
    required String country,
    String? couponCode,
  }) async {
    state = state.copyWith(status: PaymentStatus.calculatingPrice, errorMessage: null);
    try {
      final breakdown = await _service.calculatePrice(CalculatePriceRequest(
        couponCode: couponCode,
        price: price,
        discountablePrice: discountablePrice,
        country: country,
      ));
      state = state.copyWith(
        status: PaymentStatus.idle,
        priceBreakdown: breakdown,
        couponCode: couponCode,
        couponValid: couponCode != null && couponCode.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(status: PaymentStatus.error, errorMessage: _parseError(e));
    }
  }

  Future<bool> validateAndApplyCoupon({
    required String code,
    required int price,
    required int discountablePrice,
    required String country,
  }) async {
    if (code.trim().isEmpty) return false;
    try {
      final coupon = await _service.validateCoupon(code.trim());
      if (!coupon.isValid) {
        state = state.copyWith(
          couponValid: false,
          clearCoupon: true,
          errorMessage: 'Invalid or expired coupon',
        );
        return false;
      }
      await calculatePrice(
        price: price,
        discountablePrice: discountablePrice,
        country: country,
        couponCode: code.trim(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        couponValid: false,
        clearCoupon: true,
        errorMessage: _parseError(e),
      );
      return false;
    }
  }

  void clearCoupon() {
    state = state.copyWith(clearCoupon: true, clearPriceBreakdown: true, couponValid: false);
  }

  Future<CreateOrderResponse?> createOrder({
    required int price,
    required int discountablePrice,
    required String country,
    String? couponCode,
    String? planId,
  }) async {
    state = state.copyWith(status: PaymentStatus.creatingOrder, errorMessage: null);
    try {
      final order = await _service.createOrder(CreateOrderRequest(
        couponCode: couponCode ?? (state.couponValid ? state.couponCode : null),
        price: price,
        discountablePrice: discountablePrice,
        country: country,
        planId: planId,
      ));
      state = state.copyWith(status: PaymentStatus.idle, currentOrder: order);
      return order;
    } catch (e) {
      state = state.copyWith(status: PaymentStatus.error, errorMessage: _parseError(e));
      return null;
    }
  }

  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    state = state.copyWith(status: PaymentStatus.processingPayment, errorMessage: null);
    try {
      await _service.verifyPayment(VerifyPaymentRequest(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      ));
      await _ref.read(userProvider.notifier).loadProfile();
      state = state.copyWith(status: PaymentStatus.success, clearOrder: true);
      return true;
    } catch (e) {
      state = state.copyWith(status: PaymentStatus.error, errorMessage: _parseError(e));
      return false;
    }
  }

  void reset() {
    state = const PaymentState();
  }

  String _parseError(Object e) {
    final str = e.toString();
    if (str.contains('already has an active premium')) {
      return 'You already have an active premium subscription.';
    }
    if (str.contains('DioException')) {
      return 'Network error. Please check your connection and try again.';
    }
    return str.replaceFirst('Exception: ', '');
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(ref.read(paymentServiceProvider), ref);
});
