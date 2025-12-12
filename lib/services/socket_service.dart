import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../screens/incoming_call_screen.dart';

class IncomingCall {
  final String callerName;
  final String callerId;
  final String roomId;
  final bool isVideo;

  IncomingCall({
    required this.callerName,
    required this.callerId,
    required this.roomId,
    required this.isVideo,
  });
}

class AppSocket {
  AppSocket._privateConstructor();
  static final AppSocket instance = AppSocket._privateConstructor();

  late IO.Socket socket;
  String? loggedInUserId;
  String? serverUrl;

  /// IMPORTANT: set this as MaterialApp.navigatorKey so dialogs can be shown from anywhere.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final ValueNotifier<IncomingCall?> incomingCallNotifier =
      ValueNotifier<IncomingCall?>(null);

  bool _isDialogShowing = false;
  static const int _maxPopupRetries = 6;
  static const Duration _popupRetryDelay = Duration(milliseconds: 500);

  /// Initialize Socket.IO connection
  void init(String serverUrl, String userId) {
    this.serverUrl = serverUrl;
    loggedInUserId = userId;

    socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setQuery({'userId': userId})
          .build(),
    );

    socket.onConnect((_) {
      debugPrint("🟢 Socket connected (id: ${socket.id})");
      socket.emit('register', userId);
    });

    socket.onDisconnect((_) => debugPrint("⚠️ Socket disconnected"));

    socket.onError((data) => debugPrint("❌ Socket error: $data"));

    /// ------------------ Incoming call ------------------
    socket.on('incoming-call', (data) {
      debugPrint(
        '📞 Received incoming-call raw payload: ${data.runtimeType} -> $data',
      );

      dynamic raw;
      try {
        raw = (data is String) ? jsonDecode(data) : data;
      } catch (e) {
        raw = data;
      }

      String roomId = 'unknown_room';
      String callerId = 'unknown_caller';
      String? callerNameCandidate;
      bool isVideo = false;

      String? _safe(dynamic src, List<String> keys) {
        try {
          if (src is Map) {
            for (final k in keys) {
              if (src.containsKey(k) && src[k] != null) {
                final v = src[k];
                if (v is String && v.trim().isNotEmpty) return v.trim();
                if (v is num || v is bool) return v.toString();
              }
            }
          }
        } catch (_) {}
        return null;
      }

      if (raw is Map) {
        roomId = _safe(raw, ['roomId', 'room_id', 'room', 'roomName']) ?? roomId;
        callerId = _safe(raw, [
              'fromUserId',
              'from_user_id',
              'from',
              'callerId',
              'caller_id',
              'caller',
            ]) ??
            callerId;

        callerNameCandidate = _safe(raw, [
          'callerName',
          'caller_name',
          'caller',
          'name',
          'displayName',
        ]);

        final typeStr = _safe(raw, ['type', 'callType', 'call_type']);
        if (typeStr != null) {
          final t = typeStr.toLowerCase();
          if (t.contains('audio')) isVideo = false;
          if (t.contains('video')) isVideo = true;
        }

        final rawIsVideo = raw['isVideo'] ?? raw['is_video'] ?? raw['video'];
        if (rawIsVideo != null) {
          if (rawIsVideo is bool) {
            isVideo = rawIsVideo;
          } else if (rawIsVideo is String) {
            isVideo = rawIsVideo.toLowerCase() == 'true' || rawIsVideo == '1';
          } else if (rawIsVideo is num) {
            isVideo = rawIsVideo == 1;
          }
        }

        if (callerNameCandidate == null) {
          final meta = raw['metadata'] ?? raw['meta'] ?? raw['payload'];
          if (meta != null) {
            try {
              final parsedMeta = (meta is String) ? jsonDecode(meta) : meta;
              if (parsedMeta is Map) {
                callerNameCandidate = _safe(parsedMeta, [
                  'name',
                  'displayName',
                  'employeeName',
                ]);
                final empId = _safe(parsedMeta, [
                  'employeeId',
                  'employee_id',
                  'id',
                ]);
                if (callerNameCandidate != null && empId != null) {
                  callerNameCandidate = '${callerNameCandidate} ($empId)';
                }
              } else if (parsedMeta is String && parsedMeta.trim().isNotEmpty) {
                callerNameCandidate = parsedMeta.trim();
              }
            } catch (_) {
              if (meta is String && meta.trim().isNotEmpty)
                callerNameCandidate = meta.trim();
            }
          }
        }
      } else {
        final s = raw?.toString();
        if (s != null && s.isNotEmpty) {
          if (s.contains('type=audio') || s.contains('callType=audio'))
            isVideo = false;
          if (s.contains('type=video') || s.contains('callType=video'))
            isVideo = true;
          callerNameCandidate = s;
        }
      }

      final callerName =
          (callerNameCandidate != null && callerNameCandidate.trim().isNotEmpty)
              ? callerNameCandidate!
              : callerId;

      final call = IncomingCall(
        callerName: callerName,
        callerId: callerId,
        roomId: roomId,
        isVideo: isVideo,
      );

      incomingCallNotifier.value = call;
      _attemptShowPopup(call, 0);
    });

    /// ------------------ Call ended ------------------
    socket.on('call_ended', (data) {
      final roomId = data['roomId'] ?? '';
      debugPrint('❌ Received call_ended for room $roomId');

      // Close any open call screen automatically
      if (navigatorKey.currentState?.canPop() ?? false) {
        navigatorKey.currentState?.pop(); // closes CallScreen or IncomingCallScreen
      }

      // Optionally show a SnackBar
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Call ended by other participant')),
        );
      }
    });
  }

  void _attemptShowPopup(IncomingCall call, int attempt) {
    if (_isDialogShowing) return;

    final ctx =
        navigatorKey.currentState?.overlay?.context ?? navigatorKey.currentContext;

    if (ctx == null) {
      if (attempt < _maxPopupRetries) {
        Timer(_popupRetryDelay, () => _attemptShowPopup(call, attempt + 1));
      }
      return;
    }

    _showIncomingCallDialog(ctx, call);
  }

  void _showIncomingCallDialog(BuildContext ctx, IncomingCall call) {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    showDialog<void>(
          context: ctx,
          barrierDismissible: false,
          builder: (_) => IncomingCallScreen(
            callerName: call.callerName,
            callerId: call.callerId,
            receiverId: loggedInUserId ?? '',
            roomId: call.roomId,
            isVideo: call.isVideo,
            serverUrl: serverUrl ?? '',
            userId: loggedInUserId ?? '',
          ),
        )
        .then((_) {
          _isDialogShowing = false;
          incomingCallNotifier.value = null;
        })
        .catchError((err) {
          _isDialogShowing = false;
          debugPrint("❌ Error showing incoming call dialog: $err");
        });
  }

  /// Outgoing call helper
  void callUser({
    required String toUserId,
    required String fromUserId,
    required String roomId,
    required bool isVideo,
    String? callerName,
  }) {
    final payload = {
      'toUserId': toUserId,
      'fromUserId': fromUserId,
      'roomId': roomId,
      'isVideo': isVideo,
      'callType': isVideo ? 'video' : 'audio',
      'callerName': callerName ?? fromUserId,
      'callerId': fromUserId,
      'metadata': {'name': callerName ?? fromUserId, 'id': fromUserId},
    };

    debugPrint('🔵 Emitting call-user payload: $payload');
    socket.emit('call-user', payload);
  }

  void disconnect() {
    socket.disconnect();
  }
}
