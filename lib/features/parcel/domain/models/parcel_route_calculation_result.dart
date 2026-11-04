import 'package:flutter/foundation.dart';

@immutable
class ParcelRouteCalculationResult {
  final double distanceKm;
  final double extraCharge;
  final bool isSuccess;
  final String? failureMessage;

  const ParcelRouteCalculationResult.success({
    required this.distanceKm,
    required this.extraCharge,
  })  : isSuccess = true,
        failureMessage = null;

  const ParcelRouteCalculationResult.failure({
    required this.failureMessage,
  })  : isSuccess = false,
        distanceKm = -1,
        extraCharge = 0;

  @override
  String toString() {
    return 'ParcelRouteCalculationResult(isSuccess: $isSuccess, distanceKm: $distanceKm, extraCharge: $extraCharge, failureMessage: $failureMessage)';
  }
}

