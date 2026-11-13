import 'package:shopping_app/features/cart/data/models/cart_item_model.dart';

abstract class CartState {}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<CartItemModel> items;
  final double subtotal;
  final int totalCount;

  CartLoaded({
    required this.items,
    required this.subtotal,
    required this.totalCount,
  });
}

class CartError extends CartState {
  final String message;
  CartError(this.message);
}

class CartActionSuccess extends CartState {
  final String message;
  CartActionSuccess(this.message);
}

