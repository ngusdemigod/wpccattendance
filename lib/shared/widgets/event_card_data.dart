import 'package:flutter/material.dart';

abstract class EventCardData {
  String get title;
  String get eyebrow;
  String get dateText;
  String get timeText;
  String? get imageUrl;
  List<Color> get gradientColors;
}
