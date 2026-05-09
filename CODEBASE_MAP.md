# SmartLedger 코드베이스 맵

> 기능별 관련 파일 빠른 참조용

---

## 앱 진입 / 네비게이션

| 역할 | 파일 |
|------|------|
| 앱 진입점, Firebase/NaverMap 초기화 | `lib/main.dart` |
| 하단 탭 네비게이션 (홈/내역/지도/통계/예산) | `lib/navigation/main_navigation.dart` |
| 탭 선택 상태 | `lib/providers/navigation_provider.dart` |

---

## 홈 화면

| 역할 | 파일 |
|------|------|
| 홈 메인 화면 (요약 카드, 내역 리스트, FAB) | `lib/features/home/home_screen.dart` |
| 내역 추가 바텀시트 (카메라/갤러리/수동입력 선택) | `lib/features/receipt/receipt_upload_screen.dart` |

---

## 영수증 OCR

| 역할 | 파일 |
|------|------|
| 카메라/갤러리 이미지 선택 → OCR → 화면 이동 | `lib/features/receipt/receipt_handler.dart` |
| Clova OCR API 호출 및 응답 파싱 | `lib/services/ocr_service.dart` |
| OCR 결과 모델 (OcrResult, OcrItem) | `lib/services/ocr_service.dart` |

---

## 지출/수입 내역

| 역할 | 파일 |
|------|------|
| 내역 추가/수정 폼 화면 | `lib/features/expense/expense_edit_screen.dart` |
| 내역 상세 보기 다이얼로그 | `lib/features/expense/expense_detail_screen.dart` |
| 내역 목록 화면 (내역 탭) | `lib/features/expense/expense_list_screen.dart` |
| Firestore CRUD (add/update/delete) | `lib/services/expense_service.dart` |
| 내역 데이터 모델 (ExpenseModel) | `lib/models/expense_model.dart` |
| 내역 목록/합계 상태 관리 | `lib/providers/expense_provider.dart` |

---

## 카테고리

| 역할 | 파일 |
|------|------|
| 카테고리 관리 화면 | `lib/features/category/category_manage_screen.dart` |
| 카테고리 데이터 모델 | `lib/models/category_model.dart` |
| 카테고리 상태 관리 (목록, 추가) | `lib/providers/category_provider.dart` |

---

## 예산

| 역할 | 파일 |
|------|------|
| 예산 설정 화면 (예산 탭) | `lib/features/stats/budget_screen.dart` |
| 예산 Firestore CRUD | `lib/services/budget_service.dart` |
| 예산 데이터 모델 | `lib/models/budget_model.dart` |
| 예산 상태 관리 | `lib/providers/budget_provider.dart` |

---

## 통계 / 분석

| 역할 | 파일 |
|------|------|
| 통계 화면 (통계 탭) | `lib/features/stats/stats_screen.dart` |
| 분석 화면 | `lib/features/stats/analysis_screen.dart` |
| 분석 데이터 상태 관리 | `lib/providers/analysis_provider.dart` |

---

## 지도

| 역할 | 파일 |
|------|------|
| 지도 화면 (지도 탭, Naver Map) | `lib/features/map/map_screen.dart` |
| 지도 관련 상태 관리 | `lib/providers/map_provider.dart` |

---

## 위치 선택

| 역할 | 파일 |
|------|------|
| 위치 선택 페이지 (내역 추가 시 사용) | `lib/features/location_picker/location_picker_page.dart` |
| 위치 선택 상태 관리 | `lib/providers/location_picker_provider.dart` |
| 장소 검색 서비스 | `lib/services/place_search_service.dart` |
| 좌표 ↔ 주소 변환 | `lib/services/geocoding_service.dart` |
| 장소 검색 결과 모델 (LocationPickerResult) | `lib/models/place_result.dart` |
| Geohash 등 지리 유틸 | `lib/core/utils/geo_utils.dart` |

---

## 인증

| 역할 | 파일 |
|------|------|
| Firebase 익명 로그인, userId 제공 | `lib/providers/auth_provider.dart` |
| Firebase 관련 서비스 | `lib/services/firebase_service.dart` |

---

## 설정

| 역할 | 파일 |
|------|------|
| 설정 화면 | `lib/features/settings/settings_screen.dart` |

---

## 공통 / 인프라

| 역할 | 파일 |
|------|------|
| API 키, 환경 설정값 | `lib/core/config/app_config.dart` |
| 색상 상수 | `lib/core/constants/app_colors.dart` |
| 텍스트 스타일 상수 | `lib/core/constants/app_text_styles.dart` |
| 앱 테마 | `lib/core/theme/app_theme.dart` |
| 날짜 포맷 유틸 | `lib/core/utils/date_utils.dart` |
| 숫자/금액 포맷 유틸 | `lib/core/utils/format_utils.dart` |
| 애니메이션 화면 전환 위젯 | `lib/core/widgets/animated_content_switcher.dart` |
