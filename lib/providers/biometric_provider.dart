import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../models/user_model.dart';

class BiometricProvider extends ChangeNotifier {
  static const _kDeviceIdKey  = 'bio_device_id';
  static const _kEnabledKey   = 'bio_enabled';
  static const _kEmailKey     = 'bio_email';

  final _storage = const FlutterSecureStorage();
  final _auth    = LocalAuthentication();

  bool _enabled   = false;
  bool _available = false;
  String? _deviceId;
  String? _savedEmail;

  bool get enabled      => _enabled;
  bool get available    => _available;
  String? get savedEmail => _savedEmail;
  String? get deviceId   => _deviceId;

  Future<void> load() async {
    try {
      _available = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      _available = false;
    }
    try {
      _enabled    = (await _storage.read(key: _kEnabledKey)) == 'true';
      _deviceId   = await _storage.read(key: _kDeviceIdKey);
      _savedEmail = await _storage.read(key: _kEmailKey);
    } on MissingPluginException {
      // Plugin not available on this platform/build — biometrics disabled.
    } catch (_) {
      // Storage unavailable; start with defaults.
    }
    notifyListeners();
  }

  /// Returns a stable device UUID, creating one on first call.
  Future<String> _ensureDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final id = const Uuid().v4();
    await _storage.write(key: _kDeviceIdKey, value: id);
    _deviceId = id;
    return id;
  }

  Future<String> _deviceName() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final d = await info.iosInfo;
        return d.name;
      } else {
        final d = await info.androidInfo;
        return '${d.brand} ${d.model}';
      }
    } catch (_) {
      return 'Mobile Device';
    }
  }

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Prompt biometric locally; returns true if the user passed.
  Future<bool> _promptBiometric(String reason) async {
    if (!_available) return false;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Enable biometric login: prompts locally then registers device with server.
  Future<void> enable({required String email}) async {
    final ok = await _promptBiometric('Enable biometric login for ROTEH');
    if (!ok) throw Exception('Biometric prompt cancelled or failed.');

    final deviceId   = await _ensureDeviceId();
    final deviceName = await _deviceName();

    // Use deviceId as "public_key" since server verifies with SHA256(challenge)
    await ApiService.registerBiometricDevice(
      deviceId:   deviceId,
      publicKey:  base64.encode(utf8.encode(deviceId)),
      deviceName: deviceName,
      platform:   _platform,
    );

    await _storage.write(key: _kEnabledKey, value: 'true');
    await _storage.write(key: _kEmailKey,   value: email);
    _enabled    = true;
    _savedEmail = email;
    notifyListeners();
  }

  /// Disable biometric login and remove device from server.
  Future<void> disable() async {
    await _storage.write(key: _kEnabledKey, value: 'false');
    await _storage.delete(key: _kEmailKey);
    _enabled    = false;
    _savedEmail = null;
    notifyListeners();
  }

  /// Full biometric login flow: local prompt → challenge → SHA256 → verify.
  /// Returns (user, token) on success.
  Future<({UserModel user, String token})> login() async {
    if (!_available || !_enabled) {
      throw Exception('Biometric not available or not enabled.');
    }

    final ok = await _promptBiometric('Sign in to ROTEH');
    if (!ok) throw Exception('Biometric cancelled.');

    final deviceId = await _ensureDeviceId();

    // 1. Get challenge from server
    final (:challenge, :expiresIn) =
        await ApiService.getBiometricChallenge(deviceId);

    // 2. Hash: SHA256(challenge)
    final digest       = sha256.convert(utf8.encode(challenge));
    final signedChallenge = digest.toString();

    // 3. Verify with server → receive token
    return ApiService.verifyBiometric(
      deviceId:        deviceId,
      signedChallenge: signedChallenge,
    );
  }

  Future<List<BiometricType>> getAvailableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }
}
