import 'package:shopping_app/features/home/data/models/product_model.dart';

abstract class FavoriteState {}

class FavoriteInitial extends FavoriteState {}

class FavoriteLoading extends FavoriteState {}

class FavoriteLoaded extends FavoriteState {
  final List<ProductModel> favorites;
  final Set<int> favoriteIds;

  FavoriteLoaded({
    required this.favorites,
    required this.favoriteIds,
  });
}

class FavoriteError extends FavoriteState {
  final String message;
  FavoriteError(this.message);
}

class FavoriteActionSuccess extends FavoriteState {
  final String message;
  FavoriteActionSuccess(this.message);
}

