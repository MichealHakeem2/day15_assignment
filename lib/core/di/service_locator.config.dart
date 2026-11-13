// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:http/http.dart' as _i519;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shopping_app/core/database/sqflite_helper.dart' as _i555;
import 'package:shopping_app/core/di/service_locator.dart' as _i568;
import 'package:shopping_app/features/account/data/data_sources/user_local_data_source.dart'
    as _i409;
import 'package:shopping_app/features/account/data/data_sources/user_remote_data_source.dart'
    as _i570;
import 'package:shopping_app/features/account/data/repositories/user_repository.dart'
    as _i464;
import 'package:shopping_app/features/account/presentation/view_model/account_cubit.dart'
    as _i588;
import 'package:shopping_app/features/cart/data/local/cart_local_data_source.dart'
    as _i762;
import 'package:shopping_app/features/cart/data/remote/cart_remote_data_source.dart'
    as _i494;
import 'package:shopping_app/features/cart/data/repository/cart_repository.dart'
    as _i487;
import 'package:shopping_app/features/cart/presentation/view_model/cart_cubit.dart'
    as _i824;
import 'package:shopping_app/features/favorite/data/local/favorite_local_data_source.dart'
    as _i354;
import 'package:shopping_app/features/favorite/data/remote/favorite_remote_data_source.dart'
    as _i458;
import 'package:shopping_app/features/favorite/data/repository/favorite_repository.dart'
    as _i538;
import 'package:shopping_app/features/favorite/presentation/view_model/favorite_cubit.dart'
    as _i683;
import 'package:shopping_app/features/home/data/data_source/home_data_source.dart'
    as _i81;
import 'package:shopping_app/features/home/data/data_source/home_data_source_implementation.dart'
    as _i378;
import 'package:shopping_app/features/home/data/repository/home_repository_implementation.dart'
    as _i818;
import 'package:shopping_app/features/home/domain/repository/home_repository.dart'
    as _i527;
import 'package:shopping_app/features/home/domain/use_cases/get_all_categories_use_case.dart'
    as _i353;
import 'package:shopping_app/features/home/domain/use_cases/get_all_products_use_case.dart'
    as _i282;
import 'package:shopping_app/features/home/presentation/view_model/home_cubit.dart'
    as _i991;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i519.Client>(() => registerModule.client);
    gh.lazySingleton<_i555.SqfliteHelper>(() => registerModule.sqfliteHelper);
    gh.factory<_i487.CartRepository>(
      () => _i487.CartRepository(
        remoteDataSource: gh<_i494.CartRemoteDataSource>(),
        localDataSource: gh<_i762.CartLocalDataSource>(),
      ),
    );
    gh.factory<_i81.HomeDataSource>(
      () => _i378.HomeDataSourceImplementation(client: gh<_i519.Client>()),
    );
    gh.factory<_i409.UserLocalDataSource>(
      () => _i409.UserLocalDataSource(dbHelper: gh<_i555.SqfliteHelper>()),
    );
    gh.factory<_i762.CartLocalDataSource>(
      () => _i762.CartLocalDataSource(dbHelper: gh<_i555.SqfliteHelper>()),
    );
    gh.factory<_i354.FavoriteLocalDataSource>(
      () => _i354.FavoriteLocalDataSource(dbHelper: gh<_i555.SqfliteHelper>()),
    );
    gh.factory<_i570.UserRemoteDataSource>(
      () => _i570.UserRemoteDataSource(client: gh<_i519.Client>()),
    );
    gh.factory<_i494.CartRemoteDataSource>(
      () => _i494.CartRemoteDataSource(client: gh<_i519.Client>()),
    );
    gh.factory<_i458.FavoriteRemoteDataSource>(
      () => _i458.FavoriteRemoteDataSource(client: gh<_i519.Client>()),
    );
    gh.factory<_i538.FavoriteRepository>(
      () => _i538.FavoriteRepository(
        remoteDataSource: gh<_i458.FavoriteRemoteDataSource>(),
        localDataSource: gh<_i354.FavoriteLocalDataSource>(),
      ),
    );
    gh.factory<_i824.CartCubit>(
      () => _i824.CartCubit(gh<_i487.CartRepository>()),
    );
    gh.factory<_i527.HomeRepository>(
      () => _i818.HomeRepositoryImplementation(gh<_i81.HomeDataSource>()),
    );
    gh.factory<_i464.UserRepository>(
      () => _i464.UserRepository(
        remoteDataSource: gh<_i570.UserRemoteDataSource>(),
        localDataSource: gh<_i409.UserLocalDataSource>(),
      ),
    );
    gh.factory<_i683.FavoriteCubit>(
      () => _i683.FavoriteCubit(gh<_i538.FavoriteRepository>()),
    );
    gh.factory<_i588.AccountCubit>(
      () => _i588.AccountCubit(gh<_i464.UserRepository>()),
    );
    gh.factory<_i353.GetAllCategoriesUseCase>(
      () => _i353.GetAllCategoriesUseCase(gh<_i527.HomeRepository>()),
    );
    gh.factory<_i282.GetAllProductsUseCase>(
      () => _i282.GetAllProductsUseCase(gh<_i527.HomeRepository>()),
    );
    gh.factory<_i991.HomeCubit>(
      () => _i991.HomeCubit(
        getAllCategoriesUseCase: gh<_i353.GetAllCategoriesUseCase>(),
        getAllProductsUseCase: gh<_i282.GetAllProductsUseCase>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i568.RegisterModule {}
