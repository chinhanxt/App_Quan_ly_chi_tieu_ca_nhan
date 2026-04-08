import 'package:intl/intl.dart';

class AiRuntimeConfig {
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
      apiKey: '',
      assistantEnabled: false,
      assistantProvider: 'groq',
      assistantModel: 'llama-3.1-8b-instant',
      assistantEndpoint: defaultEndpoint,
      assistantRolePrompt:
          'Bạn là trợ lý hỗ trợ người dùng ứng dụng quản lý tài chính cá nhân bằng tiếng Việt. '
          'Bạn trả lời rõ ràng, ngắn gọn, hữu ích, thân thiện và chỉ dùng dữ liệu ngữ cảnh được cung cấp.',
      assistantTaskPrompt:
          'Bạn hỗ trợ giải thích cách dùng app, trả lời câu hỏi về thu chi tháng này, ngân sách, tiết kiệm, '
          'và đề xuất hành động điều hướng an toàn trong app. '
          'Bạn không được tạo card giao dịch trong chế độ trợ lý hỗ trợ.',
      assistantConversationRulesPrompt:
          'Chỉ trả lời trong phạm vi trợ lý hỗ trợ. '
          'Nếu người dùng muốn ghi giao dịch, hãy gợi ý chuyển sang chế độ AI thêm giao dịch thay vì tự tạo card. '
          'Bạn có thể đề xuất các hành động an toàn như mở ngân sách, mở tiết kiệm, hoặc chuyển sang AI thêm giao dịch. '
          'Không tự thực thi hành động thay người dùng.',
      assistantAbbreviationRulesPrompt:
          'Tầng 4 - Chuẩn hóa tiếng lóng, viết tắt, sai chính tả, và câu không dấu trước khi trả lời. '
          'Phải hiểu cách nói đời thường như bn, bnh, khum, hông, dc, z, dz, cf, ck, tk, ls, ns, '
          'cũng như các câu thiếu dấu hoặc gõ sai chính tả. '
          'Nếu một từ có nhiều nghĩa thì phải chọn nghĩa hợp lý nhất theo toàn câu và ngữ cảnh ứng dụng.',
      assistantAdvancedReasoningPrompt:
          'Tầng 5 - Xử lý thật thông minh và khôn khéo trong các tình huống quá nghiệp vụ hoặc quá rộng. '
          'Khi câu hỏi vượt ngoài dữ liệu đang có, phải nói rõ giới hạn, chia nhỏ vấn đề, '
          'đưa ra hướng dẫn an toàn và câu trả lời hữu ích nhất có thể thay vì trả lời vòng vo. '
          'Nếu cần, hãy đề xuất bước tiếp theo rõ ràng cho người dùng.',
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

${abbreviation.isNotEmpty ? '\n$abbreviation\n' : ''}

${advanced.isNotEmpty ? '\n$advanced\n' : ''}

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
      "type": "open_budget|open_savings|switch_to_transaction|open_add_transaction",
      "payload": "string"
    }
  ]
}

Quy tắc bắt buộc:
- Không tạo transaction card trong chế độ trợ lý hỗ trợ.
- Chỉ trả lời dựa trên ngữ cảnh được cung cấp và câu hỏi của người dùng.
- Nếu dữ liệu ngữ cảnh không đủ chắc để kết luận, phải nói rõ giới hạn đó.
- Chỉ đề xuất hành động an toàn; không giả định rằng app đã tự thực thi hành động.
- Nếu người dùng đang muốn ghi giao dịch, ưu tiên gợi ý chuyển sang AI thêm giao dịch.
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
