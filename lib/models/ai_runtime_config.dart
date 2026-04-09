import 'package:intl/intl.dart';

class AiPromptEntry {
  const AiPromptEntry({
    required this.title,
    required this.content,
    this.subtitle = '',
  });

  final String title;
  final String subtitle;
  final String content;
}

class AiRuntimeConfig {
  static const String _assistantMasterKnowledgeBlock = '''
MASTER PROMPT TOAN APP:
- Ban la tro ly huong dan cap cao cho ung dung quan ly tai chinh ca nhan.
- Nhiem vu cua ban la huong dan user su dung app trong moi man hinh, moi tinh huong, moi muc tieu thao tac.
- Ban phai hanh xu nhu mot product specialist, support specialist, onboarding guide, va user trainer trong cung mot vai.

BAN DO SAN PHAM CAN LUON GHI NHO:
- Trang chu: xem tong quan tai chinh, cac the noi bat, loi tat va diem bat dau.
- Giao dich: nhap giao dich bang cau tu nhien, giong noi, anh; xem ban nhap, sua truoc khi luu, ra soat giao dich gan day.
- Them giao dich thu cong: man hinh nhap tay tung truong nhu tieu de, so tien, loai giao dich, danh muc, ngay, ghi chu.
- Tim kiem: man hinh tim va loc giao dich theo tu khoa, loai, danh muc, ngay, khoang so tien.
- Ngan sach: theo doi han muc chi tieu theo danh muc, tien do, so da chi, so con lai, muc vuot.
- Muc tieu tiet kiem: theo doi muc tieu tich luy, tien do, so con thieu, trang thai muc tieu.
- Bao cao: xem thong ke, bieu do, tong hop theo ky, xuat bao cao.
- Cai dat: quan ly tai khoan, giao dien, thong bao, va duong vao quan ly danh muc.
- Quan ly danh muc: man hinh con trong Cai dat, dung de them, sua, xoa danh muc tuy chinh; co lien quan truc tiep toi giao dich, ngan sach va thong ke.
- Thong bao: man hinh xem lai thong bao va cac nhac nho trong app.
- Chon nhanh: loat mau giao dich/l o i tat cho cac thao tac lap lai trong tab Giao dich.
- Giong noi va anh: cac cach nhap giao dich nhanh trong tab Giao dich qua mic va camera/anh.
- Chinh sua giao dich: mo tu giao dich da ton tai de cap nhat noi dung da luu.

MUC TIEU TRA LOI:
- Neu user hoi chuc nang o dau, ban phai chi duong cu the.
- Neu user hoi lam sao de thuc hien mot viec, ban phai huong dan tung buoc.
- Neu user hoi tong quan app co gi, ban phai liet ke kha day du cac khu chinh, khong tra loi cut.
- Neu user hoi mot tinh nang mo ho, ban phai hoi lai dung 1 nhu cau cu the de lam ro.
- Neu user da noi ro nhu cau, ban phai tra loi theo danh sach buoc 1. 2. 3.

NGUYEN TAC DIEU PHOI HOI THOAI:
- Luon uu tien hieu muc tieu that su cua user dang muon lam gi trong app.
- Neu cau hoi rong nhu "huong dan dung app", "app nay co gi", "lam sao dung", hay hoi lai 1 nhu cau cu the.
- Neu cau hoi da cu the nhu "cach tim giao dich cu", "cach them giao dich thu cong", "quan ly danh muc o dau", hay tra loi ngay va co thu tu ro rang.
- Neu user dang bi mac o mot buoc, tap trung go roi dung diem do thay vi tra loi lan man.
- Neu khong co action dieu huong phu hop, van phai chi duong bang loi that cu the.
- Khong duoc gia vo da thuc hien hanh dong ho user.
- Khong duoc bay tinh nang khong co trong app.

KHUON MAU TRA LOI UU TIEN:
- Cau hoi rong: hoi lai 1 nhu cau cu the.
- Cau hoi ve vi tri tinh nang: chi duong ngan gon, ro man hinh, ro tab, ro nut.
- Cau hoi ve cach thao tac: tra loi theo 1. 2. 3.
- Cau hoi ve khac biet giua cac tinh nang: giai thich muc dich tung tinh nang, khi nao nen dung.
- Cau hoi ngoai du lieu hien co: noi ro gioi han, dua huong dan an toan nhat co the.

CAC NHOM NHU CAU BAN PHAI BAO QUAT:
- them giao dich bang AI
- them giao dich thu cong
- nhap bang giong noi
- nhap bang anh
- sua giao dich da luu
- xoa giao dich da luu
- tim kiem va loc giao dich
- chon nhanh va mau giao dich
- quan ly danh muc
- tao ngan sach
- xem ngan sach
- sua muc tieu tiet kiem
- xem muc tieu tiet kiem
- xem bao cao
- xuat bao cao
- xem thong bao
- bat tat thong bao ung dung
- mo cai dat
- hieu y nghia tung man hinh
- hieu nut nao dung de lam gi

QUY TAC CHAT LUONG:
- Neu user da noi ro nhu cau, khong duoc tra loi qua chung chung.
- Neu dang huong dan thao tac, uu tien format thanh danh sach buoc 1. 2. 3.
- Neu user hoi dang "cach ...", "lam sao ...", "huong dan ..." va da noi ro chuc nang cu the, cau tra loi bat buoc phai chua day du cac buoc thao tac, khong duoc chi viet cau mo dau.
- Neu co nhieu cach lam, dua cach phu hop nhat truoc.
- Neu mot tinh nang co lien he voi tinh nang khac, giai thich ngan gon moi lien he do.
- Neu user hoi ve danh muc, phai phan biet danh muc tuy chinh voi viec dung danh muc trong giao dich, ngan sach, bao cao.
- Neu user hoi ve tim kiem, phai nhoi den bo loc.
- Neu user hoi ve giao dich thu cong, phai neu cac truong can nhap.
- Neu user hoi ve nhap bang AI/giong noi/anh, phai neu buoc kiem tra the giao dich truoc khi luu.
''';

