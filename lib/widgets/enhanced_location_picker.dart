// lib/widgets/enhanced_location_picker.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:sip_track/services/location_service.dart';
import 'package:sip_track/utils/theme.dart';

class EnhancedLocationPicker extends StatefulWidget {
  final TextEditingController controller;
  final Color accentColor;

  const EnhancedLocationPicker({
    Key? key,
    required this.controller,
    required this.accentColor,
  }) : super(key: key);

  @override
  State<EnhancedLocationPicker> createState() => _EnhancedLocationPickerState();
}

class _EnhancedLocationPickerState extends State<EnhancedLocationPicker> {
  final LocationService _locationService = LocationService();
  final FocusNode _focusNode = FocusNode();

  List<String> _savedLocations = [];
  List<String> _filteredLocations = [];
  bool _isLoadingSuggestions = false;
  bool _isLoadingCurrentLocation = false;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();

    // Show dropdown when field gets focus
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showDropdown = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLocations() async {
    try {
      final locations = await _locationService.getSavedLocations();
      setState(() {
        _savedLocations = locations;
        _filteredLocations = locations;
      });
    } catch (e) {
      print('Error loading saved locations: $e');
    }
  }

  void _filterLocations(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredLocations = _savedLocations;
      });
      return;
    }

    setState(() {
      _filteredLocations = _savedLocations
          .where((location) => location.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingCurrentLocation = true;
    });

    try {
      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _showPermissionDeniedMessage();
          setState(() {
            _isLoadingCurrentLocation = false;
          });
          return;
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      // Reverse geocode to get address
      final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locationName = _formatLocationName(place);

        // Set the location text
        widget.controller.text = locationName;

        // Save this location
        await _locationService.saveLocation(locationName);

        // Reload saved locations
        _loadSavedLocations();

        // Hide dropdown
        setState(() {
          _showDropdown = false;
        });
      }
    } catch (e) {
      print('Error getting current location: $e');
      _showErrorMessage('Could not determine your current location.');
    } finally {
      setState(() {
        _isLoadingCurrentLocation = false;
      });
    }
  }

  String _formatLocationName(Placemark place) {
    // For places like bars/restaurants, we'd ideally use the business name
    // But without Google Places API, we have to use the address components

    // Simplified version with just neighborhood/locality
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      return place.subLocality!; // e.g., "Williamsburg"
    }

    if (place.locality != null && place.locality!.isNotEmpty) {
      return place.locality!; // e.g., "Brooklyn"
    }

    // Fallback to a simple format
    if (place.street != null && place.street!.isNotEmpty) {
      return place.street!; // e.g., "Bedford Ave"
    }

    return "Current Location";
  }

  void _selectLocation(String location) {
    widget.controller.text = location;
    _locationService.saveLocation(location);
    setState(() {
      _showDropdown = false;
    });
  }

  void _showPermissionDeniedMessage() {
    _showErrorMessage('Location permission denied. Please enable location services in your device settings.');
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location text field
        CupertinoTextField(
          controller: widget.controller,
          focusNode: _focusNode,
          placeholder: 'e.g. New York, Bar name, etc.',
          placeholderStyle: const TextStyle(
            color: Color(0xFF666666),
            decoration: TextDecoration.none,
          ),
          style: const TextStyle(
            color: Colors.white,
            decoration: TextDecoration.none,
          ),
          prefix: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(
              CupertinoIcons.location,
              color: widget.accentColor,
              size: 20,
            ),
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF444444),
              width: 1,
            ),
          ),
          cursorColor: widget.accentColor,
          autocorrect: false,
          enableSuggestions: true,
          onChanged: (value) {
            _filterLocations(value);
            if (!_showDropdown) {
              setState(() {
                _showDropdown = true;
              });
            }
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _locationService.saveLocation(value);
            }
            setState(() {
              _showDropdown = false;
            });
          },
        ),

        // Current location button
        const SizedBox(height: 8),
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF444444),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.location_fill,
                  color: widget.accentColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Use Current Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (_isLoadingCurrentLocation) ...[
                  const SizedBox(width: 8),
                  const CupertinoActivityIndicator(radius: 8),
                ],
              ],
            ),
          ),
          onPressed: _isLoadingCurrentLocation ? null : _getCurrentLocation,
        ),

        // Dropdown with location suggestions
        if (_showDropdown) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF444444),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildSuggestionsList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestionsList() {
    if (_isLoadingSuggestions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    if (_filteredLocations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No saved locations match your search. Type a location name and press enter to save it.',
          style: TextStyle(
            color: Color(0xFF888888),
            fontSize: 14,
            decoration: TextDecoration.none,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _filteredLocations.length,
      itemBuilder: (context, index) {
        final location = _filteredLocations[index];
        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _selectLocation(location),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: index == _filteredLocations.length - 1
                      ? Colors.transparent
                      : const Color(0xFF444444),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.location,
                  color: Colors.grey[400],
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}