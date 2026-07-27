import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../theme/playspot_theme.dart';
import '../services/geocoding_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.initialAddress,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final MapController _mapController = MapController();
  LatLng? _centerLocation; // Tracks the center of the map
  
  // Manual input controllers
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  
  // Map Pin search controllers
  final TextEditingController _mapSearchController = TextEditingController();
  
  // State
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = false;
  String? _errorMessage;
  List<Location> _searchResults = [];
  String? _mapSearchError;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedLocation = widget.initialLocation;
    _selectedAddress = widget.initialAddress;
    _centerLocation = widget.initialLocation;
    
    if (_selectedLocation != null) {
      _mapController.move(_selectedLocation!, 15);
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _mapSearchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await Geolocator.openLocationSettings();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Fallback to default location if permission denied
          setState(() {
            _selectedLocation = const LatLng(20.5937, 78.9629);
          });
          _mapController.move(_selectedLocation!, 5);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      _mapController.move(_selectedLocation!, 15);
      await _reverseGeocode(_selectedLocation!);
    } catch (e) {
      print('Error getting location: $e');
      // Fallback to default location on error
      setState(() {
        _selectedLocation = const LatLng(20.5937, 78.9629);
      });
      _mapController.move(_selectedLocation!, 5);
    }
  }

  Future<void> _searchAddress() async {
    final cityText = _cityController.text.trim();
    final pincodeText = _pincodeController.text.trim();
    
    if (cityText.isEmpty && pincodeText.isEmpty) {
      setState(() => _errorMessage = 'Please enter at least city or pincode');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String address = _buildAddressString();
      print('Searching for address: $address');
      List<LatLng> locations = await GeocodingService.forwardGeocode(address);
      print('Found ${locations.length} locations');
      
      if (locations.isNotEmpty) {
        setState(() {
          _searchResults = locations.map((latLng) => Location(latLng.latitude, latLng.longitude)).toList();
          _selectedLocation = locations.first;
          _errorMessage = null;
        });
        
        await _reverseGeocode(_selectedLocation!);
      } else {
        setState(() {
          _errorMessage = 'Address not found. Please check your input.';
          _searchResults = [];
        });
      }
    } catch (e) {
      print('Error searching address: $e');
      setState(() {
        _errorMessage = 'Error searching address: ${e.toString()}';
        _searchResults = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchMapLocation() async {
    final searchText = _mapSearchController.text.trim();
    if (searchText.isEmpty) {
      setState(() => _mapSearchError = 'Please enter a city or city+pincode');
      return;
    }

    setState(() {
      _isLoading = true;
      _mapSearchError = null;
    });

    try {
      List<LatLng> locations = await GeocodingService.forwardGeocode(searchText);
      
      if (locations.isNotEmpty) {
        final newLocation = locations.first;
        setState(() {
          _selectedLocation = newLocation;
          _mapSearchError = null;
        });
        
        // Animate map to the new location
        _mapController.move(newLocation, 15);
        
        await _reverseGeocode(newLocation);
      } else {
        setState(() {
          _mapSearchError = 'Couldn\'t find that area, try adjusting the pincode or drop the pin manually';
        });
      }
    } catch (e) {
      setState(() {
        _mapSearchError = 'Couldn\'t find that area, try adjusting the pincode or drop the pin manually';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _buildAddressString() {
    List<String> parts = [];
    if (_streetController.text.trim().isNotEmpty) {
      parts.add(_streetController.text.trim());
    }
    if (_cityController.text.trim().isNotEmpty) {
      parts.add(_cityController.text.trim());
    }
    if (_pincodeController.text.trim().isNotEmpty) {
      parts.add(_pincodeController.text.trim());
    }
    return parts.join(', ');
  }

  Future<void> _reverseGeocode(LatLng location) async {
    try {
      String address = await GeocodingService.reverseGeocode(
        location.latitude,
        location.longitude,
      );
      setState(() {
        _selectedAddress = address;
      });
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
  }

  void _confirmLocation() {
    if (_selectedLocation == null) {
      setState(() => _errorMessage = 'Please select a location');
      return;
    }
    
    Navigator.pop(context, {
      'location': _selectedLocation,
      'address': _selectedAddress ?? 'Selected location',
    });
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Location',
          style: TextStyle(
            color: Color(0xFFFFF8F0),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: PSColors.gold,
          unselectedLabelColor: PSColors.inkDim,
          indicatorColor: PSColors.gold,
          tabs: const [
            Tab(text: 'Manual Input', icon: Icon(Icons.edit_location)),
            Tab(text: 'Map Pin', icon: Icon(Icons.map)),
          ],
        ),
      ),
      body: _tabController != null
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildManualInputTab(),
                _buildMapPinTab(),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0700),
          border: Border(
            top: BorderSide(color: PSColors.border),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedAddress != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: PSColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PSColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: PSColors.gold, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedAddress!,
                          style: const TextStyle(
                            color: Color(0xFFFFF8F0),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _confirmLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PSColors.gold,
                    foregroundColor: const Color(0xFF140A00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Confirm Location',
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
      ),
    );
  }

  Widget _buildManualInputTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Address Details',
            style: TextStyle(
              color: Color(0xFFFFF8F0),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pincode is required for validation',
            style: TextStyle(
              color: PSColors.inkDim,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildTextField(
            controller: _streetController,
            label: 'Street Address',
            hint: '123 Main Street',
            icon: Icons.streetview,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _cityController,
            label: 'City',
            hint: 'New York',
            icon: Icons.location_city,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _pincodeController,
            label: 'Pincode *',
            hint: '10001',
            icon: Icons.pin,
            required: true,
          ),
          const SizedBox(height: 24),
          
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _searchAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: PSColors.gold,
                foregroundColor: const Color(0xFF140A00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF140A00)),
                      ),
                    )
                  : const Text(
                      'Search Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Search Results',
              style: TextStyle(
                color: Color(0xFFFFF8F0),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._searchResults.asMap().entries.map((entry) {
              int index = entry.key;
              Location location = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PSColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PSColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: PSColors.gold, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Result ${index + 1}',
                            style: const TextStyle(
                              color: Color(0xFFFFF8F0),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              color: PSColors.inkDim,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: PSColors.gold),
                      onPressed: () async {
                        setState(() {
                          _selectedLocation = LatLng(location.latitude, location.longitude);
                        });
                        await _reverseGeocode(_selectedLocation!);
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: PSColors.gold, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFFF8F0),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: PSColors.inkDim),
            filled: true,
            fillColor: PSColors.surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: PSColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: PSColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: PSColors.gold),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: const TextStyle(color: Color(0xFFFFF8F0), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildMapPinTab() {
    return Column(
      children: [
        // Search bar at the top
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0700),
            border: Border(
              bottom: BorderSide(color: PSColors.border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mapSearchController,
                      style: const TextStyle(color: Color(0xFFFFF8F0), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search city or city+pincode (e.g., Berlin 14055)',
                        hintStyle: TextStyle(color: PSColors.inkDim, fontSize: 13),
                        filled: true,
                        fillColor: PSColors.surface2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: PSColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: PSColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: PSColors.gold),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixIcon: const Icon(Icons.search, color: PSColors.gold, size: 20),
                      ),
                      onSubmitted: (_) => _searchMapLocation(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _searchMapLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PSColors.gold,
                        foregroundColor: const Color(0xFF140A00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
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
                          : const Icon(Icons.search, size: 20),
                    ),
                  ),
                ],
              ),
              if (_mapSearchError != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _mapSearchError!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Map
        Expanded(
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation ?? const LatLng(20.5937, 78.9629),
                    initialZoom: _selectedLocation != null ? 15 : 5,
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) {
                        // Update center location when map stops moving
                        setState(() {
                          _centerLocation = event.camera.center;
                          _selectedLocation = event.camera.center;
                        });
                        _reverseGeocode(event.camera.center);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.playspot_flutter',
                      maxZoom: 18,
                    ),
                    // Fixed center pin
                    const Center(
                      child: Icon(
                        Icons.location_on,
                        size: 50,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              // Current location button
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: PSColors.gold,
                  onPressed: _getCurrentLocation,
                  child: const Icon(Icons.my_location, color: Color(0xFF140A00)),
                ),
              ),
              // Address overlay
              if (_selectedAddress != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E0700).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: PSColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: PSColors.gold, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedAddress!,
                            style: const TextStyle(
                              color: Color(0xFFFFF8F0),
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
