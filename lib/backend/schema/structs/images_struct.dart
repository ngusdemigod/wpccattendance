// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ImagesStruct extends BaseStruct {
  ImagesStruct({
    String? name,
    String? url,

    /// event id
    String? eventid,
  })  : _name = name,
        _url = url,
        _eventid = eventid;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  set name(String? val) => _name = val;

  bool hasName() => _name != null;

  // "url" field.
  String? _url;
  String get url => _url ?? '';
  set url(String? val) => _url = val;

  bool hasUrl() => _url != null;

  // "eventid" field.
  String? _eventid;
  String get eventid => _eventid ?? '';
  set eventid(String? val) => _eventid = val;

  bool hasEventid() => _eventid != null;

  static ImagesStruct fromMap(Map<String, dynamic> data) => ImagesStruct(
        name: data['name'] as String?,
        url: data['url'] as String?,
        eventid: data['eventid'] as String?,
      );

  static ImagesStruct? maybeFromMap(dynamic data) =>
      data is Map ? ImagesStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'name': _name,
        'url': _url,
        'eventid': _eventid,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'name': serializeParam(
          _name,
          ParamType.String,
        ),
        'url': serializeParam(
          _url,
          ParamType.String,
        ),
        'eventid': serializeParam(
          _eventid,
          ParamType.String,
        ),
      }.withoutNulls;

  static ImagesStruct fromSerializableMap(Map<String, dynamic> data) =>
      ImagesStruct(
        name: deserializeParam(
          data['name'],
          ParamType.String,
          false,
        ),
        url: deserializeParam(
          data['url'],
          ParamType.String,
          false,
        ),
        eventid: deserializeParam(
          data['eventid'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'ImagesStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ImagesStruct &&
        name == other.name &&
        url == other.url &&
        eventid == other.eventid;
  }

  @override
  int get hashCode => const ListEquality().hash([name, url, eventid]);
}

ImagesStruct createImagesStruct({
  String? name,
  String? url,
  String? eventid,
}) =>
    ImagesStruct(
      name: name,
      url: url,
      eventid: eventid,
    );
