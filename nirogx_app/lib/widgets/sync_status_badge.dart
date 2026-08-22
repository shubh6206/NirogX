import 'package:flutter/material.dart';
import '../models/sync_status.dart';

class SyncStatusBadge extends StatelessWidget {
  final SyncMetadata metadata;
  final VoidCallback? onSyncTap;

  const SyncStatusBadge({
    Key? key,
    required this.metadata,
    this.onSyncTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (metadata.dataFreshness) {
      case DataFreshness.realTime:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        icon = Icons.sensors_rounded;
        label = 'Real-time Stream';
        break;
      case DataFreshness.latestSynced:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        icon = Icons.cloud_done_rounded;
        label = 'Synced ${metadata.formattedLastSyncTime}';
        break;
      case DataFreshness.syncing:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        icon = Icons.sync_rounded;
        label = 'Synchronizing...';
        break;
      case DataFreshness.stale:
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFFC2410C);
        icon = Icons.history_rounded;
        label = 'Stale (${metadata.formattedLastSyncTime})';
        break;
      case DataFreshness.unavailable:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        icon = Icons.error_outline_rounded;
        label = 'Sync Required';
        break;
      case DataFreshness.insufficientData:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        icon = Icons.info_outline_rounded;
        label = 'No Synced Records';
        break;
    }

    return InkWell(
      onTap: onSyncTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (metadata.dataFreshness == DataFreshness.syncing)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            else
              Icon(icon, size: 13, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
