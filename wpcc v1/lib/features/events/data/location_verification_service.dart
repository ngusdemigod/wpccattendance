import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/event_flow_models.dart';

class LocationVerificationResult {
  const LocationVerificationResult({
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
  });

  final double latitude;
  final double longitude;
  final double distanceMeters;
}

class LocationVerificationException implements Exception {
  const LocationVerificationException(this.reason, [this.message]);

  final EventCheckInFailureReason reason;
  final String? message;
}

class LocationVerificationService {
  const LocationVerificationService();

  static const double boundaryMeters = 100;

  Future<LocationVerificationResult> verify({
    required double eventLatitude,
    required double eventLongitude,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationVerificationException(
        EventCheckInFailureReason.gpsDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationVerificationException(
          EventCheckInFailureReason.permissionDenied,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationVerificationException(
        EventCheckInFailureReason.permissionDeniedForever,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15));

      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        eventLatitude,
        eventLongitude,
      );

      if (distanceMeters > boundaryMeters) {
        throw LocationVerificationException(
          EventCheckInFailureReason.outsideBoundary,
          'You are ${distanceMeters.toStringAsFixed(0)}m away from the attendance point.',
        );
      }

      return LocationVerificationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        distanceMeters: distanceMeters,
      );
    } on LocationVerificationException {
      rethrow;
    } on TimeoutException {
      throw const LocationVerificationException(
        EventCheckInFailureReason.timeout,
      );
    } catch (_) {
      throw const LocationVerificationException(
        EventCheckInFailureReason.unknown,
      );
    }
  }
}
