# Voice Bill: Cau Don va 1 Cau Nhieu Y

## Muc tieu tai lieu

Tai lieu nay tom tat cach project hien tai xay dung chuc nang nhap bill bang giong noi theo 2 che do:

- `cau don`: moi lan noi chi giai quyet 1 dong bill
- `1 cau nhieu y`: 1 cau noi co the chua nhieu dong bill, sau do tach ra de review

Muc tieu la de AI hoac team o project khac hieu nhanh:

- dang dung cong nghe gi
- pipeline xu ly voice hoat dong nhu the nao
- phan nao la STT, phan nao la parser, phan nao la UI review
- vi sao flow nhieu y phai review truoc khi ghi du lieu

## Stack cong nghe

### 1. Speech-to-text

Project dung package Flutter:

- `speech_to_text`

Vai tro:

- mo micro
- lang nghe va nhan transcript theo thoi gian thuc
- tra ve partial transcript va final transcript
- lay locale uu tien `vi_VN`

Wrapper service duoc dat trong:

- `lib/core/services/speech_capture_service.dart`

Y tuong quan trong:

- tach rieng `SpeechCaptureService` thanh abstraction
- UI khong goi truc tiep plugin
- de test co the fake speech service rat de

### 2. Permission

Project dung:

- `permission_handler`

Vai tro:

- xin quyen microphone
- neu bi tu choi hoac block vinh vien thi hien thong bao va cho phep mo app settings

### 3. Parser tu viet

Project khong dua vao LLM hay cloud parser o critical path.
Thay vao do, parser duoc viet tay trong:

- `lib/core/services/voice_bill_parser.dart`

Parser nay la trung tam cua tinh nang:

- normalize transcript tieng Viet
- tach so luong
- fuzzy match voi menu item
- quyet dinh `confirmAdd`, `pickItem`, `askQuantity`, hoac `retry`
- tach 1 cau nhieu y thanh nhieu segment roi parse tung segment

### 4. UI review

Popup voice nam o:

- `lib/features/bill/voice_bill_entry_popup.dart`

Popup nay khong ghi bill ngay lap tuc. No chi:

- nghe voice
- hien transcript
- parse ket qua
- bat nguoi dung review
- chi tra ve danh sach dong da xac nhan cho man hinh bill

Man hinh nhan ket qua:

- `lib/features/bill/bill_entry_screen.dart`

## Kien truc tong the

Pipeline tong quat:

1. User bam mo popup voice.
2. App xin quyen micro va khoi tao speech engine.
3. Speech engine tra ve transcript.
4. Parser xu ly transcript theo che do dang chon.
5. UI hien ket qua:
   - `cau don`: resolve 1 dong
   - `1 cau nhieu y`: hien danh sach tung dong de review
6. Chi sau khi user xac nhan, popup moi tra ve ket qua cho bill screen.
7. Bill screen moi them vao draft bill.

Nguyen tac an toan cua system:

- voice khong ghi thang vao daily totals
- voice khong auto-commit bill
- multi-intent khong auto-add
- draft bill la bien gioi an toan cuoi cung

## Du lieu va contract chinh

### Voice mode

`VoiceBillEntryMode`

- `single`
- `multiIntent`

### Ket qua parse cau don

`VoiceBillParseResult`

- `rawTranscript`
- `normalizedTranscript`
- `quantity`
- `quantityResolved`
- `step`
- `matchedItem`
- `candidateItems`

### Trang thai xu ly cau don

`VoiceBillResolutionStep`

- `confirmAdd`: da xac dinh duoc mon va so luong
- `pickItem`: co nhieu mon gan dung, user can chon
- `askQuantity`: da biet mon nhung chua chac so luong
- `retry`: khong du tu tin de dung

### Ket qua parse cau nhieu y

`VoiceBillMultiParseResult`

- `lines`
- `canReview`
- `retryMessage`

Moi dong trong `lines` la `VoiceBillReviewLine` voi state rieng:

- `resolved`
- `needsItem`
- `needsQuantity`
- `retry`

Day la diem rat quan trong: multi-intent khong co 1 status chung cho ca cau, ma moi segment co state rieng.

## Cac buoc xu ly transcript

### 1. Normalize tieng Viet

Parser chuan hoa transcript bang cach:

- lower-case
- bo dau tieng Viet
- loai bo ky tu dac biet
- collapse khoang trang

Vi du:

- `Lau ca keo 2 nguoi 2`
- `lau ca keo hai nguoi hai`

deu duoc dua ve dang de match hon.

Ham lien quan:

- `normalizeTranscript(...)`

### 2. Tach so luong cuoi cau

