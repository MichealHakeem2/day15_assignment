abstract class AccountState {}

class AccountInitial extends AccountState {}

// --- GetUserData states ---
class AccountLoading extends AccountState {}

class AccountLoaded extends AccountState {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String image;

  AccountLoaded({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.image,
  });
}

class AccountError extends AccountState {
  final String message;
  AccountError(this.message);
}

// --- Update states ---
class AccountUpdateLoading extends AccountState {}

class AccountUpdateSuccess extends AccountState {
  final String message;
  AccountUpdateSuccess(this.message);
}

class AccountUpdateError extends AccountState {
  final String message;
  AccountUpdateError(this.message);
}

// --- Image upload states ---
class AccountImageUploadLoading extends AccountState {}

class AccountImageUploadSuccess extends AccountState {
  final String imageUrl;
  AccountImageUploadSuccess(this.imageUrl);
}

class AccountImageUploadError extends AccountState {
  final String message;
  AccountImageUploadError(this.message);
}

