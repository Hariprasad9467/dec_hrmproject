// lib/services/livekit_service.dart
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../main.dart';


const String livekitUrl = "wss://hrm-rjvaayq4.livekit.cloud";  // optional fallback

class LiveKitService with ChangeNotifier {
  LiveKitService._internal();
  static final LiveKitService instance = LiveKitService._internal();

  Room? _room;
  Room? get room => _room;

  bool _isVideoCall = false;
  bool get isVideoCall => _isVideoCall;

  GlobalKey<NavigatorState>? navigatorKey;
  void setNavigatorKey(GlobalKey<NavigatorState> key) => navigatorKey = key;

  // -------------------------
  // Public token fetch (simple)
  // -------------------------
  Future<String> fetchToken({
    required String userId,
    required String roomId,
  }) async {
    final url = Uri.parse('$apiBaseUrl/api/get-livekit-token');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identity': userId, 'roomName': roomId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch token: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data == null || data['token'] == null) {
      throw Exception('Invalid token response');
    }

    return data['token'] as String;
  }

  // -------------------------
  // (Legacy internal) kept for backward compatibility
  // -------------------------
  Future<String?> _fetchLiveKitToken({
    required String roomName,
    required String identity,
  }) async {
    if (roomName.isEmpty || identity.isEmpty) {
      debugPrint('❌ Room name or identity cannot be empty.');
      return null;
    }

    final url = Uri.parse('$apiBaseUrl/api/get-livekit-token');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'roomName': roomName, 'identity': identity}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final token = data['token'];
        if (token != null && token is String && token.isNotEmpty) {
          return token;
        }
      }
      debugPrint('❌ Failed to fetch token: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching token: $e');
    }
    return null;
  }

  // -------------------------
  // Connect to LiveKit using serverUrl + token
  // -------------------------
  Future<void> connectToRoom({
    required String serverUrl,
    required String token,
    required bool isVideo,
  }) async {
    try {
      final options = const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
       // autoSubscribe: true,
      );

      _room = Room(roomOptions: options);

      await _room!.connect(serverUrl, token);
      _isVideoCall = isVideo;

      // enable microphone and camera according to isVideo
      await _room!.localParticipant?.setMicrophoneEnabled(true);
      if (isVideo) {
        await _room!.localParticipant?.setCameraEnabled(true);
      } else {
        await _room!.localParticipant?.setCameraEnabled(false);
      }

      debugPrint("✅ Connected to LiveKit room successfully.");
      notifyListeners();
    } catch (e, st) {
      debugPrint("❌ Error connecting to LiveKit: $e\n$st");
      rethrow;
    }
  }

  // -------------------------
  // Toggle mic (wrapper)
  // -------------------------
  Future<void> toggleMic() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;

    try {
      await lp.setMicrophoneEnabled(!lp.isMicrophoneEnabled());
    } catch (e) {
      debugPrint('⚠️ toggleMic API difference: $e');
    }
    notifyListeners();
  }

  // -------------------------
  // Toggle camera (wrapper)
  // -------------------------
  Future<void> toggleCamera() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;

    final currentlyEnabled = lp.isCameraEnabled();
    final shouldEnable = !currentlyEnabled;

    try {
      await lp.setCameraEnabled(shouldEnable);
    } catch (e) {
      debugPrint('⚠️ setCameraEnabled API difference: $e');
    }

    if (!shouldEnable) {
      try {
        final pubs = lp.videoTrackPublications ?? [];
        for (final pub in pubs) {
          try {
            await (pub as dynamic).mute();
          } catch (_) {
            try {
              await (pub as dynamic).setMuted(true);
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('⚠️ Could not mute local video publications on camera toggle: $e');
      }
    }

    notifyListeners();
  }

  // -------------------------
  // Disconnect
  // -------------------------
  Future<void> disconnect() async {
    if (_room != null) {
      try {
        await _room!.disconnect();
      } catch (e) {
        debugPrint('⚠️ disconnect threw: $e');
      }
      _room = null;
      debugPrint('✅ Disconnected from LiveKit room');
    }
    notifyListeners();
  }

  // -------------------------
  // Remote participants
  // -------------------------
  List<RemoteParticipant> get remoteParticipants =>
      _room?.remoteParticipants.values.toList() ?? [];
}
