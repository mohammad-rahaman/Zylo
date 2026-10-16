import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../models/user.dart';
import '../../models/moment.dart';
import '../../models/moment_shortcut.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/moment_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/upload_service.dart';
import '../../widgets/moment_badge.dart';
import '../../widgets/user_avatar.dart';
import 'camera_filters.dart';
import '../../widgets/zylo_button.dart';

class CameraSendScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final ZyloFilterType filter;
  final bool isFlipped;
  final List<String>? initialRecipientIds;

  const CameraSendScreen({
    super.key,
    required this.imagePath,
    required this.filter,
    this.isFlipped = false,
    this.initialRecipientIds,
  });

  @override
  ConsumerState<CameraSendScreen> createState() => _CameraSendScreenState();
}

class _CameraSendScreenState extends ConsumerState<CameraSendScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final Set<String> _selectedUserIds = {};
  String _searchQuery = '';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecipientIds != null && widget.initialRecipientIds!.isNotEmpty) {
      _selectedUserIds.addAll(widget.initialRecipientIds!);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleUser(String userId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _toggleShortcut(MomentShortcut shortcut) {
    HapticFeedback.lightImpact();
    setState(() {
      final shortcutIds = shortcut.contactIds.toSet();
      // If all members are already selected, deselect them. Otherwise, add all members.
      final allSelected = shortcutIds.isNotEmpty &&
          shortcutIds.every((id) => _selectedUserIds.contains(id));

      if (allSelected) {
        _selectedUserIds.removeAll(shortcutIds);
      } else {
        _selectedUserIds.addAll(shortcutIds);
      }
    });
  }

  Future<String> _resolveUploadPath() async {
    if (!widget.isFlipped) return widget.imagePath;

    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final uiImage = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.translate(uiImage.width.toDouble(), 0);
      canvas.scale(-1.0, 1.0);
      canvas.drawImage(uiImage, Offset.zero, Paint());

      final picture = recorder.endRecording();
      final flippedImage = await picture.toImage(uiImage.width, uiImage.height);
      final byteData = await flippedImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final dir = File(widget.imagePath).parent.path;
        final flippedPath = '$dir/moment_mirrored_${DateTime.now().millisecondsSinceEpoch}.png';
        await File(flippedPath).writeAsBytes(byteData.buffer.asUint8List());
        return flippedPath;
      }
    } catch (e) {
      debugPrint('Failed to horizontally mirror selfie file for upload: $e');
    }
    return widget.imagePath;
  }

  Future<void> _handleSend() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one recipient')),
      );
      return;
    }

    setState(() => _isSending = true);
    HapticFeedback.mediumImpact();

    try {
      // 1. Upload media once using existing UploadService (mirror file if selfie was flipped)
      final uploadService = ref.read(uploadServiceProvider);
      final fileToUpload = await _resolveUploadPath();
      final uploadRes = await uploadService.uploadFile(
        filePath: fileToUpload,
        fileName: 'moment_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final mediaUrl = uploadRes['url'] as String? ?? '';
      if (mediaUrl.isEmpty) {
        throw Exception('Media upload failed: no URL returned');
      }

      // 2. Dispatch to multiple recipients via MomentService
      final momentService = ref.read(momentServiceProvider);
      await momentService.sendMoment(
        mediaUrl: mediaUrl,
        recipientIds: _selectedUserIds.toList(),
        caption: _captionController.text.trim().isNotEmpty
            ? _captionController.text.trim()
            : null,
        filter: widget.filter != ZyloFilterType.normal ? widget.filter.name : null,
      );

      // Refresh moments and conversations lists
      ref.invalidate(momentsProvider);
      ref.invalidate(conversationsProvider);

      if (!mounted) return;

      final count = _selectedUserIds.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Moment sent to $count recipient${count > 1 ? 's' : ''}!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // Pop back to home screen
      context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send Moment: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _showCreateShortcutDialog(List<User> availableContacts) {
    final nameCtrl = TextEditingController();
    String selectedEmoji = '✨';
    final Set<String> shortcutMembers = Set.from(_selectedUserIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Create Quick Send',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(dialogCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Emoji + Name
                  Row(
                    children: [
                      // Emoji selector
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceSubduedDark : AppColors.surfaceSubduedLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        child: DropdownButton<String>(
                          value: selectedEmoji,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: '✨', child: Text('✨ Besties')),
                            DropdownMenuItem(value: '🏠', child: Text('🏠 Family')),
                            DropdownMenuItem(value: '🎓', child: Text('🎓 College')),
                            DropdownMenuItem(value: '💼', child: Text('💼 Work')),
                            DropdownMenuItem(value: '⚡', child: Text('⚡ Squad')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedEmoji = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Shortcut Name (e.g. Besties)',
                            filled: true,
                            fillColor: isDark ? AppColors.surfaceSubduedDark : AppColors.surfaceSubduedLight,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Select Contacts to include:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: availableContacts.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No contacts available', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: availableContacts.length,
                            itemBuilder: (_, i) {
                              final contact = availableContacts[i];
                              final isChecked = shortcutMembers.contains(contact.id);
                              return CheckboxListTile(
                                dense: true,
                                title: Text(contact.resolvedName),
                                subtitle: Text('@${contact.username}'),
                                secondary: UserAvatar(
                                  imageUrl: contact.profilePhoto,
                                  name: contact.resolvedName,
                                  radius: 16,
                                ),
                                activeColor: AppColors.primaryOrange,
                                value: isChecked,
                                onChanged: (val) {
                                  setDialogState(() {
                                    if (val == true) {
                                      shortcutMembers.add(contact.id);
                                    } else {
                                      shortcutMembers.remove(contact.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;

                      await ref.read(shortcutsProvider.notifier).createShortcut(
                            name: name,
                            emoji: selectedEmoji,
                            contactIds: shortcutMembers.toList(),
                          );

                      if (dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Shortcut', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(authProvider).user;
    final usersAsync = ref.watch(userSearchProvider(_searchQuery));
    final momentsState = ref.watch(momentsProvider);
    final shortcutsAsync = ref.watch(shortcutsProvider);

    // Map active moments by friend ID for instant count badge display
    final momentByFriendId = <String, Moment>{};
    for (final m in momentsState.moments) {
      if (m.friend != null) {
        momentByFriendId[m.friend!.id] = m;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Send Moment', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Media Preview & Caption Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Small filtered image preview
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 68,
                            height: 88,
                            child: Transform.flip(
                              flipX: widget.isFlipped,
                              child: widget.filter.colorFilter != null
                                  ? ColorFiltered(
                                      colorFilter: widget.filter.colorFilter!,
                                      child: Image.file(
                                        File(widget.imagePath),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.file(
                                      File(widget.imagePath),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Caption input
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _captionController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  hintText: 'Add a Moment caption...',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (widget.filter != ZyloFilterType.normal)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryOrange.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${widget.filter.icon} ${widget.filter.displayName}',
                                    style: const TextStyle(
                                      color: AppColors.primaryOrange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Quick Send Shortcuts Header & Carousel
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Send',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Shortcuts horizontal list
                      shortcutsAsync.when(
                        data: (shortcuts) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                // Existing shortcuts chips
                                ...shortcuts.map((sc) {
                                  final shortcutIds = sc.contactIds.toSet();
                                  final isAllSelected = shortcutIds.isNotEmpty &&
                                      shortcutIds.every((id) => _selectedUserIds.contains(id));

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      selected: isAllSelected,
                                      label: Text('${sc.emoji} ${sc.name}'),
                                      selectedColor: AppColors.primaryOrange.withValues(alpha: 0.18),
                                      checkmarkColor: AppColors.primaryOrange,
                                      labelStyle: TextStyle(
                                        color: isAllSelected
                                            ? AppColors.primaryOrange
                                            : (isDark ? Colors.white70 : Colors.black87),
                                        fontWeight: isAllSelected ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: isAllSelected
                                              ? AppColors.primaryOrange
                                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                        ),
                                      ),
                                      onSelected: (_) => _toggleShortcut(sc),
                                    ),
                                  );
                                }),

                                // + Create shortcut chip
                                ActionChip(
                                  avatar: const Icon(Icons.add_rounded, size: 18, color: AppColors.primaryOrange),
                                  label: const Text(
                                    'Create',
                                    style: TextStyle(
                                      color: AppColors.primaryOrange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: AppColors.primaryOrange.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  onPressed: () {
                                    usersAsync.whenData((allUsers) {
                                      final filtered = allUsers
                                          .where((u) => u.id != currentUser?.id)
                                          .toList();
                                      _showCreateShortcutDialog(filtered);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox(height: 36),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Contacts Header & Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contacts',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search contacts...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          filled: true,
                          fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Contacts List
              usersAsync.when(
                data: (users) {
                  final list = users.where((u) => u.id != currentUser?.id).toList();

                  if (list.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No contacts found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final user = list[index];
                        final isSelected = _selectedUserIds.contains(user.id);
                        final moment = momentByFriendId[user.id];

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryOrange.withValues(alpha: isDark ? 0.16 : 0.08)
                                : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryOrange
                                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: UserAvatar(
                                imageUrl: user.profilePhoto,
                                name: user.resolvedName,
                                radius: 20,
                                showOnlineStatus: true,
                                isOnline: user.isOnline,
                                hasGlow: isSelected,
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.resolvedName,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (moment != null) ...[
                                    const SizedBox(width: 6),
                                    MomentBadge.fromMoment(moment),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                '@${user.username}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              trailing: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? AppColors.primaryOrange : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryOrange
                                        : (isDark ? Colors.white30 : Colors.black26),
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                              onTap: () => _toggleUser(user.id),
                            ),
                          ),
                        );
                      },
                      childCount: list.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.primaryOrange),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Could not load contacts: $e', style: const TextStyle(color: Colors.grey)),
                    ),
                  ),
                ),
              ),

              // Bottom padding space for floating action button
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),

          // 5. Bottom Send Floating Button with glowing pill
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SafeArea(
              child: DecoratedBox(
                // Solid backing so the list never shows through the translucent button.
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bgDark : AppColors.bgLight,
                  borderRadius: AppRadius.mdBorder,
                ),
                child: ZyloPrimaryButton(
                  label: _selectedUserIds.isEmpty
                      ? 'Select recipients'
                      : 'Send moment (${_selectedUserIds.length})',
                  icon: Icons.auto_awesome_outlined,
                  height: 54,
                  isLoading: _isSending,
                  onPressed: _selectedUserIds.isEmpty ? null : _handleSend,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
