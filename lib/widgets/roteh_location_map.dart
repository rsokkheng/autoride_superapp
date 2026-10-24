import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

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

  static const _green = Color(0xFF0E9F6E);

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
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.location_on_rounded, color: _green, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context).pickupLocation,
                  style: const TextStyle(
                      color: _green, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: context.appTextSecondary)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
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
              right: 10,
              bottom: 10,
              child: GestureDetector(
                onTap: _openGoogleMaps,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B4F4A),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Icon(Icons.open_in_new_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Open in Maps',
                        style: TextStyle(
                            color: Colors.white, fontSize: 12,
                            fontWeight: FontWeight.w600)),
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

