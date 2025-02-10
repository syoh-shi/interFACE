// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future newCustomAction() async {
  // Update FFAppState().boundingBoxCenterOld 's value from current one to FFAppState().boundingBoxCenter

  // Get the current value of FFAppState().boundingBoxCenter
  var currentBoundingBoxCenter = FFAppState().boundingBoxCenter;

  // Update FFAppState().boundingBoxCenterOld with the current value
  FFAppState().update(() {
    FFAppState().boundingBoxCenterOld = currentBoundingBoxCenter;
  });

  // Print a message to confirm the update
  print(
      'FFAppState().boundingBoxCenterOld updated to: ${FFAppState().boundingBoxCenterOld}');
}
