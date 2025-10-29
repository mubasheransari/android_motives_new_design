import 'dart:async';
import 'package:flutter/material.dart';

import 'sync_service.dart'; // <- your SyncService with events & pendingNotifier

/// Wrap your app with this to auto-show a progress dialog whenever
/// SyncService starts sending queued requests after connectivity returns.
class SyncProgressPortal extends StatefulWidget {
  final Widget child;
  const SyncProgressPortal({super.key, required this.child});

  @override
  State<SyncProgressPortal> createState() => _SyncProgressPortalState();
}

class _SyncProgressPortalState extends State<SyncProgressPortal> {
  StreamSubscription<SyncEvent>? _sub;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();

    // Subscribe after the first frame so a Navigator is present.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sub = SyncService.instance.events.listen((e) {
        // When sync starts and there are items to send -> open the dialog once.
        if (e.type == SyncEventType.started && e.total > 0 && !_dialogOpen) {
          _dialogOpen = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _SyncProgressDialog(initial: e),
          ).whenComplete(() {
            _dialogOpen = false;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SyncProgressDialog extends StatelessWidget {
  final SyncEvent initial;
  const _SyncProgressDialog({required this.initial});

  @override
  Widget build(BuildContext context) {
    // Keep rebuilding the dialog as sync progresses.
    return StreamBuilder<SyncEvent>(
      stream: SyncService.instance.events,
      initialData: initial,
      builder: (ctx, snap) {
        final ev = snap.data ?? initial;

        if (ev.type == SyncEventType.completed) {
          // Close dialog and toast success if the queue is empty now.
          Future.microtask(() {
            if (Navigator.of(ctx, rootNavigator: true).canPop()) {
              Navigator.of(ctx, rootNavigator: true).pop();
            }
            if (ev.remaining == 0) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('All pending actions synced ✅')),
              );
            }
          });
          return const SizedBox.shrink();
        }

        final total = ev.total;
        final remaining = ev.remaining;
        final done = (total - remaining).clamp(0, total);
        final progress = total == 0 ? null : done / total;

        return AlertDialog(
          title: const Text('Sync in progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 12),
              Text('Sending offline data… ($done of $total)'),
            ],
          ),
        );
      },
    );
  }
}
