import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_app/core/database/sqflite_helper.dart';
import 'package:shopping_app/features/home/data/models/product_model.dart';
import 'package:sqflite/sqflite.dart';

@injectable
class FavoriteLocalDataSource {
  static const String _favoritesStorageKey = 'persistent_favorite_items';
  final SqfliteHelper dbHelper;

  FavoriteLocalDataSource({SqfliteHelper? dbHelper})
      : dbHelper = dbHelper ?? SqfliteHelper.instance;

  Future<void> _syncToPrefs([List<ProductModel>? items]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<ProductModel> list = items ?? [];
      if (items == null) {
        try {
          final db = await dbHelper.database;
          final results = await db.query('favorites');
          list = results.map((map) {
            return ProductModel(
              id: map['productId'] as int,
              title: map['title'] as String? ?? '',
              price: (map['price'] as num?)?.toDouble() ?? 0.0,
              image: map['image'] as String? ?? '',
              category: map['category'] as String? ?? '',
              isFavorite: true,
            );
          }).toList();
        } catch (_) {}
      }
      final jsonList = list.map((e) => e.toMap()).toList();
      await prefs.setString(_favoritesStorageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('FavoriteLocalDataSource _syncToPrefs error: $e');
    }
  }

  Future<List<ProductModel>> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_favoritesStorageKey);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          return decoded
              .whereType<Map<String, dynamic>>()
              .map((map) {
                final p = ProductModel.fromMap(map);
                p.isFavorite = true;
                return p;
              })
              .toList();
        }
      }
    } catch (e) {
      debugPrint('FavoriteLocalDataSource _loadFromPrefs error: $e');
    }
    return [];
  }

  Future<List<ProductModel>> getFavorites() async {
    try {
      final db = await dbHelper.database;
      final results = await db.query('favorites');

      final items = results.map((map) {
        return ProductModel(
          id: map['productId'] as int,
          title: map['title'] as String? ?? '',
          price: (map['price'] as num?)?.toDouble() ?? 0.0,
          image: map['image'] as String? ?? '',
          category: map['category'] as String? ?? '',
          isFavorite: true,
        );
      }).toList();

      if (items.isNotEmpty) {
        _syncToPrefs(items);
        return items;
      }
    } catch (e) {
      debugPrint('FavoriteLocalDataSource getFavorites SQLite error: $e');
    }

    // Fallback: If SQLite returned empty (e.g. web reload/restart), restore from persistent prefs
    final fallbackItems = await _loadFromPrefs();
    if (fallbackItems.isNotEmpty) {
      try {
        final db = await dbHelper.database;
        final batch = db.batch();
        for (var p in fallbackItems) {
          batch.insert(
            'favorites',
            {
              'productId': p.id,
              'title': p.title,
              'price': p.price,
              'image': p.image,
              'category': p.category,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      } catch (_) {}
    }
    return fallbackItems;
  }

  Future<bool> isFavorite(int productId) async {
    try {
      final db = await dbHelper.database;
      final results = await db.query(
        'favorites',
        where: 'productId = ?',
        whereArgs: [productId],
      );
      if (results.isNotEmpty) return true;
    } catch (_) {}

    // Also check persistent backup
    final fallback = await _loadFromPrefs();
    return fallback.any((e) => e.id == productId);
  }

  Future<void> addFavorite(ProductModel product) async {
    try {
      final db = await dbHelper.database;
      await db.insert(
        'favorites',
        {
          'productId': product.id,
          'title': product.title,
          'price': product.price,
          'image': product.image,
          'category': product.category,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await db.update(
        'products',
        {'isFavorite': 1},
        where: 'id = ?',
        whereArgs: [product.id],
      );
    } catch (e) {
      debugPrint('FavoriteLocalDataSource addFavorite SQLite error: $e');
    }
    await _syncToPrefs();
  }

  Future<void> deleteFavorite(int productId) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        'favorites',
        where: 'productId = ?',
        whereArgs: [productId],
      );

      await db.update(
        'products',
        {'isFavorite': 0},
        where: 'id = ?',
        whereArgs: [productId],
      );
    } catch (e) {
      debugPrint('FavoriteLocalDataSource deleteFavorite SQLite error: $e');
    }
    await _syncToPrefs();
  }
}
