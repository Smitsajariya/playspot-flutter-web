import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/chat_models.dart';
import '../socket_service.dart';
import 'group_chat_screen.dart';

class PublicGroupsScreen extends StatefulWidget {
  const PublicGroupsScreen({super.key});

  @override
  State<PublicGroupsScreen> createState() => _PublicGroupsScreenState();
}

class _PublicGroupsScreenState extends State<PublicGroupsScreen> {
  final SocketService _socketService = SocketService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ChatGroup> _groups = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _socketService.connect();
    _searchPublicGroups('');
  }

  void _searchPublicGroups(String query) {
    setState(() => _isLoading = true);
    _socketService.searchPublicGroups(query, (groups) {
      if (mounted) {
        setState(() {
          _groups = groups.map((g) => ChatGroup.fromJson(g)).toList();
          _isLoading = false;
        });
      }
    });
  }

  void _joinGroup(ChatGroup group) {
    _socketService.joinPublicGroup(group.id, (response) {
      if (response['ok']) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupChatScreen(
              groupId: group.id,
              groupName: group.name,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join: ${response['error'] ?? 'Unknown error'}')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0700),
        elevation: 0,
        title: const Text(
          'Discover Groups',
          style: TextStyle(
            color: Color(0xFFFFF8F0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search groups worldwide...',
                hintStyle: const TextStyle(color: Color(0x47FFF8F0)),
                filled: true,
                fillColor: const Color(0xFF1A0C00),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFFF5A623),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFFF5A623)),
                        onPressed: () {
                          _searchController.clear();
                          _searchPublicGroups('');
                        },
                      )
                    : null,
              ),
              style: const TextStyle(color: Color(0xFFFFF8F0)),
              onChanged: (value) {
                _searchQuery = value;
                _searchPublicGroups(value);
              },
            ),
          ),
          // Groups list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF5A623)),
                  )
                : _groups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: const Color(0x47FFF8F0),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No groups found',
                              style: TextStyle(
                                color: Color(0x47FFF8F0),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try a different search term',
                              style: TextStyle(
                                color: Color(0x47FFF8F0),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          return _buildGroupCard(group);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(ChatGroup group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A0C00),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFFF5A623).withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Group photo
                CircleAvatar(
                  radius: 32,
                  backgroundImage: group.photo != null
                      ? CachedNetworkImageProvider(group.photo!)
                      : null,
                  child: group.photo == null
                      ? const Icon(Icons.group, size: 32, color: Color(0xFFF5A623))
                      : null,
                ),
                const SizedBox(width: 12),
                // Group info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              style: const TextStyle(
                                color: Color(0xFFFFF8F0),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (group.isEventGroup)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5A623).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF5A623)),
                              ),
                              child: const Text(
                                'EVENT',
                                style: TextStyle(
                                  color: Color(0xFFF5A623),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.people, size: 14, color: Color(0x8CFFF8F0)),
                          const SizedBox(width: 4),
                          Text(
                            '${group.memberCount} members',
                            style: const TextStyle(
                              color: Color(0x8CFFF8F0),
                              fontSize: 12,
                            ),
                          ),
                          if (group.maxParticipants != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              '/ ${group.maxParticipants}',
                              style: const TextStyle(
                                color: Color(0x8CFFF8F0),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (group.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                group.description,
                style: const TextStyle(
                  color: Color(0x8CFFF8F0),
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (group.announcement != null && group.announcement!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF5A623).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.announcement, size: 14, color: Color(0xFFF5A623)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        group.announcement!,
                        style: const TextStyle(
                          color: Color(0xFFF5A623),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Join button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _joinGroup(group),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  foregroundColor: const Color(0xFF140A00),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Join Group',
                  style: TextStyle(
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
    _searchController.dispose();
    super.dispose();
  }
}
