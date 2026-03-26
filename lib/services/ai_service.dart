import 'dart:io';
import 'dart:convert';

import 'package:app/models/ai_runtime_config.dart';
import 'package:app/services/ai_response_enhancement.dart';
import 'package:app/services/transaction_amount_parser.dart';
import 'package:app/services/transaction_category_resolver.dart';
import 'package:app/services/transaction_confidence.dart';
import 'package:app/services/transaction_datetime_inference.dart';
import 'package:app/services/transaction_phrase_lexicon.dart';
import 'package:app/services/transaction_segmenter.dart';
import 'package:app/services/transaction_type_inference.dart';
import 'package:app/utils/icon_list.dart';
import 'package:app/utils/ocr_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AIService {
  final appIcons = AppIcons();

  Map<String, dynamic> _buildResponse({
    required String status,
    required String message,
    List<Map<String, dynamic>> transactions = const <Map<String, dynamic>>[],
    String source = 'local_parse',
    String? responseKind,
  }) {
    return <String, dynamic>{
      'status': status,
      'success': status == 'success',
      'message': message,
      'transactions': transactions,
      'data': transactions,
      'source': source,
      ...?responseKind == null
          ? null
          : <String, dynamic>{'responseKind': responseKind},
    };
  }

  Future<AiRuntimeConfig> loadPublishedRuntimeConfig() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('system_configs')
          .doc('ai_runtime_config')
          .get();
      return AiRuntimeConfig.fromMap(snapshot.data());
    } catch (_) {
      return AiRuntimeConfig.defaults();
    }
  }

  Future<List<Map<String, dynamic>>> _getAvailableCategories() async {
    final seen = <String>{};
    final categories = <Map<String, dynamic>>[];

    void addCategory(Map<String, dynamic> item) {
      final name = item['name']?.toString().trim() ?? '';
      if (name.isEmpty) return;

      final normalized = TransactionTypeInference.normalizeText(name);
      if (!seen.add(normalized)) return;

      categories.add(<String, dynamic>{
        'name': name,
        'iconName': item['iconName']?.toString().trim().isNotEmpty == true
            ? item['iconName'].toString().trim()
            : 'cartShopping',
      });
    }

    for (final item in appIcons.defaultCategories) {
      addCategory(item);
    }

    try {
      final globalSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('createdAt')
          .get();
      for (final doc in globalSnapshot.docs) {
        addCategory(doc.data());
      }
    } catch (_) {}

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final customCategories =
            userDoc.data()?['customCategories'] as List<dynamic>? ??
            <dynamic>[];
        for (final item in customCategories) {
          if (item is Map) {
            addCategory(Map<String, dynamic>.from(item));
          }
        }
      }
    } catch (_) {}

    return categories;
  }

  Future<String?> _resolveLocalType(String input) async {
    final lexicon = await TransactionPhraseLexicon.load();
    return lexicon.inferType(input) ??
        TransactionTypeInference.inferType(input: input);
  }

  String _defaultTypeForCategory(String category) {
    final normalized = TransactionTypeInference.normalizeText(category);
    if (normalized.contains('luong') ||
        normalized.contains('thu nhap') ||
        normalized.contains('doanh thu') ||
        normalized.contains('thuong') ||
        normalized.contains('hoan tien')) {
      return 'credit';
    }
    return 'debit';
  }

  String _buildTitle(String input, String fallbackCategory) {
    var title = input.trim();
    title = title.replaceAll(
      RegExp(
        r'\b\d[\d\.,]*(?:\s*)(k|ngan|nghin|tr|trieu|cu|m|lit|ve|xị|xi)?\b',
        caseSensitive: false,
      ),
      ' ',
    );
    title = title.replaceAll(
      RegExp(
        r'\b(luc|lúc|ngay|ngày|hom|hôm|nay|qua|mai|toi|tối|sang|sáng|trua|trưa|chieu|chiều|dem|đêm|khuya|va|và|voi|với|roi|rồi|sau do|sau đó|xong|thu|thứ|tuan|tuần|thang|tháng|nam|năm|dau|đầu|cuoi|cuối)\b',
        caseSensitive: false,
        unicode: true,
      ),
      ' ',
    );
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (title.isEmpty) return fallbackCategory;

    final words = title.split(' ').where((item) => item.trim().isNotEmpty);
    final trimmed = words.take(6).join(' ').trim();
    if (trimmed.isEmpty) return fallbackCategory;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  Future<Map<String, dynamic>?> _parseSegment({
    required String segmentText,
    required String fullInput,
    required List<Map<String, dynamic>> categories,
    required bool isMultiSegment,
  }) async {
    final amounts = TransactionAmountParser.extractAmounts(segmentText);
    if (amounts.isEmpty) return null;

    final amount = amounts.last.amount;
    final provisionalTitle = _buildTitle(segmentText, 'Giao dịch');
    final resolvedCategory = await TransactionCategoryResolver.resolve(
      input: segmentText,
      title: provisionalTitle,
      availableCategories: categories,
    );

    final inferredType =
        await _resolveLocalType(segmentText) ??
        TransactionTypeInference.inferType(
          input: segmentText,
          title: provisionalTitle,
          category: resolvedCategory.category,
        ) ??
        _defaultTypeForCategory(resolvedCategory.category);

    final resolvedDateTime = TransactionDateTimeInference.resolveDateTime(
      input: fullInput,
      transaction: <String, dynamic>{'title': provisionalTitle},
    );

    final confidenceScore = TransactionConfidence.score(
      hasAmount: amount > 0,
      hasType: inferredType.isNotEmpty,
      hasCategory: resolvedCategory.category.trim().isNotEmpty,
      hasKnownCategory: resolvedCategory.isKnownCategory,
      hasTitle: provisionalTitle.trim().isNotEmpty,
      isMultiSegment: isMultiSegment,
    );

    return <String, dynamic>{
      'title': provisionalTitle,
      'amount': amount,
      'type': inferredType,
      'category': resolvedCategory.category,
      'note': segmentText.trim(),
      'date': DateFormat('dd/MM/yyyy').format(resolvedDateTime),
      'time': DateFormat('HH:mm').format(resolvedDateTime),
      'dateTime': DateFormat('dd/MM/yyyy HH:mm').format(resolvedDateTime),
      'isNewCategory': resolvedCategory.isNewCategory,
      'confirmCreateCategory': resolvedCategory.isNewCategory,
      'suggestedIcon': resolvedCategory.iconName,
      'confidence': confidenceScore,
      'confidenceLabel': TransactionConfidence.label(confidenceScore),
      'source': 'local_parse',
    };
  }

  Future<List<Map<String, dynamic>>> _parseTransactions(
    String input,
    List<Map<String, dynamic>> categories,
  ) async {
    final segments = TransactionSegmenter.split(input);
    final transactions = <Map<String, dynamic>>[];

    for (final segment in segments) {
      final parsed = await _parseSegment(
        segmentText: segment.text,
        fullInput: input,
        categories: categories,
        isMultiSegment: segments.length > 1,
      );
      if (parsed != null) {
        transactions.add(parsed);
      }
    }

    return transactions;
  }

  Future<Map<String, dynamic>> _processLocalInput(String input) async {
    try {
      if (TransactionDateTimeInference.requiresExactDateClarification(input)) {
        return _buildResponse(
          status: 'clarification',
          message: AIResponseEnhancement.exactDateClarificationMessage(),
        );
      }

      final lexicon = await TransactionPhraseLexicon.load();
      if (lexicon.hasFutureIntent(input)) {
        return _buildResponse(
          status: 'clarification',
          message:
              'Nghe như bạn đang nói tới một khoản sắp phát sinh đó nha. Khi nào giao dịch xảy ra thật thì nhắn mình ghi sổ liền nhé!',
        );
      }
      if (lexicon.hasPendingDebtIntent(input) || lexicon.hasNegation(input)) {
        return _buildResponse(
          status: 'clarification',
          message:
              'Khoản này nghe giống chưa phát sinh hẳn hoặc cần nói rõ thêm, nên mình chưa tạo giao dịch vội đâu. Bạn xác nhận lại giúp mình nhé!',
        );
      }

      final preflight = AIResponseEnhancement.preflight(input);
      if (preflight != null) {
        return <String, dynamic>{...preflight, 'source': 'local_parse'};
      }

      final categories = await _getAvailableCategories();
      final transactions = await _parseTransactions(input, categories);
      final typed = TransactionTypeInference.refineResult(
        _buildResponse(
          status: transactions.isEmpty ? 'clarification' : 'success',
          message: transactions.isEmpty
              ? 'Mình chưa tách được giao dịch nào đủ rõ. Bạn thử nói rõ hơn một chút nhé!'
              : AIResponseEnhancement.successMessage(transactions.length),
          transactions: transactions,
        ),
        input: input,
      );
      final dated = TransactionDateTimeInference.refineResult(
        typed,
        input: input,
      );
      final result = AIResponseEnhancement.postProcess(dated, input: input);

      if ((result['transactions'] as List?)?.isEmpty ?? true) {
        if (result['status'] == 'clarification' &&
            (result['message']?.toString().trim().isNotEmpty ?? false)) {
          return <String, dynamic>{...result, 'source': 'local_parse'};
        }
        return _buildResponse(
          status: 'clarification',
          message: AIResponseEnhancement.missingAllInfoMessage(),
        );
      }

      return <String, dynamic>{...result, 'source': 'local_parse'};
    } catch (_) {
      return _buildResponse(
        status: 'error',
        message:
            'Mình đang bị khựng một nhịp khi phân tích giao dịch. Bạn thử lại giúp mình nhé!',
      );
    }
  }

  String _buildRemoteUserInput(String input, {String? ocrSummary}) {
    final buffer = StringBuffer()..writeln('Người dùng nói: "$input"');
    if (ocrSummary != null && ocrSummary.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Ngữ cảnh OCR từ ảnh:')
        ..writeln(ocrSummary.trim());
    }
    return buffer.toString().trim();
  }

  String _buildOcrSummary(Map<String, String> ocrResult) {
    final lines = <String>[];
    final rawText = ocrResult['ocrText']?.trim() ?? '';
    if (rawText.isNotEmpty) {
      lines
        ..add('Van ban OCR day du:')
        ..add(rawText);
    }

    for (final entry in ocrResult.entries) {
      if (entry.key == 'ocrText') continue;
      final value = entry.value.trim();
      if (value.isEmpty) continue;
      lines.add('- ${entry.key}: $value');
    }
    return lines.join('\n');
  }

  String _resolveResponsesEndpoint(String endpoint) {
    final trimmed = endpoint.trim();
    if (trimmed.endsWith('/responses')) {
      return trimmed;
    }
    if (trimmed.endsWith('/chat/completions')) {
      return trimmed.replaceFirst('/chat/completions', '/responses');
    }
    if (trimmed.endsWith('/')) {
      return '${trimmed}responses';
    }
    return '$trimmed/responses';
  }

  String _mimeTypeForImagePath(String imagePath) {
    final lower = imagePath.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  String _extractMessageContent(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final choices = payload['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;
        if (first is Map<String, dynamic>) {
          final message = first['message'];
          if (message is Map<String, dynamic>) {
            final content = message['content'];
            if (content is String) {
              return content.trim();
            }
            if (content is List) {
              final text = content
                  .whereType<Map>()
                  .map((item) => item['text']?.toString() ?? '')
                  .join()
                  .trim();
              if (text.isNotEmpty) return text;
            }
          }
        }
      }
    }
    return '';
  }

  Map<String, dynamic> _extractJsonPayload(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('AI không trả về nội dung JSON.');
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start != -1 && end > start) {
      final slice = trimmed.substring(start, end + 1);
      final decoded = jsonDecode(slice);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }

    throw const FormatException(
      'AI trả về nội dung không parse được thành JSON.',
    );
  }

  String _extractResponsesOutputText(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final outputText = payload['output_text']?.toString().trim();
      if (outputText != null && outputText.isNotEmpty) {
        return outputText;
      }

      final output = payload['output'];
      if (output is List) {
        final buffer = StringBuffer();
        for (final item in output.whereType<Map>()) {
          final content = item['content'];
          if (content is List) {
            for (final part in content.whereType<Map>()) {
              final text = part['text']?.toString();
              if (text != null && text.trim().isNotEmpty) {
                buffer.write(text);
              }
            }
          }
        }
        final aggregated = buffer.toString().trim();
        if (aggregated.isNotEmpty) {
          return aggregated;
        }
      }
    }
    return '';
  }

  Map<String, dynamic>? _findCategoryByName(
    String category,
    List<Map<String, dynamic>> categories,
  ) {
    final normalized = TransactionTypeInference.normalizeText(category);
    for (final item in categories) {
      final name = item['name']?.toString().trim() ?? '';
      if (TransactionTypeInference.normalizeText(name) == normalized) {
        return item;
      }
    }
    return null;
  }

  Set<String> _meaningfulTokens(String value) {
    const stopWords = <String>{
      'an',
      'uong',
      'mua',
      'tra',
      'chi',
      'thu',
      'tien',
      'phi',
      'va',
      'voi',
      'cho',
      'di',
      've',
      'roi',
      'them',
      'mot',
      'cai',
      'o',
      'tu',
      'den',
      'qua',
      'nay',
    };

    return TransactionTypeInference.normalizeText(value)
        .split(' ')
        .where((token) => token.isNotEmpty && !stopWords.contains(token))
        .toSet();
  }

  Map<String, dynamic>? _findClosestExistingCategory(
    String rawText,
    List<Map<String, dynamic>> categories,
  ) {
    final text = TransactionTypeInference.normalizeText(rawText);
    if (text.isEmpty) return null;

    final textTokens = _meaningfulTokens(text);
    Map<String, dynamic>? bestMatch;
    var bestScore = 0;

    for (final item in categories) {
      final name = item['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;

      final normalizedName = TransactionTypeInference.normalizeText(name);
      if (normalizedName.isEmpty) continue;

      var score = 0;
      if (text.contains(normalizedName) || normalizedName.contains(text)) {
        score += 6;
      }

      final categoryTokens = _meaningfulTokens(normalizedName);
      final overlap = textTokens.intersection(categoryTokens).length;
      score += overlap * 3;

      if (normalizedName.split(' ').length == 1 &&
          textTokens.contains(normalizedName)) {
        score += 4;
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = item;
      }
    }

    return bestScore >= 4 ? bestMatch : null;
  }

  Future<(String, String?, Map<String, dynamic>?)>
  _resolveBestCategoryCandidate({
    required Map<String, dynamic> tx,
    required List<Map<String, dynamic>> categories,
  }) async {
    final rawCategory = tx['category']?.toString().trim().isNotEmpty == true
        ? tx['category'].toString().trim()
        : 'Khác';
    final title = tx['title']?.toString().trim() ?? '';
    final note = tx['note']?.toString().trim() ?? '';

    var matchedCategory = _findCategoryByName(rawCategory, categories);
    var resolvedCategoryName = rawCategory;
    var resolvedIconName = tx['suggestedIcon']?.toString().trim();

    if (matchedCategory != null) {
      return (resolvedCategoryName, resolvedIconName, matchedCategory);
    }

    final resolverInput = <String>[
      title,
      note,
      rawCategory,
    ].where((item) => item.isNotEmpty).join(' ');
    if (resolverInput.isNotEmpty) {
      final resolved = await TransactionCategoryResolver.resolve(
        input: resolverInput,
        title: title,
        availableCategories: categories,
      );
      resolvedCategoryName = resolved.category;
      resolvedIconName = resolved.iconName;
      matchedCategory = _findCategoryByName(resolved.category, categories);
      if (matchedCategory != null) {
        return (resolved.category, resolved.iconName, matchedCategory);
      }
    }

    final closest = _findClosestExistingCategory(
      <String>[
        rawCategory,
        title,
        note,
      ].where((item) => item.isNotEmpty).join(' '),
      categories,
    );
    if (closest != null) {
      return (
        closest['name']?.toString() ?? rawCategory,
        closest['iconName']?.toString(),
        closest,
      );
    }

    return (resolvedCategoryName, resolvedIconName, matchedCategory);
  }

  int _normalizeAmount(dynamic raw) {
    if (raw is num) return raw.abs().round();
    final parsed = int.tryParse(raw?.toString() ?? '');
    return parsed?.abs() ?? 0;
  }

  bool _looksLikeGeneralFinanceQuestion(String input) {
    final normalized = TransactionTypeInference.normalizeText(input);
    if (normalized.isEmpty) return false;

    const questionHints = <String>[
      '?',
      'danh muc nao',
      'nen cho vao',
      'phan loai',
      'xep vao',
      'co nen',
      'la gi',
      'nghia la gi',
      'giai thich',
      'tu van',
    ];

    return questionHints.any((hint) => normalized.contains(hint));
  }

  String _ensureNewCategoryPrompt(
    String message,
    List<Map<String, dynamic>> transactions,
  ) {
    final newCategories = transactions
        .where((tx) => tx['isNewCategory'] == true)
        .map((tx) => tx['category']?.toString().trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (newCategories.isEmpty) return message;

    final normalizedMessage = TransactionTypeInference.normalizeText(message);
    final alreadyAsking =
        normalizedMessage.contains('tao danh muc') ||
        normalizedMessage.contains('danh muc moi') ||
        normalizedMessage.contains('muon tao');

    if (alreadyAsking) return message;

    final categoryList = newCategories.join(', ');
    final suffix = newCategories.length == 1
        ? ' Mình chưa thấy danh mục "$categoryList" trong tài khoản. Bạn có muốn tạo danh mục mới này không?'
        : ' Mình chưa thấy các danh mục $categoryList trong tài khoản. Bạn có muốn tạo các danh mục mới này không?';

    final trimmed = message.trim();
    if (trimmed.isEmpty) return suffix.trim();
    return '$trimmed$suffix';
  }

  Future<List<Map<String, dynamic>>> _normalizeRemoteTransactions(
    dynamic rawTransactions,
    List<Map<String, dynamic>> categories,
    String input,
  ) async {
    if (rawTransactions is! List) return const <Map<String, dynamic>>[];
    final now = DateTime.now();
    final normalized = <Map<String, dynamic>>[];
    for (final item in rawTransactions.whereType<Map>()) {
      final tx = Map<String, dynamic>.from(item);
      final resolvedCandidate = await _resolveBestCategoryCandidate(
        tx: tx,
        categories: categories,
      );
      final resolvedCategoryName = resolvedCandidate.$1;
      final resolvedIconName = resolvedCandidate.$2;
      final matchedCategory = resolvedCandidate.$3;

      final isNewCategory = matchedCategory == null;
      final type = tx['type']?.toString() == 'credit' ? 'credit' : 'debit';
      final amount = _normalizeAmount(tx['amount']);
      final dateText = tx['date']?.toString().trim();
      final timeText = tx['time']?.toString().trim();
      final dateTimeText = tx['dateTime']?.toString().trim();
      final defaultDate = DateFormat('dd/MM/yyyy').format(now);
      final defaultTime = DateFormat('HH:mm').format(now);
      final resolvedDate = dateText != null && dateText.isNotEmpty
          ? dateText
          : (dateTimeText != null && dateTimeText.length >= 10
                ? dateTimeText.substring(0, 10)
                : defaultDate);
      final resolvedTime = timeText != null && timeText.isNotEmpty
          ? timeText
          : (dateTimeText != null && dateTimeText.length >= 16
                ? dateTimeText.substring(11, 16)
                : defaultTime);
      final resolvedDateTime = dateTimeText != null && dateTimeText.isNotEmpty
          ? dateTimeText
          : '$resolvedDate $resolvedTime';
      final normalizedTx = <String, dynamic>{
        'title': tx['title']?.toString().trim().isNotEmpty == true
            ? tx['title'].toString().trim()
            : resolvedCategoryName,
        'amount': amount,
        'type': type,
        'category': resolvedCategoryName,
        'note': tx['note']?.toString().trim() ?? '',
        'date': resolvedDate,
        'time': resolvedTime,
        'dateTime': resolvedDateTime,
        'isNewCategory': isNewCategory,
        'confirmCreateCategory': isNewCategory,
        'suggestedIcon': resolvedIconName?.isNotEmpty == true
            ? resolvedIconName
            : matchedCategory?['iconName']?.toString() ??
                  (type == 'credit' ? 'moneyBillWave' : 'cartShopping'),
        'fallbackCategory':
            matchedCategory?['name']?.toString() ?? resolvedCategoryName,
        'fallbackIconName':
            matchedCategory?['iconName']?.toString() ??
            (type == 'credit' ? 'moneyBillWave' : 'cartShopping'),
        'source': 'remote_ai',
      };
      final dateRefined = TransactionDateTimeInference.refineTransaction(
        input: input,
        transaction: normalizedTx,
      );
      if ((dateRefined['amount'] as int) > 0) {
        normalized.add(dateRefined);
      }
    }
    return normalized;
  }

  Future<Map<String, dynamic>> _callRemoteAi({
    required String input,
    required AiRuntimeConfig runtimeConfig,
    String? ocrSummary,
  }) async {
    final categories = await _getAvailableCategories();
    final prompt = runtimeConfig.buildSystemPrompt(categories: categories);
    final payload = <String, dynamic>{
      'model': runtimeConfig.model,
      'messages': <Map<String, String>>[
        <String, String>{'role': 'system', 'content': prompt},
        <String, String>{
          'role': 'user',
          'content': _buildRemoteUserInput(input, ocrSummary: ocrSummary),
        },
      ],
      'temperature': 0.2,
      'response_format': <String, dynamic>{'type': 'json_object'},
    };

    final response = await http.post(
      Uri.parse(runtimeConfig.endpoint),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${runtimeConfig.apiKey}',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final rawResponse = jsonDecode(response.body);
    final content = _extractMessageContent(rawResponse);
    final decoded = _extractJsonPayload(content);
    final responseKind = decoded['responseKind']?.toString().trim();
    final transactions = await _normalizeRemoteTransactions(
      decoded['transactions'] ?? decoded['data'],
      categories,
      input,
    );

    if (responseKind == 'natural_reply') {
      return _buildResponse(
        status: 'success',
        responseKind: 'natural_reply',
        message: decoded['message']?.toString().trim().isNotEmpty == true
            ? decoded['message'].toString()
            : 'Mình đang nghe bạn đây. Bạn nói tiếp chi tiết hơn để mình hỗ trợ chuẩn hơn nhé!',
        transactions: const <Map<String, dynamic>>[],
        source: 'remote_ai',
      );
    }

    if (transactions.isEmpty) {
      return _buildResponse(
        status: decoded['status']?.toString() == 'error'
            ? 'error'
            : 'clarification',
        responseKind: responseKind == 'error' ? 'error' : 'clarification',
        message: decoded['message']?.toString().trim().isNotEmpty == true
            ? decoded['message'].toString()
            : AIResponseEnhancement.defaultClarificationMessage(),
        transactions: const <Map<String, dynamic>>[],
        source: 'remote_ai',
      );
    }

    return _buildResponse(
      status: 'success',
      responseKind: 'card_ready',
      message: _ensureNewCategoryPrompt(
        decoded['message']?.toString().trim().isNotEmpty == true
            ? decoded['message'].toString()
            : AIResponseEnhancement.successMessage(transactions.length),
        transactions,
      ),
      transactions: transactions,
      source: 'remote_ai',
    );
  }

  Future<Map<String, dynamic>> _callRemoteVisionAi({
    required String imagePath,
    required AiRuntimeConfig runtimeConfig,
  }) async {
    final categories = await _getAvailableCategories();
    final prompt = runtimeConfig.buildSystemPrompt(categories: categories);
    final imageBytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(imageBytes);
    final imageUrl =
        'data:${_mimeTypeForImagePath(imagePath)};base64,$base64Image';

    final payload = <String, dynamic>{
      'model': runtimeConfig.model,
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
              'text':
                  'Phân tích trực tiếp ảnh giao dịch này. Hãy ưu tiên đọc ảnh trước OCR. Nếu đủ dữ kiện thì trả card JSON ngay, nếu thiếu thì hỏi lại đúng phần thiếu.',
            },
            <String, dynamic>{
              'type': 'input_image',
              'detail': 'auto',
              'image_url': imageUrl,
            },
          ],
        },
      ],
    };

    final response = await http.post(
      Uri.parse(_resolveResponsesEndpoint(runtimeConfig.endpoint)),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${runtimeConfig.apiKey}',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final rawResponse = jsonDecode(response.body);
    final content = _extractResponsesOutputText(rawResponse);
    final decoded = _extractJsonPayload(content);
    final transactions = await _normalizeRemoteTransactions(
      decoded['transactions'] ?? decoded['data'],
      categories,
      'Phan tich anh truc tiep',
    );
    final responseKind = decoded['responseKind']?.toString().trim();

    if (responseKind == 'natural_reply') {
      return _buildResponse(
        status: 'success',
        responseKind: 'natural_reply',
        message: decoded['message']?.toString().trim().isNotEmpty == true
            ? decoded['message'].toString()
            : 'Mình đã đọc ảnh nhưng đây có vẻ chưa phải giao dịch rõ để lên card ngay.',
        transactions: const <Map<String, dynamic>>[],
        source: 'remote_ai_vision',
      );
    }

    if (transactions.isEmpty) {
      return _buildResponse(
        status: decoded['status']?.toString() == 'error'
            ? 'error'
            : 'clarification',
        responseKind: responseKind == 'error' ? 'error' : 'clarification',
        message: decoded['message']?.toString().trim().isNotEmpty == true
            ? decoded['message'].toString()
            : AIResponseEnhancement.defaultClarificationMessage(),
        transactions: const <Map<String, dynamic>>[],
        source: 'remote_ai_vision',
      );
    }

    return _buildResponse(
      status: 'success',
      responseKind: 'card_ready',
      message: _ensureNewCategoryPrompt(
        decoded['message']?.toString().trim().isNotEmpty == true
            ? decoded['message'].toString()
            : AIResponseEnhancement.successMessage(transactions.length),
        transactions,
      ),
      transactions: transactions,
      source: 'remote_ai_vision',
    );
  }

  Future<Map<String, dynamic>> _processRemoteInput(
    String input,
    AiRuntimeConfig runtimeConfig, {
    String? ocrSummary,
  }) async {
    try {
      if (TransactionDateTimeInference.requiresExactDateClarification(input)) {
        return _buildResponse(
          status: 'clarification',
          responseKind: 'clarification',
          message: AIResponseEnhancement.exactDateClarificationMessage(),
          source: 'remote_ai',
        );
      }

      final result = await _callRemoteAi(
        input: input,
        runtimeConfig: runtimeConfig,
        ocrSummary: ocrSummary,
      );
      final transactions =
          (result['transactions'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map>()
              .toList(growable: false);
      if (transactions.isEmpty && result['responseKind'] != 'natural_reply') {
        final recovered = await _processLocalInput(input);
        final recoveredTransactions =
            (recovered['transactions'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<Map>()
                .toList(growable: false);
        if (recoveredTransactions.isNotEmpty) {
          return <String, dynamic>{
            ...recovered,
            'message':
                recovered['message']?.toString().trim().isNotEmpty == true
                ? recovered['message']
                : result['message'],
            'source': 'remote_ai_recovered',
          };
        }
      }
      if (transactions.isEmpty &&
          result['responseKind'] != 'natural_reply' &&
          _looksLikeGeneralFinanceQuestion(input)) {
        return _buildResponse(
          status: 'success',
          responseKind: 'natural_reply',
          message: result['message']?.toString().trim().isNotEmpty == true
              ? result['message'].toString()
              : 'Mình nghiêng về trả lời tư vấn hơn là tạo giao dịch cho câu này. Bạn nói thêm nếu muốn mình lên card nhé!',
          source: 'remote_ai',
        );
      }
      return result;
    } catch (_) {
      if (runtimeConfig.fallbackPolicy == 'local_parse') {
        return _processLocalInput(input);
      }
      return _buildResponse(
        status: 'error',
        responseKind: 'error',
        message:
            'Mình chưa kết nối được AI thật lúc này. Bạn thử lại sau hoặc tạm chuyển về parse thường nhé!',
        source: 'remote_ai',
      );
    }
  }

  Future<Map<String, dynamic>> processInput(
    String input, {
    AiRuntimeConfig? runtimeOverride,
  }) async {
    final runtimeConfig = runtimeOverride ?? await loadPublishedRuntimeConfig();
    if (runtimeConfig.canUseRemoteAi) {
      if (AIResponseEnhancement.shouldUseLocalFastPath(input)) {
        final localFastPath = await _processLocalInput(input);
        final localTransactions =
            (localFastPath['transactions'] as List<dynamic>? ??
                    const <dynamic>[])
                .whereType<Map>()
                .toList(growable: false);
        if (localTransactions.isNotEmpty &&
            localFastPath['status']?.toString() == 'success') {
          return <String, dynamic>{
            ...localFastPath,
            'source': 'local_fast_path',
          };
        }
      }
      return _processRemoteInput(input, runtimeConfig);
    }
    return _processLocalInput(input);
  }

  Future<Map<String, dynamic>> processImageOcrInput(
    Map<String, String> ocrResult, {
    AiRuntimeConfig? runtimeOverride,
  }) async {
    final runtimeConfig = runtimeOverride ?? await loadPublishedRuntimeConfig();
    if (!runtimeConfig.canUseRemoteAi) {
      return _buildResponse(
        status: 'clarification',
        responseKind: 'clarification',
        message:
            'AI thật hiện chưa sẵn sàng cho ảnh. Bạn bật AI thật và thêm cấu hình đầy đủ rồi thử lại nhé!',
        source: 'remote_ai',
      );
    }

    final ocrSummary = _buildOcrSummary(ocrResult);
    final hint = <String>[
      'Đây là dữ liệu OCR từ ảnh giao dịch hoặc hóa đơn.',
      'Bạn phải đọc cả văn bản OCR đầy đủ trước, sau đó mới tham chiếu các field đã bóc tách sơ bộ.',
      'Nếu OCR cho thấy đủ số tiền, nội dung, ngày hoặc ngữ cảnh danh mục thì hãy lên card luôn.',
      'Hãy chỉ tạo card nếu dữ liệu đủ chắc chắn.',
      if (ocrSummary.isNotEmpty) ocrSummary,
    ].join('\n');

    return _processRemoteInput(hint, runtimeConfig, ocrSummary: ocrSummary);
  }

  Future<Map<String, dynamic>> processImageFileInput(
    String imagePath, {
    AiRuntimeConfig? runtimeOverride,
  }) async {
    final runtimeConfig = runtimeOverride ?? await loadPublishedRuntimeConfig();
    if (!runtimeConfig.canUseRemoteAi) {
      return _buildResponse(
        status: 'clarification',
        responseKind: 'clarification',
        message:
            'AI thật hiện chưa sẵn sàng cho ảnh. Bạn bật AI thật và thêm cấu hình đầy đủ rồi thử lại nhé!',
        source: 'remote_ai',
      );
    }

    if (runtimeConfig.imageStrategy == 'ocr_only') {
      final ocrResult = await OcrHelper.scanImageFile(imagePath);
      return processImageOcrInput(ocrResult, runtimeOverride: runtimeConfig);
    }

    try {
      final visionResult = await _callRemoteVisionAi(
        imagePath: imagePath,
        runtimeConfig: runtimeConfig,
      );
      final transactions =
          (visionResult['transactions'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map>()
              .toList(growable: false);
      if (transactions.isNotEmpty) {
        return visionResult;
      }
    } catch (_) {}

    final ocrResult = await OcrHelper.scanImageFile(imagePath);
    return processImageOcrInput(ocrResult, runtimeOverride: runtimeConfig);
  }
}
