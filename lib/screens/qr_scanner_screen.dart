import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../socket_service.dart';

class QRScannerScreen extends StatefulWidget {
  final String gameId;
  const QRScannerScreen({super.key, required this.gameId});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final SocketService _socketService = SocketService();
  bool _isScanning = true;
  String? _scannedCode;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _socketService.connect();
  }

  Future<void> _verifyPlayer(String playerId) async {
    // Verify player with backend - TODO: implement in SocketService
    // For now, just simulate verification
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isVerified = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildPlaceholder(),
          ),
          if (_scannedCode != null)
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF0E0700),
              child: Column(
                children: [
                  Icon(
                    _isVerified ? Icons.check_circle : Icons.error,
                    color: _isVerified ? Colors.green : Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isVerified ? 'Player Verified!' : 'Verification Failed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Code: $_scannedCode',
                    style: const TextStyle(color: Color(0x8CFFF8F0)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _scannedCode = null;
                        _isVerified = false;
                        _isScanning = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A623),
                      foregroundColor: const Color(0xFF140A00),
                    ),
                    child: const Text('Scan Another'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'QR scanning temporarily unavailable',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
