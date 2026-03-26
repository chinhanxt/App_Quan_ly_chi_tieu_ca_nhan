import 'package:app/services/transaction_phrase_lexicon.dart';
import 'package:app/services/transaction_type_inference.dart';

class ResolvedCategory {
  const ResolvedCategory({
    required this.category,
    required this.iconName,
    required this.isNewCategory,
    required this.isKnownCategory,
    required this.section,
  });

  final String category;
  final String iconName;
  final bool isNewCategory;
  final bool isKnownCategory;
  final String? section;
}

class TransactionCategoryResolver {
  static const Map<String, ({String category, String iconName})> _sectionMap =
      <String, ({String category, String iconName})>{
        'AN_UONG': (category: 'Ăn uống', iconName: 'utensils'),
        'DI_LAI': (category: 'Di chuyển', iconName: 'gasPump'),
        'MUA_SAM': (category: 'Mua sắm', iconName: 'cartShopping'),
        'HOA_DON': (category: 'Hóa đơn', iconName: 'bolt'),
        'GIAI_TRI': (category: 'Giải trí', iconName: 'gamepad'),
        'NHA_O': (category: 'Nhà ở', iconName: 'house'),
        'NHA_CUA': (category: 'Nhà ở', iconName: 'house'),
        'Y_TE': (category: 'Sức khỏe', iconName: 'heartPulse'),
        'HOC_TAP': (category: 'Giáo dục', iconName: 'graduationCap'),
        'TAI_CHINH': (category: 'Tài chính', iconName: 'buildingColumns'),
        'TIET_KIEM': (category: 'Tiết kiệm', iconName: 'piggyBank'),
        'KHAC': (category: 'Khác', iconName: 'ellipsis'),
      };

  static const Map<String, List<String>> _sectionHints = <String, List<String>>{
    'AN_UONG': <String>[
      'an',
      'uong',
      'an sang',
      'an trua',
      'an toi',
      'com',
      'bun',
      'pho',
      'cafe',
      'ca phe',
      'cf',
      'tra sua',
      'tra da',
      'do an',
      'do uong',
    ],
    'DI_LAI': <String>[
      'di xe',
      'xe om',
      'xe om cong nghe',
      'grab',
      'be',
      'gsm',
      'taxi',
      'bus',
      'xe buyt',
      'do xang',
      'xang',
      'gui xe',
      've xe',
      'tau xe',
      'di lai',
      'di chuyen',
      'ship xe',
      'di grab',
    ],
    'MUA_SAM': <String>[
      'mua',
      'shop',
      'order',
      'sieu thi',
      'bach hoa xanh',
      'shopee',
      'lazada',
      'tiki',
    ],
    'HOA_DON': <String>[
      'tien dien',
      'tien nuoc',
      'wifi',
      'internet',
      'hoa don',
      'tien mang',
    ],
    'NHA_O': <String>['tien nha', 'tien tro', 'thue nha', 'phong tro'],
  };

