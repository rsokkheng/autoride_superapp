import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/shared/payway_checkout_screen.dart';
import '../theme/app_theme.dart';
import 'api_service.dart';

/// ABA / ACLEDA are collected through ABA PayWay (KHQR).
bool isPayWayMethod(String? method) => method == 'aba' || method == 'acleda';

/// Opens the ABA PayWay KHQR for an order and returns true once the server
/// has confirmed the payment with PayWay. [type]: ride | delivery |
/// marketplace | car_rental | subscription. The amount is computed by the
/// server from the order — never sent from the app.
Future<bool> payOrderWithAba(BuildContext context, {
  required String type,
  required int id,
  String? guestToken,
}) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final nav = Navigator.of(context);
  try {
    final checkout = await ApiService.createPayWayForOrder(type: type, id: id, guestToken: guestToken);
    final paid = await nav.push<bool>(MaterialPageRoute(
        builder: (_) => PayWayCheckoutScreen(checkout: checkout, guestToken: guestToken)));
    return paid == true;
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text(e.statusCode == 503 ? l.paywayNotAvailable : e.message),
      backgroundColor: e.statusCode == 503 ? AppTheme.warning : AppTheme.danger,
      behavior: SnackBarBehavior.floating,
    ));
  } catch (_) {
    messenger.showSnackBar(SnackBar(
      content: Text(l.connectionErrorRetry), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
  }
  return false;
}
