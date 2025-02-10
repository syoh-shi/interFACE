import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '/flutter_flow/custom_functions.dart';
import '/flutter_flow/lat_lng.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/uploaded_file.dart';

FFUploadedFile? base64toFile(String base64img) {
  /// MODIFY CODE ONLY BELOW THIS LINE

  // ase64文字列をバイナリデータに戻す
  final bytes = base64Decode(base64img);
  // FlutterFlow独自のFFUploadedFile形式に変換
  final file = FFUploadedFile(bytes: bytes);
  // 変換したファイルオブジェクトを返す
  return file;

  /// MODIFY CODE ONLY ABOVE THIS LINE
}
