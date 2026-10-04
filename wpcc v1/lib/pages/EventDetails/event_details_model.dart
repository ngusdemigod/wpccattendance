import '/components/attendee_stack2_widget.dart';
import '/components/info_tile3_widget.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'event_details_widget.dart' show EventDetailsWidget;
import 'package:flutter/material.dart';

class EventDetailsModel extends FlutterFlowModel<EventDetailsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for AttendeeStack.
  late AttendeeStack2Model attendeeStackModel;
  // Model for InfoTile.
  late InfoTile3Model infoTileModel1;
  // Model for InfoTile.
  late InfoTile3Model infoTileModel2;
  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];

  @override
  void initState(BuildContext context) {
    attendeeStackModel = createModel(context, () => AttendeeStack2Model());
    infoTileModel1 = createModel(context, () => InfoTile3Model());
    infoTileModel2 = createModel(context, () => InfoTile3Model());
  }

  @override
  void dispose() {
    attendeeStackModel.dispose();
    infoTileModel1.dispose();
    infoTileModel2.dispose();
  }
}
