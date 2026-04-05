## Context

Ung dung hien co nhieu diem vao ghi du lieu giao dich: man hinh them giao dich, form them giao dich, luong sua/xoa thong qua `Db`, va luong luu giao dich bang AI. Cac diem vao nay dang cap nhat `totalDebit` theo hai quy uoc trai nguoc nhau, trong khi cac man hinh tong hop, bao cao, va admin lai doc cung mot truong tong hop do.

Van de khong chi nam o mot ham sai dau. Day la thay doi cat ngang qua nhieu module, co lien quan den du lieu tong hop dang ton tai trong Firestore, va co nguy co gay regression neu sua tung diem rieng le ma khong chot mot invariant chung.

Rang buoc quan trong cua change nay la giu nguyen cau truc du lieu va cac tinh nang khong lien quan. Muc tieu la chuan hoa nghiep vu tong hop giao dich va dong bo tat ca diem ghi/ doc phu thuoc truc tiep vao no, khong mo rong thanh redesign hay refactor rong.

## Goals / Non-Goals

**Goals:**
- Xac lap mot quy uoc duy nhat cho `amount`, `totalCredit`, `totalDebit`, va `remainingAmount`.
- Bao dam them, sua, xoa, va luu giao dich bang AI deu cap nhat cung mot bo quy tac tong hop.
- Xac dinh co che doi soat hoac tai tinh toan de sua cac user document da sai so lieu truoc do.
- Giu tac dong trong pham vi logic giao dich va cac diem hien thi tong hop truc tiep, khong pha vo cac cau truc khong lien quan.

**Non-Goals:**
- Khong doi schema Firestore.
- Khong thay doi cach luu `type` cua giao dich.
- Khong redesign UI, chi cho phep dieu chinh hien thi dau am/duong neu can de phu hop voi quy uoc moi.
- Khong can thiep vao phan quyen, admin workflow khong lien quan, saving goals, budget rules, hay OCR parsing.

## Decisions

1. **Chon quy uoc tong chi la so duong**
   - `transaction.amount` duoc xem la gia tri tuyet doi, luon duong.
   - `totalCredit` va `totalDebit` deu la tong duong.
   - `remainingAmount = totalCredit - totalDebit`, va luong cap nhat runtime tuong duong voi cong tru tren so du.
   - Ly do: UI hien tai da tu them dau `+`/`-`; bao cao dang tinh `totalCredit - totalDebit`; admin va export cung co xu huong ky vong tong chi la duong.
   - Alternatives da can nhac:
     - Giu `totalDebit` la so am: se yeu cau sua rong hon o UI, report, admin, export, va tang nguy co dau am kep.
     - Cho phep moi luong co quy uoc rieng roi chuan hoa khi hien thi: khong chap nhan vi du lieu tong hop se tiep tuc lech.

2. **Chuan hoa nghiep vu theo thao tac, khong theo dau luu tru**
   - Them `credit`: `remaining += amount`, `totalCredit += amount`
   - Them `debit`: `remaining -= amount`, `totalDebit += amount`
   - Xoa `credit`: `remaining -= amount`, `totalCredit -= amount`
   - Xoa `debit`: `remaining += amount`, `totalDebit -= amount`
   - Sua giao dich: hoan tac giao dich cu theo `oldType`, sau do ap dung giao dich moi theo `newType`
   - Ly do: Giup luong update type-change (`credit -> debit`, `debit -> credit`) dung trong moi truong hop.
   - Alternative da can nhac:
     - Tinh delta truc tiep bang cach tru so cu roi cong so moi tren tung truong: de sai khi doi `type` va kho kiem chung hon.

3. **Gom logic tong hop ve mot diem su that**
   - Cac luong nhap tay, AI, sua, va xoa phai dung chung mot service hoac chung mot cong thuc nghiep vu duy nhat.
   - UI entry points khong nen tu dinh nghia quy tac tinh tong rieng.
   - Ly do: bug hien tai xuat hien chinh vi co nhieu diem vao tu tinh toan.
   - Alternative da can nhac:
     - Sua tung diem vao mot cach doc lap: nhanh hon trong ngan han nhung de tai phat khi them luong moi.

4. **Thuc hien doi soat du lieu user tu lich su giao dich**
   - Can co buoc tai tinh toan `totalCredit`, `totalDebit`, va `remainingAmount` tu `users/{uid}/transactions` de sua cac document nguoi dung da sai.
   - Quy tac doi soat:
     - tong thu = tong `amount` cua `credit`
     - tong chi = tong `amount` cua `debit`
     - so du = tong thu - tong chi
   - Ly do: sua code moi ma bo qua du lieu sai cu se khien UI va bao cao van sai sau deploy.
   - Alternative da can nhac:
     - Khong migration, chi dua vao thao tac moi de du lieu tu can bang dan: qua cham va khong dang tin.
     - Suy ra tu `user` doc hien tai thay vi transaction history: khong sua duoc du lieu da sai.

5. **Khong mo rong thay doi ra ngoai pham vi tong hop giao dich**
   - Khong thay doi cau truc collection, field names, hay cac tinh nang khac.
   - Cac man hinh/report chi duoc sua neu dang gia dinh `totalDebit` am.
   - Ly do: yeu cau cua change la sua logic ma khong pha vo cau truc khong lien quan.

## Risks / Trade-offs

- [Du lieu cu da sai nen sua code xong van thay so lieu bat thuong] -> Bo sung migration/rebuild summary tu transaction history va xac minh truoc/sau.
- [Bo sot mot entry point ghi giao dich] -> Lap danh sach day du cac luong ghi hien co va kiem tra lai sau khi hop nhat cong thuc.
- [UI hien thi dau am kep hoac sai net amount] -> Ra soat cac diem hien thi `totalDebit` va cac phep tinh tong hop truoc khi apply.
- [Transaction history ban than co du lieu bat thuong, vi du amount am] -> Migration phai normalize theo `type` va log cac truong hop khong hop le de xu ly rieng.
- [Sua service trung tam co the anh huong admin/report] -> Giu schema cu, chi thay doi quy tac tinh toan, va kiem tra cac man doc `totalDebit` truc tiep.

## Migration Plan

1. Chot invariant du lieu tong hop va ap dung cho tat ca diem vao giao dich.
2. Chuan hoa logic them/sua/xoa/AI ve cung mot service hoac mot bo helper nghiep vu chung.
3. Ra soat cac man hinh va report dang doc `totalDebit` de dam bao chi hien thi dau, khong dua vao gia tri am.
4. Chay buoc doi soat hoac script rebuild summary cho user documents tu transaction history.
5. Xac minh bang mot ma tran case: them/xoa/sua credit, them/xoa/sua debit, doi type, va transaction AI.

Rollback:
- Co the rollback code logic ve commit truoc neu phat hien regression runtime.
- Neu da chay migration, rollback du lieu phai dua tren transaction history va chay lai rebuild theo quy tac cu; vi vay nen nen test migration tren tap mau truoc khi chay rong.

## Open Questions

- Trong migration, co can xu ly rieng nhung transaction da luu `amount` am hay se chuan hoa bang gia tri tuyet doi?
- Buoc doi soat du lieu se duoc chay mot lan bang script/admin tool hay tich hop thanh mot utility noi bo chi dung trong qua trinh sua loi?
- Co can them test tu dong cho service tong hop truoc khi sua UI hien thi hay chi can test nghiep vu theo integration path?
