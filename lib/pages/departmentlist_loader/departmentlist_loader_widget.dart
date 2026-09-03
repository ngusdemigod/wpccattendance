import '/shared/widgets/wpcc_shimmer.dart';
import 'package:flutter/material.dart';

import 'departmentlist_loader_model.dart';
export 'departmentlist_loader_model.dart';

class DepartmentlistLoaderWidget extends StatefulWidget {
  const DepartmentlistLoaderWidget({super.key});

  @override
  State<DepartmentlistLoaderWidget> createState() =>
      _DepartmentlistLoaderWidgetState();
}

class _DepartmentlistLoaderWidgetState
    extends State<DepartmentlistLoaderWidget> {
  late DepartmentlistLoaderModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = DepartmentlistLoaderModel();
    _model.initState(context);
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        WpccShimmerCard(
          radius: 30,
          child: Row(
            children: [
              WpccShimmerCircle(size: 44),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WpccShimmerBlock(width: 180, height: 14, radius: 8),
                    SizedBox(height: 6),
                    WpccShimmerBlock(width: 96, height: 10, radius: 8),
                  ],
                ),
              ),
              SizedBox(width: 12),
              WpccShimmerBlock(width: 58, height: 24, radius: 999),
            ],
          ),
        ),
        SizedBox(height: 8),
        WpccShimmerCard(
          radius: 30,
          child: Row(
            children: [
              WpccShimmerCircle(size: 44),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WpccShimmerBlock(width: 160, height: 14, radius: 8),
                    SizedBox(height: 6),
                    WpccShimmerBlock(width: 110, height: 10, radius: 8),
                  ],
                ),
              ),
              SizedBox(width: 12),
              WpccShimmerBlock(width: 58, height: 24, radius: 999),
            ],
          ),
        ),
      ],
    );
  }
}
