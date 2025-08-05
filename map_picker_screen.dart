// lib/screens/map_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // Initial camera position (e.g., Hyderabad)
  static const LatLng _initialCenter = LatLng(17.448294, 78.391487);
  
  // This will hold the location the user picks
  LatLng? _pickedLocation;

  void _selectLocation(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Your Location'),
        actions: [
          // Show a "confirm" checkmark button only if a location has been picked
          if (_pickedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                // Return the selected LatLng object to the previous screen
                Navigator.of(context).pop(_pickedLocation);
              },
            ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _initialCenter, zoom: 11),
            // When the user taps the map, call our _selectLocation function
            onTap: _selectLocation,
            // Display a marker at the picked location
            markers: (_pickedLocation == null)
                ? {} // If no location is picked, show no markers
                : {
                    Marker(
                      markerId: const MarkerId('picked_location_marker'),
                      position: _pickedLocation!,
                    ),
                  },
          ),
          // A helpful instruction text overlay
          if (_pickedLocation == null)
            Positioned(
              top: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Tap on the map to place a pin',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          // A floating "Confirm" button at the bottom
          if (_pickedLocation != null)
            Positioned(
              bottom: 30,
              left: 30,
              right: 30,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Confirm This Location'),
                onPressed: () {
                   // Return the selected LatLng object to the previous screen
                   Navigator.of(context).pop(_pickedLocation);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}