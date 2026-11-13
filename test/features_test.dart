import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_app/core/constants/api_constants.dart';
import 'package:shopping_app/core/database/sqflite_helper.dart';
import 'package:shopping_app/core/di/service_locator.dart';
import 'package:shopping_app/core/services/notification_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shopping_app/features/account/data/data_sources/user_remote_data_source.dart';
import 'package:shopping_app/features/account/data/models/profile_model.dart';
import 'package:shopping_app/features/account/data/repositories/user_repository.dart';
import 'package:shopping_app/features/account/presentation/view_model/account_cubit.dart';
import 'package:shopping_app/features/account/presentation/view_model/account_state.dart';
import 'package:shopping_app/features/cart/data/local/cart_local_data_source.dart';
import 'package:shopping_app/features/cart/data/models/cart_item_model.dart';
import 'package:shopping_app/features/cart/data/remote/cart_remote_data_source.dart';
import 'package:shopping_app/features/cart/data/repository/cart_repository.dart';
import 'package:shopping_app/features/cart/presentation/view_model/cart_cubit.dart';
import 'package:shopping_app/features/cart/presentation/view_model/cart_state.dart';
import 'package:shopping_app/features/favorite/data/local/favorite_local_data_source.dart';
import 'package:shopping_app/features/favorite/data/remote/favorite_remote_data_source.dart';
import 'package:shopping_app/features/favorite/data/repository/favorite_repository.dart';
import 'package:shopping_app/features/favorite/presentation/view_model/favorite_cubit.dart';
import 'package:shopping_app/features/favorite/presentation/view_model/favorite_state.dart';
import 'package:shopping_app/features/home/data/data_source/home_data_source.dart';
import 'package:shopping_app/features/home/data/data_source/home_data_source_implementation.dart';
import 'package:shopping_app/features/home/data/models/product_model.dart';
import 'package:shopping_app/features/home/data/repository/home_repository_implementation.dart';
import 'package:shopping_app/features/home/domain/repository/home_repository.dart';
import 'package:shopping_app/features/home/presentation/view_model/home_cubit.dart';

class MockDatabase implements Database {
  final Map<String, List<Map<String, Object?>>> tables = {
    'cart': [],
    'favorites': [],
    'products': [],
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Map<String, Object?>>> query(String table, {bool? distinct, List<String>? columns, String? where, List<Object?>? whereArgs, String? groupBy, String? having, String? orderBy, int? limit, int? offset}) async {
    final list = tables[table] ?? [];
    if (where != null && whereArgs != null && where.contains('productId = ?')) {
      final pid = whereArgs.first;
      return list.where((row) => row['productId'] == pid).toList();
    }
    return List.from(list);
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    tables.putIfAbsent(table, () => []);
    tables[table]!.removeWhere((row) => row['productId'] == values['productId']);
    tables[table]!.add(Map<String, Object?>.from(values));
    return 1;
  }

  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) async {
    final list = tables[table] ?? [];
    if (where != null && whereArgs != null && where.contains('productId = ?')) {
      final pid = whereArgs.first;
      for (var row in list) {
        if (row['productId'] == pid) {
          row.addAll(values);
        }
      }
    }
    return 1;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    if (where == null) {
      tables[table]?.clear();
    } else if (whereArgs != null && where.contains('productId = ?')) {
      final pid = whereArgs.first;
      tables[table]?.removeWhere((row) => row['productId'] == pid);
    }
    return 1;
  }

  @override
  Batch batch() => MockBatch(this);
}

class MockBatch implements Batch {
  final MockDatabase db;
  MockBatch(this.db);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) {
    db.insert(table, values);
  }

  @override
  Future<List<Object?>> commit({bool? exclusive, bool? noResult, bool? continueOnError}) async {
    return [];
  }
}

class MockSqfliteHelper implements SqfliteHelper {
  final MockDatabase mockDb = MockDatabase();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Database> get database => Future.value(mockDb);
}

