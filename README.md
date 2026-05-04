# SmartLedger

영수증 OCR 기반 스마트 가계부 앱 (Flutter + Firebase)

## 주요 기능

- 영수증 촬영 → Clova OCR 자동 인식 → 지출 자동 등록
- 지출 내역 CRUD (수동 입력/수정/삭제)
- 카테고리별 관리
- 월별 예산 설정 및 진행률 표시
- 카테고리별 지출 분석 (도넛 차트)

## 시작하기

### 1. Flutter 패키지 설치

```bash
cd smart_ledger
flutter pub get
```

### 2. Firebase 설정

1. [Firebase Console](https://console.firebase.google.com)에서 프로젝트 생성
2. Android: `google-services.json` → `smart_ledger/android/app/`
3. iOS: `GoogleService-Info.plist` → `smart_ledger/ios/Runner/`
4. Firestore 데이터베이스 생성 (테스트 모드로 시작)
5. `backend/firebase_rules/firestore.rules` 배포

### 3. Clova OCR 설정

`smart_ledger/lib/services/ocr_service.dart` 에서 아래 값 교체:

```dart
static const _apiUrl = 'YOUR_CLOVA_OCR_INVOKE_URL';
static const _secretKey = 'YOUR_CLOVA_OCR_SECRET_KEY';
```

### 4. 실행

```bash
flutter run
```

## 기술 스택

| 영역 | 기술 |
|---|---|
| Framework | Flutter 3.x |
| 상태 관리 | Riverpod 2.x |
| 데이터베이스 | Firebase Firestore |
| OCR | Naver Clova OCR |
| 차트 | fl_chart |

## 프로젝트 구조

자세한 내용은 [`docs/architecture.md`](docs/architecture.md) 참고
