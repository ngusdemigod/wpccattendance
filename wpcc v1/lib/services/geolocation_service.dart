import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GeolocationService {
  // Church location coordinates
  static const double churchLatitude = 4.808472604032901;
  static const double churchLongitude = 6.97530560092991;
  // 40km radius in meters
  static const double allowedRadiusMeters = 40000;

  /// Check if the user is within the allowed radius of the church location
  static Future<bool> isUserWithinAllowedLocation() async {
    try {
      if (kIsWeb) {
        // Web-specific location handling
        return await _checkWebLocation();
      } else {
        // Mobile-specific location handling
        return await _checkMobileLocation();
      }
    } catch (e) {
      print('Geolocation error: $e');
      return false;
    }
  }

  /// Mobile-specific location check (Android/iOS)
  static Future<bool> _checkMobileLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Calculate distance to church location
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        churchLatitude,
        churchLongitude,
      );

      // Check if within allowed radius
      return distance <= allowedRadiusMeters;
    } catch (e) {
      print('Mobile geolocation error: $e');
      return false;
    }
  }

  /// Web-specific location check using browser Geolocation API
  static Future<bool> _checkWebLocation() async {
    try {
      // For web, we need to use JavaScript interop or a web-specific approach
      // Since geolocator web support is limited, we'll use a workaround
      // that attempts to get position via the Geolocator class which has web support
      
      // Check if browser supports geolocation
      if (!await _isWebGeolocationSupported()) {
        print('Web geolocation not supported in this browser');
        return false;
      }

      // Try to get position using Geolocator (it has some web support)
      Position? position = await _getWebPosition();
      
      if (position == null) {
        return false;
      }

      // Calculate distance to church location
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        churchLatitude,
        churchLongitude,
      );

      // Check if within allowed radius
      return distance <= allowedRadiusMeters;
    } catch (e) {
      print('Web geolocation error: $e');
      return false;
    }
  }

  /// Check if web geolocation is supported
  static Future<bool> _isWebGeolocationSupported() async {
    try {
      // For web, we check if we can get a position
      // This is a basic check - in production, you might want to use 
      // a more robust approach with JavaScript interop
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position != null;
    } catch (e) {
      return false;
    }
  }

  /// Get position for web platform
  static Future<Position?> _getWebPosition() async {
    try {
      // Get position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      print('Error getting web position: $e');
      return null;
    }
  }

  /// Get current position
  static Future<Position?> getCurrentPosition() async {
    try {
      if (kIsWeb) {
        return await _getWebPosition();
      } else {
        return await _getMobilePosition();
      }
    } catch (e) {
      print('Geolocation error: $e');
      return null;
    }
  }

  /// Mobile-specific position retrieval
  static Future<Position?> _getMobilePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Mobile geolocation error: $e');
      return null;
    }
  }

  /// Get distance to church location in meters
  static Future<double> getDistanceToChurch() async {
    try {
      Position? position = await getCurrentPosition();
      if (position == null) {
        return -1;
      }

      return Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        churchLatitude,
        churchLongitude,
      );
    } catch (e) {
      print('Geolocation error: $e');
      return -1;
    }
  }

  /// Get distance in kilometers
  static Future<double> getDistanceToChurchKm() async {
    double meters = await getDistanceToChurch();
    if (meters < 0) return -1;
    return meters / 1000;
  }
}