class FailingCartRemoteDataSource implements CartRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> addToCart(int productId) async {
    throw Exception('HTTP 500: Invalid URL on backend');
  }

  @override
  Future<List<CartItemModel>> getCart() async {
    return [];
  }

  @override
  Future<bool> deleteFromCart(int productId) async {
    throw Exception('HTTP 500: Server error');
  }
}

class FailingFavoriteRemoteDataSource implements FavoriteRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> addFavorite(int productId) async {
    throw Exception('HTTP 500: Invalid URL on backend');
  }

  @override
  Future<List<ProductModel>> getFavorites() async {
    return [];
  }

  @override
  Future<bool> deleteFavorite(int productId) async {
    throw Exception('HTTP 500: Server error');
  }
}

// Mock repository for testing AccountCubit workflows
class MockUserRepository implements UserRepository {
  bool editShouldFail = false;
  bool uploadShouldFail = false;
  String lastUploadedUrl = 'https://example.com/avatar.png';
  String? lastUpdatedImage;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<ProfileModel> getUserData() {
    return Future.value(ProfileModel(
      id: '123',
      name: 'John Doe',
      email: 'john@example.com',
      phone: '0123456789',
      address: 'Cairo, Egypt',
      image: lastUpdatedImage ?? 'https://example.com/existing.png',
    ));
  }

  @override
  Future<String> editUserData({
    required String name,
    required String phone,
    required String address,
    String? image,
  }) {
    if (editShouldFail) {
      return Future.error(Exception('Invalid profile data'));
    }
    lastUpdatedImage = image;
    return Future.value('Profile updated successfully!');
  }

  @override
  Future<String> uploadImage(String filePath, {List<int>? fileBytes, String? fileName}) {
    if (uploadShouldFail) {
      return Future.error(Exception('Failed to upload image to server'));
    }
    return Future.value(lastUploadedUrl);
  }
}

// Mock repository for testing CartCubit workflows
class MockCartRepository implements CartRepository {
  List<CartItemModel> items = [];
  bool shouldFail = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<CartItemModel>> getCart() {
    if (shouldFail) return Future.error(Exception('Failed to load cart'));
    return Future.value(List.from(items));
  }

  @override
  Future<void> addToCart(ProductModel product, {int quantity = 1}) {
    if (shouldFail) return Future.error(Exception('Failed to add to cart'));
    final index = items.indexWhere((e) => e.productId == product.id);
    if (index != -1) {
      items[index].quantity += quantity;
    } else {
      items.add(CartItemModel(
        productId: product.id,
        title: product.title,
        price: product.price,
        image: product.image,
        quantity: quantity,
      ));
    }
    return Future.value();
  }

  @override
  Future<void> updateQuantity(int productId, int quantity) {
    if (shouldFail) return Future.error(Exception('Failed to update quantity'));
    final index = items.indexWhere((e) => e.productId == productId);
    if (index != -1) {
      items[index].quantity = quantity;
    }
    return Future.value();
  }

  @override
  Future<void> deleteFromCart(int productId) {
    if (shouldFail) return Future.error(Exception('Failed to remove item'));
    items.removeWhere((e) => e.productId == productId);
    return Future.value();
  }

  @override
  Future<void> clearCart() {
    if (shouldFail) return Future.error(Exception('Failed to clear cart'));
    items.clear();
    return Future.value();
  }
}

// Mock repository for testing FavoriteCubit workflows
class MockFavoriteRepository implements FavoriteRepository {
  List<ProductModel> favorites = [];
  bool shouldFail = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<ProductModel>> getFavorites() {
    if (shouldFail) return Future.error(Exception('Failed to load favorites'));
    return Future.value(List.from(favorites));
  }

  @override
  Future<bool> isFavorite(int productId) {
    return Future.value(favorites.any((e) => e.id == productId));
  }

