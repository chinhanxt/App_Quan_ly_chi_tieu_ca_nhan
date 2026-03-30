## Why

Ung dung hien tai da gan hoan tat, nhung mot so man hinh quan trong van co nguy co vo layout tren cac may Android hep, thap, hoac de font he thong lon. Van de nay dang xuat hien o the giao dich, thanh dieu huong day, cum nut noi, va man AI, nen can mot change rieng de on dinh giao dien truoc khi tiep tuc mo rong tinh nang.

## What Changes

- Bo sung mot lop quy tac layout mobile de giao dien co the chuyen sang che do compact tren may Android hep, thap, hoac co text scale lon.
- Dieu chinh cac thanh phan co rui ro cao de co fallback layout an toan thay vi chi co mot bo cuc co dinh.
- Giam nguy co de FAB, composer, bottom navigation, va noi dung cuon de len nhau o man hinh nho.
- Chuan hoa cach hien thi text dai, so tien, va metadata de tranh text bi ep thanh cot doc hoac vo card.
- Gioi han pham vi trong nhom UI mobile chinh, khong thay doi nghiep vu, du lieu, hay admin web.

## Capabilities

### New Capabilities
- `mobile-adaptive-layout`: Quy dinh cach cac man hinh mobile cua ung dung phai thich ung voi Android man hep, man thap, safe area, va text scale lon ma khong vo bo cuc.

### Modified Capabilities
- None.

## Impact

- Affected code: `lib/screens/home_screen.dart`, `lib/screens/ai_input_screen.dart`, `lib/widgets/transaction_card.dart`, `lib/widgets/navbar.dart`, `lib/widgets/hero_card.dart`, `lib/widgets/app_chrome.dart`, va mot so widget giao dich lien quan.
- Affected systems: Flutter mobile UI layout, spacing, safe area, bottom navigation, floating actions, text overflow handling.
- Dependencies: Khong them dependency moi; uu tien tan dung helper responsive va pattern hien co.
