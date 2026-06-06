import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:autoride_superapp/theme/app_theme.dart';

// Android key is unrestricted for HTTP — safe to use on both platforms.
// The iOS key (in AppDelegate.swift) is SDK-only and cannot make HTTP calls.
const _kHttpApiKey = 'AIzaSyBzMVRTpOLoEI5y1S6zDq5icp1llS0fYkc';

const _kDefaultCenter = LatLng(11.5564, 104.9282); // Phnom Penh

// ─────────────────────────────────────────────────────────────────────────────
// Public address field
// ─────────────────────────────────────────────────────────────────────────────

class AddressField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;

  /// Set to true when the field sits on a navy-blue (accent) background.
  /// All text, icons, and the field fill will switch to white-on-dark colours.
  final bool darkBackground;

  const AddressField({
    super.key,
    required this.hint,
    required this.icon,
    required this.controller,
    this.darkBackground = false,
  });

  @override
  State<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> {
  Future<void> _open({required bool mapMode}) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        initial: widget.controller.text,
        startOnMap: mapMode,
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      widget.controller.text = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = widget.darkBackground;

    // Colours that flip based on background
    final Color textColor  = dark ? Colors.white : AppTheme.textPrimary;
    final Color hintColor  = dark ? Colors.white60 : AppTheme.textSecondary;
    final Color iconColor  = dark ? Colors.white70 : AppTheme.textSecondary;
    final Color mapIconColor = dark ? Colors.white : AppTheme.accent;
    final Color fillColor  = dark
        ? Colors.white.withValues(alpha: 0.12)  // translucent white on navy
        : AppTheme.surface;
    final Color focusBorderColor = dark ? Colors.white : AppTheme.accent;

    return TextField(
      controller: widget.controller,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(widget.icon, color: iconColor, size: 20),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _open(mapMode: false),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.search, color: iconColor, size: 20),
              ),
            ),
            GestureDetector(
              onTap: () => _open(mapMode: true),
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 12),
                child: Icon(Icons.map_outlined, color: mapIconColor, size: 20),
              ),
            ),
          ],
        ),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: dark
                ? BorderSide(color: Colors.white.withValues(alpha: 0.25))
                : BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: dark
                ? BorderSide(color: Colors.white.withValues(alpha: 0.25))
                : BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: focusBorderColor, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Suggestion model
// ─────────────────────────────────────────────────────────────────────────────

