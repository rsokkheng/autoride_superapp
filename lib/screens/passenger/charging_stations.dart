import 'dart:math' show cos, sin, sqrt, atan2, pi;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/maps_service.dart';
import '../../services/locale_service.dart';
import 'ride_booking.dart';

// Restrict the map to Cambodia only.
const _kCambodiaSW = LatLng(10.4, 102.3);
const _kCambodiaNE = LatLng(14.7, 107.6);
final _kCambodiaBounds = LatLngBounds(southwest: _kCambodiaSW, northeast: _kCambodiaNE);
const _kPhnomPenh = LatLng(11.5563738, 104.9282099);

// Phnom Penh metro area only — this screen now shows Phnom Penh stations
// exclusively, per request, rather than all of Cambodia.
const _kPhnomPenhSW = LatLng(11.40, 104.75);
const _kPhnomPenhNE = LatLng(11.70, 105.05);

bool _latLngInCambodia(double lat, double lng) =>
    lat >= _kCambodiaSW.latitude  && lat <= _kCambodiaNE.latitude &&
    lng >= _kCambodiaSW.longitude && lng <= _kCambodiaNE.longitude;

bool _latLngInPhnomPenh(double lat, double lng) =>
    lat >= _kPhnomPenhSW.latitude  && lat <= _kPhnomPenhNE.latitude &&
    lng >= _kPhnomPenhSW.longitude && lng <= _kPhnomPenhNE.longitude;

bool _isInCambodia(Position p) => _latLngInCambodia(p.latitude, p.longitude);

// Straight-line distance in km — always computed client-side from the
// user's live position rather than trusted from the backend's own
// distance_km, which has been observed to return nonsense (~12,000+ km,
// consistent with a broken/default (0,0) reference point server-side).
double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

