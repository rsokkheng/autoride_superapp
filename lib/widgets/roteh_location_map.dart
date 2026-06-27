import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/maps_service.dart';

// ROTEH CAMBODIA office — geocoded once per session and cached
const _kRotehAddress = 'ROTEH CAMBODIA, ផ្លូវលេខ6A, Phnom Penh';
LatLng? _cachedRotehPin;

/// Embedded non-interactive map showing the ROTEH CAMBODIA pickup location.
/// If [pin] is provided (product-specific coordinates) it takes priority.
/// Otherwise geocodes [_kRotehAddress] once per session.
class RotehLocationMap extends StatefulWidget {
  final LatLng? pin;
  final String? addressLabel;
  const RotehLocationMap({super.key, this.pin, this.addressLabel});

  @override
  State<RotehLocationMap> createState() => _RotehLocationMapState();
}

class _RotehLocationMapState extends State<RotehLocationMap> {
  GoogleMapController? _ctrl;
  LatLng? _resolved;
  bool _loading = false;

  static const _green = Color(0xFF00C48C);

  @override
  void initState() {
    super.initState();
    if (widget.pin != null) {
      _resolved = widget.pin;
    } else {
      _resolveDefault();
    }
  }

  Future<void> _resolveDefault() async {
    if (_cachedRotehPin != null) {
      if (mounted) setState(() => _resolved = _cachedRotehPin);
      return;
    }
    if (mounted) setState(() => _loading = true);
    final results = await MapsService.searchAddress(_kRotehAddress);
    if (!mounted) return;
    if (results.isNotEmpty) {
      _cachedRotehPin = results.first.latLng;
      setState(() { _resolved = _cachedRotehPin; _loading = false; });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _openFullScreen() {
    final pin = _resolved;
    if (pin == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _RotehMapFullScreen(
          pin: pin,
          address: widget.addressLabel ?? _kRotehAddress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final address = widget.addressLabel ?? _kRotehAddress;
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
          child: _loading || _resolved == null
              ? Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      CircularProgressIndicator(
                          strokeWidth: 2, color: _green),
                      SizedBox(height: 8),
                      Text('Loading map…',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ]),
                  ),
                )
              : GestureDetector(
                  onTap: _openFullScreen,
                  child: Stack(children: [
                    GoogleMap(
                      onMapCreated: (c) => _ctrl = c,
                      initialCameraPosition:
                          CameraPosition(target: _resolved!, zoom: 16),
                      markers: {
                        Marker(
                          markerId: const MarkerId('roteh'),
                          position: _resolved!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueGreen),
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
                          Icon(Icons.fullscreen_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Tap to expand',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ]),
                      ),
                    ),
                  ]),
                ),
        ),
      ),
    ]);
  }
}

class _RotehMapFullScreen extends StatelessWidget {
  final LatLng pin;
  final String address;
  const _RotehMapFullScreen({required this.pin, required this.address});

  static const _green = Color(0xFF00C48C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick-up Location'),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: pin, zoom: 17),
          markers: {
            Marker(
              markerId: const MarkerId('roteh'),
              position: pin,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(
                title: 'Pick-up Here',
                snippet: address,
              ),
            ),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Row(children: [
              const Icon(Icons.location_on_rounded, color: _green, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(address,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
