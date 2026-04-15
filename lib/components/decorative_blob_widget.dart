import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'decorative_blob_model.dart';
export 'decorative_blob_model.dart';

class DecorativeBlobWidget extends StatefulWidget {
  const DecorativeBlobWidget({
    super.key,
    this.size,
    this.color,
  });

  final double? size;
  final Color? color;

  @override
  State<DecorativeBlobWidget> createState() => _DecorativeBlobWidgetState();
}

class _DecorativeBlobWidgetState extends State<DecorativeBlobWidget> {
  late DecorativeBlobModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DecorativeBlobModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.15,
      child: ClipRect(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 40.0,
            sigmaY: 40.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: valueOrDefault<Color>(
                widget!.color,
                Color(0x00000000),
              ),
              borderRadius: BorderRadius.circular(9999.0),
            ),
          ),
        ),
      ),
    );
  }
}