class _Suggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;
  const _Suggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Picker sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PickerSheet extends StatefulWidget {
  final String initial;
  final bool startOnMap;
  const _PickerSheet({required this.initial, required this.startOnMap});

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // ── Search ────────────────────────────────────────────────────────────────
  late final TextEditingController _searchCtrl;
  Timer? _debounce;
  List<_Suggestion> _suggestions = [];
  bool _searching = false;
  String _searchError = '';

  // ── Map ───────────────────────────────────────────────────────────────────
  GoogleMapController? _mapCtrl;

  // Tracked separately from notifiers so onCameraMove never calls setState.
  LatLng _mapCenter = _kDefaultCenter;
  double _mapZoom   = 15;

  // Race-condition guard: each geocode call gets a token; if a newer call
  // starts before an older one finishes, the older result is silently dropped.
  int _geocodeToken = 0;

  // ── Notifiers (only the address card + button listen to these) ────────────
  //
  // _confirmedAddress: the most recent SUCCESSFULLY geocoded address.
  //   Button is enabled whenever this is non-empty — even while loading.
  //
  // _pendingAddress: address currently being fetched (shown in the card while
  //   the previous confirmed address stays on the button).
  //
  // _geocoding: true while an HTTP geocode request is in flight.
  final _confirmedAddress = ValueNotifier<String>('');
  final _geocoding        = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 2, vsync: this, initialIndex: widget.startOnMap ? 1 : 0);
    _searchCtrl = TextEditingController(text: widget.initial);
    if (widget.initial.isNotEmpty) _fetchSuggestions(widget.initial);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    _mapCtrl?.dispose();
    _confirmedAddress.dispose();
    _geocoding.dispose();
    super.dispose();
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<LatLng?> _getPosition() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> _jumpToMyLocation() async {
    final ll = await _getPosition();
    if (ll == null || !mounted) return;
    _mapCenter = ll;
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(ll, 16));
    _reverseGeocode(ll);
  }

  // ── Places autocomplete ───────────────────────────────────────────────────

  void _onSearchChanged(String q) {
    setState(() => _searchError = '');
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _fetchSuggestions(q));
  }

  Future<void> _fetchSuggestions(String q) async {
    if (!mounted) return;
    setState(() { _searching = true; _searchError = ''; });
    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        {
          'input': q,
          'key': _kHttpApiKey,
          'components': 'country:kh',
        },
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (!mounted) return;

      final data   = jsonDecode(res.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';

      if (status != 'OK' && status != 'ZERO_RESULTS') {
        setState(() {
          _searching = false;
          _searchError = data['error_message'] as String? ?? status;
        });
        return;
      }

      final preds = data['predictions'] as List? ?? [];
      setState(() {
        _suggestions = preds.map((p) {
          final sf = p['structured_formatting'] as Map<String, dynamic>?;
          return _Suggestion(
            placeId:       p['place_id'] as String? ?? '',
            mainText:      sf?['main_text'] as String?
                           ?? p['description'] as String? ?? '',
            secondaryText: sf?['secondary_text'] as String? ?? '',
          );
        }).toList();
        _searching = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _searching = false;
          _searchError = 'Network error — check your connection';
        });
      }
    }
  }

  Future<void> _selectSuggestion(_Suggestion s) async {
    if (s.placeId.isEmpty) {
      if (mounted) Navigator.pop(context, s.mainText);
      return;
    }
    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/details/json',
        {
          'place_id': s.placeId,
          'fields':   'formatted_address,geometry',
          'key':      _kHttpApiKey,
        },
      );
      final res    = await http.get(uri).timeout(const Duration(seconds: 8));
      final data   = jsonDecode(res.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      final addr   = result?['formatted_address'] as String?
          ?? '${s.mainText}, ${s.secondaryText}'
              .trim()
              .replaceAll(RegExp(r',\s*$'), '');
      if (mounted) Navigator.pop(context, addr);
    } catch (_) {
      if (mounted) {
        final fallback =
            '${s.mainText}, ${s.secondaryText}'.trim().replaceAll(RegExp(r',\s*$'), '');
        Navigator.pop(context, fallback);
      }
    }
  }

  // ── Reverse geocode ───────────────────────────────────────────────────────
  //
  // Each call increments _geocodeToken. If, when the response arrives, the
  // token no longer matches, another drag happened in between → discard.

  Future<void> _reverseGeocode(LatLng ll) async {
    final myToken = ++_geocodeToken;
    _geocoding.value = true;

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        {
          'latlng':   '${ll.latitude},${ll.longitude}',
          'key':      _kHttpApiKey,
          'language': 'en',
        },
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      // Discard if a newer drag started while we were waiting.
      if (myToken != _geocodeToken || !mounted) return;

      final data    = jsonDecode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List? ?? [];

      if (results.isNotEmpty) {
        _confirmedAddress.value =
            results.first['formatted_address'] as String? ?? '';
      } else {
        // Fallback: coordinates — button always enables after first map load.
        _confirmedAddress.value =
            '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}';
      }
    } catch (_) {
      if (myToken != _geocodeToken || !mounted) return;
      // Network error fallback — never leave button disabled.
      _confirmedAddress.value =
          '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}';
    } finally {
      if (myToken == _geocodeToken && mounted) {
        _geocoding.value = false;
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: AppTheme.cardBg, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabs,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              indicator: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(icon: Icon(Icons.search, size: 18), text: 'Search'),
                Tab(icon: Icon(Icons.map_outlined, size: 18), text: 'Map'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [_buildSearchTab(), _buildMapTab()],
          ),
        ),
      ]),
    );
  }

  // ── Search tab ────────────────────────────────────────────────────────────

  Widget _buildSearchTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TextField(
          controller: _searchCtrl,
          autofocus: !widget.startOnMap,
          style: const TextStyle(color: AppTheme.textPrimary),
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search address, place or landmark…',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            prefixIcon: const Icon(Icons.search,
                color: AppTheme.textSecondary, size: 20),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.accent)))
                : _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            size: 18, color: AppTheme.textSecondary),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _suggestions = [];
                            _searchError  = '';
                          });
                        })
                    : null,
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
            ),
          ),
        ),
      ),

      if (_searchError.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline,
                  color: AppTheme.danger, size: 16),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(_searchError,
                      style: const TextStyle(
                          color: AppTheme.danger, fontSize: 12))),
            ]),
          ),
        ),

      // Use current location shortcut
      InkWell(
        onTap: () async {
          final ll = await _getPosition();
          if (ll == null || !mounted) return;
          _mapCenter = ll;
          _geocoding.value = true;
          await _reverseGeocode(ll);
          if (mounted && _confirmedAddress.value.isNotEmpty) {
            Navigator.pop(context, _confirmedAddress.value);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.my_location,
                  color: AppTheme.accent, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Use my current location',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    Text('Detected via GPS',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ]),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textSecondary, size: 20),
          ]),
        ),
      ),

      const Divider(
          height: 1, color: AppTheme.cardBg, indent: 20, endIndent: 20),

      Expanded(
        child: _searching
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accent))
            : _suggestions.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                          _searchCtrl.text.isEmpty
                              ? Icons.location_on_outlined
                              : Icons.search_off,
                          color: AppTheme.cardBg,
                          size: 48),
                      const SizedBox(height: 8),
                      Text(
                          _searchCtrl.text.isEmpty
                              ? 'Type to search for a place'
                              : 'No results for "${_searchCtrl.text}"',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    ]),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppTheme.cardBg),
                    itemBuilder: (_, i) {
                      final s = _suggestions[i];
                      return InkWell(
                        onTap: () => _selectSuggestion(s),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(children: [
                            const Icon(Icons.location_on_outlined,
                                color: AppTheme.accent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(s.mainText,
                                        style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    if (s.secondaryText.isNotEmpty)
                                      Text(s.secondaryText,
                                          style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12)),
                                  ]),
                            ),
                            const Icon(Icons.north_west,
                                color: AppTheme.textSecondary, size: 14),
                          ]),
                        ),
                      );
                    },
                  ),
      ),
    ]);
  }

  // ── Map tab ───────────────────────────────────────────────────────────────

  Widget _buildMapTab() {
    return Stack(children: [
      // ── Google Map ────────────────────────────────────────────────────────
      // onCameraMove NEVER calls setState — it only mutates plain fields and
      // ValueNotifiers.  This is critical: setState during a drag frame
      // triggers a widget rebuild that resets the GestureRecognizer chain,
      // making the map feel stuck or unresponsive.
      GoogleMap(
        initialCameraPosition:
            CameraPosition(target: _mapCenter, zoom: _mapZoom),
        onMapCreated: (ctrl) {
          _mapCtrl = ctrl;
          // Geocode the default center so the button becomes active
          // as soon as the map loads.
          _reverseGeocode(_mapCenter);
        },
        onCameraMove: (pos) {
          // Plain field mutation only — zero widget-tree impact.
          _mapCenter = pos.target;
          _mapZoom   = pos.zoom;
          // Signal loading via ValueNotifier (does NOT rebuild GoogleMap).
          _geocoding.value = true;
        },
        // onCameraIdle fires once the camera fully stops.
        // At this point _mapCenter holds the final drag position.
        onCameraIdle: () => _reverseGeocode(_mapCenter),
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
      ),

      // ── Center pin ────────────────────────────────────────────────────────
      // IgnorePointer is mandatory: without it the Center layout widget
      // (which fills the Stack) absorbs touch events before GoogleMap sees them.
      IgnorePointer(
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: const Icon(Icons.location_on,
                color: AppTheme.danger, size: 40),
          ),
        ),
      ),

      // ── Address card ──────────────────────────────────────────────────────
      Positioned(
        top: 0, left: 16, right: 16,
        child: ValueListenableBuilder<bool>(
          valueListenable: _geocoding,
          builder: (_, loading, __) => ValueListenableBuilder<String>(
            valueListenable: _confirmedAddress,
            builder: (_, addr, __) => Card(
              elevation: 4,
              color: AppTheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(children: [
                  const Icon(Icons.location_on_outlined,
                      color: AppTheme.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (loading)
                            const LinearProgressIndicator(
                                color: AppTheme.accent,
                                backgroundColor: AppTheme.cardBg,
                                minHeight: 2)
                          else
                            Text(
                              addr.isEmpty
                                  ? 'Move the map to set location'
                                  : addr,
                              style: TextStyle(
                                color: addr.isEmpty
                                    ? AppTheme.textSecondary
                                    : AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                            ),
                          if (loading && addr.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(addr,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),

      // ── My-location FAB ───────────────────────────────────────────────────
      Positioned(
        bottom: 90, right: 16,
        child: FloatingActionButton.small(
          heroTag: 'addrPickerMyLoc',
          backgroundColor: AppTheme.surface,
          elevation: 3,
          onPressed: _jumpToMyLocation,
          child: const Icon(Icons.my_location,
              color: AppTheme.accent, size: 20),
        ),
      ),

      // ── Confirm button ────────────────────────────────────────────────────
      // Enabled as soon as _confirmedAddress is non-empty (i.e. after the
      // first geocode, even while subsequent geocodes are loading).
      // This means the user can ALWAYS tap it once the map has loaded.
      Positioned(
        bottom: 20, left: 20, right: 20,
        child: SafeArea(
          top: false,
          child: ValueListenableBuilder<String>(
            valueListenable: _confirmedAddress,
            builder: (_, addr, __) {
              final canConfirm = addr.isNotEmpty;
              return ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canConfirm ? AppTheme.accent : AppTheme.cardBg,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: canConfirm ? 2 : 0,
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Use this location',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                onPressed: canConfirm
                    ? () => Navigator.pop(context, addr)
                    : null,
              );
            },
          ),
        ),
      ),
    ]);
  }
}
