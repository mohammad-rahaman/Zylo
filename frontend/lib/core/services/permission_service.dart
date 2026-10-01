import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

class PermissionService {
  /// Request camera permission for capturing Moment photos and video.
  Future<bool> requestCameraPermission({BuildContext? context}) async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.camera.request();
      if (status.isGranted || status.isLimited) {
        return true;
      }
      if (status.isPermanentlyDenied && context != null && context.mounted) {
        _showSettingsDialog(context, 'Camera');
      }
      return false;
    } catch (_) {
      return true; // Fallback gracefully if platform does not support plugin
    }
  }

  /// Request photo library / storage permission for selecting images.
  Future<bool> requestPhotosPermission({BuildContext? context}) async {
    if (kIsWeb) return true;
    try {
      PermissionStatus status = await Permission.photos.request();
      if (!status.isGranted && !status.isLimited) {
        status = await Permission.storage.request();
      }
      if (status.isGranted || status.isLimited) {
        return true;
      }
      if (status.isPermanentlyDenied && context != null && context.mounted) {
        _showSettingsDialog(context, 'Photo Library');
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  /// Request location permission for geotagging Moments and sharing map location.
  Future<bool> requestLocationPermission({BuildContext? context}) async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.locationWhenInUse.request();
      if (status.isGranted || status.isLimited) {
        return true;
      }
      if (status.isPermanentlyDenied && context != null && context.mounted) {
        _showSettingsDialog(context, 'Location');
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  /// Request microphone permission for voice/video.
  Future<bool> requestMicrophonePermission({BuildContext? context}) async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted || status.isLimited) {
        return true;
      }
      if (status.isPermanentlyDenied && context != null && context.mounted) {
        _showSettingsDialog(context, 'Microphone');
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  void _showSettingsDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$feature Permission Required'),
        content: Text(
          'Zylo needs $feature access to share your moments. Please grant permission in your system settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
