import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/services/api_service.dart';
import '../../models/delivery_model.dart';
import '../shared/ride_chat_screen.dart';

const _kGreen   = Color(0xFF00B14F);
const _kTextMain = Color(0xFF1A1A1A);
const _kTextSub  = Color(0xFF757575);
const _kDivider  = Color(0xFFEEEEEE);

// Phnom Penh fallback coords used when no geocoded positions are available.
const _kDefaultPickup  = LatLng(11.5680, 104.9195);
const _kDefaultDropoff = LatLng(11.5550, 104.9300);

/// Status order for delivery progress bar.
const _kDeliverySteps = [
  'requested',
  'accepted',
  'picked_up',
  'in_progress',
  'delivered',
];

/// Status order for moving progress bar.
const _kMovingSteps = [
  'accepted',
  'arrived',
  'loading',
  'in_transit',
  'completed',
];

class DeliveryTrackingScreen extends StatefulWidget {
  final int    deliveryId;
  final String from;          // pickup address
  final String to;            // dropoff address
  final String fareDisplay;   // e.g. "12,000 ៛"
  final String serviceType;   // 'delivery' | 'moving'
  final String recipientName;

  const DeliveryTrackingScreen({
    super.key,
    required this.deliveryId,
    required this.from,
    required this.to,
    required this.fareDisplay,
    required this.serviceType,
    required this.recipientName,
  });

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  GoogleMapController? _mapController;
  Timer?               _pollTimer;

  DeliveryModel? _delivery;
  bool           _loading  = true;
  String?        _error;

  // Rating dialog state
  int _stars = 5;

  // Cancel in-progress guard
  bool _cancelling = false;

  final Set<Marker> _markers = {};

