// lib/screens/incoming_call_screen.dart
import 'package:flutter/material.dart';
import '../services/livekit_service.dart';
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

  Future<void> _acceptCall() async {
    setState(() => _isConnecting = true);

    try {
      // 1) fetch token from backend
      final token = await LiveKitService.instance.fetchToken(
        userId: widget.userId,
        roomId: widget.roomId,
      );

      // 2) connect using server URL + token
      await LiveKitService.instance.connectToRoom(
        serverUrl: widget.serverUrl,
        token: token,
        isVideo: widget.isVideo,
      );

      debugPrint('✅ Receiver joined LiveKit room');

      if (!mounted) return;

      // 3) close the incoming-call dialog before navigating
      Navigator.of(context).pop();

      // 4) open call screen (CallScreen reads LiveKitService.instance.room)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            callType: widget.isVideo ? "video" : "audio",
          ),
        ),
      );
    } catch (err, st) {
      debugPrint('❌ Failed to join call: $err\n$st');

      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to join call")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleIcon = widget.isVideo ? Icons.video_call : Icons.phone;
    final titleText = widget.isVideo ? 'Video Call' : 'Audio Call';
    final titleColor = widget.isVideo ? Colors.deepPurple : Colors.green;

    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(titleIcon, color: titleColor),
            const SizedBox(width: 10),
            Text(titleText),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.callerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text("ID: ${widget.callerId}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            if (_isConnecting) const CircularProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
