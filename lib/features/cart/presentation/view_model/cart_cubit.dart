import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shopping_app/features/cart/data/models/cart_item_model.dart';
import 'package:shopping_app/features/cart/data/repository/cart_repository.dart';
import 'package:shopping_app/features/cart/presentation/view_model/cart_state.dart';
import 'package:shopping_app/features/home/data/models/product_model.dart';

@injectable
class CartCubit extends Cubit<CartState> {
  final CartRepository _cartRepository;

  CartCubit(this._cartRepository) : super(CartInitial());

  double _calculateSubtotal(List<CartItemModel> items) {
    double sum = 0;
    for (var item in items) {
      sum += item.totalPrice;
    }
    return sum;
  }

  int _calculateCount(List<CartItemModel> items) {
    int count = 0;
    for (var item in items) {
      count += item.quantity;
    }
    return count;
  }

  Future<void> getCart({bool showLoading = true}) async {
    if (isClosed) return;
    if (showLoading && state is! CartLoaded) {
      emit(CartLoading());
    }
    try {
      final items = await _cartRepository.getCart();
      if (isClosed) return;
      emit(CartLoaded(
        items: items,
        subtotal: _calculateSubtotal(items),
        totalCount: _calculateCount(items),
      ));
    } catch (e) {
      if (isClosed) return;
      emit(CartError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> addToCart(ProductModel product, {int quantity = 1}) async {
    if (isClosed) return;
    try {
      await _cartRepository.addToCart(product, quantity: quantity);
      if (isClosed) return;
      emit(CartActionSuccess('Added "${product.title}" to cart'));
      await getCart(showLoading: false);
    } catch (e) {
      if (isClosed) return;
      emit(CartError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    if (isClosed) return;
    try {
      await _cartRepository.updateQuantity(productId, quantity);
      if (isClosed) return;
      await getCart(showLoading: false);
    } catch (e) {
      if (isClosed) return;
      emit(CartError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> removeFromCart(int productId, {String? itemTitle}) async {
    if (isClosed) return;
    try {
      await _cartRepository.deleteFromCart(productId);
      if (isClosed) return;
      final msg = itemTitle != null ? 'Removed "$itemTitle" from cart' : 'Item removed from cart';
      emit(CartActionSuccess(msg));
      await getCart(showLoading: false);
    } catch (e) {
      if (isClosed) return;
      emit(CartError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> clearCart() async {
    if (isClosed) return;
    try {
      await _cartRepository.clearCart();
      if (isClosed) return;
      emit(CartActionSuccess('Cart cleared'));
      await getCart(showLoading: false);
    } catch (e) {
      if (isClosed) return;
      emit(CartError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}

