# SmartLedger 아키텍처

## 전체 구조

```
Flutter App (smart_ledger/)
├── Presentation Layer  → features/ (화면)
├── State Layer         → providers/ (Riverpod)
├── Domain Layer        → models/ (데이터 구조)
└── Data Layer          → services/ (Firebase, OCR API)
```

## 상태 관리 흐름 (Riverpod)

```
UI Widget
  └─ ref.watch(provider)
       └─ Provider
            └─ Service (Firestore / HTTP)
```

### 주요 Provider

| Provider | 역할 |
|---|---|
| `selectedMonthProvider` | 현재 선택된 월 (StateProvider) |
| `expenseListProvider` | 월별 지출 목록 조회 (FutureProvider) |
| `expenseTotalProvider` | 월 총 지출액 (Provider, 파생) |
| `categoryListProvider` | 카테고리 목록 (FutureProvider) |
| `categoryNotifierProvider` | 카테고리 CRUD (AsyncNotifierProvider) |
| `budgetProvider` | 월별 예산 조회 (FutureProvider.family) |
| `budgetNotifierProvider` | 예산 저장 (NotifierProvider) |
| `categoryStatsProvider` | 카테고리별 비율 계산 (Provider, 파생) |
| `dailyStatsProvider` | 일별 지출 합계 (Provider, 파생) |

## 영수증 OCR 흐름

```
영수증 스캔 버튼
  → ReceiptUploadScreen (카메라 / 갤러리 선택)
  → ReceiptHandler (이미지 피커 → OcrService 호출)
  → OcrService (Clova OCR API → 파싱)
  → ExpenseEditScreen (OCR 결과 pre-fill → 사용자 확인)
  → ExpenseService (Firestore 저장)
```

## Firebase 컬렉션 구조

```
expenses/
  {id}: { categoryId, categoryName, amount, memo, date, receiptImageUrl, createdAt }

categories/
  {id}: { name, colorIndex, order }

budgets/
  {yyyy-MM}: { amount }
```
