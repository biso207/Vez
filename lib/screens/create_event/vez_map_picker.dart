// Developed and Designed by Outly • © 2026
// OSM Map Picker per selezionare la posizione precisa dell'evento

// TODO: improve UI

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../models/vez_glass.dart';
import '../../services/translation_service.dart';

class VezMapPicker extends StatefulWidget {
  const VezMapPicker({super.key});

  @override
  State<VezMapPicker> createState() => _VezMapPickerState();
}

class _VezMapPickerState extends State<VezMapPicker> {
  final MapController _mapController = MapController();
  LatLng _centerPoint = const LatLng(45.4642, 9.1900); // Default: Milano (puoi usare la posizione dell'utente se la hai)
  bool _isLoading = false;
  String _currentAddress = StringRes.at('move_map_to_select_place');
  String _currentName = "";

  @override
  void initState() {
    super.initState();
    _determinePosition(); // Cerca il GPS appena entri
  }

  // find the user position thanks to the GPS
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se i servizi di localizzazione sono abilitati
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      return; // Resta su Milano se il GPS è spento
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    // Prendi la posizione attuale
    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      _centerPoint = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });

    // Sposta la telecamera della mappa sulla tua posizione
    _mapController.move(_centerPoint, 15.0);

    // Recupera l'indirizzo del punto trovato
    _getAddressFromLatLng(_centerPoint);
  }

  // Chiama Nominatim (OSM) per tradurre le coordinate in indirizzo
  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isLoading = true);
    try {
      // Nominatim richiede un User-Agent valido per non bloccarti
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1'),
        headers: {'User-Agent': 'VezApp/1.0 (info@vezapp.com)'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // Se ha un nome proprio (es. "Pizzeria Da Michele") prende quello, altrimenti usa la via
          _currentName = data['name'] ?? data['address']['road'] ?? StringRes.at('unknown_place');
          _currentAddress = data['display_name'] ?? StringRes.at('address_not_found');
        });
      }
    } catch (e) {
      setState(() => _currentAddress = StringRes.at('network_error_try_again'));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmLocation() {
    if (_currentAddress == StringRes.at('move_map_to_select_place') || _currentAddress.isEmpty) return;

    // Ritorna i dati strutturati al CreateEvent screen
    Navigator.pop(context, {
      'name': _currentName,
      'address': _currentAddress,
      'latitude': _centerPoint.latitude,
      'longitude': _centerPoint.longitude,
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
          icon: const Icon(Icons.arrow_back, color: Colors.black87), // Colore scuro per leggibilità sulla mappa chiara
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. LA MAPPA OSM
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centerPoint, // if GPS works, is the user position
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && position.center != null) {
                  setState(() => _centerPoint = position.center!);
                }
              },
              onMapEvent: (event) {
                // Quando l'utente smette di muovere la mappa, fetchiamo l'indirizzo
                if (event is MapEventMoveEnd) {
                  _getAddressFromLatLng(_centerPoint);
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

          // 2. IL PIN CENTRALE FISSO
          const Center(
            child: Icon(Icons.location_on, size: 50, color: Colors.redAccent),
          ),

          // 3. LA CARD IN BASSO (Vez Glass Style)
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
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
                        color: _isLoading ? Colors.grey : const Color.fromARGB(255, 8, 157, 13), // Il tuo verde
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(StringRes.at('confirm_location'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