  @override
  Future<bool> toggleFavorite(ProductModel product) {
    if (shouldFail) return Future.error(Exception('Failed to toggle favorite'));
    final index = favorites.indexWhere((e) => e.id == product.id);
    if (index != -1) {
      favorites.removeAt(index);
      return Future.value(false);
    } else {
      favorites.add(product);
      return Future.value(true);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Dependency Injection Verification', () {
    setUpAll(() async {
      await configureDependencies();
    });

    test('GetIt resolves HomeRepository as HomeRepositoryImplementation', () {
      final repo = getIt<HomeRepository>();
      expect(repo, isA<HomeRepositoryImplementation>());
    });

    test('GetIt resolves HomeDataSource as HomeDataSourceImplementation', () {
      final dataSource = getIt<HomeDataSource>();
      expect(dataSource, isA<HomeDataSourceImplementation>());
    });

    test('GetIt resolves HomeCubit with all use cases intact', () {
      final cubit = getIt<HomeCubit>();
      expect(cubit, isA<HomeCubit>());
    });

    test('GetIt resolves UserRepository and AccountCubit', () {
      final userRepo = getIt<UserRepository>();
      expect(userRepo, isA<UserRepository>());

      final accountCubit = getIt<AccountCubit>();
      expect(accountCubit, isA<AccountCubit>());
    });

    test('GetIt resolves CartRepository and CartCubit', () {
      final cartRepo = getIt<CartRepository>();
      expect(cartRepo, isA<CartRepository>());

      final cartCubit = getIt<CartCubit>();
      expect(cartCubit, isA<CartCubit>());
    });

    test('GetIt resolves FavoriteRepository and FavoriteCubit', () {
      final favRepo = getIt<FavoriteRepository>();
      expect(favRepo, isA<FavoriteRepository>());

      final favCubit = getIt<FavoriteCubit>();
      expect(favCubit, isA<FavoriteCubit>());
    });
  });

