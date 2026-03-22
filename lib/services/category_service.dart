import 'dart:async';

import 'package:app/utils/icon_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CategoryOption {
  const CategoryOption({
    required this.name,
    required this.type,
    required this.iconName,
  });

  final String name;
  final String type;
  final String iconName;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'type': type,
      'iconName': iconName,
    };
  }
}

class CategoryService {
  CategoryService({
    FirebaseFirestore? firestore,
    AppIcons? icons,
  }) : _firestore = firestore,
       _icons = icons ?? AppIcons();

  final FirebaseFirestore? _firestore;
  final AppIcons _icons;

  static final ValueNotifier<int> refreshSignal = ValueNotifier<int>(0);

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  void notifyChanged() {
    refreshSignal.value++;
  }

  Future<void> addCustomCategory({
    required String userId,
    required String name,
    required String iconName,
    required String type,
  }) async {
    final option = _normalizeCategory(
      name: name,
      type: type,
      iconName: iconName,
    );
    if (option == null) return;

    final userRef = firestore.collection('users').doc(userId);
    await userRef.collection('categories').doc(_categoryDocId(option)).set(
      <String, dynamic>{
        ...option.toMap(),
        'isDefault': false,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      SetOptions(merge: true),
    );

    notifyChanged();
  }

  Future<void> updateCustomCategory({
    required String userId,
    required CategoryOption oldCategory,
    required String newName,
    required String newIconName,
    required String newType,
  }) async {
    final updated = _normalizeCategory(
      name: newName,
      type: newType,
      iconName: newIconName,
    );
    if (updated == null) return;

    final collection = firestore.collection('users').doc(userId).collection('categories');
    final oldDocId = _categoryDocId(oldCategory);
    final newDocId = _categoryDocId(updated);

    if (oldDocId == newDocId) {
      await collection.doc(newDocId).set(
        <String, dynamic>{
          ...updated.toMap(),
          'isDefault': false,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        SetOptions(merge: true),
      );
    } else {
      final batch = firestore.batch();
      batch.delete(collection.doc(oldDocId));
      batch.set(
        collection.doc(newDocId),
        <String, dynamic>{
          ...updated.toMap(),
          'isDefault': false,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        SetOptions(merge: true),
      );
      await batch.commit();
    }

    notifyChanged();
  }

  Future<void> deleteCustomCategory({
    required String userId,
    required String name,
    required String type,
  }) async {
    final option = _normalizeCategory(name: name, type: type, iconName: '');
    if (option == null) return;

    await firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(_categoryDocId(option))
        .delete();

    notifyChanged();
  }

  Stream<List<CategoryOption>> getCategoriesStream({
    required String? userId,
    String? transactionType,
  }) {
    if (userId == null || userId.trim().isEmpty) {
      return Stream<List<CategoryOption>>.value(
        _fallbackDefaults(transactionType: transactionType),
      );
    }

    final controller = StreamController<List<CategoryOption>>.broadcast();
    final userRef = firestore.collection('users').doc(userId);

    List<CategoryOption> userCategories = <CategoryOption>[];
    List<CategoryOption> legacyCategories = <CategoryOption>[];

    void emit() {
      if (controller.isClosed) return;
      final merged = _mergeCategories(
        globalCategories: _fallbackDefaults(transactionType: transactionType),
        userCategories: userCategories,
        legacyCategories: legacyCategories,
        transactionType: transactionType,
      );
      controller.add(merged);
    }

    final userSub = userRef.collection('categories').snapshots().listen(
      (snapshot) {
        userCategories = _queryToOptions(snapshot);
        emit();
      },
      onError: (_) {
        userCategories = <CategoryOption>[];
        emit();
      },
    );

    userRef.get(const GetOptions(source: Source.serverAndCache)).then((snapshot) {
      legacyCategories = _legacyCategoriesFromSnapshot(snapshot);
      emit();
    }).catchError((_) {
      legacyCategories = <CategoryOption>[];
      emit();
    });

    controller.onListen = emit;

    controller.onCancel = () async {
      await userSub.cancel();
    };

    return controller.stream;
  }

  Stream<List<CategoryOption>> getUserCategoriesStream({
    required String? userId,
    String? transactionType,
  }) {
    if (userId == null || userId.trim().isEmpty) {
      return Stream<List<CategoryOption>>.value(const <CategoryOption>[]);
    }

    return firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .snapshots()
        .map((snapshot) {
          return _queryToOptions(
            snapshot,
            transactionType: transactionType,
          );
        });
  }

  Future<List<CategoryOption>> loadAvailableCategories({
    required String? userId,
    String? transactionType,
  }) async {
    final userCategoriesFuture = userId == null || userId.trim().isEmpty
        ? Future<QuerySnapshot<Map<String, dynamic>>?>.value(null)
        : firestore
            .collection('users')
            .doc(userId)
            .collection('categories')
            .get(const GetOptions(source: Source.serverAndCache));
    final userDocFuture = userId == null || userId.trim().isEmpty
        ? Future<DocumentSnapshot<Map<String, dynamic>>?>.value(null)
        : firestore
            .collection('users')
            .doc(userId)
            .get(const GetOptions(source: Source.serverAndCache));

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        userCategoriesFuture,
        userDocFuture,
      ]);
      final userCategoriesSnapshot =
          results[0] as QuerySnapshot<Map<String, dynamic>>?;
      final userDocSnapshot = results[1] as DocumentSnapshot<Map<String, dynamic>>?;

      return _mergeCategories(
        globalCategories: _fallbackDefaults(transactionType: transactionType),
        userCategories: userCategoriesSnapshot == null
            ? const <CategoryOption>[]
            : _queryToOptions(
                userCategoriesSnapshot,
                transactionType: transactionType,
              ),
        legacyCategories: userDocSnapshot == null
            ? const <CategoryOption>[]
            : _legacyCategoriesFromSnapshot(
                userDocSnapshot,
                transactionType: transactionType,
              ),
        transactionType: transactionType,
      );
    } catch (_) {
      return _fallbackDefaults(transactionType: transactionType);
    }
  }

