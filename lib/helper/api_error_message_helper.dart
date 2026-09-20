import 'package:get/get.dart';

/// Converts known server messages into clear, user-facing text.
///
/// Some backend translations are returned as complete sentences, so they do
/// not pass through the app's translation files before being displayed.
class ApiErrorMessageHelper {
  static String? orderPlacementMessage(String? message) {
    if (message == null || message.trim().isEmpty) {
      return message;
    }

    final normalized = message.trim().toLowerCase();
    final isDeliveryOrderLimit =
        normalized.contains('أوامر الولادة') ||
        (normalized.contains('الحد الأقصى') &&
            normalized.contains('الخدمة') &&
            normalized.contains('تجاوز')) ||
        (normalized.contains('delivery') &&
            normalized.contains('order') &&
            normalized.contains('maximum') &&
            normalized.contains('exceed'));

    if (isDeliveryOrderLimit) {
      return Get.locale?.languageCode == 'ar'
          ? 'تم الوصول إلى الحد الأقصى لطلبات التوصيل المتاحة لهذه الخدمة. حاول مرة أخرى لاحقًا.'
          : 'The maximum number of delivery orders for this service has been reached. Please try again later.';
    }

    return message;
  }
}
