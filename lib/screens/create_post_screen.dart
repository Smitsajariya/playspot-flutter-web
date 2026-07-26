import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:video_player/video_player.dart';
import '../theme/playspot_theme.dart';

class CreatePostScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onPostCreated;

  const CreatePostScreen({super.key, this.onPostCreated});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedMediaFile;
  Uint8List? _selectedMediaBytes;
  bool _isVideo = false;
  String _selectedFilter = 'Normal';
  final List<String> _filters = ['Normal', 'Grayscale', 'Sepia', 'Vintage', 'Warm', 'Cool'];
  bool _isLoading = false;
  bool _isFetchingLocation = false;

  VideoPlayerController? _videoController;
  Future<void>? _videoInitFuture;

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _setupVideoPreview(XFile video) async {
    // Dispose any previous controller before creating a new one.
    await _videoController?.dispose();
    _videoController = null;

    final controller = kIsWeb
        // On web, XFile.path for a picked video is a playable blob: URL.
        ? VideoPlayerController.networkUrl(Uri.parse(video.path))
        : VideoPlayerController.file(File(video.path));

    _videoController = controller;
    _videoInitFuture = controller.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedMediaFile = image;
          _selectedMediaBytes = bytes;
          _isVideo = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickVideo() async {
    try {
      setState(() => _isLoading = true);
      final XFile? video = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final bytes = await video.readAsBytes();
        await _setupVideoPreview(video);
        setState(() {
          _selectedMediaFile = video;
          _selectedMediaBytes = bytes;
          _isVideo = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick video: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _takePhoto() async {
    try {
      setState(() => _isLoading = true);
      final XFile? photo = await _imagePicker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _selectedMediaFile = photo;
          _selectedMediaBytes = bytes;
          _isVideo = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take photo: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0700),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFFFFF8F0)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(
            color: Color(0xFFFFF8F0),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _selectedMediaFile != null ? _sharePost : null,
            child: Text(
              'Share',
              style: TextStyle(
                color: _selectedMediaFile != null ? PSColors.gold : PSColors.inkDim,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E0700), Color(0xFF0A0500)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMediaSection(),
                    const SizedBox(height: 20),
                    if (_selectedMediaFile != null && !_isVideo) _buildFilterSection(),
                    if (_selectedMediaFile != null && !_isVideo) const SizedBox(height: 20),
                    _buildCaptionSection(),
                    const SizedBox(height: 20),
                    _buildLocationSection(),
                    const SizedBox(height: 20),
                    _buildTagSection(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: PSGradients.sportCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PSColors.gold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: _selectedMediaFile != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _isVideo
                      ? _buildVideoPreview()
                      : _selectedMediaBytes != null
                          ? ColorFiltered(
                              colorFilter: _getImageColorFilter(),
                              child: Image.memory(
                                _selectedMediaBytes!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 64,
                                      color: Color(0xFFF5A623),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 64,
                                    color: const Color(0xFFF5A623),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Tap Gallery or Camera',
                                    style: TextStyle(
                                      color: Color(0xFFFFF8F0),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'to add photo',
                                    style: TextStyle(
                                      color: Color(0x8CFFF8F0),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),
                if (_isVideo)
                  const Positioned(
                    top: 16,
                    right: 16,
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isVideo ? 'Video' : 'Photo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      _videoController?.dispose();
                      _videoController = null;
                      _videoInitFuture = null;
                      setState(() {
                        _selectedMediaFile = null;
                        _selectedMediaBytes = null;
                        _isVideo = false;
                        _selectedFilter = 'Normal';
                      });
                    },
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 64,
                    color: PSColors.gold.withOpacity(0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add media',
                    style: TextStyle(
                      color: PSColors.inkDim,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildVideoPreview() {
    final controller = _videoController;
    if (controller == null || _videoInitFuture == null) {
      return const Center(
        child: Icon(Icons.videocam, size: 64, color: Color(0xFFF5A623)),
      );
    }
    return FutureBuilder<void>(
      future: _videoInitFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || !controller.value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF5A623)),
          );
        }
        return GestureDetector(
          onTap: () {
            setState(() {
              controller.value.isPlaying ? controller.pause() : controller.play();
            });
          },
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
              if (!controller.value.isPlaying)
                const Icon(Icons.play_circle_fill, size: 56, color: Colors.white70),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCaptionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: PSGradients.sportCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PSColors.gold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _captionController,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'Write a caption...',
          hintStyle: TextStyle(color: PSColors.inkDim),
          border: InputBorder.none,
        ),
        style: const TextStyle(color: Color(0xFFFFF8F0)),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filters',
          style: TextStyle(
            color: PSColors.gold,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [PSColors.gold, PSColors.gold.withOpacity(0.8)],
                            )
                          : PSGradients.sportCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? PSColors.gold : PSColors.gold.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF140A00) : PSColors.inkDim,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: PSGradients.sportCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PSColors.gold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: PSColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Add location...',
                hintStyle: TextStyle(color: PSColors.inkDim),
                border: InputBorder.none,
              ),
              style: const TextStyle(color: Color(0xFFFFF8F0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: PSGradients.sportCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PSColors.gold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.tag, color: PSColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tag people',
              style: TextStyle(
                color: PSColors.inkDim,
                fontSize: 16,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: PSColors.inkDim),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0E0700).withOpacity(0.95),
            const Color(0xFF0E0700),
          ],
        ),
      ),
      child: Row(
        children: [
          _buildMediaOption(
            icon: Icons.photo_library,
            label: 'Gallery',
            onTap: _pickImage,
          ),
          const SizedBox(width: 12),
          _buildMediaOption(
            icon: Icons.camera_alt,
            label: 'Camera',
            onTap: _takePhoto,
          ),
          const SizedBox(width: 12),
          _buildMediaOption(
            icon: Icons.videocam,
            label: 'Video',
            onTap: _pickVideo,
          ),
          const Spacer(),
          _buildMediaOption(
            icon: Icons.location_on,
            label: 'Location',
            onTap: _isFetchingLocation ? () {} : _fetchCurrentLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: PSGradients.secondaryButton,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: PSColors.gold.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: PSColors.gold, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: PSColors.inkDim,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await Geolocator.openLocationSettings();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      String label = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [p.locality, p.administrativeArea, p.country]
              .where((s) => s != null && s.trim().isNotEmpty)
              .toList();
          if (parts.isNotEmpty) label = parts.join(', ');
        }
      } catch (e) {
        // Reverse geocoding not supported on this platform (e.g. some
        // web setups) — fall back to raw coordinates set above.
        print('Reverse geocoding failed: $e');
      }

      setState(() {
        _locationController.text = label;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _sharePost() async {
    if (_selectedMediaBytes == null && _captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add media or write a caption'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get user profile
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('ps_profile');
      final profile = profileJson != null ? jsonDecode(profileJson) : {};

      // Create post data
      final postData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': prefs.getString('ps_userId') ?? 'unknown',
        'userName': profile['name'] ?? 'Anonymous',
        'userAvatar': profile['photoUrl'] ?? '',
        'avatarUrl': profile['photoUrl'] ?? '',
        'content': _captionController.text.trim(),
        'location': _locationController.text.trim(),
        'filter': _selectedFilter,
        'isVideo': _isVideo,
        'mediaBytes': _selectedMediaBytes != null ? base64Encode(_selectedMediaBytes!) : null,
        'mediaPath': _selectedMediaFile?.path,
        'createdAt': DateTime.now().toIso8601String(),
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'isLive': false,
        'isFollowing': false,
        'category': 'General',
        'categoryEmoji': '🎯',
      };

      // Save to local storage
      List<dynamic> posts = [];
      final postsJson = prefs.getString('ps_posts');
      if (postsJson != null) {
        posts = jsonDecode(postsJson);
      }
      posts.insert(0, postData); // Add to beginning
      await prefs.setString('ps_posts', jsonEncode(posts));

      // Call callback if provided
      if (widget.onPostCreated != null) {
        widget.onPostCreated!(postData);
      }

      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post shared successfully!'),
          backgroundColor: PSColors.gold,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share post: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Returns the color + blend mode to apply for the selected filter.
  // IMPORTANT: BlendMode.modulate multiplies the image by this color,
  // so "no filter" must map to opaque WHITE (identity for multiply),
  // never Colors.transparent (alpha 0), which blacks the image out
  // entirely — that was the bug causing photos to appear blank.
  ColorFilter _getImageColorFilter() {
    switch (_selectedFilter) {
      case 'Grayscale':
        // True grayscale via a saturation matrix, not a tint.
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'Sepia':
        return ColorFilter.mode(const Color(0xFF704214).withOpacity(0.35), BlendMode.softLight);
      case 'Vintage':
        return ColorFilter.mode(const Color(0xFF8B4513).withOpacity(0.25), BlendMode.softLight);
      case 'Warm':
        return ColorFilter.mode(const Color(0xFFFFA500).withOpacity(0.2), BlendMode.softLight);
      case 'Cool':
        return ColorFilter.mode(const Color(0xFF00BFFF).withOpacity(0.2), BlendMode.softLight);
      case 'Normal':
      default:
        // Identity filter: leaves the image untouched.
        return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
    }
  }
}
