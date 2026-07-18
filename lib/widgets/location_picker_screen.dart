import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../services/maps_service.dart';

/// Result of picking a location: a human-readable address plus coordinates.
class LocationPickResult {
  final String address;
  final LatLng latLng;
  const LocationPickResult({required this.address, required this.latLng});
}

/// Full-screen map picker — drag the map to move the center pin, or search
/// for a location by name. Confirms with the resolved address + coordinates.
class LocationPickerScreen extends StatefulWidget {
  final String title;
  final Color  pinColor;
  final LatLng? initial;
  const LocationPickerScreen({
    super.key,
    this.title    = 'Set Location',
    this.pinColor = AppTheme.accent,
    this.initial,
  });
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _phnomPenh = LatLng(11.5680, 104.9195);

  GoogleMapController? _mapCtrl;
  late LatLng _center  = widget.initial ?? _phnomPenh;
  String _address  = '';
  bool   _geocoding = false;

  final _searchCtrl = TextEditingController();
  List<PlaceResult> _results = [];
  bool  _searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _mapCtrl?.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) { setState(() => _results = []); return; }
    _debounce = Timer(const Duration(milliseconds: 450), () => _doSearch(q));
  }

  Future<void> _doSearch(String q) async {
    setState(() => _searching = true);
    try {
      final r = await MapsService.searchAddress(q);
      if (mounted) setState(() { _results = r; _searching = false; });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectResult(PlaceResult r) {
    _searchCtrl.text = r.address;
    setState(() { _center = r.latLng; _address = r.address; _results = []; });
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(r.latLng, 16));
  }

  Future<void> _onCameraIdle() async {
    setState(() { _geocoding = true; _address = ''; });
    try {
      final a = await MapsService.reverseGeocode(_center);
      if (mounted) setState(() {
        _address  = a ?? '${_center.latitude.toStringAsFixed(4)}, ${_center.longitude.toStringAsFixed(4)}';
        _geocoding = false;
      });
    } catch (_) {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: Stack(children: [

        // Map
        GoogleMap(
          onMapCreated: (c) {
            _mapCtrl = c;
            c.animateCamera(CameraUpdate.newLatLngZoom(_center, 15));
            _onCameraIdle();
          },
          initialCameraPosition: CameraPosition(target: _center, zoom: 15),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onCameraMove: (pos) => _center = pos.target,
          onCameraIdle: _onCameraIdle,
        ),

        // Crosshair pin
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.location_on_rounded, color: widget.pinColor, size: 40),
            const SizedBox(
              width: 10, height: 4,
              child: DecoratedBox(decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.all(Radius.circular(2)))),
            ),
          ]),
        ),

        // Top: back + search
        SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: context.appSurface, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6)],
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: context.appTextPrimary, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8)],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      style: TextStyle(color: context.appTextPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search location…',
                        hintStyle: TextStyle(color: context.appTextSecondary, fontSize: 14),
                        prefixIcon: _searching
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        color: AppTheme.accent, strokeWidth: 2)))
                            : Icon(Icons.search_rounded,
                                color: context.appTextSecondary, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded,
                                    color: context.appTextSecondary, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _results = []);
                                })
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ]),
            ),

            // Search results
            if (_results.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(62, 6, 12, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10)],
                ),
                child: Material(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _results.length.clamp(0, 5),
                    separatorBuilder: (_, __) => Divider(height: 1, color: context.appCardBg),
                    itemBuilder: (_, i) {
                      final r = _results[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.place_outlined,
                            color: AppTheme.accent, size: 18),
                        title: Text(r.address, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: context.appTextPrimary, fontSize: 13)),
                        onTap: () => _selectResult(r),
                      );
                    },
                  ),
                ),
              ),
          ]),
        ),

        // Bottom confirm
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
                16, 14, 16, 14 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: context.appCardBg, borderRadius: BorderRadius.circular(2)),
              ),
              Row(children: [
                Icon(Icons.location_on_rounded, color: widget.pinColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: _geocoding
                      ? Row(children: [
                          SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  color: AppTheme.accent, strokeWidth: 2)),
                          const SizedBox(width: 10),
                          Text('Finding address…',
                              style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                        ])
                      : Text(_address.isEmpty ? 'Move map to set location' : _address,
                          style: TextStyle(
                            color: _address.isEmpty
                                ? context.appTextSecondary
                                : context.appTextPrimary,
                            fontSize: 13,
                            fontWeight: _address.isEmpty ? FontWeight.w400 : FontWeight.w600,
                          )),
                ),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: _address.isEmpty ? null : () {
                    Navigator.pop(context, LocationPickResult(
                      address: _address,
                      latLng:  _center,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.confirmBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    disabledBackgroundColor: AppTheme.confirmBlue.withValues(alpha: 0.4),
                  ),
                  child: const Text('Confirm Location',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
