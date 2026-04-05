## Why

Logic tong hop giao dich hien dang khong nhat quan giua cac luong them, sua, xoa, va nhap bang AI. Cung mot truong `totalDebit` dang bi cap nhat theo hai quy uoc trai nguoc nhau, lam cho tong chi tieu, so du, va du lieu tong hop cua nguoi dung bi sai sau mot so thao tac binh thuong.

## What Changes

- Chuan hoa quy uoc nghiep vu cho `amount`, `totalCredit`, `totalDebit`, va `remainingAmount` de moi luong ghi du lieu deu ap dung cung mot cach tinh.
- Dinh nghia lai hanh vi them, sua, va xoa giao dich sao cho cac truong tong hop duoc hoan tac va ap dung dung theo `type`.
- Bo sung yeu cau dong bo cho cac diem vao du lieu giao dich hien co, bao gom luong nhap tay, luong sua giao dich, luong xoa giao dich, va luong them giao dich bang AI.
- Yeu cau co buoc doi chieu va tai tinh toan du lieu tong hop da ton tai de sua cac user document dang lech so lieu.
- Gioi han pham vi thay doi trong logic tong hop giao dich va cac man hinh hien thi phu thuoc truc tiep vao cac truong tong hop; khong mo rong sang thay doi cau truc Firestore, quyen han, hay cac tinh nang khong lien quan.

## Capabilities

### New Capabilities
- `transaction-summary-consistency`: Quy dinh cach tinh va dong bo tong thu, tong chi, va so du nguoi dung nhat quan tren moi luong thao tac giao dich.

### Modified Capabilities

None.

## Impact

- Affected code: `lib/screens/add_transaction_screen.dart`, `lib/widgets/add_transactions_form.dart`, `lib/services/db.dart`, `lib/screens/ai_input_screen.dart`, va cac man hinh hien thi tong hop nhu `lib/widgets/hero_card.dart`, `lib/services/report_service.dart`, cung cac man admin doc `totalDebit`.
- Affected data: user documents trong `users/{uid}` co cac truong `totalCredit`, `totalDebit`, `remainingAmount`; transaction documents trong `users/{uid}/transactions`.
- Affected systems: transaction entry flows, delete/update transaction logic, summary cards, reports, admin monitoring.
- Dependencies: khong them dependency moi; uu tien sua logic hien co va bo sung migration hoac rebuild summary trong pham vi giao dich.