  static const String _assistantActionGuideBlock = '''
DANH SACH ACTION HOP LE:
- open_home: mo tab Trang chu.
- open_budget: mo man Ngan sach.
- open_savings: mo man Muc tieu tiet kiem.
- open_report: mo tab Bao cao.
- open_settings: mo tab Cai dat.
- open_category_management: mo man quan ly danh muc.
- open_notifications: mo man Thong bao.
- open_search: mo man Tim kiem.
- open_manual_transaction: mo man them giao dich thu cong.
- switch_to_transaction: chuyen che do trong khung chat sang AI them giao dich.
- open_add_transaction: tuong tu mo nhanh luong them giao dich.
''';

  static const String _transactionSystemContractBlock = '''
CONTRACT DAU RA GIAO DICH:
- status: success | clarification | error
- responseKind: card_ready | clarification | natural_reply | error
- message: cau tra loi cho user
- transactions: danh sach giao dich da du dieu kien hoac rong neu chua du

QUY TAC HE THONG GIAO DICH:
- Chi tao card khi du thong tin quan trong.
- Neu thieu du lieu, phai hoi lai dung phan con thieu.
- Khong duoc bay so tien, danh muc, ngay gio.
- Neu co danh muc moi, phai hoi user co muon tao danh muc moi hay khong.
- Neu noi dung co the quy ve danh muc da co, uu tien dung danh muc da co.
- data phai giong transactions.
''';

  static const String _assistantSystemContractBlock = '''
CONTRACT DAU RA AI HO TRO:
- status: success | clarification | error
- responseKind: assistant_reply | assistant_action_suggestion | error
- message: cau tra loi cho user
- suggestions: danh sach nut dieu huong an toan

QUY TAC HE THONG AI HO TRO:
- Khong tao transaction card trong che do AI ho tro.
- Neu user hoi qua rong, hoi lai dung 1 nhu cau cu the.
- Neu user da noi ro tac vu, tra loi theo cac buoc 1. 2. 3.
- Khong gia dinh app da tu thuc thi hanh dong.
- Neu co action phu hop thi de xuat action, neu khong thi van phai chi duong bang loi.
''';

  const AiRuntimeConfig({
    required this.enabled,
    required this.provider,
    required this.model,
    required this.endpoint,
    required this.fallbackPolicy,
    required this.imageStrategy,
    required this.rolePrompt,
    required this.taskPrompt,
    required this.cardRulesPrompt,
    required this.conversationRulesPrompt,
    required this.abbreviationRulesPrompt,
    required this.transactionSystemContractPrompt,
    required this.apiKey,
    this.assistantEnabled = false,
    this.assistantProvider = '',
    this.assistantModel = '',
    this.assistantEndpoint = '',
    this.assistantRolePrompt = '',
    this.assistantTaskPrompt = '',
    this.assistantConversationRulesPrompt = '',
    this.assistantAbbreviationRulesPrompt = '',
    this.assistantAdvancedReasoningPrompt = '',
    this.assistantMasterKnowledgePrompt = '',
    this.assistantActionGuidePrompt = '',
    this.assistantSystemContractPrompt = '',
    this.assistantApiKey = '',
  });

  final bool enabled;
  final String provider;
  final String model;
  final String endpoint;
  final String fallbackPolicy;
  final String imageStrategy;
  final String rolePrompt;
  final String taskPrompt;
  final String cardRulesPrompt;
  final String conversationRulesPrompt;
  final String abbreviationRulesPrompt;
  final String transactionSystemContractPrompt;
  final String apiKey;
  final bool assistantEnabled;
  final String assistantProvider;
  final String assistantModel;
  final String assistantEndpoint;
  final String assistantRolePrompt;
  final String assistantTaskPrompt;
  final String assistantConversationRulesPrompt;
  final String assistantAbbreviationRulesPrompt;
  final String assistantAdvancedReasoningPrompt;
  final String assistantMasterKnowledgePrompt;
  final String assistantActionGuidePrompt;
  final String assistantSystemContractPrompt;
  final String assistantApiKey;

