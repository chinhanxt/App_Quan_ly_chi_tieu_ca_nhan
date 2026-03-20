import 'dart:async';
import 'dart:convert';

import 'package:app/services/ai_config.dart';
import 'package:app/services/ai_response_enhancement.dart';
import 'package:app/services/transaction_datetime_inference.dart';
import 'package:app/services/transaction_type_inference.dart';
import 'package:app/utils/icon_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AIService {
  final appIcons = AppIcons();
  static const int _maxOpenAIRetries = 3;

  static const Map<String, dynamic> _transactionItemSchema = <String, dynamic>{
    'type': 'object',
    'additionalProperties': false,
    'properties': <String, dynamic>{
      'title': <String, dynamic>{'type': 'string'},
      'amount': <String, dynamic>{'type': 'number'},
      'type': <String, dynamic>{
        'type': 'string',
        'enum': <String>['credit', 'debit'],
      },
      'category': <String, dynamic>{'type': 'string'},
      'note': <String, dynamic>{'type': 'string'},
      'date': <String, dynamic>{'type': 'string'},
      'time': <String, dynamic>{'type': 'string'},
      'dateTime': <String, dynamic>{'type': 'string'},
      'isNewCategory': <String, dynamic>{'type': 'boolean'},
      'suggestedIcon': <String, dynamic>{'type': 'string'},
    },
    'required': <String>[
      'title',
      'amount',
      'type',
      'category',
      'note',
      'date',
      'time',
      'dateTime',
      'isNewCategory',
      'suggestedIcon',
    ],
  };

  static const Map<String, dynamic> _responseSchema = <String, dynamic>{
    'type': 'object',
    'additionalProperties': false,
    'properties': <String, dynamic>{
      'status': <String, dynamic>{
        'type': 'string',
        'enum': <String>['success', 'error', 'clarification'],
      },
      'message': <String, dynamic>{'type': 'string'},
      'success': <String, dynamic>{'type': 'boolean'},
      'transactions': <String, dynamic>{
        'type': 'array',
        'items': _transactionItemSchema,
      },
      'data': <String, dynamic>{
        'type': 'array',
        'items': _transactionItemSchema,
      },
    },
    'required': <String>[
      'status',
      'message',
      'success',
      'transactions',
      'data',
    ],
  };

  Map<String, dynamic> _buildErrorResponse(
    String message, {
    String? errorCode,
  }) {
    return <String, dynamic>{
      'status': 'error',
      'success': false,
      'message': message,
      if (errorCode != null && errorCode.isNotEmpty) 'errorCode': errorCode,
      'transactions': const <Map<String, dynamic>>[],
      'data': const <Map<String, dynamic>>[],
    };
  }

  Future<List<String>> _getUserCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return <String>[];

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final categories = <String>[
      'Lương',
      'Mua sắm',
      'Ăn uống',
      'Di chuyển',
      'Tiết kiệm',
    ];

    if (doc.exists && (doc.data()?.containsKey('customCategories') ?? false)) {
      final customCats = List<dynamic>.from(doc['customCategories']);
      for (final cat in customCats) {
        final name = cat is Map ? cat['name']?.toString().trim() : null;
        if (name != null && name.isNotEmpty) {
          categories.add(name);
        }
      }
    }

    return categories;
  }

  String _getSystemPrompt(
    List<String> categories,
    List<Map<String, dynamic>> suggestedIcons,
  ) {
    final now = DateTime.now();
    final iconNames = suggestedIcons.map((e) => e['iconName']).toList();

    return """
Bạn là Chuyên gia Tai chinh AI. Nhiem vu: Boc tach ngon ngu doi thuong thanh du lieu giao dich JSON.
Hom nay la: ${DateFormat('dd/MM/yyyy HH:mm').format(now)}. Danh muc uu tien: ${categories.join(', ')}. Icon hop le: ${iconNames.join(', ')}.

QUY TAC:
1. Neu dau vao khong phai giao dich tai chinh ro rang, hay tra ve JSON `status:"clarification"` va `message` than thien, vui ve.
2. Neu mot cau co nhieu khoan thu/chi, hay tach thanh nhieu transaction trong mang.
3. Tien: k->1.000, cu/m->1.000.000, lit->100.000, ve->500.000.
4. Sua loi viet tat (dt->Dien thoai, shp->Shopee).
5. `type` chi duoc la `credit` hoac `debit`.
6. `credit` = tien DI VAO vi/tai khoan cua nguoi noi. Vi du:
   - "luong ve 15 trieu" -> credit
   - "duoc tang 100k" -> credit
   - "duoc cho 200k" -> credit
   - "nhan thuong 500k" -> credit
   - "hoan tien 30k" -> credit
   - "thu no 2 trieu" -> credit
7. `debit` = tien DI RA khoi vi/tai khoan cua nguoi noi. Vi du:
   - "an sang 30k" -> debit
   - "tang me 100k" -> debit
   - "tra no 1 trieu" -> debit
   - "mua ao 200k" -> debit
   - "dong tien dien 500k" -> debit
8. Dac biet quan trong:
   - "duoc tang", "duoc cho", "nhan", "luong ve", "hoan tien", "thu no" thuong la credit.
   - "mua", "an", "uong", "tra", "tang", "cho", "dong", "nap" thuong la debit.
   - "duoc tang/duoc cho" la credit, nhung "tang ai/cho ai" la debit.
   - KHONG duoc mac dinh moi giao dich la debit.
9. Ve thoi gian:
   - Neu nguoi dung noi ro ngay/gio, phai bam theo dung thong tin do.
   - Neu chi co ngay ma khong co gio, giu gio hien tai.
   - Neu chi co gio ma khong co ngay, dung ngay hom nay.
   - Neu co khung thoi gian nhu "sang/trua/chieu/toi/dem" ma khong co gio cu the, quy doi lan luot thanh 08:00 / 12:00 / 15:00 / 19:00 / 22:00.
   - KHONG duoc tu y doi thanh 00:00 neu nguoi dung khong noi nua dem.
10. Validation:
   - Neu amount am, chuyen ve so duong va suy ra `type` theo nghia thu/chi.
   - Neu chi co mot giao dich va amount > 100.000.000, giu giong dieu hai huoc va yeu cau nguoi dung xac nhan lai.
11. Neu la muc moi, tu tao danh muc, chon icon phu hop nhat, dat `isNewCategory`: true.
12. UU TIEN schema mo rong, NHUNG van giu schema cu de app tuong thich:
{"status":"success|error|clarification","message":"...","success":true|false,"transactions":[...],"data":[...]}
13. Moi transaction nen co:
{"title":...,"amount":...,"type":"credit|debit","category":...,"note":...,"date":"${DateFormat('dd/MM/yyyy').format(now)}","time":"${DateFormat('HH:mm').format(now)}","dateTime":"${DateFormat('dd/MM/yyyy HH:mm').format(now)}","isNewCategory":...,"suggestedIcon":...}
""";
  }

  Future<void> _waitBeforeRetry(int attempt) async {
    final seconds = attempt;
    await Future<void>.delayed(Duration(seconds: seconds));
  }

  int? _extractRetryAfterSeconds(String? message) {
    if (message == null || message.isEmpty) return null;
    final match = RegExp(
      r'retry in ([0-9]+(?:\.[0-9]+)?)s',
      caseSensitive: false,
    ).firstMatch(message);
    final raw = match?.group(1);
    if (raw == null) return null;
    final seconds = double.tryParse(raw);
    if (seconds == null) return null;
    return seconds.ceil();
  }

  bool _shouldRetryOpenAI({
    required int statusCode,
    String? message,
    required int attempt,
  }) {
    if (attempt >= _maxOpenAIRetries) return false;
    if (statusCode >= 500) return true;

    final lowered = message?.toLowerCase() ?? '';
    return statusCode == 429 ||
        lowered.contains('quota') ||
        lowered.contains('rate limit') ||
        lowered.contains('temporarily unavailable');
  }

  Map<String, dynamic> _mapHttpError({
    required int statusCode,
    String? message,
  }) {
    final lowered = message?.toLowerCase() ?? '';

    if (statusCode == 429 ||
        lowered.contains('quota') ||
        lowered.contains('rate limit')) {
      return _buildErrorResponse(
        'Mình đang chạm giới hạn lượt gọi AI từ OpenAI. Bạn thử lại sau ít phút nhé.',
        errorCode: 'rate_limit',
      );
    }

    if (statusCode == 400) {
      return _buildErrorResponse(
        message ??
            'Nội dung gửi lên chưa hợp lệ. Bạn thử nhập ngắn gọn hơn nhé.',
        errorCode: 'bad_request',
      );
    }

    if (statusCode == 401 || statusCode == 403) {
      return _buildErrorResponse(
        'OpenAI API key không hợp lệ hoặc đã hết quyền truy cập.',
        errorCode: 'auth',
      );
    }

    return _buildErrorResponse(
      message ??
          'AI đang gặp trục trặc khi xử lý yêu cầu. Bạn thử lại sau ít phút nhé.',
      errorCode: statusCode >= 500 ? 'server_error' : 'unknown',
    );
  }

  int? _extractSingleAmount(String input) {
    final rawMatches = RegExp(
      r'(\d[\d\.,]*)(?:\s*)(k|ngan|nghin|tr|trieu|cu|m|lit|ve)?',
      caseSensitive: false,
    ).allMatches(input);

    final amounts = <int>[];
    for (final match in rawMatches) {
      final rawNumber = match.group(1);
      if (rawNumber == null) continue;

      final unit = match.group(2)?.toLowerCase();
      var normalized = rawNumber.replaceAll('.', '').replaceAll(',', '.');
      final parsed = double.tryParse(normalized);
      if (parsed == null) continue;

      var value = parsed;
      switch (unit) {
        case 'k':
        case 'ngan':
        case 'nghin':
          value *= 1000;
          break;
        case 'tr':
        case 'trieu':
        case 'cu':
        case 'm':
          value *= 1000000;
          break;
        case 'lit':
          value *= 100000;
          break;
        case 've':
          value *= 500000;
          break;
      }

      amounts.add(value.round());
    }

    if (amounts.length != 1) return null;
    return amounts.first.abs();
  }

  String _buildFallbackTitle(String input, String category) {
    var title = input.trim();
    title = title.replaceAll(
      RegExp(
        r'\b\d[\d\.,]*(?:\s*)(k|ngan|nghin|tr|trieu|cu|m|lit|ve)?\b',
        caseSensitive: false,
      ),
      '',
    );
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (title.isEmpty) return category;
    if (title.length > 40) return title.substring(0, 40).trim();
    return title;
  }

  ({String category, String iconName, bool isNewCategory}) _resolveCategory(
    String input,
    List<String> categories,
  ) {
    final normalized = TransactionTypeInference.normalizeText(input);

    for (final category in categories) {
      final normalizedCategory = TransactionTypeInference.normalizeText(
        category,
      );
      if (normalizedCategory.isNotEmpty &&
          normalized.contains(normalizedCategory)) {
        return (
          category: category,
          iconName: 'cartShopping',
          isNewCategory: false,
        );
      }
    }

    if (normalized.contains('luong')) {
      return (
        category: 'Lương',
        iconName: 'moneyBillWave',
        isNewCategory: false,
      );
    }

    if (normalized.contains('xang') ||
        normalized.contains('grab') ||
        normalized.contains('taxi') ||
        normalized.contains('xe')) {
      return (category: 'Di chuyển', iconName: 'gasPump', isNewCategory: false);
    }

    if (normalized.contains('shopee') ||
        normalized.contains('mua') ||
        normalized.contains('quan ao')) {
      return (
        category: 'Mua sắm',
        iconName: 'cartShopping',
        isNewCategory: false,
      );
    }

    if (normalized.contains('an') ||
        normalized.contains('uong') ||
        normalized.contains('cafe') ||
        normalized.contains('ca phe')) {
      return (category: 'Ăn uống', iconName: 'utensils', isNewCategory: false);
    }

    if (normalized.contains('tiet kiem')) {
      return (
        category: 'Tiết kiệm',
        iconName: 'piggyBank',
        isNewCategory: false,
      );
    }

    return (
      category: 'Mua sắm',
      iconName: 'cartShopping',
      isNewCategory: false,
    );
  }

  Map<String, dynamic>? _buildLocalFallbackResponse({
    required String input,
    required List<String> categories,
    required String failureCode,
  }) {
    final amount = _extractSingleAmount(input);
    if (amount == null) return null;

    final inferredType = TransactionTypeInference.inferType(input: input);
    if (inferredType == null) return null;

    final resolvedCategory = _resolveCategory(input, categories);
    final now = TransactionDateTimeInference.resolveDateTime(
      input: input,
      transaction: const <String, dynamic>{},
    );
    final title = _buildFallbackTitle(input, resolvedCategory.category);
    final transaction = <String, dynamic>{
      'title': title,
      'amount': amount,
      'type': inferredType,
      'category': resolvedCategory.category,
      'note': input.trim(),
      'date': DateFormat('dd/MM/yyyy').format(now),
      'time': DateFormat('HH:mm').format(now),
      'dateTime': DateFormat('dd/MM/yyyy HH:mm').format(now),
      'isNewCategory': resolvedCategory.isNewCategory,
      'suggestedIcon': resolvedCategory.iconName,
    };

    return <String, dynamic>{
      'status': 'success',
      'success': true,
      'message': AIResponseEnhancement.fallbackMessage(
        reasonCode: failureCode,
        transactionCount: 1,
      ),
      'transactions': <Map<String, dynamic>>[transaction],
      'data': <Map<String, dynamic>>[transaction],
      'fallbackReason': failureCode,
    };
  }

  String _extractOpenAIText(Map<String, dynamic> payload) {
    final output = payload['output'];
    if (output is! List) return '';

    for (final item in output) {
      if (item is! Map) continue;
      if (item['type']?.toString() != 'message') continue;

      final content = item['content'];
      if (content is! List) continue;

      final text = content
          .whereType<Map>()
          .map((part) => part['text']?.toString() ?? '')
          .join()
          .trim();
      if (text.isNotEmpty) return text;
    }

    return '';
  }

  Future<Map<String, dynamic>> _requestOpenAI({
    required String input,
    required List<String> categories,
  }) async {
    final prompt = _getSystemPrompt(categories, appIcons.suggestedCategories);
    for (var attempt = 1; attempt <= _maxOpenAIRetries; attempt++) {
      final response = await http
          .post(
            Uri.parse(AIConfig.responsesEndpoint),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AIConfig.openAIApiKey}',
            },
            body: jsonEncode(<String, dynamic>{
              'model': AIConfig.openAIModel,
              'reasoning': <String, dynamic>{
                'effort': AIConfig.openAIReasoningEffort,
              },
              'max_output_tokens': AIConfig.openAIMaxOutputTokens,
              'input': <Map<String, dynamic>>[
                <String, dynamic>{
                  'role': 'system',
                  'content': <Map<String, dynamic>>[
                    <String, dynamic>{'type': 'input_text', 'text': prompt},
                  ],
                },
                <String, dynamic>{
                  'role': 'user',
                  'content': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'type': 'input_text',
                      'text': 'Người dùng: "$input"',
                    },
                  ],
                },
              ],
              'text': <String, dynamic>{
                'format': <String, dynamic>{
                  'type': 'json_schema',
                  'name': 'finance_transaction_response',
                  'strict': true,
                  'schema': _responseSchema,
                },
              },
            }),
          )
          .timeout(const Duration(seconds: 45));

      Map<String, dynamic>? payload;
      if (response.body.trim().isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          payload = Map<String, dynamic>.from(decoded);
        }
      }

      final errorMessage = payload?['error'] is Map
          ? (payload!['error'] as Map)['message']?.toString()
          : payload?['message']?.toString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (payload == null) {
          return _buildErrorResponse('AI trả về dữ liệu không hợp lệ.');
        }

        final text = _extractOpenAIText(payload);
        if (text.isEmpty) {
          return _buildErrorResponse('AI không phản hồi nội dung.');
        }

        final decoded = jsonDecode(text);
        if (decoded is! Map) {
          return _buildErrorResponse('AI trả về dữ liệu không hợp lệ.');
        }

        return Map<String, dynamic>.from(decoded);
      }

      if (_shouldRetryOpenAI(
        statusCode: response.statusCode,
        message: errorMessage,
        attempt: attempt,
      )) {
        final retryAfterSeconds = _extractRetryAfterSeconds(errorMessage);
        if (retryAfterSeconds != null) {
          await Future<void>.delayed(Duration(seconds: retryAfterSeconds));
        } else {
          await _waitBeforeRetry(attempt);
        }
        continue;
      }

      final mapped = _mapHttpError(
        statusCode: response.statusCode,
        message: errorMessage,
      );
      final failureCode = mapped['errorCode']?.toString() ?? 'unknown';
      return _buildLocalFallbackResponse(
            input: input,
            categories: categories,
            failureCode: failureCode,
          ) ??
          mapped;
    }

    final fallback = _buildLocalFallbackResponse(
      input: input,
      categories: categories,
      failureCode: 'rate_limit',
    );
    return fallback ??
        _buildErrorResponse(
          'Mình đang chạm giới hạn lượt gọi AI từ OpenAI. Bạn thử lại sau ít phút nhé.',
          errorCode: 'rate_limit',
        );
  }

  Future<Map<String, dynamic>> processInput(String input) async {
    try {
      final preflight = AIResponseEnhancement.preflight(input);
      if (preflight != null) {
        return preflight;
      }

      final categories = await _getUserCategories();
      final rawData = await _requestOpenAI(
        input: input,
        categories: categories,
      );
      final extracted = AIResponseEnhancement.normalizeSchema(rawData);
      final typed = TransactionTypeInference.refineResult(
        extracted,
        input: input,
      );
      final dated = TransactionDateTimeInference.refineResult(
        typed,
        input: input,
      );
      return AIResponseEnhancement.postProcess(dated, input: input);
    } on TimeoutException {
      final categories = await _getUserCategories();
      return _buildLocalFallbackResponse(
            input: input,
            categories: categories,
            failureCode: 'timeout',
          ) ??
          _buildErrorResponse(
            'AI phản hồi hơi lâu nên mình chưa xử lý xong. Bạn thử lại giúp mình nhé.',
            errorCode: 'timeout',
          );
    } on FormatException {
      return _buildErrorResponse(
        'AI trả về dữ liệu không hợp lệ.',
        errorCode: 'bad_response',
      );
    } catch (_) {
      final categories = await _getUserCategories();
      return _buildLocalFallbackResponse(
            input: input,
            categories: categories,
            failureCode: 'network',
          ) ??
          _buildErrorResponse(
            'Không kết nối được OpenAI. Bạn kiểm tra mạng rồi thử lại nhé.',
            errorCode: 'network',
          );
    }
  }
}
