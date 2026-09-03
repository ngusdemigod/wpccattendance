import 'dart:async';

import '/components/leaflet_map_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

class EventGeofenceDebugWidget extends StatefulWidget {
  const EventGeofenceDebugWidget({
    super.key,
    required this.title,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 30,
  });

  final String title;
  final String location;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  @override
  State<EventGeofenceDebugWidget> createState() =>
      _EventGeofenceDebugWidgetState();
}

class _EventGeofenceDebugWidgetState extends State<EventGeofenceDebugWidget> {
  Timer? _pollTimer;
  bool _loadingLocation = true;
  String? _locationError;
  double? _userLatitude;
  double? _userLongitude;

  @override
  void initState() {
    super.initState();
    _pollLocation();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollLocation(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _pollLocation({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loadingLocation = true;
        _locationError = null;
      });
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required to show your marker.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
        _loadingLocation = false;
        _locationError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingLocation = false;
        _locationError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapKey = ValueKey(
      '${widget.latitude},${widget.longitude},${_userLatitude ?? 'na'},${_userLongitude ?? 'na'}',
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Geofence Debug',
          style: FlutterFlowTheme.of(context).titleMedium.override(
                font: GoogleFonts.instrumentSans(
                  fontWeight: FontWeight.w700,
                ),
                color: Colors.white,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).headlineSmall.override(
                      font: GoogleFonts.instrumentSans(
                        fontWeight: FontWeight.w800,
                      ),
                      color: Colors.white,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.location,
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.instrumentSans(
                        fontWeight: FontWeight.w400,
                      ),
                      color: FlutterFlowTheme.of(context).secondaryText,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w400,
                    ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 420,
                  decoration: BoxDecoration(
                    color: const Color(0xFF171717),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: FlutterFlowTheme.of(context).divider,
                    ),
                  ),
                  child: LeafletMapWidget(
                    key: mapKey,
                    height: 420,
                    title: widget.title,
                    location: widget.location,
                    latitude: widget.latitude,
                    longitude: widget.longitude,
                    radiusMeters: widget.radiusMeters,
                    userLatitude: _userLatitude,
                    userLongitude: _userLongitude,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF171717),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: FlutterFlowTheme.of(context).divider,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Radius',
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            font: GoogleFonts.instrumentSans(
                              fontWeight: FontWeight.w400,
                            ),
                            color: FlutterFlowTheme.of(context).secondaryText,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.radiusMeters.toStringAsFixed(0)} m geofence',
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            font: GoogleFonts.instrumentSans(
                              fontWeight: FontWeight.w700,
                            ),
                            color: Colors.white,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Event: ${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.instrumentSans(
                              fontWeight: FontWeight.w400,
                            ),
                            color: FlutterFlowTheme.of(context).secondaryText,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (_loadingLocation)
                      Text(
                        'Polling your location...',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.instrumentSans(
                                fontWeight: FontWeight.w400,
                              ),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w400,
                            ),
                      )
                    else if (_locationError != null)
                      Text(
                        _locationError!,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.instrumentSans(
                                fontWeight: FontWeight.w400,
                              ),
                              color: const Color(0xFFFF6B6B),
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w400,
                            ),
                      )
                    else
                      Text(
                        'Your position: ${_userLatitude!.toStringAsFixed(6)}, ${_userLongitude!.toStringAsFixed(6)}',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.instrumentSans(
                                fontWeight: FontWeight.w400,
                              ),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