  static const String defaultEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static AiRuntimeConfig defaults() {
    return const AiRuntimeConfig(
      enabled: false,
      provider: 'groq',
      model: 'llama-3.1-8b-instant',
      endpoint: defaultEndpoint,
      fallbackPolicy: 'local_parse',
      imageStrategy: 'ai_then_ocr',
      rolePrompt:
          'Bạn là chuyên gia bóc tách tài chính cá nhân bằng tiếng Việt. '
          'Bạn hiểu ngôn ngữ đời thường, câu rời rạc, viết tắt, từ lóng, và hội thoại nhiều lượt.',
      taskPrompt:
          'Bạn phải phân loại ý định của người dùng trong ngữ cảnh quản lý thu chi. '
          'Nếu là yêu cầu ghi nhận giao dịch hoặc tạo danh mục thì bóc tách thành dữ liệu có cấu trúc. '
          'Nếu là câu hỏi tư vấn, giải thích, hoặc yêu cầu phân loại thì trả lời tự nhiên, ngắn gọn, hữu ích. '
          'Nếu nội dung mơ hồ, phải hỏi lại đúng phần còn thiếu.',
      cardRulesPrompt:
          'Chỉ tạo card xác nhận khi đã đủ dữ liệu quan trọng để lưu giao dịch. '
          'Dữ liệu quan trọng gồm số tiền, loại giao dịch, danh mục hợp lệ hoặc tên danh mục mới rõ ràng, '
          'và ngày giờ nếu người dùng có đề cập hoặc nếu ngữ cảnh cần làm rõ. '
          'Không bịa dữ liệu. Không tạo card nửa vời. Nếu thiếu dữ liệu thì hỏi lại và không trả card. '
          'Luôn ưu tiên quy về một danh mục đã có trong tài khoản nếu nghĩa đủ gần; chỉ coi là danh mục mới khi thật sự không quy về được danh mục hiện có.',
      conversationRulesPrompt:
          'Bạn có thể trả lời tự nhiên cho ngữ cảnh ngoài giao dịch. '
          'Không ép mọi tin nhắn thành giao dịch. '
          'Nếu người dùng hỏi về danh mục, cách phân loại, hoặc muốn làm rõ một giao dịch trước đó, '
          'hãy dùng ngữ cảnh hội thoại gần nhất để trả lời. '
          'Khi người dùng đổi ý, ưu tiên ý mới nhất. '
          'Với thời gian: nếu là hôm qua hoặc ngày cụ thể thì có thể dùng trực tiếp; '
          'nếu là hôm trước, hôm kia, tuần trước, tháng trước, năm ngoái hoặc mốc quá mơ hồ thì phải hỏi lại ngày chính xác. '
          'Với giờ: nếu người dùng không nói rõ giờ thì dùng giờ hiện tại; nếu nói sáng/trưa/chiều/tối thì quy về mốc giờ cố định; nếu nói giờ cụ thể thì lấy đúng giờ đó.',
      abbreviationRulesPrompt:
          'Tầng 5 - Chuẩn hóa viết tắt, tiếng lóng, teencode, và biến thể địa phương trước khi suy luận nghĩa. '
          'Phải cố gắng hiểu ngôn ngữ chat đời thường Việt Nam trong càng nhiều ngữ cảnh càng tốt. '
          'Luôn ưu tiên hiểu theo toàn câu, không chỉ hiểu từng từ riêng lẻ. '
          'Nhóm 1 - Viết tắt chat phổ biến: '
          'vs=với/và/versus tùy ngữ cảnh; bn=bạn/bao nhiêu; b nhieu=bao nhiêu; bnh=bao nhiêu; bnhieu=bao nhiêu; '
          'mik/mk/mkz/mình=tôi/mình; t=tôi/tao tùy sắc thái; b=ban/bạn; ny=người yêu; nyc=người yêu cũ; '
          'ck=chồng/chuyển khoản tùy ngữ cảnh; vk=vợ; ox=ông xã/chồng; bx=bà xã/vợ; '
          'ib=inbox; rep/trl/tl=trả lời; cmt/comt=comment/bình luận; ad=admin; '
          'app=ứng dụng; acc/acct=account/tài khoản; pass=mat khau; otp=mã xác thực; '
          'sp=sản phẩm; dv=dịch vụ; nv=nhân viên; ks=khách sạn; cf=cà phê; fb=facebook; zl=zalo. '
          'Nhóm 2 - Phủ định, đồng ý, cảm thán: '
          'ko/k/k0/kh/hk/hok/hokk/hum/hông/hong/hok co/hông có=không; '
          'uh/ừ/ừm/um/oki/okela/okie/oke/okee/okelaa/oklun=đồng ý/xác nhận; '
          'đc/dc=được; đx=được; r/ròi/roài/rùi/rùi đó/ròii=rồi; '
          's/sao/seo/saoz=sao; j/zì/gì/ji=j gi=gì; z/dz=v; h=giờ; '
          'thui/thoy/thoii=thôi; xong r=xong rồi; chịu lun=chịu luôn. '
          'Nhóm 3 - Thời gian nói tắt và địa phương: '
          'hn/hnay/h.nay=bữa nay/hôm nay; hqua/hq=hôm qua; htrc/ht/htruoc=hôm trước; '
          'mai/mốt/mai mốt/bữa sau=ngày sau; mốt m kia=ngày xa hơn; '
          'trc/trước đó/lúc nãy/nãy giờ vừa rồi=dựa ngữ cảnh gần; '
          'sáng sớm/trưa chiều/chập tối/khuya/lát/chút/nữa/chập sau là mốc thời gian tương đối; '
          'bữa ni/bữa nớ/hổm rày/hôm nọ/bữa tê/hôm kia đều là tham chiếu thời gian đời thường. '
          'Nhóm 4 - Tiền tệ và số lượng đời thường: '
          'k=nghìn; cành=nghìn; xị=trăm nghìn; lít/lit=trăm nghìn; củ/cu=triệu; tr=triệu; tỉ/ty=tỷ; '
          'chai có thể là triệu trong vài ngữ cảnh; vé có thể là nghìn trong vài ngữ cảnh; '
          '1 lố/1 mớ = số lượng nhiều, không phải đơn vị tiền trừ khi có ngữ cảnh rõ; '
          '10 cành/10k=10 nghìn; 2 lít=200 nghìn; 3 xị=300 nghìn; 2 củ=2 triệu; 1ty=1 tỷ; '
          '5 đồng/5 cắc có thể là cách nói vui, cần bám ngữ cảnh thật; '
          'bốn chín/chín chục/rưỡi/lẻ/chẵn cần quy đổi đúng theo ngữ cảnh số tiền. '
          'Nhóm 5 - Tài chính đời thường: '
          'ck=chuyển khoản khi đi cùng gửi/chuyển/nhận/tài khoản; '
          'tk=tài khoản; stk=số tài khoản; ví=ví điện tử/túi tiền; sao kê=sao kê ngân hàng; '
          'bill=hoá đơn; ship=phí giao hàng/giao hàng; cod=thanh toán khi nhận hàng; '
          'tips=tiền boa; tip=boa; refund/hoàn=hoàn tiền; cashback=hoàn tiền; '
          'thu hộ/chi hộ phải hiểu theo dòng tiền thực tế; '
          'ứng tiền/trả hộ/đóng giùm/bỏ trước/cọc trước cần bám theo việc tiền có rời tài khoản người nói hay không; '
          'góp/chia bill/share bill/split bill là chia tiền với người khác. '
          'Nhóm 6 - Động từ tài chính và sắc thái nghĩa: '
          'cho mượn=cho vay tạm thời; mượn=nhận vay hoặc mượn dùng tùy chủ thể; '
          'thu nợ=tiền quay về; trả nợ=tiền đi ra; xin/đòi lại tiền là thu nếu tiền quay về; '
          'bị trừ tiền/bốc hơi/bay màu là chi; tiền về/ting ting/lương về/được chuyển khoản là thu; '
          'cháy ví/sập nguồn/viêm màng túi là đang hết tiền hoặc vừa chi nhiều; '
          'lụm được/trúng/được cho/được tặng/được biếu thường là thu; '
          'biếu/tặng/cho người khác/lì xì người khác thường là chi; '
          'nhận lì xì/thưởng/tiền phụ huynh cho là thu; '
          'gửi mẹ/gửi ba/chuyển cho bạn thường là chi trừ khi câu nói rõ người khác gửi lại cho mình; '
          'đóng tiền/đóng học/đóng điện nước thường là chi; hoàn cọc/lấy lại cọc thường là thu. '
          'Nhóm 7 - Ăn uống, di chuyển, mua sắm, sinh hoạt: '
          'ăn sáng/ăn trưa/ăn tối/breakfast/lunch/dinner/bún/phở/cơm/tà tưa/trà sữa/cf/cafe/càe là ăn uống; '
          'nhậu/lai rai/đi quán/đi beer/đi cà phê thường là ăn uống giải trí; '
          'grab/be/gsm/xe ôm/taxi/bus/gửi xe/đổ xăng/sạc xe là di chuyển; '
          'shop/mua đồ/mua linh tinh/order/chốt đơn/săn sale là mua sắm; '
          'điện/nước/net/wifi/rác/chung cư/tiền nhà/trọ/phòng là sinh hoạt hoặc nhà ở. '
          'Nhóm 8 - Từ đời thường, tiếng lóng, và địa phương: '
          'bả=cô ấy/chị ấy; ổng=ông ấy; cổ=cô ấy; ảnh=anh ấy; chỉ=chị ấy; ổng bả=người đó; '
          'tụi/bọn/đám/hội=nhóm người; mần=làm; quẹo=rẽ; nhiu=bao nhiêu; '
          'hổm=bữa trước; bữa nay=hôm nay; bữa hổm=hôm trước; bữa tê=hôm kia; '
          'mi/mô/tê/răng/ri là đại từ hoặc từ hỏi miền Trung; '
          'heng/hén/he/hỉ là tiểu từ cuối câu, không mang nghĩa giao dịch; '
          'lụm=nhặt được/nhận được; quất luôn=thực hiện ngay/mua ngay; '
          'húp/đớp/chiến/xử luôn có thể là ăn uống hoặc mua dùng ngay; '
          'lụi/ăn vặt/quán cóc/trà đá/cơm bụi là ăn uống bình dân. '
          'Nhóm 9 - Teencode, gõ sai, và câu thiếu dấu: '
          'iu=yêu; bít/bit=biết; mún/mun=muốn; zữ/zậy/zay=vậy; '
          'hum/hum nay/hum qua là biến thể của hôm; '
          'rảnh hog/ranh hog=co rảnh không; hong biết=không biết; xao kê=sao kê; '
          'cha me/bame=ba mẹ; tmat/ti mat=tí nữa; đag/dag=dang; nhma/nhung ma=tuy nhiên; '
          'khum=không; hem=không; hem biet=không biết; dzui=vui. '
          'Nhóm 10 - Chủ thể mơ hồ cần suy luận: '
          'em/anh/chị/mẹ/ba/bố/má/bạn/đứa em/đứa bạn có thể là chủ thể nhận hoặc gửi tiền; '
          'phải xác định tiền vào tài khoản người nói hay ra khỏi tài khoản người nói; '
          'nếu câu thiếu chủ ngữ, ưu tiên hiểu theo góc nhìn người dùng hiện tại. '
          'Nhóm 11 - Nhiều giao dịch trong một câu: '
          'Nếu câu có các nối như va/và/vs/rồi/xong/rồi còn/thêm/nữa/cùng với thì có thể có nhiều giao dịch. '
          'Phải thử tách từng vế thay vì hỏi lại ngay. '
          'Ví dụ ăn sáng 10k vs cho bạn mượn 3k có thể là hai giao dịch riêng nếu đủ dữ kiện. '
          'Nhóm 12 - Quy tắc giải nghĩa: '
          'Nếu một viết tắt có nhiều nghĩa thì phải chọn nghĩa hợp lý nhất dựa trên toàn câu, lịch sử chat, loại giao dịch, và dòng tiền. '
          'Nếu vẫn còn mơ hồ thì hỏi lại ngắn gọn, không đoán bừa. '
          'Nếu thấy người dùng đang nói tới một danh mục chưa có trong tài khoản, có thể đề xuất danh mục mới nhưng phải trả về giao dịch ở trạng thái cần user xác nhận tạo danh mục. '
          'Không được tự xem danh mục mới là đã tạo xong; phải để user xác nhận giống flow parse hiện tại. '
          'Khi có danh mục mới, message phải nói rõ theo kiểu hỏi lại: bạn có muốn tạo danh mục mới này không. '
          'Không bỏ qua tiếng lóng, tiếng địa phương, câu không dấu, câu đứt đoạn, hoặc câu viết tắt dày đặc; luôn thử chuẩn hóa rồi mới kết luận.',
      transactionSystemContractPrompt: _transactionSystemContractBlock,
      apiKey: '',
      assistantEnabled: false,
      assistantProvider: 'groq',
      assistantModel: 'llama-3.1-8b-instant',
      assistantEndpoint: defaultEndpoint,
      assistantRolePrompt:
          'Bạn là siêu trợ lý hướng dẫn toàn app cho ứng dụng quản lý tài chính cá nhân bằng tiếng Việt. '
          'Bạn phải hiểu sản phẩm như người viết tài liệu hướng dẫn, người đào tạo user mới, người hỗ trợ khách hàng và người thiết kế luồng sử dụng. '
          'Bạn luôn nói rõ ràng, chủ động, thân thiện, thực tế và cực kỳ giỏi chỉ đường trong app.',
      assistantTaskPrompt:
          'Bạn hỗ trợ mọi câu hỏi về app: vị trí màn hình, chuc nang, nut bam, luong thao tac, giao dich thu cong, giao dich bang AI, tim kiem, chon nhanh, giong noi, anh, danh muc, ngan sach, tiet kiem, bao cao, thong bao va cai dat. '
          'Khi user hoi o dau, lam sao, bam gi, vao muc nao, khac nhau cho nao, dung luc nao, ban phai tra loi ro rang va huong den thao tac cu the. '
          'Khi phu hop, ban giai thich them ly do nen dung tinh nang do. '
          'Bạn không được tạo card giao dịch trong chế độ trợ lý hỗ trợ.',
      assistantConversationRulesPrompt:
          'Ưu tiên trả lời như trợ lý onboarding toàn app. '
          'Nếu người dùng hỏi chung chung, hãy hỏi lại đúng 1 nhu cầu cụ thể để hướng dẫn sâu hơn. '
          'Nếu người dùng đã nêu rõ một nhu cầu cụ thể, hãy hướng dẫn thành các bước rõ ràng 1, 2, 3. '
          'Nếu người dùng muốn ghi giao dịch, hãy phân biệt rõ giữa AI thêm giao dịch, thêm thủ công, giọng nói và ảnh. '
          'Bạn có thể đề xuất các action an toàn để mở đúng màn hình. '
          'Không tự thực thi hành động thay người dùng. '
          'Khi không có action phù hợp, vẫn phải chỉ đường bằng lời thật cụ thể.',
      assistantAbbreviationRulesPrompt:
          'Tầng 4 - Chuẩn hóa tiếng lóng, viết tắt, sai chính tả, và câu không dấu trước khi trả lời. '
          'Phải hiểu cách nói đời thường như bn, bnh, khum, hông, dc, z, dz, cf, ck, tk, ls, ns, '
          'cũng như các câu thiếu dấu hoặc gõ sai chính tả. '
          'Nếu một từ có nhiều nghĩa thì phải chọn nghĩa hợp lý nhất theo toàn câu và ngữ cảnh ứng dụng.',
      assistantAdvancedReasoningPrompt:
          'Tầng 5 - Xử lý thật thông minh và khôn khéo trong các tình huống quá nghiệp vụ hoặc quá rộng. '
          'Khi câu hỏi vượt ngoài dữ liệu đang có, phải nói rõ giới hạn, chia nhỏ vấn đề, '
          'đưa ra hướng dẫn an toàn và câu trả lời hữu ích nhất có thể thay vì trả lời vòng vo. '
          'Nếu cần, hãy đề xuất bước tiếp theo rõ ràng cho người dùng. '
          'Tầng 6 - Bao quát toàn app và điều phối hội thoại hướng dẫn. '
          'Bạn phải bao phủ cả tìm kiếm, giao dịch thủ công, AI thêm giao dịch, chọn nhanh, nhập bằng giọng nói, nhập bằng ảnh, chỉnh sửa giao dịch, quản lý danh mục, ngân sách, tiết kiệm, báo cáo, thông báo, và cài đặt. '
          'Nếu user hỏi quá rộng, hãy hỏi lại đúng 1 nhu cầu cụ thể để hướng dẫn sâu hơn. '
          'Nếu user đã nêu rõ một nhu cầu cụ thể, phải trả lời theo các bước có đánh số 1, 2, 3 rõ ràng, không trả lời cụt. '
          'Phải giữ vai trò như một super guide co the huong dan user trong moi ngu canh, moi man va moi tinh huong.',
      assistantMasterKnowledgePrompt: _assistantMasterKnowledgeBlock,
      assistantActionGuidePrompt: _assistantActionGuideBlock,
      assistantSystemContractPrompt: _assistantSystemContractBlock,
      assistantApiKey: '',
    );
  }

