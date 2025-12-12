import 'package:flutter/material.dart';
import '../services/livekit_service.dart';
import '../services/socket_service.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String callerId;
  final String receiverId;
  final String roomId;
  final bool isVideo;
  final String serverUrl;
  final String userId;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.callerId,
    required this.receiverId,
    required this.roomId,
    required this.isVideo,
    required this.serverUrl,
    required this.userId,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  bool _isConnecting = false;

  // ------------------- ACCEPT CALL -------------------
  Future<void> _acceptCall() async {
    setState(() => _isConnecting = true);

    try {
      final lk = LiveKitService.instance;

      await lk.connectToRoom(
        roomName: widget.roomId,
        userName: widget.receiverId,
        isVideo: widget.isVideo,
        serverUrl: widget.serverUrl,
      );

      if (!mounted) return;

      Navigator.of(context).pop(); // Close popup
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              CallScreen(callType: widget.isVideo ? "video" : "audio"),
        ),
      );
    } catch (e) {
      debugPrint('❌ Accept call failed: $e');
      setState(() => _isConnecting = false);
    }
  }

  // ------------------- DECLINE CALL -------------------
 void _declineCall() {
  try {
    AppSocket.instance.socket.emit('end_call', {
      'roomId': widget.roomId,
      'fromUserId': widget.receiverId, // this is the receiver who declined
      'toUserId': widget.callerId,
      'toUserIds': [widget.callerId],
    });
  } catch (e) {
    debugPrint('⚠️ Failed to emit end_call on decline: $e');
  }

  // Close popup
  Navigator.of(context).pop();
}


  @override
  Widget build(BuildContext context) {
    // ------------------- VIDEO CALL POPUP -------------------
    if (widget.isVideo) {
      return WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Row(
            children: const [
              Icon(Icons.video_call, color: Colors.deepPurple),
              SizedBox(width: 10),
              Text('Video Call'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.callerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "ID: ${widget.callerId}",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              if (_isConnecting) const CircularProgressIndicator(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _declineCall,
              child: const Text('Decline', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: _isConnecting ? null : _acceptCall,
              child: const Text('Accept'),
            ),
          ],
        ),
      );
    }

    // ------------------- AUDIO CALL POPUP -------------------
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.phone, color: Colors.green),
            SizedBox(width: 10),
            Text('Audio Call'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.callerName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "ID: ${widget.callerId}",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (_isConnecting) const CircularProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _declineCall,
            child: const Text('Decline', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: _isConnecting ? null : _acceptCall,
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}