  static Future<ResolvedCategory> resolve({
    required String input,
    required String? title,
    required List<Map<String, dynamic>> availableCategories,
  }) async {
    final normalizedInput = TransactionTypeInference.normalizeText(input);
    final normalizedTitle = TransactionTypeInference.normalizeText(title ?? '');

    for (final category in availableCategories) {
      final name = category['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      final normalizedName = TransactionTypeInference.normalizeText(name);
      if (normalizedName.isEmpty) continue;

      if (_containsPhrase(normalizedInput, normalizedName) ||
          _containsPhrase(normalizedTitle, normalizedName)) {
        return ResolvedCategory(
          category: name,
          iconName: category['iconName']?.toString().trim().isNotEmpty == true
              ? category['iconName'].toString().trim()
              : 'cartShopping',
          isNewCategory: false,
          isKnownCategory: true,
          section: null,
        );
      }
    }

    final semanticSection = _inferSectionFromHints(
      '$normalizedInput $normalizedTitle',
    );
    if (semanticSection != null && _sectionMap.containsKey(semanticSection)) {
      final mapped = _sectionMap[semanticSection]!;
      final matchedExisting = _findExistingCategory(
        mapped.category,
        availableCategories,
      );
      return ResolvedCategory(
        category: matchedExisting?.$1 ?? mapped.category,
        iconName: matchedExisting?.$2 ?? mapped.iconName,
        isNewCategory: matchedExisting == null,
        isKnownCategory: matchedExisting != null,
        section: semanticSection,
      );
    }

    final lexicon = await TransactionPhraseLexicon.load();
    final section =
        lexicon.bestPrioritySection(input) ??
        lexicon.bestCategorySection(input);
    if (section != null && _sectionMap.containsKey(section)) {
      final mapped = _sectionMap[section]!;
      final matchedExisting = _findExistingCategory(
        mapped.category,
        availableCategories,
      );
      return ResolvedCategory(
        category: matchedExisting?.$1 ?? mapped.category,
        iconName: matchedExisting?.$2 ?? mapped.iconName,
        isNewCategory: matchedExisting == null,
        isKnownCategory: matchedExisting != null,
        section: section,
      );
    }

    final suggested = _buildSuggestedCategory(input, title: title);
    return ResolvedCategory(
      category: suggested,
      iconName: 'ellipsis',
      isNewCategory: true,
      isKnownCategory: false,
      section: null,
    );
  }

  static (String, String)? _findExistingCategory(
    String canonicalCategory,
    List<Map<String, dynamic>> availableCategories,
  ) {
    final normalizedCanonical = TransactionTypeInference.normalizeText(
      canonicalCategory,
    );

    for (final category in availableCategories) {
      final name = category['name']?.toString().trim() ?? '';
      if (TransactionTypeInference.normalizeText(name) != normalizedCanonical) {
        continue;
      }
      final iconName =
          category['iconName']?.toString().trim().isNotEmpty == true
          ? category['iconName'].toString().trim()
          : _sectionMap.values
                .firstWhere(
                  (item) => item.category == canonicalCategory,
                  orElse: () =>
                      (category: canonicalCategory, iconName: 'ellipsis'),
                )
                .iconName;
      return (name, iconName);
    }

    return null;
  }

  static String _buildSuggestedCategory(String input, {String? title}) {
    final normalizedInput = TransactionTypeInference.normalizeText(input);
    const specialSuggestions = <String, String>{
      'meo': 'Thú cưng',
      'hamster': 'Thú cưng',
      'cat meo': 'Thú cưng',
      'hat cho hamster': 'Thú cưng',
      'host web': 'Công nghệ',
      'domain': 'Công nghệ',
      'server': 'Công nghệ',
      'lens may anh': 'Máy ảnh',
      'guitar': 'Học nhạc',
    };
    for (final entry in specialSuggestions.entries) {
      if (_containsPhrase(normalizedInput, entry.key)) {
        return entry.value;
      }
    }

    final source = (title?.trim().isNotEmpty == true ? title!.trim() : input)
        .replaceAll(
          RegExp(
            r'\b\d[\d\.,]*(?:\s*)(k|ngan|nghin|ngàn|nghìn|tr|trieu|triệu|cu|củ|m|lit|lít|ve|xị|xi|chai)?\b',
            caseSensitive: false,
            unicode: true,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'\b(mua|an|uong|dong|tra|nap|nhan|duoc|hoan|chuyen|khoan|tien|phi|chi|thu|roi|rồi|va|và|luc|lúc|hom|hôm|nay|qua|mai|toi|tối|sang|sáng|trua|trưa|chieu|chiều|dinh|định|sap|sắp|se|sẽ|chua|chưa|cho|me|mẹ|bo|bố)\b',
            caseSensitive: false,
            unicode: true,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (source.isEmpty) {
      return 'Khác';
    }

    final words = source
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .take(2)
        .toList();
    if (words.isEmpty) return 'Khác';

    return words.map(_capitalize).join(' ');
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  static bool _containsPhrase(String text, String phrase) {
    final pattern = RegExp('(^| )${RegExp.escape(phrase)}(?= |\$)');
    return pattern.hasMatch(text);
  }

  static String? _inferSectionFromHints(String normalizedText) {
    for (final entry in _sectionHints.entries) {
      for (final hint in entry.value) {
        if (_containsPhrase(normalizedText, hint)) {
          return entry.key;
        }
      }
    }
    return null;
  }
}
