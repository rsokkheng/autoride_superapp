class WalletTransactionModel {
  final int     id;
  final int     userId;
  final String  direction;      // 'credit' | 'debit'
  final String  type;           // 'top_up' | 'trip_earning' | 'platform_commission' | 'bonus' | ...
  final int     amount;         // KHR
  final int     balanceBefore;
  final int     balanceAfter;
  final String? referenceType;
  final int?    referenceId;
  final String  status;
  final String? note;
  final int?    createdBy;
  final String  createdAt;
  final String  updatedAt;

  const WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.direction,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.referenceType,
    this.referenceId,
    required this.status,
    this.note,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id:            json['id'] as int,
      userId:        json['user_id'] as int,
      direction:     json['direction']?.toString()  ?? 'credit',
      type:          json['type']?.toString()        ?? 'other',
      amount:        _toInt(json['amount']),
      balanceBefore: _toInt(json['balance_before']),
      balanceAfter:  _toInt(json['balance_after']),
      referenceType: json['reference_type']?.toString(),
      referenceId:   json['reference_id'] == null ? null : _toInt(json['reference_id']),
      status:        json['status']?.toString() ?? 'completed',
      note:          json['note']?.toString(),
      createdBy:     json['created_by'] == null ? null : _toInt(json['created_by']),
      createdAt:     json['created_at']?.toString() ?? '',
      updatedAt:     json['updated_at']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  bool get isCredit => direction == 'credit';
  bool get isDebit  => direction == 'debit';

  String get displayLabel {
    if (note != null && note!.isNotEmpty) return note!;
    switch (type) {
      case 'top_up':              return 'Wallet Top-up';
      case 'trip_earning':        return 'Trip Earning';
      case 'platform_commission': return 'Platform Fee';
      case 'bonus':               return 'Bonus Credit';
      case 'trip_payment':        return 'Trip Payment';
      case 'refund':              return 'Refund';
      default:                    return type.replaceAll('_', ' ');
    }
  }

  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) {
        return 'Today, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else {
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {
      return createdAt;
    }
  }
}

class TopUpRequestModel {
  final int     id;
  final int     userId;
  final int     amount;
  final String  method;   // 'cash' | 'online' | 'company_credit'
  final String? note;
  final String  status;   // 'pending' | 'approved' | 'rejected'
  final String? adminNote;
  final int?    approvedBy;
  final String? approvedAt;
  final String  createdAt;

  const TopUpRequestModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.method,
    this.note,
    required this.status,
    this.adminNote,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
  });

  factory TopUpRequestModel.fromJson(Map<String, dynamic> json) {
    final r = (json['data']?['top_up_request'] ?? json['top_up_request'] ?? json)
        as Map<String, dynamic>;
    return TopUpRequestModel(
      id:         _toInt(r['id']),
      userId:     _toInt(r['user_id']),
      amount:     _toInt(r['amount']),
      method:     r['method']?.toString()      ?? 'cash',
      note:       r['note']?.toString(),
      status:     r['status']?.toString()      ?? 'pending',
      adminNote:  r['admin_note']?.toString(),
      approvedBy: r['approved_by'] == null ? null : _toInt(r['approved_by']),
      approvedAt: r['approved_at']?.toString(),
      createdAt:  r['created_at']?.toString()  ?? '',
    );
  }

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  bool get isPending  => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

class WithdrawResultModel {
  final int newBalance; // KHR

  const WithdrawResultModel({required this.newBalance});

  factory WithdrawResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final raw  = data['balance'];
    return WithdrawResultModel(
      newBalance: raw is int ? raw : int.tryParse(raw?.toString() ?? '') ?? 0,
    );
  }
}

class WalletTransactionsPage {
  final List<WalletTransactionModel> transactions;
  final int  currentPage;
  final int  lastPage;
  final int  total;
  final bool hasNextPage;

  const WalletTransactionsPage({
    required this.transactions,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.hasNextPage,
  });

  factory WalletTransactionsPage.fromJson(Map<String, dynamic> json) {
    // 'transactions' may be a flat list (with pagination info in a sibling
    // 'pagination' object) or a nested Laravel paginator ({ data: [...],
    // current_page, ... }) — support both shapes.
    final txField = json['transactions'];
    final List<dynamic> rawList;
    Map<String, dynamic>? paginator;
    if (txField is List) {
      rawList = txField;
    } else if (txField is Map<String, dynamic>) {
      paginator = txField;
      rawList = (txField['data'] as List<dynamic>?) ?? [];
    } else {
      rawList = (json['data'] as List<dynamic>?) ?? [];
    }

    // Pagination metadata: prefer a sibling 'pagination' object, else fall
    // back to fields on the paginator itself, else on the root object.
    final pageInfo = (json['pagination'] as Map<String, dynamic>?) ?? paginator ?? json;

    final data = rawList
        .whereType<Map<String, dynamic>>()
        .map(WalletTransactionModel.fromJson)
        .toList();
    final currentPage = _toInt(pageInfo['current_page'] ?? 1);
    final lastPage     = _toInt(pageInfo['last_page'] ?? 1);
    return WalletTransactionsPage(
      transactions: data,
      currentPage:  currentPage,
      lastPage:     lastPage,
      total:        _toInt(pageInfo['total']),
      hasNextPage:  pageInfo['next_page_url'] != null || currentPage < lastPage,
    );
  }

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
}

class WalletModel {
  final int    balance;      // KHR
  final String currency;
  final List<WalletTransactionModel> transactions;
  // Withdrawal eligibility — min_withdrawal_khr is admin-configurable
  // (Settings → Ride Pricing), never hardcode it on the frontend.
  final bool    canWithdraw;
  final int     minWithdrawalKhr;
  final Map<String, dynamic>? pendingWithdrawal;
  // Go-online gate — also present on /wallet and /wallet/balance responses.
  final bool    canGoOnline;

  const WalletModel({
    required this.balance,
    required this.currency,
    required this.transactions,
    this.canWithdraw       = true,
    this.minWithdrawalKhr  = 0,
    this.pendingWithdrawal,
    this.canGoOnline       = true,
  });

  bool get hasPendingWithdrawal => pendingWithdrawal != null;

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final rawBalance = json['balance'] ?? json['wallet_balance'] ?? json['balance_khr'];
    final balance = rawBalance is int
        ? rawBalance
        : int.tryParse(rawBalance?.toString() ?? '') ?? 0;

    final txField = json['transactions'];
    final rawTxList = txField is List
        ? txField
        : (txField is Map<String, dynamic> ? txField['data'] as List<dynamic>? : null) ?? [];
    final txList = rawTxList
        .whereType<Map<String, dynamic>>()
        .map(WalletTransactionModel.fromJson)
        .toList();

    final minWithdrawal = json['min_withdrawal_khr'];

    return WalletModel(
      balance:      balance,
      currency:     json['currency']?.toString() ?? 'KHR',
      transactions: txList,
      canWithdraw:  json['can_withdraw'] as bool? ?? true,
      minWithdrawalKhr: minWithdrawal is int
          ? minWithdrawal
          : int.tryParse(minWithdrawal?.toString() ?? '') ?? 0,
      pendingWithdrawal: json['pending_withdrawal'] as Map<String, dynamic>?,
      canGoOnline:  json['can_go_online'] as bool? ?? true,
    );
  }
}