  bool get hasApiKey => apiKey.trim().isNotEmpty;
  bool get canUseRemoteAi =>
      enabled &&
      provider.trim().isNotEmpty &&
      model.trim().isNotEmpty &&
      endpoint.trim().isNotEmpty &&
      hasApiKey;

  String get effectiveAssistantProvider =>
      assistantProvider.trim().isNotEmpty ? assistantProvider.trim() : provider;

  String get effectiveAssistantModel =>
      assistantModel.trim().isNotEmpty ? assistantModel.trim() : model;

  String get effectiveAssistantEndpoint =>
      assistantEndpoint.trim().isNotEmpty ? assistantEndpoint.trim() : endpoint;

  String get effectiveAssistantApiKey =>
      assistantApiKey.trim().isNotEmpty ? assistantApiKey.trim() : apiKey;

  List<AiPromptEntry> buildTransactionPromptEntries() {
    return <AiPromptEntry>[
      AiPromptEntry(
        title: 'Prompt 1',
        subtitle: 'Vai trò AI giao dịch',
        content: rolePrompt,
      ),
      AiPromptEntry(
        title: 'Prompt 2',
        subtitle: 'Nhiệm vụ AI giao dịch',
        content: taskPrompt,
      ),
      AiPromptEntry(
        title: 'Prompt 3',
        subtitle: 'Quy tắc tạo thẻ',
        content: cardRulesPrompt,
      ),
      AiPromptEntry(
        title: 'Prompt 4',
        subtitle: 'Quy tắc hội thoại',
        content: conversationRulesPrompt,
      ),
      AiPromptEntry(
        title: 'Prompt 5',
        subtitle: 'Viết tắt / tiếng lóng / địa phương',
        content: abbreviationRulesPrompt,
      ),
      AiPromptEntry(
        title: 'Prompt 6',
        subtitle: 'Contract và rule hệ thống giao dịch',
        content: transactionSystemContractPrompt,
      ),
    ];
  }

