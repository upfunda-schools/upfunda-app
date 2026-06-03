import 'package:dio/dio.dart';
import '../../core/utils/profile_storage.dart';
import '../models/payment_model.dart';
import 'firebase_auth_service.dart';

class PaymentService {
  final Dio _dio;

  PaymentService({
    required String baseUrl,
    required FirebaseAuthService authService,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await authService.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        final profileId = ProfileStorage.profileId;
        if (profileId != null) {
          options.headers['X-Profile-ID'] = profileId;
        }
        return handler.next(options);
      },
    ));
  }

  Future<PremiumPriceResponse> fetchPremiumPrice() async {
    final response = await _dio.get('/student/premium/price');
    return PremiumPriceResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CalculatePriceResponse> calculatePrice(CalculatePriceRequest req) async {
    final response = await _dio.post(
      '/student/payment/calculate-price',
      data: req.toJson(),
    );
    return CalculatePriceResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CreateOrderResponse> createOrder(CreateOrderRequest req) async {
    final response = await _dio.post(
      '/student/payment/create-order',
      data: req.toJson(),
    );
    return CreateOrderResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> verifyPayment(VerifyPaymentRequest req) async {
    await _dio.post(
      '/student/payment/verify',
      data: req.toJson(),
    );
  }

  Future<ValidateCouponResponse> validateCoupon(String code) async {
    final response = await _dio.get('/student/coupons/validate/$code');
    return ValidateCouponResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