  static const _initialCamera = CameraPosition(
    target: LatLng(11.5680, 104.9195),
    zoom: 14,
  );

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initMarkers();
    _fetchDelivery();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchDelivery(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────────

  Future<void> _fetchDelivery() async {
    try {
      final d = await ApiService.getDelivery(widget.deliveryId);
      if (!mounted) return;
      setState(() {
        _delivery = d;
        _loading  = false;
        _error    = null;
      });
      _updateMarkersFromDelivery(d);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error   = e.toString();
      });
    }
  }

  // ── Map ───────────────────────────────────────────────────────────────────────

  LatLng get _pickupPos => (_delivery?.pickupLat != null && _delivery?.pickupLng != null)
      ? LatLng(_delivery!.pickupLat!, _delivery!.pickupLng!)
      : _kDefaultPickup;

  LatLng get _dropoffPos => (_delivery?.dropoffLat != null && _delivery?.dropoffLng != null)
      ? LatLng(_delivery!.dropoffLat!, _delivery!.dropoffLng!)
      : _kDefaultDropoff;

  void _initMarkers() {
    _markers.addAll([
      Marker(
        markerId: const MarkerId('pickup'),
        position: _kDefaultPickup,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: widget.from),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: _kDefaultDropoff,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.to),
      ),
    ]);
  }

  void _updateMarkersFromDelivery(DeliveryModel d) {
    if (d.pickupLat == null) return;
    setState(() {
      _markers
        ..removeWhere((m) => m.markerId.value == 'pickup' || m.markerId.value == 'dropoff')
        ..addAll([
          Marker(
            markerId: const MarkerId('pickup'),
            position: _pickupPos,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: widget.from),
          ),
          Marker(
            markerId: const MarkerId('dropoff'),
            position: _dropoffPos,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(title: widget.to),
          ),
        ]);
    });
    _fitMarkers();
  }

  void _fitMarkers() {
    final pickup  = _pickupPos;
    final dropoff = _dropoffPos;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            pickup.latitude  < dropoff.latitude
                ? pickup.latitude  - 0.01
                : dropoff.latitude - 0.01,
            pickup.longitude < dropoff.longitude
                ? pickup.longitude  - 0.01
                : dropoff.longitude - 0.01,
          ),
          northeast: LatLng(
            pickup.latitude  > dropoff.latitude
                ? pickup.latitude  + 0.01
                : dropoff.latitude + 0.01,
            pickup.longitude > dropoff.longitude
                ? pickup.longitude  + 0.01
                : dropoff.longitude + 0.01,
          ),
        ),
        72,
      ),
    );
  }

  // ── Status helpers ────────────────────────────────────────────────────────────

  bool get _isMoving => widget.serviceType == 'moving';

  String get _status => _delivery?.status ?? 'requested';

  List<String> get _steps => _isMoving ? _kMovingSteps : _kDeliverySteps;

  int get _stepIndex {
    final idx = _steps.indexOf(_status);
    return idx < 0 ? 0 : idx;
  }

  String get _statusLabel {
    if (_isMoving) {
      switch (_status) {
        case 'pending':
        case 'requested': return 'Looking for a driver...';
        case 'accepted':  return 'Driver assigned';
        case 'arrived':   return 'Driver arrived at pickup';
        case 'loading':   return 'Loading items...';
        case 'in_transit':return 'On the way to destination';
        case 'completed': return 'Moving completed!';
        case 'cancelled': return 'Cancelled';
        default:          return 'Processing...';
      }
    }
    switch (_status) {
      case 'requested':   return 'Looking for a driver...';
      case 'accepted':    return 'Driver assigned';
      case 'picked_up':   return 'Package picked up';
      case 'in_progress': return 'On the way to recipient';
      case 'delivered':   return 'Delivered!';
      case 'cancelled':   return 'Cancelled';
      default:            return 'Processing...';
    }
  }

  bool get _isDelivered  =>
      _status == 'delivered' || _status == 'completed';
  bool get _canCancel    =>
      _status == 'requested' || _status == 'pending';
  bool get _driverAssigned =>
      _status != 'requested' && _status != 'pending' &&
      _delivery?.driver != null;

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> _cancelDelivery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to cancel this delivery?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel Order',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await ApiService.cancelDelivery(widget.deliveryId);
      if (!mounted) return;
      _mapController?.dispose();
      _mapController = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      setState(() => _cancelling = false);
    } catch (_) {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _openChat() async {
    final saved = await ApiService.getSavedUser();
    if (!mounted) return;
    final driverId = _delivery?.driverId ?? 0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideChatScreen(
          rideId:      widget.deliveryId.toString(),
          driverId:    driverId,
          passengerId: saved?.id ?? 0,
          myId:        saved?.id ?? 0,
          myName:      saved?.name ?? 'Sender',
          otherName:   _delivery?.driver?.name ?? 'Driver',
          isDriver:    false,
        ),
      ),
    );
  }

  Future<void> _showRatingDialog() async {
    _stars = 5;
    await showDialog(
      context: context,
      builder: (ctx) => _RatingDialog(
        initialStars: _stars,
        onSubmit: (stars, comment) async {
          Navigator.pop(ctx);
          try {
            await ApiService.rateDelivery(
              widget.deliveryId,
              rating: stars.toDouble(),
              comment: comment.isNotEmpty ? comment : null,
            );
          } on ApiException catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(e.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ));
            }
            return;
          } catch (_) {}
          if (!mounted) return;
          // Navigate home after successful rating
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading && _delivery == null
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : _error != null && _delivery == null
              ? _ErrorView(error: _error!, onRetry: _fetchDelivery)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        // ── Map ──────────────────────────────────────────────────────────────
        GoogleMap(
          onMapCreated: (c) {
            _mapController = c;
            _fitMarkers();
          },
          initialCameraPosition: _initialCamera,
          markers: _markers,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
        ),

        // ── Top route card ────────────────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _RouteCard(from: widget.from, to: widget.to),
          ),
        ),

        // ── Delivered banner ──────────────────────────────────────────────
        if (_isDelivered)
          Positioned(
            top: MediaQuery.of(context).padding.top + 90,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _kGreen.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Delivered!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Bottom sheet ──────────────────────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _BottomSheet(
            delivery:    _delivery,
            status:      _status,
            statusLabel: _statusLabel,
            stepIndex:   _stepIndex,
            isDelivered: _isDelivered,
            canCancel:   _canCancel,
            driverAssigned: _driverAssigned,
            fareDisplay: widget.fareDisplay,
            serviceType: widget.serviceType,
            recipientName: widget.recipientName,
            cancelling:  _cancelling,
            onCancel:    _cancelling ? null : _cancelDelivery,
            onChat:      _driverAssigned ? _openChat : null,
            onRate:      _isDelivered ? _showRatingDialog : null,
          ),
        ),
      ],
    );
  }
}