  group('AccountCubit Workflow and State Transitions', () {
    late MockUserRepository mockRepo;
    late AccountCubit cubit;

    setUp(() {
      mockRepo = MockUserRepository();
      cubit = AccountCubit(mockRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('getUserData emits AccountLoading and then AccountLoaded', () async {
      final states = <AccountState>[];
      cubit.stream.listen(states.add);

      await cubit.getUserData();
      await pumpEventQueue();

      expect(states.length, 2, reason: 'Emitted: $states');
      expect(states[0], isA<AccountLoading>());
      expect(states[1], isA<AccountLoaded>());

      final loaded = states[1] as AccountLoaded;
      expect(loaded.name, 'John Doe');
      expect(loaded.email, 'john@example.com');
      expect(loaded.phone, '0123456789');
    });

    test('updateUserData emits AccountUpdateLoading then AccountUpdateSuccess on success', () async {
      final states = <AccountState>[];
      cubit.stream.listen(states.add);

      await cubit.updateUserData(
        name: 'Jane Doe',
        phone: '01011112222',
        address: 'Alexandria',
        image: 'https://example.com/new.png',
      );
      await pumpEventQueue();

      expect(states.any((s) => s is AccountUpdateLoading), isTrue, reason: 'Emitted: $states');
      expect(states.any((s) => s is AccountUpdateSuccess), isTrue, reason: 'Emitted: $states');
      final success = states.firstWhere((s) => s is AccountUpdateSuccess) as AccountUpdateSuccess;
      expect(success.message, 'Profile updated successfully!');
    });

    test('updateUserData emits AccountUpdateLoading then AccountUpdateError on failure', () async {
      mockRepo.editShouldFail = true;
      final states = <AccountState>[];
      cubit.stream.listen(states.add);

      await cubit.updateUserData(
        name: 'Jane Doe',
        phone: '01011112222',
        address: 'Alexandria',
      );
      await pumpEventQueue();

      expect(states.any((s) => s is AccountUpdateLoading), isTrue, reason: 'States: $states');
      expect(states.any((s) => s is AccountUpdateError), isTrue, reason: 'States: $states');
      final error = states.firstWhere((s) => s is AccountUpdateError) as AccountUpdateError;
      expect(error.message, 'Invalid profile data');
    });

    test('Two-step image upload workflow (Operation A -> Operation B)', () async {
      final states = <AccountState>[];
      cubit.stream.listen(states.add);

      await cubit.uploadAndSaveProfileImage(
        filePath: '/mock/path/profile.jpg',
        name: 'John Doe',
        phone: '0123456789',
        address: 'Cairo',
      );
      await pumpEventQueue();

      // Verify Operation A emitted AccountImageUploadLoading and AccountImageUploadSuccess
      expect(states.any((s) => s is AccountImageUploadLoading), isTrue);
      expect(states.any((s) => s is AccountImageUploadSuccess), isTrue);
      final uploadSuccess = states.firstWhere((s) => s is AccountImageUploadSuccess) as AccountImageUploadSuccess;
      expect(uploadSuccess.imageUrl, 'https://example.com/avatar.png');

      // Verify Operation B passed the uploaded URL to editUserData and succeeded
      expect(mockRepo.lastUpdatedImage, 'https://example.com/avatar.png');
      expect(states.any((s) => s is AccountUpdateSuccess), isTrue);
    });

    test('AccountCubit does not emit or throw after being closed during async call', () async {
      // Start an operation and close cubit immediately
      final future = cubit.getUserData();
      await cubit.close();

      // Ensure waiting for the async call does not throw Bad state: Cannot emit new states after calling close
      await expectLater(future, completes);
    });
  });

  group('CartCubit Workflow and State Transitions', () {
    late MockCartRepository mockRepo;
    late CartCubit cubit;

    final sampleProduct = ProductModel(
      id: 101,
      title: 'Running Shoes',
      price: 250.0,
      description: 'Comfortable sports shoes',
      image: 'https://example.com/shoes.jpg',
    );

    setUp(() {
      mockRepo = MockCartRepository();
      cubit = CartCubit(mockRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('getCart emits CartLoading and CartLoaded with items and subtotal', () async {
      mockRepo.items = [
        CartItemModel(
          productId: 101,
          title: 'Running Shoes',
          price: 250.0,
          image: 'https://example.com/shoes.jpg',
          quantity: 2,
        ),
      ];

      final states = <CartState>[];
      cubit.stream.listen(states.add);

      await cubit.getCart();
      await pumpEventQueue();

      expect(states.length, 2);
      expect(states[0], isA<CartLoading>());
      expect(states[1], isA<CartLoaded>());

      final loaded = states[1] as CartLoaded;
      expect(loaded.items.length, 1);
      expect(loaded.subtotal, 500.0);
      expect(loaded.totalCount, 2);
    });

    test('addToCart emits CartActionSuccess and reloads cart', () async {
      final states = <CartState>[];
      cubit.stream.listen(states.add);

      await cubit.addToCart(sampleProduct, quantity: 2);
      await pumpEventQueue();

      expect(states.any((s) => s is CartActionSuccess), isTrue);
      final success = states.firstWhere((s) => s is CartActionSuccess) as CartActionSuccess;
      expect(success.message, contains('Running Shoes'));

      expect(states.any((s) => s is CartLoaded), isTrue);
      final loaded = states.whereType<CartLoaded>().last;
      expect(loaded.items.length, 1);
      expect(loaded.items.first.quantity, 2);
      expect(loaded.subtotal, 500.0);
    });

    test('updateQuantity updates item quantity and recalculates totals', () async {
      mockRepo.items = [
        CartItemModel(
          productId: 101,
          title: 'Running Shoes',
          price: 250.0,
          image: 'https://example.com/shoes.jpg',
          quantity: 1,
        ),
      ];

      final states = <CartState>[];
      cubit.stream.listen(states.add);

      await cubit.updateQuantity(101, 3);
      await pumpEventQueue();

      expect(states.any((s) => s is CartLoaded), isTrue);
      final loaded = states.whereType<CartLoaded>().last;
      expect(loaded.items.first.quantity, 3);
      expect(loaded.subtotal, 750.0);
      expect(loaded.totalCount, 3);
    });

    test('removeFromCart emits CartActionSuccess and reloads cart without item', () async {
      mockRepo.items = [
        CartItemModel(
          productId: 101,
          title: 'Running Shoes',
          price: 250.0,
          image: 'https://example.com/shoes.jpg',
          quantity: 1,
        ),
      ];

      final states = <CartState>[];
      cubit.stream.listen(states.add);

      await cubit.removeFromCart(101, itemTitle: 'Running Shoes');
      await pumpEventQueue();

      expect(states.any((s) => s is CartActionSuccess), isTrue);
      final success = states.firstWhere((s) => s is CartActionSuccess) as CartActionSuccess;
      expect(success.message, 'Removed "Running Shoes" from cart');

      final loaded = states.whereType<CartLoaded>().last;
      expect(loaded.items.isEmpty, isTrue);
      expect(loaded.subtotal, 0.0);
    });

    test('clearCart empties the cart and emits CartActionSuccess', () async {
      mockRepo.items = [
        CartItemModel(
          productId: 101,
          title: 'Running Shoes',
          price: 250.0,
          image: 'https://example.com/shoes.jpg',
          quantity: 1,
        ),
      ];

      final states = <CartState>[];
      cubit.stream.listen(states.add);

      await cubit.clearCart();
      await pumpEventQueue();

      expect(states.any((s) => s is CartActionSuccess), isTrue);
      final loaded = states.whereType<CartLoaded>().last;
      expect(loaded.items.isEmpty, isTrue);
    });

    test('CartCubit does not emit or throw after being closed during async call', () async {
      final future = cubit.addToCart(sampleProduct);
      await cubit.close();

      await expectLater(future, completes);
    });
  });

  group('FavoriteCubit Workflow and State Transitions', () {
    late MockFavoriteRepository mockRepo;
    late FavoriteCubit cubit;

    final sampleProduct = ProductModel(
      id: 202,
      title: 'Smart Watch',
      price: 1500.0,
      description: 'Feature-rich smartwatch',
      image: 'https://example.com/watch.jpg',
    );

    setUp(() {
      mockRepo = MockFavoriteRepository();
      cubit = FavoriteCubit(mockRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('getFavorites emits FavoriteLoading and FavoriteLoaded with items and ids', () async {
      mockRepo.favorites = [sampleProduct];

      final states = <FavoriteState>[];
      cubit.stream.listen(states.add);

      await cubit.getFavorites();
      await pumpEventQueue();

      expect(states.length, 2);
      expect(states[0], isA<FavoriteLoading>());
      expect(states[1], isA<FavoriteLoaded>());

      final loaded = states[1] as FavoriteLoaded;
      expect(loaded.favorites.length, 1);
      expect(loaded.favoriteIds.contains(202), isTrue);
    });

    test('toggleFavorite adds item and emits FavoriteActionSuccess then FavoriteLoaded', () async {
      final states = <FavoriteState>[];
      cubit.stream.listen(states.add);

      await cubit.toggleFavorite(sampleProduct);
      await pumpEventQueue();

      expect(states.any((s) => s is FavoriteActionSuccess), isTrue);
      final success = states.firstWhere((s) => s is FavoriteActionSuccess) as FavoriteActionSuccess;
      expect(success.message, 'Added "Smart Watch" to favourites');

      final loaded = states.whereType<FavoriteLoaded>().last;
      expect(loaded.favorites.length, 1);
      expect(loaded.favoriteIds.contains(202), isTrue);
    });

    test('toggleFavorite removes item when already favorite', () async {
      mockRepo.favorites = [sampleProduct];

      final states = <FavoriteState>[];
      cubit.stream.listen(states.add);

      await cubit.toggleFavorite(sampleProduct);
      await pumpEventQueue();

      expect(states.any((s) => s is FavoriteActionSuccess), isTrue);
      final success = states.firstWhere((s) => s is FavoriteActionSuccess) as FavoriteActionSuccess;
      expect(success.message, 'Removed "Smart Watch" from favourites');

      final loaded = states.whereType<FavoriteLoaded>().last;
      expect(loaded.favorites.isEmpty, isTrue);
      expect(loaded.favoriteIds.isEmpty, isTrue);
    });

    test('removeFavorite removes item and emits action success', () async {
      mockRepo.favorites = [sampleProduct];

      final states = <FavoriteState>[];
      cubit.stream.listen(states.add);

      await cubit.removeFavorite(sampleProduct);
      await pumpEventQueue();

      expect(states.any((s) => s is FavoriteActionSuccess), isTrue);
      final success = states.firstWhere((s) => s is FavoriteActionSuccess) as FavoriteActionSuccess;
      expect(success.message, 'Removed "Smart Watch" from favourites');
    });

    test('FavoriteCubit does not emit or throw after being closed during async call', () async {
      final future = cubit.toggleFavorite(sampleProduct);
      await cubit.close();

      await expectLater(future, completes);
    });
  });

  group('HomeCubit Closed-State Protection', () {
    test('HomeCubit does not emit or throw after being closed during async calls', () async {
      final homeCubit = getIt<HomeCubit>();
      final catFuture = homeCubit.getAllCategories();
      final prodFuture = homeCubit.getAllProducts();
      await homeCubit.close();

      await expectLater(catFuture, completes);
      await expectLater(prodFuture, completes);
    });
  });

  group('Image MIME Type Detection', () {
    test('UserRemoteDataSource.resolveMediaType detects PNG from magic bytes', () {
      final pngBytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      final mediaType = UserRemoteDataSource.resolveMediaType(bytes: pngBytes);
      expect(mediaType.type, 'image');
      expect(mediaType.subtype, 'png');
    });

    test('UserRemoteDataSource.resolveMediaType detects JPEG from magic bytes', () {
      final jpegBytes = [0xFF, 0xD8, 0xFF, 0xE0];
      final mediaType = UserRemoteDataSource.resolveMediaType(bytes: jpegBytes);
      expect(mediaType.type, 'image');
      expect(mediaType.subtype, 'jpeg');
    });

    test('UserRemoteDataSource.resolveMediaType detects MIME type from filename extension', () {
      final pngType = UserRemoteDataSource.resolveMediaType(nameOrPath: 'my_avatar.png');
      expect(pngType.type, 'image');
      expect(pngType.subtype, 'png');

      final jpgType = UserRemoteDataSource.resolveMediaType(nameOrPath: 'photo.jpg');
      expect(jpgType.type, 'image');
      expect(jpgType.subtype, 'jpeg');

      final jpegType = UserRemoteDataSource.resolveMediaType(nameOrPath: '/path/to/img.jpeg');
      expect(jpegType.type, 'image');
      expect(jpegType.subtype, 'jpeg');
    });
  });

  group('Profile Image URL Formatting and 404 Prevention', () {
    test('ProfileModel.formatImageUrl formats relative images path to root domain', () {
      final formatted = ProfileModel.formatImageUrl('images/portfolio/1794568720650-701740.jpg');
      final expectedBase = ApiConstants.baseUrl.replaceAll('/api/v1', '');
      expect(formatted, '$expectedBase/images/portfolio/1794568720650-701740.jpg');
      expect(formatted.contains('/api/v1/'), isFalse);
    });

    test('ProfileModel.formatImageUrl removes invalid /api/v1 prefix from image URLs', () {
      final formatted = ProfileModel.formatImageUrl('https://supermarket-dan1.onrender.com/api/v1/images/portfolio/pic.jpg');
      expect(formatted, 'https://supermarket-dan1.onrender.com/images/portfolio/pic.jpg');
    });

    test('ProfileModel.formatImageUrl ignores simple.jpg default placeholder', () {
      expect(ProfileModel.formatImageUrl('https://supermarket-dan1.onrender.com/images/simple.jpg'), '');
    });
  });

  group('NotificationService Permission and Safety', () {
    test('showNotification does not throw Bad state on Web or when permission is not granted', () async {
      // Must complete without throwing Bad state: FlutterLocalNotifications.show(): You must request notifications permissions first
      final result = await NotificationService.instance.showNotification(
        title: 'Test Title',
        body: 'Test Body',
      );
      // In non-device unit test environment or Web, it returns a bool gracefully without crashing
      expect(result, isA<bool>());
    });

    test('scheduleNotification completes gracefully without throwing exceptions', () async {
      final result = await NotificationService.instance.scheduleNotification(
        title: 'Test Title',
        body: 'Test Body',
        seconds: 2,
      );
      expect(result, isA<bool>());
    });
  });

  group('Local Persistence and Backend Error Resilience', () {
    test('CartRepository preserves local cart even if remote addToCart fails with HTTP 500', () async {
      final localDS = CartLocalDataSource(dbHelper: MockSqfliteHelper());
      await localDS.clearCart();

      final repo = CartRepository(
        localDataSource: localDS,
        remoteDataSource: FailingCartRemoteDataSource(),
      );

      final product = ProductModel(
        id: 999,
        title: 'Offline Product',
        price: 99.0,
        image: 'https://example.com/product.jpg',
      );

      // Adding to cart must succeed locally despite remote 500
      await repo.addToCart(product, quantity: 2);

      final items = await repo.getCart();
      expect(items.any((e) => e.productId == 999), isTrue);
      expect(items.firstWhere((e) => e.productId == 999).quantity, 2);

      // Clean up
      await repo.clearCart();
    });

    test('CartLocalDataSource restores cart items from persistent storage when SQLite is empty (web restart)', () async {
      final mockHelper1 = MockSqfliteHelper();
      final localDS1 = CartLocalDataSource(dbHelper: mockHelper1);

      await localDS1.addToCart(CartItemModel(
        productId: 555,
        title: 'Persisted Cart Item',
        price: 200.0,
        image: 'https://example.com/item.jpg',
        quantity: 3,
      ));

      // Simulate a browser restart / reload where SQLite in-memory is empty
      final freshMockHelper = MockSqfliteHelper(); // empty tables
      final localDS2 = CartLocalDataSource(dbHelper: freshMockHelper);

      final restored = await localDS2.getCart();
      expect(restored.any((e) => e.productId == 555), isTrue);
      expect(restored.firstWhere((e) => e.productId == 555).quantity, 3);
    });

    test('FavoriteRepository preserves local favorite even if remote addFavorite fails with HTTP 500', () async {
      final localDS = FavoriteLocalDataSource(dbHelper: MockSqfliteHelper());
      await localDS.deleteFavorite(888);

      final repo = FavoriteRepository(
        localDataSource: localDS,
        remoteDataSource: FailingFavoriteRemoteDataSource(),
      );

      final product = ProductModel(
        id: 888,
        title: 'Offline Favorite',
        price: 150.0,
        image: 'https://example.com/fav.jpg',
      );

      final isFav = await repo.toggleFavorite(product);
      expect(isFav, isTrue);

      final favorites = await repo.getFavorites();
      expect(favorites.any((e) => e.id == 888), isTrue);

      // Clean up
      await repo.toggleFavorite(product);
    });

    test('FavoriteLocalDataSource restores favorites from persistent storage when SQLite is empty (web restart)', () async {
      final mockHelper1 = MockSqfliteHelper();
      final localDS1 = FavoriteLocalDataSource(dbHelper: mockHelper1);

      await localDS1.addFavorite(ProductModel(
        id: 777,
        title: 'Persisted Favorite',
        price: 300.0,
        image: 'https://example.com/fav.jpg',
      ));

      // Simulate browser restart / reload where SQLite in-memory is empty
      final freshMockHelper = MockSqfliteHelper(); // empty tables
      final localDS2 = FavoriteLocalDataSource(dbHelper: freshMockHelper);

      final restored = await localDS2.getFavorites();
      expect(restored.any((e) => e.id == 777), isTrue);
    });
  });
}
