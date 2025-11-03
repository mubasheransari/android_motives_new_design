import 'dart:async';
import 'package:flutter/material.dart';

import 'sync_service.dart'; // <- your SyncService with events & pendingNotifier


import 'dart:async';
import 'package:flutter/material.dart';

import 'sync_service.dart'; // <- your SyncService with events & pendingNotifier

/// Wrap your app with this to auto-show a progress dialog whenever
/// SyncService starts sending queued requests after connectivity returns.
///
/// Usage:
///   runApp(SyncProgressPortal(child: MyApp()));
class SyncProgressPortal extends StatefulWidget {
  final Widget child;
  const SyncProgressPortal({super.key, required this.child});

  @override
  State<SyncProgressPortal> createState() => _SyncProgressPortalState();
}

class _SyncProgressPortalState extends State<SyncProgressPortal> with WidgetsBindingObserver {
  StreamSubscription<SyncEvent>? _sub;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Subscribe after first frame so a Navigator exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sub = SyncService.instance.events.listen(_onSyncEvent, onError: (_) {});
    });
  }

  void _onSyncEvent(SyncEvent e) {
    if (!mounted) return;

    // Open once on "started"
    if (e.type == SyncEventType.started && e.total > 0 && !_dialogOpen) {
      _dialogOpen = true;
      // Defer to next microtask to avoid "setState during build" issues.
      Future.microtask(() {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          useRootNavigator: true,
          builder: (_) => _SyncProgressDialog(initial: e),
        ).whenComplete(() {
          _dialogOpen = false;
        });
      });
      return;
    }

    // If we somehow finished without the dialog (rare), optionally toast here.
    if (e.type == SyncEventType.completed && !_dialogOpen && e.remaining == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All pending actions synced ✅')),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SyncProgressDialog extends StatefulWidget {
  final SyncEvent initial;
  const _SyncProgressDialog({required this.initial});

  @override
  State<_SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends State<_SyncProgressDialog> {
  late SyncEvent _latest;

  @override
  void initState() {
    super.initState();
    _latest = widget.initial;
  }

  String _jobKindLabel(SyncEvent e) {
    final k = e.job?.kind.toString() ?? '';
    // usually looks like "QueueKind.order" → take the tail
    final tail = k.contains('.') ? k.split('.').last : k;
    switch (tail.toLowerCase()) {
      case 'order':
        return 'Order';
      case 'attendance':
        return 'Attendance';
      case 'startroute':
        return 'Start Route';
      case 'routeaction':
        return 'Route Action';
      default:
        return tail.isEmpty ? 'Job' : tail;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return StreamBuilder<SyncEvent>(
      stream: SyncService.instance.events,
      initialData: widget.initial,
      builder: (ctx, snap) {
        _latest = snap.data ?? _latest;

        // Close on completion; toast success if all sent.
        if (_latest.type == SyncEventType.completed) {
          Future.microtask(() {
            if (!mounted) return;
            if (Navigator.of(ctx, rootNavigator: true).canPop()) {
              Navigator.of(ctx, rootNavigator: true).pop();
            }
            if (_latest.remaining == 0) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('All pending actions synced ✅')),
              );
            } else {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(
                    'Some actions left (${_latest.remaining}). Will retry automatically.',
                  ),
                ),
              );
            }
          });
          return const SizedBox.shrink();
        }

        final total = _latest.total;
        final remaining = _latest.remaining;
        final done = (total - remaining).clamp(0, total);
        final progress = total == 0 ? null : done / total;

        final showError = _latest.type == SyncEventType.failed;
        final subtitle = showError
            ? (_latest.message?.isNotEmpty == true
                ? 'Will retry automatically.\n${_latest.message}'
                : 'Will retry automatically.')
            : 'Sending ${_jobKindLabel(_latest)}…';

        return WillPopScope(
          onWillPop: () async => false, // block back button while syncing
          child: AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.sync_rounded),
                const SizedBox(width: 8),
                const Text('Sync in progress'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 12),
                Text('$_niceCount($done) of $_niceCount($total)',
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: t.bodySmall?.copyWith(
                    color: showError ? Colors.redAccent : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _niceCount(int v) => v.toString();
}


/// Wrap your app with this to auto-show a progress dialog whenever
/// SyncService starts sending queued requests after connectivity returns.
// class SyncProgressPortal extends StatefulWidget {
//   final Widget child;
//   const SyncProgressPortal({super.key, required this.child});

//   @override
//   State<SyncProgressPortal> createState() => _SyncProgressPortalState();
// }

// class _SyncProgressPortalState extends State<SyncProgressPortal> {
//   StreamSubscription<SyncEvent>? _sub;
//   bool _dialogOpen = false;

//   @override
//   void initState() {
//     super.initState();

//     // Subscribe after the first frame so a Navigator is present.
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _sub = SyncService.instance.events.listen((e) {
//         // When sync starts and there are items to send -> open the dialog once.
//         if (e.type == SyncEventType.started && e.total > 0 && !_dialogOpen) {
//           _dialogOpen = true;
//           showDialog(
//             context: context,
//             barrierDismissible: false,
//             builder: (_) => _SyncProgressDialog(initial: e),
//           ).whenComplete(() {
//             _dialogOpen = false;
//           });
//         }
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _sub?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) => widget.child;
// }

// class _SyncProgressDialog extends StatelessWidget {
//   final SyncEvent initial;
//   const _SyncProgressDialog({required this.initial});

//   @override
//   Widget build(BuildContext context) {
//     // Keep rebuilding the dialog as sync progresses.
//     return StreamBuilder<SyncEvent>(
//       stream: SyncService.instance.events,
//       initialData: initial,
//       builder: (ctx, snap) {
//         final ev = snap.data ?? initial;

//         if (ev.type == SyncEventType.completed) {
//           // Close dialog and toast success if the queue is empty now.
//           Future.microtask(() {
//             if (Navigator.of(ctx, rootNavigator: true).canPop()) {
//               Navigator.of(ctx, rootNavigator: true).pop();
//             }
//             if (ev.remaining == 0) {
//               ScaffoldMessenger.of(ctx).showSnackBar(
//                 const SnackBar(content: Text('All pending actions synced ✅')),
//               );
//             }
//           });
//           return const SizedBox.shrink();
//         }

//         final total = ev.total;
//         final remaining = ev.remaining;
//         final done = (total - remaining).clamp(0, total);
//         final progress = total == 0 ? null : done / total;

//         return AlertDialog(
//           title: const Text('Sync in progress'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               LinearProgressIndicator(value: progress),
//               const SizedBox(height: 12),
//               Text('Sending offline data… ($done of $total)'),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