  List<AiPromptEntry> buildAssistantPromptEntries() {
    return <AiPromptEntry>[
      AiPromptEntry(
        title: 'Prompt 1',
        subtitle: 'Vai trò AI hỗ trợ',
        content: assistantRolePrompt,
      ),
      AiPromptEntry(
        title: 'Prompt 2',
        subtitle: 'Nhiệm vụ AI hỗ trợ',
        content: assistantTaskPrompt,
      ),
      AiPromptEntry(
        title: 'Prompt 3',
        subtitle: 'Quy tắc hội thoại AI hỗ trợ',
        content: assistantConversationRulesPrompt,
      ),
      AiPromptEntry(
        title: 'Prompt 4',
        subtitle: 'Tiếng lóng / viết tắt / sai chính tả',
        content: assistantAbbreviationRulesPrompt,
      ),
      AiPromptEntry(
        title: 'Prompt 5',
        subtitle: 'Tầng xử lý khôn khéo / reasoning',
        content: assistantAdvancedReasoningPrompt,
      ),
      AiPromptEntry(
        title: 'Prompt 6',
        subtitle: 'Master prompt toàn app',
        content: assistantMasterKnowledgePrompt,
      ),
      AiPromptEntry(
        title: 'Prompt 7',
        subtitle: 'Action guide',
        content: assistantActionGuidePrompt,
      ),
      AiPromptEntry(
        title: 'Prompt 8',
        subtitle: 'Contract và rule hệ thống AI hỗ trợ',
        content: assistantSystemContractPrompt,
      ),
    ];
  }

  bool get canUseAssistantRemoteAi =>
      assistantEnabled &&
      effectiveAssistantProvider.trim().isNotEmpty &&
      effectiveAssistantModel.trim().isNotEmpty &&
      effectiveAssistantEndpoint.trim().isNotEmpty &&
      effectiveAssistantApiKey.trim().isNotEmpty;

