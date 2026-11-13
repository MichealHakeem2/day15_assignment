import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shopping_app/features/favorite/data/repository/favorite_repository.dart';
import 'package:shopping_app/features/favorite/presentation/view_model/favorite_state.dart';
import 'package:shopping_app/features/home/data/models/product_model.dart';

@injectable
class FavoriteCubit extends Cubit<FavoriteState> {
  final FavoriteRepository _favoriteRepository;

  FavoriteCubit(this._favoriteRepository) : super(FavoriteInitial());

  Future<void> getFavorites({bool showLoading = true}) async {
    if (isClosed) return;
    if (showLoading && state is! FavoriteLoaded) {
      emit(FavoriteLoading());
    }
    try {
      final items = await _favoriteRepository.getFavorites();
      if (isClosed) return;
      final ids = items.map((e) => e.id).toSet();
      emit(FavoriteLoaded(favorites: items, favoriteIds: ids));
    } catch (e) {
      if (isClosed) return;
      emit(FavoriteError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<bool> isFavorite(int productId) async {
    return await _favoriteRepository.isFavorite(productId);
  }

  Future<void> toggleFavorite(ProductModel product) async {
    if (isClosed) return;
    try {
      final isFav = await _favoriteRepository.toggleFavorite(product);
      if (isClosed) return;
      final msg = isFav
          ? 'Added "${product.title}" to favourites'
          : 'Removed "${product.title}" from favourites';
      emit(FavoriteActionSuccess(msg));
      await getFavorites(showLoading: false);
    } catch (e) {
      if (isClosed) return;
      emit(FavoriteError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> removeFavorite(ProductModel product) async {
    if (isClosed) return;
    try {
      await _favoriteRepository.toggleFavorite(product);
      if (isClosed) return;
      emit(FavoriteActionSuccess('Removed "${product.title}" from favourites'));
      await getFavorites(showLoading: false);
    } catch (e) {
      if (isClosed) return;
      emit(FavoriteError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}