Parser uu tien doc `trailing quantity`.

Vi du:

- `ga rang muoi 2` -> item query = `ga rang muoi`, quantity = `2`
- `rau muong xao toi` -> chua co quantity

Ham lien quan:

- `extractTrailingQuantity(...)`
- `_parseQuantityToken(...)`

Parser co map so bang chu:

- `mot, hai, ba, bon, nam, sau...`

dong thoi ho tro item name co chua so, vi du:

- `lau ca keo 2 nguoi`
- `lau ca keo hai nguoi`

### 3. Match mon voi menu item

Parser khong match exact thuần. No dung fuzzy scoring tu hop nhieu signal:

- token overlap
- lexical overlap
- shared prefix count
- ordered token match
- contains / startsWith
- similarity score theo Levenshtein

Ham lien quan:

- `rankCandidates(...)`
- `_scoreCandidateVariant(...)`
- `_similarityScore(...)`

Ngoai ra parser tao them variant cho ten mon co chu so:

- `2` -> `hai`
- `3` -> `ba`

de tang kha nang match voice transcript.

### 4. Ra quyet dinh ket qua

Sau khi co candidate ranking, parser chia ra 4 nhom:

- match rat chac + co so luong -> `confirmAdd`
- match rat chac + chua co so luong -> `askQuantity`
- co vai candidate hop ly -> `pickItem`
- khong du tu tin -> `retry`

Day la cach flow giu an toan ma van nhanh.

## Che do `cau don`

### Muc tieu

Toi uu cho tinh huong noi tung dong bill mot.
Day la fast path va la che do default.

### Flow

1. User noi 1 cau, vi du `ga rang muoi 2`.
2. Parser normalize va tach so luong.
3. Parser fuzzy-match voi menu.
4. UI xu ly theo `step`:
   - `confirmAdd`: hien nut them ngay
   - `askQuantity`: bat user nhap them so luong
   - `pickItem`: dua danh sach candidate de chon
   - `retry`: yeu cau noi lai
5. Sau khi user xac nhan, popup tra ve 1 `VoiceBillSelection`.

### Uu diem

- don gian
- an toan
- de dung trong moi truong on ao
- it risk parser tach sai

## Che do `1 cau nhieu y`

### Muc tieu

Cho phep doc 1 cau co nhieu dong bill, vi du:

- `ga rang muoi 2, com trang 3, khoai tay chien 1`

### Tu duy thiet ke

Project khong coi day la "1 bai toan parser moi hoan toan".
Thay vao do, no chia thanh 2 tang:

1. tang segmentation
2. tang parse tung segment bang logic cua cau don

Nghia la:

- tach cau thanh cac cum co the la tung dong bill
- parse tung cum bang parser san co

### Chien luoc tach segment

Parser uu tien 3 muc fallback:

#### Muc 1: tach truc tiep bang separator ro rang

`segmentTranscript(...)` se thay cac dau phan tach bang `|`

Danh sach separator dang dung:

- dau phay
- dau cham phay
- `va`
- `và`
- `roi`
- `rồi`
- xuong dong

Neu tach duoc >= 2 segment thi parse tung segment ngay.

#### Muc 2: tach theo quantity boundary

Neu STT khong tra dau phay, parser thu doan:

- tim token nao co ve la quantity
- xem sau quantity co kha nang bat dau ten mon moi hay khong

Vi du logic:

- `ga 2 com 3`

co the duoc hieu la sau `2` bat dau 1 item moi.

Ham lien quan:

- `_segmentByQuantityBoundaries(...)`
- `_isLikelyQuantityBoundary(...)`

#### Muc 3: suy luan segment khong co separator

Neu van khong tach duoc, parser dung 1 dang dynamic programming nhe:

- thu cac chunk token tu ngan den vua
- parse best effort tung chunk
- tim plan co tong diem cao nhat

Ham lien quan:

- `_inferSegmentsWithoutSeparators(...)`
- `_SegmentPlan`

Score cua plan uu tien:

- nhieu line hop ly
- line `resolved` cao diem hon `needsItem`
- line co quantityResolved duoc cong diem them

### Review flow

Khac voi `cau don`, che do multi-intent khong duoc add ngay.

Moi line sau khi parse co the o 1 trong 4 state:

- `resolved`
- `needsItem`
- `needsQuantity`
- `retry`

UI cho phep:

- chon lai mon neu ambiguous
- nhap lai so luong neu thieu
- xoa dong neu transcript qua mo ho

Chi khi tat ca dong con lai deu `resolved`, nut batch add moi duoc enable.

### Vi sao phai review?

Vi `1 cau nhieu y` co risk cao hon:

