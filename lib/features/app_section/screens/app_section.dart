import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopping_app/core/constants/app_assets.dart';
import 'package:shopping_app/core/constants/app_colors.dart';
import 'package:shopping_app/core/di/service_locator.dart';
import 'package:shopping_app/features/account/presentation/view/account_screen.dart';
import 'package:shopping_app/features/account/presentation/view_model/account_cubit.dart';
import 'package:shopping_app/features/cart/presentation/view/cart_screen.dart';
import 'package:shopping_app/features/cart/presentation/view_model/cart_cubit.dart';
import 'package:shopping_app/features/favorite/presentation/view/favorite_screen.dart';
import 'package:shopping_app/features/favorite/presentation/view_model/favorite_cubit.dart';
import 'package:shopping_app/features/home/presentation/view/home_screen.dart';
import 'package:shopping_app/features/home/presentation/view_model/home_cubit.dart';

class AppSection extends StatefulWidget {
  const AppSection({super.key});

  @override
  State<AppSection> createState() => _AppSectionState();
}

class _AppSectionState extends State<AppSection> {
  int index = 0;

  static const List<Widget> screens = [
    HomeScreen(),
    CartScreen(),
    FavoriteScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<HomeCubit>()
            ..getAllCategories()
            ..getAllProducts(),
        ),
        BlocProvider(
          create: (context) => getIt<CartCubit>()..getCart(),
        ),
        BlocProvider(
          create: (context) => getIt<FavoriteCubit>()..getFavorites(),
        ),
        BlocProvider(
          create: (context) => getIt<AccountCubit>()..getUserData(),
        ),
      ],
      child: Scaffold(
        body: screens[index],
        bottomNavigationBar: BottomNavigationBar(
          elevation: 0,
          backgroundColor: AppColors.white,
          type: BottomNavigationBarType.fixed,
          currentIndex: index,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: (selectedIndex) {
            setState(() {
              index = selectedIndex;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Image.asset(AppAssets.homeIcons, width: 24, height: 24),
              activeIcon: Image.asset(
                AppAssets.homeIcons,
                width: 24,
                height: 24,
                color: AppColors.primary,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(AppAssets.cartIcons, width: 24, height: 24),
              activeIcon: Image.asset(
                AppAssets.cartIcons,
                width: 24,
                height: 24,
                color: AppColors.primary,
              ),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(AppAssets.favoriteIcons, width: 24, height: 24),
              activeIcon: Image.asset(
                AppAssets.favoriteIcons,
                width: 24,
                height: 24,
                color: AppColors.primary,
              ),
              label: 'Favourite',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(AppAssets.profileIcons, width: 24, height: 24),
              activeIcon: Image.asset(
                AppAssets.profileIcons,
                width: 24,
                height: 24,
                color: AppColors.primary,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
