import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

class LeafletMapWidget extends StatefulWidget {
  const LeafletMapWidget({
    super.key,
    required this.height,
    required this.title,
    required this.location,
    this.latitude = 4.808890849053463,
    this.longitude = 6.975136973137541,
    this.radiusMeters = 30,
    this.userLatitude,
    this.userLongitude,
  });

  final double height;
  final String title;
  final String location;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final double? userLatitude;
  final double? userLongitude;

  @override
  State<LeafletMapWidget> createState() => _LeafletMapWidgetState();
}

class _LeafletMapWidgetState extends State<LeafletMapWidget> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'leaflet-map-${DateTime.now().microsecondsSinceEpoch}';
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..srcdoc = _buildHtml();
      return iframe;
    });
  }

  String _buildHtml() {
    final lat = widget.latitude;
    final lng = widget.longitude;
    final radiusMeters = widget.radiusMeters;
    final titleJson = jsonEncode(widget.title);
    final locationJson = jsonEncode(widget.location);
    final hasUserLocation =
        widget.userLatitude != null && widget.userLongitude != null;
    final userLat = widget.userLatitude;
    final userLng = widget.userLongitude;
    return '''
<!DOCTYPE html>
<html><head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin="" />
<style>html, body, #map { width: 100%; height: 100%; margin: 0; padding: 0; background: #111111; } .leaflet-container { font-family: Arial, sans-serif; }</style>
</head><body><div id="map"></div>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>
<script>
const map = L.map('map', { zoomControl: true, attributionControl: true }).setView([$lat, $lng], 15);
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19, attribution: '&copy; OpenStreetMap contributors' }).addTo(map);
const marker = L.marker([$lat, $lng]).addTo(map);
const circle = L.circle([$lat, $lng], { radius: $radiusMeters, color: '#C5099C', weight: 2, fillColor: '#C5099C', fillOpacity: 0.18 }).addTo(map);
marker.bindPopup('<strong>' + $titleJson + '</strong><br>' + $locationJson).openPopup();
circle.bindPopup('30m geofence');
${hasUserLocation ? "const userMarker = L.circleMarker([$userLat, $userLng], {radius: 9, color: '#2B8CFD', weight: 3, fillColor: '#2B8CFD', fillOpacity: 0.9}).addTo(map); userMarker.bindPopup('Your location');" : ""}
</script></body></html>''';
  }

  @override
  Widget build(BuildContext context) => SizedBox(
      height: widget.height, child: HtmlElementView(viewType: _viewType));
}
