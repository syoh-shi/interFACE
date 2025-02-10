/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require("firebase-functions");
const vision = require("@google-cloud/vision");
const cors = require("cors")({origin: "YOUR_URL"});

// Vision クライアントを初期化
const client = new vision.ImageAnnotatorClient();

exports.detectFace = functions.https.onRequest(async (req, res) => {
  // corsミドルウェアでラップ
  return cors(req, res, async () => {
    try {
      // OPTIONS メソッドの場合、とりあえず 200返して終了
      if (req.method === "OPTIONS") {
        return res.status(200).send("OK");
      }
      // POST された JSON ボディに "image" フィールドとして base64 が格納されている想定
      const {image} = req.body;
      if (!image) {
        return res.status(400).json({error: "No image data provided."});
      }

      // 画像解析リクエスト
      // image: { content: <Base64文字列> } の形でVision API に送る
      const [result] = await client.faceDetection({
        image: {content: image},
      });

      // 顔検出結果
      const faces = result.faceAnnotations || [];
      if (faces.length === 0) {
        // 顔が検出されない場合
        return res.json({faces: []});
      }

      // 今回は先頭の顔(=faces[0])だけ解析してレスポンスする例
      const face = faces[0];

      // boundingPolyやfdBoundingPoly など、座標を含む情報が入っている
      // fdBoundingPoly: 顔の特徴点(大まかな四角形)が格納される
      const boundingPoly = face.fdBoundingPoly || face.boundingPoly;

      // 例: 頂点座標を返す
      // vertices には [{x:..., y:...}, ...] が入っている
      return res.json({
        boundingPoly,
      });
    } catch (error) {
      console.error(error);
      return res.status(500).json({error: error.message});
    }
  });
});
