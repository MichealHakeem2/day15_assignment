import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopping_app/core/constants/app_colors.dart';
import 'package:shopping_app/core/di/service_locator.dart';
import 'package:shopping_app/features/cart/data/repository/cart_repository.dart';
import 'package:shopping_app/features/cart/presentation/view_model/cart_cubit.dart';
import 'package:shopping_app/features/favorite/presentation/view_model/favorite_cubit.dart';
import 'package:shopping_app/features/favorite/presentation/view_model/favorite_state.dart';
import 'package:shopping_app/features/home/data/models/product_model.dart';
import 'package:shopping_app/features/home/presentation/product_details_screen.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<FavoriteCubit>();
      return const _FavoriteScreenContent();
    } catch (_) {
      return BlocProvider(
        create: (context) => getIt<FavoriteCubit>()..getFavorites(),
        child: const _FavoriteScreenContent(),
      );
    }
  }
}

class _FavoriteScreenContent extends StatefulWidget {
  const _FavoriteScreenContent();

  @override
  State<_FavoriteScreenContent> createState() => _FavoriteScreenContentState();
}

class _FavoriteScreenContentState extends State<_FavoriteScreenContent> {
  List<ProductModel> _favorites = [];
  bool _isLoading = false;
  final Set<int> _processingCartProductIds = <int>{};

  @override
  void initState() {
    super.initState();
    final currentState = context.read<FavoriteCubit>().state;
    if (currentState is FavoriteLoaded) {
      _favorites = currentState.favorites;
      _isLoading = false;
    } else {
      _isLoading = true;
      context.read<FavoriteCubit>().getFavorites();
    }
  }

  void _removeFavorite(ProductModel product) {
    context.read<FavoriteCubit>().removeFavorite(product);
  }

  void _addToCart(ProductModel product) async {
    if (_processingCartProductIds.contains(product.id)) return;
    _processingCartProductIds.add(product.id);
    try {
      await context.read<CartCubit>().addToCart(product);
    } catch (_) {
      await CartRepository.instance.addToCart(product);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${product.title}" to cart'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.secondary,
        ),
      );
    } finally {
      if (mounted) {
        _processingCartProductIds.remove(product.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FavoriteCubit, FavoriteState>(
      listener: (context, state) {
        if (state is FavoriteLoading) {
          setState(() => _isLoading = true);
        } else if (state is FavoriteLoaded) {
          setState(() {
            _isLoading = false;
            _favorites = state.favorites;
          });
        } else if (state is FavoriteActionSuccess) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              duration: const Duration(seconds: 1),
              backgroundColor: AppColors.dark,
            ),
          );
        } else if (state is FavoriteError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0.5,
            title: const Text(
              'My Favourites',
              style: TextStyle(
                color: AppColors.dark,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          body: _isLoading && _favorites.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : RefreshIndicator(
                  onRefresh: () =>
                      context.read<FavoriteCubit>().getFavorites(showLoading: false),
                  color: AppColors.primary,
                  child: _favorites.isEmpty
                      ? _buildEmptyFavorites()
                      : _buildFavoritesGrid(),
                ),
        );
      },
    );
  }

  Widget _buildEmptyFavorites() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_outline,
                  size: 64,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'There are no products in your favourite list',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap the heart icon on any product to save it here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _favorites.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.58,
      ),
      itemBuilder: (context, index) {
        final product = _favorites[index];
        return _buildFavoriteCard(product);
      },
    );
  }

  Widget _buildFavoriteCard(ProductModel product) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(productId: product.id),
          ),
        ).then((_) {
          if (mounted) {
            context.read<FavoriteCubit>().getFavorites(showLoading: false);
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 112,
                    width: double.infinity,
                    color: const Color(0xFFF7F7F9),
                    child: product.image.isNotEmpty
                        ? Image.network(
                            product.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported, color: AppColors.grey),
                          )
                        : const Icon(Icons.shopping_bag_outlined, color: AppColors.grey),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: IconButton(
                      iconSize: 20,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () => _removeFavorite(product),
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'EGP ${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: () => _addToCart(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                  label: const Text(
                    'Add to cart',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef FavouriteScreen = FavoriteScreen;
