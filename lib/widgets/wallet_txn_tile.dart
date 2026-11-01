import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/wallet_model.dart';
import '../theme/app_theme.dart';

/// One wallet transaction row (driver earnings tab and full history page).
class WalletTxnTile extends StatelessWidget {
  final WalletTransactionModel txn;

  const WalletTxnTile({super.key, required this.txn});

  IconData get _icon {
    switch (txn.type) {
      case 'trip_earning':        return Icons.electric_rickshaw;
      case 'platform_commission': return Icons.percent;
      case 'bonus':               return Icons.emoji_events;
      case 'top_up':
      case 'topup':               return Icons.add_circle_outline;
      case 'withdrawal':
      case 'withdrawal_hold':     return Icons.account_balance_outlined;
      case 'withdrawal_rejected':
      case 'withdrawal_refund':
      case 'refund':              return Icons.undo;
      default:                    return Icons.swap_horiz;
    }
  }

  Color get _statusColor {
    switch (txn.status) {
      case 'completed':  return AppTheme.success;
      case 'pending':    return AppTheme.warning;
      case 'processing': return AppTheme.accentOrange;
      case 'failed':
      case 'rejected':
      case 'cancelled':  return AppTheme.danger;
      default:            return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (txn.status) {
      case 'completed':  return Icons.check_circle_rounded;
      case 'pending':     return Icons.schedule_rounded;
      case 'processing': return Icons.autorenew_rounded;
      case 'failed':
      case 'rejected':
      case 'cancelled':  return Icons.cancel_rounded;
      default:            return Icons.circle;
    }
  }

  String _statusLabel(AppLocalizations l) => switch (txn.status) {
        'completed'  => l.completed,
        'pending'    => l.txStatusPending,
        'processing' => l.txStatusProcessing,
        'failed'     => l.txStatusFailed,
        'rejected'   => l.txStatusRejected,
        'cancelled'  => l.cancelled,
        _            => txn.status,
      };

  @override
  Widget build(BuildContext context) {
    final isCredit    = txn.isCredit;
    final itemColor   = isCredit ? AppTheme.success : AppTheme.accentOrange;
    final statusColor = _statusColor;
    final isPending    = txn.status == 'pending' || txn.status == 'processing';
    final amountStr = isCredit
        ? '+${AppTheme.khr(txn.amount)}'
        : '-${AppTheme.khr(txn.amount)}';

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(
              color: isPending ? statusColor : Colors.transparent, width: 3))),
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: itemColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(_icon, color: itemColor, size: 18),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.displayLabel,
                    style: TextStyle(
                        color: context.appTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 3),
                Row(children: [
                  Text(txn.formattedDate,
                      style: TextStyle(
                          color: context.appTextSecondary,
                          fontSize: 11)),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_statusIcon, color: statusColor, size: 10),
                      const SizedBox(width: 3),
                      Text(_statusLabel(AppLocalizations.of(context)),
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
              ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(amountStr,
              style: TextStyle(
                  color: itemColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          Text(AppLocalizations.of(context).drvBalanceShort(AppTheme.khr(txn.balanceAfter)),
              style: TextStyle(
                  color: context.appTextSecondary, fontSize: 10)),
        ]),
      ]),
    );
  }
}
