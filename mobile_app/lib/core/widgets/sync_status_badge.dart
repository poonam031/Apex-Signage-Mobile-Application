import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum SyncStatus { draft, uploading, synced, failed }

class SyncStatusBadge extends StatelessWidget {
  final SyncStatus status;

  const SyncStatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String text;
    Color color;

    switch (status) {
      case SyncStatus.draft:
        icon = Icons.edit_note;
        text = 'Offline Draft';
        color = AppColors.warning;
        break;
      case SyncStatus.uploading:
        icon = Icons.sync;
        text = 'Syncing...';
        color = AppColors.info;
        break;
      case SyncStatus.synced:
        icon = Icons.cloud_done;
        text = 'Synced';
        color = AppColors.success;
        break;
      case SyncStatus.failed:
        icon = Icons.sync_problem;
        text = 'Sync Failed (Tap to retry)';
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
