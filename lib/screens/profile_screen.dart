import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/playspot_theme.dart';

class ProfileScreen extends StatefulWidget {
  final bool isFirstTimeSetup;

  const ProfileScreen({super.key, this.isFirstTimeSetup = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isGoogleVerified = false;
  bool _isLoading = false;
  String? _photoUrl;
  String? _googleEmail;
  bool _isPrivateAccount = false;
  bool _allowMessagesFromAll = true;
  bool _showOnMap = true;
  List<String> _selectedInterests = [];
  // Drives the skill-matching nudge when joining games (map_screen.dart) —
  // 'any' means "don't warn me", otherwise it's compared against a game's
  // skillLevel before joining.
  String _skillLevel = 'intermediate';

  static const List<Map<String, String>> _skillLevelOptions = [
    {'id': 'beginner', 'emoji': '🌱', 'label': 'Beginner'},
    {'id': 'intermediate', 'emoji': '⚡', 'label': 'Intermediate'},
    {'id': 'advanced', 'emoji': '🔥', 'label': 'Advanced'},
  ];

  // Chip options offered on the interests picker — sports + play-style tags.
  static const List<Map<String, String>> _interestOptions = [
    {'id': 'football', 'emoji': '⚽', 'label': 'Football'},
    {'id': 'basketball', 'emoji': '🏀', 'label': 'Basketball'},
    {'id': 'tennis', 'emoji': '🎾', 'label': 'Tennis'},
    {'id': 'badminton', 'emoji': '🏸', 'label': 'Badminton'},
    {'id': 'volleyball', 'emoji': '🏐', 'label': 'Volleyball'},
    {'id': 'cricket', 'emoji': '🏏', 'label': 'Cricket'},
    {'id': 'running', 'emoji': '🏃', 'label': 'Running'},
    {'id': 'cycling', 'emoji': '🚴', 'label': 'Cycling'},
    {'id': 'beginner_friendly', 'emoji': '🌱', 'label': 'Beginner Friendly'},
    {'id': 'competitive', 'emoji': '🔥', 'label': 'Competitive'},
    {'id': 'casual', 'emoji': '😎', 'label': 'Casual'},
  ];

  /// Profile completion, 0.0–1.0, driven by which fields are actually filled.
  /// Mirrors the "% complete" ring pattern — each field is worth an equal share.
  double get _profileCompletion {
    final fields = <bool>[
      _photoUrl != null && _photoUrl!.isNotEmpty,
      _nameController.text.trim().isNotEmpty,
      _bioController.text.trim().isNotEmpty,
      _selectedInterests.isNotEmpty,
      _isGoogleVerified,
    ];
    final filled = fields.where((f) => f).length;
    return filled / fields.length;
  }

  int get _profileCompletionPercent => (_profileCompletion * 100).round();

  @override
  void initState() {
    super.initState();
    _checkGoogleSignIn();
    _loadProfile();
  }

  Future<void> _checkGoogleSignIn() async {
    final account = await _googleSignIn.signInSilently();
    if (account != null) {
      setState(() {
        _isGoogleVerified = true;
        _googleEmail = account.email;
        _nameController.text = account.displayName ?? '';
        _photoUrl = account.photoUrl;
      });
      await _saveProfile(showConfirmation: false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        final idToken = await account.authentication.then((auth) => auth.idToken);
        
        // Try to verify with backend, but don't fail if it doesn't work
        bool backendVerified = false;
        try {
          final response = await http.post(
            Uri.parse('https://playspot-backend.onrender.com/api/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'credential': idToken}),
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['ok'] && data['emailVerified']) {
              backendVerified = true;
            }
          }
        } catch (e) {
          print('Backend verification failed: $e');
          // Continue anyway - accept Google sign-in locally
        }

        setState(() {
          _isGoogleVerified = true;
          _googleEmail = account.email;
          _nameController.text = account.displayName?.trim() ?? '';
          _photoUrl = account.photoUrl;
        });

        // Auto-save immediately so the real photo/name is available
        // right away to other screens (e.g. map marker), instead of
        // only being saved when the user manually taps "Save".
        await _saveProfile(showConfirmation: false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(backendVerified 
                ? 'Google verified successfully' 
                : 'Signed in with Google (local mode)'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePhotoSelect() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (kIsWeb) {
          // Web: use data URL directly
          final bytes = await image.readAsBytes();
          final base64Str = base64Encode(bytes);
          setState(() => _photoUrl = 'data:image/jpeg;base64,$base64Str');
        } else {
          // Mobile: upload photo
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('https://playspot-backend.onrender.com/api/upload-photo'),
          );
          request.files.add(await http.MultipartFile.fromPath('photo', image.path));
          
          final response = await request.send();
          if (response.statusCode == 200) {
            final data = jsonDecode(await response.stream.bytesToString());
            if (data['ok']) {
              setState(() => _photoUrl = data['url']);
            }
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo selection failed: $e')),
      );
    }
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('ps_profile');
      
      if (profileJson != null) {
        final profile = jsonDecode(profileJson);
        setState(() {
          _nameController.text = profile['name'] ?? '';
          _photoUrl = profile['photoUrl'];
          _isPrivateAccount = profile['isPrivateAccount'] ?? false;
          _allowMessagesFromAll = profile['allowMessagesFromAll'] ?? true;
          _showOnMap = profile['showOnMap'] ?? true;
          _bioController.text = profile['bio'] ?? '';
          _selectedInterests = (profile['interests'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          _skillLevel = profile['skillLevel'] ?? 'intermediate';
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  Future<void> _saveProfile({bool showConfirmation = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('ps_userId');
      
      final profile = {
        'name': _nameController.text.trim(),
        'email': _googleEmail ?? '',
        'photoUrl': _photoUrl,
        'isGoogleVerified': _isGoogleVerified,
        'isPrivateAccount': _isPrivateAccount,
        'allowMessagesFromAll': _allowMessagesFromAll,
        'showOnMap': _showOnMap,
        'bio': _bioController.text.trim(),
        'interests': _selectedInterests,
        'skillLevel': _skillLevel,
      };

      // Save to SharedPreferences
      await prefs.setString('ps_profile', jsonEncode(profile));

      // Mock backend call for web/localhost testing
      if (kDebugMode) {
        print('Mock profile save: ${jsonEncode({...profile, 'userId': userId})}');
      } else {
        // Send to backend in background (don't await, don't block navigation)
        http.post(
          Uri.parse('https://playspot-backend.onrender.com/api/profile'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({...profile, 'userId': userId}),
        ).catchError((e) {
          print('Backend profile save failed (CORS expected on localhost): $e');
          return http.Response('Error', 500);
        });
      }

      if (showConfirmation && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Color(0xFFF5A623),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Profile save error: $e');
      if (showConfirmation && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile save failed: $e')),
        );
      }
    }
  }

  Future<void> _submitProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _saveProfile();

      // Navigate immediately
      if (mounted) {
        context.go('/home');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFirstTimeSetup) {
      return _buildOnboardingUI(context);
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.go('/home');
                        }
                      },
                      icon: const Icon(Icons.arrow_back, color: Color(0xFFF5A623)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'PlaySpot',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                    color: Color(0xFFF5A623),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Avatar upload, wrapped in a profile-completion ring
                Center(
                  child: SizedBox(
                    width: 132,
                    height: 132,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!widget.isFirstTimeSetup)
                          SizedBox(
                            width: 132,
                            height: 132,
                            child: CircularProgressIndicator(
                              value: _profileCompletion,
                              strokeWidth: 4,
                              backgroundColor: PSColors.surface2,
                              valueColor: const AlwaysStoppedAnimation<Color>(PSColors.gold),
                            ),
                          ),
                        GestureDetector(
                          onTap: _handlePhotoSelect,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1A0C00),
                              border: Border.all(color: const Color(0xFFF5A623), width: 2),
                            ),
                            child: _photoUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      _photoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.camera_alt, size: 40, color: Color(0xFFF5A623));
                                      },
                                    ),
                                  )
                                : const Icon(Icons.camera_alt, size: 40, color: Color(0xFFF5A623)),
                          ),
                        ),
                        if (!widget.isFirstTimeSetup)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: PSColors.bg,
                                borderRadius: BorderRadius.circular(PSRadius.full),
                                border: Border.all(color: PSColors.gold, width: 1),
                              ),
                              child: Text(
                                '$_profileCompletionPercent%',
                                style: const TextStyle(
                                  color: PSColors.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (!widget.isFirstTimeSetup) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: _shareProfile,
                      icon: const Icon(Icons.share, size: 16, color: PSColors.gold),
                      label: const Text(
                        'Share Profile',
                        style: TextStyle(color: PSColors.gold, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                
                if (!_isGoogleVerified)
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Sign in with Google'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() => _isGoogleVerified = true);
                        },
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(
                            color: Color(0x8CFFF8F0),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                
                // Name field
                TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    filled: true,
                    fillColor: const Color(0xFF1A0C00),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF5A623)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF5A623)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF5A623), width: 2),
                    ),
                  ),
                  style: const TextStyle(color: Color(0xFFFFF8F0)),
                ),
                const SizedBox(height: 24),

                // Bio + Interests - only show if NOT first-time setup, to keep onboarding short
                if (!widget.isFirstTimeSetup) ...[
                  const Text(
                    'About Me',
                    style: TextStyle(color: PSColors.gold, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    onChanged: (_) => setState(() {}),
                    maxLines: 3,
                    maxLength: 150,
                    decoration: InputDecoration(
                      hintText: 'Easygoing player who loves 5-a-side and a good rally...',
                      hintStyle: const TextStyle(color: Color(0x8CFFF8F0), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF1A0C00),
                      counterStyle: const TextStyle(color: Color(0x8CFFF8F0), fontSize: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF5A623)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF5A623)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF5A623), width: 2),
                      ),
                    ),
                    style: const TextStyle(color: Color(0xFFFFF8F0)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Interests',
                    style: TextStyle(color: PSColors.gold, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _interestOptions.map((option) {
                      final id = option['id']!;
                      final isSelected = _selectedInterests.contains(id);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            _selectedInterests.remove(id);
                          } else {
                            _selectedInterests.add(id);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? PSColors.gold.withOpacity(0.15) : PSColors.surface,
                            borderRadius: BorderRadius.circular(PSRadius.full),
                            border: Border.all(
                              color: isSelected ? PSColors.gold : PSColors.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${option['emoji']} ${option['label']}',
                            style: TextStyle(
                              color: isSelected ? PSColors.gold : PSColors.inkDim,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'My Skill Level',
                    style: TextStyle(color: PSColors.gold, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Used to nudge you before joining games above your level',
                    style: TextStyle(color: Color(0x8CFFF8F0), fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _skillLevelOptions.map((option) {
                      final id = option['id']!;
                      final isSelected = _skillLevel == id;
                      return GestureDetector(
                        onTap: () => setState(() => _skillLevel = id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? PSColors.gold.withOpacity(0.15) : PSColors.surface,
                            borderRadius: BorderRadius.circular(PSRadius.full),
                            border: Border.all(
                              color: isSelected ? PSColors.gold : PSColors.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${option['emoji']} ${option['label']}',
                            style: TextStyle(
                              color: isSelected ? PSColors.gold : PSColors.inkDim,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Privacy settings - only show if NOT first-time setup
                if (!widget.isFirstTimeSetup)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0C00),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF5A623).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text(
                            'Private Account',
                            style: TextStyle(color: Color(0xFFFFF8F0)),
                          ),
                          subtitle: const Text(
                            'Only approved followers see your posts',
                            style: TextStyle(color: Color(0x8CFFF8F0), fontSize: 12),
                          ),
                          activeColor: const Color(0xFFF5A623),
                          value: _isPrivateAccount,
                          onChanged: (val) => setState(() => _isPrivateAccount = val),
                        ),
                        SwitchListTile(
                          title: const Text(
                            'Allow Messages From Everyone',
                            style: TextStyle(color: Color(0xFFFFF8F0)),
                          ),
                          activeColor: const Color(0xFFF5A623),
                          value: _allowMessagesFromAll,
                          onChanged: (val) => setState(() => _allowMessagesFromAll = val),
                        ),
                        SwitchListTile(
                          title: const Text(
                            'Show My Location on Map',
                            style: TextStyle(color: Color(0xFFFFF8F0)),
                          ),
                          subtitle: const Text(
                            'Others can see you on the map',
                            style: TextStyle(color: Color(0x8CFFF8F0), fontSize: 12),
                          ),
                          activeColor: const Color(0xFFF5A623),
                          value: _showOnMap,
                          onChanged: (val) => setState(() => _showOnMap = val),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: widget.isFirstTimeSetup ? 32 : 24),
                
                // Save button - only show if NOT first-time setup
                if (!widget.isFirstTimeSetup)
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: (_nameController.text.trim().isEmpty && !_isGoogleVerified) || _isLoading
                            ? null
                            : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5A623),
                          foregroundColor: const Color(0xFF140A00),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF140A00)),
                                ),
                              )
                            : const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                
                // Continue button
                ElevatedButton(
                  onPressed: (_nameController.text.trim().isEmpty || _isLoading)
                      ? null
                      : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: const Color(0xFFF5A623),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFF5A623)),
                    ),
                  ),
                  child: Text(
                    widget.isFirstTimeSetup ? 'Continue' : 'Done',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// First-time-setup screen: full-bleed hero photo with a frosted glass
  /// card floating over the bottom, matching the target design.
  Widget _buildOnboardingUI(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background hero photo
          Image.asset(
            'assets/branding/onboarding_hero.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF0E0700)),
          ),
          // Gradient scrim so text/card stay readable over the photo
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x991A0C00),
                  Color(0x001A0C00),
                  Color(0x001A0C00),
                  Color(0xE60E0700),
                ],
                stops: [0.0, 0.25, 0.55, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Create your profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w800,
                      fontSize: 32,
                      height: 1.15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 260),

                  // Frosted glass card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                        decoration: BoxDecoration(
                          color: const Color(0x59140A00), // ~0.35 opacity
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Add photo
                            GestureDetector(
                              onTap: _handlePhotoSelect,
                              child: Column(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                      ),
                                    ),
                                    child: _photoUrl != null
                                        ? ClipOval(
                                            child: Image.network(
                                              _photoUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                Icons.camera_alt_outlined,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt_outlined,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _photoUrl != null ? 'Change photo' : 'Add photo',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Continue with Google
                            if (!_isGoogleVerified)
                              SizedBox(
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const _GoogleGlyph(),
                                  label: const Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.92),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle, color: Color(0xFFF5A623), size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      _googleEmail ?? 'Signed in with Google',
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 20),

                            const Text(
                              'Or enter your name',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _nameController,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              cursorColor: const Color(0xFFF5A623),
                              decoration: InputDecoration(
                                hintText: 'Name',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                                isDense: true,
                                border: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white30),
                                ),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white30),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFFF5A623), width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Continue button
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: (_nameController.text.trim().isEmpty || _isLoading)
                                    ? null
                                    : _submitProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF5A623),
                                  disabledBackgroundColor: const Color(0xFFF5A623).withOpacity(0.35),
                                  foregroundColor: const Color(0xFF140A00),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF140A00)),
                                        ),
                                      )
                                    : const Text(
                                        'Continue  →',
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _shareProfile() {
    final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Check out my profile';
    final interestsLine = _selectedInterests.isNotEmpty
        ? '\n${_selectedInterests.map((id) {
            final match = _interestOptions.firstWhere(
              (o) => o['id'] == id,
              orElse: () => {'emoji': '', 'label': id},
            );
            return '${match['emoji']} ${match['label']}';
          }).join('  ')}'
        : '';
    Share.share(
      '$name is on PlaySpot 🏆$interestsLine\n\nJoin the game on PlaySpot!',
      subject: '$name on PlaySpot',
    );
  }
}

/// Small inline "G" glyph so we don't need an extra asset for the Google button.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 18,
        color: Color(0xFF4285F4),
      ),
    );
  }
}
