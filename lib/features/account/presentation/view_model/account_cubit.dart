import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shopping_app/features/account/data/repositories/user_repository.dart';
import 'package:shopping_app/features/account/presentation/view_model/account_state.dart';

@injectable
class AccountCubit extends Cubit<AccountState> {
  final UserRepository _userRepository;

  AccountCubit(this._userRepository) : super(AccountInitial());

  /// Fetch user data from the repository and emit the appropriate state.
  Future<void> getUserData() async {
    if (isClosed) return;
    emit(AccountLoading());
    try {
      final profile = await _userRepository.getUserData();
      if (isClosed) return;
      emit(AccountLoaded(
        id: profile.id,
        name: profile.name,
        email: profile.email,
        phone: profile.phone,
        address: profile.address,
        image: profile.image,
      ));
    } catch (e) {
      if (isClosed) return;
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      emit(AccountError(errorMsg));
    }
  }

  /// Update the user profile. Emits loading → success/error.
  Future<void> updateUserData({
    required String name,
    required String phone,
    required String address,
    String? image,
  }) async {
    if (isClosed) return;
    emit(AccountUpdateLoading());
    try {
      final message = await _userRepository.editUserData(
        name: name,
        phone: phone,
        address: address,
        image: image,
      );
      if (isClosed) return;
      emit(AccountUpdateSuccess(message));
      // Refresh the loaded state after a successful update
      await getUserData();
    } catch (e) {
      if (isClosed) return;
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      emit(AccountUpdateError(errorMsg));
    }
  }

  /// Upload a profile image file and emit the returned URL on success.
  Future<void> uploadProfileImage(
    String filePath, {
    List<int>? fileBytes,
    String? fileName,
  }) async {
    if (isClosed) return;
    emit(AccountImageUploadLoading());
    try {
      final imageUrl = await _userRepository.uploadImage(
        filePath,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      if (isClosed) return;
      emit(AccountImageUploadSuccess(imageUrl));
    } catch (e) {
      if (isClosed) return;
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      emit(AccountImageUploadError(errorMsg));
    }
  }

  /// Workflow combining Operation A (upload image) and Operation B (update profile with new image URL)
  Future<void> uploadAndSaveProfileImage({
    required String filePath,
    List<int>? fileBytes,
    String? fileName,
    required String name,
    required String phone,
    required String address,
  }) async {
    if (isClosed) return;
    emit(AccountImageUploadLoading());
    try {
      // Operation A: Upload image to get URL
      final imageUrl = await _userRepository.uploadImage(
        filePath,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      if (isClosed) return;
      emit(AccountImageUploadSuccess(imageUrl));

      // Operation B: Account Update with the new image URL
      await updateUserData(
        name: name,
        phone: phone,
        address: address,
        image: imageUrl,
      );
    } catch (e) {
      if (isClosed) return;
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      emit(AccountImageUploadError(errorMsg));
    }
  }
}