// ── Bottom sheet widget ───────────────────────────────────────────────────────

class _BottomSheet extends StatelessWidget {
  final DeliveryModel? delivery;
  final String  status;
  final String  statusLabel;
  final int     stepIndex;
  final bool    isDelivered;
  final bool    canCancel;
  final bool    driverAssigned;
  final String  fareDisplay;
  final String  serviceType;
  final String  recipientName;
  final bool    cancelling;
  final VoidCallback? onCancel;
  final VoidCallback? onChat;
  final VoidCallback? onRate;

  const _BottomSheet({
    required this.delivery,
    required this.status,
    required this.statusLabel,
    required this.stepIndex,
    required this.isDelivered,
    required this.canCancel,
    required this.driverAssigned,
    required this.fareDisplay,
    required this.serviceType,
    required this.recipientName,
    required this.cancelling,
    this.onCancel,
    this.onChat,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Status title
              Row(children: [
                Expanded(
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: isDelivered ? _kGreen : _kTextMain,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Fare chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    fareDisplay,
                    style: const TextStyle(
                      color: _kGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 14),

              // Progress bar
              _StatusProgressBar(
                stepIndex:   stepIndex,
                isMoving:    serviceType == 'moving',
              ),
              const SizedBox(height: 18),

              // Driver info card (shown when driver is assigned)
              if (driverAssigned && delivery?.driver != null) ...[
                _DriverCard(driver: delivery!.driver!),
                const SizedBox(height: 16),
                const Divider(color: _kDivider, height: 1),
                const SizedBox(height: 14),
              ],

              // Recipient info
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Recipient',
                value: recipientName.isNotEmpty
                    ? recipientName
                    : (delivery?.recipientName ?? '--'),
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: serviceType == 'moving'
                    ? Icons.local_shipping_outlined
                    : Icons.delivery_dining_outlined,
                label: 'Service',
                value: serviceType == 'moving' ? 'Moving' : 'Delivery',
              ),
              const SizedBox(height: 16),
              const Divider(color: _kDivider, height: 1),
              const SizedBox(height: 14),

              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Chat Driver
                  _ActionBtn(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat Driver',
                    onTap: onChat ?? () {},
                    disabled: !driverAssigned,
                  ),
                  // Cancel (only when requested)
                  if (canCancel)
                    _ActionBtn(
                      icon: Icons.cancel_outlined,
                      label: cancelling ? '...' : 'Cancel',
                      onTap: onCancel ?? () {},
                      danger: true,
                      loading: cancelling,
                    ),
                ],
              ),

              // "Rate Delivery" button when delivered
              if (isDelivered) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onRate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Rate Delivery',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status progress bar ───────────────────────────────────────────────────────

class _StatusProgressBar extends StatelessWidget {
  final int  stepIndex;
  final bool isMoving;

  const _StatusProgressBar({
    required this.stepIndex,
    this.isMoving = false,
  });

  static const _deliveryLabels = [
    'Order',
    'Driver\nAssigned',
    'Picked Up',
    'On the\nWay',
    'Delivered',
  ];

  static const _movingLabels = [
    'Accepted',
    'Arrived',
    'Loading',
    'In Transit',
    'Done',
  ];

  List<String> get _labels => isMoving ? _movingLabels : _deliveryLabels;
  List<String> get _steps  => isMoving ? _kMovingSteps : _kDeliverySteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        // Even indices → step circles; odd indices → connectors
        if (i.isOdd) {
          final stepIdx = i ~/ 2;
          final filled  = stepIdx < stepIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: filled ? _kGreen : Colors.grey[300],
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final done    = stepIdx <= stepIndex;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: done ? _kGreen : Colors.grey[200],
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? _kGreen : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              _labels[stepIdx],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: done ? _kGreen : _kTextSub,
                fontSize: 9,
                fontWeight: done ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Driver card ───────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final dynamic driver; // UserModel

  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final name  = driver.name  as String? ?? 'Driver';
    final phone = driver.phone as String? ?? '--';

    return Row(children: [
      CircleAvatar(
        radius: 26,
        backgroundColor: Colors.grey[200],
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'D',
          style: const TextStyle(
            color: _kTextMain,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    color: _kTextMain,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.phone_outlined, color: _kTextSub, size: 14),
              const SizedBox(width: 4),
              Text(phone,
                  style: const TextStyle(color: _kTextSub, fontSize: 13)),
            ]),
          ],
        ),
      ),
    ]);
  }
}

