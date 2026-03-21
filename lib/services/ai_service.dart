import 'package:app/services/ai_response_enhancement.dart';
import 'package:app/services/transaction_amount_parser.dart';
import 'package:app/services/transaction_category_resolver.dart';
import 'package:app/services/transaction_confidence.dart';
import 'package:app/services/transaction_datetime_inference.dart';
import 'package:app/services/transaction_phrase_lexicon.dart';
import 'package:app/services/transaction_segmenter.dart';
import 'package:app/services/transaction_type_inference.dart';
import 'package:app/utils/icon_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AIService {
  final appIcons = AppIcons();

  Map<String, dynamic> _buildResponse({
    required String status,
    required String message,
    List<Map<String, dynamic>> transactions = const <Map<String, dynamic>>[],
  }) {
    return <String, dynamic>{
      'status': status,
      'success': status == 'success',
      'message': message,
      'transactions': transactions,
      'data': transactions,
      'source': 'local_parse',
    };
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

  Future<Map<String, dynamic>> processInput(String input) async {
    try {
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
}
