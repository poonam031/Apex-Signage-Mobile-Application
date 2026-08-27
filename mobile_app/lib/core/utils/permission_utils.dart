import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  /// Request all core field permissions (Camera, Mic, Location, Photos) on app start or demand
  static Future<Map<Permission, PermissionStatus>> requestAllFieldPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.locationWhenInUse,
      Permission.photos,
    ].request();

    return statuses;
  }

  /// Request single permission with friendly rationale dialog if denied
  static Future<bool> requestPermission(
    BuildContext context,
    Permission permission, {
    required String title,
    required String message,
  }) async {
    PermissionStatus status = await permission.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      status = await permission.request();
      if (status.isGranted) return true;
    }

    if (status.isPermanentlyDenied && context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text('$message\n\nPlease enable it in App Settings to proceed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
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
      return false;
    }

    return status.isGranted;
  }
}
