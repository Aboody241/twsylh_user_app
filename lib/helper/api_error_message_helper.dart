import 'package:get/get.dart';

/// Converts known server messages, network errors, and raw exceptions into clear, localized user-facing text.
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
      return 'maximum_delivery_orders_exceeded'.tr;
    }

    return message;
  }

  static String? getLocalizedMessage(String? message) {
    if (message == null || message.trim().isEmpty) {
      return message;
    }

    String trimmed = message.trim();

    // Check order placement message
    String? orderMsg = orderPlacementMessage(trimmed);
    if (orderMsg != trimmed) {
      return orderMsg;
    }

    // Check if it produces a direct translation
    String directTr = trimmed.tr;
    if (directTr != trimmed) {
      return directTr;
    }

    final lower = trimmed.toLowerCase();

    // Network & Connection errors
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection closed') ||
        lower.contains('connection timed out') ||
        lower.contains('clientexception') ||
        lower.contains('timeoutexception') ||
        lower.contains('handshakeexception') ||
        lower.contains('connection_to_api_server_failed') ||
        lower == 'connection to api server failed due to internet connection') {
      return 'connection_to_api_server_failed'.tr;
    }

    if (lower == 'no internet connection' || lower == 'no_internet_connection') {
      return 'no_internet_connection'.tr;
    }

    // Authentication & Credential errors
    if (lower.contains('invalid credentials') ||
        lower.contains('credentials do not match') ||
        lower.contains('invalid_credentials') ||
        lower.contains('credentials_does_not_match')) {
      return 'invalid_credentials'.tr;
    }

    if (lower.contains('phone has already been taken') ||
        lower.contains('phone number already exists') ||
        lower.contains('phone_number_already_exists')) {
      return 'phone_number_already_exists'.tr;
    }

    if (lower.contains('email has already been taken') ||
        lower.contains('email already exists') ||
        lower.contains('email_already_exists')) {
      return 'email_already_exists'.tr;
    }

    if (lower.contains('unauthenticated') ||
        lower.contains('unauthorized') ||
        lower.contains('token_expired')) {
      return 'session_expired_please_sign_in_again'.tr;
    }

    // Rate limiting & server errors
    if (lower.contains('too many attempts') ||
        lower.contains('too many requests') ||
        lower.contains('too-many-requests')) {
      return 'too_many_attempts_please_try_again_later'.tr;
    }

    if (lower.contains('quota-exceeded')) {
      return 'firebase_auth_quota_exceeded'.tr;
    }

    if (lower.contains('invalid-verification-code') || lower.contains('session-expired')) {
      return 'firebase_auth_invalid_verification_code'.tr;
    }

    if (lower.contains('user-disabled')) {
      return 'firebase_auth_user_disabled'.tr;
    }

    if (lower.contains('operation-not-allowed')) {
      return 'firebase_auth_operation_not_allowed'.tr;
    }

    if (lower.contains('app-not-authorized')) {
      return 'firebase_auth_app_not_authorized'.tr;
    }

    if (lower.contains('invalid-phone-number')) {
      return 'please_submit_a_valid_phone_number'.tr;
    }

    if (lower.contains('google sign-in not supported') || lower.contains('google sign in not supported')) {
      return 'google_sign_in_not_supported'.tr;
    }

    if (lower.contains('internal server error') || lower == 'server error' || lower == '500') {
      return 'internal_server_error'.tr;
    }

    if (lower.contains('service unavailable') || lower == '503') {
      return 'service_unavailable_try_again_later'.tr;
    }

    if (lower == 'the guest id field is required.') {
      return 'this_field_is_required'.tr;
    }

    return trimmed;
  }
}
