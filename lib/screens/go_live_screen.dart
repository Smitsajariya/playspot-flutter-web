import 'package:flutter/material.dart';
import '../theme/playspot_theme.dart';

class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({super.key});

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  bool _isLive = false;
  int _viewerCount = 0;
  final List<String> _comments = [
    'Great stream! 🔥',
    'Where are you playing?',
    'Love this!',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildLiveStream(),
          _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildLiveStream() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isLive ? Icons.videocam : Icons.videocam_off,
              size: 80,
              color: PSColors.gold.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              _isLive ? 'Streaming...' : 'Camera Preview',
              style: TextStyle(
                color: PSColors.inkDim,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Column(
      children: [
        _buildTopBar(),
        const Spacer(),
        _buildLiveIndicator(),
        const SizedBox(height: 20),
        _buildCommentsSection(),
        const SizedBox(height: 16),
        _buildBottomControls(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.remove_red_eye, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '$_viewerCount',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (_isLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.red, Colors.red.shade700]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 8,
                      height: 8,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => _endStream(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.withOpacity(0.9),
              Colors.red.shade700.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          _isLive ? '🔴 LIVE' : '▶️ Go Live',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Live Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '${_comments.length} comments',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: PSGradients.goldAccent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('👤', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _comments[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          _buildControlButton(
            icon: Icons.mic,
            onTap: () {},
          ),
          const Spacer(),
          _buildLiveButton(),
          const Spacer(),
          _buildControlButton(
            icon: Icons.flash_on,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          _buildControlButton(
            icon: Icons.camera_alt,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildLiveButton() {
    return GestureDetector(
      onTap: _toggleLive,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          gradient: _isLive
              ? LinearGradient(colors: [Colors.red.shade700, Colors.red])
              : PSGradients.primaryButton,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: (_isLive ? Colors.red : PSColors.gold).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          _isLive ? Icons.stop : Icons.videocam,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  void _toggleLive() {
    setState(() {
      _isLive = !_isLive;
      if (_isLive) {
        _viewerCount = 1;
        _startViewerSimulation();
      } else {
        _viewerCount = 0;
      }
    });
  }

  void _startViewerSimulation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (_isLive && mounted) {
        setState(() {
          _viewerCount += (DateTime.now().millisecond % 3);
        });
        return _isLive;
      }
      return false;
    });
  }

  void _endStream() {
    if (_isLive) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: PSColors.surface2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'End Stream?',
            style: TextStyle(color: Color(0xFFFFF8F0)),
          ),
          content: const Text(
            'Are you sure you want to end your live stream?',
            style: TextStyle(color: Color(0xFFFFF8F0)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('End Stream'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }
}
