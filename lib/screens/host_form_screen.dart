import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import '../socket_service.dart';
import '../screens/ingame_screen.dart';
import '../screens/location_picker_screen.dart';
import '../utils/sport_icons.dart';
import '../theme/playspot_theme.dart';
import '../services/notification_service.dart';

class HostFormScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedActivity;
  const HostFormScreen({super.key, this.selectedActivity});

  @override
  State<HostFormScreen> createState() => _HostFormScreenState();
}

class _HostFormScreenState extends State<HostFormScreen> {
  final SocketService _socketService = SocketService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _ticketPriceController = TextEditingController();
  
  int _maxPlayers = 10;
  DateTime? _selectedDateTime;
  String _skillLevel = 'any';
  String _recurrence = 'none'; // none | weekly | biweekly
  bool _isLoading = false;
  bool _isPaidEvent = false;
  double? _lat;
  double? _lng;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (kIsWeb) {
      // Web: use browser geolocation API
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _lat = position.latitude;
          _lng = position.longitude;
        });
      } catch (e) {
        print('Error getting location on web: $e');
      }
    } else {
      // Mobile: use geolocator
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _lat = position.latitude;
          _lng = position.longitude;
        });
      } catch (e) {
        print('Error getting location: $e');
      }
    }
  }

  Future<void> _selectDateTime() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
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

  Future<void> _submitGame() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a game title')),
      );
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location')),
      );
      return;
    }
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
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

      final gameData = {
        'name': profile['name'] ?? 'Player',
        'sport': widget.selectedActivity?['id'] ?? 'football',
        'category': widget.selectedActivity?['categoryId'] ?? 'sports',
        'title': _titleController.text.trim(),
        'description': _notesController.text.trim(),
        'location': _locationController.text.trim(),
        'maxPlayers': _maxPlayers,
        'skillLevel': _skillLevel,
        'userId': userId,
        'lat': _lat,
        'lng': _lng,
        'photoUrl': profile['photoUrl'] ?? '',
        'isPaidEvent': _isPaidEvent,
        'ticketPrice': _isPaidEvent ? double.tryParse(_ticketPriceController.text) ?? 0 : 0,
        // Was captured via _selectDateTime() but never sent before — needed
        // for the map's date-strip filter (Phase 2).
        'scheduledFor': _selectedDateTime?.toIso8601String(),
        // Recurring games: PlaySpot's backend doesn't materialize future
        // instances yet (no cron/scheduler), so this just carries the rule
        // through for whenever that's wired server-side. In the meantime
        // we persist it locally (see below) and confirm the next
        // occurrence to the host immediately.
        'recurrence': _recurrence == 'none'
            ? null
            : {
                'freq': _recurrence,
                'weekday': _selectedDateTime?.weekday,
                'time': _selectedDateTime != null
                    ? '${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}'
                    : null,
              },
      };

      _socketService.createGame(gameData, (response) async {
        setState(() => _isLoading = false);
        
        if (response['ok']) {
          final gameId = response['game']['id'];
          prefs.setString('ps_gameId', gameId);
          
          // Save created game to local storage for visibility
          final createdGame = {
            ...gameData,
            'id': gameId,
            'createdAt': DateTime.now().toIso8601String(),
            'players': 1,
          };
          
          List<dynamic> createdGames = [];
          final createdGamesJson = prefs.getString('ps_created_games');
          if (createdGamesJson != null) {
            createdGames = jsonDecode(createdGamesJson);
          }
          createdGames.add(createdGame);
          await prefs.setString('ps_created_games', jsonEncode(createdGames));

          if (_recurrence != 'none') {
            List<dynamic> recurringGames = [];
            final recurringJson = prefs.getString('ps_recurring_games');
            if (recurringJson != null) recurringGames = jsonDecode(recurringJson);
            recurringGames.add({'gameId': gameId, 'title': _titleController.text.trim(), ...gameData['recurrence'] as Map});
            await prefs.setString('ps_recurring_games', jsonEncode(recurringGames));

            await NotificationService().add(NotificationItem(
              id: 'recurrence_set_${gameId}_${DateTime.now().millisecondsSinceEpoch}',
              type: PSNotificationType.gameActivity,
              title: 'Standing game set up 🔁',
              body: "${_titleController.text.trim()} repeats $_recurrence — we'll remind you before each one.",
              emoji: '🔁',
              timestamp: DateTime.now(),
              groupId: gameId,
              groupName: _titleController.text.trim(),
            ));
          }
          
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => IngameScreen(gameId: gameId),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'] ?? 'Failed to create game')),
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
            if (widget.selectedActivity != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: PSGradients.goldAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.selectedActivity?['icon'] ?? '🎮',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              'Host ${widget.selectedActivity?['name'] ?? 'Game'}',
              style: const TextStyle(
                color: Color(0xFFFFF8F0),
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E0700), Color(0xFF0A0500)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Game title
              _buildStyledTextField(
                controller: _titleController,
                hintText: 'Game title',
                icon: Icons.title,
              ),
              const SizedBox(height: 20),

              // Location picker
              _buildLocationPicker(),
              const SizedBox(height: 20),

              // Max players dropdown
              _buildStyledDropdown(
                value: _maxPlayers,
                items: List.generate(19, (index) => index + 2),
                onChanged: (value) => setState(() => _maxPlayers = value ?? 10),
                label: 'Max Players',
              ),
              const SizedBox(height: 20),

              // Date/time picker
              _buildDateTimePicker(),
              const SizedBox(height: 20),

              // Skill level selector
              _buildSkillLevelSelector(),
              const SizedBox(height: 20),

              // Recurring games — "every Tuesday 6pm" instead of one-off only
              _buildRecurrenceSelector(),
              const SizedBox(height: 20),

              // Notes (optional)
              _buildStyledTextField(
                controller: _notesController,
                hintText: 'Notes (optional)',
                icon: Icons.note,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Ticket pricing
              _buildTicketPricingSection(),
              const SizedBox(height: 32),

              // Submit button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hintText,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: PSColors.inkDim),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          prefixIcon: Icon(icon, color: PSColors.gold),
        ),
        style: const TextStyle(color: PSColors.ink),
      ),
    );
  }

  Widget _buildStyledDropdown<T>({
    required T value,
    required List<T> items,
    required Function(T?) onChanged,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: PSGradients.sportCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PSColors.gold.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            dropdownColor: PSColors.surface2,
            style: const TextStyle(color: PSColors.ink),
            items: items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text('$label: $item'),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
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

  Widget _buildSkillLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skill Level',
          style: TextStyle(
            color: PSColors.gold,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSkillButton('Beginner', 'beginner'),
            const SizedBox(width: 12),
            _buildSkillButton('Any', 'any'),
            const SizedBox(width: 12),
            _buildSkillButton('Pro', 'advanced'),
          ],
        ),
      ],
    );
  }

  Widget _buildTicketPricingSection() {
    return Container(
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
              Checkbox(
                value: _isPaidEvent,
                onChanged: (value) => setState(() => _isPaidEvent = value ?? false),
                activeColor: PSColors.gold,
                checkColor: const Color(0xFF140A00),
              ),
              Text(
                'This is a paid event',
                style: TextStyle(
                  color: PSColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_isPaidEvent) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _ticketPriceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Ticket price',
                prefixText: '\$ ',
                hintStyle: TextStyle(color: PSColors.inkDim),
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(color: PSColors.ink, fontSize: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationPicker() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocationPickerScreen(
              initialLocation: _lat != null && _lng != null
                  ? LatLng(_lat!, _lng!)
                  : null,
              initialAddress: _selectedAddress,
            ),
          ),
        );
        
        if (result != null) {
          setState(() {
            _lat = result['location'].latitude;
            _lng = result['location'].longitude;
            _selectedAddress = result['address'];
            _locationController.text = _selectedAddress ?? '';
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
                Icon(Icons.location_on, color: PSColors.gold, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Location',
                  style: TextStyle(
                    color: Color(0xFFFFF8F0),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, color: PSColors.inkDim, size: 16),
              ],
            ),
            if (_selectedAddress != null) ...[
              const SizedBox(height: 8),
              Text(
                _selectedAddress!,
                style: TextStyle(
                  color: PSColors.inkDim,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Tap to select location',
                style: TextStyle(
                  color: PSColors.inkDim,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: PSGradients.primaryButton,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: PSColors.gold.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF140A00),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF140A00)),
                ),
              )
            : const Text(
                'Drop pin & go live',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildRecurrenceSelector() {
    const options = [
      {'label': 'One-time', 'value': 'none'},
      {'label': 'Weekly', 'value': 'weekly'},
      {'label': 'Bi-weekly', 'value': 'biweekly'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repeat',
          style: TextStyle(color: PSColors.gold, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          _selectedDateTime == null
              ? 'Pick a date/time above to enable repeats'
              : 'Repeats on the same weekday & time',
          style: const TextStyle(color: Color(0x8CFFF8F0), fontSize: 12),
        ),
        const SizedBox(height: 12),
        Row(
          children: options.map((opt) {
            final value = opt['value']!;
            final isSelected = _recurrence == value;
            final enabled = _selectedDateTime != null || value == 'none';
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: value != options.last['value'] ? 12 : 0),
                child: GestureDetector(
                  onTap: enabled ? () => setState(() => _recurrence = value) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: isSelected ? PSGradients.primaryButton : PSGradients.secondaryButton,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? PSColors.gold : PSColors.gold.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Opacity(
                      opacity: enabled ? 1 : 0.4,
                      child: Text(
                        opt['label']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF140A00) : PSColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSkillButton(String label, String value) {
    final isSelected = _skillLevel == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _skillLevel = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected ? PSGradients.primaryButton : PSGradients.secondaryButton,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? PSColors.gold : PSColors.gold.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: PSColors.gold.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFF140A00) : PSColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
