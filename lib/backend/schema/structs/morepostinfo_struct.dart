// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MorepostinfoStruct extends BaseStruct {
  MorepostinfoStruct({
    List<ImagesStruct>? images,
  }) : _images = images;

  // "images" field.
  List<ImagesStruct>? _images;
  List<ImagesStruct> get images => _images ?? const [];
  set images(List<ImagesStruct>? val) => _images = val;

  void updateImages(Function(List<ImagesStruct>) updateFn) {
    updateFn(_images ??= []);
  }

  bool hasImages() => _images != null;

  static MorepostinfoStruct fromMap(Map<String, dynamic> data) =>
      MorepostinfoStruct(
        images: getStructList(
          data['images'],
          ImagesStruct.fromMap,
        ),
      );

  static MorepostinfoStruct? maybeFromMap(dynamic data) => data is Map
      ? MorepostinfoStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'images': _images?.map((e) => e.toMap()).toList(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'images': serializeParam(
          _images,
          ParamType.DataStruct,
          isList: true,
        ),
      }.withoutNulls;

  static MorepostinfoStruct fromSerializableMap(Map<String, dynamic> data) =>
      MorepostinfoStruct(
        images: deserializeStructParam<ImagesStruct>(
          data['images'],
          ParamType.DataStruct,
          true,
          structBuilder: ImagesStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'MorepostinfoStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is MorepostinfoStruct &&
        listEquality.equals(images, other.images);
  }

  @override
  int get hashCode => const ListEquality().hash([images]);
}

MorepostinfoStruct createMorepostinfoStruct() => MorepostinfoStruct();
