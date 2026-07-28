import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as native_geocoding;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  static Future<String> reverseGeocode(double lat, double lng) async {
    if (kIsWeb) {
      return await _reverseGeocodeWeb(lat, lng);
    } else {
      return await _reverseGeocodeNative(lat, lng);
    }
  }

  static Future<List<LatLng>> forwardGeocode(String address) async {
    if (kIsWeb) {
      return await _forwardGeocodeWeb(address);
    } else {
      return await _forwardGeocodeNative(address);
    }
  }

  static Future<String> _reverseGeocodeWeb(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng'),
        headers: {
          'User-Agent': 'PlaySpot-Flutter-App',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['address'] != null) {
          final address = data['address'];
          List<String> parts = [];
          
          if (address['road'] != null) parts.add(address['road']);
          if (address['suburb'] != null) parts.add(address['suburb']);
          if (address['city'] != null || address['town'] != null || address['village'] != null) {
            parts.add(address['city'] ?? address['town'] ?? address['village']);
          }
          if (address['state'] != null) parts.add(address['state']);
          if (address['postcode'] != null) parts.add(address['postcode']);
          if (address['country'] != null) parts.add(address['country']);
          
          return parts.isNotEmpty ? parts.join(', ') : 'Selected location';
        }
      }
      return 'Selected location';
    } catch (e) {
      print('Web reverse geocoding error: $e');
      return 'Selected location';
    }
  }

  static Future<List<LatLng>> _forwardGeocodeWeb(String address) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(address)}'),
        headers: {
          'User-Agent': 'PlaySpot-Flutter-App',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((result) => LatLng(
          double.parse(result['lat']),
          double.parse(result['lon']),
        )).toList();
      }
      return [];
    } catch (e) {
      print('Web forward geocoding error: $e');
      return [];
    }
  }

  static Future<String> _reverseGeocodeNative(double lat, double lng) async {
    try {
      List<native_geocoding.Placemark> placemarks = await native_geocoding.placemarkFromCoordinates(
        lat,
        lng,
      );
      
      if (placemarks.isNotEmpty) {
        native_geocoding.Placemark place = placemarks.first;
        List<String> parts = [];
        if (place.street?.isNotEmpty == true) parts.add(place.street!);
        if (place.subLocality?.isNotEmpty == true) parts.add(place.subLocality!);
        if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
        if (place.administrativeArea?.isNotEmpty == true) parts.add(place.administrativeArea!);
        if (place.postalCode?.isNotEmpty == true) parts.add(place.postalCode!);
        if (place.country?.isNotEmpty == true) parts.add(place.country!);
        
        return parts.isNotEmpty ? parts.join(', ') : 'Selected location';
      }
      return 'Selected location';
    } catch (e) {
      print('Native reverse geocoding error: $e');
      return 'Selected location';
    }
  }

  static Future<List<LatLng>> _forwardGeocodeNative(String address) async {
    try {
      List<native_geocoding.Location> locations = await native_geocoding.locationFromAddress(address);
      return locations.map((location) => LatLng(location.latitude, location.longitude)).toList();
    } catch (e) {
      print('Native forward geocoding error: $e');
      return [];
    }
  }
}
