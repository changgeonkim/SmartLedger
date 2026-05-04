# API 흐름 문서

## 1. Clova OCR API

**엔드포인트**: `POST {CLOVA_OCR_INVOKE_URL}`

**요청 헤더**
```
Content-Type: application/json
X-OCR-SECRET: {SECRET_KEY}
```

**요청 바디**
```json
{
  "version": "V2",
  "requestId": "1234567890",
  "timestamp": 0,
  "images": [
    {
      "format": "jpg",
      "name": "receipt",
      "data": "{base64_encoded_image}"
    }
  ]
}
```

**응답 파싱 경로**

| 데이터 | JSON 경로 |
|---|---|
| 가게명 | `images[0].receipt.result.storeInfo.name.text` |
| 총금액 | `images[0].receipt.result.totalPrice.price.formatted.value` |
| 날짜 | `images[0].receipt.result.paymentInfo.date.formatted` |
| 품목 목록 | `images[0].receipt.result.subResults[].items[]` |

---

## 2. Firestore CRUD

### 지출 내역

| 작업 | 메서드 | 위치 |
|---|---|---|
| 월별 조회 | `ExpenseService.fetchByMonth(month)` | `services/expense_service.dart` |
| 추가 | `ExpenseService.add(expense)` | |
| 수정 | `ExpenseService.update(expense)` | |
| 삭제 | `ExpenseService.delete(id)` | |

### 카테고리

| 작업 | 메서드 | 위치 |
|---|---|---|
| 전체 조회 | `categoryListProvider` | `providers/category_provider.dart` |
| 추가 | `CategoryNotifier.add(name, colorIndex)` | |
| 삭제 | `CategoryNotifier.delete(id)` | |

### 예산

| 작업 | 메서드 | 위치 |
|---|---|---|
| 조회 | `budgetProvider(month)` | `providers/budget_provider.dart` |
| 저장 | `BudgetNotifier.save(month, amount)` | |
