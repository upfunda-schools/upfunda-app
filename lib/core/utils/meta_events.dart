import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

/// Thin wrapper over the Meta SDK. All calls are no-ops on web and never throw.
class MetaEvents {
  MetaEvents._();

  static final FacebookAppEvents _fb = FacebookAppEvents();

  static Future<void> _log(
    String name, {
    Map<String, dynamic>? params,
    double? valueToSum,
  }) async {
    if (kIsWeb) {
      debugPrint('ℹ️ [MetaEvents - Web (Skipped)] Event: $name');
      return;
    }
    try {
      await _fb.logEvent(
        name: name,
        parameters: params,
        valueToSum: valueToSum,
      );
      await _fb.flush();
      debugPrint(
        '🎯 [MetaEvents - Logged] $name | Value: $valueToSum | Params: $params',
      );
    } catch (e) {
      debugPrint('❌ [MetaEvents - Failed] $name: $e');
    }
  }

  static Future<void> completeRegistration({String? method}) => _log(
    'fb_mobile_complete_registration',
    params: {if (method != null) 'fb_registration_method': method},
  );

  static Future<void> initiateCheckout() =>
      _log('fb_mobile_initiated_checkout');

  /// Call only after the payment is verified. [amountInPaise] is converted to rupees.
  /// [orderId] is sent as the event ID.
  static Future<void> subscribe({
    required int amountInPaise,
    required String planName,
    required String orderId,
  }) => _log(
    'Subscribe',
    valueToSum: amountInPaise / 100,
    params: {
      'fb_currency': 'INR',
      'plan_name': planName,
      'fb_order_id': orderId,
      'event_id': orderId,
    },
  );
}
