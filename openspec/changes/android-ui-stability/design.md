## Context

Ung dung Flutter hien co bo cuc dep tren thiet bi tham chieu, nhung mot so thanh phan duoc xay theo gia dinh chieu rong va chieu cao kha rong. Thuc te Android co nhieu bien the: man hep, man thap, tai tho, thanh dieu huong 3 nut, va text scale lon. Cac man hinh rui ro cao nhat hien nay la `HomeScreen`, `TransactionCard`, `Navbar/FAB`, `HeroCard`, va `AIInputScreen`.

Du an dang o giai doan hoan tat, nen muc tieu khong phai lam lai toan bo UI. Design can uu tien thay doi toi thieu, giam nguy co regression, va chi can thiep o nhung cho co kha nang vo layout ro rang.

## Goals / Non-Goals

**Goals:**
- Tao mot tang responsive nhe cho mobile Android dua tren width, height, safe area, va text scale.
- Cung cap fallback layout cho cac widget co rui ro cao thay vi chi co mot bo cuc co dinh.
- Bao dam text dai, so tien, metadata, quick actions, FAB, va bottom navigation khong de len nhau tren may nho.
- Giu nguyen visual language chinh cua app, khong bien doi lon ve mau sac hay huong thiet ke.

**Non-Goals:**
- Khong redesign toan bo ung dung.
- Khong can thiep vao admin web.
- Khong thay doi logic nghiep vu, schema du lieu, hay luong AI.
- Khong toi uu cho tablet/desktop trong change nay.

## Decisions

1. **Dung breakpoint mobile nhe thay vi mot he thong responsive phuc tap**
   - Quy tac uu tien: `compactWidth`, `shortHeight`, va `largeText`.
   - Ly do: Du de che layout fallback cho Android ma khong phai dua vao design system moi.
   - Alternative da can nhac:
     - Tao design system responsive day du: qua lon cho giai doan hien tai.
     - Sua tung man khong co quy tac chung: nhanh luc dau nhung de mat dong bo.

2. **Uu tien sua component-level truoc screen-level**
   - `TransactionCard`, `Navbar`, `HeroCard`, va cac khung header/composer se co fallback rieng.
   - Ly do: Phan lon su co den tu mot so widget dung chung, sua o day se giam regression rong hon.
   - Alternative da can nhac:
     - Sua tung screen rieng le: de xot lai diem gay khi widget duoc tai su dung noi khac.

3. **Card giao dich phai co bo cuc 2 mode**
   - Man rong: bo cuc ngang hien tai.
   - Man hep: thong tin duoc xep lai theo chieu doc, menu khong duoc ep text.
   - Ly do: Day la diem gay da xuat hien thuc te tren Android.

4. **Bottom actions phai uu tien an toan hon la nhieu nut noi**
   - Cum FAB se duoc tinh lai theo safe area va do chen voi bottom navigation; neu can se rut gon cach hien thi.
   - Ly do: Android man thap de gap tinh trang content, nav, va nut noi chen nhau.

5. **AI screen can co compact density mode**
   - Giam kich thuoc/padding o header, quick section, va composer tren may thap hoac text scale lon.
   - Ly do: Man AI hien dep nhung mat do qua cao, de bi chat tren may thuc te.

6. **Text overflow phai duoc coi la quy tac bat buoc**
   - Tieu de, note, metadata, so tien, chip label, va nav label phai co gioi han dong/fallback ro rang.
   - Ly do: Android thuong gap vo layout do khac biet font he thong va text scale.

## Risks / Trade-offs

- [Widget fallback lam thay doi giao dien so voi may tham chieu] -> Giu visual language hien tai, chi chuyen mode khi gap dieu kien compact/short.
- [Sua `TransactionCard` va `Navbar` co the anh huong nhieu man] -> Uu tien thay doi toi thieu, test thu cong tren man hinh dai dien.
- [Compact mode tren man AI lam giao dien it “hoanh trang” hon] -> Danh doi lay tinh on dinh tren may that.
- [Khong co bo test snapshot da nen regression co the bi bo sot] -> Kiem tra thu cong theo nhom may Android dai dien va text scale lon.

## Migration Plan

- Khong can migration du lieu.
- Trien khai theo cum:
  1. Helper/heuristic cho compact width, short height, large text
  2. `TransactionCard` va widget lien quan
  3. `Navbar` + FAB/home chrome
  4. `HeroCard` / `HomeScreen`
  5. `AIInputScreen`
- Rollback: Co the rollback tung nhom widget bang cach hoan tac file UI tuong ung neu phat sinh regression.

## Open Questions

- Co nen thu nho label o bottom navigation tren man `compactWidth` hay van giu hien day du?
- Co nen rut 2 FAB tren `HomeScreen` thanh 1 speed dial de giam chen nhau khong?
- Co nen gioi han text scale toi da o mot so khu vuc nhay cam, hay chi xu ly bang adaptive layout?
