import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../services/translation_service.dart';
import '../../views/widgets/vez_glass.dart';

class VezMapPicker extends StatefulWidget {
  const VezMapPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialName,
    this.initialAddress,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialName;
  final String? initialAddress;

  @override
  State<VezMapPicker> createState() => _VezMapPickerState();
}

class _VezMapPickerState extends State<VezMapPicker> {
  static const LatLng _fallbackPoint = LatLng(45.4642, 9.1900);

  final MapController _mapController = MapController();

  late LatLng _selectedPoint;
  bool _isLoading = true;
  String _currentAddress = StringRes.at('move_map_to_select_place');
  String _currentName = '';
  int _reverseLookupToken = 0;
  Timer? _reverseLookupDebounce;

  @override
  void initState() {
    super.initState();

    _selectedPoint =
        widget.initialLatitude != null && widget.initialLongitude != null
        ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
        : _fallbackPoint;
    _currentName = widget.initialName?.trim() ?? '';
    _currentAddress = widget.initialAddress?.trim().isNotEmpty == true
        ? widget.initialAddress!.trim()
        : StringRes.at('move_map_to_select_place');

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _getAddressFromLatLng(_selectedPoint);
    } else {
      _determinePosition();
    }
  }

  @override
  void dispose() {
    _reverseLookupDebounce?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _getAddressFromLatLng(_selectedPoint);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _getAddressFromLatLng(_selectedPoint);
        return;
      }

      final Position position = await Geolocator.getCurrentPosition();
      final LatLng userPoint = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() => _selectedPoint = userPoint);
      _mapController.move(userPoint, 15.0);
      await _getAddressFromLatLng(userPoint);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    final int token = ++_reverseLookupToken;
    if (mounted) setState(() => _isLoading = true);

    try {
      final Uri uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json&lat=${position.latitude}&lon=${position.longitude}'
        '&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'VezApp/1.0 (info@vezapp.com)'},
      );

      if (!mounted || token != _reverseLookupToken) return;
      if (response.statusCode != 200) return;

      final Map<String, dynamic> data = json.decode(response.body);
      final Map<String, dynamic> address = data['address'] is Map
          ? Map<String, dynamic>.from(data['address'] as Map)
          : <String, dynamic>{};
      final String name =
          (data['name'] ??
                  address['amenity'] ??
                  address['shop'] ??
                  address['tourism'] ??
                  address['building'] ??
                  address['road'] ??
                  StringRes.at('unknown_place'))
              .toString()
              .trim();
      final String displayName =
          (data['display_name'] ?? StringRes.at('address_not_found'))
              .toString()
              .trim();

      setState(() {
        _currentName = name.isNotEmpty
            ? name
            : StringRes.at('unknown_place');
        _currentAddress = displayName.isNotEmpty
            ? displayName
            : StringRes.at('address_not_found');
      });
    } catch (_) {
      if (mounted && token == _reverseLookupToken) {
        setState(
          () => _currentAddress = StringRes.at('network_error_try_again'),
        );
      }
    } finally {
      if (mounted && token == _reverseLookupToken) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectPoint(LatLng point, {bool moveCamera = false}) {
    _reverseLookupDebounce?.cancel();
    setState(() {
      _selectedPoint = point;
      _currentAddress = StringRes.at('move_map_to_select_place');
    });

    if (moveCamera) {
      _mapController.move(point, _mapController.camera.zoom);
    }

    _reverseLookupDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _getAddressFromLatLng(point),
    );
  }

  void _confirmLocation() {
    if (_isLoading) return;

    Navigator.pop(context, {
      'name': _currentName.trim().isNotEmpty
          ? _currentName.trim()
          : StringRes.at('unknown_place'),
      'address': _currentAddress,
      'latitude': _selectedPoint.latitude,
      'longitude': _selectedPoint.longitude,
      'is_precise': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPoint,
              initialZoom: 15.0,
              onTap: (_, point) => _selectPoint(point, moveCamera: true),
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && position.center != null) {
                  setState(() => _selectedPoint = position.center!);
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _selectPoint(event.camera.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.outly.vez',
              ),
            ],
          ),
          const Center(
            child: Icon(Icons.location_on, size: 50, color: Colors.redAccent),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: VezGlass.container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _currentAddress,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: _isLoading ? null : _confirmLocation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isLoading
                            ? Colors.grey
                            : const Color.fromARGB(255, 8, 157, 13),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          StringRes.at('confirm_location'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
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
}