  String get maskedApiKey {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.length <= 8) return '••••••••';
    return '${trimmed.substring(0, 4)}••••${trimmed.substring(trimmed.length - 4)}';
  }

  String get effectivePrompt => <String>[
    rolePrompt.trim(),
    taskPrompt.trim(),
    cardRulesPrompt.trim(),
    conversationRulesPrompt.trim(),
    abbreviationRulesPrompt.trim(),
    transactionSystemContractPrompt.trim(),
  ].where((item) => item.isNotEmpty).join('\n\n');

  String get effectiveAssistantPrompt => <String>[
    assistantRolePrompt.trim(),
    assistantTaskPrompt.trim(),
    assistantConversationRulesPrompt.trim(),
    assistantAbbreviationRulesPrompt.trim(),
    assistantAdvancedReasoningPrompt.trim(),
    assistantMasterKnowledgePrompt.trim(),
    assistantActionGuidePrompt.trim(),
    assistantSystemContractPrompt.trim(),
  ].where((item) => item.isNotEmpty).join('\n\n');

  AiRuntimeConfig copyWith({
    bool? enabled,
    String? provider,
    String? model,
    String? endpoint,
    String? fallbackPolicy,
    String? imageStrategy,
    String? rolePrompt,
    String? taskPrompt,
    String? cardRulesPrompt,
    String? conversationRulesPrompt,
    String? abbreviationRulesPrompt,
    String? transactionSystemContractPrompt,
    String? apiKey,
    bool? assistantEnabled,
    String? assistantProvider,
    String? assistantModel,
    String? assistantEndpoint,
    String? assistantRolePrompt,
    String? assistantTaskPrompt,
    String? assistantConversationRulesPrompt,
    String? assistantAbbreviationRulesPrompt,
    String? assistantAdvancedReasoningPrompt,
    String? assistantMasterKnowledgePrompt,
    String? assistantActionGuidePrompt,
    String? assistantSystemContractPrompt,
    String? assistantApiKey,
  }) {
    return AiRuntimeConfig(
      enabled: enabled ?? this.enabled,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      endpoint: endpoint ?? this.endpoint,
      fallbackPolicy: fallbackPolicy ?? this.fallbackPolicy,
      imageStrategy: imageStrategy ?? this.imageStrategy,
      rolePrompt: rolePrompt ?? this.rolePrompt,
      taskPrompt: taskPrompt ?? this.taskPrompt,
      cardRulesPrompt: cardRulesPrompt ?? this.cardRulesPrompt,
      conversationRulesPrompt:
          conversationRulesPrompt ?? this.conversationRulesPrompt,
      abbreviationRulesPrompt:
          abbreviationRulesPrompt ?? this.abbreviationRulesPrompt,
      transactionSystemContractPrompt:
          transactionSystemContractPrompt ?? this.transactionSystemContractPrompt,
      apiKey: apiKey ?? this.apiKey,
      assistantEnabled: assistantEnabled ?? this.assistantEnabled,
      assistantProvider: assistantProvider ?? this.assistantProvider,
      assistantModel: assistantModel ?? this.assistantModel,
      assistantEndpoint: assistantEndpoint ?? this.assistantEndpoint,
      assistantRolePrompt: assistantRolePrompt ?? this.assistantRolePrompt,
      assistantTaskPrompt: assistantTaskPrompt ?? this.assistantTaskPrompt,
      assistantConversationRulesPrompt:
          assistantConversationRulesPrompt ??
          this.assistantConversationRulesPrompt,
      assistantAbbreviationRulesPrompt:
          assistantAbbreviationRulesPrompt ??
          this.assistantAbbreviationRulesPrompt,
      assistantAdvancedReasoningPrompt:
          assistantAdvancedReasoningPrompt ??
          this.assistantAdvancedReasoningPrompt,
      assistantMasterKnowledgePrompt:
          assistantMasterKnowledgePrompt ?? this.assistantMasterKnowledgePrompt,
      assistantActionGuidePrompt:
          assistantActionGuidePrompt ?? this.assistantActionGuidePrompt,
      assistantSystemContractPrompt:
          assistantSystemContractPrompt ?? this.assistantSystemContractPrompt,
      assistantApiKey: assistantApiKey ?? this.assistantApiKey,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'provider': provider,
      'model': model,
      'endpoint': endpoint,
      'fallbackPolicy': fallbackPolicy,
      'imageStrategy': imageStrategy,
      'rolePrompt': rolePrompt,
      'taskPrompt': taskPrompt,
      'cardRulesPrompt': cardRulesPrompt,
      'conversationRulesPrompt': conversationRulesPrompt,
      'abbreviationRulesPrompt': abbreviationRulesPrompt,
      'transactionSystemContractPrompt': transactionSystemContractPrompt,
      'apiKey': apiKey,
      'assistantEnabled': assistantEnabled,
      'assistantProvider': assistantProvider,
      'assistantModel': assistantModel,
      'assistantEndpoint': assistantEndpoint,
      'assistantRolePrompt': assistantRolePrompt,
      'assistantTaskPrompt': assistantTaskPrompt,
      'assistantConversationRulesPrompt': assistantConversationRulesPrompt,
      'assistantAbbreviationRulesPrompt': assistantAbbreviationRulesPrompt,
      'assistantAdvancedReasoningPrompt': assistantAdvancedReasoningPrompt,
      'assistantMasterKnowledgePrompt': assistantMasterKnowledgePrompt,
      'assistantActionGuidePrompt': assistantActionGuidePrompt,
      'assistantSystemContractPrompt': assistantSystemContractPrompt,
      'assistantApiKey': assistantApiKey,
    };
  }

  factory AiRuntimeConfig.fromMap(Map<String, dynamic>? raw) {
    final defaults = AiRuntimeConfig.defaults();
    final data = raw ?? const <String, dynamic>{};
    return AiRuntimeConfig(
      enabled: data['enabled'] == null
          ? defaults.enabled
          : data['enabled'] == true,
      provider: data['provider']?.toString().trim().isNotEmpty == true
          ? data['provider'].toString().trim()
          : defaults.provider,
      model: data['model']?.toString().trim().isNotEmpty == true
          ? data['model'].toString().trim()
          : defaults.model,
      endpoint: data['endpoint']?.toString().trim().isNotEmpty == true
          ? data['endpoint'].toString().trim()
          : defaults.endpoint,
      fallbackPolicy:
          data['fallbackPolicy']?.toString().trim().isNotEmpty == true
          ? data['fallbackPolicy'].toString().trim()
          : defaults.fallbackPolicy,
      imageStrategy: data['imageStrategy']?.toString().trim().isNotEmpty == true
          ? data['imageStrategy'].toString().trim()
          : defaults.imageStrategy,
      rolePrompt: data['rolePrompt']?.toString().trim().isNotEmpty == true
          ? data['rolePrompt'].toString()
          : defaults.rolePrompt,
      taskPrompt: data['taskPrompt']?.toString().trim().isNotEmpty == true
          ? data['taskPrompt'].toString()
          : defaults.taskPrompt,
      cardRulesPrompt:
          data['cardRulesPrompt']?.toString().trim().isNotEmpty == true
          ? data['cardRulesPrompt'].toString()
          : defaults.cardRulesPrompt,
      conversationRulesPrompt:
          data['conversationRulesPrompt']?.toString().trim().isNotEmpty == true
          ? data['conversationRulesPrompt'].toString()
          : defaults.conversationRulesPrompt,
      abbreviationRulesPrompt:
          data['abbreviationRulesPrompt']?.toString().trim().isNotEmpty == true
          ? data['abbreviationRulesPrompt'].toString()
          : defaults.abbreviationRulesPrompt,
      transactionSystemContractPrompt:
          data['transactionSystemContractPrompt']?.toString().trim().isNotEmpty ==
              true
          ? data['transactionSystemContractPrompt'].toString()
          : defaults.transactionSystemContractPrompt,
      apiKey: data['apiKey']?.toString() ?? '',
      assistantEnabled: data['assistantEnabled'] == true,
      assistantProvider:
          data['assistantProvider']?.toString().trim().isNotEmpty == true
          ? data['assistantProvider'].toString().trim()
          : '',
      assistantModel:
          data['assistantModel']?.toString().trim().isNotEmpty == true
          ? data['assistantModel'].toString().trim()
          : '',
      assistantEndpoint:
          data['assistantEndpoint']?.toString().trim().isNotEmpty == true
          ? data['assistantEndpoint'].toString().trim()
          : '',
      assistantRolePrompt:
          data['assistantRolePrompt']?.toString().trim().isNotEmpty == true
          ? data['assistantRolePrompt'].toString()
          : defaults.assistantRolePrompt,
      assistantTaskPrompt:
          data['assistantTaskPrompt']?.toString().trim().isNotEmpty == true
          ? data['assistantTaskPrompt'].toString()
          : defaults.assistantTaskPrompt,
      assistantConversationRulesPrompt:
          data['assistantConversationRulesPrompt']?.toString().trim().isNotEmpty ==
              true
          ? data['assistantConversationRulesPrompt'].toString()
          : defaults.assistantConversationRulesPrompt,
      assistantAbbreviationRulesPrompt:
          data['assistantAbbreviationRulesPrompt']?.toString().trim().isNotEmpty ==
              true
          ? data['assistantAbbreviationRulesPrompt'].toString()
          : defaults.assistantAbbreviationRulesPrompt,
      assistantAdvancedReasoningPrompt:
          data['assistantAdvancedReasoningPrompt']?.toString().trim().isNotEmpty ==
              true
          ? data['assistantAdvancedReasoningPrompt'].toString()
          : defaults.assistantAdvancedReasoningPrompt,
      assistantMasterKnowledgePrompt:
          data['assistantMasterKnowledgePrompt']?.toString().trim().isNotEmpty ==
              true
          ? data['assistantMasterKnowledgePrompt'].toString()
          : defaults.assistantMasterKnowledgePrompt,
      assistantActionGuidePrompt:
          data['assistantActionGuidePrompt']?.toString().trim().isNotEmpty ==
              true
          ? data['assistantActionGuidePrompt'].toString()
          : defaults.assistantActionGuidePrompt,
      assistantSystemContractPrompt:
          data['assistantSystemContractPrompt']?.toString().trim().isNotEmpty ==
              true
          ? data['assistantSystemContractPrompt'].toString()
          : defaults.assistantSystemContractPrompt,
      assistantApiKey: data['assistantApiKey']?.toString() ?? '',
    );
  }

  String buildSystemPrompt({
    required List<Map<String, dynamic>> categories,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final categoryNames = categories
        .map((item) => item['name']?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final nowText = DateFormat('dd/MM/yyyy HH:mm').format(current);

    return '''
$effectivePrompt

Thông tin vận hành:
- Hôm nay là: $nowText
- Danh mục hiện có: ${categoryNames.isEmpty ? 'Chưa có danh mục nào' : categoryNames.join(', ')}
- Fallback policy: $fallbackPolicy
- Image strategy: $imageStrategy

Contract đầu ra JSON:
{
  "status": "success|clarification|error",
  "responseKind": "card_ready|clarification|natural_reply|error",
  "message": "string",
  "transactions": [
    {
      "title": "string",
      "amount": 0,
      "type": "credit|debit",
      "category": "string",
      "note": "string",
      "date": "dd/MM/yyyy",
      "time": "HH:mm",
      "dateTime": "dd/MM/yyyy HH:mm",
      "isNewCategory": false,
      "confirmCreateCategory": false,
      "suggestedIcon": "string"
    }
  ],
  "data": []
}

Quy tắc bắt buộc:
- Nếu chưa đủ dữ liệu để tạo giao dịch, đặt responseKind="clarification", transactions=[] và hỏi lại đúng phần thiếu.
- Nếu đang trả lời tự nhiên mà không tạo giao dịch, đặt responseKind="natural_reply", transactions=[].
- Chỉ đặt responseKind="card_ready" khi transaction đã đủ để app hiển thị card xác nhận.
- Không được bịa số tiền, danh mục, hoặc ngày giờ khi chưa chắc.
- Nếu có danh mục mới, đặt isNewCategory=true và confirmCreateCategory=true.
- Nếu có danh mục mới chưa tồn tại trong danh mục hiện có, message phải hỏi user có muốn tạo danh mục mới đó không.
- Nếu nội dung như ăn sáng, ăn trưa, cafe, trà sữa, đi grab, đổ xăng, gửi xe, taxi, xe ôm, điện nước, tiền nhà... có thể quy về danh mục hiện có thì phải ưu tiên quy về danh mục hiện có thay vì tạo danh mục mới.
- Phải hiểu cả câu có dấu và không dấu; ví dụ an sang, uong cf, di grab, do xang vẫn phải suy luận như câu có dấu.
- Với thời gian, phải bám theo ngữ nghĩa tiếng Việt đời thường: hôm qua và ngày cụ thể thì tự tính; còn hôm trước, hôm kia, tuần trước, tháng trước, năm ngoái thì phải hỏi lại ngày chính xác trước khi lên card.
- Với giờ, nếu không có giờ rõ ràng thì lấy giờ hiện tại. Nếu chỉ có mốc như sáng, trưa, chiều, tối, khuya thì quy về giờ mặc định tương ứng. Nếu có giờ cụ thể như 8h, 8:30, 19h15 thì phải dùng đúng giờ đó.
- data phải giống transactions.
'''
        .trim();
  }

  String buildAssistantSystemPrompt({
    required String contextSummary,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final nowText = DateFormat('dd/MM/yyyy HH:mm').format(current);
    final role = assistantRolePrompt.trim().isNotEmpty
        ? assistantRolePrompt.trim()
        : rolePrompt.trim();
    final task = assistantTaskPrompt.trim().isNotEmpty
        ? assistantTaskPrompt.trim()
        : taskPrompt.trim();
    final conversation = assistantConversationRulesPrompt.trim().isNotEmpty
        ? assistantConversationRulesPrompt.trim()
        : conversationRulesPrompt.trim();
    final abbreviation = assistantAbbreviationRulesPrompt.trim();
    final advanced = assistantAdvancedReasoningPrompt.trim();

    return '''
$role

$task

$conversation

Năng lực bắt buộc trong app này:
- Bạn phải hỗ trợ như một trợ lý rất rành toàn bộ ứng dụng, không bị giới hạn ở ngân sách hay tiết kiệm.
- Bạn phải biết hướng dẫn người dùng theo từng bước khi họ hỏi vị trí tính năng, cách thao tác, hoặc ý nghĩa của một màn hình.
- Bạn phải ưu tiên trả lời các câu hỏi kiểu: chức năng này ở đâu, bấm nút nào, vào mục nào, làm sao để thêm/sửa/xóa/xem.
- Khi không có action điều hướng phù hợp, vẫn phải chỉ đường bằng lời thật cụ thể và dễ làm theo.

Sơ đồ hiểu app cần luôn ghi nhớ:
- Trang chủ: màn tổng quan, nơi người dùng nhìn nhanh tình hình tài chính và các khối nổi bật.
- Giao dịch: nơi nhập giao dịch bằng văn bản, giọng nói, ảnh, xem bản nháp và rà soát giao dịch gần đây.
- Ngân sách: nơi theo dõi hạn mức chi theo danh mục.
- Mục tiêu tiết kiệm: nơi theo dõi mục tiêu tích lũy và tiến độ tiết kiệm.
- Báo cáo: nơi xem thống kê, biểu đồ, tổng hợp kỳ và xuất báo cáo.
- Cài đặt: nơi chỉnh giao diện, thông báo, tài khoản và đi vào quản lý danh mục.
- Quản lý danh mục: là màn con nằm trong Cài đặt, dùng để thêm, sửa, xóa danh mục tùy chỉnh; dữ liệu này liên quan tới giao dịch, ngân sách và thống kê.
- Thông báo: là màn riêng mở từ biểu tượng chuông, dùng để xem lại các thông báo và hành động liên quan.

Nguyên tắc trả lời chất lượng cao:
- Nếu user hỏi "ở đâu", phải trả lời theo đường đi cụ thể từ màn hiện tại hoặc từ tab chính.
- Nếu user hỏi "app có gì", phải liệt kê tương đối đầy đủ các khu chính, không trả lời cụt một tính năng.
- Nếu user hỏi về danh mục, phải phân biệt giữa quản lý danh mục tùy chỉnh với việc dùng danh mục trong giao dịch, ngân sách và báo cáo.
- Nếu user hỏi cách làm, nên trả lời theo từng bước ngắn gọn, có thứ tự rõ ràng.
- Nếu câu hỏi còn quá rộng, hãy hỏi lại user đúng 1 nhu cầu cụ thể để bạn hướng dẫn sâu hơn.
- Nếu user đã nói rõ một nhu cầu cụ thể, phải trả lời thành các bước đánh số 1, 2, 3...
- Nếu action chip có thể giúp user đi nhanh hơn, hãy thêm suggestion phù hợp.

${abbreviation.isNotEmpty ? '\n$abbreviation\n' : ''}

${advanced.isNotEmpty ? '\n$advanced\n' : ''}

${assistantMasterKnowledgePrompt.trim().isNotEmpty ? '\n${assistantMasterKnowledgePrompt.trim()}\n' : ''}

Ngữ cảnh ứng dụng và người dùng:
- Hôm nay là: $nowText
$contextSummary

Contract đầu ra JSON:
{
  "status": "success|clarification|error",
  "responseKind": "assistant_reply|assistant_action_suggestion|error",
  "message": "string",
  "suggestions": [
    {
      "id": "string",
      "label": "string",
      "type": "open_home|open_budget|open_savings|open_report|open_settings|open_category_management|open_notifications|open_search|open_manual_transaction|switch_to_transaction|open_add_transaction",
      "payload": "string"
    }
  ]
}

${assistantActionGuidePrompt.trim().isNotEmpty ? '\n${assistantActionGuidePrompt.trim()}\n' : ''}

Quy tắc bắt buộc:
- Không tạo transaction card trong chế độ trợ lý hỗ trợ.
- Chỉ trả lời dựa trên ngữ cảnh được cung cấp và câu hỏi của người dùng.
- Nếu dữ liệu ngữ cảnh không đủ chắc để kết luận, phải nói rõ giới hạn đó.
- Chỉ đề xuất hành động an toàn; không giả định rằng app đã tự thực thi hành động.
${assistantSystemContractPrompt.trim().isNotEmpty ? '\n${assistantSystemContractPrompt.trim()}\n' : ''}
'''
        .trim();
  }
}

class AiRuntimeConfigState {
  const AiRuntimeConfigState({
    required this.published,
    required this.publishedVersion,
    required this.draft,
    required this.draftVersion,
    required this.sourceLabel,
  });

  final AiRuntimeConfig published;
  final int publishedVersion;
  final AiRuntimeConfig draft;
  final int draftVersion;
  final String sourceLabel;
}
