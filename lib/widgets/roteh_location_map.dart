import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ROTEH CAMBODIA office — exact coordinates from Google Maps, no geocoding
// round-trip needed (and no risk of a bad address-search match).
const kRotehAddress = 'ROTEH CAMBODIA, ផ្លូវលេខ6A, Phnom Penh';
const kRotehPin = LatLng(11.647847, 104.9147521);

/// Embedded non-interactive map showing the ROTEH CAMBODIA pickup location.
/// If [pin] is provided (product-specific coordinates) it takes priority.
/// Otherwise defaults to the ROTEH CAMBODIA office.
class RotehLocationMap extends StatefulWidget {
  final LatLng? pin;
  final String? addressLabel;
  const RotehLocationMap({super.key, this.pin, this.addressLabel});

  @override
  State<RotehLocationMap> createState() => _RotehLocationMapState();
}

class _RotehLocationMapState extends State<RotehLocationMap> {
  GoogleMapController? _ctrl;
  late final LatLng _resolved = widget.pin ?? kRotehPin;

  static const _green = Color(0xFF00C48C);

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _openGoogleMaps() async {
    final pin = _resolved;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${pin.latitude},${pin.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = widget.addressLabel ?? kRotehAddress;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.location_on_rounded, color: _green, size: 16),
        const SizedBox(width: 6),
        const Text("Pick-up Location",
            style: TextStyle(
                color: _green, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 4),
      Text(address,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 180,
          child: Stack(children: [
            GoogleMap(
              onMapCreated: (c) => _ctrl = c,
              onTap: (_) => _openGoogleMaps(),
              initialCameraPosition: CameraPosition(target: _resolved, zoom: 16),
              markers: {
                Marker(
                  markerId: const MarkerId('roteh'),
                  position: _resolved,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen),
                  infoWindow: InfoWindow(
                    title: widget.addressLabel ?? 'Pick-up Location',
                    snippet: 'Tap to open Google Maps',
                    onTap: _openGoogleMaps,
                  ),
                  onTap: _openGoogleMaps,
                ),
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: GestureDetector(
                onTap: _openGoogleMaps,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Icon(Icons.open_in_new_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Open in Maps',
                        style: TextStyle(
                            color: Colors.white, fontSize: 11)),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

