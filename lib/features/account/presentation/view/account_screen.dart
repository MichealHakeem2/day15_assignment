import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopping_app/core/constants/app_colors.dart';
import 'package:shopping_app/core/di/service_locator.dart';
import 'package:shopping_app/core/local_storage/cache_helper.dart';
import 'package:shopping_app/core/routes/app_routes.dart';
import 'package:shopping_app/core/utils/app_validator.dart';
import 'package:shopping_app/core/widgets/custom_elevated_button.dart';
import 'package:shopping_app/core/widgets/custom_text_form_field.dart';
import 'package:shopping_app/features/account/data/models/profile_model.dart';
import 'package:shopping_app/features/account/presentation/view_model/account_cubit.dart';
import 'package:shopping_app/features/account/presentation/view_model/account_state.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<AccountCubit>();
      return const _AccountScreenContent();
    } catch (_) {
      return BlocProvider(
        create: (context) => getIt<AccountCubit>()..getUserData(),
        child: const _AccountScreenContent(),
      );
    }
  }
}

class _AccountScreenContent extends StatefulWidget {
  const _AccountScreenContent();

  @override
  State<_AccountScreenContent> createState() => _AccountScreenContentState();
}

class _AccountScreenContentState extends State<_AccountScreenContent> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    // Populate controllers if AccountCubit is already loaded
    final currentState = context.read<AccountCubit>().state;
    if (currentState is AccountLoaded) {
      _nameController.text = currentState.name;
      _emailController.text = currentState.email;
      _phoneController.text = currentState.phone;
      _addressController.text =
          currentState.address == 'not added' ? '' : currentState.address;
      _avatarUrl = currentState.image;
    } else {
      // Trigger a load just in case
      context.read<AccountCubit>().getUserData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AccountCubit>().updateUserData(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            image: _avatarUrl,
          );
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      final bytes = await pickedFile.readAsBytes();
      if (!mounted) return;
      context.read<AccountCubit>().uploadAndSaveProfileImage(
            filePath: pickedFile.path,
            fileBytes: bytes,
            fileName: pickedFile.name,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
          );
    }
  }

  void _onLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      CacheHelper.clear();
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountCubit, AccountState>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, state) {
        if (state is AccountLoaded) {
          _nameController.text = state.name;
          _emailController.text = state.email;
          _phoneController.text = state.phone;
          _addressController.text =
              state.address == 'not added' ? '' : state.address;
          setState(() {
            _avatarUrl = state.image;
          });
        } else if (state is AccountImageUploadSuccess) {
          setState(() {
            _avatarUrl = state.imageUrl;
          });
        } else if (state is AccountUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message.isNotEmpty
                    ? state.message
                    : 'Profile updated successfully!',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is AccountUpdateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message.isNotEmpty
                    ? state.message
                    : 'Failed to update profile',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is AccountImageUploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message.isNotEmpty
                    ? state.message
                    : 'Failed to upload image',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is AccountError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message.isNotEmpty
                    ? state.message
                    : 'Failed to load profile',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        final isInitialLoading = state is AccountLoading;
        final isSaving = state is AccountUpdateLoading;
        final isUploadingImage = state is AccountImageUploadLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0.5,
            title: const Text(
              'My Profile',
              style: TextStyle(
                color: AppColors.dark,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                tooltip: 'Logout',
                onPressed: _onLogout,
              ),
            ],
          ),
          body: isInitialLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<AccountCubit>().getUserData(),
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    border: Border.all(
                                        color: AppColors.primary, width: 2),
                                  ),
                                  child: ClipOval(
                                    child: isUploadingImage
                                        ? const Center(
                                            child: SizedBox(
                                              width: 32,
                                              height: 32,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          )
                                        : (_avatarUrl != null &&
                                                _avatarUrl!.isNotEmpty
                                            ? Image.network(
                                                ProfileModel.formatImageUrl(_avatarUrl),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(Icons.person,
                                                        size: 60,
                                                        color:
                                                            AppColors.primary),
                                              )
                                            : const Icon(Icons.person,
                                                size: 60,
                                                color: AppColors.primary)),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: isUploadingImage || isSaving
                                        ? null
                                        : _pickAndUploadImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: AppColors.dark,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text
                                : 'User Profile',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark,
                            ),
                          ),
                          Text(
                            _emailController.text,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 28),
                          CustomTextFormField(
                            label: 'Name',
                            hintText: 'Enter your full name',
                            controller: _nameController,
                            validator: AppValidator.validateName,
                          ),
                          const SizedBox(height: 16),
                          CustomTextFormField(
                            label: 'Email Address',
                            hintText: 'Enter your email',
                            controller: _emailController,
                            readOnly: true,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          CustomTextFormField(
                            label: 'Phone Number',
                            hintText: 'Enter your phone number',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: AppValidator.validatePhone,
                          ),
                          const SizedBox(height: 16),
                          CustomTextFormField(
                            label: 'Address',
                            hintText: 'Enter your delivery address',
                            controller: _addressController,
                          ),
                          const SizedBox(height: 16),
                          CustomTextFormField(
                            label: 'Password',
                            hintText: '••••••••',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.grey,
                              ),
                              onPressed: () {
                                setState(() =>
                                    _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                          CustomElevatedButton(
                            text: 'Submit',
                            isLoading: isSaving,
                            loadingIndicatorColor: AppColors.primary,
                            onPressed: _saveProfile,
                            backgroundColor: AppColors.dark,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
