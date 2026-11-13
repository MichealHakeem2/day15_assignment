import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_app/core/database/sqflite_helper.dart';
import 'package:shopping_app/features/cart/data/models/cart_item_model.dart';
import 'package:sqflite/sqflite.dart';

@injectable
class CartLocalDataSource {
  static const String _cartStorageKey = 'persistent_cart_items';
  final SqfliteHelper dbHelper;

  CartLocalDataSource({SqfliteHelper? dbHelper})
      : dbHelper = dbHelper ?? SqfliteHelper.instance;

  Future<void> _syncToPrefs([List<CartItemModel>? items]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<CartItemModel> list = items ?? [];
      if (items == null) {
        try {
          final db = await dbHelper.database;
          final results = await db.query('cart', orderBy: 'id DESC');
          list = results.map((map) => CartItemModel.fromMap(map)).toList();
        } catch (_) {}
      }
      final jsonList = list.map((e) => e.toMap()).toList();
      await prefs.setString(_cartStorageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('CartLocalDataSource _syncToPrefs error: $e');
    }
  }

  Future<List<CartItemModel>> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_cartStorageKey);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          return decoded
              .whereType<Map<String, dynamic>>()
              .map((map) => CartItemModel.fromMap(map))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('CartLocalDataSource _loadFromPrefs error: $e');
    }
    return [];
  }

  Future<List<CartItemModel>> getCart() async {
    try {
      final db = await dbHelper.database;
      final results = await db.query('cart', orderBy: 'id DESC');
      final items = results.map((map) => CartItemModel.fromMap(map)).toList();
      if (items.isNotEmpty) {
        _syncToPrefs(items);
        return items;
      }
    } catch (e) {
      debugPrint('CartLocalDataSource getCart SQLite error: $e');
    }

    // Fallback: If SQLite returned empty (e.g. web reload/restart), restore from persistent prefs
    final fallbackItems = await _loadFromPrefs();
    if (fallbackItems.isNotEmpty) {
      try {
        final db = await dbHelper.database;
        final batch = db.batch();
        for (var item in fallbackItems) {
          batch.insert(
            'cart',
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      } catch (_) {}
    }
    return fallbackItems;
  }

  Future<void> addToCart(CartItemModel item) async {
    try {
      final db = await dbHelper.database;
      final existing = await db.query(
        'cart',
        where: 'productId = ?',
        whereArgs: [item.productId],
      );

      if (existing.isNotEmpty) {
        final currentQuantity = (existing.first['quantity'] as num?)?.toInt() ?? 1;
        await db.update(
          'cart',
          {'quantity': currentQuantity + item.quantity},
          where: 'productId = ?',
          whereArgs: [item.productId],
        );
      } else {
        await db.insert(
          'cart',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('CartLocalDataSource addToCart SQLite error: $e');
    }
    await _syncToPrefs();
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    try {
      final db = await dbHelper.database;
      if (quantity <= 0) {
        await deleteFromCart(productId);
        return;
      } else {
        await db.update(
          'cart',
          {'quantity': quantity},
          where: 'productId = ?',
          whereArgs: [productId],
        );
      }
    } catch (e) {
      debugPrint('CartLocalDataSource updateQuantity SQLite error: $e');
    }
    await _syncToPrefs();
  }

  Future<void> deleteFromCart(int productId) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        'cart',
        where: 'productId = ?',
        whereArgs: [productId],
      );
    } catch (e) {
      debugPrint('CartLocalDataSource deleteFromCart SQLite error: $e');
    }
    await _syncToPrefs();
  }

  Future<void> clearCart() async {
    try {
      final db = await dbHelper.database;
      await db.delete('cart');
    } catch (e) {
      debugPrint('CartLocalDataSource clearCart SQLite error: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartStorageKey);
    } catch (_) {}
  }

  Future<void> cacheCartItems(List<CartItemModel> items) async {
    try {
      final db = await dbHelper.database;
      final batch = db.batch();
      for (var item in items) {
        batch.insert(
          'cart',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('CartLocalDataSource cacheCartItems SQLite error: $e');
    }
    await _syncToPrefs(items);
  }
}