// Real Cambodia EV charging stations (sourced from Google Places / a manual
// national listing), used only as a local fallback when the backend returns
// no station inside Cambodia — e.g. while its own data still has
// placeholder/foreign coordinates.
// TODO: remove once the backend serves real Cambodia station data.
final List<ChargingStationModel> _kFallbackStations = [
  const ChargingStationModel(id: -1, name: '2002 Café (NR7)', address: '', lat: 11.9926, lng: 105.4519, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -2, name: 'A1 Boutique', address: '', lat: 12.2818, lng: 103.0335, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -3, name: 'AIQR Showroom', address: '', lat: 13.3602, lng: 103.8780, connectorTypes: const ['GB-T'], hours: '8am - 5pm', fastCharging: true),
  const ChargingStationModel(id: -4, name: 'Amara Home', address: '', lat: 13.3587, lng: 103.8523, connectorTypes: const ['GB-T'], hours: '8am - 10pm', fastCharging: true),
  const ChargingStationModel(id: -5, name: 'Asia Mart', address: '', lat: 13.3576, lng: 103.8540, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -6, name: 'Asia Supermarket', address: '', lat: 11.5325, lng: 104.9533, connectorTypes: const ['CCS', 'SAE'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -7, name: 'Axis Residence', address: '', lat: 11.5497, lng: 104.8643, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -8, name: 'Baitong Hotel & Resort Phnom Penh', address: '', lat: 11.5547, lng: 104.9242, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -9, name: 'Barista Coffee Toul TomPong', address: '', lat: 11.5456, lng: 104.9161, connectorTypes: const ['CCS2'], hours: '7am - 7pm', fastCharging: true),
  const ChargingStationModel(id: -10, name: 'Bayon Market-Chroy Changvar', address: '', lat: 11.6039, lng: 104.9301, connectorTypes: const ['GB-T'], hours: '6:30am - 9:00pm', fastCharging: true),
  const ChargingStationModel(id: -11, name: 'Begonia Tower', address: '', lat: 11.5882, lng: 104.8896, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -12, name: 'BYD KHIEV Auto Monivong Branch', address: '', lat: 11.5505, lng: 104.9221, connectorTypes: const [], hours: '8:30am - 6:30pm', fastCharging: true),
  const ChargingStationModel(id: -13, name: 'Cam ev charging', address: '', lat: 12.4956, lng: 106.0171, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -14, name: 'Cars Care 168 & Mountain coffee', address: '', lat: 13.7280, lng: 106.9672, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -15, name: 'City Tower', address: '', lat: 11.5615, lng: 104.9013, connectorTypes: const ['GB-T', 'CCS2'], hours: '6am - 10pm', fastCharging: true),
  const ChargingStationModel(id: -16, name: 'Coffee 95 Pailin', address: '', lat: 12.8595, lng: 102.6091, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -17, name: 'Connextion Koh Pich Island', address: '', lat: 11.5525, lng: 104.9429, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -18, name: 'Courtyard by Marriott', address: '', lat: 11.5605, lng: 104.9223, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -19, name: 'Domrey Park 598', address: '', lat: 11.6308, lng: 104.8849, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -20, name: 'Dong Feng', address: '', lat: 11.5629, lng: 104.8762, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -21, name: 'Electric Vehicle Charging Station', address: '', lat: 13.3637, lng: 103.8609, connectorTypes: const ['CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -22, name: 'Electric Vehicle Charging Station', address: '', lat: 13.3599, lng: 103.8496, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -23, name: 'EV Charging - Clean Energy Skun', address: '', lat: 12.0484, lng: 105.0276, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -24, name: 'EV Charging Station Battambang', address: '', lat: 13.1022, lng: 103.1998, connectorTypes: const ['GB-T', 'CCS2'], hours: '8:00am - 6:00pm', fastCharging: true),
  const ChargingStationModel(id: -25, name: 'EV Energy Klang Ler Sihanoukville', address: '', lat: 10.6346, lng: 103.5433, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -26, name: 'EV Energy Tech Charging Station', address: '', lat: 11.5519, lng: 104.9233, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -27, name: 'EV Energy Tech Charging Station', address: '', lat: 11.6458, lng: 104.9164, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -28, name: 'EV Station', address: '', lat: 12.4511, lng: 106.0307, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -29, name: 'Exchange Sqaure', address: '', lat: 11.5740, lng: 104.9205, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -30, name: 'Fairy Hotel and Restaurant', address: '', lat: 10.6201, lng: 103.5375, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -31, name: 'Food Supermarket', address: '', lat: 10.6220, lng: 103.5389, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -32, name: 'Furi Mall', address: '', lat: 10.6306, lng: 103.5058, connectorTypes: const ['GB-T', 'CCS2'], hours: '8am - 6pm', fastCharging: true),
  const ChargingStationModel(id: -33, name: 'Good time Relax Resort', address: '', lat: 10.6474, lng: 104.1799, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -34, name: 'J7 Angkor Hotel', address: '', lat: 13.3622, lng: 103.8577, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -35, name: 'Just\'s Coffee & Ice Cream', address: '', lat: 12.2540, lng: 105.9671, connectorTypes: const ['GB-T'], hours: '6am - 7pm', fastCharging: true),
  const ChargingStationModel(id: -36, name: 'Kampot', address: '', lat: 10.5951, lng: 104.1770, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -37, name: 'KMK Garage Station', address: '', lat: 11.8241, lng: 106.1825, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -38, name: 'Krong Kracheh', address: '', lat: 12.4952, lng: 106.0174, connectorTypes: const ['GB-T'], hours: '7am - 7pm', fastCharging: true),
  const ChargingStationModel(id: -39, name: 'Krong Stueng Saen', address: '', lat: 12.7313, lng: 104.8940, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -40, name: 'Le botum hotel', address: '', lat: 11.5606, lng: 104.9313, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -41, name: 'Liberty Carz', address: '', lat: 11.5885, lng: 104.9323, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -42, name: 'Lim Long', address: '', lat: 12.1757, lng: 104.6624, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -43, name: 'Lim Long', address: '', lat: 12.0440, lng: 106.4721, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -44, name: 'Lim Long Gastation', address: '', lat: 11.5754, lng: 104.8917, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -45, name: 'Lim Long Gastation', address: '', lat: 11.4759, lng: 104.5864, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -46, name: 'LMG Car Care', address: '', lat: 11.5350, lng: 104.9747, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -47, name: 'Ly Penglim Car 178', address: '', lat: 11.5957, lng: 104.9006, connectorTypes: const ['GB-T'], hours: '7:30am - 6:00pm', fastCharging: true),
  const ChargingStationModel(id: -48, name: 'Midnight Premier Club', address: '', lat: 11.5111, lng: 104.8743, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -49, name: 'Ministry of Public Works and Transport', address: '', lat: 11.6203, lng: 104.8864, connectorTypes: const ['GB-T', 'CCS2'], hours: '8am - 6pm', fastCharging: true),
  const ChargingStationModel(id: -50, name: 'Munen Coffee & SR Quick', address: '', lat: 11.5742, lng: 104.8587, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -51, name: 'No1 EV Garage', address: '', lat: 11.5579, lng: 104.9013, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -52, name: 'NOVA Resort Mondulkiri', address: '', lat: 12.3755, lng: 107.1740, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -53, name: 'Novotel Hotel', address: '', lat: 10.6107, lng: 103.5030, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -54, name: 'Pa Pa Gasoline Station', address: '', lat: 12.4583, lng: 107.1833, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -55, name: 'Paris Angkor Hotel', address: '', lat: 13.3630, lng: 103.8544, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -56, name: 'Paris Guest House', address: '', lat: 12.5325, lng: 104.2091, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -57, name: 'Penh Em Reaksmey Sign', address: '', lat: 11.5062, lng: 104.8741, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -58, name: 'Phat Power Hotel', address: '', lat: 10.5708, lng: 103.5576, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -59, name: 'Platinum KTV', address: '', lat: 13.3679, lng: 103.8532, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -60, name: 'Poi Pet Resort', address: '', lat: 13.6454, lng: 102.5697, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -61, name: 'PTT Charging Station', address: '', lat: 10.6344, lng: 103.5445, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -62, name: 'PTT Chbar Ompov', address: '', lat: 11.5328, lng: 104.9539, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -63, name: 'PTT Gas Station (Kamroeuk Hall)', address: '', lat: 13.3694, lng: 103.8468, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -64, name: 'PTT Gas Station - Neakvoan', address: '', lat: 11.5708, lng: 104.9056, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -65, name: 'PTT Gas Station - Prek Pnov', address: '', lat: 11.6794, lng: 104.8506, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -66, name: 'PTT Gas Station - Veng Sreng', address: '', lat: 11.5319, lng: 104.8614, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -67, name: 'PTT Gas Station Prey Kei', address: '', lat: 11.4875, lng: 104.8161, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -68, name: 'PTT Phnom Penh Tmei', address: '', lat: 11.5742, lng: 104.8856, connectorTypes: const ['GB-T', 'CCS2'], hours: '5am - 9pm', fastCharging: true),
  const ChargingStationModel(id: -69, name: 'Radio FM 104.5, Preah Vihear', address: '', lat: 13.7950, lng: 104.9909, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -70, name: 'Rest Area Prey Nob', address: '', lat: 10.7945, lng: 103.7424, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -71, name: 'Riva Hotel', address: '', lat: 10.6119, lng: 103.5037, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -72, name: 'Riviera Hotel & Resort Kep', address: '', lat: 10.4773, lng: 104.3038, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -73, name: 'Romdoul Kirirom Resort', address: '', lat: 11.3812, lng: 104.0304, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -74, name: 'Sek Meas Restaurant', address: '', lat: 12.0542, lng: 105.0627, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -75, name: 'Serey Sophon', address: '', lat: 13.5928, lng: 102.9671, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -76, name: 'Sing-Specialists Medical Centre', address: '', lat: 11.5656, lng: 104.9198, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -77, name: 'Skylar by Maridian', address: '', lat: 11.5361, lng: 104.9266, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -78, name: 'SOHO Mall', address: '', lat: 11.5519, lng: 104.9346, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -79, name: 'Sokimex Krong Kompot', address: '', lat: 10.6103, lng: 104.1807, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -80, name: 'Sokimex Noir Coffee', address: '', lat: 13.3612, lng: 103.8608, connectorTypes: const ['GB-T'], hours: '7am - 12am', fastCharging: true),
  const ChargingStationModel(id: -81, name: 'Sovandolla Guesthouse', address: '', lat: 10.6391, lng: 103.5157, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -82, name: 'St2004', address: '', lat: 11.5494, lng: 104.8615, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -83, name: 'Stella Depo Tela Gasoline Srae Ambel', address: '', lat: 11.0461, lng: 103.7962, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -84, name: 'Summer Bay Beach', address: '', lat: 10.5493, lng: 103.5986, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -85, name: 'Tela and Coffee Koum Meas Kampong Thom', address: '', lat: 12.5462, lng: 105.0844, connectorTypes: const ['GB-T', 'CCS2'], hours: '6:00am - 8:00pm', fastCharging: true),
  const ChargingStationModel(id: -86, name: 'The B Resort & Restaurant', address: '', lat: 10.6134, lng: 104.1722, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -87, name: 'The Pub house', address: '', lat: 13.3609, lng: 103.8483, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -88, name: 'The Wave Kep West', address: '', lat: 10.4936, lng: 104.2899, connectorTypes: const ['CCS2'], hours: '7am - 11pm', fastCharging: true),
  const ChargingStationModel(id: -89, name: 'TK Central', address: '', lat: 11.5827, lng: 104.9005, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -90, name: 'Total Energies', address: '', lat: 13.5908, lng: 102.9724, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -91, name: 'Total Energies', address: '', lat: 12.6814, lng: 104.9012, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -92, name: 'Total Engeries Clean', address: '', lat: 11.3176, lng: 104.3106, connectorTypes: const ['GB-T'], hours: '5am - 12am', fastCharging: true),
  const ChargingStationModel(id: -93, name: 'Traeng Trayueng', address: '', lat: 11.2767, lng: 104.2111, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -94, name: 'True Go Hotel BKK', address: '', lat: 11.5460, lng: 104.9225, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -95, name: 'Urban Village Condominiums', address: '', lat: 11.5243, lng: 104.9311, connectorTypes: const ['GB-T', 'CCS2'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -96, name: 'Venture Kampot', address: '', lat: 10.5719, lng: 104.0078, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -97, name: 'VET Parking Lot Koh Sdach Port', address: '', lat: 10.9389, lng: 103.0980, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -98, name: 'We want Coffee', address: '', lat: 12.5698, lng: 105.0484, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -99, name: 'WOW NOW', address: '', lat: 11.5253, lng: 104.8913, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -100, name: 'YW Auto Service', address: '', lat: 11.5903, lng: 104.8817, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -101, name: 'Zara Coffee at Pusat', address: '', lat: 12.5336, lng: 103.9181, connectorTypes: const ['GB-T'], hours: '24/7', fastCharging: true),
  const ChargingStationModel(id: -102, name: 'Zara Coffee Battambang', address: '', lat: 13.0927, lng: 103.2084, connectorTypes: const ['GB-T', 'CCS2'], hours: '6:30am - 9:00pm', fastCharging: true),
  const ChargingStationModel(id: -103, name: 'ZEEKR Showroom', address: '', lat: 11.5423, lng: 104.9224, connectorTypes: const ['GB-T', 'CCS2'], hours: '8am - 7pm', fastCharging: true),
];

// ── Fixed light palette — this screen always renders in a white/light
// theme, regardless of the app's dark/light mode setting. ────────────────────
const _kBg       = Color(0xFFF5F7F5);
const _kCard     = Color(0xFFFFFFFF);
const _kChip     = Color(0xFFEEF1EF);
const _kTextSec  = Color(0xFF6B7280);
const _kTextPri  = Color(0xFF14181C);

const _kLightMapStyle = '''
[
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]}
]
''';

const _kFilters = ['All', 'Fast Charging', 'Available', 'Favorites'];

class ChargingStationsScreen extends StatefulWidget {
  const ChargingStationsScreen({super.key});

  @override
  State<ChargingStationsScreen> createState() => _ChargingStationsScreenState();
}

class _ChargingStationsScreenState extends State<ChargingStationsScreen> {
  List<ChargingStationModel> _stations = [];
  bool    _loading = true;
  bool    _showAll = false;
  String? _error;
  Position? _position;

  String _filter = 'All';
  final _searchCtrl = TextEditingController();
  final Set<int> _favorites = {};

  GoogleMapController? _mapController;
  final Map<int, BitmapDescriptor> _pinIcons = {};

  String? _prevMapsLanguage;

  @override
  void initState() {
    super.initState();
    // Force the native Maps SDK (road/place labels) to Khmer for this whole
    // screen, regardless of the app's current UI language — restored on
    // dispose so the rest of the app keeps the user's chosen language.
    _prevMapsLanguage = MapsService.language;
    MapsService.language = 'km';
    LocaleService.setLocale('km');
    _load();
  }

  @override
  void dispose() {
    if (_prevMapsLanguage != null) {
      MapsService.language = _prevMapsLanguage!;
      LocaleService.setLocale(_prevMapsLanguage!);
    }
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    // Best-effort location — proceed without if denied
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low)
          .timeout(const Duration(seconds: 5));
      // Reject a fix outside Cambodia — a stale cached position or a mock
      // location (common on emulators/simulators) should not silently
      // teleport the map to another country.
      _position = _isInCambodia(pos) ? pos : null;
    } catch (_) {}

    try {
      final stations = await ApiService.getChargingStations(
        lat: _position?.latitude,
        lng: _position?.longitude,
      );
      if (!mounted) return;
      // Drop any station with bogus/placeholder coordinates outside
      // Cambodia — bad data here was clamping the map camera to the
      // Cambodia border trying to reach it (see _kCambodiaBounds above).
      var validStations =
          stations.where((s) => _latLngInCambodia(s.lat, s.lng)).toList();
      // Backend returned nothing usable — fall back to a known-good local
      // list of real Cambodia stations rather than showing an empty page.
      if (validStations.isEmpty) validStations = _kFallbackStations;
      // This screen shows Phnom Penh only.
      validStations = validStations.where((s) => _latLngInPhnomPenh(s.lat, s.lng)).toList();

      // Compare every station against "My Location" and sort nearest-first
      // so the "Nearby" panel and marker numbering both reflect real
      // proximity. Always computed client-side — the backend's own
      // distance_km has been observed to return nonsense (~12,000+ km).
      // Falls back to the Phnom Penh reference point when GPS isn't
      // available, so the list is always sorted by *some* real proximity
      // rather than left in whatever arbitrary order the data arrived in —
      // but the distance figure itself is only shown on cards when it's
      // measured from the user's actual position (see _StationCard).
      final refLat = _position?.latitude  ?? _kPhnomPenh.latitude;
      final refLng = _position?.longitude ?? _kPhnomPenh.longitude;
      validStations = validStations
          .map((s) => s.copyWith(
              distanceKm: _haversineKm(refLat, refLng, s.lat, s.lng)))
          .toList()
        ..sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));

      setState(() { _stations = validStations; _loading = false; });
      await _buildPinIcons();
      _fitOverviewCamera();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  List<ChargingStationModel> get _filteredStations {
    var list = _stations;
    switch (_filter) {
      case 'Fast Charging':
        list = list.where((s) => s.fastCharging).toList();
        break;
      case 'Available':
        list = list.where((s) => s.availablePorts > 0).toList();
        break;
      case 'Favorites':
        list = list.where((s) => _favorites.contains(s.id)).toList();
        break;
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.address.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  // ── Numbered pin markers ─────────────────────────────────────────────────

  Future<void> _buildPinIcons() async {
    for (int i = 0; i < _stations.length; i++) {
      final n = i + 1;
      if (_pinIcons.containsKey(n)) continue;
      _pinIcons[n] = await _paintNumberedPin(n);
    }
    if (mounted) setState(() {});
  }

  static Future<BitmapDescriptor> _paintNumberedPin(int number) async {
    const scale  = 3.0;
    const headR  = 15.0 * scale;
    const w      = headR * 2 + 10 * scale;
    const h      = headR * 2 + 16 * scale;
    final headCx = w / 2;
    final headCy = headR + 4 * scale;

    final recorder = ui.PictureRecorder();
    final canvas    = Canvas(recorder);

    // Teardrop pin: circular head + tapering tail down to a point.
    final path = Path()
      ..moveTo(headCx, h)
      ..quadraticBezierTo(headCx - headR, headCy + headR * 0.7, headCx - headR, headCy)
      ..arcToPoint(Offset(headCx + headR, headCy),
          radius: Radius.circular(headR), clockwise: true)
      ..quadraticBezierTo(headCx + headR, headCy + headR * 0.7, headCx, h)
      ..close();

    canvas.drawPath(
      path.shift(const Offset(0, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(path, Paint()..color = AppTheme.accent);

    // Bolt glyph in the pin head.
    final boltTp = TextPainter(
      text: const TextSpan(
        text: '⚡',
        style: TextStyle(color: Colors.white, fontSize: headR * 1.1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    boltTp.paint(canvas,
        Offset(headCx - boltTp.width / 2, headCy - boltTp.height / 2));

    // Number badge, top-right of the head.
    final badgeCenter = Offset(headCx + headR * 0.72, headCy - headR * 0.72);
    const badgeR = 9.0 * scale;
    canvas.drawCircle(badgeCenter, badgeR, Paint()..color = Colors.white);
    canvas.drawCircle(badgeCenter, badgeR,
        Paint()..color = AppTheme.accent..style = PaintingStyle.stroke..strokeWidth = 2);
    final numTp = TextPainter(
      text: TextSpan(
        text: '$number',
        style: const TextStyle(
            color: Color(0xFF0B0F14), fontSize: badgeR * 1.05, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    numTp.paint(canvas,
        badgeCenter - Offset(numTp.width / 2, numTp.height / 2));

    final picture = recorder.endRecording();
    final img     = await picture.toImage(w.ceil(), h.ceil());
    final bytes   = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: scale);
  }

  void _fitOverviewCamera() {
    // Guards against "GoogleMapController used after widget disposed" —
    // this can fire after the user has already navigated away from this
    // screen while an async load was still pending.
    if (!mounted || _mapController == null) return;
    final points = [
      if (_position != null) LatLng(_position!.latitude, _position!.longitude),
      ..._stations.map((s) => LatLng(s.lat, s.lng)),
    ];
    if (points.length < 2) return;
    final lats = points.map((p) => p.latitude);
    final lngs = points.map((p) => p.longitude);
    final sw = LatLng(lats.reduce((a, b) => a < b ? a : b) - 0.01,
                      lngs.reduce((a, b) => a < b ? a : b) - 0.01);
    final ne = LatLng(lats.reduce((a, b) => a > b ? a : b) + 0.01,
                      lngs.reduce((a, b) => a > b ? a : b) + 0.01);
    try {
      _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 48));
    } catch (_) {}
  }

  void _recenter() {
    if (_position == null || !mounted || _mapController == null) return;
    try {
      _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(_position!.latitude, _position!.longitude), 15));
    } catch (_) {}
  }

  // Tapping a station now opens the normal ride-booking confirm screen
  // (My Location → this EV station as the destination) — the same flow
  // used everywhere else in the app to book a ride.
  void _bookRideTo(ChargingStationModel station) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideBookingScreen(
          initialDestAddress: station.name,
          initialDestLatLng:  LatLng(station.lat, station.lng),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: _kBg,
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: _kTextPri), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              child: Text('Retry', style: TextStyle(color: AppTheme.primary)),
            ),
          ]),
        )),
      );
    }

    final filtered = _filteredStations;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        GoogleMap(
          key: const ValueKey('ev_overview_map_km'),
          initialCameraPosition: CameraPosition(
            target: _position != null
                ? LatLng(_position!.latitude, _position!.longitude)
                : (_stations.isNotEmpty
                    ? LatLng(_stations.first.lat, _stations.first.lng)
                    : _kPhnomPenh),
            zoom: 13,
          ),
          style: _kLightMapStyle,
          onMapCreated: (c) {
            _mapController = c;
            _fitOverviewCamera();
          },
          myLocationEnabled: _position != null,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          cameraTargetBounds: CameraTargetBounds(_kCambodiaBounds),
          minMaxZoomPreference: const MinMaxZoomPreference(6, 20),
          markers: {
            for (int i = 0; i < _stations.length; i++)
              if (_pinIcons.containsKey(i + 1))
                Marker(
                  markerId: MarkerId('station_${_stations[i].id}'),
                  position: LatLng(_stations[i].lat, _stations[i].lng),
                  icon: _pinIcons[i + 1]!,
                  anchor: const Offset(0.5, 1.0),
                  infoWindow: InfoWindow(title: _stations[i].name, snippet: _stations[i].address),
                  onTap: () => _bookRideTo(_stations[i]),
                ),
          },
        ),

        // ── Top search bar + filter chips ─────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(children: [
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 46, height: 46,
                    decoration: const BoxDecoration(
                      color: _kCard,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 10)],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: _kTextPri, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(23),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)],
                    ),
                    child: Row(children: [
                      const Icon(Icons.search, color: _kTextSec, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(color: _kTextPri, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Search charging station, location...',
                            hintStyle: TextStyle(color: _kTextSec, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _searchCtrl.clear()),
                          child: const Icon(Icons.close, color: _kTextSec, size: 18),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _load,
                  child: Container(
                    width: 46, height: 46,
                    decoration: const BoxDecoration(color: _kCard, shape: BoxShape.circle),
                    child: const Icon(Icons.tune, color: _kTextPri, size: 20),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _kFilters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = _kFilters[i];
                    final selected = _filter == f;
                    final icon = switch (f) {
                      'Fast Charging' => Icons.bolt,
                      'Available'     => Icons.circle,
                      'Favorites'     => Icons.star,
                      _               => Icons.done_all,
                    };
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.accent : _kChip,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(icon,
                              size: f == 'Available' ? 8 : 14,
                              color: selected
                                  ? Colors.white
                                  : (f == 'Available' ? AppTheme.accent : _kTextSec)),
                          const SizedBox(width: 6),
                          Text(f,
                              style: TextStyle(
                                  color: selected ? Colors.white : _kTextPri,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              if (_stations.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on, color: AppTheme.accent, size: 12),
                  const SizedBox(width: 4),
                  Text(
                      _position != null
                          ? 'Sorted by distance from your location'
                          : 'Sorted by distance from Phnom Penh (location unavailable)',
                      style: const TextStyle(color: _kTextSec, fontSize: 11)),
                ]),
              ],
            ]),
          ),
        ),

        // ── Recenter FAB ────────────────────────────────────────────────────
        Positioned(
          right: 16,
          bottom: 300,
          child: GestureDetector(
            onTap: _recenter,
            child: Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8)],
              ),
              child: const Icon(Icons.my_location, color: Color(0xFF0B0F14), size: 20),
            ),
          ),
        ),

        // ── Bottom "Nearby Charging Stations" panel ─────────────────────────
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.46),
              decoration: const BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.black12, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Nearby Charging Stations',
                        style: TextStyle(color: _kTextPri, fontSize: 16, fontWeight: FontWeight.w700)),
                    GestureDetector(
                      onTap: () => setState(() => _showAll = !_showAll),
                      child: Text(_showAll ? 'Show less' : 'See all',
                          style: const TextStyle(
                              color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
                Flexible(
                  child: filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No charging stations found.',
                              style: TextStyle(color: _kTextSec)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          itemCount: (_showAll || _searchCtrl.text.trim().isNotEmpty)
                              ? filtered.length
                              : filtered.length.clamp(0, 5),
                          itemBuilder: (context, i) {
                            final s = filtered[i];
                            return _StationCard(
                              station: s,
                              index: _stations.indexOf(s) + 1,
                              favorite: _favorites.contains(s.id),
                              showDistance: _position != null,
                              onToggleFavorite: () => setState(() {
                                _favorites.contains(s.id)
                                    ? _favorites.remove(s.id)
                                    : _favorites.add(s.id);
                              }),
                              onNavigate: () => _bookRideTo(s),
                            );
                          },
                        ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────

class _StationCard extends StatelessWidget {
  final ChargingStationModel station;
  final int index;
  final bool favorite;
  final bool showDistance;
  final VoidCallback onToggleFavorite;
  final VoidCallback onNavigate;

  const _StationCard({
    required this.station,
    required this.index,
    required this.favorite,
    required this.showDistance,
    required this.onToggleFavorite,
    required this.onNavigate,
  });

  static const _logoPalette = [
    Color(0xFF00B14F), Color(0xFF2196F3), Color(0xFF9C27B0),
    Color(0xFFFF6B00), Color(0xFF00C48C), Color(0xFF6366F1),
  ];

  @override
  Widget build(BuildContext context) {
    final logoColor = _logoPalette[station.id.abs() % _logoPalette.length];
    final initials = station.operator.isNotEmpty
        ? station.operator.substring(0, 1).toUpperCase()
        : (station.name.isNotEmpty ? station.name.substring(0, 1).toUpperCase() : 'E');

    final connectorLabel = [
      if (station.connectorTypes.isNotEmpty)
        station.connectorTypes.join('/')
      else if (station.fastCharging)
        'Fast Charging',
      if (station.hours.isNotEmpty) station.hours,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: logoColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Text(initials,
                style: TextStyle(color: logoColor, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(station.name,
                    style: const TextStyle(color: _kTextPri, fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (station.verified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified, color: AppTheme.accent, size: 14),
              ],
            ]),
            const SizedBox(height: 2),
            Text(connectorLabel,
                style: const TextStyle(color: _kTextSec, fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(
              station.totalPorts != null
                  ? '${station.availablePorts}/${station.totalPorts} Available'
                  : '${station.availablePorts} Available',
              style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          GestureDetector(
            onTap: onToggleFavorite,
            child: Icon(favorite ? Icons.star : Icons.star_border,
                color: favorite ? AppTheme.gold : _kTextSec, size: 18),
          ),
          const SizedBox(height: 6),
          if (showDistance && station.distanceKm != null)
            Text('${station.distanceKm!.toStringAsFixed(1)} km',
                style: const TextStyle(color: _kTextPri, fontSize: 12.5, fontWeight: FontWeight.w700)),
          if (station.pricePerKwh != null)
            Text('\$${station.pricePerKwh!.toStringAsFixed(2)}/kWh',
                style: const TextStyle(color: _kTextSec, fontSize: 11)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onNavigate,
            child: Container(
              width: 30, height: 30,
              decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
              child: const Icon(Icons.navigation, color: Colors.white, size: 15),
            ),
          ),
        ]),
      ]),
    );
  }
}