- STT co the mat dau phay
- co the tach nham ranh gioi giua 2 mon
- 1 line sai khong nen lam hong line dung khac

Nen project chon mo hinh:

- parse tung line doc lap
- hien su bat dinh cho user thay
- chi submit khi da xu ly xong

## Vi du thuc te tu test

### Cau don

- `lau ca keo 2 nguoi 2` -> match `Lau ca keo 2 nguoi`, quantity `2`, `confirmAdd`
- `rau muong xao toi` -> da ro mon, chua ro so luong, `askQuantity`
- `lau 2` -> giu lai quantity `2` nhung item ambiguous, `pickItem`

### Cau nhieu y

- `ga rang muoi 2, com trang 3, khoai tay chien 1`
  -> tach thanh 3 dong, ca 3 dong `resolved`

- `lau ca keo 2 nguoi 2, lau 3`
  -> dong 1 `resolved`
  -> dong 2 `needsItem`, nhung van giu quantity `3`

- `ga rang muoi 2 com trang 3`
  -> neu parser khong tu tin tach an toan thi `canReview = false`
  -> UI yeu cau noi lai ro hon

## Cac quyet dinh kien truc dang hoc hoi tot

### 1. Tach plugin khoi business logic

`SpeechCaptureService` giup:

- test de
- doi plugin de
- UI khong bi khoa chat vao implementation speech package

### 2. Khong dua LLM vao critical path

Voi bai toan nhap bill tai cho:

- toc do quan trong
- tinh on dinh quan trong
- offline-ish/local-first experience huu ich

Rule-based parser + review UI la lua chon hop ly hon goi AI online moi lan noi.

### 3. Multi-intent la "segmentation + single-line parser"

Day la pattern rat de tai su dung cho project khac:

- tách tong the truoc
- resolve tung phan sau

No giam risk hon viec viet 1 parser monolithic cho ca cau.

### 4. Safety boundary nam o draft layer

Voice chi sinh ra de xuat.
Phan ghi du lieu that su van phai di qua man review/draft.

## Neu port sang project khac thi can giu nhung module nao

Toi thieu nen co 4 module rieng:

### 1. Speech adapter

Interface de nhan:

- start
- stop
- partial transcript
- final transcript
- error

### 2. Transcript parser

Can gom:

- normalize
- quantity extraction
- candidate ranking
- single-intent resolve
- multi-intent segmentation

### 3. Review state model

Can co:

- resolved
- needsItem
- needsQuantity
- retry

### 4. Draft integration

Khong commit thang vao data chinh.
Phai co lop tam de user review va sua.

## Nhung diem can tuy bien khi ap dung lai

Khi dua sang project khac, AI hoac dev can doi:

- tu dien so bang chu theo ngon ngu
- separator phu hop kieu noi cua user
- scoring threshold theo domain
- candidate ranking dua tren catalog thuc te
- rule cho item co chua so trong ten
- UI review phu hop nghiep vu

Neu project moi co menu phuc tap hon, co the bo sung:

- alias cho mon an
- synonym dictionary
- category-aware ranking
- cache transcript corrections de hoc dan

## Han che hien tai

- parser van la heuristic, khong hieu nghia sau
- segmentation khong phai luc nao cung tach dung neu user noi lien qua nhanh
- multi-intent hien tai uu tien an toan hon toc do
- batch add dang bat buoc cac dong con lai phai resolve het moi submit

## Khi nao nen dung thiet ke nay

Phu hop khi:

- co danh muc item ro rang
- muon nhap nhanh bang voice nhung van can an toan
- muon test tot, deterministic
- khong muon phu thuoc cloud AI trong luc nhap lieu

It phu hop khi:

- user noi tu do rat dai
- domain can hieu cau lenh phuc tap
- khong co tap candidate item ro rang de fuzzy match

## File code quan trong de tham khao

- `lib/core/services/speech_capture_service.dart`
- `lib/core/services/voice_bill_parser.dart`
- `lib/features/bill/voice_bill_entry_popup.dart`
- `lib/features/bill/bill_entry_screen.dart`
- `test/voice_bill_parser_test.dart`
- `test/voice_bill_entry_popup_test.dart`
- `openspec/changes/add-voice-entry-modes/design.md`

## Tom tat ngan gon

Kien truc cua project nay co the mo ta bang 1 cau:

`Speech-to-text -> normalize transcript -> parse cau don hoac tach nhieu segment -> review UI -> them vao draft bill`

Diem manh nhat cua cach lam nay la:

- khong phu thuoc LLM
- an toan
- de test
- de port
- mo rong duoc tu `cau don` len `1 cau nhieu y` ma khong vo flow cu