  List<CategoryOption> _queryToOptions(
    QuerySnapshot<Map<String, dynamic>> snapshot, {
    String? transactionType,
  }) {
    return snapshot.docs
        .map((doc) => _fromMap(doc.data(), fallbackType: transactionType))
        .whereType<CategoryOption>()
        .where(
          (item) => transactionType == null || item.type == transactionType,
        )
        .toList(growable: false);
  }

  List<CategoryOption> _legacyCategoriesFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    String? transactionType,
  }) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final customCategories =
        data['customCategories'] as List<dynamic>? ?? const <dynamic>[];

    return customCategories
        .whereType<Map>()
        .map(
          (item) => _fromMap(
            Map<String, dynamic>.from(item),
            fallbackType: transactionType,
          ),
        )
        .whereType<CategoryOption>()
        .where(
          (item) => transactionType == null || item.type == transactionType,
        )
        .toList(growable: false);
  }

  List<CategoryOption> _mergeCategories({
    required List<CategoryOption> globalCategories,
    required List<CategoryOption> userCategories,
    required List<CategoryOption> legacyCategories,
    String? transactionType,
  }) {
    final merged = <CategoryOption>[];
    final seen = <String>{};

    void addAll(List<CategoryOption> items) {
      for (final item in items) {
        if (transactionType != null && item.type != transactionType) {
          continue;
        }
        final key = '${item.type.toLowerCase()}:${item.name.toLowerCase()}';
        if (!seen.add(key)) continue;
        merged.add(item);
      }
    }

    addAll(globalCategories);
    addAll(userCategories);
    addAll(legacyCategories);

    if (merged.isEmpty) {
      return _fallbackDefaults(transactionType: transactionType);
    }

    return merged;
  }

  List<CategoryOption> _fallbackDefaults({String? transactionType}) {
    return _icons.defaultCategories
        .map(
          (item) => _normalizeCategory(
            name: item['name']?.toString() ?? '',
            type: item['name'] == 'Lương' ? 'credit' : 'debit',
            iconName: item['iconName']?.toString() ?? 'cartShopping',
          ),
        )
        .whereType<CategoryOption>()
        .where(
          (item) => transactionType == null || item.type == transactionType,
        )
        .toList(growable: false);
  }

  CategoryOption? _fromMap(
    Map<String, dynamic>? data, {
    String? fallbackType,
  }) {
    if (data == null) return null;
    return _normalizeCategory(
      name: data['name']?.toString() ?? '',
      type: data['type']?.toString() ?? fallbackType ?? 'debit',
      iconName: data['iconName']?.toString() ?? '',
    );
  }

  CategoryOption? _normalizeCategory({
    required String name,
    required String type,
    required String iconName,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return null;

    final normalizedType = type.trim().isEmpty ? 'debit' : type.trim();
    final normalizedIcon = iconName.trim().isEmpty
        ? (normalizedType == 'credit' ? 'moneyBillWave' : 'cartShopping')
        : iconName.trim();

    return CategoryOption(
      name: trimmedName,
      type: normalizedType,
      iconName: normalizedIcon,
    );
  }

  String _categoryDocId(CategoryOption option) {
    final safeName = option.name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[/\\?#\[\]]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return '${option.type.trim().toLowerCase()}__$safeName';
  }
}