// ── Route card (top of screen) ────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  final String from;
  final String to;

  const _RouteCard({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                  color: _kGreen, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(from,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _kTextMain,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 19, top: 2, bottom: 2),
            child: Row(children: [
              Container(width: 2, height: 12, color: Colors.grey[300]),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              const Icon(Icons.location_on, color: Colors.red, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(to,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _kTextMain,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: _kTextSub, size: 16),
      const SizedBox(width: 8),
      Text('$label: ',
          style: const TextStyle(color: _kTextSub, fontSize: 13)),
      Expanded(
        child: Text(value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: _kTextMain,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ),
    ]);
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData   icon;
  final String     label;
  final VoidCallback onTap;
  final bool       disabled;
  final bool       danger;
  final bool       loading;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.disabled = false,
    this.danger   = false,
    this.loading  = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color active  = danger ? Colors.red : _kGreen;
    final Color iconClr = disabled
        ? _kTextSub.withValues(alpha: 0.4)
        : active;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: disabled
                  ? Colors.grey.withValues(alpha: 0.08)
                  : active.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: danger
                  ? Border.all(color: Colors.red.withValues(alpha: 0.4))
                  : null,
            ),
            child: loading
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: active))
                : Icon(icon, color: iconClr, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: disabled
                  ? _kTextSub.withValues(alpha: 0.4)
                  : danger
                      ? Colors.red
                      : _kTextSub,
              fontSize: 12,
              fontWeight: danger ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rating dialog ─────────────────────────────────────────────────────────────

class _RatingDialog extends StatefulWidget {
  final int initialStars;
  final void Function(int stars, String comment) onSubmit;

  const _RatingDialog({
    required this.initialStars,
    required this.onSubmit,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  late int    _stars;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _stars = widget.initialStars;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Rate Delivery',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'How was your delivery experience?',
            style: TextStyle(color: _kTextSub, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _stars;
              return GestureDetector(
                onTap: () => setState(() => _stars = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled
                        ? const Color(0xFFFFA000)
                        : Colors.grey[400],
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Comment
          TextField(
            controller: _ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Leave a comment (optional)',
              hintStyle: const TextStyle(color: _kTextSub, fontSize: 13),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);           // close dialog
                Navigator.of(context).popUntil(  // go home
                    (route) => route.isFirst);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Skip'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => widget.onSubmit(_stars, _ctrl.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ],
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String       error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            const SizedBox(height: 12),
            Text(
              'Could not load delivery',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextSub, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
