import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../socket_service.dart';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final SocketService _socketService = SocketService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  String _category = 'culture';
  DateTime? _selectedDate;
  bool _isLoading = false;
  String? _photoUrl;

  final List<String> _categories = [
    'music', 'art', 'food', 'sports', 'tech', 'social', 'culture', 'fitness'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0700),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFF8F0)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            _getCategoryIcon(_category, size: 32),
            const SizedBox(width: 12),
            const Text(
              'Create Event',
              style: TextStyle(
                color: Color(0xFFFFF8F0),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo upload
            GestureDetector(
              onTap: _handlePhotoSelect,
              child: Container(
                width: double.infinity,
                height: 148,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0C00),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF5A623)),
                ),
                child: _photoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholder(),
                        ),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Event title',
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
            const SizedBox(height: 16),

            // Category selector
            const Text(
              'Category',
              style: TextStyle(
                color: Color(0xFFF5A623),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF5A623) : const Color(0xFF1A0C00),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFF5A623) : const Color(0x1AFFB93C),
                      ),
                    ),
                    child: Text(
                      '${_getCategoryEmoji(cat)} ${cat.toUpperCase()}',
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF140A00) : const Color(0xFFFFF8F0),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Location
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Location',
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
            const SizedBox(height: 16),

            // Date picker
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0C00),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF5A623)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFFF5A623)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate != null
                            ? _selectedDate.toString().substring(0, 10)
                            : 'Select date',
                        style: const TextStyle(color: Color(0xFFFFF8F0)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Description (optional)',
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
            const SizedBox(height: 32),

            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitEvent,
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
                  : const Text(
                      'Create Event',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 48, color: Color(0xFFF5A623)),
          SizedBox(height: 8),
          Text(
            'Add photo',
            style: TextStyle(color: Color(0x8CFFF8F0)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handlePhotoSelect() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          final base64Str = base64Encode(bytes);
          setState(() => _photoUrl = 'data:image/jpeg;base64,$base64Str');
        } else {
          // Mobile: upload to backend
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

  Future<void> _submitEvent() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an event title')),
      );
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location')),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('ps_userId');
      final profileJson = prefs.getString('ps_profile');
      final profile = profileJson != null 
          ? Map<String, dynamic>.from(
              jsonDecode(profileJson) as Map
            )
          : {};

      final eventData = {
        'title': _titleController.text.trim(),
        'category': _category,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'date': _selectedDate.toString().substring(0, 10),
        'userId': userId,
        'photoUrl': _photoUrl,
        'hostName': profile['name'] ?? 'Host',
      };

      _socketService.createEvent(eventData, (response) {
        setState(() => _isLoading = false);
        
        if (response['ok']) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'] ?? 'Failed to create event')),
          );
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _getCategoryIcon(String category, {double size = 24}) {
    final iconMap = {
      'music': Icons.music_note,
      'art': Icons.palette,
      'food': Icons.restaurant,
      'sports': Icons.sports_soccer,
      'tech': Icons.computer,
      'social': Icons.people,
      'culture': Icons.museum,
      'fitness': Icons.fitness_center,
    };
    final icon = iconMap[category] ?? Icons.event;
    return Icon(icon, size: size, color: const Color(0xFFF5A623));
  }

  String _getCategoryEmoji(String category) {
    final emojis = {
      'music': '🎵',
      'art': '🎨',
      'food': '🍔',
      'sports': '⚽',
      'tech': '💻',
      'social': '🎉',
      'culture': '🏛️',
      'fitness': '🏋️',
    };
    return emojis[category] ?? '📅';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
