import 'dart:async';
import 'dart:io'; // <-- [FIX 1] ADD THIS IMPORT
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  _ShareScreenState createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  HttpServer? _server; // <-- [FIX 2] CHANGED THE TYPE from 'shelf.HttpServer'

  bool _isSharing = false;
  String _serverUrl = 'Not running';

  // WebRTC objects for peer connection
  RTCPeerConnection? _peerConnection;
  final _rtcConfig = <String, dynamic>{
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'}, // Google's public STUN server
    ],
  };

  @override
  void initState() {
    super.initState();
    _localRenderer.initialize();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _localStream?.getTracks().forEach((track) => track.stop());
    _peerConnection?.close();
    _server?.close(force: true);
    super.dispose();
  }

  Future<void> _toggleSharing() async {
    if (_isSharing) {
      // Stop sharing
      await _stopSharing();
    } else {
      // Start sharing
      await _startSharing();
    }
  }

  Future<void> _startSharing() async {
    try {
      // 1. Get screen sharing stream
      _localStream = await navigator.mediaDevices.getDisplayMedia({
        'video': true,
        'audio': false, // Audio sharing is more complex, let's start with video
      });

      // Update the local video renderer to show a preview
      _localRenderer.srcObject = _localStream;

      // 2. Start the web server
      await _startServer();

      setState(() {
        _isSharing = true;
      });
    } catch (e) {
      debugPrint('Error starting sharing: $e');
      setState(() {
        _serverUrl = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _stopSharing() async {
    try {
      // Stop all video tracks
      _localStream?.getTracks().forEach((track) {
        track.stop();
      });
      _localStream = null;

      // Close the server
      await _server?.close(force: true);
      _server = null;

      // Close any active peer connection
      await _peerConnection?.close();
      _peerConnection = null;

      // Clear the video preview
      _localRenderer.srcObject = null;

      setState(() {
        _isSharing = false;
        _serverUrl = 'Not running';
      });
    } catch (e) {
      debugPrint('Error stopping sharing: $e');
    }
  }

  // --- Web Server Logic ---

  Future<void> _startServer() async {
    final router = shelf_router.Router();

    // This endpoint is called by the browser to start the WebRTC connection
    router.post('/offer', _handleOffer);

    // This endpoint serves the simple HTML viewer page
    router.get('/', (shelf.Request request) {
      return shelf.Response.ok(
        _htmlViewerPage, // HTML code is defined at the bottom
        headers: {'Content-Type': 'text/html'},
      );
    });

    // Start the server on port 8080 (you can change this)
    // We bind to '0.0.0.0' to make it accessible on the local network
    final server = await shelf_io.serve(router, '0.0.0.0', 8080);
    _server = server;

    // NOTE: FlutLab's environment might be tricky for getting the *local* IP.
    // In a real device, you would get the IP.
    // For now, we'll just state the port.
    setState(() {
      _serverUrl = 'Running at http://[YOUR_PHONE_IP]:8080';
    });
  }

  // --- WebRTC Server Handlers ---

  Future<shelf.Response> _handleOffer(shelf.Request request) async {
    final body = await request.readAsString();
    final offer = RTCSessionDescription(body, 'offer');

    // 1. Create a new peer connection
    _peerConnection = await createPeerConnection(_rtcConfig);

    // 2. Add the screen stream tracks to the connection
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    // 3. Set the "offer" from the browser as the remote description
    await _peerConnection!.setRemoteDescription(offer);

    // 4. Create an "answer" to send back
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    // 5. Send the answer back to the browser
    return shelf.Response.ok(
      answer.sdp,
      headers: {'Content-Type': 'application/sdp'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Screen Sharer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video preview window
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black54,
                border: Border.all(color: Colors.grey),
              ),
              child: _localRenderer.srcObject != null
                  ? RTCVideoView(_localRenderer, mirror: false)
                  : const Center(
                      child: Text('Screen preview will appear here'),
                    ),
            ),
            const SizedBox(height: 20),

            // Start/Stop Button
            ElevatedButton(
              onPressed: _toggleSharing,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSharing ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                _isSharing ? 'Stop Sharing' : 'Start Sharing',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 30),

            // Server status info
            const Text(
              'Share URL:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                // Changed to SelectableText
                _serverUrl,
                style: const TextStyle(fontSize: 16, letterSpacing: 1.1),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Type this URL into any browser on the SAME Wi-Fi network.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // This is the HTML page that will be served to the PC's browser
  final String _htmlViewerPage = '''
  <html>
    <head>
      <title>Screen Viewer</title>
      <style>
        body { background-color: #333; color: white; font-family: sans-serif; }
        video { width: 100%; max-width: 1200px; display: block; margin: 20px auto; background-color: black; }
        h1 { text-align: center; }
      </style>
    </head>
    <body>
      <h1>Viewing Screen</h1>
      <video id="video" autoplay playsinline></video>
      <script>
        // This Javascript runs in the browser
        const pc = new RTCPeerConnection({
          iceServers: [{ urls: 'stun:stun.l.google.com:19302' }]
        });

        // This function starts the connection
        async function startConnection() {
          try {
            // 1. Create an "offer"
            const offer = await pc.createOffer();
            await pc.setLocalDescription(offer);

            // 2. Send the offer to the Flutter app's server
            const response = await fetch('/offer', {
              method: 'POST',
              headers: { 'Content-Type': 'application/sdp' },
              body: offer.sdp
            });

            // 3. Get the "answer" back from the Flutter app
            const answerSdp = await response.text();
            await pc.setRemoteDescription(new RTCSessionDescription({ type: 'answer', sdp: answerSdp }));

          } catch (err) {
            console.error(err);
            alert('Failed to connect');
          }
        }

        // When the PC receives the video stream, add it to the <video> tag
        pc.ontrack = (event) => {
          document.getElementById('video').srcObject = event.streams[0];
        };

        // Start the whole process when the page loads
        window.onload = startConnection;
      </script>
    </body>
  </html>
  ''';
}
