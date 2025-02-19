// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img; // Image processing library
import 'package:http/http.dart' as http;

class CameraLimitedDetector extends StatefulWidget {
  const CameraLimitedDetector({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  final double? width;
  final double? height;

  @override
  _CameraLimitedDetectorState createState() => _CameraLimitedDetectorState();
}

class _CameraLimitedDetectorState extends State<CameraLimitedDetector> {
  CameraController? controller;
  late Future<List<CameraDescription>> _cameras;

  /// 撮影処理が進行中かどうかを表すフラグ
  bool _isProcessingPhoto = false;

  @override
  void initState() {
    super.initState();
    _cameras = availableCameras();
  }

  @override
  void didUpdateWidget(covariant CameraLimitedDetector oldWidget) {
    super.didUpdateWidget(oldWidget);

    // makeSolidPhotoフラグがtrue、かつまだ撮影処理中でない場合のみ撮影
    if (FFAppState().makeSolidPhoto && !_isProcessingPhoto) {
      _isProcessingPhoto = true; // 撮影処理を始める

      controller!.takePicture().then((file) async {
        Uint8List fileAsBytes = await file.readAsBytes();

        // 画像データを均一化する処理
        Uint8List standardizedImage = _standardizeImage(fileAsBytes);
        final base64Image = base64Encode(standardizedImage);

        // 撮影した画像(Base64)を一旦保存(任意で使う場合)
        FFAppState().update(() {
          FFAppState().fileBase64 = base64Image;
        });

        // ▼▼▼ ここから追加：HTTPリクエストでCloud Functionsを呼び出し ▼▼▼
        try {
          final response = await http.post(
            Uri.parse(
              'Cloud FunctionのエンドポイントURL',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'image': base64Image}),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            // boundingPoly 情報があるかチェック
            final boundingPoly = data['boundingPoly'];
            if (boundingPoly != null && boundingPoly['vertices'] != null) {
              List<dynamic> vertices = boundingPoly['vertices'];

              double minX = double.infinity;
              double maxX = -double.infinity;

              for (final v in vertices) {
                if (v['x'] != null) {
                  final xVal = v['x'].toDouble();
                  if (xVal < minX) minX = xVal;
                  if (xVal > maxX) maxX = xVal;
                }
              }

              // 左右の中心Xを計算(整数に丸める)
              final centerX = ((minX + maxX) / 2.0 - 320.0).round();
              final priceCount = FFAppState().pictureCount;

              if (priceCount == null) {
                FFAppState().update(() {
                  FFAppState().boundingBoxCenter = centerX;
                  FFAppState().pictureCount = 1;
                });
              } else {
                final oldcenterX = await FFAppState().boundingBoxCenter;
                // AppStateに保存 (BoundingBoxCenterはint想定)
                FFAppState().update(() {
                  FFAppState().boundingBoxCenterOld = oldcenterX;
                  FFAppState().boundingBoxCenter = centerX;
                  FFAppState().pictureCount += 1;
                });
              }
            }
          } else {
            // エラー時の処理(ログ出力など)
            print('HTTP Error: ${response.statusCode} ${response.body}');
          }
        } catch (e) {
          print('Error calling detectFace: $e');
        }
        // ▲▲▲ 追加箇所ここまで ▲▲▲
      }).catchError((error) {
        print('Error taking picture: $error');
      }).whenComplete(() {
        // 写真撮影フラグと撮影処理中フラグをリセット
        FFAppState().update(() {
          FFAppState().makeSolidPhoto = false;
        });
        _isProcessingPhoto = false;
      });
    }
  }

  // 画像を均一化するメソッド
  Uint8List _standardizeImage(Uint8List imageBytes) {
    // 画像をデコード
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // 解像度を統一
    const targetWidth = 640;
    const targetHeight = 480;
    image = img.copyResize(image, width: targetWidth, height: targetHeight);

    // 明るさの均一化（ヒストグラム均一化）
    img.adjustColor(image, gamma: 0.8); // ガンマ補正を適用

    // エンコードし直してUint8Listに変換
    return Uint8List.fromList(img.encodeJpg(image, quality: 80));
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CameraDescription>>(
      future: _cameras,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            // コントローラ未初期化の場合のみ初期化
            if (controller == null) {
              controller = CameraController(
                snapshot.data![0],
                ResolutionPreset.max,
              );
              controller!.initialize().then((_) {
                if (!mounted) {
                  return;
                }
                setState(() {});
              });
            }
            // カメラが利用可能な場合、プレビューを表示
            return controller!.value.isInitialized
                ? MaterialApp(
                    home: CameraPreview(controller!),
                  )
                : Container();
          } else {
            // カメラが見つからない場合はメッセージを表示
            return Center(child: Text('No cameras available.'));
          }
        } else {
          // 読み込み中はローディングインジケーターを表示
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
