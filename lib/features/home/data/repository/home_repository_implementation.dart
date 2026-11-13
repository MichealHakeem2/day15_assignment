import 'package:injectable/injectable.dart';
import 'package:shopping_app/core/network/api_result.dart';
import 'package:shopping_app/features/home/data/data_source/home_data_source.dart';
import 'package:shopping_app/features/home/domain/entities/category_entity.dart';
import 'package:shopping_app/features/home/domain/entities/product_entity.dart';
import 'package:shopping_app/features/home/domain/repository/home_repository.dart';

@Injectable(as: HomeRepository)
class HomeRepositoryImplementation implements HomeRepository {
  final HomeDataSource remoteDataSource;

  HomeRepositoryImplementation(this.remoteDataSource);

  @override
  Future<ApiResult<List<CategoryEntity>>> getAllCategories() async {
    try {
      final categoryDtos = await remoteDataSource.getAllCategories();
      // convert list of DTOs to list of Entities
      final categoryEntities =
          categoryDtos.map((dto) => dto.toEntity()).toList();
      return Success(categoryEntities);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<ApiResult<List<ProductEntity>>> getAllProducts({
    int skip = 0,
    int limit = 10,
    String? category,
  }) async {
    try {
      final productDtos = await remoteDataSource.getAllProducts(
        skip: skip,
        limit: limit,
        category: category,
      );
      // convert list of DTOs to list of Entities
      final productEntities =
          productDtos.map((dto) => dto.toEntity()).toList();
      return Success(productEntities);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}
