import 'package:flutter/material.dart';
import '../socket_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final SocketService _socketService = SocketService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _announcementController = TextEditingController();
  
  bool _isPublic = false;
  bool _isSearchable = true;
  bool _isEventGroup = false;
  bool _isLoading = false;
  int? _maxParticipants;
  String? _eventId;

  @override
  void initState() {
    super.initState();
    _socketService.connect();
  }

  void _createGroup() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    _socketService.createGroup(
      name: name,
      description: _descriptionController.text.trim(),
      announcement: _announcementController.text.trim(),
      isPublic: _isPublic,
      isSearchable: _isSearchable,
      isEventGroup: _isEventGroup,
      eventId: _eventId,
      maxParticipants: _maxParticipants,
      callback: (response) {
        setState(() => _isLoading = false);
        if (response['ok']) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group created successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create group: ${response['error'] ?? 'Unknown error'}')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0700),
        elevation: 0,
        title: const Text(
          'Create Group',
          style: TextStyle(
            color: Color(0xFFFFF8F0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group photo
            Center(
              child: GestureDetector(
                onTap: () {
                  // TODO: Add photo picker
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0C00),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF5A623), width: 2),
                  ),
                  child: const Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: Color(0xFFF5A623),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Group name
            const Text(
              'Group Name',
              style: TextStyle(
                color: Color(0xFFF5A623),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter group name',
                hintStyle: const TextStyle(color: Color(0x47FFF8F0)),
                filled: true,
                fillColor: const Color(0xFF1A0C00),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Color(0xFFFFF8F0)),
            ),
            const SizedBox(height: 16),
            
            // Description
            const Text(
              'Description',
              style: TextStyle(
                color: Color(0xFFF5A623),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'What is this group about?',
                hintStyle: const TextStyle(color: Color(0x47FFF8F0)),
                filled: true,
                fillColor: const Color(0xFF1A0C00),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Color(0xFFFFF8F0)),
            ),
            const SizedBox(height: 16),
            
            // Announcement
            const Text(
              'Announcement (Optional)',
              style: TextStyle(
                color: Color(0xFFF5A623),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _announcementController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Important announcement for group members',
                hintStyle: const TextStyle(color: Color(0x47FFF8F0)),
                filled: true,
                fillColor: const Color(0xFF1A0C00),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Color(0xFFFFF8F0)),
            ),
            const SizedBox(height: 16),
            
            // Event Group toggle
            SwitchListTile(
              title: const Text(
                'Event Group',
                style: TextStyle(color: Color(0xFFFFF8F0)),
              ),
              subtitle: const Text(
                'Private group for event participants only',
                style: TextStyle(color: Color(0x8CFFF8F0), fontSize: 12),
              ),
              value: _isEventGroup,
              onChanged: (value) => setState(() => _isEventGroup = value),
              activeColor: const Color(0xFFF5A623),
            ),
            
            // Max participants (for event groups)
            if (_isEventGroup)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Max participants (optional)',
                    hintStyle: const TextStyle(color: Color(0x47FFF8F0)),
                    filled: true,
                    fillColor: const Color(0xFF1A0C00),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Color(0xFFFFF8F0)),
                  onChanged: (value) {
                    _maxParticipants = int.tryParse(value);
                  },
                ),
              ),
            
            // Public/Private toggle
            SwitchListTile(
              title: const Text(
                'Public Group',
                style: TextStyle(color: Color(0xFFFFF8F0)),
              ),
              subtitle: const Text(
                'Anyone can discover and join this group',
                style: TextStyle(color: Color(0x8CFFF8F0), fontSize: 12),
              ),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
              activeColor: const Color(0xFFF5A623),
            ),
            
            // Searchable toggle (for public groups)
            if (_isPublic)
              SwitchListTile(
                title: const Text(
                  'Searchable',
                  style: TextStyle(color: Color(0xFFFFF8F0)),
                ),
                subtitle: const Text(
                  'Group appears in worldwide search results',
                  style: TextStyle(color: Color(0x8CFFF8F0), fontSize: 12),
                ),
                value: _isSearchable,
                onChanged: (value) => setState(() => _isSearchable = value),
                activeColor: const Color(0xFFF5A623),
              ),
            const SizedBox(height: 24),
            
            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  foregroundColor: const Color(0xFF140A00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF140A00))
                    : const Text(
                        'Create Group',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _announcementController.dispose();
    super.dispose();
  }
}
