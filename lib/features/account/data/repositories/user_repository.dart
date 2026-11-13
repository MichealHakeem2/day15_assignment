import 'package:injectable/injectable.dart';
import 'package:shopping_app/core/local_storage/cache_helper.dart';
import 'package:shopping_app/features/account/data/data_sources/user_local_data_source.dart';
import 'package:shopping_app/features/account/data/data_sources/user_remote_data_source.dart';
import 'package:shopping_app/features/account/data/models/profile_model.dart';

@injectable
class UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;

  UserRepository({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  Future<ProfileModel> getUserData() async {
    try {
      final remoteProfile = await remoteDataSource.getUserData();
      await localDataSource.cacheProfile(remoteProfile);
      if (remoteProfile.name.isNotEmpty) {
        await CacheHelper.updateUserName(remoteProfile.name);
      }
      return remoteProfile;
    } catch (_) {
      final cached = await localDataSource.getCachedProfile();
      if (cached != null) {
        return cached;
      }
      return ProfileModel(
        id: '1',
        name: CacheHelper.userName ?? '',
        email: CacheHelper.userEmail ?? '',
        phone: '',
        address: '',
        image: '',
      );
    }
  }

  /// Returns the backend success message on success, throws on failure.
  Future<String> editUserData({
    required String name,
    required String phone,
    required String address,
    String? image,
  }) async {
    final cached = await localDataSource.getCachedProfile();
    final updated = ProfileModel(
      id: cached?.id ?? '1',
      name: name,
      email: cached?.email ?? CacheHelper.userEmail ?? '',
      phone: phone,
      address: address,
      image: image ?? cached?.image ?? '',
    );
    await localDataSource.cacheProfile(updated);

    final message = await remoteDataSource.editUserData(
      name: name,
      phone: phone,
      address: address,
      image: image,
    );
    if (name.isNotEmpty) {
      await CacheHelper.updateUserName(name);
    }
    return message;
  }

  /// Uploads an image file and returns the URL returned by the backend.
  Future<String> uploadImage(String filePath, {List<int>? fileBytes, String? fileName}) async {
    return remoteDataSource.uploadImage(filePath, fileBytes: fileBytes, fileName: fileName);
  }
}
