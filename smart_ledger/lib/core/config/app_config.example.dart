// 이 파일을 복사해서 app_config.dart로 만든 후 실제 키를 입력하세요.
// cp lib/core/config/app_config.example.dart lib/core/config/app_config.dart

class AppConfig {
  AppConfig._();

  static const clovaOcrApiUrl = 'https://naveropenapi.apigw.ntruss.com/custom-ocr/v1/infer/...';
  static const clovaOcrSecretKey = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

  // Naver Cloud Platform → Application → Maps → Client ID
  static const naverMapsClientId = 'YOUR_NAVER_MAPS_CLIENT_ID';

  // Naver Cloud Platform → Application → Maps → Client Secret
  static const naverMapsClientSecret = 'YOUR_NAVER_MAPS_CLIENT_SECRET';
}
