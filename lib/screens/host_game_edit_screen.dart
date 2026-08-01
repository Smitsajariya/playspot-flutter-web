import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../socket_service.dart';
import '../theme/playspot_theme.dart';
import 'chat_screen.dart';

class HostGameEditScreen extends StatefulWidget {
  final String gameId;
  const HostGameEditScreen({super.key, required this.gameId});

  @override
  State<HostGameEditScreen> createState() => _HostGameEditScreenState();
}

class _HostGameEditScreenState extends State<HostGameEditScreen> {
  final SocketService _socketService = SocketService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  Map<String, dynamic>? _game;
  int _maxPlayers = 10;
  DateTime? _selectedDateTime;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    // First try to load from local storage
    final prefs = await SharedPreferences.getInstance();
    final createdGamesJson = prefs.getString('ps_created_games');
    
    if (createdGamesJson != null) {
      final createdGames = jsonDecode(createdGamesJson) as List<dynamic>;
      final game = createdGames.firstWhere(
        (g) => g['id'] == widget.gameId,
        orElse: () => null,
      );
      if (game != null) {
        _populateGame(game);
        return;
      }
    }

    // If not found locally, fetch from socket service
    _socketService.connect();
    _socketService.getGames((games) {
      final game = games.firstWhere(
        (g) => g['id'] == widget.gameId,
        orElse: () => null,
      );
      if (game != null) {
        _populateGame(game);
      }
    });
  }

  void _populateGame(Map<String, dynamic> game) {
    setState(() {
      _game = game;
      _titleController.text = game['title'] ?? '';
      _descriptionController.text = game['description'] ?? '';
      _maxPlayers = game['maxPlayers'] ?? 10;
      if (game['scheduledFor'] != null) {
        _selectedDateTime = DateTime.parse(game['scheduledFor']);
      }
      _isLoading = false;
    });
  }

  Future<void> _selectDateTime() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: _selectedDateTime != null
            ? TimeOfDay(hour: _selectedDateTime!.hour, minute: _selectedDateTime!.minute)
            : TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _saveChanges() {
    if (_game == null) return;
    
    setState(() => _isSaving = true);

    final updates = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'maxPlayers': _maxPlayers,
      if (_selectedDateTime != null)
        'scheduledFor': _selectedDateTime!.toIso8601String(),
    };

    _socketService.updateGame(widget.gameId, updates, (response) {
      setState(() => _isSaving = false);
      
      if (response['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Game updated successfully!'),
            backgroundColor: PSColors.gold,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response['error'] ?? 'Failed to update game'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _cancelGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0C00),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Game',
          style: TextStyle(color: Color(0xFFFFF8F0)),
        ),
        content: const Text(
          'Are you sure you want to cancel this game? This will count toward your cancellation limit.',
          style: TextStyle(color: Color(0x8CFFF8F0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'No',
              style: TextStyle(color: Color(0xFFF5A623)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performCancel();
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Color(0xFFFF4D1C)),
            ),
          ),
        ],
      ),
    );
  }

  void _performCancel() {
    if (_game == null) return;
    
    final userId = _game!['hostUserId']?.toString();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Missing user ID')),
      );
      return;
    }

    _socketService.cancelGame(widget.gameId, userId, (response) {
      if (response['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Game cancelled successfully'),
            backgroundColor: PSColors.gold,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response['error'] ?? 'Failed to cancel game'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _messagePlayers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(gameId: widget.gameId),
      ),
    );
  }

  String _getSportEmoji(String sport) {
    final emojis = {
      'football': '⚽',
      'cricket': '🏏',
      'basketball': '🏀',
      'badminton': '🏸',
      'volleyball': '🏐',
      'tennis': '🎾',
      'running': '🏃',
      'cycling': '🚴',
      'frisbee': '🥏',
      'hockey': '🏑',
      'kabaddi': '🤼',
    };
    return emojis[sport] ?? '🎯';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E0700),
        body: const Center(
          child: CircularProgressIndicator(color: PSColors.gold),
        ),
      );
    }

    if (_game == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E0700),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0E0700),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFFFF8F0)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text(
            'Game not found',
            style: TextStyle(color: Color(0xFFFFF8F0)),
          ),
        ),
      );
    }

    final sport = _game!['sport'] ?? 'unknown';
    final sportEmoji = _getSportEmoji(sport);
    final players = _game!['players'] is List 
        ? (_game!['players'] as List).length 
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0700),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0700),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFF8F0)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Game',
          style: TextStyle(
            color: Color(0xFFFFF8F0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Read-only game details
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: PSGradients.sportCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: PSColors.gold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        sportEmoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _game!['title'] ?? 'Game',
                              style: const TextStyle(
                                color: Color(0xFFFFF8F0),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$sportEmoji ${sport[0].toUpperCase()}${sport.substring(1)} · $players/${_maxPlayers} players',
                              style: const TextStyle(
                                color: Color(0xFFF5A623),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildReadOnlyField('Location', _game!['location'] ?? 'Not set'),
                  _buildReadOnlyField('Skill Level', _game!['skillLevel'] ?? 'any'),
                  if (_selectedDateTime != null)
                    _buildReadOnlyField('Date & Time', _selectedDateTime.toString().substring(0, 16)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Edit section
            const Text(
              'Edit Details',
              style: TextStyle(
                color: PSColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            _buildEditField(
              controller: _titleController,
              label: 'Title',
              icon: Icons.title,
            ),
            const SizedBox(height: 16),

            // Description
            _buildEditField(
              controller: _descriptionController,
              label: 'Description',
              icon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Date/time picker
            _buildDateTimePicker(),
            const SizedBox(height: 16),

            // Max players dropdown
            _buildMaxPlayersDropdown(),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: PSColors.gold,
                foregroundColor: const Color(0xFF140A00),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF140A00)),
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _messagePlayers,
                    icon: const Icon(Icons.chat),
                    label: const Text('Message Players'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A0C00),
                      foregroundColor: PSColors.gold,
                      side: const BorderSide(color: PSColors.gold),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _cancelGame,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel Game'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0x8CFFF8F0),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFFF8F0),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: PSGradients.sportCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PSColors.gold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: PSColors.inkDim),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          prefixIcon: Icon(icon, color: PSColors.gold),
        ),
        style: const TextStyle(color: Color(0xFFFFF8F0)),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return GestureDetector(
      onTap: _selectDateTime,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: PSGradients.sportCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: PSColors.gold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: PSColors.gold, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _selectedDateTime != null
                    ? _selectedDateTime.toString().substring(0, 16)
                    : 'Select date and time',
                style: TextStyle(
                  color: _selectedDateTime != null ? PSColors.ink : PSColors.inkDim,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaxPlayersDropdown() {
    return Container(
      decoration: BoxDecoration(
        gradient: PSGradients.sportCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PSColors.gold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _maxPlayers,
            dropdownColor: PSColors.surface2,
            style: const TextStyle(color: PSColors.ink),
            items: List.generate(19, (index) => index + 2).map((value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('Max Players: $value'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _maxPlayers = value ?? 10),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
