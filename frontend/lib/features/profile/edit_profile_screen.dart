import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/upload_service.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/zylo_background.dart';
import '../../widgets/zylo_states.dart';
import '../../widgets/zylo_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _newPhotoUrl;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameController.text = user.displayName;
      _bioController.text = user.bio;
      _newPhotoUrl = user.profilePhoto;
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        setState(() => _isUploadingPhoto = true);
        final uploadService = ref.read(uploadServiceProvider);
        final res = await uploadService.uploadFile(
          filePath: picked.path,
          fileName: picked.name,
        );
        setState(() {
          _newPhotoUrl = res['url'] as String;
          _isUploadingPhoto = false;
        });
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  void _saveProfile() async {
    final success = await ref.read(profileControllerProvider.notifier).updateProfile(
      displayName: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      profilePhoto: _newPhotoUrl,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully! ✨')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final profileState = ref.watch(profileControllerProvider);
    final isSaving = profileState.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(letterSpacing: -0.2),
        ),
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
      ),
      body: ZyloBackground(
        intensity: ZyloBackgroundIntensity.subtle,
        showTopGlow: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    UserAvatar(
                      imageUrl: _newPhotoUrl ?? user?.profilePhoto,
                      name: user?.displayName ?? 'Me',
                      radius: 54,
                      hasGlow: true,
                    ),
                    if (_isUploadingPhoto)
                      const Positioned.fill(
                        child: Center(
                          child: ZyloLoadingIndicator(size: 28),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.emberLight : AppColors.primaryOrange,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 18,
                            color: isDark ? AppColors.emberLight : AppColors.primaryOrange,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              ZyloSurface(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DISPLAY NAME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Enter your name',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'BIO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bioController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Write a short bio...',
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                    Divider(
                      height: 32,
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Username',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          '@${user?.username ?? ''}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              ZyloPrimaryButton(
                label: 'Save Changes',
                isLoading: isSaving,
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
