import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('km'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('km'),
    Locale('en'),
    Locale('zh'),
  ];

  static const Map<String, Map<String, String>> _t = {
    'en': {
     'appName': 'RETEH',
      'tagline': 'ROTEH APP',
      'copyright': 'ROTEH APP © 2026 — All rights reserved',
      'whoAreYou': 'Who are you?',
      'selectRole': 'Select your role to continue',
      'passenger': 'Passenger',
      'passengerSub': 'Book rides, order deliveries,\nbuy or rent vehicles',
      'driver': 'Driver',
      'driverSub': 'Accept ride requests, manage deliveries & earn money',
      'home': 'ROTEH',
      'charging': 'Charging',
      'chat': 'Chat',
      'profile': 'Profile',
      'earnings': 'Earnings',
      'dashboard': 'Dashboard',
      'bookRide': 'Book Ride',
      'bookRideSub': 'Now or schedule later',
      'delivery': 'Delivery',
      'deliverySub': 'Send packages fast',
      'marketplace': 'Marketplace',
      'marketplaceSub': 'Buy or rent vehicles',
      'evStations': 'EV Stations',
      'evStationsSub': 'Find charging near you',
      'safety': 'Safety',
      'payment': 'Payment',
      'support': 'Support',
      'recentTrips': 'Recent Trips',
      'seeAll': 'See all',
      'services': 'Services',
      'quickActions': 'Quick Actions',
      'whereAreYouGoing': 'Where are you going?',
      'bookNow': 'Book Now',
      'scheduleRide': 'Schedule Ride',
      'scheduleForLater': 'Schedule for later',
      'sendNow': 'Send Now',
      'evChargingStations': 'EV Charging Stations',
      'buy': 'Buy',
      'rent': 'Rent',
      'trackTrip': 'Track Trip',
      'driverOnTheWay': 'Driver on the way',
      'tripInProgress': 'Trip in Progress',
      'arrived': 'Driver Arrived!',
      'paySecurely': 'Pay Securely',
      'emergencySOS': 'Emergency SOS',
      'selectLanguage': 'Select Language',
      'language': 'Language',
      'goodMorning': 'Good morning,',
      'goodAfternoon': 'Good afternoon,',
      'goodEvening': 'Good evening,',
      'hello': 'Hello',
      'welcome': 'Welcome!',
      'online': 'Online',
      'offline': 'Offline',
      'driverDashboard': 'Driver Dashboard',
      'messages': 'Messages & Support',
      'paymentSuccessful': 'Payment Successful!',
      'signOut': 'Sign Out',
      'paymentMethods': 'Payment Methods',
      'safetySettings': 'Safety Settings',
      'tripHistory': 'Trip',
      'notifications': 'Notifications',
      'helpSupport': 'Help & Support',
      'bankPayouts': 'Bank & Payouts',
      'documents': 'Documents',
      'navigate': 'Navigate',
      'available': 'Available',
      'connectionErrorRetry': 'Can\'t reach the server. Check your internet connection and try again.',
      'sortBy': 'Sort by',
      'sortNewest': 'Newest',
      'sortOldest': 'Oldest',
      'sortPriceHigh': 'Price: high to low',
      'sortPriceLow': 'Price: low to high',
      'searchRentalsHint': 'Search rentals…',
      'rentalBookedSuccess': 'Rental booked successfully!',
      'rentalHeaderSubtitle': 'Fill in the details to book your rental',
      'drvTopUpMsg': 'Your wallet balance is too low to go online. Please top up at least {amount} to continue.',
      'drvShortBy': 'Short by {amount}',
      'drvKmAway': '{km} km away',
      'drvEndsInHm': 'ends in {h}h {m}m',
      'drvEndsInMin': 'ends in {m} min',
      'drvTripsCount': '{n} Trips',
      'drvSurgeInside': '{x}× Surge Zone — You\'re Inside!',
      'drvSurgeNearby': '{x}× Surge Nearby — {zone}',
      'drvZone': 'Zone',
      'drvInactive': 'Inactive',
      'drvPeakExtra': 'Extra {amount} per trip during peak hours',
      'drvPeakProgress': '{done} of {target} peak-hour trips completed today',
      'drvStreakCount': '{n} consecutive 5-star ratings!',
      'drvStreakRemaining': '{n} more 5-star = Earn {amount} bonus',
      'drvStreakUnlocked': 'Streak bonus unlocked — {amount}!',
      'drvPassengerNo': 'Passenger #{id}',
      'drvSenderNo': 'Sender #{id}',
      'drvSecondsShort': '{n} s',
      'drvFloors': 'Floor: pickup {from} → dropoff {to}',
      'drvElevator': 'Elevator: {v}',
      'drvHelpers': '{n} helper(s) — {type}',
      'drvHeavyCarry': 'Heavy carry',
      'drvNormalCarry': 'Normal carry',
      'drvWithdrawConfirm': 'Withdraw your full balance to {bank}?\nThis will be sent to admin for approval.',
      'drvWithdrawSubmitted': '✅ Withdrawal request for {amount} submitted — pending admin approval',
      'drvMinWithdrawal': 'Minimum withdrawal: {amount}',
      'drvWithdrawTo': '💸  Withdraw {amount} to {bank}',
      'drvTodaysTransactions': 'Today\'s Transactions',
      'drvTotalCount': '{n} total',
      'drvBalanceShort': 'Bal: {amount}',
      'seatsCount': '{n} seats',
      'seatsOne': '1 seat',
      'senderNameHint': 'Sender\'s name',
      'senderPhoneHint': 'Sender\'s phone',
      'recipientNameHint': 'Recipient\'s name',
      'recipientPhoneHint': 'Recipient\'s phone',
      'floorsPickupDropoff': 'Pickup: {from}  •  Dropoff: {to}',
      'packageAmountHint': 'Package value in ៛ (optional)',
      'packageAmount': 'Package Amount',
      'deliveryFee': 'Delivery Fee',
      'serviceFee': 'Service Fee',
      'pickup': 'Pickup',
      'completedAt': 'Completed At',
      'completionTime': 'Completion Time',
      'deliveryCompleted': 'Delivery Completed',
      'deliveryReceipt': 'Delivery Receipt',
      'deliverySummary': 'Delivery Summary',
      'viewDeliverySummary': 'View Delivery Summary',
      'feePaidBy': 'Fee Paid By',
      'paidBySender': 'Paid by sender',
      'paidByRecipient': 'Paid by recipient',
      'guestOtpReason': 'Confirm your phone number to place this order.',
      'confirmOtpTitle': 'Confirm OTP code',
      'otpSentToYourPhone': 'We sent a 6-digit code to your phone',
      'didntReceiveCode': 'Didn\'t receive the code?',
      'resendShort': 'Resend',
      'guestPhoneStarHint': 'Phone number * (e.g. 012 345 678)',
      'guestFullNameRequired': 'Please enter your full name.',
      'guestPhoneInvalid': 'Please enter a valid phone number (8–16 digits).',
      'guestPhoneNotVerified': 'Please verify your phone number with the SMS code.',
      'guestOtpNote': 'We\'ll send an SMS code to verify this number.',
      'regJoinTitle': 'Join ROTEH',
      'regTagline': 'Fast, safe rides in Cambodia',
      'regIWantTo': 'I want to',
      'regRideAsPassenger': 'Ride as Passenger',
      'regDriveAndEarn': 'Drive & Earn',
      'regOwner': 'Owner',
      'regSelectCity': 'Select your city',
      'regCityRequired': 'City is required',
      'regNameRequired': 'Name is required',
      'regEmailRequired': 'Email is required',
      'regEmailInvalid': 'Enter a valid email',
      'regPhoneOptional': 'Phone (optional)',
      'regPasswordMin': 'At least 8 characters',
      'regPasswordMismatch': 'Passwords do not match',
      'regReferralOptional': 'Referral Code (optional)',
      'regRegisterUpload': 'Register & Upload Documents',
      'cityPhnomPenh': 'Phnom Penh',
      'citySiemReap': 'Siem Reap',
      'citySihanoukville': 'Sihanoukville',
      'cityBattambang': 'Battambang',
      'cityKampongCham': 'Kampong Cham',
      'cityKampot': 'Kampot',
      'cityKep': 'Kep',
      'cityPoipet': 'Poipet',
      'chatsTab': 'Chats',
      'noConversationsYet': 'No conversations yet',
      'driverMessagesHint': 'Messages with your driver will appear here',
      'rotehSupport': 'ROTEH Support',
      'chatWithOurTeam': 'Chat with our team',
      'noMessagesSayHello': 'No messages yet. Say hello!',
      'typeAMessageHint': 'Type a message...',
      'howCanWeHelp': 'How can we help?',
      'searchForHelp': 'Search for help...',
      'quickHelp': 'Quick Help',
      'qhDriverLate': 'My driver is late',
      'qhOvercharged': 'I was overcharged',
      'qhLostItem': 'Lost item in vehicle',
      'qhSafetyIssue': 'Report a safety issue',
      'qhCancelTrip': 'Cancel my trip',
      'support247': '24/7 Support',
      'openTicketReplyHere': 'Open a ticket and our team will reply here',
      'chatNow': 'Chat Now',
      'supportRepliesSoon': 'Say hello! Our team typically replies within a few minutes.',
      'uploadFromGallery': 'Upload from gallery',
      'couldNotSendPhoto': 'Could not send photo: {error}',
      'couldNotLoadMessages': 'Could not load messages: {error}',
      'missedRequestsTitle': 'Missed requests',
      'missedTab': 'Missed',
      'declinedTab': 'Declined',
      'reasonMissed': 'No response in time',
      'reasonDeclined': 'You declined',
      'outcomeOpen': 'Still available',
      'outcomeTaken': 'Taken by another driver',
      'outcomeCancelled': 'Cancelled',
      'noMissedRequests': 'No missed requests',
      'missedRequestsHint': 'Requests you decline or don\'t answer in time appear here.',
      'trRemove': 'Remove',
      'trSwitch': 'Switch',
      'trAccount': 'Account',
      'trBack': 'Back',
      'trSave': 'Save',
      'trDelete': 'Delete',
      'trEdit': 'Edit',
      'trApprove': 'Approve',
      'trReject': 'Reject',
      'trApproved': 'Approved',
      'trRejected': 'Rejected',
      'trPending': 'Pending',
      'trActive': 'Active',
      'trInactive': 'Inactive',
      'trTitle': 'Title',
      'trRefresh': 'Refresh',
      'trSignOut': 'Sign Out',
      'trUnknown': 'Unknown',
      'trSearch': 'Search',
      'trMap': 'Map',
      'trView': 'View',
      'trNow': 'Now',
      'trJustNow': 'Just now',
      'trMinutesAgo': '{n}m ago',
      'trHoursAgo': '{n}h ago',
      'trDaysAgo': '{n}d ago',
      'trMinAgoLong': '{n} min ago',
      'trHrsAgoLong': '{n} hrs ago',
      'trDaysAgoLong': '{n} days ago',
      'trTodayAt': 'Today, {time}',
      'trPerDay': '/day',
      'trTryAgain': 'Try again',
      'trProcessing': 'Processing…',
      'trCustomerNo': 'Customer #{id}',
      'trDriverNo': 'Driver #{id}',
      'trRideNo': 'Ride #{id}',
      'trStopN': 'Stop {n}',
      'trStopWithAddress': 'Stop {n}: {address}',
      'trStopDestination': 'Stop {n} — Destination',
      'trStopDistance': 'Stop {n} · {km} km',
      'trDistanceKm': 'Distance ({km} km)',
      'trPromoWithCode': 'Promo ({code})',
      'trYouEarned': 'You earned {amount}',
      'trEtaMin': 'ETA {n} min',
      'trFromPlace': 'From: {place}',
      'trToPlace': 'To: {place}',
      'trFareKhr': 'Fare: {amount} ៛',
      'trCar': 'Car',
      'trBike': 'Bike',
      'trTukTuk': 'Tuk-Tuk',
      'trVan': 'Van',
      'trHome': 'Home',
      'trWork': 'Work',
      'trCash': 'Cash',
      'trWalletTopUp': 'Wallet Top-up',
      'trTripEarning': 'Trip Earning',
      'trPlatformFee': 'Platform Fee',
      'trBonusCredit': 'Bonus Credit',
      'trTripPayment': 'Trip Payment',
      'trRefund': 'Refund',
      'trGoogleNotConfigured': 'Google sign-in is not configured for this app. Contact support.',
      'trAdminRole': 'Admin',
      'trEnterOtp': 'Enter OTP',
      'trPhoneLogin': 'Phone Login',
      'trCodeSentTo': 'Code sent to {phone}',
      'trWeSendSmsCode': 'We\'ll send a one-time code via SMS',
      'trResendCodeIn': 'Resend code in {n}s',
      'trThisAccount': 'this account',
      'trRemoveAccount': 'Remove Account',
      'trUnlinkConfirm': 'Unlink {name} from your account?',
      'trSwitchAccount': 'Switch Account',
      'trLinkAccount': 'Link Account',
      'trNoLinkedAccounts': 'No linked accounts',
      'trLinkAnotherAccount': 'Link another account to switch between them.',
      'trLabelOptionalWork': 'Label (optional, e.g. "Work")',
      'trNewCodeSent': 'New code sent',
      'trVerifyPhone': 'Verify Phone',
      'trEnterVerificationCode': 'Enter verification code',
      'trDidntReceiveCode': 'Didn\'t receive the code? ',
      'trResendInSeconds': 'Resend in {n}s',
      'trNoTasksNow': 'No {label} tasks right now',
      'trSosFailedCall': 'SOS failed to send. Please call emergency services directly.',
      'trNoDestinationMeteredFare': 'This trip had no destination set — enter the metered fare to complete it.',
      'trCouldntAutoCalc': 'Couldn\'t auto-calculate a suggestion: ',
      'trFromKmTravelled': 'from {km} km',
      'trUser': 'User',
      'trCreditName': 'Credit {name}',
      'trAmountKhr': 'Amount (KHR)',
      'trNoteOptional': 'Note (optional)',
      'trCredit': 'Credit',
      'trCreditApplied': 'Credit applied.',
      'trDeleteUser': 'Delete User',
      'trPermanentlyDelete': 'Permanently delete {name}?',
      'trUsers': 'Users',
      'trSearchNameEmail': 'Search by name / email…',
      'trAllRoles': 'All Roles',
      'trNoUsersFound': 'No users found.',
      'trCreditWallet': 'Credit Wallet',
      'trNotifications': 'Notifications',
      'trMarkAllRead': 'Mark all read',
      'trNoNotificationsYet': 'No notifications yet',
      'trCarRental': 'Car rental',
      'trMarketplaceOrder': 'Marketplace order',
      'trManageOnWebAdmin': 'Confirm or manage this order from the web admin panel.',
      'trTransactions': 'Transactions',
      'trDebit': 'Debit',
      'trTopUp': 'Top-up',
      'trWithdraw': 'Withdraw',
      'trNoTransactions': 'No transactions.',
      'trDriverApproved': 'Driver approved',
      'trDriverRejected': 'Driver rejected',
      'trDriverApplications': 'Driver Applications',
      'trNoPendingApplications': 'No pending applications',
      'trRejectDriver': 'Reject Driver',
      'trProvideReasonOptional': 'Provide a reason (optional):',
      'trEgDocsUnclear': 'e.g. Documents unclear, ID expired…',
      'trReviewDocs': 'Review Docs',
      'trNationalIdPassport': 'National ID / Passport',
      'trDriverLicense': 'Driver License',
      'trVehicleRegistration': 'Vehicle Registration',
      'trSelfieWithId': 'Selfie with ID',
      'trVehicleInsurance': 'Vehicle Insurance',
      'trOtherDocument': 'Other Document',
      'trRejectDocument': 'Reject Document',
      'trReasonImageBlurry': 'Reason (e.g. Image too blurry)',
      'trApproveDriver': 'Approve Driver',
      'trServiceZoneOptional': 'Service zone (optional):',
      'trEgZoneA': 'e.g. Phnom Penh Zone A',
      'trConfirmApprove': 'Confirm Approve',
      'trDriverApprovedExcl': 'Driver approved!',
      'trDocuments': 'Documents',
      'trNoDocumentsYet': 'No documents uploaded yet.',
      'trNoteWith': 'Note: {note}',
      'trViewDocument': 'View Document',
      'trPricingSaved': 'Pricing settings saved.',
      'trPricingSettings': 'Pricing Settings',
      'trSaveSettings': 'Save Settings',
      'trDeleteBanner': 'Delete Banner',
      'trRemoveBannerQ': 'Remove this banner?',
      'trBanners': 'Banners',
      'trNoBannersYet': 'No banners yet.',
      'trUntitled': 'Untitled',
      'trNewBanner': 'New Banner',
      'trEditBanner': 'Edit Banner',
      'trSubtitleDescription': 'Subtitle / Description',
      'trImageUrlOptional': 'Image URL (optional)',
      'trSaveBanner': 'Save Banner',
      'trSupportTickets': 'Support Tickets',
      'trOpen': 'Open',
      'trInProgress': 'In Progress',
      'trResolved': 'Resolved',
      'trClosed': 'Closed',
      'trNoTicketsFound': 'No tickets found.',
      'trNoSubject': 'No subject',
      'trTicketNo': 'Ticket #{id}',
      'trMarkOpen': 'Mark Open',
      'trMarkInProgress': 'Mark In Progress',
      'trMarkResolved': 'Mark Resolved',
      'trMarkClosed': 'Mark Closed',
      'trTypeReply': 'Type a reply…',
      'trTopUpApproved': 'Top-up approved & wallet credited.',
      'trRejectTopUp': 'Reject Top-up',
      'trReasonColon': 'Reason:',
      'trEnterReason': 'Enter reason',
      'trRejectedDot': 'Rejected.',
      'trTopUpRequests': 'Top-up Requests',
      'trNoTopUpRequests': 'No top-up requests.',
      'trCancelRide': 'Cancel Ride',
      'trReasonForCancellation': 'Reason for cancellation:',
      'trEgPolicyViolation': 'e.g. Policy violation',
      'trRides': 'Rides',
      'trNoRidesFound': 'No rides found.',
      'trApproveWithdrawal': 'Approve Withdrawal',
      'trAddNoteOptional': 'Add a note (optional):',
      'trEgTransferredAba': 'e.g. Transferred via ABA',
      'trApprovedDot': 'Approved.',
      'trRejectWithdrawal': 'Reject Withdrawal',
      'trReasonRequired': 'Reason (required):',
      'trEgInvalidAccount': 'e.g. Invalid account number',
      'trWithdrawals': 'Withdrawals',
      'trNoWithdrawalsFound': 'No withdrawals found.',
      'trSafetyIncidents': 'Safety Incidents',
      'trCrash': 'Crash',
      'trUserReport': 'User Report',
      'trNoSafetyIncidents': 'No safety incidents.',
      'trDeliveries': 'Deliveries',
      'trNoDeliveriesFound': 'No deliveries found.',
      'trAdminDashboard': 'Admin Dashboard',
      'trRevenue7Days': 'Revenue (7 days)',
      'trSurgePromoControl': 'Surge & Promo Control',
      'trSurge': 'Surge',
      'trPromos': 'Promos',
      'trThisZone': 'this zone',
      'trDeleteSurgeZone': 'Delete Surge Zone',
      'trDeleteNamedQ': 'Delete "{name}"?',
      'trNewZone': 'New Zone',
      'trNoSurgeZones': 'No surge zones configured.',
      'trNewSurgeZone': 'New Surge Zone',
      'trEditSurgeZone': 'Edit Surge Zone',
      'trZoneName': 'Zone Name',
      'trEgCityCentre': 'e.g. City Centre',
      'trDescriptionOptional': 'Description (optional)',
      'trEgHighDemand': 'e.g. High demand area',
      'trMultiplierX': 'Multiplier: ×{x}',
      'trCreateZone': 'Create Zone',
      'trSaveChanges': 'Save Changes',
      'trDeletePromo': 'Delete Promo',
      'trNewPromo': 'New Promo',
      'trNoPromoCodes': 'No promo codes.',
      'trAmountOff': '{amount} off',
      'trUsesLeft': '{n} uses left',
      'trExpShort': 'Exp {date}',
      'trCodeDiscountRequired': 'Code and discount amount are required.',
      'trEditPromoCode': 'Edit Promo Code',
      'trNewPromoCode': 'New Promo Code',
      'trPromoCode': 'Promo Code',
      'trDiscountKhr': 'Discount (KHR)',
      'trMaxUsesHint': 'Max Uses (leave blank = unlimited)',
      'trExpiresAtHint': 'Expires At (YYYY-MM-DD)',
      'trCreatePromo': 'Create Promo',
      'trDeleteFareRule': 'Delete Fare Rule',
      'trThisVehicle': 'this vehicle',
      'trFareManagement': 'Fare Management',
      'trAddRule': 'Add Rule',
      'trNoFareRules': 'No fare rules configured.',
      'trBaseFare': 'Base Fare',
      'trPerKm': 'Per KM',
      'trMinimum': 'Minimum',
      'trFillFareFields': 'Please fill all fare fields with valid numbers.',
      'trEditFareRule': 'Edit Fare Rule',
      'trNewFareRule': 'New Fare Rule',
      'trBaseFareKhr': 'Base Fare (KHR)',
      'trPerKmRateKhr': 'Per KM Rate (KHR)',
      'trMinimumFareKhr': 'Minimum Fare (KHR)',
      'trCreateRule': 'Create Rule',
      'trDestination': 'Destination',
      'trFindingDriver': 'Finding driver…',
      'trDriverOnTheWay': 'Driver on the way',
      'trDriverEnRoutePickup': 'Driver en route to pickup',
      'trTripInProgress': 'Trip in progress',
      'trTripCompleted': 'Trip completed',
      'trTripCancelled': 'Trip cancelled',
      'trLiveTrip': 'ROTEH — Live Trip',
      'trMovingService': 'Moving Service',
      'trWaitingDriverGps': 'Waiting for driver GPS…',
      'trPageAutoUpdates': 'This page updates automatically every 8 seconds.',
      'trTripNotFound': 'Trip not found',
      'trLookingForDriver': 'Looking for a driver...',
      'trDriverAssigned': 'Driver assigned',
      'trDriverArrivedPickup': 'Driver arrived at pickup',
      'trLoadingItems': 'Loading items...',
      'trOnWayToDestination': 'On the way to destination',
      'trMovingCompletedExcl': 'Moving completed!',
      'trProcessingDots': 'Processing...',
      'trPackagePickedUp': 'Package picked up',
      'trOnWayToRecipient': 'On the way to recipient',
      'trDeliveredExcl': 'Delivered!',
      'trPackageDelivery': 'Package Delivery',
      'trTrackMy': 'Track my {service}',
      'trTrackMyLive': 'Track my {title} live',
      'trMovingCompleted': 'Moving Completed',
      'trDeliveryCompletedTitle': 'Delivery Completed',
      'trMoving': 'Moving',
      'trRecipientLine': 'Recipient: {name}',
      'trDriverLine': 'Driver: {name}',
      'trShareMovingTracking': 'Share Moving Tracking',
      'trShareDeliveryTracking': 'Share Delivery Tracking',
      'trPendingFirstRide': 'Pending first ride',
      'trSedan': 'Sedan',
      'trUpTo4Pax': 'Up to 4 pax',
      'trSuvVan': 'SUV/Van',
      'trUpTo6Pax': 'Up to 6 pax',
      'trDriverArrivingPickup': '{name} is arriving at your pickup point.',
      'trDriverWaitingAt': '{name} is waiting at {place}',
      'trSosSentToContacts': '🆘 SOS sent to {n} contact(s)',
      'trChatWithSupport': 'Chat with Support',
      'trPaidBySender': 'paid by sender',
      'trPaidByRecipient': 'paid by recipient',
      'trScheduleWithFare': 'Schedule — {fare}',
      'trConfirmWithFare': 'Confirm — {fare}',
      'trAddedToWallet': '{amount} has been added to your wallet.',
      'trRecipientPhoneNumber': 'Recipient\'s phone number',
      'trConfirmAndPay': 'Confirm & Pay',
      'trNewRideRequest': '🚗 New Ride Request',
      'trNewRequest': 'New request',
      'trSubscribed': 'Subscribed!',
      'trPlanUpgraded': 'Plan upgraded!',
      'trSubscriptionCancelled': 'Subscription cancelled.',
      'trTransferred': 'Transferred.',
      'trSearchLocation': 'Search location…',
      'trFindingAddress': 'Finding address…',
      'trMoveMapToSet': 'Move map to set location',
      'trConfirmLocation': 'Confirm Location',
      'trTapOpenGoogleMaps': 'Tap to open Google Maps',
      'trOpenInMaps': 'Open in Maps',
      'trSearchAddressHint': 'Search address, place or landmark…',
      'trUseMyLocation': 'Use my current location',
      'trDetectedViaGps': 'Detected via GPS',
      'trTypeToSearchPlace': 'Type to search for a place',
      'trNoResultsFor': 'No results for "{q}"',
      'trMoveTheMapToSet': 'Move the map to set location',
      'trUseThisLocation': 'Use this location',
      'trPromotions': 'Promotions',
      'trSlowConnection': 'Experiencing a slow connection?',
      'trSwipeToRefresh': 'Swipe down and release to refresh',
      'trPurchases': 'Purchases',
      'trRentals': 'Rentals',
      'trPaymentsCancels': 'Payments & Cancels',
      'trPerMinuteRateKhr': 'Per Minute Rate (KHR)',
      'trCancelFeeAfterArrival': 'Cancel Fee After Arrival',
      'trWaitingFreeMinutes': 'Waiting Free Minutes',
      'trWaitingFeePerMinuteKhr': 'Waiting Fee Per Minute (KHR)',
      'trNightSurchargePct': 'Night Surcharge (%)',
      'trPlatformCommissionPct': 'Platform Commission (%)',
      'trStepOrder': 'Order',
      'trStepDriverAssigned': 'Driver\nAssigned',
      'trStepPickedUp': 'Picked Up',
      'trStepOnTheWay': 'On the\nWay',
      'trStepDelivered': 'Delivered',
      'trStepAccepted': 'Accepted',
      'trStepArrived': 'Arrived',
      'trStepLoading': 'Loading',
      'trStepInTransit': 'In Transit',
      'trStepDone': 'Done',
      'trGoogleCancelled': 'Google sign-in was cancelled.',
      'trEnterEmailPassword': 'Please enter your email and password.',
      'trCannotReachServer': 'Cannot reach server.',
      'trEnterYourPhone': 'Enter your phone number.',
      'trDevModeCode': 'Dev mode — no real SMS sent. Your code is {code}',
      'trActiveCount': 'Active ({n})',
      'trCompletedCount': 'Completed ({n})',
      'trTitleRequired': 'Title is required.',
      'trZoneNameRequired': 'Zone name is required.',
      'trDeletePromoCodeQ': 'Delete promo code "{code}"?',
      'trBaseFareLower': 'Base fare',
      'trTimeMin': 'Time ({n} min)',
      'trNoFee': 'No fee',
      'trInstant': 'Instant',
      'trSurgeActiveArea': '{x}× surge pricing active in your area',
      'trSurgeHighDemand': '{x}× surge pricing — high demand in your area',
      'trNoListingMatchesFilter': 'No listing matches that filter — showing your original pick.',
      'trPaymentSuccessful': '✅ Payment Successful',
      'trPaidVia': '{amount} paid via {method}',
      'trSetLocation': 'Set Location',
      'trNetworkErrorCheck': 'Network error — check your connection',
      'trEnableBiometric': 'Enable biometric login for ROTEH',
      'trSignInToRoteh': 'Sign in to ROTEH',
      'deleteAccountLabel': 'Delete account',
      'deleteAccountTitle': 'Delete your account?',
      'deleteAccountMessage': 'This permanently deletes your name, email, phone number, saved places and emergency contacts, and signs you out on every device. Trip and payment history is kept for accounting but no longer linked to you. This cannot be undone.',
      'deleteAccountConfirm': 'Delete permanently',
      'deleteAccountDone': 'Your account has been deleted.',
      'trCouldNotCompleteTrip': 'Could not complete the trip — check your connection and try again.',
      'trSurchargesLine': 'Surcharges & minimum fare',
      'trMeterSoFar': 'Distance so far',
      'pkExportReport': 'Export report',
      'pkExportPdf': 'PDF',
      'pkExportPdfSub': 'Summary, chart and package list — easy to print or send',
      'pkExportExcel': 'Excel',
      'pkExportExcelSub': 'Every package with receiver names and addresses',
      'pkStatusCompleted': 'Completed',
      'pkStatusFailed': 'Not delivered',
      'pkStatusReturned': 'Returned to shop',
      'pkReasonCannotContact': 'Cannot contact receiver',
      'pkReasonRefused': 'Receiver refused',
      'pkReasonWrongAddress': 'Wrong address',
      'pkReasonPostponed': 'Receiver asked to deliver later',
      'pkReasonOther': 'Other reason',
      'pkReturningToShop': 'The driver is bringing it back to your shop',
      'pkReports': 'Reports',
      'pkReportsSub': 'Daily, weekly and monthly',
      'pkDay': 'Day',
      'pkWeek': 'Week',
      'pkMonth': 'Month',
      'pkTotalPackages': 'Total packages',
      'pkSuccessRate': 'Success rate',
      'pkInProgress': 'In progress',
      'pkDeliveryFees': 'Delivery fees',
      'pkCodCollected': 'COD collected',
      'pkAvgTime': 'Avg. delivery time',
      'pkMinutes': '{n} min',
      'pkFailureReasons': 'Why packages were not delivered',
      'pkNoData': 'No packages in this period',
      'pkToday': 'Today',
      'pkThisWeek': 'This week',
      'pkThisMonth': 'This month',
      'pkByHour': 'Packages by hour',
      'pkByDay': 'Packages by day',
      'pkTodaySummary': 'Today: {done} completed · {back} returned · {open} in progress',
      'drvCantDeliver': 'Can\'t deliver',
      'drvCantDeliverTitle': 'Why can\'t you deliver?',
      'drvFailNote': 'Note (optional)',
      'drvReportFail': 'Report & return to shop',
      'drvReturningTitle': 'Return the package to the shop',
      'drvReturnedToShop': 'Returned to shop',
      'drvDeliveredAfterAll': 'Receiver answered — mark delivered',
      'drvReturnDone': 'Package returned to the shop',
      'pkPartnerServices': 'Partner Services',
      'pkCreatePackage': 'Create Package',
      'pkCreatePackageSub': 'ROTEH picks up & delivers',
      'pkMyPackages': 'My Packages',
      'pkMyPackagesSub': 'All your packages',
      'pkTrackPackage': 'Track Package',
      'pkTrackPackageSub': 'Packages on the way',
      'pkHistory': 'Package History',
      'pkHistorySub': 'Delivered & cancelled',
      'pkActiveCount': '{n} on the way',
      'pkTodayCount': '{n} today',
      'pkCodPending': 'COD to collect',
      'pkBecomePartner': 'Become a ROTEH Partner',
      'pkBecomePartnerSub': 'Send packages — ROTEH picks up and delivers to your customers',
      'pkPartnerAccount': 'ROTEH Partner',
      'pkPendingTitle': 'Registration under review',
      'pkPendingBody': 'ROTEH is reviewing your Partner registration. You will get a notification once it is approved.',
      'pkRejectedTitle': 'Registration not approved',
      'pkSuspendedTitle': 'Partner account suspended',
      'pkSuspendedBody': 'Please contact ROTEH support.',
      'pkResubmit': 'Update and resubmit',
      'pkRegisterTitle': 'Register as a Partner',
      'pkRegisterIntro': 'Use this same account. After ROTEH approves, you can create packages and track them here — and still book rides as usual.',
      'pkBusinessName': 'Shop / business name',
      'pkBusinessType': 'Business type',
      'pkContactName': 'Contact person (optional)',
      'pkBusinessPhone': 'Business phone',
      'pkPickupAddress': 'Usual pickup address',
      'pkSubmit': 'Submit registration',
      'pkRequired': 'Please fill in this field',
      'pkTypeOnlineShop': 'Online shop',
      'pkTypeRetail': 'Shop / retail',
      'pkTypeRestaurant': 'Restaurant / food',
      'pkTypeOther': 'Other',
      'pkSender': 'Sender',
      'pkReceiver': 'Receiver',
      'pkName': 'Name',
      'pkPhone': 'Phone number',
      'pkPickupLocation': 'Pickup location',
      'pkDeliveryLocation': 'Delivery location',
      'pkChooseOnMap': 'Tap to choose on map',
      'pkPackage': 'Package',
      'pkPackageType': 'Package type',
      'pkDescription': 'Description (what is inside)',
      'pkWeight': 'Weight (kg, optional)',
      'pkSize': 'Size',
      'pkPhoto': 'Package photo (optional)',
      'pkAddPhoto': 'Add photo',
      'pkCamera': 'Camera',
      'pkGallery': 'Gallery',
      'pkService': 'Delivery speed',
      'pkNormal': 'Normal',
      'pkExpress': 'Express',
      'pkPayment': 'Payment',
      'pkWhoPays': 'Who pays the delivery fee?',
      'pkPartnerPays': 'I pay',
      'pkReceiverPays': 'Receiver pays (cash)',
      'pkCodAmount': 'Collect from receiver — item price (៛)',
      'pkCodHint': 'Leave empty if there is nothing to collect',
      'pkReference': 'Your order number (optional)',
      'pkNotes': 'Note for the driver (optional)',
      'pkDeliveryFee': 'Delivery fee',
      'pkSubmitPackage': 'Create package',
      'pkChooseLocations': 'Choose both the pickup and delivery locations on the map',
      'pkCreatedTitle': 'Package created',
      'pkCreatedBody': '{code} is waiting for ROTEH to confirm. We will notify you when a driver is on the way.',
      'pkStatusPending': 'Pending',
      'pkStatusConfirmed': 'Confirmed',
      'pkStatusDriverAssigned': 'Driver assigned',
      'pkStatusPickedUp': 'Picked up',
      'pkStatusInTransit': 'In transit',
      'pkStatusDelivered': 'Delivered',
      'pkStatusCancelled': 'Cancelled',
      'pkTabActive': 'On the way',
      'pkTabHistory': 'History',
      'pkTabAll': 'All',
      'pkSearchHint': 'Search code, receiver or phone',
      'pkEmptyActive': 'No packages on the way',
      'pkEmptyHistory': 'No delivered or cancelled packages yet',
      'pkEmptyAll': 'No packages yet',
      'pkDetailTitle': 'Package details',
      'pkTimeline': 'Tracking',
      'pkDriver': 'Driver',
      'pkCall': 'Call',
      'pkLiveMap': 'Live map',
      'pkShareLink': 'Share tracking link',
      'pkShareText': 'Track your ROTEH package {code}: {url}',
      'pkCancelPackage': 'Cancel package',
      'pkCancelConfirm': 'Cancel this package? This cannot be undone.',
      'pkCancelReason': 'Reason (optional)',
      'pkKeep': 'Keep',
      'pkQrTitle': 'Package QR',
      'pkQrHint': 'Stick this on the package — the driver scans it at pickup and delivery.',
      'pkProofPhoto': 'Delivery proof',
      'pkWaitingConfirm': 'Waiting for ROTEH to confirm',
      'pkFindingDriver': 'ROTEH is finding a driver',
      'pkPaymentByReceiver': 'Receiver pays',
      'pkPaymentByPartner': 'You pay',
      'pkCod': 'COD',
      'pkSizeSmall': 'Small',
      'pkSizeMedium': 'Medium',
      'pkSizeLarge': 'Large',
      'pkSizeXL': 'Extra large',
      'pkTypeDocument': 'Document',
      'pkTypeParcel': 'Parcel',
      'pkTypeFood': 'Food',
      'pkTypeClothing': 'Clothing',
      'pkTypeElectronics': 'Electronics',
      'pkTypeFragile': 'Fragile',
      'pkPayMethod': 'Pay with',
      'pkPayCash': 'Cash to driver',
      'pkPayWallet': 'ROTEH Pay',
      'pkPayAba': 'ABA / KHQR',
      'pkCreated': 'Created',
      'paywayOrderPaidBody': 'Your payment of {amount} was received. Thank you!',
      'paywayNotAvailable': 'ABA payment is not available yet. You can pay later from this order.',
      'paywayPayNow': 'Pay with ABA / KHQR',
      'paywayUnpaid': 'Not paid yet',
      'paywayPaidLabel': 'Paid',
      'paywayTitle': 'Pay with ABA / KHQR',
      'paywayScanHint': 'Scan with ABA Mobile, ACLEDA or any KHQR bank app.',
      'paywayWaiting': 'Waiting for payment',
      'paywayExpired': 'This QR has expired. Please try again.',
      'paywayFailed': 'The payment was not completed.',
      'paywayOpenAba': 'Open ABA Mobile',
      'paywayIPaid': 'I have paid — check now',
      'paywayRef': 'Reference',
      'paywayPaidTitle': 'Payment received',
      'paywayPaidBody': '{amount} has been added to your ROTEH Pay wallet.',
      'helmetConfidence': 'Confidence: {value}',
      'helmetCheckFailed': 'Could not check the photo. Please try again.',
      'txStatusPending': 'Pending',
      'txStatusProcessing': 'Processing',
      'txStatusFailed': 'Failed',
      'txStatusRejected': 'Rejected',
      'txFilterIncome': 'Income',
      'txFilterDeductions': 'Deductions',
      'txNoneForFilter': 'No transactions here yet.',
      'txWithdrawalPending': 'Withdrawal (waiting for approval)',
      'txWithdrawal': 'Withdrawal',
      'txWithdrawalReturned': 'Withdrawal rejected — money returned',
      'txTransferIn': 'Money received',
      'txTransferOut': 'Money sent',
      'txTipIn': 'Tip received',
      'txTipOut': 'Tip',
      'txSalary': 'Salary',
      'txDeliveryPayment': 'Delivery payment',
      'txCancellationFee': 'Cancellation fee',
      'txAdminCredit': 'Credit from support',
      'txReferralReward': 'Referral reward',
      'txCompanyShare': 'Company share',
      'txLoyaltyRedemption': 'Points redeemed',
      'topUpPendingTitle': 'Top-up waiting for approval',
      'topUpPendingStatus': 'Waiting for approval',
      'topUpPendingBlocked': 'You already have a top-up waiting for approval. Please wait until it is approved.',
      'drvLowBalanceOfflineTitle': 'Money withdrawn — you are offline',
      'drvLowBalanceOfflineMsg': 'Your wallet now has {balance}, below the {min} needed to go online and accept jobs. Please top up your wallet to work again.',
      'drvTripCancelledTitle': 'Trip cancelled',
      'drvRequestNoLongerAvailable': 'This request is no longer available — it was cancelled or taken by another driver.',
      'drvSenderCancelledDelivery': 'The customer cancelled that delivery request.',
      'trCancelledStatus': 'Cancelled',
      'trDeliveryCancelledTitle': 'Delivery cancelled',
      'trMovingCancelledTitle': 'Moving cancelled',
      'trCancelledByDriver': 'The driver cancelled this order.',
      'trCancelledByAdmin': 'Our support team cancelled this order.',
      'trCancelledByYou': 'You cancelled this order.',
      'trCancelledGeneric': 'This order was cancelled.',
      'trCancelReason': 'Reason: {reason}',
      'trGoBack': 'Go back',
      'drvGreeting': 'Hello, {name}!',
      'drvFindingRides': 'Looking for new rides…',
      'drvTodayStats': 'Today\'s stats',
      'drvTodayEarnings': 'Today\'s earnings',
      'drvWalletBalance': 'Wallet balance',
      'drvAcceptRides': 'Accept rides',
      'drvRideSub': 'Passengers',
      'drvDeliverySub': 'Parcels & food',
      'drvRentalSub': 'Rent out vehicle',
      'drvNoRecentTrips': 'No trips yet — go online to start earning.',
      'drvHelp': 'Help',
      'trRecipientLine2': 'Recipient: {name}',
      'trForName': 'For: {name}',
      'trClassicTukTuk': 'Classic tuk-tuk',
      'trStdPremiumVan': 'Standard, Premium & Van',
      'busy': 'Busy',
      'full': 'Full',
      'chooseRide': 'Choose your ride',
      'promoCode': 'Add promo code',
      'scheduleDelivery': 'Schedule delivery',
      'packageDetails': 'Package Details',
      'packageSize': 'Package Size',
      'sendAnything': 'Send anything,\nanywhere fast!',
      'avgDelivery': 'Average delivery: 25 min',
      'incomingRequest': 'Incoming Request',
      'acceptRide': 'Accept Ride',
      'decline': 'Decline',
      'todayPerformance': "Today's Performance",
      'recentTripsDriver': 'Recent Trips',
      'dailyBreakdown': 'Daily Breakdown',
      'withdrawEarnings': 'Withdraw Earnings',
      'evCarsAvailable': 'EV Cars Now Available!',
      'evCarsSubtitle': 'Rent or buy electric vehicles near you',
      'explore': 'Explore',
      'completed': 'Completed',
      'eta': 'ETA',
      'min': 'min',
      'km': 'km',
      'activeRideInProgress': 'Active ride in progress',
      'noRecentTrips': 'No recent trips',
      'searchProductsHint': 'Search products…',
      'filter': 'Filter',
      'listingsAvailable': 'listings available',
      'findBestDeal': 'Find the best deal',
      'browseAll': 'Browse All',
      'rentalVehicle': 'Rental Vehicle',
      'tryAgain': 'Try Again',
      'results': 'results',
      'noListingsFound': 'No listings found',
      'tryDifferentFilters': 'Try different filters',
      'salePrice': 'Sale Price',
      'rentPerDay': 'Rent / day',
      'qty': 'Qty',
      'verifiedSeller': 'Verified Seller',
      'editListing': 'Edit Listing',
      'fillRequiredFields': 'Please fill in all required fields',
      'shopAsGuest': 'Shop as guest',
      'continueAsGuest': 'Continue as Guest',
      'welcomeBack': "Welcome back",
      'signInSubtitle': "Sign in to manage your orders, rides and deliveries.",
      'noAccountYet': "Don't have an account?",
      'signInWithBiometrics': "Sign in with biometrics",
      'signInAs': "Sign in as",
      'secureSignInNote': "Your information is encrypted and kept secure.",
      'welcomeTagline': 'Buy  •  Rent  •  Deliver  •  Move',
      'welcomeTitle': 'Welcome to ROTEH APP',
      'welcomeSubtitle': 'Buy or rent products, delivered to your door — no account required.',
      'orContinueWith': 'or continue with',
      'continueWithPhone': 'Continue with Phone',
      'continueWithGoogle': 'Continue with Google',
      'secureCheckoutNote': 'Secure checkout  •  Verify phone number when placing an order',
      'continueAsGuestSub': 'Buy or rent products without an account',
      'guestShoppingNotice': "You're shopping as a guest — orders are saved on this phone.",
      'orderPlaced': 'Order Placed!',
      'purchaseRequestSent': 'Your purchase request has been sent to the seller.',
      'done': 'Done',
      'purchaseProduct': 'Purchase Product',
      'couponCode': 'Coupon Code',
      'phoneNumber': 'Phone Number',
      'confirmInformation': 'Confirm Information',
      'verifyAddressesNote': 'Please verify all addresses and contact details before '
          'proceeding. The seller will be notified once your order is placed.',
      'purchaseNow': 'Purchase Now',
      'findingAddress': 'Finding address…',
      'locationType': 'Location Type',
      'rentalDuration': 'Rental Duration',
      'orderPlacedSuccess': 'Order placed successfully!',
      'paymentMethod': 'Payment Method',
      'startDate': 'Start Date',
      'endDateAuto': 'End Date (auto)',
      'selectStartDate': 'Select a start date',
      'discountApplied': 'discount applied',
      'apply': 'Apply',
      'total': 'Total',
      'deleteListing': 'Delete listing?',
      'willBePermanentlyRemoved': 'will be permanently removed.',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'postAListing': 'Post a Listing',
      'noOrdersYet': 'No orders yet',
      'order': 'Order',
      'left': 'left',
      'savedPlaces': 'Saved places',
      'noSavedPlacesYet': 'No saved places yet.',
      'promoCodeTitle': 'Promo Code',
      'browseVouchers': 'Browse available vouchers →',
      'cambodia': 'Cambodia',
      'mapLabel': 'Map',
      'noResultsFound': 'No results found',
      'addAStop': 'Add a stop',
      'whereTo': 'Where to?',
      'now': 'Now',
      'confirmBooking': 'Confirm Booking',
      'noDestinationNeeded': 'No destination needed — tell the driver in person',
      'whereToTitle': 'Where To?',
      'noSavedPlaces': 'No saved places',
      'confirmDestination': 'Confirm Destination',
      'whereToOptional': 'Where to? (optional)',
      'chooseRideTitle': 'Choose Ride',
      'scrollUpForMore': 'Scroll up for more ride options',
      'discountSuffix': 'discount',
      'noDestinationSelected': 'No destination selected',
      'selectDestination': 'Select Destination',
      'deliveryAndMoving': 'Delivery & Moving',
      'moveWithEase': 'Move with ease,\nwe handle the rest!',
      'professionalMovingService': 'Professional moving service',
      'scheduleMovingDate': 'Schedule moving date',
      'selectLocationsForFare': 'Select pickup and dropoff locations to see fare estimate',
      'calculatingFare': 'Calculating fare…',
      'yes': 'Yes',
      'no': 'No',
      'helpersNeeded': 'Helpers needed',
      'personsForCarrying': '1–4 persons for carrying',
      'fareEstimate': 'Fare Estimate',
      'totalEstimate': 'Total estimate',
      'finalPriceConfirmed': 'Final price confirmed after booking',
      'change': 'Change',
      'confirmLocation': 'Confirm Location',
      'confirmDeliveryBooking': 'Confirm Delivery Booking',
      'noCancel': 'No, Cancel',
      'yesSendNow': 'Yes, Send Now',
      'confirmMovingBooking': 'Confirm Moving Booking',
      'estimatedFare': 'Estimated Fare',
      'yesBookNow': 'Yes, Book Now',
      'couldNotFetchEstimate': 'Could not fetch estimate',
      'rideCancelled': 'Ride Cancelled',
      'ok': 'OK',
      'stop': 'Stop',
      'dropoff': 'Dropoff',
      'safetyCentre': 'SAFETY CENTRE',
      'fare': 'Fare',
      'sendSOSQuestion': '🆘 Send SOS?',
      'sendSOS': 'Send SOS',
      'sosFailed': 'SOS failed',
      'driverPhoneNotAvailable': 'Driver phone not available yet.',
      'cannotDialPrefix': 'Cannot dial',
      'onThisDevice': 'on this device.',
      'couldNotGenerateShareLink': 'Could not generate share link',
      'linkCopied': 'Link copied to clipboard',
      'shareTrip': 'Share Trip',
      'friendsCanTrack': 'Friends & family can track your ride live',
      'driverLabel': 'Driver',
      'copyLink': 'Copy link',
      'shareVia': 'Share via...',
      'stopSharingLocation': 'Stop sharing location',
      'cancelRide': 'Cancel Ride',
      'keepRide': 'Keep Ride',
      'businessAccount': 'Business Account',
      'noBusinessAccount': 'No Business Account',
      'registerOrJoinBusiness': 'Register your company or join an existing business account.',
      'enterInviteCode': 'Enter the invite code your company admin shared with you.',
      'fillSampleData': 'Fill sample data',
      'leaveBusinessQuestion': 'Leave Business?',
      'loseBusinessAccess': 'You will no longer have access to business features.',
      'leave': 'Leave',
      'edit': 'Edit',
      'active': 'Active',
      'removeMemberQuestion': 'Remove Member?',
      'remove': 'Remove',
      'noMembersYet': 'No members yet.',
      'noBusinessTripsYet': 'No business trips yet.',
      'refresh': 'Refresh',
      'retry': 'Retry',
      'businessRegistered': 'Business Registered!',
      'shareInviteCodeNote': 'Share this invite code with your employees so they can join.',
      'inviteCodeCopied': 'Invite code copied!',
      'copyCode': 'Copy Code',
      'member': 'Member',
      'removeMemberPrefix': 'Remove',
      'thisMember': 'this member',
      'fromBusinessAccountSuffix': 'from the business account?',
      'refLabel': 'Ref',
      'promotions': 'Promotions',
      'editProfile': 'Edit Profile',
      'rotehPay': 'ROTEH Pay',
      'qrPayment': 'QR Payment',
      'promosVouchers': 'Promos & Vouchers',
      'scheduledRides': 'Scheduled Rides',
      'subscriptionPlans': 'Subscription Plans',
      'rotehRewards': 'ROTEH Rewards',
      'referEarn': 'Refer & Earn',
      'myRentals': 'My Rentals',
      'switchToDriverMode': 'Switch to Driver Mode',
      'settings': 'Settings',
      'missions': 'Missions',
      'myEarnings': 'My Earnings',
      'topUpWallet': 'Top Up Wallet',
      'helmetCheck': 'Helmet Check',
      'switchToPassengerMode': 'Switch to Passenger Mode',
      'darkMode': 'Dark Mode',
      'rideLabel': 'Ride',
      'rental': 'Rental',
      'accepted': 'Accepted',
      'hoursOnline': 'Hours Online',
      'acceptanceRate': 'Acceptance Rate',
      'verified': 'Verified',
      'trips': 'Trips',
      'bonuses': 'Bonuses',
      'fees': 'Fees',
      'topUps': 'Top-ups',
      'heavyItems': '⚠ Heavy items',
      'packing': '📦 Packing',
      'management': 'Management',
      'users': 'Users',
      'drivers': 'Drivers',
      'ridesAdmin': 'Rides',
      'deliveriesAdmin': 'Deliveries',
      'withdrawalsAdmin': 'Withdrawals',
      'supportAdmin': 'Support',
      'transactionsAdmin': 'Transactions',
      'fareRules': 'Fare Rules',
      'surgeZones': 'Surge Zones',
      'pricingAdmin': 'Pricing',
      'bannersAdmin': 'Banners',
      'safetyAdmin': 'Safety',
      'passengersStat': 'Passengers',
      'driversTotal': 'Drivers Total',
      'onlineDrivers': 'Online Drivers',
      'pendingDrivers': 'Pending Drivers',
      'ridesToday': 'Rides Today',
      'activeRides': 'Active Rides',
      'deliveriesToday': 'Deliveries Today',
      'revenueToday': 'Revenue Today',
      'revenueWeek': 'Revenue Week',
      'growth': 'Growth',
      'openTickets': 'Open Tickets',
      'safetyIncidents': 'Safety Incidents',
      'driverApprovalsSuffix': 'Driver Approvals',
      'ticketsSuffix': 'Tickets',
      'serviceModes': 'Service Modes',
      'overview': 'Overview',
      'pendingActionsSuffix': 'pending actions',
      'clearAll': 'Clear all',
      'size': 'Size',
      'vehicleType': 'Vehicle Type',
      'color': 'Color',
      'options': 'Options',
      'accessories': 'Accessories',
      'addAccessory': 'Add Accessory',
      'optional': 'Optional',
      'optionalAddOns': 'Optional add-ons buyers can select',
      'nameEn': 'Name (English)',
      'nameKm': 'Name (Khmer, optional)',
      'priceUsd': 'Price (USD \$)',
      'rentPerDayUsd': 'Rent / Day (USD \$)',
      'whatAreYouListing': 'What are you listing?',
      'vehicleOption': 'Vehicle (tuk-tuk, cargo…)',
      'accessoryOther': 'Accessory / Other',
      'photos': 'Photos',
      'upTo5': 'Up to 5',
      'productInfo': 'Product Info',
      'productTitle': 'Title',
      'describeProduct': 'Describe your product…',
      'type': 'Type',
      'condition': 'Condition',
      'pricing': 'Pricing',
      'quantity': 'Quantity',
      'areaDistrictOptional': 'Area / District (optional)',
      'status': 'Status',
      'findingMatch': 'Finding a match…',
      'totalSummary': 'Total Summary',
      'addAnotherItem': 'Add Another Item',
      'addItem': 'Add Item',
      'searchListings': 'Search listings…',
      'noOtherListingsFound': 'No other listings found',
      'pickUp': 'Pick Up',
      'collectMyself': "I'll collect the item myself",
      'deliverToAddress': 'Deliver the item to my address',
      'tapToSetDelivery': 'Tap to set delivery location',
      'paidFull': 'Paid Full',
      'payFullAmountNow': 'Pay the full amount now',
      'book30': 'Book 30%',
      'pay30Deposit': 'Pay 30% deposit — balance on delivery',
      'cod': 'COD',
      'cashOnDelivery': 'Cash on delivery',
      'payWithCash': 'Pay with cash',
      'inAppWalletBalance': 'In-app wallet balance',
      'abaMobileBanking': 'ABA mobile banking',
      'wingMobileWallet': 'Wing mobile wallet',
      'otherOnline': 'Other Online',
      'otherOnlinePayment': 'Other online payment',
      'enterCouponCodeOptional': 'Enter coupon code (optional)',
      'enterCouponCode': 'Enter coupon code',
      'noListingsYet': 'No listings yet',
      'postSomethingToSell': 'Post something to start selling',
      'duration': 'Duration',
      'specialInstructions': 'Any special instructions…',
      'seller': 'Seller',
      'specifications': 'Specifications',
      'pickupLocation': 'Pick-up Location',
      'all': 'All',
      'category': 'Category',
      'location': 'Location',
      'description': 'Description',
      'paymentType': 'Payment Type',
      'cash': 'Cash',
      'sender': 'Sender',
      'recipient': 'Recipient',
      'moving': 'Moving',
      'topUpRequired': 'Top Up Required',
      'topUpNow': 'Top Up Now',
      'lookingForRideRequests': 'Looking for Ride Requests',
      'deliveryModeActive': 'Delivery Mode Active',
      'incomingRideRequest': 'Incoming Ride Request',
      'incomingDeliveryRequest': 'Incoming Delivery Request',
      'incomingRentalRequest': 'Incoming Rental Request',
      'acceptDelivery': 'Accept Delivery',
      'acceptRental': 'Accept Rental',
      'searchChargingStation': 'Search charging station, location...',
      'nearbyChargingStations': 'Nearby Charging Stations',
      'noChargingStationsFound': 'No charging stations found.',
      'createAccount': 'Create Account',
      'joinRoteh': 'Join ROTEH',
      'fastSafeRides': 'Fast, safe rides in Cambodia',
      'iWantTo': 'I want to',
      'rideAsPassenger': 'Ride as Passenger',
      'driveAndEarn': 'Drive & Earn',
      'driverType': 'Driver Type',
      'fullName': 'Full Name',
      'email': 'Email',
      'enterEmail': 'Enter your email',
      'password': 'Password',
      'enterPassword': 'Enter your password',
      'confirmPassword': 'Confirm Password',
      'phoneOptional': 'Phone (optional)',
      'referralCodeOptional': 'Referral Code (optional)',
      'alreadyHaveAccount': 'Already have an account? ',
      'signIn': 'Sign In',
      'demoAccounts': 'Demo Accounts',
      'sendOtp': 'Send OTP',
      'verifyAndSignIn': 'Verify & Sign In',
      'resendOtp': 'Resend OTP',
      'family': 'Family',
      'wallet': 'Wallet',
      'rewards': 'Rewards',
      'refer': 'Refer',
      // ── Delivery / moving summary screens ──
      'phone': 'Phone',
      'package': 'Package',
      'movingCompleted': 'Moving Completed!',
      'deliveryDetails': 'Delivery Details',
      'movingDetails': 'Moving Details',
      'orderInfo': 'ORDER INFO',
      'jobInfo': 'JOB INFO',
      'paymentSummary': 'PAYMENT SUMMARY',
      'movingFee': 'Moving Fee',
      'paidBy': 'Paid By',
      'youRated': 'You rated this',
      'backToHome': 'Back to Home',
      'backToDashboard': 'Back to Dashboard',
      'updatingReceipt': 'Updating receipt…',
      'updatingSummary': 'Updating summary…',
      'couldNotRefresh': 'Could not refresh. Showing saved details.',
      'platformFee': 'Platform Fee',
      'netDriverFee': 'Net Driver Fee',
      'driverFee': 'Driver Fee',
      'beforePlatformFee': 'Before platform fee',
      'collectFromRecipient': 'Collect from recipient',
      'collectPackageAmount': 'Collect package amount',
      'packageDeliveredSuccessfully': 'Package delivered successfully.',
      'movingJobDone': 'Great job — the moving job is done.',
      'onlinePay': 'Online Pay',

      // ── Trip receipt ──
      'tripComplete': 'Trip Complete',
      'ride': 'Ride',
      'fareBreakdown': 'Fare Breakdown',
      'baseFare': 'Base fare',
      'distanceFee': 'Distance fee',
      'surgeFee': 'Surge fee',
      'promoDiscount': 'Promo discount',
      'tripDetails': 'Trip Details',
      'dateAndTime': 'Date & Time',
      'distance': 'Distance',
      'yourDriver': 'Your Driver',
      'yourRating': 'Your rating',
      'shareReceipt': 'Share Receipt',
      'tripReceipt': 'Trip Receipt',
      'minShort': 'min',
      'from': 'From',
      'to': 'To',
      'date': 'Date',
      'surge': 'Surge',
      'promo': 'Promo',
      'rotehWallet': 'ROTEH Wallet',
      // ── Payment screen ──
      'chooseHowYouWantTo': 'Choose how you want to pay',
      'confirmAndPay': 'Confirm & Pay',
      'haveAPromoCode': 'Have a promo code?',
      'payDriverDirectly': 'Pay driver directly',
      'serviceFee2': 'Service fee',
      'totalToPay': 'Total to pay',
      'tripSummary': 'Trip Summary',
      'wingMobileWallet2': 'Wing Mobile Wallet',
      'wingMoney': 'Wing Money',
      'yourWalletBalance': 'Your wallet balance',
      // ── Payment screen ──
      'payingWith': 'Paying with',
      // ── Wallet screen ──
      'amountKhrMin1000': 'Amount (KHR, min 1,000)',
      'balanceUpdated': 'Balance updated',
      'checkLater': 'Check later',
      'close': 'Close',
      'confirmTopUp': 'Confirm Top Up',
      'customAmountKhr': 'Custom amount (KHR)',
      'enterRecipientPhoneNumber': 'Enter recipient phone number.',
      'history': 'History',
      'loading': 'Loading…',
      'minimumTopUpAmountIs': 'Minimum top-up amount is 1,000 KHR.',
      'minimumTransferAmountIs1': 'Minimum transfer amount is 1,000 KHR.',
      'noTransactionsYet': 'No transactions yet',
      'recentTransactions': 'Recent Transactions',
      'reload': 'Top up',
      'send': 'Send',
      'sendMoney': 'Send Money',
      'sentSuccessfully': 'Sent successfully',
      'tapToRetry': 'Tap to retry',
      'topUp': 'Top Up',
      'topUpRotehPay': 'Top Up ROTEH Pay',
      'topUpStatus': 'Top Up Status',
      'topUpApproved': 'Top-up approved!',
      'topUpRejected': 'Top-up rejected',
      'viewAll': 'View all',
      'waitingForAdminApproval': 'Waiting for admin approval…',
      // ── passenger_home screen ──
      'n128Trips': '(128 trips)',
      // ── delivery_tracking_screen screen ──
      'areYouSureYouWant': 'Are you sure you want to cancel this delivery?',
      'cancelOrder': 'Cancel Order',
      'cancelOrder2': 'Cancel Order?',
      'chatDriver': 'Chat Driver',
      'completedAt2': 'Completed At: ',
      'copy': 'Copy',
      'couldNotLoadDelivery': 'Could not load delivery',
      'deliveryFee2': 'Delivery Fee: ',
      'howWasYourDeliveryExperience': 'How was your delivery experience?',
      'keepOrder': 'Keep Order',
      'leaveACommentOptional': 'Leave a comment (optional)',
      'packageAmount2': 'Package Amount: ',
      'rateDelivery': 'Rate Delivery',
      'recipientsAndFriendsCanTrack': 'Recipients & friends can track the live progress',
      'service': 'Service',
      'shareLink': 'Share Link',
      'skip': 'Skip',
      'stopSharingTracking': 'Stop sharing tracking',
      'submit': 'Submit',
      'summary': 'Summary',
      'trackingLinkCopiedToClipboard': 'Tracking link copied to clipboard',
      'trackingLinkDeactivated': 'Tracking link deactivated',
      'viewSummary': 'View Summary',
      // ── trip_tracking_screen screen ──
      'anSosAlertWillBe': 'An SOS alert will be sent to all your emergency contacts immediately.',
      'call': 'Call',
      'destination': 'Destination',
      'locatingYourDriver': 'Locating your driver…',
      'driverArrived': '✅ Driver Arrived!',
      'driverFound': '🛺 Driver found!',
      'yourDriverIsAlmostHere': '🛺 Your driver is almost here',
      // ── ride_booking screen ──
      'airport': 'Airport',
      'chooseOnMap': 'Choose on Map',
      'home2': 'Home',
      'office': 'Office',
      'pickupLocation2': 'Pickup location',
      'recent': 'Recent',
      'rideRequested': 'Ride Requested!',
      'saved': 'Saved',
      'searchPickupLocation': 'Search pickup location',
      'setLocationLater': 'Set location later',
      'suggestions': 'Suggestions',
      'eGSave10': 'e.g. SAVE10',
      'pickup2': '📍 Pick up',
      // ── delivery_screen screen ──
      'n1Bedroom': '1 Bedroom',
      'n10KgAndAbove': '10 kg and above',
      'n2Bedrooms': '2 Bedrooms',
      'n210Kg': '2 – 10 kg',
      'n3Bedrooms': '3+ Bedrooms',
      'baseFee': 'Base fee',
      'bike': 'Motorbike',
      'buildingHasAWorkingElevator': 'Building has a working elevator',
      'car': 'Car',
      'cashOnDeliveryCod': 'Cash on delivery (COD)',
      'commercialOfficeMoving': 'Office Moving',
      'deliveryVehicle': 'Delivery Vehicle',
      'dropoffFloor': 'Dropoff floor',
      'elevator': 'Elevator',
      'express': 'Express',
      'fasterDeliveryAtHigherFee': 'Faster delivery at higher fee',
      'floorFee': 'Floor fee',
      'floors': 'Floors',
      'fridgeSofaBedWardrobe': 'Fridge, sofa, bed, wardrobe',
      'hasElevator': 'Has elevator',
      'hasHeavyItems': 'Has heavy items',
      'helperFee': 'Helper fee',
      'helpers': 'Helpers',
      'home3': 'Home',
      'homeMove': 'Home Move',
      'informationOfMover': 'Information of mover',
      'large': 'Large',
      'largeHomeOrVilla': 'Large home or villa',
      'largerApartment': 'Larger apartment',
      'manualCarryUpDownStairs': 'Manual carry up/down stairs required',
      'medium': 'Medium',
      'mediumApartment': 'Medium apartment',
      'moveType': 'Move Type',
      'needsStairsCarry': 'Needs stairs carry',
      'normal': 'Normal',
      'notes': 'Notes',
      'officeMove': 'Office Move',
      'packingService': 'Packing service',
      'payFromWalletBalance': 'Pay from wallet balance',
      'paymentBy': 'Payment By',
      'paysUpfront': 'Pays upfront',
      'pickupFloor': 'Pickup floor',
      'priorityMovingService': 'Priority moving service',
      'privateHome': 'Private home',
      'propertySize': 'Property Size',
      'recipPh': 'Recipient Phone Number',
      'relocateHomeOffice': 'Relocate home/office',
      'residentialMoving': 'Residential moving',
      'scheduled': 'Scheduled',
      'searchLocation': 'Search location…',
      'sendPackages': 'Send packages',
      'senderPh': 'Sender Phone Number',
      'serviceOption': 'Service Option',
      'small': 'Small',
      'smallSpace': 'Small space',
      'standardDeliverySpeed': 'Standard delivery speed',
      'standardMovingService': 'Standard moving service',
      'studio1Room': 'Studio / 1 Room',
      'tukTuk': 'Tuk Tuk',
      'upTo100KgAffordable': 'Up to 100 kg  •  Affordable',
      'upTo2Kg': 'Up to 2 kg',
      'upTo20KgFastest': 'Up to 20 kg   •  Fastest',
      'upTo200KgComfortable': 'Up to 200 kg  •  Comfortable',
      'weBoxAndWrapYour': 'We box and wrap your belongings',
      'wingMobilePayment': 'Wing mobile payment',
      'buildingInfo': '🏢 Building Info',
      'serviceOptions': '🧍 Service Options',
      // ── Trip tracking messages ──
      'arrivingNow': 'Arriving now',
      'cancel2000Fee': 'Cancel (2,000 Riel Fee)',
      'cannotCancelARideIn': 'Cannot cancel a ride in progress.',
      'changedMyMind': 'Changed my mind',
      'driverAssignedConnecting': 'Driver assigned — connecting...',
      'driverHasArrivedA2': 'Driver has arrived — a 2,000 Riel fee applies.',
      'driverHasArrived': 'Driver has arrived!',
      'driverIsTakingTooLong': 'Driver is taking too long',
      'emergencyCameUp': 'Emergency came up',
      'findingDriver': 'Finding driver...',
      'findingYourDriver': 'Finding your driver...',
      'foundAnotherRide': 'Found another ride',
      'iMOnMyWay': 'I\'m on my way!\n',
      'lookingForANearbyDriver': 'Looking for a nearby driver…',
      'myRotehTrip': 'My ROTEH Trip',
      'noDriverWasAvailableFor': 'No available driver for this ride. Please try booking again.',
      'other': 'Other',
      'pleaseCheckYourBelongingsBefore': 'Please check your belongings before getting off.',
      'pleaseTellUsWhyYou': 'Please tell us why you\'re cancelling.',
      'share': 'Share',
      'sharing': 'Sharing',
      'thisRideCannotBeCancelled': 'This ride cannot be cancelled.',
      'thisRideWasCancelled': 'This ride was cancelled.',
      'trackMyRotehTripLive': 'Track my ROTEH trip live 🛺\n',
      'trackMyRideLive': 'Track my ride live',
      'tripInProgress2': 'Trip in progress',
      'wrongPickupLocation': 'Wrong pickup location',
      'yourDriverIsOnThe': 'Your driver is on the way',
      'yourDriverIsOnThe2': 'Your driver is on the way to pick you up.',
      'sosAlertSent': '🆘 SOS alert sent',
      'youReAlmostAtYour': '🔔 You\'re almost at your destination',
      // ── ride_booking messages ──
      'abaPay': 'ABA Pay',
      'acleda': 'ACLEDA',
      'aeonMallSenSok': 'Aeon Mall Sen Sok',
      'bike2': 'Bike',
      'carPremium': 'Car Premium',
      'carStandard': 'Car Standard',
      'confirmDestination2': 'Confirm destination',
      'confirmDestinations': 'Confirm destinations',
      'detectingLocation': 'Detecting location…',
      'dragMapToSetDestination': 'Drag map to set destination',
      'invalidOrExpiredCode': 'Invalid or expired code.',
      'locationPermissionDenied': 'Location permission denied',
      'lookingForADriver': 'Looking for a driver…',
      'meteredFare': 'Metered fare',
      'motorcycle': 'Motorcycle',
      'nightMarketRiverside': 'Night Market (Riverside)',
      'phnomPenhInternationalAirport': 'Techo International Airport (KTI)',
      'pickupLocation3': 'Pickup location',
      'royalPalace': 'Royal Palace',
      'sharedRide': 'Shared Ride',
      'tapMapToSetPickup': 'Tap map to set pickup',
      'tellDriverOnArrival': 'Tell driver on arrival',
      'toulTomPongMarket': 'Toul Tom Pong Market',
      'tukTuk2': 'Tuk Tuk',
      'tukTuk3': 'Tuk-tuk',
      'vanXl': 'Van / XL',
      // ── delivery_screen messages ──
      'bookMoving': 'Book Moving',
      'deliveryAddress': 'Delivery address',
      'dragMapToSelectLocation': 'Drag map to select location',
      'fromAndToAddressesAre': 'From and To addresses are required.',
      'movingCrew': 'Moving crew',
      'movingFromFullAddress': 'Moving from (full address)',
      'movingToFullAddress': 'Moving to (full address)',
      'noStairsCarry': 'No (stairs carry)',
      'noDescription': 'No description',
      'notesOptional': 'Notes (optional)',
      'packageDescriptionOptional': 'Package description (optional)',
      'pickupAddress': 'Pickup address',
      'pickupAndDeliveryAddressAre': 'Pickup and delivery address are required.',
      'scheduleDelivery2': 'Schedule Delivery',
      'scheduleMoving': 'Schedule Moving',
      // ── Ride booking categories ──
      'carShort': 'Car',
      // ── Driver earnings screen ──
      'avgTrip': 'Avg / Trip',
      'breakdown': 'Breakdown',
      'deliveries': 'Deliveries',
      'last30Days': 'Last 30 Days',
      'noEarningsHistoryYet': 'No earnings history yet',
      'rides': 'Rides',
      'totalEarnings': 'Total Earnings',
      // ── Driver earnings messages ──
      'breakdownIsOnlyAvailableFor': 'Breakdown is only available for weekly / monthly',
      'noEarningsInThisPeriod': 'No earnings in this period',
      'thisMonth': 'This Month',
      'thisWeek': 'This Week',
      'today': 'Today',
      // ── Weekday abbreviations ──
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'sun': 'Sun',
      // ── Driver home screen ──
      'stairsCarry': ' Stairs carry',
      'n1204Trips': ' · 1,204 trips',
      'n1204Trips2': '(1,204 trips)',
      'n3Of5PeakHour': '3 of 5 peak-hour trips completed today',
      'n4Consecutive5StarRatings': '4 consecutive 5-star ratings!',
      'n5StarStreak': '5-Star Streak 🔥',
      'accountHolderName': 'Account Holder Name',
      'accountNumber': 'Account Number',
      'active69Pm': 'Active 6–9 PM',
      'availableBalance': 'Available Balance',
      'bank': 'Bank',
      'confirmWithdrawal': 'Confirm Withdrawal',
      'instantWithdrawal': 'Instant Withdrawal',
      'loadMore': 'Load more',
      'peakHourBonus': 'Peak Hour Bonus',
      'rentalModeActive': 'Rental Mode Active',
      'rentalRequestAccepted': 'Rental request accepted.',
      'requestCancelled': 'Request cancelled',
      'resume': 'Resume',
      'reviewedByAdminBeforeFunds': 'Reviewed by admin before funds are sent',
      'selectBank': 'Select Bank',
      'showAll': 'Show All',
      'tapToOpenTheMap': 'Tap to open the map and see where to go.',
      'waitingForDeliveryOrdersIn': 'Waiting for delivery orders in your area.',
      'waiting': 'Waiting...',
      'yesWithdraw': 'Yes, Withdraw',
      'youHaveAWithdrawalRequest': 'You have a withdrawal request pending admin approval.',
      'youLlBeNotifiedWhen': 'You\'ll be notified when a passenger nearby needs a ride.',
      'yourVehicleIsListedFor': 'Your vehicle is listed for hourly rentals.',
      'earnedToday': 'earned today',
      // ── Driver home messages ──
      'abaBank': 'ABA Bank',
      'acledaBank': 'ACLEDA Bank',
      'canadiaBank': 'Canadia Bank',
      'completeYourTripToReceive': 'Complete your trip to receive new requests',
      'deliveryInProgress': 'Delivery In Progress',
      'headThereForHigherEarnings': 'Head there for higher earnings',
      'highDemandInYourArea': 'High demand in your area',
      'movingInProgress': 'Moving In Progress',
      'noBalanceToWithdraw': 'No balance to withdraw',
      'noDestinationPassengerWillTell': 'No destination — passenger will tell you',
      'noTransactionsToday': 'No transactions today',
      'pleaseEnterYourAccountNumber': 'Please enter your account number and holder name.',
      'rideInProgress': 'Ride In Progress',
      'thePassengerCancelledThatRide': 'The passenger cancelled that ride request.',
      'toggleOnlineToAcceptRides': 'Toggle online to accept rides',
      'transactionHistory': 'Transaction History',
      'waitingForRequests': 'Waiting for requests...',
      'withdrawalPendingApproval': 'Withdrawal pending approval',
      'withdrawalsUnavailable': 'Withdrawals unavailable',
      'urgent': '⚡ URGENT',
      'offline2': '⭕ Offline',
      'newRequest': '🆕 NEW REQUEST',
      'newDelivery': '📦 NEW DELIVERY',
      'newRental': '🚚 NEW RENTAL',
      'newMoving': '🚚 NEW MOVING',
      'busyOnATrip': '🟡 Busy — On a Trip',
      'onlineReady': '🟢 Online — Ready',
      // ── helmet_check_screen ──
      'chooseFromGallery': 'Choose from Gallery',
      'gallery': 'Gallery',
      'pleaseWearAHelmetBefore': 'Please wear a helmet before starting your trip.',
      'retake': 'Retake',
      'takePhoto': 'Take Photo',
      'tapToUploadPhoto': 'Tap to upload photo',
      'uploadAPhotoToVerify': 'Upload a photo to verify that a helmet is being worn correctly.',
      // ── helmet_check_screen messages ──
      'checkHelmet': 'Check Helmet',
      'checking': 'Checking…',
      'helmetDetected': 'Helmet Detected!',
      'noHelmetDetected': 'No Helmet Detected',
      // ── driver_withdrawal_screen ──
      'amountKhr': 'Amount (KHR)',
      'bankNameOptional': 'Bank Name (optional)',
      'confirm': 'Confirm',
      'noWithdrawalHistory': 'No withdrawal history',
      'pleaseMakeSureTheseDetails': 'Please make sure these details are correct. This cannot be undone once submitted.',
      'requestWithdrawal': 'Request Withdrawal',
      'withdrawalRequestSubmitted': 'Withdrawal request submitted!',
      // ── driver_withdrawal_screen messages ──
      'accountName': 'Account Name',
      'amount': 'Amount',
      'bankTransfer': 'Bank Transfer',
      'enterAValidAmount': 'Enter a valid amount.',
      'enterAccountHolderName': 'Enter account holder name.',
      'enterAccountNumber': 'Enter account number.',
      'fullNameAsOnAccount': 'Full name as on account',
      'method': 'Method',
      'wing': 'Wing',
      'withdraw': 'Withdraw',
      'eGAbaAcledaWing': 'e.g. ABA, ACLEDA, Wing…',
      // ── driver_vehicle_screen ──
      'colorOptional': 'Color (optional)',
      'imagesUploaded': 'Images uploaded',
      'licensePlate': 'License Plate',
      'make': 'Make',
      'model': 'Model',
      'myVehicles': 'My Vehicles',
      'noVehiclesRegistered': 'No vehicles registered',
      'registerVehicle': 'Register Vehicle',
      'registerYourVehicleToStart': 'Register your vehicle to start accepting rides.',
      'year': 'Year',
      // ── driver_vehicle_screen messages ──
      'editVehicle': 'Edit Vehicle',
      'honda': 'Honda',
      'makeModelAndPlateAre': 'Make, model and plate are required',
      'motorbike': 'Motorbike',
      'saveChanges': 'Save Changes',
      'truck': 'Truck',
      'vehicle': 'Vehicle',
      'wave': 'Wave',
      // ── driver_trip_summary_screen ──
      'confirmed': 'Confirmed',
      'fareSummary': 'FARE SUMMARY',
      'paymentMethod2': 'PAYMENT METHOD',
      'paymentReceived': 'Payment received',
      'totalFare': 'Total Fare',
      'tripCompleted': 'Trip Completed!',
      // ── driver_trip_summary_screen messages ──
      'bike3': 'Bike',
      'noDestinationToldInPerson': 'No destination — told in person',
      'tukTuk4': 'Tuk Tuk',
      // ── driver_missions_screen ──
      'acceptAJobFromThe': 'Accept a job from the home screen\nto see it here.',
      'avgFare': 'Avg fare',
      'earned': 'Earned',
      'noRidesYet': 'No rides yet',
      'tapToRefreshForLatest': 'Tap to refresh for latest status',
      'thisOrderWasCancelled': 'This order was cancelled',
      // ── driver_missions_screen messages ──
      'accepted2': 'ACCEPTED',
      'arrived2': 'Arrived',
      'cancelled': 'CANCELLED',
      'delivery2': 'DELIVERY',
      'done2': 'DONE',
      'delivered': 'Delivered',
      'failedToLoadDeliveries': 'Failed to load deliveries.',
      'failedToLoadMovings': 'Failed to load movings.',
      'failedToLoadRideHistory': 'Failed to load ride history.',
      'inProgress': 'IN PROGRESS',
      'inTransit': 'In Transit',
      'loading2': 'Loading',
      'moving2': 'MOVING',
      'pickedUp': 'Picked Up',
      // ── driver_history_screen ──
      'noMoreTrips': 'No more trips',
      'noTripsYet': 'No trips yet',
      'trip': 'Trip',
      'yourCompletedTripsWillAppear': 'Your completed trips will appear here.',
      // ── driver_history_screen messages ──
      'cancelled2': 'Cancelled',
      'unknown': 'Unknown',
      'yesterday': 'Yesterday',
      // ── driver_document_upload_screen ──
      'optionalDocuments': 'Optional Documents',
      'required': 'Required',
      'requiredDocuments': 'Required Documents',
      'submitForReview': 'Submit for Review',
      'uploadDocuments': 'Upload Documents',
      'uploaded': 'Uploaded',
      'yourDocumentsWillBeReviewed': 'Your documents will be reviewed within 1–2 business days.',
      // ── driver_document_upload_screen messages ──
      'driverLicense': 'Driver License',
      'nationalIdPassport': 'National ID / Passport',
      'optionalTapToUpload': 'Optional — tap to upload',
      'otherDocument': 'Other Document',
      'ready': 'Ready!',
      'selfieWithId': 'Selfie with ID',
      'tapToUpload': 'Tap to upload',
      'vehicleInsurance': 'Vehicle Insurance',
      'vehicleRegistration': 'Vehicle Registration',
      // ── Driver vehicle types ──
      'van': 'Van',
      // ── Document upload ──
      'requiredDocumentsUploadedSuffix': 'required documents uploaded',
      // ── Driver approval pending screen ──
      'applicationStatus': 'Application Status',
      'pleaseReviewTheFeedbackOn': 'Please review the feedback on your documents above, then re-submit with corrected photos. Contact support if you need help.',
      'reUploadDocuments': 'Re-upload Documents',
      'refreshStatus': 'Refresh Status',
      'weLlNotifyYouOnce': 'We\'ll notify you once your documents have been reviewed.\nTypically 1–2 business days.',
      'whatToDoNext': 'What to do next',
      // ── Driver approval status ──
      'documentReviewResults': 'Document Review Results',
      'documentStatus': 'Document Status',
      'approvedExcl': 'Approved!',
      'youCanNowGoOnline': 'You can now go online and accept rides.',
      'applicationRejected': 'Application Rejected',
      'pleaseReviewDocsResubmit': 'Please review your documents and re-submit.',
      'underReview': 'Under Review',
      'ourTeamIsReviewing': 'Our team is reviewing your application.',
      'city': 'City',
      'serviceZone': 'Service Zone',
      'approvedStatus': 'Approved',
      'rejectedStatus': 'Rejected',
      'pendingStatus': 'Pending',
      // ── Driver delivery active screen ──
      'toUpdateProgressContinueFrom': 'To update progress, continue from the active job screen.',
      'you': 'You',
      // ── Driver delivery active screen ──
      'movingFrom': 'Moving From',
      'movingTo': 'Moving To',
      'arriving': 'Arriving',
      'arrivedAtLocation': 'Arrived at Location',
      'loadingComplete': 'Loading Complete',
      'markAsDelivered': 'Mark as Delivered',
      'arrivedAtPickup': 'Arrived at Pickup',
      'packagePickedUp': 'Package Picked Up',
      'headingToPickupLocation': 'Heading to pickup location',
      'atLocationLoadingItems': 'At location — loading items',
      'inTransitToNewLocation': 'In transit to new location',
      'movingCompleteExcl': 'Moving complete!',
      'headingToSender': 'Heading to sender',
      'atPickupCollectPackage': 'At pickup — collect package',
      'onTheWayToRecipient': 'On the way to recipient',
      'deliveredExcl': 'Delivered!',
      'heading': 'Heading',
      'atLocation': 'At Location',
      'atPickup': 'At Pickup',
      'youArrivedAtPickupLocation': 'You arrived at pickup location',
      'packagePickedUpHeadingToDropoff': 'Package picked up — heading to dropoff',
      'arrivedAtMovingLocationStartLoading': 'Arrived at moving location — start loading',
      'loadingCompleteHeadingToNewLocation': 'Loading complete — heading to new location',
      'minAway': 'min away',
      'senderNumberPrefix': 'Sender #',
      // ── Driver active trip screen ──
      'amountToCollect': 'Amount to collect',
      'arrivedAtStop': 'Arrived at Stop',
      'callNow': 'Call Now',
      'completeTrip': 'Complete Trip',
      'emergencySos': 'Emergency SOS',
      'enable': 'Enable',
      'enterFinalFare': 'Enter Final Fare',
      'locationPermissionDeniedLiveTracking': 'Location permission denied — live tracking and fare ',
      'sos': 'SOS',
      'sendSos': 'Send SOS',
      'thisTripHadNoDestination': 'This trip had no destination set — here\'s the calculated summary.',
      'thisWillAlertEmergencyServices': 'This will alert emergency services and notify ROTEH APP operations team with your location.',
      'tripCompleted2': 'Trip Completed',
      'kmH': 'km/h',
      'sosSentHelpIsOn': '🚨 SOS Sent! Help is on the way.',
      // ── Driver active trip screen ──
      'passengerNumberPrefix': 'Passenger #',
      'noDestinationAskPassenger': 'No destination — ask passenger',
      'bike4': 'Bike',
      'tukTuk5': 'Tuk-Tuk',
      'continueStraight': 'Continue straight',
      'youHaveArrivedAt': 'You have arrived at',
      'noActiveRide': 'No active ride.',
      'headingToPickup2': 'Heading to Pickup',
      'waitingAtPickup': 'Waiting at Pickup',
      'arrivedAtPickupBtn': '✅  Arrived at Pickup',
      'passengerOnBoardStartTrip': '🛺 Passenger On Board — Start Trip',
      'backToDashboardBtn': '🏠  Back to Dashboard',
      'enterAValidAmount2': 'Enter a valid amount',
      'metered': 'Metered',
      'youEarnedPrefix': 'You earned',
      'calculatedDistancePrefix': 'Calculated distance',
      'looksWrongFartherThanTrip': 'looks wrong — that\'s farther than any trip within Cambodia.',
      'noFareReturnedForServiceType': 'No fare returned for service type',
      'fareCalculationFailedPrefix': 'Fare calculation failed:',
      'unknownError': 'unknown error',
      'tripHadNoDestinationSuggested': 'This trip had no destination set. Suggested fare below is calculated',
      'fromDistanceTravelledAdjust': 'travelled — adjust if needed.',
      // ── Driver active trip screen 2 ──
      'tripInProgressCap': 'Trip in Progress',
      'completeTripBtn': '🏁  Complete Trip',
      // ── accessibility_screen ──
      'accessibilityTitle': 'Accessibility',
      'save': 'Save',
      'accessibilitySettingsSaved': 'Accessibility settings saved.',
      'saveSettings': 'Save Settings',
      'visualSection': 'Visual',
      'audioAndSpeechSection': 'Audio & Speech',
      'interactionSection': 'Interaction',
      'largeText': 'Large Text',
      'largeTextSubtitle': 'Increase font size throughout the app',
      'highContrast': 'High Contrast',
      'highContrastSubtitle': 'Improve visibility with stronger colours',
      'reduceMotion': 'Reduce Motion',
      'reduceMotionSubtitle': 'Minimise animations and transitions',
      'screenReaderSupport': 'Screen Reader Support',
      'screenReaderSupportSubtitle': 'Optimise labels for assistive technology',
      'hapticFeedback': 'Haptic Feedback',
      'hapticFeedbackSubtitle': 'Vibrate on key interactions',
      'largeTouchTargets': 'Large Touch Targets',
      'largeTouchTargetsSubtitle': 'Bigger buttons and tap areas',
      'wheelchairAccessibleVehicles': 'Wheelchair Accessible Vehicles',
      'wheelchairAccessibleVehiclesSubtitle': 'Show only accessible vehicle options',
      // ── airport_trip_screen ──
      'airportTransferTitle': 'Airport Transfer',
      'toAirportTab': 'To Airport',
      'fromAirportTab': 'From Airport',
      'freeWaitBannerMessage': '60 minutes free wait included — we track your flight and adjust pickup automatically.',
      'dropoffAirportLabel': 'Drop-off Airport',
      'pickupAirportLabel': 'Pick-up Airport',
      'pickupAddressLabel': 'Pick-up Address',
      'dropoffAddressLabel': 'Drop-off Address',
      'enterHomeHotelAddressHint': 'Enter your home / hotel address',
      'enterDestinationAddressHint': 'Enter your destination address',
      'flightDetailsLabel': 'Flight Details',
      'flightNumberHint': 'Flight no. (e.g. QH101)',
      'terminalHint': 'Terminal (e.g. T1)',
      'departureTime': 'Departure time',
      'arrivalTime': 'Arrival time',
      'vehicleTypeLabel': 'Vehicle Type',
      'sedanLabel': 'Sedan',
      'upTo4Pax': 'Up to 4 pax',
      'suvVanLabel': 'SUV/Van',
      'upTo6Pax': 'Up to 6 pax',
      'passengersAndLuggageLabel': 'Passengers & Luggage',
      'passengersLabel': 'Passengers',
      'luggageBagsLabel': 'Luggage bags',
      'enterAddressForFareEstimate': 'Enter your address to see the estimated fare.',
      'airportSurcharge': 'Airport surcharge',
      'bookingFee': 'Booking fee',
      'distanceFare': 'Distance fare',
      'timeFare': 'Time fare',
      'nightSurcharge': 'Night surcharge',
      'weekendSurcharge': 'Weekend surcharge',
      'holidaySurcharge': 'Holiday surcharge',
      'fareRoundingAdjustment': 'Rounding adjustment',
      'luggageBagsCountLabel': 'Luggage',
      'fixedPriceNoSurge': 'Fixed price · No surge',
      'bookTransferPrefix': 'Book Transfer ·',
      'bookAirportTransfer': 'Book Airport Transfer',
      'fillAddressFlightDetailsError': 'Please fill in your address, flight number, and flight time.',
      'airportFallback': 'Airport',
      // ── cancellation_policy_screen ──
      'cancellationPolicyTitle': 'Cancellation Policy',
      'feesGoToDriversNote': 'Fees go to drivers as compensation for their time.',
      'contactSupport': 'Contact Support',
      'beforeDriverAccepts': 'Before driver accepts',
      'freeCancellation': 'Free cancellation',
      'freeCancelBeforeAcceptDetail': 'You can cancel at any time before a driver accepts your ride with no charge.',
      'afterDriverAccepts': 'After driver accepts',
      'cancelRangeMinutes': '{from}–{to} min',
      'cancelRangeFromMinutes': '{from}+ min',
      'cancelFeeAmount': '{fee} ៛ fee',
      'cancelTierFreeDetail': 'Cancelling during this period is free.',
      'cancelTierFeeDetail': 'A {fee} ៛ cancellation fee is charged if you cancel during this period.',
      'cancellationPolicyLoadFailed': 'Could not load the cancellation policy.',
      'afterDriverArrives': 'After driver arrives',
      // ── car_rental_screen ──
      'durMonth1': '1 Month',
      'durMonth2': '2 Months',
      'durMonth3': '3 Months',
      'durMonth6': '6 Months',
      'durYear1': '1 Year',
      'durYear2': '2 Years',
      'pickUpLabel': 'Pick Up',
      'collectCarMyself': "I'll collect myself",
      'deliverCarToAddress': 'Deliver to my address',
      'tapToSetPickupLocation': 'Tap to set pickup location',
      'tapToSetDeliveryLocation': 'Tap to set delivery location',
      'setPickupLocationTitle': 'Set Pickup Location',
      'setDeliveryLocationTitle': 'Set Delivery Location',
      'suvLabel': 'SUV',
      'electricLabel': 'Electric',
      'locationTypeLabel': 'Location Type',
      'rentalDurationTitle': 'Rental Duration',
      'endsPrefix': 'Ends',
      'payInCashOnPickup': 'Pay in cash on pickup',
      'failedToApplyCoupon': 'Failed to apply coupon.',
      'bookedHashPrefix': 'Booked #',
      'datesLabel': 'Dates',
      'dailyRateLabel': 'Daily rate',
      'renterLabel': 'Renter',
      'selectVehicleBeforeBooking': 'Please select a Vehicle before booking.',
      'setDeliveryLocationError': 'Please set a delivery location.',
      'enterNamePhoneError': 'Please enter your name and phone number.',
      'rentalVehicleTitle': 'Rental Vehicle',
      'locationLabel': 'Location',
      'vehicleForRentLabel': 'Vehicle for Rent',
      'browseAvailableVehicle': 'Browse Available Vehicle',
      'tapToViewAllVehicles': 'Tap to view all Vehicle for rent',
      'rentalPeriodLabel': 'Rental Period',
      'daysLabel': 'days',
      'endsLabel': 'ends',
      'startDateLabel': 'Start Date',
      'endDateAutoLabel': 'End Date (auto)',
      'yourInformationLabel': 'Your Information',
      'notesOptionalLabel': 'Notes (optional)',
      'anySpecialRequestsHint': 'Any special requests…',
      'couponCodeLabel': 'Coupon Code',
      'discountAppliedSuffix': 'discount applied',
      'enterCouponCodeHint': 'Enter coupon code',
      'bookingSummaryLabel': 'Booking Summary',
      'discountLabel': 'Discount',
      'bookNowLabel': 'Book Now',
      'selectAVehicleLabel': 'Select a Vehicle',
      'rentDashPrefix': 'Rent —',
      'failedToLoadVehicles': 'Failed to load vehicles',
      'noVehicleAvailableForRent': 'No Vehicle available for rent.',
      'photosCountSuffix': 'photos',
      'daysCapLabel': 'Days',
      // ── charging_stations ──
      'favoritesLabel': 'Favorites',
      'fastChargingLabel': 'Fast Charging',
      'showLess': 'Show less',
      'myLocationLabel': 'My location',
      'sortedByDistanceFromLocation': 'Sorted by distance from your location',
      'sortedByDistanceFromPhnomPenh': 'Sorted by distance from Phnom Penh (location unavailable)',
      'findingYourLocation': 'Finding your location…',
      'myLocationUnavailable': 'My location unavailable',
      'nearbyChargingStationsTitle': 'Nearby Charging Stations',
      'availableSuffix': 'Available',
      // ── edit_profile_screen ──
      'takeAPhoto': 'Take a photo',
      'couldNotUpdatePhotoPrefix': 'Could not update photo:',
      'couldNotUpdatePhotoTryAgain': 'Could not update photo. Try again.',
      'profileUpdatedSuccess': 'Profile updated successfully!',
      'tapPhotoToChange': 'Tap photo to change',
      'otpRequiredBadge': 'OTP required',
      'changingPhoneRequiresOtp': 'Changing your phone number requires OTP verification.',
      'enterSixDigitCode': 'Enter the 6-digit code.',
      'verifyPhoneNumberTitle': 'Verify Phone Number',
      'codeSentToPrefix': 'A 6-digit code was sent to',
      'devCodePrefix': 'Dev code:',
      'sendingOtpEllipsis': 'Sending OTP...',
      'expiresInPrefix': 'Expires in',
      'codeExpired': 'Code expired',
      'resendInPrefix': 'Resend in',
      'verify': 'Verify',
      // ── family_screen ──
      'familyAccountTitle': 'Family Account',
      'addMemberTooltip': 'Add member',
      'createFamilyGroupTitle': 'Create a Family Group',
      'familyGroupDescription': "Book rides on behalf of family members. They don't need an app — just a phone number.",
      'groupNameHint': 'Group name (e.g. Sokkheng Family)',
      'createGroup': 'Create Group',
      'membersLabel': 'Members',
      'add': 'Add',
      'noMembersYetMsg': 'No members yet. Add a family member to book rides for them.',
      'membersCountSuffix': 'members',
      'fromFamilyGroupQuestionSuffix': 'from the family group?',
      'hasAutorideAccountLabel': 'Has ROTEH APP account',
      'bookLabel': 'Book',
      'addFamilyMemberTitle': 'Add Family Member',
      'fullNameStarHint': 'Full name *',
      'phoneNumberStarHint': 'Phone number *',
      'relationshipHint': 'Relationship (e.g. Mother, Friend…)',
      'addMemberBtn': 'Add Member',
      'fullNameHint': 'Full name',
      'phoneNumberHint2': 'Phone number',
      'mother': 'Mother',
      'father': 'Father',
      'spouse': 'Spouse',
      'son': 'Son',
      'daughter': 'Daughter',
      'sibling': 'Sibling',
      'friend': 'Friend',
      // ── loyalty_screen ──
      'rotehRewardsTitle': 'ROTEH Rewards',
      'redeemPointsTitle': 'Redeem Points',
      'redeem500ptsQuestion': 'Redeem 500 pts for 5,000 ៛ discount on your next ride?',
      'pts500Redeemed': '500 pts redeemed! Discount applied to next ride.',
      'redeem500pts': 'Redeem 500 pts',
      'rotehPointsLabel': 'ROTEH Points',
      'ptsSuffix': 'pts',
      'maxTierReached': 'Max tier reached',
      'ptsToPlatinumSuffix': 'pts to Platinum',
      'ptsToGoldSuffix': 'pts to Gold',
      'ptsToSilverSuffix': 'pts to Silver',
      'membershipTiersTitle': 'Membership Tiers',
      'currentBadge': 'Current',
      'howToEarnTitle': 'How to Earn',
      'pointsActivityTitle': 'Points Activity',
      'bronzeTier': 'Bronze',
      'silverTier': 'Silver',
      'goldTier': 'Gold',
      'platinumTier': 'Platinum',
      'ptsPer1000Spent10': '10 pts per 1,000 ៛ spent',
      'birthdayBonus100pts': 'Birthday bonus 100 pts',
      'basicSupport': 'Basic support',
      'ptsPer1000Spent12': '12 pts per 1,000 ៛ spent',
      'priorityMatching': 'Priority matching',
      'fareDiscount5pct': '5% fare discount',
      'ptsPer1000Spent15': '15 pts per 1,000 ៛ spent',
      'fareDiscount10pct': '10% fare discount',
      'freeCancellation3perMo': 'Free cancellation ×3/mo',
      'ptsPer1000Spent20': '20 pts per 1,000 ៛ spent',
      'fareDiscount15pct': '15% fare discount',
      'dedicatedSupportLine': 'Dedicated support line',
      'freeCancellationUnlimited': 'Free cancellation unlimited',
      'completeATrip': 'Complete a trip',
      'ptsPer1000Simple10': '10 pts per 1,000 ៛',
      'rateYourDriver': 'Rate your driver',
      'ptsBonus50': '50 pts bonus',
      'referAFriend': 'Refer a friend',
      'ptsPerReferral500': '500 pts per referral',
      'pointsFallback': 'Points',
      // ── my_rentals_screen ──
      'noRentalsFound': 'No rentals found',
      'orderHashPrefix': 'Order #',
      'rentalHashPrefix': 'Rental #',
      'rentalVehicleBadge': 'Rental Vehicle',
      'cancelRentalTitle': 'Cancel Rental',
      'cancelRentalConfirmMsg': 'Are you sure you want to cancel this rental?',
      'yesCancelBtn': 'Yes, Cancel',
      'electricVehicleLabel': 'Electric Vehicle',
      // ── notifications_screen ──
      'justNow': 'Just now',
      'minAgoSuffix': 'min ago',
      'hrsAgoSuffix': 'hrs ago',
      'daysAgoSuffix': 'days ago',
      'markAllRead': 'Mark all read',
      'noNotificationsYet': 'No notifications yet',
      'notificationFallback': 'Notification',
      // ── payment_methods_screen ──
      'cardsSection': 'Cards',
      'noCardsAddedYet': 'No cards added yet',
      'linkedAccountsSection': 'Linked Accounts',
      'addMethodLabel': 'Add Method',
      'defaultBadge': 'Default',
      'setAsDefaultOption': 'Set as default',
      'removeOption': 'Remove',
      'unlinkOption': 'Unlink',
      'linkedLabel': 'Linked',
      'notLinkedLabel': 'Not linked',
      'addPaymentMethodTitle': 'Add Payment Method',
      'cardOptionLabel': 'Card',
      'cardOptionSubtitle': 'VISA, Mastercard, PayPal',
      'alreadyLinked': 'Already linked',
      'linkYourAbaAccount': 'Link your ABA account',
      'linkYourAcledaAccount': 'Link your ACLEDA account',
      'cardNumberLabel': 'Card Number',
      'expiryDateLabel': 'Expiry Date',
      'cvvLabel': 'CVV',
      'setAsDefaultSwitch': 'Set as Default',
      'addCardBtn': 'Add Card',
      'phoneNumberHintExample': 'e.g. 012 345 678',
      'linkAccountBtn': 'Link Account',
      'linkAbaPayTitle': 'Link ABA Pay',
      'linkAcledaPayTitle': 'Link ACLEDA Pay',
      'enterValidCardNumber': 'Enter a valid card number',
      'enterExpiryMMYY': 'Enter expiry as MM/YY',
      'cardExpiredError': 'This card has expired',
      'enterValidCvv': 'Enter a valid CVV',
      'expiresPrefix': 'Expires',
      'minOrderPrefix': 'Min order',
      'byCodeTab': 'By Code',
      'byRotehPayTab': 'By ROTEH Pay',
      'payWithRotehPay': 'Pay with ROTEH Pay',
      'enterAccountPhoneNumber': 'Enter the account phone number',
      // ── promo_screen ──
      'promosTabLabel': 'Promos',
      'storeTabLabel': 'Store',
      'myVouchersTabLabel': 'My Vouchers',
      'enterPromoCodeTitle': 'Enter Promo Code',
      'codeHintExample': 'e.g. ROTEH15',
      'invalidExpiredPromoCode': 'Invalid or expired promo code.',
      'couldNotValidateCode': 'Could not validate code. Try again.',
      'discountAppliedFallback': 'discount applied',
      'offSuffix': 'off',
      'promoAppliedDashPrefix': 'Promo',
      'appliedDashSuffix': 'applied —',
      'codeCopiedPrefix': 'Code',
      'copiedSuffix': 'copied!',
      'availableVouchersTitle': 'Available Vouchers',
      'noExpiry': 'No expiry',
      'promo1Title': '50% Off First Ride',
      'promo1Desc': 'Valid for new users only. Max discount \$5.',
      'promo2Title': '15% Off Any Ride',
      'promo2Desc': 'Use any time. Min fare \$3.00.',
      'promo3Title': '\$1 Off Delivery',
      'promo3Desc': 'Valid on standard and same-day deliveries.',
      'promo4Title': 'Free EV Station Map',
      'promo4Desc': 'Get premium station directions for free.',
      'promo5Title': '20% Off Weekends',
      'promo5Desc': 'Valid Sat–Sun. Max discount \$8.',
      'freeLabel': 'Free',
      // ── qr_payment_screen ──
      'qrPaymentTitle': 'QR Payment',
      'myQrTabLabel': 'My QR',
      'enterValidAmountKhr': 'Enter a valid amount in KHR.',
      'generateQrToReceive': 'Generate QR to Receive',
      'enterAmountShareQr': 'Enter an amount and share the QR with the payer.',
      'amountKhrLabel': 'Amount (KHR)',
      'generatingEllipsis': 'Generating…',
      'generateQrBtn': 'Generate QR',
      'qrExpired': 'QR expired',
      'waitingForPayment': 'Waiting for payment…',
      'qrReferenceCopied': 'QR reference copied',
      'newQrBtn': 'New QR',
      'noQrPaymentHistory': 'No QR payment history',
      'paidStatus': 'PAID',
      // ── rate_driver_screen ──
      'rateYourTripTitle': 'Rate Your Trip',
      'howWasYourTripQuestion': 'How was your trip?',
      'tapToRate': 'Tap to rate',
      'ratingTerrible': 'Terrible',
      'ratingBad': 'Bad',
      'ratingOkay': 'Okay',
      'ratingGood': 'Good',
      'ratingExcellent': 'Excellent!',
      'whatDidYouLoveQuestion': 'What did you love?',
      'whatWentWrongQuestion': 'What went wrong?',
      'addCommentOptionalHint': 'Add a comment (optional)...',
      'addATipQuestion': 'Add a tip?',
      'noTipLabel': 'No tip',
      'tipFailedPrefix': 'Tip failed:',
      'submitRatingBtn': 'Submit Rating',
      'thankYouExcl': 'Thank you!',
      'feedbackHelpsImprove': 'Your feedback helps us improve the experience for everyone.',
      'greatDrivingTag': 'Great driving',
      'veryFriendlyTag': 'Very friendly',
      'cleanCarTag': 'Clean car',
      'onTimeTag': 'On time',
      'safeRideTag': 'Safe ride',
      'latePickupTag': 'Late pickup',
      'rudeTag': 'Rude',
      'unsafeDrivingTag': 'Unsafe driving',
      'dirtyCarTag': 'Dirty car',
      'wrongRouteTag': 'Wrong route',
      // ── referral_screen ──
      'referralTitle': 'Referral',
      'copiedExcl': 'Copied!',
      'shareAndEarn': 'Share & Earn',
      'giveFriendsDiscountDesc': 'Give friends 10,000 ៛ off their first ride.\nYou earn 500 points per referral.',
      'yourReferralCode': 'Your Referral Code',
      'shareWithFriends': 'Share with Friends',
      'friendsReferred': 'Friends Referred',
      'pointsEarnedLabel': 'Points Earned',
      'friendsWhoJoined': 'Friends Who Joined',
      'joinedPrefix': 'Joined',
      'joinRotehWithCodePrefix': 'Join ROTEH with my code:',
      'get10000OffFirstRideSuffix': 'and get 10,000 ៛ off your first ride!',
      'downloadRotehNow': 'Download ROTEH now.',
      // ── safety_screen ──
      'safetyCenterTitle': 'Safety Center',
      'emergencySosLabel': 'Emergency SOS',
      'holdToActivate': 'Hold for 1 second to activate',
      'fakeCallLabel': 'Fake Call',
      'stopSharingLabel': 'Stop Sharing',
      'reportLabel': 'Report',
      'emergencyContactsTitle': 'Emergency Contacts',
      'noEmergencyContactsYet': 'No emergency contacts yet',
      'safetyResourcesTitle': 'Safety Resources',
      'emergencyPhoneNumbers': 'Emergency: 117 / 119',
      'reportIncidentLabel': 'Report Incident',
      'safetyGuidelinesLabel': 'Safety Guidelines',
      'sosSentToPrefix': '🆘 SOS sent to',
      'contactsSuffix': 'contact(s)',
      'noActiveRideToShare': 'No active ride to share',
      'sharingStopped': 'Sharing stopped',
      'tripLinkSharedTitle': 'Trip Link Shared',
      'shareLinkTrackDesc': 'Share this link so others can track your trip in real time.',
      'sosWillBeSentNoContacts': 'An SOS alert will be sent immediately. No emergency contacts added yet.',
      'sosWillBeSentToContactsPrefix': 'SOS will be sent to',
      'emergencyContactsImmediatelySuffix': 'emergency contact(s) immediately.',
      'harassmentTag': 'Harassment',
      'unsafeDrivingTitleTag': 'Unsafe Driving',
      'overchargeTag': 'Overcharge',
      'otherTag': 'Other',
      'describeWhatHappenedHint': 'Describe what happened…',
      'submitReportBtn': 'Submit Report',
      'incidentReportedThanks': 'Incident reported. Thank you.',
      'addEmergencyContactTitle': 'Add Emergency Contact',
      'relationshipHintExample': 'Relationship (e.g. Mom)',
      'notifyOnSos': 'Notify on SOS',
      'notifyOnTripShare': 'Notify on trip share',
      'addContactBtn': 'Add Contact',
      'contactAddedExcl': 'Contact added!',
      'editContactTitle': 'Edit Contact',
      'contactUpdatedExcl': 'Contact updated!',
      'removeContactQuestion': 'Remove contact?',
      'willBeRemovedFromContactsSuffix': 'will be removed from your emergency contacts.',
      'contactRemoved': 'Contact removed',
      'sosTagLabel': 'SOS',
      'tripShareTagLabel': 'Trip Share',
      'fakeCallChooseDelayTitle': 'Fake Call — Choose Delay',
      'phoneWillRingDesc': 'Your phone will ring after the selected delay.',
      'nowSecLabel': 'Now (5 sec)',
      'inSecLabel10': 'In 10 sec',
      'inSecLabel30': 'In 30 sec',
      'inMinLabel1': 'In 1 min',
      'incomingCallEllipsis': 'Incoming Call…',
      'fakeCallInPrefix': 'Fake call in',
      'secondsSuffix': 's…',
      // ── saved_places_screen ──
      'deletePlaceQuestion': 'Delete place?',
      'removePlacePrefix': 'Remove',
      'fromSavedPlacesQuestionSuffix': 'from your saved places?',
      'removedSuffix': 'removed',
      'addHomeLabel': 'Add Home',
      'addWorkLabel': 'Add Work',
      'yourPlacesLabel': 'Your Places',
      'saveHomeWorkDesc': 'Save home, work, or favourite spots\nfor faster booking.',
      'addAPlaceBtn': 'Add a place',
      'editPlaceTitle': 'Edit Place',
      'addPlaceTitle': 'Add Place',
      'labelHintExample': 'Home, Work, Gym…',
      'openingMapEllipsis': 'Opening map…',
      'searchOrDragPinHint': 'Search or drag pin on map',
      'setAsDefaultCheckbox': 'Set as default',
      'labelAndLocationRequired': 'Label and location are required',
      'setLocationTitle': 'Set Location',
      'labelFieldTitle': 'Label',
      // ── scheduled_rides_screen ──
      'scheduledRidesTitle': 'Scheduled Rides',
      'pastLabel': 'Past',
      'inPrefix': 'in',
      'daysLabel2': 'days',
      'hrsLabel': 'hrs',
      'minLabel': 'min',
      'cancelRideTitle': 'Cancel Ride',
      'cancelScheduledRideConfirm': 'Are you sure you want to cancel this scheduled ride?',
      'keepLabel': 'Keep',
      'rideCancelledPeriod': 'Ride cancelled.',
      'noUpcomingRides': 'No upcoming rides',
      'scheduleRideToSeeHere': 'Schedule a ride to see it here.',
      'modifyComingSoon': 'Modify coming soon.',
      'modifyBtn': 'Modify',
      'jan': 'Jan', 'feb': 'Feb', 'mar': 'Mar', 'apr': 'Apr',
      'may': 'May', 'jun': 'Jun', 'jul': 'Jul', 'aug': 'Aug',
      'sep': 'Sep', 'oct': 'Oct', 'nov': 'Nov', 'dec': 'Dec',
      // ── subscription_screen ──
      'subscriptionPlansTitle': 'Subscription Plans',
      'plansTab': 'Plans',
      'upgradeToPrefix': 'Upgrade to',
      'subscribeToPrefix': 'Subscribe to',
      'paymentColonPrefix': 'Payment:',
      'upgradeBtn': 'Upgrade',
      'subscribeBtn': 'Subscribe',
      'cancelSubscriptionQuestion': 'Cancel Subscription?',
      'benefitsContinueDesc': 'Benefits continue until your plan expires. Auto-renew will be turned off.',
      'cancelPlanBtn': 'Cancel Plan',
      'autoRideWalletLabel': 'ROTEH APP Wallet',
      'creditDebitCardLabel': 'Credit / Debit Card',
      'cardLabel': 'Card',
      'changePlanLabel': 'Change Plan',
      'choosePlanLabel': 'Choose a Plan',
      'rideCreditLabel': 'Ride credit',
      'leftSuffix': 'left',
      'cancellationsLeftLabel': 'Cancellations left',
      'autoRenewLabel': 'Auto-renew',
      'creditSuffix': 'credit',
      'offRidesSuffix': 'off rides',
      'offDeliverySuffix': 'off delivery',
      'noSurgeLabel': 'No surge',
      'freeCancellationsPerMonthSuffix': 'free cancellations / month',
      'bonusLoyaltyPointsSuffix': 'bonus loyalty points',
      'currentPlanBtn': 'Current Plan',
      'noBillingHistoryYet': 'No billing history yet.',
      'newSubscriptionLabel': 'New subscription',
      'renewalLabel': 'Renewal',
      'cancellationLabel': 'Cancellation',
      // ── support_screen ──
      'myTicketsTab': 'My Tickets',
      'faqTab': 'FAQ',
      'noSupportTickets': 'No support tickets',
      'tapPlusToCreateTicket': 'Tap + to create a new support request.',
      'openParenPrefix': 'Open',
      'resolvedParenPrefix': 'Resolved',
      'repliesCountLabel': 'replies',
      'dAgoSuffix': 'd ago',
      'hAgoSuffix': 'h ago',
      'mAgoSuffix': 'm ago',
      'needHelpTitle': 'Need help?',
      'cantFindAnswerDesc': "Can't find your answer? Open a ticket.",
      'subjectAndMessageRequired': 'Subject and message are required',
      'newSupportTicketTitle': 'New Support Ticket',
      'priorityColonLabel': 'Priority:',
      'highPriority': 'High',
      'urgentPriority': 'Urgent',
      'subjectLabel': 'Subject',
      'describeYourIssueLabel': 'Describe your issue',
      'submitTicketBtn': 'Submit Ticket',
      'noRepliesYetDesc': "No replies yet. We'll respond within 24 hours.",
      'writeAReplyHint': 'Write a reply…',
      'supportTeamLabel': 'Support Team',
      'faq1Q': 'How do I book a ride?',
      'faq1A': 'Open the app, tap Book Ride, set your pickup and destination, then confirm.',
      'faq2Q': 'How do I cancel a ride?',
      'faq2A': 'During a booking you can tap Cancel on the tracking screen. Cancellation fees may apply after the driver is on the way.',
      'faq3Q': 'How does payment work?',
      'faq3A': 'We accept cash and wallet. Choose your method before confirming the booking.',
      'faq4Q': 'How do I report a problem?',
      'faq4A': 'Create a support ticket by tapping the + button above. Our team responds within 24 hours.',
      'faq5Q': 'Where does ROTEH APP operate?',
      'faq5A': 'Currently available across Phnom Penh, Cambodia.',
      'faq6Q': 'How do I become a driver?',
      'faq6A': 'Register with role "Driver", complete verification, then register your vehicle.',
      'faq7Q': "What if the driver doesn't show up?",
      'faq7A': 'Use the SOS or contact button on the tracking screen, or cancel and rebook.',
      // ── trip_history_screen ──
      'tripTitle': 'Trip',
      'spentLabel': 'Spent',
      'noTripsFound': 'No trips found',
      'byDayLabel': 'By Day',
      'filterTripsTitle': 'Filter Trips',
      'resetLabel': 'Reset',
      'applyFiltersBtn': 'Apply Filters',
      'allTripsLabel': 'All trips',
      'tipSuffix2': 'tip',
      'thisTripNoDestinationRebook': 'This trip has no destination to rebook.',
      'bookAgainBtn': 'Book Again',
      'rateBtn': 'Rate',
      // ── voucher_screen ──
      'vouchersTitle': 'Vouchers',
      'voucherClaimedCheckMy': 'Voucher claimed! Check My Vouchers.',
      'noVouchersAvailable': 'No vouchers available',
      'claimBtn': 'Claim',
      'noVouchersYet': 'No vouchers yet',
      'claimFromStoreTab': 'Claim from the Store tab',
      'usedBadge': 'Used',
      'usedBadgeCap': 'USED',
      'expPrefix': 'Exp',
      'voucherFallback': 'Voucher',
      // ── business_screen ──
      'tabAccount': 'Account',
      'tabMembers': 'Members',
      'registerABusiness': 'Register a Business',
      'joinWithInviteCode': 'Join with Invite Code',
      'joinBusinessAccount': 'Join Business Account',
      'inviteCodeHint': 'Invite code (e.g. ABC12345)',
      'joinBusiness': 'Join Business',
      'registerBusiness': 'Register Business',
      'companyNameRequiredHint': 'Company name *',
      'taxIdHint': 'Tax ID / VAT number',
      'industryHint': 'Industry',
      'contactPerson': 'Contact Person',
      'contactNameRequiredHint': 'Contact name *',
      'contactPhoneHint': 'Contact phone',
      'billingEmailRequiredHint': 'Billing email *',
      'billingCycle': 'Billing Cycle',
      'companyAddressHint': 'Company address',
      'taxIdLabel': 'Tax ID',
      'billingEmailLabel': 'Billing Email',
      'billingCycleLabel': 'Billing Cycle',
      'contactLabel': 'Contact',
      'addressLabel': 'Address',
      'inviteCodeLabel': 'Invite Code',
      'editAccount': 'Edit Account',
      'editBusinessAccount': 'Edit Business Account',
      'companyNameHint': 'Company name',
      'billingEmailHint': 'Billing email',
      'contactNameHint': 'Contact name',
      'addressHint': 'Address',
      'roleMemberAdminHint': 'Role (member / admin)',
      'departmentHint': 'Department',
      'costCenterHint': 'Cost center',
      'employeeIdHint': 'Employee ID',
      'monthlyLimitKhrHint': 'Monthly limit (KHR)',
      'businessTripDefault': 'Business Trip',
      'weeklyLabel': 'Weekly',
      'monthlyLabel': 'Monthly',
      // ── settings_screen ──
      'settingsTitle': 'Settings',
      'biometricLogin': 'Biometric Login',
      // ── onboarding_screen ──
      'next': 'Next',
      'getStarted': 'Get Started',
      'onboardWelcomeTitle': 'Welcome to ROTEH',
      'onboardWelcomeSubtitle': 'Your smart ride companion in Cambodia.\nFast, safe, and affordable rides at your fingertips.',
      'onboardBookTitle': 'Book in Seconds',
      'onboardBookSubtitle': 'Choose your vehicle type — Car, Bike, or Tuk-Tuk.\nGet a fare estimate before you confirm.',
      'onboardPaySubtitle': 'Pay by cash or use ROTEH Pay wallet.\nSend money to friends with QR code.',
      'onboardRewardsTitle': 'Earn Rewards',
      'onboardRewardsSubtitle': 'Collect ROTEH Points on every trip.\nClimb from Bronze to Platinum and unlock exclusive benefits.',
      // ── auth_service ──
      'phoneVerificationFailedMsg': 'Phone verification failed.',
      'couldNotObtainFirebaseToken': 'Could not obtain Firebase ID token.',
      // ── marketplace_screen ──
      'browseTab': 'Browse',
      'myOrdersTab': 'My Orders',
      'popularListings': 'Popular Listings',
      'recentListings': 'Recent Listings',
      'allListingsTitle': 'All Listings',
      'forSaleLabel': 'For Sale',
      'forRentLabel': 'For Rent',
      'saleAndRentLabel': 'Sale & Rent',
      'listingTypeLabel': 'Listing Type',
      'conditionNewLabel': 'New',
      'conditionUsedLabel': 'Used',
      'conditionRefurbishedLabel': 'Refurbished',
      'conditionRefurbAbbrev': 'Refurb',
      'viewsCountSuffix': 'views',
      'viewsSpecLabel': 'Views',
      'perDaySpecLabel': 'Per Day',
      'buyNowLabel': 'Buy Now',
      'rentNowLabel': 'Rent Now',
      'searchLocationHint': 'Search location…',
      'dragMapToSetLocation': 'Drag map to set location',
      'setPickupHere': 'Set Pick-up Here',
      'setDropoffHere': 'Set Drop-off Here',
      'pickUpShortLabel': 'Pick Up',
      'deliverCarToMyAddress': 'Deliver the car to my address',
      'addItemTitle': 'Add Item',
      'searchListingsHint': 'Search listings…',
      'selectRentalDatesError': 'Please select rental start and end dates.',
      'walletLabel': 'Wallet',
      'onlineLabel': 'Online',
      'buyItemTitle': 'Buy Item',
      'rentItemTitle': 'Rent Item',
      'durationLabel': 'Duration',
      'selectLabel': 'Select',
      'anySpecialInstructionsHint': 'Any special instructions…',
      'orderSummaryLabel': 'Order Summary',
      'vehicleLabel': 'Vehicle',
      'totalSummaryLabel': 'Total Summary',
      'confirmRentalLabel': 'Confirm Rental',
      'selectDatesToContinue': 'Select Dates to Continue',
      'proceedToCheckout': 'Proceed to Checkout',
      'noListingsYetTitle': 'No listings yet',
      'postSomethingToStartSelling': 'Post something to start selling',
      'purchaseLabel': 'Purchase',
      'titleIsRequiredError': 'Title is required.',
      'priceMustBeNumberError': 'Price must be a number.',
      'enterValidPricePrefix': 'Enter a valid price for',
      'updatedExclaim': 'Updated!',
      'postedExclaim': 'Posted!',
      'egIphone14Pro': 'e.g. iPhone 14 Pro',
      'egRemovableCanopy': 'e.g. Removable Canopy',
      'egBkk1PhnomPenh': 'e.g. BKK1, Phnom Penh',
      'saleTypeLabel': 'Sale',
      'bothTypeLabel': 'Both',
      'draftStatusLabel': 'Draft',
      'pausedStatusLabel': 'Paused',
      'soldStatusLabel': 'Sold',
      'postListingBtn': 'Post Listing',
      'buyingTab': 'Buying',
    },
    'km': {
       'appName': 'រទេះ',
      'tagline': 'រទេះអេប',
      'copyright': 'រទេះអេប © ២០២៦ — រក្សាសិទ្ធិគ្រប់យ៉ាង',
      'whoAreYou': 'អ្នកជានរណា?',
      'selectRole': 'ជ្រើសរើសតួនាទីដើម្បីបន្ត',
      'passenger': 'អ្នកដំណើរ',
      'passengerSub': 'កក់ការធ្វើដំណើរ, ហៅការដឹកជញ្ជូន\nទិញ ឬជួលយានយន្តអគ្គិសនី',
      'driver': 'អ្នកបើកបរ',
      'driverSub': 'ទទួលសំណើដឹក, គ្រប់គ្រង\nការដឹកជញ្ជូន & រកប្រាក់',
      'home': 'រទេះ',
      'charging': 'ប្តូរថ្ម',
      'chat': 'សារ',
      'profile': 'ប្រវត្តិរូប',
      'earnings': 'ប្រាក់ចំណូល',
      'dashboard': 'ផ្ទាំងគ្រប់គ្រង',
      'bookRide': 'ហៅរទេះ',
      'bookRideSub': 'ឥលូវ ឬ កក់ទុកមុន',
      'delivery': 'ដឹកជញ្ជូន',
      'deliverySub': 'ដឹកឥវ៉ាន់/ដឹករហ័ស',
      'marketplace': 'ផ្សារ',
      'marketplaceSub': 'ទិញ/ជួលយានជំនិះ',
      'evStations': 'ស្ថានីយ៍ប្តូរថ្ម',
      'evStationsSub': 'ស្វែងរកទីតាំងប្តូរថ្មនៅជិតអ្នក',
      'safety': 'សុវត្ថិភាព',
      'payment': 'ការទូទាត់',
      'support': 'ជំនួយ',
      'recentTrips': 'ដំណើរថ្មីៗ',
      'seeAll': 'មើលទាំងអស់',
      'services': 'ប្រតិបត្តិការ',
      'quickActions': 'សកម្មភាពរហ័ស',
      'whereAreYouGoing': 'ថ្ងៃនេះអ្នកចង់ទៅណាដែរ?',
      'bookNow': 'កក់ឥលូវ',
      'scheduleRide': 'កក់ទុកមុន',
      'scheduleForLater': 'កក់ទុកសម្រាប់ពេលក្រោយ',
      'sendNow': 'ផ្ញើឥលូវ',
      'evChargingStations': 'ស្ថានីយ៍ប្តូរថ្ម',
      'buy': 'ទិញ',
      'rent': 'ជួល',
      'trackTrip': 'តាមដានដំណើរ',
      'driverOnTheWay': 'អ្នកបើកបរកំពុងមក',
      'tripInProgress': 'កំពុងធ្វើដំណើរ',
      'arrived': 'អ្នកបើកបរមកដល់ហើយ!',
      'paySecurely': 'ទូទាត់ដោយសុវត្ថិភាព',
      'emergencySOS': 'SOS បន្ទាន់',
      'selectLanguage': 'ជ្រើសរើសភាសា',
      'language': 'ភាសា',
      'goodMorning': 'អរុណសួស្តី,',
      'hello': 'សួស្តី',
      'welcome': 'សូមស្វាគមន៍!',
      'online': 'អនឡាញ',
      'offline': 'គ្មានអ៊ីនធឺណិត',
      'driverDashboard': 'ផ្ទាំងអ្នកបើកបរ',
      'messages': 'សារ & ជំនួយ',
      'paymentSuccessful': 'ការទូទាត់ជោគជ័យ!',
      'signOut': 'ចាកចេញ',
      'paymentMethods': 'វិធីទូទាត់',
      'safetySettings': 'ការកំណត់សុវត្ថិភាព',
      'tripHistory': 'ប្រវត្តិដំណើរ',
      'notifications': 'ការជូនដំណឹង',
      'helpSupport': 'គាំទ្រ & ជំនួយ',
      'bankPayouts': 'ទូទាត់តាមធនាគារ',
      'documents': 'ឯកសារ',
      'navigate': 'ស្វែងរក',
      'available': 'មាន',
      'connectionErrorRetry': 'មិនអាចភ្ជាប់ទៅម៉ាស៊ីនមេបានទេ សូមពិនិត្យអ៊ីនធឺណិតរបស់អ្នក ហើយព្យាយាមម្តងទៀត',
      'sortBy': 'តម្រៀបតាម',
      'sortNewest': 'ថ្មីបំផុត',
      'sortOldest': 'ចាស់បំផុត',
      'sortPriceHigh': 'តម្លៃ៖ ខ្ពស់ទៅទាប',
      'sortPriceLow': 'តម្លៃ៖ ទាបទៅខ្ពស់',
      'searchRentalsHint': 'ស្វែងរកការជួល…',
      'rentalBookedSuccess': 'ការជួលបានកក់ដោយជោគជ័យ!',
      'rentalHeaderSubtitle': 'បំពេញព័ត៌មានដើម្បីកក់យានជួល',
      'drvTopUpMsg': 'សមតុល្យកាបូបរបស់អ្នកទាបពេកដើម្បីចូលធ្វើការ សូមបញ្ចូលទឹកប្រាក់យ៉ាងតិច {amount} ដើម្បីបន្ត',
      'drvShortBy': 'ខ្វះ {amount}',
      'drvKmAway': 'ចម្ងាយ {km} គ.ម',
      'drvEndsInHm': 'បញ្ចប់ក្នុង {h} ម៉ោង {m} នាទី',
      'drvEndsInMin': 'បញ្ចប់ក្នុង {m} នាទី',
      'drvTripsCount': '{n} ដំណើរ',
      'drvSurgeInside': 'តំបន់តម្លៃកើនឡើង {x}× — អ្នកនៅក្នុងតំបន់!',
      'drvSurgeNearby': 'តំបន់តម្លៃកើនឡើង {x}× នៅជិត — {zone}',
      'drvZone': 'តំបន់',
      'drvInactive': 'អសកម្ម',
      'drvPeakExtra': 'បន្ថែម {amount} ក្នុងមួយដំណើរ ក្នុងម៉ោងមមាញឹក',
      'drvPeakProgress': 'ថ្ងៃនេះបានបញ្ចប់ {done}/{target} ដំណើរក្នុងម៉ោងមមាញឹក',
      'drvStreakCount': 'ទទួលបាន 5 ផ្កាយជាប់ៗគ្នា {n} ដង!',
      'drvStreakRemaining': '{n} ដង 5 ផ្កាយទៀត = ទទួលបានប្រាក់រង្វាន់ {amount}',
      'drvStreakUnlocked': 'បានទទួលប្រាក់រង្វាន់ជាប់ៗគ្នា — {amount}!',
      'drvPassengerNo': 'អ្នកដំណើរ #{id}',
      'drvSenderNo': 'អ្នកផ្ញើ #{id}',
      'drvSecondsShort': '{n} វិ',
      'drvFloors': 'ជាន់៖ ទទួល {from} → ទម្លាក់ {to}',
      'drvElevator': 'ជណ្តើរយន្ត៖ {v}',
      'drvHelpers': 'អ្នកជំនួយ {n} នាក់ — {type}',
      'drvHeavyCarry': 'លើកធ្ងន់',
      'drvNormalCarry': 'លើកធម្មតា',
      'drvWithdrawConfirm': 'ដកសមតុល្យទាំងអស់ទៅ {bank}?\nសំណើនេះនឹងត្រូវផ្ញើទៅអ្នកគ្រប់គ្រងដើម្បីអនុម័ត',
      'drvWithdrawSubmitted': '✅ បានដាក់សំណើដកប្រាក់ {amount} — កំពុងរង់ចាំការអនុម័ត',
      'drvMinWithdrawal': 'ការដកប្រាក់អប្បបរមា៖ {amount}',
      'drvWithdrawTo': '💸  ដក {amount} ទៅ {bank}',
      'drvTodaysTransactions': 'ប្រតិបត្តិការថ្ងៃនេះ',
      'drvTotalCount': 'សរុប {n}',
      'drvBalanceShort': 'សមតុល្យ៖ {amount}',
      'seatsCount': '{n} កៅអី',
      'seatsOne': '1 កៅអី',
      'senderNameHint': 'ឈ្មោះអ្នកផ្ញើ',
      'senderPhoneHint': 'លេខទូរស័ព្ទអ្នកផ្ញើ',
      'recipientNameHint': 'ឈ្មោះអ្នកទទួល',
      'recipientPhoneHint': 'លេខទូរស័ព្ទអ្នកទទួល',
      'floorsPickupDropoff': 'ទទួល៖ {from}  •  ទម្លាក់៖ {to}',
      'packageAmountHint': 'តម្លៃកញ្ចប់ឥវ៉ាន់ ជា ៛ (ស្រេចចិត្ត)',
      'packageAmount': 'តម្លៃកញ្ចប់ឥវ៉ាន់',
      'deliveryFee': 'ថ្លៃដឹកជញ្ជូន',
      'serviceFee': 'ថ្លៃសេវា',
      'pickup': 'ទីតាំងទទួល',
      'completedAt': 'បញ្ចប់នៅ',
      'completionTime': 'ពេលវេលាបញ្ចប់',
      'deliveryCompleted': 'ការដឹកជញ្ជូនបានបញ្ចប់',
      'deliveryReceipt': 'បង្កាន់ដៃដឹកជញ្ជូន',
      'deliverySummary': 'សង្ខេបការដឹកជញ្ជូន',
      'viewDeliverySummary': 'មើលសង្ខេបការដឹកជញ្ជូន',
      'feePaidBy': 'ថ្លៃបង់ដោយ',
      'paidBySender': 'បង់ដោយអ្នកផ្ញើ',
      'paidByRecipient': 'បង់ដោយអ្នកទទួល',
      'guestOtpReason': 'សូមផ្ទៀងផ្ទាត់លេខទូរស័ព្ទរបស់អ្នក ដើម្បីដាក់ការបញ្ជាទិញនេះ',
      'confirmOtpTitle': 'បញ្ជាក់លេខកូដ OTP',
      'otpSentToYourPhone': 'យើងបានផ្ញើលេខកូដ 6 ខ្ទង់ទៅលេខទូរស័ព្ទរបស់អ្នក',
      'didntReceiveCode': 'មិនទាន់ទទួលលេខកូដ?',
      'resendShort': 'ផ្ញើម្តងទៀត',
      'guestPhoneStarHint': 'លេខទូរស័ព្ទ * (ឧ. 012 345 678)',
      'guestFullNameRequired': 'សូមបញ្ចូលឈ្មោះពេញរបស់អ្នក',
      'guestPhoneInvalid': 'សូមបញ្ចូលលេខទូរស័ព្ទត្រឹមត្រូវ (8–16 ខ្ទង់)',
      'guestPhoneNotVerified': 'សូមផ្ទៀងផ្ទាត់លេខទូរស័ព្ទរបស់អ្នកជាមួយលេខកូដ SMS',
      'guestOtpNote': 'យើងនឹងផ្ញើលេខកូដ SMS ដើម្បីផ្ទៀងផ្ទាត់លេខនេះ',
      'regJoinTitle': 'ចូលរួមជាមួយ ROTEH',
      'regTagline': 'ការធ្វើដំណើររហ័ស និងសុវត្ថិភាពនៅកម្ពុជា',
      'regIWantTo': 'ខ្ញុំចង់',
      'regRideAsPassenger': 'ជិះជាអ្នកដំណើរ',
      'regDriveAndEarn': 'បើកបរ និងរកប្រាក់',
      'regOwner': 'ម្ចាស់យានជំនិះ',
      'regSelectCity': 'ជ្រើសរើសទីក្រុងរបស់អ្នក',
      'regCityRequired': 'សូមជ្រើសរើសទីក្រុង',
      'regNameRequired': 'សូមបញ្ចូលឈ្មោះ',
      'regEmailRequired': 'សូមបញ្ចូលអ៊ីមែល',
      'regEmailInvalid': 'សូមបញ្ចូលអ៊ីមែលឲ្យបានត្រឹមត្រូវ',
      'regPhoneOptional': 'លេខទូរស័ព្ទ (ស្រេចចិត្ត)',
      'regPasswordMin': 'យ៉ាងតិច ៨ តួអក្សរ',
      'regPasswordMismatch': 'ពាក្យសម្ងាត់មិនដូចគ្នាទេ',
      'regReferralOptional': 'លេខកូដណែនាំ (ស្រេចចិត្ត)',
      'regRegisterUpload': 'ចុះឈ្មោះ និងបញ្ចូលឯកសារ',
      'cityPhnomPenh': 'ភ្នំពេញ',
      'citySiemReap': 'សៀមរាប',
      'citySihanoukville': 'ព្រះសីហនុ',
      'cityBattambang': 'បាត់ដំបង',
      'cityKampongCham': 'កំពង់ចាម',
      'cityKampot': 'កំពត',
      'cityKep': 'កែប',
      'cityPoipet': 'ប៉ោយប៉ែត',
      'chatsTab': 'ការជជែក',
      'noConversationsYet': 'មិនទាន់មានការសន្ទនានៅឡើយ',
      'driverMessagesHint': 'សារជាមួយអ្នកបើកបររបស់អ្នកនឹងបង្ហាញនៅទីនេះ',
      'rotehSupport': 'ផ្នែកជំនួយ ROTEH',
      'chatWithOurTeam': 'ជជែកជាមួយក្រុមការងាររបស់យើង',
      'noMessagesSayHello': 'មិនទាន់មានសារនៅឡើយ សូមផ្ញើសារសួរសុខទុក្ខ!',
      'typeAMessageHint': 'វាយសារ...',
      'howCanWeHelp': 'តើយើងអាចជួយអ្វីបាន?',
      'searchForHelp': 'ស្វែងរកជំនួយ...',
      'quickHelp': 'ជំនួយរហ័ស',
      'qhDriverLate': 'អ្នកបើកបររបស់ខ្ញុំមកយឺត',
      'qhOvercharged': 'ខ្ញុំត្រូវបានគិតថ្លៃលើស',
      'qhLostItem': 'ភ្លេចរបស់របរក្នុងយានជំនិះ',
      'qhSafetyIssue': 'រាយការណ៍បញ្ហាសុវត្ថិភាព',
      'qhCancelTrip': 'បោះបង់ដំណើររបស់ខ្ញុំ',
      'support247': 'ជំនួយ 24/7',
      'openTicketReplyHere': 'បើកសំណើជំនួយ ហើយក្រុមការងាររបស់យើងនឹងឆ្លើយតបនៅទីនេះ',
      'chatNow': 'ជជែកឥឡូវ',
      'supportRepliesSoon': 'សួរសុខទុក្ខមកយើង! ក្រុមការងាររបស់យើងតែងឆ្លើយតបក្នុងរយៈពេលប៉ុន្មាននាទី',
      'uploadFromGallery': 'ផ្ទុកឡើងពីវិចិត្រសាល',
      'couldNotSendPhoto': 'មិនអាចផ្ញើរូបថតបានទេ៖ {error}',
      'couldNotLoadMessages': 'មិនអាចផ្ទុកសារបានទេ៖ {error}',
      'missedRequestsTitle': 'សំណើដែលខកខាន',
      'missedTab': 'ខកខាន',
      'declinedTab': 'បានបដិសេធ',
      'reasonMissed': 'មិនបានឆ្លើយតបទាន់ពេល',
      'reasonDeclined': 'អ្នកបានបដិសេធ',
      'outcomeOpen': 'នៅទំនេរ',
      'outcomeTaken': 'អ្នកបើកបរផ្សេងបានទទួល',
      'outcomeCancelled': 'បានបោះបង់',
      'noMissedRequests': 'មិនមានសំណើដែលខកខាន',
      'missedRequestsHint': 'សំណើដែលអ្នកបដិសេធ ឬមិនបានឆ្លើយតបទាន់ពេល នឹងបង្ហាញនៅទីនេះ',
      'trRemove': 'លុបចេញ',
      'trSwitch': 'ប្តូរ',
      'trAccount': 'គណនី',
      'trBack': 'ត្រឡប់ក្រោយ',
      'trSave': 'រក្សាទុក',
      'trDelete': 'លុប',
      'trEdit': 'កែប្រែ',
      'trApprove': 'អនុម័ត',
      'trReject': 'បដិសេធ',
      'trApproved': 'បានអនុម័ត',
      'trRejected': 'បានបដិសេធ',
      'trPending': 'កំពុងរង់ចាំ',
      'trActive': 'សកម្ម',
      'trInactive': 'អសកម្ម',
      'trTitle': 'ចំណងជើង',
      'trRefresh': 'ផ្ទុកឡើងវិញ',
      'trSignOut': 'ចាកចេញ',
      'trUnknown': 'មិនស្គាល់',
      'trSearch': 'ស្វែងរក',
      'trMap': 'ផែនទី',
      'trView': 'មើល',
      'trNow': 'ឥឡូវនេះ',
      'trJustNow': 'អម្បាញ់មិញ',
      'trMinutesAgo': '{n} នាទីមុន',
      'trHoursAgo': '{n} ម៉ោងមុន',
      'trDaysAgo': '{n} ថ្ងៃមុន',
      'trMinAgoLong': '{n} នាទីមុន',
      'trHrsAgoLong': '{n} ម៉ោងមុន',
      'trDaysAgoLong': '{n} ថ្ងៃមុន',
      'trTodayAt': 'ថ្ងៃនេះ {time}',
      'trPerDay': '/ថ្ងៃ',
      'trTryAgain': 'ព្យាយាមម្តងទៀត',
      'trProcessing': 'កំពុងដំណើរការ…',
      'trCustomerNo': 'អតិថិជន #{id}',
      'trDriverNo': 'អ្នកបើកបរ #{id}',
      'trRideNo': 'ដំណើរ #{id}',
      'trStopN': 'ចំណត {n}',
      'trStopWithAddress': 'ចំណត {n}៖ {address}',
      'trStopDestination': 'ចំណត {n} — គោលដៅ',
      'trStopDistance': 'ចំណត {n} · {km} គ.ម',
      'trDistanceKm': 'ចម្ងាយ ({km} គ.ម)',
      'trPromoWithCode': 'ប្រូម៉ូសិន ({code})',
      'trYouEarned': 'អ្នកទទួលបាន {amount}',
      'trEtaMin': 'ប្រហែល {n} នាទី',
      'trFromPlace': 'ពី៖ {place}',
      'trToPlace': 'ទៅ៖ {place}',
      'trFareKhr': 'ថ្លៃ៖ {amount} ៛',
      'trCar': 'ឡាន',
      'trBike': 'ម៉ូតូ',
      'trTukTuk': 'កង់បី',
      'trVan': 'ឡានវ៉ាន',
      'trHome': 'ផ្ទះ',
      'trWork': 'កន្លែងធ្វើការ',
      'trCash': 'សាច់ប្រាក់',
      'trWalletTopUp': 'បញ្ចូលទឹកប្រាក់កាបូប',
      'trTripEarning': 'ចំណូលពីដំណើរ',
      'trPlatformFee': 'ថ្លៃសេវាកម្មវិធី',
      'trBonusCredit': 'ប្រាក់រង្វាន់',
      'trTripPayment': 'ការទូទាត់ដំណើរ',
      'trRefund': 'ប្រាក់សងវិញ',
      'trGoogleNotConfigured': 'ការចូលដោយ Google មិនទាន់បានកំណត់សម្រាប់កម្មវិធីនេះទេ សូមទាក់ទងផ្នែកជំនួយ',
      'trAdminRole': 'អ្នកគ្រប់គ្រង',
      'trEnterOtp': 'បញ្ចូលលេខកូដ OTP',
      'trPhoneLogin': 'ចូលដោយលេខទូរស័ព្ទ',
      'trCodeSentTo': 'លេខកូដត្រូវបានផ្ញើទៅ {phone}',
      'trWeSendSmsCode': 'យើងនឹងផ្ញើលេខកូដប្រើម្តងតាម SMS',
      'trResendCodeIn': 'ផ្ញើលេខកូដម្តងទៀតក្នុង {n}វិ',
      'trThisAccount': 'គណនីនេះ',
      'trRemoveAccount': 'លុបគណនីចេញ',
      'trUnlinkConfirm': 'ផ្តាច់ {name} ពីគណនីរបស់អ្នក?',
      'trSwitchAccount': 'ប្តូរគណនី',
      'trLinkAccount': 'ភ្ជាប់គណនី',
      'trNoLinkedAccounts': 'មិនមានគណនីដែលបានភ្ជាប់',
      'trLinkAnotherAccount': 'ភ្ជាប់គណនីផ្សេងទៀត ដើម្បីប្តូររវាងគណនី',
      'trLabelOptionalWork': 'ស្លាក (ស្រេចចិត្ត ឧ. "ការងារ")',
      'trNewCodeSent': 'បានផ្ញើលេខកូដថ្មី',
      'trVerifyPhone': 'ផ្ទៀងផ្ទាត់លេខទូរស័ព្ទ',
      'trEnterVerificationCode': 'បញ្ចូលលេខកូដផ្ទៀងផ្ទាត់',
      'trDidntReceiveCode': 'មិនទាន់ទទួលបានលេខកូដ? ',
      'trResendInSeconds': 'ផ្ញើម្តងទៀតក្នុង {n}វិ',
      'trNoTasksNow': 'មិនមានការងារ{label}ទេនៅពេលនេះ',
      'trSosFailedCall': 'មិនអាចផ្ញើ SOS បានទេ សូមហៅសេវាសង្គ្រោះបន្ទាន់ដោយផ្ទាល់',
      'trNoDestinationMeteredFare': 'ដំណើរនេះគ្មានគោលដៅ — សូមបញ្ចូលថ្លៃតាមម៉ែត្រ ដើម្បីបញ្ចប់',
      'trCouldntAutoCalc': 'មិនអាចគណនាដោយស្វ័យប្រវត្តិបានទេ៖ ',
      'trFromKmTravelled': 'ពី {km} គ.ម',
      'trUser': 'អ្នកប្រើប្រាស់',
      'trCreditName': 'បញ្ចូលប្រាក់ឲ្យ {name}',
      'trAmountKhr': 'ចំនួនទឹកប្រាក់ (រៀល)',
      'trNoteOptional': 'កំណត់ចំណាំ (ស្រេចចិត្ត)',
      'trCredit': 'បញ្ចូលប្រាក់',
      'trCreditApplied': 'បានបញ្ចូលប្រាក់',
      'trDeleteUser': 'លុបអ្នកប្រើប្រាស់',
      'trPermanentlyDelete': 'លុប {name} ជាអចិន្ត្រៃយ៍?',
      'trUsers': 'អ្នកប្រើប្រាស់',
      'trSearchNameEmail': 'ស្វែងរកតាមឈ្មោះ / អ៊ីមែល…',
      'trAllRoles': 'តួនាទីទាំងអស់',
      'trNoUsersFound': 'រកមិនឃើញអ្នកប្រើប្រាស់',
      'trCreditWallet': 'បញ្ចូលប្រាក់កាបូប',
      'trNotifications': 'ការជូនដំណឹង',
      'trMarkAllRead': 'សម្គាល់ថាបានអានទាំងអស់',
      'trNoNotificationsYet': 'មិនទាន់មានការជូនដំណឹង',
      'trCarRental': 'ការជួលឡាន',
      'trMarketplaceOrder': 'ការបញ្ជាទិញពីផ្សារ',
      'trManageOnWebAdmin': 'សូមបញ្ជាក់ ឬគ្រប់គ្រងការបញ្ជាទិញនេះពីផ្ទាំងគ្រប់គ្រងលើវេប',
      'trTransactions': 'ប្រតិបត្តិការ',
      'trDebit': 'ដកប្រាក់',
      'trTopUp': 'បញ្ចូលប្រាក់',
      'trWithdraw': 'ដកប្រាក់',
      'trNoTransactions': 'មិនមានប្រតិបត្តិការ',
      'trDriverApproved': 'បានអនុម័តអ្នកបើកបរ',
      'trDriverRejected': 'បានបដិសេធអ្នកបើកបរ',
      'trDriverApplications': 'ពាក្យស្នើសុំអ្នកបើកបរ',
      'trNoPendingApplications': 'មិនមានពាក្យស្នើសុំកំពុងរង់ចាំ',
      'trRejectDriver': 'បដិសេធអ្នកបើកបរ',
      'trProvideReasonOptional': 'ផ្តល់មូលហេតុ (ស្រេចចិត្ត)៖',
      'trEgDocsUnclear': 'ឧ. ឯកសារមិនច្បាស់ អត្តសញ្ញាណប័ណ្ណផុតកំណត់…',
      'trReviewDocs': 'ពិនិត្យឯកសារ',
      'trNationalIdPassport': 'អត្តសញ្ញាណប័ណ្ណ / លិខិតឆ្លងដែន',
      'trDriverLicense': 'ប័ណ្ណបើកបរ',
      'trVehicleRegistration': 'កាតគ្រីយានយន្ត',
      'trSelfieWithId': 'រូបថតខ្លួនឯងជាមួយអត្តសញ្ញាណប័ណ្ណ',
      'trVehicleInsurance': 'ធានារ៉ាប់រងយានយន្ត',
      'trOtherDocument': 'ឯកសារផ្សេងៗ',
      'trRejectDocument': 'បដិសេធឯកសារ',
      'trReasonImageBlurry': 'មូលហេតុ (ឧ. រូបភាពព្រិលពេក)',
      'trApproveDriver': 'អនុម័តអ្នកបើកបរ',
      'trServiceZoneOptional': 'តំបន់សេវាកម្ម (ស្រេចចិត្ត)៖',
      'trEgZoneA': 'ឧ. ភ្នំពេញ តំបន់ A',
      'trConfirmApprove': 'បញ្ជាក់ការអនុម័ត',
      'trDriverApprovedExcl': 'បានអនុម័តអ្នកបើកបរ!',
      'trDocuments': 'ឯកសារ',
      'trNoDocumentsYet': 'មិនទាន់មានឯកសារបានបញ្ចូល',
      'trNoteWith': 'កំណត់ចំណាំ៖ {note}',
      'trViewDocument': 'មើលឯកសារ',
      'trPricingSaved': 'បានរក្សាទុកការកំណត់តម្លៃ',
      'trPricingSettings': 'ការកំណត់តម្លៃ',
      'trSaveSettings': 'រក្សាទុកការកំណត់',
      'trDeleteBanner': 'លុបផ្ទាំងផ្សាយ',
      'trRemoveBannerQ': 'លុបផ្ទាំងផ្សាយនេះ?',
      'trBanners': 'ផ្ទាំងផ្សាយ',
      'trNoBannersYet': 'មិនទាន់មានផ្ទាំងផ្សាយ',
      'trUntitled': 'គ្មានចំណងជើង',
      'trNewBanner': 'ផ្ទាំងផ្សាយថ្មី',
      'trEditBanner': 'កែប្រែផ្ទាំងផ្សាយ',
      'trSubtitleDescription': 'ចំណងជើងរង / ការពិពណ៌នា',
      'trImageUrlOptional': 'តំណរូបភាព (ស្រេចចិត្ត)',
      'trSaveBanner': 'រក្សាទុកផ្ទាំងផ្សាយ',
      'trSupportTickets': 'សំណើជំនួយ',
      'trOpen': 'បើក',
      'trInProgress': 'កំពុងដំណើរការ',
      'trResolved': 'បានដោះស្រាយ',
      'trClosed': 'បានបិទ',
      'trNoTicketsFound': 'រកមិនឃើញសំណើជំនួយ',
      'trNoSubject': 'គ្មានប្រធានបទ',
      'trTicketNo': 'សំណើ #{id}',
      'trMarkOpen': 'សម្គាល់ថាបើក',
      'trMarkInProgress': 'សម្គាល់ថាកំពុងដំណើរការ',
      'trMarkResolved': 'សម្គាល់ថាបានដោះស្រាយ',
      'trMarkClosed': 'សម្គាល់ថាបានបិទ',
      'trTypeReply': 'វាយការឆ្លើយតប…',
      'trTopUpApproved': 'បានអនុម័តការបញ្ចូលប្រាក់ និងបញ្ចូលទៅកាបូប',
      'trRejectTopUp': 'បដិសេធការបញ្ចូលប្រាក់',
      'trReasonColon': 'មូលហេតុ៖',
      'trEnterReason': 'បញ្ចូលមូលហេតុ',
      'trRejectedDot': 'បានបដិសេធ',
      'trTopUpRequests': 'សំណើបញ្ចូលប្រាក់',
      'trNoTopUpRequests': 'មិនមានសំណើបញ្ចូលប្រាក់',
      'trCancelRide': 'បោះបង់ដំណើរ',
      'trReasonForCancellation': 'មូលហេតុនៃការបោះបង់៖',
      'trEgPolicyViolation': 'ឧ. បំពានគោលការណ៍',
      'trRides': 'ដំណើរ',
      'trNoRidesFound': 'រកមិនឃើញដំណើរ',
      'trApproveWithdrawal': 'អនុម័តការដកប្រាក់',
      'trAddNoteOptional': 'បន្ថែមកំណត់ចំណាំ (ស្រេចចិត្ត)៖',
      'trEgTransferredAba': 'ឧ. បានផ្ទេរតាម ABA',
      'trApprovedDot': 'បានអនុម័ត',
      'trRejectWithdrawal': 'បដិសេធការដកប្រាក់',
      'trReasonRequired': 'មូលហេតុ (ចាំបាច់)៖',
      'trEgInvalidAccount': 'ឧ. លេខគណនីមិនត្រឹមត្រូវ',
      'trWithdrawals': 'ការដកប្រាក់',
      'trNoWithdrawalsFound': 'រកមិនឃើញការដកប្រាក់',
      'trSafetyIncidents': 'ឧប្បត្តិហេតុសុវត្ថិភាព',
      'trCrash': 'គ្រោះថ្នាក់',
      'trUserReport': 'របាយការណ៍អ្នកប្រើ',
      'trNoSafetyIncidents': 'មិនមានឧប្បត្តិហេតុសុវត្ថិភាព',
      'trDeliveries': 'ការដឹកជញ្ជូន',
      'trNoDeliveriesFound': 'រកមិនឃើញការដឹកជញ្ជូន',
      'trAdminDashboard': 'ផ្ទាំងគ្រប់គ្រង',
      'trRevenue7Days': 'ចំណូល (៧ ថ្ងៃ)',
      'trSurgePromoControl': 'គ្រប់គ្រងតម្លៃកើន និងប្រូម៉ូសិន',
      'trSurge': 'តម្លៃកើន',
      'trPromos': 'ប្រូម៉ូសិន',
      'trThisZone': 'តំបន់នេះ',
      'trDeleteSurgeZone': 'លុបតំបន់តម្លៃកើន',
      'trDeleteNamedQ': 'លុប "{name}"?',
      'trNewZone': 'តំបន់ថ្មី',
      'trNoSurgeZones': 'មិនទាន់មានតំបន់តម្លៃកើន',
      'trNewSurgeZone': 'តំបន់តម្លៃកើនថ្មី',
      'trEditSurgeZone': 'កែប្រែតំបន់តម្លៃកើន',
      'trZoneName': 'ឈ្មោះតំបន់',
      'trEgCityCentre': 'ឧ. កណ្តាលក្រុង',
      'trDescriptionOptional': 'ការពិពណ៌នា (ស្រេចចិត្ត)',
      'trEgHighDemand': 'ឧ. តំបន់មានតម្រូវការខ្ពស់',
      'trMultiplierX': 'មេគុណ៖ ×{x}',
      'trCreateZone': 'បង្កើតតំបន់',
      'trSaveChanges': 'រក្សាទុកការផ្លាស់ប្តូរ',
      'trDeletePromo': 'លុបប្រូម៉ូសិន',
      'trNewPromo': 'ប្រូម៉ូសិនថ្មី',
      'trNoPromoCodes': 'មិនមានលេខកូដប្រូម៉ូសិន',
      'trAmountOff': 'បញ្ចុះ {amount}',
      'trUsesLeft': 'នៅសល់ {n} ដង',
      'trExpShort': 'ផុត {date}',
      'trCodeDiscountRequired': 'ត្រូវការលេខកូដ និងចំនួនបញ្ចុះតម្លៃ',
      'trEditPromoCode': 'កែប្រែលេខកូដប្រូម៉ូសិន',
      'trNewPromoCode': 'លេខកូដប្រូម៉ូសិនថ្មី',
      'trPromoCode': 'លេខកូដប្រូម៉ូសិន',
      'trDiscountKhr': 'ការបញ្ចុះតម្លៃ (រៀល)',
      'trMaxUsesHint': 'ចំនួនប្រើអតិបរមា (ទុកទទេ = គ្មានដែនកំណត់)',
      'trExpiresAtHint': 'ផុតកំណត់នៅ (YYYY-MM-DD)',
      'trCreatePromo': 'បង្កើតប្រូម៉ូសិន',
      'trDeleteFareRule': 'លុបច្បាប់តម្លៃ',
      'trThisVehicle': 'យានជំនិះនេះ',
      'trFareManagement': 'គ្រប់គ្រងតម្លៃ',
      'trAddRule': 'បន្ថែមច្បាប់',
      'trNoFareRules': 'មិនទាន់មានច្បាប់តម្លៃ',
      'trBaseFare': 'ថ្លៃមូលដ្ឋាន',
      'trPerKm': 'ក្នុងមួយគ.ម',
      'trMinimum': 'អប្បបរមា',
      'trFillFareFields': 'សូមបំពេញចន្លោះតម្លៃទាំងអស់ដោយលេខត្រឹមត្រូវ',
      'trEditFareRule': 'កែប្រែច្បាប់តម្លៃ',
      'trNewFareRule': 'ច្បាប់តម្លៃថ្មី',
      'trBaseFareKhr': 'ថ្លៃមូលដ្ឋាន (រៀល)',
      'trPerKmRateKhr': 'តម្លៃក្នុងមួយគ.ម (រៀល)',
      'trMinimumFareKhr': 'ថ្លៃអប្បបរមា (រៀល)',
      'trCreateRule': 'បង្កើតច្បាប់',
      'trDestination': 'គោលដៅ',
      'trFindingDriver': 'កំពុងស្វែងរកអ្នកបើកបរ…',
      'trDriverOnTheWay': 'អ្នកបើកបរកំពុងមក',
      'trDriverEnRoutePickup': 'អ្នកបើកបរកំពុងទៅទីតាំងទទួល',
      'trTripInProgress': 'ដំណើរកំពុងដំណើរការ',
      'trTripCompleted': 'ដំណើរបានបញ្ចប់',
      'trTripCancelled': 'ដំណើរត្រូវបានបោះបង់',
      'trLiveTrip': 'ROTEH — ដំណើរផ្ទាល់',
      'trMovingService': 'សេវាដឹកឥវ៉ាន់ផ្លាស់ទី',
      'trWaitingDriverGps': 'កំពុងរង់ចាំ GPS អ្នកបើកបរ…',
      'trPageAutoUpdates': 'ទំព័រនេះធ្វើបច្ចុប្បន្នភាពដោយស្វ័យប្រវត្តិរៀងរាល់ ៨ វិនាទី',
      'trTripNotFound': 'រកមិនឃើញដំណើរ',
      'trLookingForDriver': 'កំពុងស្វែងរកអ្នកបើកបរ...',
      'trDriverAssigned': 'បានចាត់អ្នកបើកបរ',
      'trDriverArrivedPickup': 'អ្នកបើកបរបានមកដល់ទីតាំងទទួល',
      'trLoadingItems': 'កំពុងលើកឥវ៉ាន់...',
      'trOnWayToDestination': 'កំពុងធ្វើដំណើរទៅគោលដៅ',
      'trMovingCompletedExcl': 'ការដឹកផ្លាស់ទីបានបញ្ចប់!',
      'trProcessingDots': 'កំពុងដំណើរការ...',
      'trPackagePickedUp': 'បានទទួលកញ្ចប់ឥវ៉ាន់',
      'trOnWayToRecipient': 'កំពុងដឹកទៅអ្នកទទួល',
      'trDeliveredExcl': 'បានដឹកដល់!',
      'trPackageDelivery': 'ការដឹកកញ្ចប់ឥវ៉ាន់',
      'trTrackMy': 'តាមដាន{service}របស់ខ្ញុំ',
      'trTrackMyLive': 'តាមដាន{title}របស់ខ្ញុំផ្ទាល់',
      'trMovingCompleted': 'ការដឹកផ្លាស់ទីបានបញ្ចប់',
      'trDeliveryCompletedTitle': 'ការដឹកជញ្ជូនបានបញ្ចប់',
      'trMoving': 'ការដឹកផ្លាស់ទី',
      'trRecipientLine': 'អ្នកទទួល៖ {name}',
      'trDriverLine': 'អ្នកបើកបរ៖ {name}',
      'trShareMovingTracking': 'ចែករំលែកការតាមដានការដឹកផ្លាស់ទី',
      'trShareDeliveryTracking': 'ចែករំលែកការតាមដានការដឹកជញ្ជូន',
      'trPendingFirstRide': 'រង់ចាំដំណើរដំបូង',
      'trSedan': 'ឡានសេដង់',
      'trUpTo4Pax': 'រហូតដល់ ៤ នាក់',
      'trSuvVan': 'SUV/ឡានវ៉ាន',
      'trUpTo6Pax': 'រហូតដល់ ៦ នាក់',
      'trDriverArrivingPickup': '{name} កំពុងមកដល់ទីតាំងទទួលរបស់អ្នក',
      'trDriverWaitingAt': '{name} កំពុងរង់ចាំនៅ {place}',
      'trSosSentToContacts': '🆘 បានផ្ញើ SOS ទៅទំនាក់ទំនង {n} នាក់',
      'trChatWithSupport': 'ជជែកជាមួយផ្នែកជំនួយ',
      'trPaidBySender': 'បង់ដោយអ្នកផ្ញើ',
      'trPaidByRecipient': 'បង់ដោយអ្នកទទួល',
      'trScheduleWithFare': 'កំណត់ពេល — {fare}',
      'trConfirmWithFare': 'បញ្ជាក់ — {fare}',
      'trAddedToWallet': 'បានបញ្ចូល {amount} ទៅក្នុងកាបូបរបស់អ្នក',
      'trRecipientPhoneNumber': 'លេខទូរស័ព្ទអ្នកទទួល',
      'trConfirmAndPay': 'បញ្ជាក់ និងបង់ប្រាក់',
      'trNewRideRequest': '🚗 សំណើដំណើរថ្មី',
      'trNewRequest': 'សំណើថ្មី',
      'trSubscribed': 'បានជាវ!',
      'trPlanUpgraded': 'បានដំឡើងគម្រោង!',
      'trSubscriptionCancelled': 'បានបោះបង់ការជាវ',
      'trTransferred': 'បានផ្ទេរ',
      'trSearchLocation': 'ស្វែងរកទីតាំង…',
      'trFindingAddress': 'កំពុងស្វែងរកអាសយដ្ឋាន…',
      'trMoveMapToSet': 'រំកិលផែនទីដើម្បីកំណត់ទីតាំង',
      'trConfirmLocation': 'បញ្ជាក់ទីតាំង',
      'trTapOpenGoogleMaps': 'ចុចដើម្បីបើក Google Maps',
      'trOpenInMaps': 'បើកក្នុងផែនទី',
      'trSearchAddressHint': 'ស្វែងរកអាសយដ្ឋាន ទីកន្លែង ឬសំណង់សម្គាល់…',
      'trUseMyLocation': 'ប្រើទីតាំងបច្ចុប្បន្នរបស់ខ្ញុំ',
      'trDetectedViaGps': 'រកឃើញតាម GPS',
      'trTypeToSearchPlace': 'វាយដើម្បីស្វែងរកទីកន្លែង',
      'trNoResultsFor': 'រកមិនឃើញលទ្ធផលសម្រាប់ "{q}"',
      'trMoveTheMapToSet': 'រំកិលផែនទីដើម្បីកំណត់ទីតាំង',
      'trUseThisLocation': 'ប្រើទីតាំងនេះ',
      'trPromotions': 'ប្រូម៉ូសិន',
      'trSlowConnection': 'ការតភ្ជាប់យឺតមែនទេ?',
      'trSwipeToRefresh': 'អូសចុះក្រោម ហើយលែងដើម្បីផ្ទុកឡើងវិញ',
      'trPurchases': 'ការទិញ',
      'trRentals': 'ការជួល',
      'trPaymentsCancels': 'ការទូទាត់ និងការបោះបង់',
      'trPerMinuteRateKhr': 'តម្លៃក្នុងមួយនាទី (រៀល)',
      'trCancelFeeAfterArrival': 'ថ្លៃបោះបង់ក្រោយមកដល់',
      'trWaitingFreeMinutes': 'នាទីរង់ចាំឥតគិតថ្លៃ',
      'trWaitingFeePerMinuteKhr': 'ថ្លៃរង់ចាំក្នុងមួយនាទី (រៀល)',
      'trNightSurchargePct': 'ថ្លៃបន្ថែមពេលយប់ (%)',
      'trPlatformCommissionPct': 'កម្រៃជើងសារកម្មវិធី (%)',
      'trStepOrder': 'ការបញ្ជា',
      'trStepDriverAssigned': 'បានចាត់\nអ្នកបើកបរ',
      'trStepPickedUp': 'បានទទួល',
      'trStepOnTheWay': 'កំពុង\nដឹក',
      'trStepDelivered': 'បានដឹកដល់',
      'trStepAccepted': 'បានទទួលយក',
      'trStepArrived': 'បានមកដល់',
      'trStepLoading': 'កំពុងលើក',
      'trStepInTransit': 'កំពុងដឹក',
      'trStepDone': 'រួចរាល់',
      'trGoogleCancelled': 'ការចូលដោយ Google ត្រូវបានបោះបង់',
      'trEnterEmailPassword': 'សូមបញ្ចូលអ៊ីមែល និងពាក្យសម្ងាត់របស់អ្នក',
      'trCannotReachServer': 'មិនអាចភ្ជាប់ទៅម៉ាស៊ីនមេបានទេ',
      'trEnterYourPhone': 'សូមបញ្ចូលលេខទូរស័ព្ទរបស់អ្នក',
      'trDevModeCode': 'របៀបសាកល្បង — មិនបានផ្ញើ SMS ពិតទេ លេខកូដរបស់អ្នកគឺ {code}',
      'trActiveCount': 'សកម្ម ({n})',
      'trCompletedCount': 'បានបញ្ចប់ ({n})',
      'trTitleRequired': 'ត្រូវការចំណងជើង',
      'trZoneNameRequired': 'ត្រូវការឈ្មោះតំបន់',
      'trDeletePromoCodeQ': 'លុបលេខកូដប្រូម៉ូសិន "{code}"?',
      'trBaseFareLower': 'ថ្លៃមូលដ្ឋាន',
      'trTimeMin': 'រយៈពេល ({n} នាទី)',
      'trNoFee': 'គ្មានថ្លៃសេវា',
      'trInstant': 'ភ្លាមៗ',
      'trSurgeActiveArea': 'តម្លៃកើន {x}× កំពុងអនុវត្តក្នុងតំបន់របស់អ្នក',
      'trSurgeHighDemand': 'តម្លៃកើន {x}× — តម្រូវការខ្ពស់ក្នុងតំបន់របស់អ្នក',
      'trNoListingMatchesFilter': 'គ្មានទំនិញត្រូវនឹងតម្រងនេះទេ — កំពុងបង្ហាញជម្រើសដើមរបស់អ្នក',
      'trPaymentSuccessful': '✅ ការទូទាត់បានជោគជ័យ',
      'trPaidVia': 'បានបង់ {amount} តាម {method}',
      'trSetLocation': 'កំណត់ទីតាំង',
      'trNetworkErrorCheck': 'កំហុសបណ្តាញ — សូមពិនិត្យការតភ្ជាប់',
      'trEnableBiometric': 'បើកការចូលដោយស្នាមម្រាមដៃ/មុខ សម្រាប់ ROTEH',
      'trSignInToRoteh': 'ចូលគណនី ROTEH',
      'deleteAccountLabel': 'លុបគណនី',
      'deleteAccountTitle': 'លុបគណនីរបស់អ្នក?',
      'deleteAccountMessage': 'សកម្មភាពនេះនឹងលុបឈ្មោះ អ៊ីមែល លេខទូរស័ព្ទ ទីកន្លែងដែលបានរក្សាទុក និងទំនាក់ទំនងសង្គ្រោះបន្ទាន់របស់អ្នកជាអចិន្ត្រៃយ៍ ហើយចាកចេញពីគ្រប់ឧបករណ៍។ ប្រវត្តិដំណើរ និងការទូទាត់ត្រូវបានរក្សាទុកសម្រាប់គណនេយ្យ ប៉ុន្តែលែងភ្ជាប់នឹងអ្នកទៀតហើយ។ មិនអាចត្រឡប់វិញបានទេ។',
      'deleteAccountConfirm': 'លុបជាអចិន្ត្រៃយ៍',
      'deleteAccountDone': 'គណនីរបស់អ្នកត្រូវបានលុបហើយ។',
      'trCouldNotCompleteTrip': 'មិនអាចបញ្ចប់ដំណើរបានទេ — សូមពិនិត្យអ៊ីនធឺណិត ហើយព្យាយាមម្តងទៀត។',
      'trSurchargesLine': 'ថ្លៃបន្ថែម និងថ្លៃអប្បបរមា',
      'trMeterSoFar': 'ចម្ងាយរហូតមកដល់ពេលនេះ',
      'pkExportReport': 'នាំចេញរបាយការណ៍',
      'pkExportPdf': 'PDF',
      'pkExportPdfSub': 'សង្ខេប ក្រាហ្វ និងបញ្ជីកញ្ចប់ — ងាយបោះពុម្ព ឬផ្ញើ',
      'pkExportExcel': 'Excel',
      'pkExportExcelSub': 'កញ្ចប់ទាំងអស់ រួមទាំងឈ្មោះ និងអាសយដ្ឋានអ្នកទទួល',
      'pkStatusCompleted': 'បានបញ្ចប់',
      'pkStatusFailed': 'មិនបានដឹកដល់',
      'pkStatusReturned': 'បានប្រគល់ត្រឡប់មកហាង',
      'pkReasonCannotContact': 'មិនអាចទាក់ទងអ្នកទទួល',
      'pkReasonRefused': 'អ្នកទទួលបដិសេធ',
      'pkReasonWrongAddress': 'អាសយដ្ឋានខុស',
      'pkReasonPostponed': 'អ្នកទទួលស្នើឲ្យដឹកពេលក្រោយ',
      'pkReasonOther': 'មូលហេតុផ្សេងៗ',
      'pkReturningToShop': 'អ្នកបើកបរកំពុងយកត្រឡប់មកហាងរបស់អ្នក',
      'pkReports': 'របាយការណ៍',
      'pkReportsSub': 'ប្រចាំថ្ងៃ សប្តាហ៍ និងខែ',
      'pkDay': 'ថ្ងៃ',
      'pkWeek': 'សប្តាហ៍',
      'pkMonth': 'ខែ',
      'pkTotalPackages': 'កញ្ចប់សរុប',
      'pkSuccessRate': 'អត្រាជោគជ័យ',
      'pkInProgress': 'កំពុងដំណើរការ',
      'pkDeliveryFees': 'ថ្លៃដឹកសរុប',
      'pkCodCollected': 'COD បានប្រមូល',
      'pkAvgTime': 'រយៈពេលដឹកជាមធ្យម',
      'pkMinutes': '{n} នាទី',
      'pkFailureReasons': 'មូលហេតុដែលកញ្ចប់មិនបានដឹកដល់',
      'pkNoData': 'គ្មានកញ្ចប់ក្នុងរយៈពេលនេះ',
      'pkToday': 'ថ្ងៃនេះ',
      'pkThisWeek': 'សប្តាហ៍នេះ',
      'pkThisMonth': 'ខែនេះ',
      'pkByHour': 'កញ្ចប់តាមម៉ោង',
      'pkByDay': 'កញ្ចប់តាមថ្ងៃ',
      'pkTodaySummary': 'ថ្ងៃនេះ៖ បានបញ្ចប់ {done} · ប្រគល់វិញ {back} · កំពុងដំណើរការ {open}',
      'drvCantDeliver': 'មិនអាចដឹកដល់',
      'drvCantDeliverTitle': 'ហេតុអ្វីមិនអាចដឹកដល់?',
      'drvFailNote': 'កំណត់សម្គាល់ (ស្រេចចិត្ត)',
      'drvReportFail': 'រាយការណ៍ ហើយយកត្រឡប់ទៅហាង',
      'drvReturningTitle': 'យកកញ្ចប់ត្រឡប់ទៅហាងវិញ',
      'drvReturnedToShop': 'បានប្រគល់ទៅហាងវិញ',
      'drvDeliveredAfterAll': 'អ្នកទទួលឆ្លើយហើយ — ដឹកដល់',
      'drvReturnDone': 'បានប្រគល់កញ្ចប់ទៅហាងវិញ',
      'pkPartnerServices': 'សេវាដៃគូ',
      'pkCreatePackage': 'បង្កើតកញ្ចប់',
      'pkCreatePackageSub': 'ROTEH មកយក និងដឹកជូន',
      'pkMyPackages': 'កញ្ចប់របស់ខ្ញុំ',
      'pkMyPackagesSub': 'មើលកញ្ចប់ទាំងអស់',
      'pkTrackPackage': 'តាមដានកញ្ចប់',
      'pkTrackPackageSub': 'តាមដានការដឹកជញ្ជូន',
      'pkHistory': 'ប្រវត្តិផ្ញើកញ្ចប់',
      'pkHistorySub': 'បានដឹកដល់ និងបានបោះបង់',
      'pkActiveCount': '{n} កំពុងដឹក',
      'pkTodayCount': 'ថ្ងៃនេះ {n}',
      'pkCodPending': 'COD ត្រូវប្រមូល',
      'pkBecomePartner': 'ក្លាយជាដៃគូ ROTEH',
      'pkBecomePartnerSub': 'ផ្ញើកញ្ចប់ — ROTEH មកយក និងដឹកជូនអតិថិជនរបស់អ្នក',
      'pkPartnerAccount': 'ដៃគូ ROTEH',
      'pkPendingTitle': 'កំពុងពិនិត្យការចុះឈ្មោះ',
      'pkPendingBody': 'ROTEH កំពុងពិនិត្យការចុះឈ្មោះដៃគូរបស់អ្នក។ អ្នកនឹងទទួលបានការជូនដំណឹងនៅពេលត្រូវបានអនុម័ត។',
      'pkRejectedTitle': 'ការចុះឈ្មោះមិនត្រូវបានអនុម័ត',
      'pkSuspendedTitle': 'គណនីដៃគូត្រូវបានផ្អាក',
      'pkSuspendedBody': 'សូមទាក់ទងផ្នែកជំនួយ ROTEH។',
      'pkResubmit': 'កែប្រែ និងដាក់ស្នើម្តងទៀត',
      'pkRegisterTitle': 'ចុះឈ្មោះជាដៃគូ',
      'pkRegisterIntro': 'ប្រើគណនីដដែលនេះ។ បន្ទាប់ពី ROTEH អនុម័ត អ្នកអាចបង្កើត និងតាមដានកញ្ចប់នៅទីនេះ — ហើយនៅតែកក់ដំណើរបានដូចធម្មតា។',
      'pkBusinessName': 'ឈ្មោះហាង / អាជីវកម្ម',
      'pkBusinessType': 'ប្រភេទអាជីវកម្ម',
      'pkContactName': 'អ្នកទំនាក់ទំនង (ស្រេចចិត្ត)',
      'pkBusinessPhone': 'លេខទូរស័ព្ទអាជីវកម្ម',
      'pkPickupAddress': 'ទីតាំងយកកញ្ចប់ជាប្រចាំ',
      'pkSubmit': 'ដាក់ស្នើការចុះឈ្មោះ',
      'pkRequired': 'សូមបំពេញព័ត៌មាននេះ',
      'pkTypeOnlineShop': 'ហាងអនឡាញ',
      'pkTypeRetail': 'ហាងលក់រាយ',
      'pkTypeRestaurant': 'ភោជនីយដ្ឋាន / ម្ហូប',
      'pkTypeOther': 'ផ្សេងៗ',
      'pkSender': 'អ្នកផ្ញើ',
      'pkReceiver': 'អ្នកទទួល',
      'pkName': 'ឈ្មោះ',
      'pkPhone': 'លេខទូរស័ព្ទ',
      'pkPickupLocation': 'ទីតាំងមកយក',
      'pkDeliveryLocation': 'ទីតាំងដឹកជូន',
      'pkChooseOnMap': 'ចុចដើម្បីជ្រើសលើផែនទី',
      'pkPackage': 'កញ្ចប់',
      'pkPackageType': 'ប្រភេទកញ្ចប់',
      'pkDescription': 'ការពិពណ៌នា (មានអ្វីខាងក្នុង)',
      'pkWeight': 'ទម្ងន់ (គីឡូ, ស្រេចចិត្ត)',
      'pkSize': 'ទំហំ',
      'pkPhoto': 'រូបភាពកញ្ចប់ (ស្រេចចិត្ត)',
      'pkAddPhoto': 'បន្ថែមរូបភាព',
      'pkCamera': 'កាមេរ៉ា',
      'pkGallery': 'វិចិត្រសាល',
      'pkService': 'ល្បឿនដឹកជញ្ជូន',
      'pkNormal': 'ធម្មតា',
      'pkExpress': 'រហ័ស',
      'pkPayment': 'ការទូទាត់',
      'pkWhoPays': 'នរណាបង់ថ្លៃដឹក?',
      'pkPartnerPays': 'ខ្ញុំបង់',
      'pkReceiverPays': 'អ្នកទទួលបង់ (សាច់ប្រាក់)',
      'pkCodAmount': 'ប្រមូលពីអ្នកទទួល — តម្លៃទំនិញ (៛)',
      'pkCodHint': 'ទុកទទេ បើគ្មានប្រាក់ត្រូវប្រមូល',
      'pkReference': 'លេខកម្ម៉ង់របស់អ្នក (ស្រេចចិត្ត)',
      'pkNotes': 'កំណត់សម្គាល់ជូនអ្នកបើកបរ (ស្រេចចិត្ត)',
      'pkDeliveryFee': 'ថ្លៃដឹកជញ្ជូន',
      'pkSubmitPackage': 'បង្កើតកញ្ចប់',
      'pkChooseLocations': 'សូមជ្រើសទីតាំងមកយក និងដឹកជូនលើផែនទី',
      'pkCreatedTitle': 'បានបង្កើតកញ្ចប់',
      'pkCreatedBody': '{code} កំពុងរង់ចាំ ROTEH បញ្ជាក់។ យើងនឹងជូនដំណឹងនៅពេលអ្នកបើកបរកំពុងមក។',
      'pkStatusPending': 'កំពុងរង់ចាំ',
      'pkStatusConfirmed': 'បានបញ្ជាក់',
      'pkStatusDriverAssigned': 'មានអ្នកបើកបរ',
      'pkStatusPickedUp': 'បានមកយក',
      'pkStatusInTransit': 'កំពុងដឹក',
      'pkStatusDelivered': 'បានដឹកដល់',
      'pkStatusCancelled': 'បានបោះបង់',
      'pkTabActive': 'កំពុងដឹក',
      'pkTabHistory': 'ប្រវត្តិ',
      'pkTabAll': 'ទាំងអស់',
      'pkSearchHint': 'ស្វែងរកលេខកូដ អ្នកទទួល ឬលេខទូរស័ព្ទ',
      'pkEmptyActive': 'គ្មានកញ្ចប់កំពុងដឹក',
      'pkEmptyHistory': 'មិនទាន់មានកញ្ចប់បានដឹក ឬបោះបង់',
      'pkEmptyAll': 'មិនទាន់មានកញ្ចប់',
      'pkDetailTitle': 'ព័ត៌មានកញ្ចប់',
      'pkTimeline': 'ការតាមដាន',
      'pkDriver': 'អ្នកបើកបរ',
      'pkCall': 'ហៅ',
      'pkLiveMap': 'ផែនទីផ្ទាល់',
      'pkShareLink': 'ចែករំលែកតំណតាមដាន',
      'pkShareText': 'តាមដានកញ្ចប់ ROTEH {code} របស់អ្នក៖ {url}',
      'pkCancelPackage': 'បោះបង់កញ្ចប់',
      'pkCancelConfirm': 'បោះបង់កញ្ចប់នេះ? មិនអាចត្រឡប់វិញបានទេ។',
      'pkCancelReason': 'មូលហេតុ (ស្រេចចិត្ត)',
      'pkKeep': 'ទុក',
      'pkQrTitle': 'QR កញ្ចប់',
      'pkQrHint': 'បិទលើកញ្ចប់ — អ្នកបើកបរស្កេននៅពេលមកយក និងពេលដឹកដល់។',
      'pkProofPhoto': 'ភស្តុតាងដឹកដល់',
      'pkWaitingConfirm': 'កំពុងរង់ចាំ ROTEH បញ្ជាក់',
      'pkFindingDriver': 'ROTEH កំពុងស្វែងរកអ្នកបើកបរ',
      'pkPaymentByReceiver': 'អ្នកទទួលបង់',
      'pkPaymentByPartner': 'អ្នកបង់',
      'pkCod': 'COD',
      'pkSizeSmall': 'តូច',
      'pkSizeMedium': 'មធ្យម',
      'pkSizeLarge': 'ធំ',
      'pkSizeXL': 'ធំខ្លាំង',
      'pkTypeDocument': 'ឯកសារ',
      'pkTypeParcel': 'កញ្ចប់ទូទៅ',
      'pkTypeFood': 'អាហារ',
      'pkTypeClothing': 'សម្លៀកបំពាក់',
      'pkTypeElectronics': 'គ្រឿងអេឡិចត្រូនិក',
      'pkTypeFragile': 'ងាយបែក',
      'pkPayMethod': 'បង់តាម',
      'pkPayCash': 'សាច់ប្រាក់ឲ្យអ្នកបើកបរ',
      'pkPayWallet': 'ROTEH Pay',
      'pkPayAba': 'ABA / KHQR',
      'pkCreated': 'បានបង្កើត',
      'paywayOrderPaidBody': 'បានទទួលការបង់ប្រាក់ {amount} របស់អ្នក។ សូមអរគុណ!',
      'paywayNotAvailable': 'ការបង់ប្រាក់តាម ABA មិនទាន់អាចប្រើបានទេ។ អ្នកអាចបង់ពេលក្រោយពីការកម្ម៉ង់នេះ។',
      'paywayPayNow': 'បង់ប្រាក់តាម ABA / KHQR',
      'paywayUnpaid': 'មិនទាន់បង់ប្រាក់',
      'paywayPaidLabel': 'បានបង់ប្រាក់',
      'paywayTitle': 'បង់ប្រាក់តាម ABA / KHQR',
      'paywayScanHint': 'ស្កេនជាមួយ ABA Mobile, ACLEDA ឬកម្មវិធីធនាគារ KHQR ណាមួយ។',
      'paywayWaiting': 'កំពុងរង់ចាំការបង់ប្រាក់',
      'paywayExpired': 'QR នេះផុតកំណត់ហើយ។ សូមព្យាយាមម្តងទៀត។',
      'paywayFailed': 'ការបង់ប្រាក់មិនបានជោគជ័យទេ។',
      'paywayOpenAba': 'បើក ABA Mobile',
      'paywayIPaid': 'ខ្ញុំបានបង់រួចហើយ — ពិនិត្យឥឡូវនេះ',
      'paywayRef': 'លេខយោង',
      'paywayPaidTitle': 'បានទទួលការបង់ប្រាក់',
      'paywayPaidBody': 'បានបញ្ចូល {amount} ទៅក្នុងកាបូប ROTEH Pay របស់អ្នក។',
      'helmetConfidence': 'ភាពជាក់លាក់៖ {value}',
      'helmetCheckFailed': 'មិនអាចពិនិត្យរូបថតបានទេ។ សូមព្យាយាមម្តងទៀត។',
      'txStatusPending': 'កំពុងរង់ចាំ',
      'txStatusProcessing': 'កំពុងដំណើរការ',
      'txStatusFailed': 'បរាជ័យ',
      'txStatusRejected': 'បានបដិសេធ',
      'txFilterIncome': 'ចំណូល',
      'txFilterDeductions': 'ការដក',
      'txNoneForFilter': 'មិនទាន់មានប្រតិបត្តិការនៅឡើយ។',
      'txWithdrawalPending': 'ដកប្រាក់ (កំពុងរង់ចាំអនុម័ត)',
      'txWithdrawal': 'ដកប្រាក់',
      'txWithdrawalReturned': 'ការដកប្រាក់ត្រូវបានបដិសេធ — បានប្រគល់ប្រាក់វិញ',
      'txTransferIn': 'បានទទួលប្រាក់',
      'txTransferOut': 'បានផ្ញើប្រាក់',
      'txTipIn': 'បានទទួលប្រាក់ទឹកតែ',
      'txTipOut': 'ប្រាក់ទឹកតែ',
      'txSalary': 'ប្រាក់ខែ',
      'txDeliveryPayment': 'ការទូទាត់ការដឹកជញ្ជូន',
      'txCancellationFee': 'ថ្លៃលុបចោល',
      'txAdminCredit': 'ប្រាក់បញ្ចូលពីក្រុមការងារ',
      'txReferralReward': 'រង្វាន់ណែនាំមិត្ត',
      'txCompanyShare': 'ចំណែកក្រុមហ៊ុន',
      'txLoyaltyRedemption': 'ប្តូរពិន្ទុ',
      'topUpPendingTitle': 'កំពុងរង់ចាំការអនុម័តបញ្ចូលប្រាក់',
      'topUpPendingStatus': 'កំពុងរង់ចាំអនុម័ត',
      'topUpPendingBlocked': 'អ្នកមានសំណើបញ្ចូលប្រាក់កំពុងរង់ចាំការអនុម័តរួចហើយ។ សូមរង់ចាំរហូតដល់ត្រូវបានអនុម័ត។',
      'bankTransfer': 'ផ្ទេរតាមធនាគារ',
      'drvLowBalanceOfflineTitle': 'បានដកប្រាក់ចេញ — អ្នកត្រូវបានបិទអនឡាញ',
      'drvLowBalanceOfflineMsg': 'កាបូបរបស់អ្នកនៅសល់ {balance} តិចជាង {min} ដែលត្រូវការដើម្បីបើកអនឡាញ និងទទួលការដឹក។ សូមបញ្ចូលប្រាក់ក្នុងកាបូប ដើម្បីធ្វើការបានវិញ។',
      'drvTripCancelledTitle': 'ដំណើរត្រូវបានលុបចោល',
      'drvRequestNoLongerAvailable': 'ការស្នើនេះលែងមានទៀតហើយ — ត្រូវបានលុបចោល ឬអ្នកបើកបរផ្សេងបានទទួល។',
      'drvSenderCancelledDelivery': 'អតិថិជនបានលុបចោលការកម្ម៉ង់ដឹកជញ្ជូននេះ។',
      'trCancelledStatus': 'បានលុបចោល',
      'trDeliveryCancelledTitle': 'ការដឹកជញ្ជូនត្រូវបានលុបចោល',
      'trMovingCancelledTitle': 'ការដឹកជញ្ជូនផ្លាស់ប្តូរត្រូវបានលុបចោល',
      'trCancelledByDriver': 'អ្នកបើកបរបានលុបចោលការកម្ម៉ង់នេះ។',
      'trCancelledByAdmin': 'ក្រុមការងារជំនួយបានលុបចោលការកម្ម៉ង់នេះ។',
      'trCancelledByYou': 'អ្នកបានលុបចោលការកម្ម៉ង់នេះ។',
      'trCancelledGeneric': 'ការកម្ម៉ង់នេះត្រូវបានលុបចោល។',
      'trCancelReason': 'មូលហេតុ៖ {reason}',
      'trGoBack': 'ត្រឡប់ក្រោយ',
      'drvGreeting': 'ជំរាបសួរ {name}!',
      'drvFindingRides': 'ស្វែងរកដំណើរថ្មី…',
      'drvTodayStats': 'ស្ថិតិថ្ងៃនេះ',
      'drvTodayEarnings': 'ចំណូលថ្ងៃនេះ',
      'drvWalletBalance': 'សមតុល្យកាបូប',
      'drvAcceptRides': 'ទទួលដំណើរ',
      'drvRideSub': 'អ្នកដំណើរ',
      'drvDeliverySub': 'អីវ៉ាន់',
      'drvRentalSub': 'ជួលយានយន្ត',
      'drvNoRecentTrips': 'មិនទាន់មានដំណើរនៅឡើយ — បើកទទួលដំណើរដើម្បីរកចំណូល។',
      'drvHelp': 'ជំនួយ',
      'trRecipientLine2': 'អ្នកទទួល៖ {name}',
      'trForName': 'សម្រាប់៖ {name}',
      'trClassicTukTuk': 'កង់បីធម្មតា',
      'trStdPremiumVan': 'ធម្មតា ពិសេស និងវ៉ាន',
      'goodAfternoon': 'ទិវាសួស្តី,',
      'goodEvening': 'សាយណ្ហសួស្តី,',
      'busy': 'រវល់',
      'full': 'ពេញ',
      'chooseRide': 'ជ្រើសរើសការធ្វើដំណើររបស់អ្នក',
      'promoCode': 'លេខកូដបញ្ចុះតម្លៃ',
      'scheduleDelivery': 'កំណត់ពេលដឹក',
      'packageDetails': 'ព័ត៌មានលំអិតអំពីកញ្ចប់',
      'packageSize': 'ទំហំកញ្ចប់',
      'sendAnything': 'ផ្ញើទៅណាក៏បាន!',
      'avgDelivery': 'ការដឹកជញ្ជូនជាមធ្យម: ២៥ នាទី',
      'incomingRequest': 'ការស្នើសុំចូល',
      'acceptRide': 'ទទួលដឹក',
      'decline': 'បដិសេធ',
      'todayPerformance': 'ការដឹកថ្ងៃនេះ',
      'recentTripsDriver': 'ដំណើរថ្មីៗ',
      'dailyBreakdown': 'ការបែងចែកប្រចាំថ្ងៃ',
      'withdrawEarnings': 'ដោះដូរប្រាក់ចំណូល',
      'evCarsAvailable': 'យានជំនិះអគ្គិសនី\nមានឥលូវ!',
      'evCarsSubtitle': 'ជួល ឬ ទិញយានជំនិះអគ្គិសនី នៅជិតអ្នក',
      'explore': 'ស្វែងរកយានជំនិះ',
      'completed': 'បានជោគជ័យ',
      'eta': 'ពេលវេលាប៉ាន់ស្មាន',
      'min': 'នាទី',
      'km': 'គ.ម',
      'activeRideInProgress': 'កំពុងបន្តដឹកអ្នកដំណើរ',
      'noRecentTrips': 'មិនទាន់មានដំណើរថ្មីៗទេ',
      'searchProductsHint': 'ស្វែងរកទំនិញ…',
      'filter': 'តម្រង',
      'listingsAvailable': 'បញ្ជីទំនិញដែលមាន',
      'findBestDeal': 'ស្វែងរកតម្លៃល្អបំផុត',
      'browseAll': 'បង្ហាញទាំងអស់',
      'rentalVehicle': 'យានជំនិះជួល',
      'tryAgain': 'ព្យាយាមម្តងទៀត',
      'results': 'លទ្ធផល',
      'noListingsFound': 'រកមិនឃើញទំនិញទេ',
      'tryDifferentFilters': 'សូមសាកល្បងតម្រងផ្សេង',
      'salePrice': 'តម្លៃលក់',
      'rentPerDay': 'តម្លៃជួល / ថ្ងៃ',
      'qty': 'ចំនួន',
      'verifiedSeller': 'អ្នកលក់ដែលបានផ្ទៀងផ្ទាត់',
      'editListing': 'កែសម្រួលការផ្សាយ',
      'fillRequiredFields': 'សូមបំពេញព័ត៌មានទាំងអស់ដែលជាតម្រូវការ',
      'shopAsGuest': 'ទិញជាភ្ញៀវ',
      'continueAsGuest': 'បន្តជាភ្ញៀវ',
      'welcomeBack': "សូមស្វាគមន៍ការត្រឡប់មកវិញ",
      'signInSubtitle': "ចូលគណនីដើម្បីគ្រប់គ្រងការបញ្ជាទិញ ការធ្វើដំណើរ និងការដឹកជញ្ជូនរបស់អ្នក",
      'noAccountYet': "មិនទាន់មានគណនី?",
      'signInWithBiometrics': "ចូលដោយប្រើស្នាមម្រាមដៃ",
      'signInAs': "ចូលជា",
      'secureSignInNote': "ព័ត៌មានរបស់អ្នកត្រូវបានអ៊ិនគ្រីប និងរក្សាសុវត្ថិភាព",
      'welcomeTagline': 'ទិញ  •  ជួល  •  ដឹកជញ្ជូន  •  ផ្លាស់ទី',
      'welcomeTitle': 'សូមស្វាគមន៍មកកាន់ \nROTEH APP',
      'welcomeSubtitle': 'ទិញ ឬជួលផលិតផល ដឹកដល់ផ្ទះ — មិនចាំបាច់មានគណនី',
      'orContinueWith': 'ឬបន្តជាមួយ',
      'continueWithPhone': 'បន្តជាមួយលេខទូរស័ព្ទ',
      'continueWithGoogle': 'បន្តជាមួយ Google',
      'secureCheckoutNote': 'ការទូទាត់មានសុវត្ថិភាព  •  ផ្ទៀងផ្ទាត់លេខទូរស័ព្ទពេលបញ្ជាទិញ',
      'continueAsGuestSub': 'ទិញ ឬជួលផលិតផលដោយមិនចាំបាច់មានគណនី',
      'guestShoppingNotice': 'អ្នកកំពុងទិញជាភ្ញៀវ — ការបញ្ជាទិញត្រូវបានរក្សាទុកនៅលើទូរស័ព្ទនេះ',
      'orderPlaced': 'បញ្ជាទិញជោគជ័យ!',
      'purchaseRequestSent': 'សំណើទិញរបស់អ្នកត្រូវបានបញ្ជូន',
      'done': 'រួចរាល់',
      'purchaseProduct': 'ទិញផលិតផល',
      'couponCode': 'កូដបញ្ចុះតម្លៃ',
      'phoneNumber': 'លេខទូរស័ព្ទ',
      'confirmInformation': 'បញ្ជាក់ព័ត៌មាន',
      'verifyAddressesNote': 'សូមផ្ទៀងផ្ទាត់អាសយដ្ឋាន និងព័ត៌មានទំនាក់ទំនងទាំងអស់មុននឹង'
          'បន្ត អ្នកលក់នឹងទទួលបានការជូនដំណឹងនៅពេលការបញ្ជាទិញរបស់អ្នកបានបញ្ជូន',
      'purchaseNow': 'ទិញឥលូវនេះ',
      'findingAddress': 'កំពុងស្វែងរកអាសយដ្ឋាន…',
      'locationType': 'ប្រភេទទីតាំង',
      'rentalDuration': 'រយៈពេលជួល',
      'orderPlacedSuccess': 'បញ្ជាទិញជោគជ័យ!',
      'paymentMethod': 'វិធីបង់ប្រាក់',
      'startDate': 'ថ្ងៃចាប់ផ្តើម',
      'endDateAuto': 'ថ្ងៃបញ្ចប់ (ស្វ័យប្រវត្តិ)',
      'selectStartDate': 'ជ្រើសរើសថ្ងៃចាប់ផ្តើម',
      'discountApplied': 'បញ្ចុះតម្លៃត្រូវបានអនុវត្ត',
      'apply': 'អនុវត្ត',
      'total': 'សរុប',
      'deleteListing': 'លុបការផ្សាយនេះ?',
      'willBePermanentlyRemoved': 'នឹងត្រូវលុបជាអចិន្ត្រៃយ៍',
      'cancel': 'បោះបង់',
      'delete': 'លុប',
      'postAListing': 'ផ្សាយលក់',
      'noOrdersYet': 'មិនទាន់មានការបញ្ជាទិញទេ',
      'order': 'ការបញ្ជាទិញ',
      'left': 'នៅសល់',
      'savedPlaces': 'ទីតាំងដែលបានរក្សាទុក',
      'noSavedPlacesYet': 'មិនមានទីតាំងដែលបានរក្សាទុកទេ',
      'promoCodeTitle': 'កូដបញ្ចុះតម្លៃ',
      'browseVouchers': 'មើលប័ណ្ណបញ្ចុះតម្លៃ →',
      'cambodia': 'កម្ពុជា',
      'mapLabel': 'ផែនទី',
      'noResultsFound': 'រកមិនឃើញលទ្ធផលទេ',
      'addAStop': 'បន្ថែមទីតាំងទៅដល់',
      'whereTo': 'ទៅណា?',
      'now': 'ឥលូវនេះ',
      'confirmBooking': 'បញ្ជាក់ការកក់',
      'noDestinationNeeded': 'មិនចាំបាច់មានទីតាំង — សូមប្រាប់អ្នកបើកបរដោយផ្ទាល់',
      'whereToTitle': 'ទៅណា?',
      'noSavedPlaces': 'គ្មានទីតាំងដែលបានរក្សាទុក',
      'confirmDestination': 'បញ្ជាក់ទីតាំងទៅ',
      'whereToOptional': 'អ្នកចង់ទៅណា? (សូមបញ្ជាក់ទីតាំងទៅកាន់អ្នកបើកបរ)',
      'chooseRideTitle': 'ជ្រើសរើសយានជំនិះ',
      'scrollUpForMore': 'អូសទៅលើដើម្បីឃើញជម្រើសយានជំនិះបន្ថែម',
      'discountSuffix': 'បញ្ចុះតម្លៃ',
      'noDestinationSelected': 'មិនទាន់បានជ្រើសរើសទីតាំងទេ',
      'selectDestination': 'ជ្រើសរើសទីតាំង',
      'deliveryAndMoving': 'ដឹកជញ្ជូន និងដឹកឥវ៉ាន់រើផ្ទះឬការិយាល័យ',
      'moveWithEase': 'រើដោយងាយស្រួល\nយើងខ្ញុំរៀបចំជូនអ្នក!',
      'professionalMovingService': 'សេវាកម្មរើផ្ទះជាមួយអ្នកជំនាញ',
      'scheduleMovingDate': 'កំណត់ថ្ងៃដឹកជញ្ជូន',
      'selectLocationsForFare': 'ជ្រើសរើសទីតាំងទទួល និងទីតាំងទៅដល់ដើម្បីឃើញតម្លៃប៉ាន់ស្មាន',
      'calculatingFare': 'កំពុងគណនាតម្លៃ…',
      'yes': 'បាទ/ចាស',
      'no': 'ទេ',
      'helpersNeeded': 'ត្រូវការជំនួយ',
      'personsForCarrying': '១–៤ នាក់សម្រាប់លីកឥវ៉ាន់',
      'fareEstimate': 'តម្លៃប៉ាន់ស្មាន',
      'totalEstimate': 'តម្លៃសរុបប៉ាន់ស្មាន',
      'finalPriceConfirmed': 'តម្លៃចុងក្រោយនឹងបញ្ជាក់បន្ទាប់ពីកក់',
      'change': 'ប្តូរ',
      'confirmLocation': 'បញ្ជាក់ទីតាំង',
      'confirmDeliveryBooking': 'បញ្ជាក់ការកក់ដឹកជញ្ជូន',
      'noCancel': 'ទេ, បោះបង់',
      'yesSendNow': 'ផ្ញើឥលូវនេះ',
      'confirmMovingBooking': 'បញ្ជាក់ការកក់ដឹកជញ្ជូនរើផ្ទះ',
      'estimatedFare': 'តម្លៃប៉ាន់ស្មាន',
      'yesBookNow': 'កក់ឥលូវនេះ',
      'couldNotFetchEstimate': 'មិនអាចទាញយកតម្លៃប៉ាន់ស្មានបានទេ',
      'rideCancelled': 'ដំណើរត្រូវបានបោះបង់',
      'ok': 'យល់ព្រម',
      'stop': 'ចំណតឈប់',
      'dropoff': 'ទីតាំងទៅ',
      'safetyCentre': 'មជ្ឈមណ្ឌលសុវត្ថិភាព',
      'fare': 'តម្លៃ',
      'sendSOSQuestion': '🆘 ផ្ញើសញ្ញា SOS?',
      'sendSOS': 'ផ្ញើ SOS',
      'sosFailed': 'ការផ្ញើ SOS បរាជ័យ',
      'driverPhoneNotAvailable': 'លេខទូរស័ព្ទអ្នកបើកបរមិនទាន់មានទេ',
      'cannotDialPrefix': 'មិនអាចហៅលេខ',
      'onThisDevice': 'នៅលើឧបករណ៍នេះ',
      'couldNotGenerateShareLink': 'មិនអាចបង្កើតតំណចែករំលែកបានទេ',
      'linkCopied': 'តំណបានចម្លង',
      'shareTrip': 'ចែករំលែកដំណើរ',
      'friendsCanTrack': 'មិត្តភ័ក្តិ និងគ្រួសារអាចតាមដានដំណើររបស់អ្នកបានផ្ទាល់',
      'driverLabel': 'អ្នកបើកបរ',
      'copyLink': 'ចម្លងតំណ',
      'shareVia': 'ចែករំលែកតាមរយៈ...',
      'stopSharingLocation': 'បញ្ឈប់ការចែករំលែកទីតាំង',
      'cancelRide': 'បោះបង់ដំណើរ',
      'keepRide': 'បន្តដំណើរ',
      'businessAccount': 'គណនីអាជីវកម្ម',
      'noBusinessAccount': 'គ្មានគណនីអាជីវកម្មទេ',
      'registerOrJoinBusiness': 'ចុះឈ្មោះក្រុមហ៊ុនរបស់អ្នក ឬចូលរួមគណនីអាជីវកម្មដែលមានស្រាប់',
      'enterInviteCode': 'បញ្ចូលកូដអញ្ជើញដែលអ្នកគ្រប់គ្រងក្រុមហ៊ុនរបស់អ្នកបានផ្ដល់ឲ្យ',
      'fillSampleData': 'បំពេញទិន្នន័យគំរូ',
      'leaveBusinessQuestion': 'ចាកចេញពីអាជីវកម្ម?',
      'loseBusinessAccess': 'អ្នកនឹងលែងអាចប្រើមុខងារអាជីវកម្ម',
      'leave': 'ចាកចេញ',
      'edit': 'កែសម្រួល',
      'active': 'សកម្ម',
      'removeMemberQuestion': 'លុបសមាជិកនេះ?',
      'remove': 'លុប',
      'noMembersYet': 'មិនទាន់មានសមាជិកទេ',
      'noBusinessTripsYet': 'មិនទាន់មានដំណើរអាជីវកម្មទេ',
      'refresh': 'Refresh',
      'retry': 'ព្យាយាមម្តងទៀត',
      'businessRegistered': 'ចុះឈ្មោះអាជីវកម្មបានជោគជ័យ!',
      'shareInviteCodeNote': 'ចែករំលែកកូដអញ្ជើញនេះជាមួយបុគ្គលិករបស់អ្នកដើម្បីពួកគេចូលរួមបាន',
      'inviteCodeCopied': 'កូដអញ្ជើញត្រូវបានចម្លង!',
      'copyCode': 'ចម្លងកូដ',
      'member': 'សមាជិក',
      'removeMemberPrefix': 'លុប',
      'thisMember': 'សមាជិកនេះ',
      'fromBusinessAccountSuffix': 'ចេញពីគណនីអាជីវកម្ម?',
      'refLabel': 'លេខយោង',
      'promotions': 'ការផ្សព្វផ្សាយ',
      'editProfile': 'កែសម្រួលប្រវត្តិរូប',
      'rotehPay': 'ROTEH Pay',
      'qrPayment': 'បង់ប្រាក់ QR',
      'promosVouchers': 'ប្រូម៉ូសិន និងប័ណ្ណបញ្ចុះតម្លៃ',
      'scheduledRides': 'ដំណើរដែលបានកំណត់ពេល',
      'subscriptionPlans': 'គម្រោងសមាជិកភាព',
      'rotehRewards': 'ROTEH Rewards',
      'referEarn': 'ណែនាំ និងទទួលរង្វាន់',
      'myRentals': 'ការជួលយានជំនិះរបស់ខ្ញុំ',
      'switchToDriverMode': 'ប្តូរទៅជាអ្នកបើកបរ',
      'settings': 'ការកំណត់',
      'missions': 'បេសកកម្ម',
      'myEarnings': 'ចំណូលរបស់ខ្ញុំ',
      'topUpWallet': 'បញ្ចូលប្រាក់ក្នុងកាបូប',
      'helmetCheck': 'ពិនិត្យមួកសុវត្ថិភាព',
      'switchToPassengerMode': 'ប្តូរទៅជាអ្នកដំណើរ',
      'darkMode': 'ម៉ូតងងឹត',
      'rideLabel': 'ដំណើរ',
      'rental': 'ជួល',
      'accepted': 'បានទទួល',
      'hoursOnline': 'ម៉ោងអនឡាញ',
      'acceptanceRate': 'អត្រាទទួលយក',
      'verified': 'បានផ្ទៀងផ្ទាត់',
      'trips': 'ដំណើរ',
      'bonuses': 'ប្រាក់រង្វាន់',
      'fees': 'កម្រៃ',
      'topUps': 'បញ្ចូលប្រាក់',
      'heavyItems': '⚠ វត្ថុធ្ងន់',
      'packing': '📦 វេចខ្ចប់',
      'management': 'ការគ្រប់គ្រង',
      'users': 'អ្នកប្រើប្រាស់',
      'drivers': 'អ្នកបើកបរ',
      'ridesAdmin': 'ដំណើរ',
      'deliveriesAdmin': 'ការដឹកជញ្ជូន',
      'withdrawalsAdmin': 'ការដោះដូរប្រាក់',
      'supportAdmin': 'ជំនួយ',
      'transactionsAdmin': 'ប្រតិបត្តិការ',
      'fareRules': 'ច្បាប់តម្លៃ',
      'surgeZones': 'ទីតាំងតម្លៃខ្ពស់',
      'pricingAdmin': 'តម្លៃ',
      'bannersAdmin': 'បដា',
      'safetyAdmin': 'សុវត្ថិភាព',
      'passengersStat': 'អ្នកដំណើរ',
      'driversTotal': 'អ្នកបើកបរសរុប',
      'onlineDrivers': 'អ្នកបើកបរអនឡាញ',
      'pendingDrivers': 'អ្នកបើកបរកំពុងរង់ចាំ',
      'ridesToday': 'ដំណើរថ្ងៃនេះ',
      'activeRides': 'ដំណើរកំពុងបន្ត',
      'deliveriesToday': 'ការដឹកជញ្ជូនថ្ងៃនេះ',
      'revenueToday': 'ចំណូលថ្ងៃនេះ',
      'revenueWeek': 'ចំណូលសប្តាហ៍នេះ',
      'growth': 'កំណើន',
      'openTickets': 'សំណើមិនទាន់ដោះដូរស្រាយ',
      'safetyIncidents': 'ករណីសុវត្ថិភាព',
      'driverApprovalsSuffix': 'ការអនុម័តឱ្យក្លាយជាអ្នកបើកបរ',
      'ticketsSuffix': 'សំណើ',
      'serviceModes': 'សេវាកម្ម',
      'overview': 'ទិដ្ឋភាពទូទៅ',
      'pendingActionsSuffix': 'សកម្មភាពកំពុងកើតឡើង',
      'clearAll': 'សម្អាតទាំងអស់',
      'size': 'ទំហំ',
      'vehicleType': 'ប្រភេទយានជំនិះ',
      'color': 'ពណ៌',
      'options': 'ជម្រើស',
      'accessories': 'គ្រឿងបន្លាស់',
      'addAccessory': 'បន្ថែមគ្រឿងបន្លាស់',
      'optional': 'មិនតម្រូវ',
      'optionalAddOns': 'គ្រឿងបន្លាស់បន្ថែមដែលអ្នកទិញអាចជ្រើសរើស',
      'nameEn': 'ឈ្មោះ (អង់គ្លេស)',
      'nameKm': 'ឈ្មោះ (ខ្មែរ, មិនតម្រូវ)',
      'priceUsd': 'តម្លៃ (ដុល្លារ \$)',
      'rentPerDayUsd': 'ថ្លៃជួល / ថ្ងៃ (ដុល្លារ \$)',
      'whatAreYouListing': 'តើអ្នកចង់ដាក់លក់អ្វី?',
      'vehicleOption': 'យានជំនិះ (កង់បី, យានជំនិះអគ្គីសនី…)',
      'accessoryOther': 'គ្រឿងបន្លាស់ / ផ្សេងៗ',
      'photos': 'រូបថត',
      'upTo5': 'រហូតដល់ ៥ សន្លឹក',
      'productInfo': 'ព័ត៌មានទំនិញ',
      'productTitle': 'ចំណងជើង',
      'describeProduct': 'ពិពណ៌នាអំពីទំនិញរបស់អ្នក…',
      'type': 'ប្រភេទ',
      'condition': 'ស្ថានភាព',
      'pricing': 'ការកំណត់តម្លៃ',
      'quantity': 'បរិមាណ',
      'areaDistrictOptional': 'តំបន់ / ខណ្ឌ (មិនតម្រូវ)',
      'status': 'ស្ថានភាព',
      'findingMatch': 'កំពុងស្វែងរកទំនិញត្រូវគ្នា…',
      'totalSummary': 'សរុបទាំងអស់',
      'addAnotherItem': 'បន្ថែមទំនិញផ្សេងទៀត',
      'addItem': 'បន្ថែមទំនិញ',
      'searchListings': 'ស្វែងរកទំនិញ…',
      'noOtherListingsFound': 'រកមិនឃើញទំនិញផ្សេងទៀតទេ',
      'pickUp': 'មកយកផ្ទាល់',
      'collectMyself': 'ខ្ញុំនឹងមកយកទំនិញដោយផ្ទាល់',
      'deliverToAddress': 'ដឹកជញ្ជូនទំនិញទៅកាន់អាសយដ្ឋានរបស់ខ្ញុំ',
      'tapToSetDelivery': 'ចុចដើម្បីកំណត់ទីតាំងដឹកជញ្ជូន',
      'paidFull': 'ទូទាត់ពេញលេញ',
      'payFullAmountNow': 'ទូទាត់ប្រាក់ពេញឥលូវនេះ',
      'book30': 'កក់ ៣០%',
      'pay30Deposit': 'បង់ប្រាក់កក់ ៣០% — នៅសល់ទូទាត់ពេលដឹកដល់',
      'cod': 'ទូទាត់ពេលទទួល (COD)',
      'cashOnDelivery': 'ទូទាត់សាច់ប្រាក់ពេលទទួលទំនិញ',
      'payWithCash': 'ទូទាត់ជាសាច់ប្រាក់',
      'inAppWalletBalance': 'សមតុល្យកាបូបក្នុងអេប',
      'abaMobileBanking': 'សេវាធនាគារតាមទូរស័ព្ទ ABA',
      'wingMobileWallet': 'កាបូបអេឡិចត្រូនិច Wing',
      'otherOnline': 'អនឡាញផ្សេងទៀត',
      'otherOnlinePayment': 'ការទូទាត់តាមប្រព័ន្ធអនឡាញផ្សេងៗ',
      'enterCouponCodeOptional': 'បញ្ចូលលេខកូដប័ណ្ណបញ្ចុះតម្លៃ (មិនតម្រូវ)',
      'enterCouponCode': 'បញ្ចូលលេខកូដប័ណ្ណបញ្ចុះតម្លៃ',
      'noListingsYet': 'មិនទាន់មានទំនិញដាក់លក់នៅឡើយទេ',
      'postSomethingToSell': 'បង្ហោះទំនិញដើម្បីចាប់ផ្តើមលក់',
      'duration': 'រយៈពេល',
      'specialInstructions': 'ចំណាំ ឬការណែនាំពិសេស…',
      'seller': 'អ្នកលក់',
      'specifications': 'លក្ខណៈបច្ចេកទេស',
      'pickupLocation': 'ទីតាំងទទួលទំនិញ',
      'all': 'ទាំងអស់',
      'category': 'ប្រភេទ',
      'location': 'ទីតាំង',
      'description': 'ការពិពណ៌នា',
      'paymentType': 'ប្រភេទការទូទាត់',
      'cash': 'សាច់ប្រាក់',
      'sender': 'អ្នកផ្ញើ',
      'recipient': 'អ្នកទទួល',
      'moving': 'ដឹកជញ្ជូន',
      'topUpRequired': 'តម្រូវឱ្យបញ្ចូលប្រាក់',
      'topUpNow': 'បញ្ចូលប្រាក់ឥលូវនេះ',
      'lookingForRideRequests': 'កំពុងស្វែងរកអ្នកធ្វើដំណើរ',
      'deliveryModeActive': 'ដំណើរការដឹកជញ្ជូន',
      'incomingRideRequest': 'មានសំណើដឹកអ្នកដំណើរចូលមក',
      'incomingDeliveryRequest': 'សំណើដឹកជញ្ជូនចូលមក',
      'incomingRentalRequest': 'សំណើជួលចូលមក',
      'acceptDelivery': 'ទទួលការដឹកជញ្ជូន',
      'acceptRental': 'ទទួលការជួល',
      'searchChargingStation': 'ស្វែងរកស្ថានីយ៍ប្តូរថ្ម, ទីតាំង...',
      'nearbyChargingStations': 'ស្ថានីយ៍ប្តូរថ្មនៅជិត',
      'noChargingStationsFound': 'មិនមានស្ថានីយ៍ប្តូរថ្មទេ',
      'createAccount': 'បង្កើតគណនី',
      'joinRoteh': 'ចូលរួមជាមួយ រទេះ',
      'fastSafeRides': 'ការធ្វើដំណើររហ័ស និងសុវត្ថិភាពនៅកម្ពុជា',
      'iWantTo': 'ខ្ញុំចង់',
      'rideAsPassenger': 'ជិះជាអ្នកដំណើរ',
      'driveAndEarn': 'បើកបរ & រកចំណូល',
      'driverType': 'ប្រភេទអ្នកបើកបរ',
      'fullName': 'ឈ្មោះពេញ',
      'email': 'អ៊ីមែល',
      'enterEmail': 'បញ្ចូលអ៊ីមែល',
      'password': 'ពាក្យសម្ងាត់',
      'enterPassword': 'បញ្ចូលពាក្យសម្ងាត់',
      'confirmPassword': 'បញ្ជាក់ពាក្យសម្ងាត់ម្តងទៀត',
      'phoneOptional': 'លេខទូរស័ព្ទ (មិនតម្រូវ)',
      'referralCodeOptional': 'លេខកូដណែនាំ (មិនតម្រូវ)',
      'alreadyHaveAccount': 'មានគណនីរួចហើយមែនទេ? ',
      'signIn': 'ចូលគណនី',
      'demoAccounts': 'គណនីសាកល្បង',
      'sendOtp': 'ផ្ញើ OTP',
      'verifyAndSignIn': 'ផ្ទៀងផ្ទាត់ & ចូលគណនី',
      'resendOtp': 'ផ្ញើ OTP ម្តងទៀត',
      'family': 'គ្រួសារ',
      'wallet': 'កាបូប',
      'rewards': 'រង្វាន់',
      'refer': 'ណែនាំ',
      
      // ── Delivery / moving summary screens ──
      'phone': 'លេខទូរស័ព្ទ',
      'package': 'កញ្ចប់ទំនិញ',
      'movingCompleted': 'ការដឹកជញ្ជូនបានជោគជ័យ!',
      'deliveryDetails': 'ព័ត៌មានលម្អិតការដឹកជញ្ជូន',
      'movingDetails': 'ព័ត៌មានលម្អិតការដឹកជញ្ជូនរើទីតាំង',
      'orderInfo': 'ព័ត៌មានការបញ្ជាទិញ',
      'jobInfo': 'ព័ត៌មានការងារ',
      'paymentSummary': 'សង្ខេបការទូទាត់',
      'movingFee': 'តម្លៃសេវារើទីតាំង',
      'paidBy': 'បង់ដោយ',
      'youRated': 'អ្នកបានផ្តល់ចំណាត់ថ្នាក់',
      'backToHome': 'ត្រឡប់ទៅទំព័រដើម',
      'backToDashboard': 'ត្រឡប់ទៅផ្ទាំងគ្រប់គ្រង',
      'updatingReceipt': 'កំពុងធ្វើបច្ចុប្បន្នភាពបង្កាន់ដៃ…',
      'updatingSummary': 'កំពុងធ្វើបច្ចុប្បន្នភាពសង្ខេប…',
      'couldNotRefresh': 'មិនអាចធ្វើបច្ចុប្បន្នភាពបាន កំពុងបង្ហាញព័ត៌មានដែលបានរក្សាទុក',
      'platformFee': 'ថ្លៃវេទិកា',
      'netDriverFee': 'សេវាអ្នកបើកបរត្រូវទទួលបាន',
      'driverFee': 'សេវាអ្នកបើកបរ',
      'beforePlatformFee': 'មុនកាត់ថ្លៃវេទិកា',
      'collectFromRecipient': 'សេវាពីអ្នកទទួល',
      'collectPackageAmount': 'តម្លៃទំនិញ',
      'packageDeliveredSuccessfully': 'ទំនិញត្រូវបានដឹកជញ្ជូនដោយជោគជ័យ',
      'movingJobDone': 'ល្អមែន — ការរើទីតាំងបានបញ្ចប់',
      'onlinePay': 'បង់តាមអនឡាញ',

      // ── Trip receipt ──
      'tripComplete': 'ដំណើរបានបញ្ចប់',
      'ride': 'ការធ្វើដំណើរ',
      'fareBreakdown': 'ថ្លៃធ្វើដំណើរ',
      'baseFare': 'តម្លៃចាប់ផ្តើម',
      'distanceFee': 'តម្លៃចម្ងាយ',
      'surgeFee': 'តម្លៃបន្ថែម',
      'promoDiscount': 'ចុះតម្លៃ',
      'tripDetails': 'ការធ្វើដំណើរលម្អិត',
      'dateAndTime': 'កាលបរិច្ឆេទ & ម៉ោង',
      'distance': 'ចម្ងាយ',
      'yourDriver': 'អ្នកបើកបរ របស់អ្នក',
      'yourRating': 'ចំណាត់ថ្នាក់ អ្នកបានដាក់ឱ្យ',
      'shareReceipt': 'ចែករំលែក បង្កាន់ដៃ',
      'tripReceipt': 'បង្កាន់ដៃការធ្វើដំណើរ',
      'minShort': 'នាទី',
      'from': 'ពី',
      'to': 'ទៅ',
      'date': 'កាលបរិច្ឆទ',
      'surge': 'បន្ថែម',
      'promo': 'ចុះថ្លៃ',
      'rotehWallet': 'ROTEH Wallet',
      // ── Payment screen ──
      'chooseHowYouWantTo': 'ជ្រើសរើសវិធីបង់ប្រាក់',
      'confirmAndPay': 'បញ្ជាក់ & បង់ប្រាក់',
      'haveAPromoCode': 'មានកូដចុះតម្លៃ?',
      'payDriverDirectly': 'បង់ប្រាក់ទៅអ្នកបើកបរ',
      'serviceFee2': 'ថ្លៃសេវា',
      'totalToPay': 'បង់ប្រាក់សរុប',
      'tripSummary': 'សង្ខេបដំណើរ',
      'wingMobileWallet2': 'Wing Mobile Wallet',
      'wingMoney': 'លុយវីង',
      'yourWalletBalance': 'ទឹកប្រាក់ក្នុងកាបូបអ្នក',
      // ── Payment screen ──
      'payingWith': 'បង់ប្រាក់តាម',
      // ── Wallet screen ──
      'amountKhrMin1000': 'ចំនួន (រៀល, តិចបំផុត 1,000)',
      'balanceUpdated': 'ចំនួនទឹកប្រាក់បានធ្វើបច្ចុប្បន្នភាព',
      'checkLater': 'ឆែកពេលក្រោយ',
      'close': 'បិទ',
      'confirmTopUp': 'បញ្ជាក់ការបញ្ចូលទឹកប្រាក់',
      'customAmountKhr': 'កំណត់ចំនួនបាន (រៀល)',
      'enterRecipientPhoneNumber': 'បញ្ចូលលេខទូរស័ព្ទអ្នកទទួល.',
      'history': 'ប្រវត្តិ',
      'loading': 'កំពុងទៅ…',
      'minimumTopUpAmountIs': 'បញ្ចូលទឹកប្រាក់ចាប់ពី 1,000 រៀល.',
      'minimumTransferAmountIs1': 'វេរទឹកប្រាក់ចាប់ពី 1,000 រៀល.',
      'noTransactionsYet': 'មិនមានប្រតិបត្តិការនៅឡើយ',
      'recentTransactions': 'ប្រតិបត្តិការថ្មីៗ',
      'reload': 'បញ្ចូលប្រាក់',
      'send': 'ផ្ញើ',
      'sendMoney': 'វេរ ទឹកប្រាក់',
      'sentSuccessfully': 'វេរ ជោគជ័យ',
      'tapToRetry': 'ចុច ដើម្បីសាកម្តងទៀត',
      'topUp': 'បញ្ចូល',
      'topUpRotehPay': 'បញ្ជូលទឹកប្រាក់ក្នុង ROTEH Pay',
      'topUpStatus': 'ស្ថានភាពបញ្ជូលទឹកប្រាក់',
      'topUpApproved': 'បញ្ជូលទឹកប្រាក់បានជោគជ័យ!',
      'topUpRejected': 'បញ្ជូលទឹកប្រាក់បរាជ័យ',
      'viewAll': 'បង្ហាញទាំងអស់',
      'waitingForAdminApproval': 'សូមរងចាំការអនុម័ត…',
      // ── passenger_home screen ──
      'n128Trips': '(128 ដំណើរ)',
      // ── delivery_tracking_screen screen ──
      'areYouSureYouWant': 'អ្នកពិតជាចង់លុបចោលការដឹកនេះ?',
      'cancelOrder': 'លុបចោលការដឹក',
      'cancelOrder2': 'លុបចោលការដឹក?',
      'chatDriver': 'សារទៅកាន់អ្នកបើកបរ',
      'completedAt2': 'បញ្ចប់នៅ (ម៉ោងបញ្ចប់): ',
      'copy': 'ចម្លង',
      'couldNotLoadDelivery': 'មិនអាចទាញទិន្នន័យ',
      'deliveryFee2': 'តម្លៃដឹកជញ្ជូន (តម្លៃសេវាដឹក): ',
      'howWasYourDeliveryExperience': 'តើការដឹកជញ្ជូនឥវ៉ាន់យ៉ាងម៉េចដែរ?',
      'keepOrder': 'បន្តការកម្មង់',
      'leaveACommentOptional': 'បញ្ចេញយោបល់ (មិនតម្រូវ)',
      'packageAmount2': 'តម្លៃកញ្ចប់ឥវ៉ាន់ (តម្លៃទំនិញ): ',
      'rateDelivery': 'ដាក់ពិន្ទុការដឹកជញ្ជូន',
      'recipientsAndFriendsCanTrack': 'អ្នកទទួល ឬមិត្តអ្នកអាចឃើញពីដំណើរកំពុងដឹកជញ្ជូនបាន',
      'service': 'សេវាកម្ម',
      'shareLink': 'ចែករំលែក លីង',
      'skip': 'រំលង',
      'stopSharingTracking': 'បញ្ឈប់ការចែករំលែកព័ត៌មានកំពុងដឹកជញ្ជូន',
      'submit': 'បញ្ជូន',
      'summary': 'សង្ខេប',
      'trackingLinkCopiedToClipboard': 'លីងត្រូវបានចម្លងរួច',
      'trackingLinkDeactivated': 'លឹងត្រូវបានបិទ',
      'viewSummary': 'បង្ហាញព័ត៌មានសង្ខេប',
      // ── trip_tracking_screen screen ──
      'anSosAlertWillBe': 'សារព្រមាន SOS នឹងត្រូវបញ្ជូនទៅកាន់លេខទំនាក់ទំនងភ្លាមៗ.',
      'call': 'ខល',
      'destination': 'ទីតាំងទៅដល់',
      'locatingYourDriver': 'កំពុងទាញយកទីតាំងអ្នកបើកបរ…',
      'driverArrived': '✅ អ្នកបើកបរបានមកដល់!',
      'driverFound': '🛺 រកបានអ្នកបើកបរហើយ!',
      'yourDriverIsAlmostHere': '🛺 អ្នកបើកបររបស់អ្នកជិតមកដល់ហើយ',
      // ── ride_booking screen ──
      'airport': 'ព្រលានយន្តហោះ',
      'chooseOnMap': 'ជ្រើសរើសទីតាំង នៅលើ ផែនទី',
      'home2': 'ទីតាំងដើម',
      'office': 'ការិយាល័យ',
      'pickupLocation2': 'ទីតាំងទៅយក',
      'recent': 'ថ្មីៗ',
      'rideRequested': 'ការដឹកបានដាក់ស្នើ!',
      'saved': 'បានរក្សាទុក',
      'searchPickupLocation': 'ស្វែងរកទីតាំងទៅយក',
      'setLocationLater': 'អាចកំណត់ទីតាំងតាមក្រោយបាន',
      'suggestions': 'ផ្តល់យោបល់',
      'eGSave10': 'ឧ. save10',
      'pickup2': '📍 ទីតាំងទៅយក',
      // ── delivery_screen screen ──
      'n1Bedroom': '1 បន្ទប់គេង',
      'n10KgAndAbove': '10 គម ឡើង',
      'n2Bedrooms': '2 បន្ទប់គេង',
      'n210Kg': '2 – 10 គម',
      'n3Bedrooms': '3+ បន្ទប់គេង',
      'baseFee': 'តម្លៃតិចបំផុត',
      'bike': 'ម៉ូតូ',
      'buildingHasAWorkingElevator': 'អគារមានជណ្តើរយន្ត',
      'car': 'ឡាន',
      'cashOnDeliveryCod': 'ដឹកហើយ យកប្រាក់ (COD)',
      'commercialOfficeMoving': 'រើទីតាំងការិយាល័យ',
      'deliveryVehicle': 'យានជំនិះដឹកជញ្ជូន',
      'dropoffFloor': 'ជាន់ត្រូវដឹកជញ្ជូនទៅ',
      'elevator': 'ជណ្តើរយន្ត',
      'express': 'រហ័ស',
      'fasterDeliveryAtHigherFee': 'ដឹកជញ្ជូនរហ័ស តែតម្លៃល្អ',
      'floorFee': 'ឈ្នួលតាមជាន់',
      'floors': 'ជាន់',
      'fridgeSofaBedWardrobe': 'ទូរទឹកកក, សាឡុង, គ្រែ, ទូរខោអាវ',
      'hasElevator': 'មានជណ្តើរយន្ត',
      'hasHeavyItems': 'មានឥវ៉ាន់ធ្ងន់ៗ',
      'helperFee': 'សេវាអ្នកជួយរើ',
      'helpers': 'អ្នកជួយរើ',
      'home3': 'ទីតាំងដើម',
      'homeMove': 'រើ ផ្ទះ',
      'informationOfMover': 'ព័ត៌មានរបស់អ្នករើ',
      'large': 'ធំ',
      'largeHomeOrVilla': 'ផ្ទះធំ ឬវីឡា',
      'largerApartment': 'ប្រភេទខុនដូធំ',
      'manualCarryUpDownStairs': 'ត្រូវការលើកឡើង លើកចុះ ដោយមនុស្ស',
      'medium': 'មធ្យម',
      'mediumApartment': 'ប្រភេទខុនដូមធ្យម',
      'moveType': 'ប្រភេទការរើ',
      'needsStairsCarry': 'ត្រូវការលើកតាមជណ្តើរ',
      'normal': 'ធម្មតា',
      'notes': 'សម្គាល់',
      'officeMove': 'រើការិយាល័យ',
      'packingService': 'សេវាវេចខ្ចប់',
      'payFromWalletBalance': 'បង់ប្រាក់តាមកាបូបអេឡិចត្រូនិច',
      'paymentBy': 'បង់ប្រាក់តាម',
      'paysUpfront': 'បង់ប្រាក់មុន',
      'pickupFloor': 'ទីតាំងជាន់ ទៅទទួល',
      'priorityMovingService': 'សេវារើ ប្រញាប់',
      'privateHome': 'ផ្ទះឯកជន',
      'propertySize': 'ទំហំ',
      'recipPh': 'លេខទូរស័ព្ទអ្នកទទួល',
      'relocateHomeOffice': 'ផ្លាស់ប្តូរទីតាំង ផ្ទះ/ការិយាល័យ',
      'residentialMoving': 'រើទីលំនៅ',
      'scheduled': 'កំណត់ពេល',
      'searchLocation': 'ស្វែងរក ទីតាំង…',
      'sendPackages': 'ផ្ញើ កញ្ចប់ឥវ៉ាន់',
      'senderPh': 'លេខទូរស័ព្ទអ្នកផ្ញើ',
      'serviceOption': 'ជម្រើសសេវាកម្ម',
      'small': 'តូច',
      'smallSpace': 'ទីតាំងតូចចង្អៀត',
      'standardDeliverySpeed': 'ស្តង់ដាល្បឿនដឹកជញ្ជូន',
      'standardMovingService': 'ស្តង់ដាសេវារើឥវ៉ាន់',
      'studio1Room': 'ស្ទូឌីយ៉ូ / 1 បន្ទប់',
      'tukTuk': 'តុកតុក',
      'upTo100KgAffordable': 'អាចបានរហូតដល់ 100 គម • តម្លៃទូទៅ',
      'upTo2Kg': 'រហូតដល់ 2 គម',
      'upTo20KgFastest': 'រហូតដល់ 20 គម • លឿនបំផុត',
      'upTo200KgComfortable': 'រហូតដល់ 200 គម • ងាយស្រួល',
      'weBoxAndWrapYour': 'យើងអាចវេចខ្ចប់ របស់របរជូនអ្នកបាន',
      'wingMobilePayment': 'ការចំណាយតាមវីង',
      'buildingInfo': '🏢 ព័ត៌មានអគារ',
      'serviceOptions': '🧍 ជម្រើសសេវាកម្ម',
      // ── Trip tracking messages ──
      'arrivingNow': 'កំពុងមកដល់',
      'cancel2000Fee': 'លុបចោល (គិតសេវា 2,000 ៛)',
      'cannotCancelARideIn': 'មិនអាចលុបចោល កំពុងធ្វើដំណើរ',
      'changedMyMind': 'ប្តូរចិត្ត',
      'driverAssignedConnecting': 'មានអ្នកបើកបរ — កំពុងភ្ជាប់...',
      'driverHasArrivedA2': 'អ្នកបើកបរបានមកដល់ — គិតសេវាចាប់ពី 2,000 ៛.',
      'driverHasArrived': 'អ្នកបើកបរបានមកដល់!',
      'driverIsTakingTooLong': 'អ្នកបើកបរយូរមិនទាន់មកដល់',
      'emergencyCameUp': 'មានការបន្ទាន់មកដល់',
      'findingDriver': 'កំពុងរកអ្នកបើកបរ...',
      'findingYourDriver': 'កំពុងរកអ្នកបើកបរសម្រាប់អ្នក...',
      'foundAnotherRide': 'រកឃើញការធ្វើដំណើរមួយទៀតហើយ',
      'iMOnMyWay': 'ខ្ញុំនៅតាមផ្លូវ!\n',
      'lookingForANearbyDriver': 'កំពុងស្វែងរកអ្នកបើកបរក្បែរនេះ…',
      'myRotehTrip': 'ការធ្វើដំណើររបស់ខ្ញុំ',
      'noDriverWasAvailableFor': 'មិនមានអ្នកបើកបរ សូមព្យាយាមម្តងទៀត',
      'other': 'ផ្សេងទៀត',
      'pleaseCheckYourBelongingsBefore': 'សូមមើលឥវ៉ាន់ឱ្យបានច្បាស់ មុនចុះពីតុកតុក',
      'pleaseTellUsWhyYou': 'សូមប្រាប់ពីមូលហេតុការលុបចោលរបស់អ្នក',
      'share': 'ចែករំលែក',
      'sharing': 'ការចែករំលែក',
      'thisRideCannotBeCancelled': 'ការធ្វើដំណើរនេះមិនអាចលុបចោលបានទេ',
      'thisRideWasCancelled': 'ការធ្វើដំណើរនេះត្រូវបានលុបចោល',
      'trackMyRotehTripLive': 'តាមដានការធ្វើដំណើរតាម ROTEH របស់ខ្ញុំផ្ទាល់ 🛺\n',
      'trackMyRideLive': 'តាមដានការធ្វើដំណើររបស់ខ្ញុំផ្ទាល់',
      'tripInProgress2': 'កំពុងធ្វើដំណើរ',
      'wrongPickupLocation': 'ខុសទីតាំងត្រូវទៅទទួល',
      'yourDriverIsOnThe': 'អ្នកបើកបរកំពុងនៅតាមផ្លូវ',
      'yourDriverIsOnThe2': 'អ្នកបើកបរកំពុងនៅតាមផ្លូវទៅទទួលអ្នក',
      'sosAlertSent': '🆘 បានផ្ញើសារអាសន្ន SOS រួចរាល់',
      'youReAlmostAtYour': '🔔 ជិតដល់គោលដៅហើយ',
      // ── ride_booking messages ──
      'abaPay': 'អេប៊ីអេ',
      'acleda': 'អេស៊ីលីដា',
      'aeonMallSenSok': 'ផ្សារអេអនសែនសុខ',
      'bike2': 'ម៉ូតូ',
      'carPremium': 'ឡានប្រណិត',
      'carStandard': 'ឡានស្តង់ដា',
      'confirmDestination2': 'បញ្ជាក់គោលដៅ',
      'confirmDestinations': 'បញ្ជាក់គោលដៅ',
      'detectingLocation': 'កំពុងកំណត់ទីតាំង…',
      'dragMapToSetDestination': 'អូសផែនទី ដើម្បីកំណត់គោលដៅ',
      'invalidOrExpiredCode': 'កូដមិនត្រឹមត្រូវ ឬផុតកំណត់',
      'locationPermissionDenied': 'មិនបានអនុញ្ញាតសិទ្ធិទីតាំង',
      'lookingForADriver': 'កំពុងស្វែងរកអ្នកបើកបរ…',
      'meteredFare': 'តម្លៃតាមម៉ែត្រ',
      'motorcycle': 'ម៉ូតូ',
      'nightMarketRiverside': 'ផ្សាររាត្រី (មាត់ទន្លេ)',
      'phnomPenhInternationalAirport': 'ព្រលានយន្តហោះអន្តរជាតិភ្នំពេញ',
      'pickupLocation3': 'ទីតាំងទទួល',
      'royalPalace': 'ព្រះបរមរាជវាំង',
      'sharedRide': 'ជិះរួមគ្នា',
      'tapMapToSetPickup': 'អូសផែនទី ដើម្បីកំណត់ទីតាំងទៅទទួល',
      'tellDriverOnArrival': 'ប្រាប់គោលដៅ ពេលជួបអ្នកបើកបរ',
      'toulTomPongMarket': 'ផ្សារទួលទំពួង',
      'tukTuk2': 'តុកតុក',
      'tukTuk3': 'តុកតុក',
      'vanXl': 'ឡាន / ឡានធំទូលាយ',
      // ── delivery_screen messages ──
      'bookMoving': 'កក់ការរើទីតាំង',
      'deliveryAddress': 'អាស័យដ្ឋានដឹកជញ្ជូន',
      'dragMapToSelectLocation': 'អូសផែនទី ដើម្បីកំណត់គោលដៅ',
      'fromAndToAddressesAre': 'អាស័យដ្ឋានទៅ និងមក តម្រូវចាំបាច់',
      'movingCrew': 'ក្រុមការងារជួយរើឥវ៉ាន់',
      'movingFromFullAddress': 'រើចេញ (អាស័យដ្ឋានពេញ)',
      'movingToFullAddress': 'រើទៅកាន់ (អាស័យដ្ឋានពេញ)',
      'noStairsCarry': 'ទេ (ជញ្ជូនតាមជណ្តើរ)',
      'noDescription': 'មិនមានការបរិយាយ',
      'notesOptional': 'សម្គាល់ (មិនតម្រូវ)',
      'packageDescriptionOptional': 'រៀបរាប់ពីកញ្ចប់ (មិនតម្រូវ)',
      'pickupAddress': 'អាស័យដ្ឋានទៅទទួល',
      'pickupAndDeliveryAddressAre': 'តម្រូវឱ្យបញ្ចូលទីតាំងទទួល និងទីតាំងប្រគល់.',
      'scheduleDelivery2': 'កំណត់ពេលដឹកជញ្ជូន',
      'scheduleMoving': 'កំណត់ពេលរើឥវ៉ាន់',
      // ── Ride booking categories ──
      'carShort': 'ឡាន',
      // ── Driver earnings screen ──
      'avgTrip': 'គិតជាមធ្យម / ការធ្វើដំណើរ',
      'breakdown': 'ការបែងចែកតម្លៃ',
      'deliveries': 'ការដឹកជញ្ជូន',
      'last30Days': '៣០ថ្ងៃមុន',
      'noEarningsHistoryYet': 'មិនមានប្រវត្តិចំណូលនៅឡើយ',
      'rides': 'ការធ្វើដំណើរ',
      'totalEarnings': 'ចំណូលសរុប',
      // ── Driver earnings messages ──
      'breakdownIsOnlyAvailableFor': 'តម្លៃលម្អិតមានតែតាមសប្តាហ៍/ តាមខែ',
      'noEarningsInThisPeriod': 'មិនមានចំណូលឡើយក្នុងកំឡុងពេលនេះ',
      'thisMonth': 'ខែនេះ',
      'thisWeek': 'សប្តាហ៍នេះ',
      'today': 'ថ្ងៃនេះ',
      // ── Weekday abbreviations ──
      'mon': 'ថ្ងៃច័ន្ទ',
      'tue': 'ថ្ងៃអង្គារ',
      'wed': 'ថ្ងៃពុធ',
      'thu': 'ថ្ងៃព្រហស្បតិ៍',
      'fri': 'ថ្ងៃសុក្រ',
      'sat': 'ថ្ងៃសៅរ៍',
      'sun': 'ថ្ងៃអាទិត្យ',
      // ── Driver home screen ──
      'stairsCarry': ' លើកតាមជណ្តើរ',
      'n1204Trips': ' · 1,204 ដំណើរ',
      'n1204Trips2': '(1,204 ដំណើរ)',
      'n3Of5PeakHour': '3 ក្នុងចំណោម 5 ដំណើរ ក្នុង ម៉ោងស្ទះ បានបញ្ចប់ជាស្ថាពរក្នុងថ្ងៃនេះ',
      'n4Consecutive5StarRatings': 'ទទួលបានផ្តាយ ៥ ចំនួន 4 ដងបន្តគ្នា!',
      'n5StarStreak': 'ទទួលផ្កាយ ៥ ឈ្នះដាច់ 🔥',
      'accountHolderName': 'ឈ្មោះម្ចាស់គណនី',
      'accountNumber': 'លេខគណនី',
      'active69Pm': 'កំពុងដំណើរការចន្លោះម៉ោង 6–9 ល្ងាច',
      'availableBalance': 'សមតុល្យដែលមាន',
      'bank': 'ធនាគារ',
      'confirmWithdrawal': 'បញ្ជាក់ពីការដោះដូរសាច់ប្រាក់',
      'instantWithdrawal': 'ដោះដូរសាច់ប្រាក់ភ្លាមៗ',
      'loadMore': 'កំពុងដំណើរការ',
      'peakHourBonus': 'ចំណូលបន្ថែម ម៉ោងស្ទះចរាចរណ៍',
      'rentalModeActive': 'កំពុងដំណើរការម៉ូតសម្រាប់ជួល',
      'rentalRequestAccepted': 'ការស្នើជួលបានអនុម័ត',
      'requestCancelled': 'ការស្នើត្រូវបានលុបចោល',
      'resume': 'បន្ត',
      'reviewedByAdminBeforeFunds': 'ត្រូវការពិនិត្យដោយអេដមីនមុនពេលទឹកប្រាក់អាចផ្ញើចេញបាន',
      'selectBank': 'ជ្រើសរើសធនាគារ',
      'showAll': 'បង្ហាញទាំងអស់',
      'tapToOpenTheMap': 'ចុចដើម្បីបើកផែនទី និងឆែកមើលទីតាំងដែលត្រូវទៅ',
      'waitingForDeliveryOrdersIn': 'កំពុងរងចាំការកម្មង់ដឹកជញ្ចូនក្នុងតំបន់របស់អ្នក​',
      'waiting': 'កំពុងរងចាំ...',
      'yesWithdraw': 'ត្រឹមត្រូវ, ដោះដូរប្រាក់',
      'youHaveAWithdrawalRequest': 'ការស្នើដោះដូរប្រាក់របស់អ្នកកំពុងរងចាំការអនុម័តពីអេដមីន',
      'youLlBeNotifiedWhen': 'នឹងមានការជូនដំណឹងពេលមានអ្នកដំណើរក្បែរៗត្រូវការអ្នកបើកបរ',
      'yourVehicleIsListedFor': 'យានជំនិះរបស់ត្រូវដាក់ជួលគិតជាម៉ោង',
      'earnedToday': 'ចំណូលថ្ងៃនេះ',
      // ── Driver home messages ──
      'abaBank': 'ធនាគារអេប៊ីអេ',
      'acledaBank': 'ធនាគារអេស៊ីលីដា',
      'canadiaBank': 'ធនាគារកាណាឌីយ៉ា',
      'completeYourTripToReceive': 'បញ្ចប់ការដឹករបស់ដើម្បីអាចទទួលការដឹកថ្មី',
      'deliveryInProgress': 'កំពុងដឹកជញ្ជូន',
      'headThereForHigherEarnings': 'ឆ្ពោះទៅទីតាំងនោះដើម្បីបានចំណូលខ្ពស់ជាងមុន',
      'highDemandInYourArea': 'មានតម្រូវការខ្ពស់ក្នុងតំបន់របស់អ្នក',
      'movingInProgress': 'កំពុងរើឥវ៉ាន់',
      'noBalanceToWithdraw': 'មិនមានសមតុល្យដើម្បីដោះដូរសាច់ប្រាក់ទេ',
      'noDestinationPassengerWillTell': 'មិនកំណត់ទីតាំង — អ្នកជិះនឹងប្រាប់អ្នកផ្ទាល់',
      'noTransactionsToday': 'មិនមានប្រតិបត្តិការសម្រាប់ថ្ងៃនេះ',
      'pleaseEnterYourAccountNumber': 'សូមបញ្ចូលឈ្មោះ និងលេខគណនីរបស់អ្នក',
      'rideInProgress': 'កំពុងដឹកអ្នកដំណើរ',
      'thePassengerCancelledThatRide': 'អ្នកដំណើរបានលុបចោលការកម្មង់',
      'toggleOnlineToAcceptRides': 'ចុចបើកអនឡាញ ដើម្បីទទួលការដឹកអ្នកដំណើរ',
      'transactionHistory': 'ប្រវត្តិប្រតិបត្តិការ',
      'waitingForRequests': 'កំពុងរងចាំការស្នើ...',
      'withdrawalPendingApproval': 'ការស្នើដោះដូរប្រាក់កំពុងរងចាំការអនុម័ត',
      'withdrawalsUnavailable': 'មិនអាចស្នើដោះដូរប្រាក់',
      'urgent': '⚡ បន្ទាន់',
      'offline2': '⭕ Offline',
      'newRequest': '🆕 ការស្នើថ្មី',
      'newDelivery': '📦 ការដឹកជញ្ជូនថ្មី',
      'newRental': '🚚 ការជួលថ្មី',
      'newMoving': '🚚 ការរើថ្មី',
      'busyOnATrip': '🟡 រវល់ — កំពុងធ្វើដំណើរ',
      'onlineReady': '🟢 អនឡាញ — អាចចេញដំណើរបាន',
      // ── helmet_check_screen ──
      'chooseFromGallery': 'ជ្រើសរើសចេញពីរូបភាព',
      'gallery': 'រូបភាព',
      'pleaseWearAHelmetBefore': 'សូមពាក់មួកសុវត្ថិភាពមុននឹងចេញដំណើរ',
      'retake': 'ថតម្តងទៀត',
      'takePhoto': 'ថតរូប',
      'tapToUploadPhoto': 'ចុចដើម្បី upload រូប',
      'uploadAPhotoToVerify': 'Upload រូបថតដើម្បីបញ្ជាក់ថាបានពាក់មួកសុវត្ថិភាពត្រឹមត្រូវហើយ',
      // ── helmet_check_screen messages ──
      'checkHelmet': 'ឆែកមួកសុវត្ថិភាព',
      'checking': 'កំពុងពិនិត្យ…',
      'helmetDetected': 'មានមួកសុវត្ថីភាពត្រឹមត្រូវ!',
      'noHelmetDetected': 'មិនអាចចាប់បានមួកសុវត្ថិភាព',
      // ── driver_withdrawal_screen ──
      'amountKhr': 'ចំនួន (រៀល)',
      'bankNameOptional': 'ឈ្មោះធនាគារ (មិនតម្រូវ)',
      'confirm': 'បញ្ជាក់',
      'noWithdrawalHistory': 'មិនមានប្រវត្តិដោះដូរប្រាក់',
      'pleaseMakeSureTheseDetails': 'សូមប្រាកដថាព៏ត៌មានពិតជាត្រឹមត្រូវ មិនអាចកែប្រែទេប្រសិនបានបញ្ជូនរួចរាល់',
      'requestWithdrawal': 'ការស្នើដោះដូរប្រាក់',
      'withdrawalRequestSubmitted': 'ការស្នើដោះដូរប្រាក់បានបញ្ជូន!',
      // ── driver_withdrawal_screen messages ──
      'accountName': 'ឈ្មោះគណនី',
      'amount': 'ចំនួន',
      'enterAValidAmount': 'បញ្ជូលចំនួនឱ្យបានត្រឹមត្រូវ',
      'enterAccountHolderName': 'បញ្ជូលឈ្មោះម្ចាស់គណនី',
      'enterAccountNumber': 'បញ្ជូលលេខគណនី',
      'fullNameAsOnAccount': 'ឈ្មោះពេញលើគណនី',
      'method': 'វិធីសាស្រ្ត',
      'wing': 'វីង',
      'withdraw': 'ដោះដូរប្រាក់',
      'eGAbaAcledaWing': 'ឧ. ABA, ACLEDA, Wing…',
      // ── driver_vehicle_screen ──
      'colorOptional': 'ពណ៌ (មិនតម្រូវ)',
      'imagesUploaded': 'បញ្ជូលរូបភាព',
      'licensePlate': 'ផ្លាកលេខ',
      'make': 'ផលិត',
      'model': 'ម៉ូដែល',
      'myVehicles': 'យានជំនិះរបស់ខ្ញុំ',
      'noVehiclesRegistered': 'មិនមានយានជំនិះចុះបញ្ជី',
      'registerVehicle': 'ចុះបញ្ជីយានជំនិះ',
      'registerYourVehicleToStart': 'ចុះបញ្ជីយានជំនិះរបស់អ្នកដើម្បីអាចទទួលដឹកអ្នកដំណើរ',
      'year': 'ឆ្នាំ',
      // ── driver_vehicle_screen messages ──
      'editVehicle': 'កែប្រែ ទិន្នន័យ យានជំនិះ',
      'honda': 'ហុងដា',
      'makeModelAndPlateAre': 'ផលិត, ម៉ូដែល និងផ្លាកលេខ​ តម្រូវចាំបាច់',
      'motorbike': 'ម៉ូតូ',
      'saveChanges': 'រក្សាទុកការកែប្រែ',
      'truck': 'ឡានដឹក',
      'vehicle': 'យានជំនិះ',
      'wave': 'ម៉ាកវេវ',
      // ── driver_trip_summary_screen ──
      'confirmed': 'បានបញ្ជាក់',
      'fareSummary': 'សង្ខេបការដឹក',
      'paymentMethod2': 'វិធីសាស្រ្តចំណាយ',
      'paymentReceived': 'បានទទួល',
      'totalFare': 'សរុប',
      'tripCompleted': 'ការដឹកអ្នកដំណើរបានជោគជ័យ!',
      // ── driver_trip_summary_screen messages ──
      'bike3': 'ម៉ូតូ',
      'noDestinationToldInPerson': 'មិនកំណត់គោលដៅ — ប្រាប់អ្នកដឹកផ្ទាល់',
      'tukTuk4': 'តុក តុក',
      // ── driver_missions_screen ──
      'acceptAJobFromThe': 'ទទួលការដឹកលើផ្ទាំងដើម ដើម្បីអាចឃើញព័ត៌មានទីនេះ',
      'avgFare': 'តម្លៃ ជាមធ្យម',
      'earned': 'បានទទួលចំណូល',
      'noRidesYet': 'មិនទាន់មានការដឹកនៅឡើយ',
      'tapToRefreshForLatest': 'ចុចដើម្បី refresh ស្ថានភាពចុងក្រោយបំផុត',
      'thisOrderWasCancelled': 'ការកម្មង់នេះត្រូវបានលុបចោល',
      // ── driver_missions_screen messages ──
      'accepted2': 'បានទទួល',
      'arrived2': 'មកដល់',
      'cancelled': 'លុបចោល',
      'delivery2': 'ដឹកជញ្ជូន',
      'done2': 'បញ្ចប់',
      'delivered': 'បានដឹកជញ្ជូន',
      'failedToLoadDeliveries': 'បរាជ័យក្នុងការបង្ហាញការដឹកជញ្ជូនឥវ៉ាន់',
      'failedToLoadMovings': 'បរាជ័យក្នុងការបង្ហាញការរើឥវ៉ាន់',
      'failedToLoadRideHistory': 'បរាជ័យក្នុងការបង្ហាញការដឹកអ្នកដំណើរ',
      'inProgress': 'កំពុងដំណើរការ',
      'inTransit': 'កំពុងប្តូរជើងដឹក',
      'loading2': 'កំពុងដំណើរការ',
      'moving2': 'កំពុងរើ',
      'pickedUp': 'បានទៅទទួល',
      // ── driver_history_screen ──
      'noMoreTrips': 'មិនទាន់មានការធ្វើដំណើរទៀតទេ',
      'noTripsYet': 'មិនទាន់មានការធ្វើដំណើរនៅឡើយ',
      'trip': 'ការធ្វើដំណើរ',
      'yourCompletedTripsWillAppear': 'ការធ្វើដំណើរជោគជ័យនឹងបង្ហាញទីនេះ',
      // ── driver_history_screen messages ──
      'cancelled2': 'បានលុបចោល',
      'unknown': 'មិនស្គាល់',
      'yesterday': 'ម្សិលមិញ',
      // ── driver_document_upload_screen ──
      'optionalDocuments': 'ឯកសារមិនតម្រូវ',
      'required': 'តម្រូវចាំបាច់',
      'requiredDocuments': 'ឯកសារតម្រូវចាំបាច់',
      'submitForReview': 'បញ្ជូនសម្រាប់ពិនិត្យ',
      'uploadDocuments': 'បញ្ចូលឯកសារ',
      'uploaded': 'បានបញ្ចូល',
      'yourDocumentsWillBeReviewed': 'ឯកសាររបស់អ្នកនឹងត្រូវពិនិត្យ ជាទូទៅ ចំណាយពេល ១ ទៅ ២ ថ្ងៃធ្វើការ',
      // ── driver_document_upload_screen messages ──
      'driverLicense': 'បណ្ណបើកបរ',
      'nationalIdPassport': 'អត្តសញ្ញាណបណ្ណ / លិខិតឆ្លងដែន',
      'optionalTapToUpload': 'មិនតម្រូវ — ចុចដើម្បីបញ្ចូល',
      'otherDocument': 'ឯកសារផ្សេងទៀត',
      'ready': 'រួចរាល់!',
      'selfieWithId': 'ថត Selfie ជាមួយអត្តសញ្ញាណបណ្ណ',
      'tapToUpload': 'ចុចដើម្បីបញ្ចូល',
      'vehicleInsurance': 'ធនារ៉ាប់រងយានជំនិះ',
      'vehicleRegistration': 'បញ្ជីយានជំនិះ',
      // ── Driver vehicle types ──
      'van': 'ឡានវែន',
      // ── Document upload ──
      'requiredDocumentsUploadedSuffix': 'ឯកសារតម្រូវចាំបាច់បានបញ្ចូលរួចរាល់',
      // ── Driver approval pending screen ──
      'applicationStatus': 'ស្ថានភាព',
      'pleaseReviewTheFeedbackOn': 'សូមពិនិត្យព័ត៌មានត្រឡប់ខាងលើ រួចបញ្ជូនរូបថតម្តងទៀតឱ្យបានត្រឹមត្រូវ សូមទាក់ទងក្រុមការងារប្រសិនបើមានចម្ងល់បន្ថែម',
      'reUploadDocuments': 'បញ្ជូលឯកសារម្តងទៀត',
      'refreshStatus': 'Refresh ស្ថានភាព',
      'weLlNotifyYouOnce': 'នឹងមានការជូនដំណឹង នៅពេល​ឯកសាររបស់អ្នកត្រូវបានពិនិត្យរួចរាល់ \n ជាទូទៅ ចំណាយពេល ១ ទៅ ២ ថ្ងៃធ្វើការ',
      'whatToDoNext': 'អ្វីដែលត្រូវធ្វើបន្ទាប់',
      // ── Driver approval status ──
      'documentReviewResults': 'លទ្ធផលពិនិត្យឯកសារ',
      'documentStatus': 'ស្ថានភាពឯកសារ',
      'approvedExcl': 'បានអនុម័ត!',
      'youCanNowGoOnline': 'អ្នកអាចឡើង អនឡាញ ហើយទទួលការដឹកឥលូវនេះ',
      'applicationRejected': 'ពាក្យសុំត្រូវបានបដិសេធ',
      'pleaseReviewDocsResubmit': 'សូមពិនិត្យឯកសាររបស់អ្នក រួចបញ្ជូនមកម្តងទៀត',
      'underReview': 'កំពុងពិនិត្យ',
      'ourTeamIsReviewing': 'ក្រុមការងារកំពុងពិនិត្យពាក្យស្នើសុំរបស់អ្នក',
      'city': 'ទីក្រុង',
      'serviceZone': 'តំបន់មានសេវា',
      'approvedStatus': 'បានអនុម័ត',
      'rejectedStatus': 'បានបដិសេធ',
      'pendingStatus': 'កំពុងដំណើរការ',
      // ── Driver delivery active screen ──
      'toUpdateProgressContinueFrom': 'ដើម្បីធ្វើបច្ចុប្បន្នភាព សូមបន្តចេញពីអេក្រង់ការងារដែលកំពុងដំណើរការ',
      'you': 'អ្នក',
      // ── Driver delivery active screen ──
      'movingFrom': 'រើចេញពី',
      'movingTo': 'រើទៅកាន់',
      'arriving': 'កំពុងមកដល់',
      'arrivedAtLocation': 'បានមកដល់ទីតាំង',
      'loadingComplete': 'លើកឥវ៉ាន់បានជោគជ័យ',
      'markAsDelivered': 'ដឹកជញ្ជូនត្រូវបានកំណត់',
      'arrivedAtPickup': 'បានមកដល់ទីតាំងទៅទទួល',
      'packagePickedUp': 'កញ្ចប់ឥវ៉ាន់បានទៅយករួចរាល់',
      'headingToPickupLocation': 'កំពុងឆ្ពោះទៅ ទីតាំងទៅយក',
      'atLocationLoadingItems': 'កំពុងនៅទីតាំង — កំពុងលើកឥវ៉ាន់',
      'inTransitToNewLocation': 'កំពុងទៅទីតាំងថ្មី',
      'movingCompleteExcl': 'រើឥវ៉ាន់ជោគជ័យ!',
      'headingToSender': 'កំពុងទៅរកអ្នកផ្ញើឥវ៉ាន់',
      'atPickupCollectPackage': 'នៅឯទីតាំងទទួល — ប្រមូលកញ្ចប់ឥវ៉ាន់',
      'onTheWayToRecipient': 'នៅតាមផ្លូវដឹកទៅរកអ្នកទទួល',
      'deliveredExcl': 'បានដឹកជញ្ជូន!',
      'heading': 'កំពុងទៅរក',
      'atLocation': 'នៅឯទីតាំង',
      'atPickup': 'នៅទីតាំងទទួល',
      'youArrivedAtPickupLocation': 'អ្នកបានមកដល់ទីតាំងទទួល',
      'packagePickedUpHeadingToDropoff': 'កញ្ចប់ឥវ៉ាន់បានទទួល — កំពុងឆ្ពោះទៅរកកន្លែងដឹកទៅ',
      'arrivedAtMovingLocationStartLoading': 'បានមកដល់កន្លែងរើឥវ៉ាន់ — កំពុងលើកឥវ៉ាន់',
      'loadingCompleteHeadingToNewLocation': 'លើកឥវ៉ាន់រួចរាល់ — ឆ្ពោះទៅកាន់ទីតាំងថ្មី',
      'minAway': 'ចម្ងាយ មិនប៉ុន្មាននាទី',
      'senderNumberPrefix': 'អ្នកផ្ញើ #',
      // ── Driver active trip screen ──
      'amountToCollect': 'ចំនួនទឹកប្រាក់ត្រូវប្រមូល',
      'arrivedAtStop': 'បានមកដល់ហាង',
      'callNow': 'ខល ឥលូវ',
      'completeTrip': 'ការធ្វើដំណើរ បញ្ចប់',
      'emergencySos': 'បន្ទាន់ SOS',
      'enable': 'បើក',
      'enterFinalFare': 'បញ្ចូលតម្លៃចុងក្រោយ',
      'locationPermissionDeniedLiveTracking': 'ទីតាំង មុខងារមិនអនុញ្ញាត — តាមដានផ្ទាល់ ',
      'sos': 'SOS',
      'sendSos': 'ផ្ញើ SOS',
      'thisTripHadNoDestination': 'ការធ្វើដំណើរនេះមិនបានកំណត់គោលដៅទៅ — នេះជាសង្ខេបការគណនា',
      'thisWillAlertEmergencyServices': 'អាចនាំឱ្យមានការបញ្ជូនសេវាបន្ទាន់ ហើយក្រុមការងារ រទេះអេប នឹងទទួលបានការជូនដំណឹងពីទីតាំងរបស់អ្នក',
      'tripCompleted2': 'ការធ្វើដំណើរបានបញ្ចប់ជោគជ័យ',
      'kmH': 'គីឡូម៉ែត្រ/ម៉ោង',
      'sosSentHelpIsOn': '🚨 SOS បានបញ្ជូន! ជំនួយកំពុងនៅតាមផ្លូវ',
      // ── Driver active trip screen ──
      'passengerNumberPrefix': 'អ្នកដំណើរ #',
      'noDestinationAskPassenger': 'មិនមានកំណត់គោលដៅទៅ — អាចសួរអ្នកដំណើរផ្ទាល់',
      'bike4': 'ម៉ូតូ',
      'tukTuk5': 'តុក-តុក',
      'continueStraight': 'បន្តទៅមុខត្រង់',
      'youHaveArrivedAt': 'អ្នកបានមកដល់',
      'noActiveRide': 'មិនមានការកំពុងធ្វើដំណើរទេ',
      'headingToPickup2': 'កំពុងឆ្ពោះទៅទទួល',
      'waitingAtPickup': 'កំពុងរងចាំនៅទីតាំងត្រូវទទួល',
      'arrivedAtPickupBtn': '✅  បានមកដល់ទីតាំងទៅទទួល',
      'passengerOnBoardStartTrip': '🛺 អ្នកដំណើរឡើងរួចរាល់ — ចាប់ផ្តើមចេញដំណើរ',
      'backToDashboardBtn': '🏠  ថយក្រោយទៅកាន់ផ្ទាំងព័ត៌មាន',
      'enterAValidAmount2': 'បញ្ចូលចំនួនដែលត្រឹមត្រូវ',
      'metered': 'គិតជាម៉ែត្រ',
      'youEarnedPrefix': 'អ្នកបានទទួលចំណូល',
      'calculatedDistancePrefix': 'បានគណនាចម្ងាយ',
      'looksWrongFartherThanTrip': 'មើលទៅដូចខុស — វាឆ្ងាយជាងដំណើរផ្សេងៗទៀត ក្នុងស្រុកខ្មែរ',
      'noFareReturnedForServiceType': 'មិនមានតម្លៃសងឡើយសម្រាប់ប្រភេទសេវាកម្ម',
      'fareCalculationFailedPrefix': 'បរាជ័យក្នុងការគណនាតម្លៃសេវា:',
      'unknownError': 'កំហុសមិនដឹងពីមូលហេតុ',
      'tripHadNoDestinationSuggested': 'ដំណើរនេះមិនមានកំណត់គោលដៅទៅ តម្លៃប៉ាន់ស្មានខាងក្រោមនេះត្រូវបានគណនា',
      'fromDistanceTravelledAdjust': 'បានចេញដំណើរ — ធ្វើការកែសម្រួលប្រសិនចាំបាច់',
      // ── Driver active trip screen 2 ──
      'tripInProgressCap': 'កំពុងធ្វើដំណើរ',
      'completeTripBtn': '🏁  ដំណើរជោគជ័យ',
      // ── accessibility_screen ──
      'accessibilityTitle': 'ភាពងាយស្រួលប្រើប្រាស់',
      'save': 'រក្សាទុក',
      'accessibilitySettingsSaved': 'បានរក្សាទុកការកំណត់ភាពងាយស្រួលប្រើប្រាស់',
      'saveSettings': 'រក្សាទុកការកំណត់',
      'visualSection': 'ចក្ខុវិស័យ',
      'audioAndSpeechSection': 'សំឡេង និងការនិយាយ',
      'interactionSection': 'អន្តរកម្ម',
      'largeText': 'អក្សរធំ',
      'largeTextSubtitle': 'ពង្រីកទំហំអក្សរនៅទូទាំងកម្មវិធី',
      'highContrast': 'កម្រិតពណ៌ផ្ទុយ',
      'highContrastSubtitle': 'បង្កើនភាពមើលឃើញច្បាស់ជាមួយពណ៌ផ្ទុយ',
      'reduceMotion': 'កាត់បន្ថយចលនា',
      'reduceMotionSubtitle': 'កាត់បន្ថយចលនា និងបែបផែនផ្លាស់ប្តូរ',
      'screenReaderSupport': 'ការគាំទ្រកម្មវិធីអានលើអេក្រង់',
      'screenReaderSupportSubtitle': 'កែសម្រួលស្លាកសម្រាប់បច្ចេកវិទ្យាជំនួយ',
      'hapticFeedback': 'ការឆ្លើយតបត្រឡប់',
      'hapticFeedbackSubtitle': 'ញ័រនៅពេលមានអន្តរកម្មសំខាន់ៗ',
      'largeTouchTargets': 'ចំណុចប៉ះអេក្រង់ទំហំធំ',
      'largeTouchTargetsSubtitle': 'ប៊ូតុង និងតំបន់ប៉ះទំហំធំជាង',
      'wheelchairAccessibleVehicles': 'យានជំនិះសម្រាប់រទេះជនពិការភាព',
      'wheelchairAccessibleVehiclesSubtitle': 'បង្ហាញតែជម្រើសយានជំនិះងាយស្រួលប្រើប្រាស់',
      // ── airport_trip_screen ──
      'airportTransferTitle': 'ដឹកជញ្ជូនអាកាសយានដ្ឋាន',
      'toAirportTab': 'ទៅអាកាសយានដ្ឋាន',
      'fromAirportTab': 'ពីអាកាសយានដ្ឋាន',
      'freeWaitBannerMessage': 'រួមបញ្ចូលការរង់ចាំឥតគិតថ្លៃ ៦០ នាទី — យើងតាមដានជើងហោះហើររបស់អ្នក ហើយកែសម្រួលការមកទទួលដោយស្វ័យប្រវត្តិ',
      'dropoffAirportLabel': 'ទីតាំងជូនចុះនៅព្រលានយន្តហោះ',
      'pickupAirportLabel': 'ទីតាំងទៅទទួលនៅព្រលានយន្តហោះ',
      'pickupAddressLabel': 'អាសយដ្ឋានទៅទទួល',
      'dropoffAddressLabel': 'អាសយដ្ឋានជូនចុះ',
      'enterHomeHotelAddressHint': 'បញ្ចូលអាសយដ្ឋានផ្ទះ/សណ្ឋាគាររបស់អ្នក',
      'enterDestinationAddressHint': 'បញ្ចូលអាសយដ្ឋានទិសដៅរបស់អ្នក',
      'flightDetailsLabel': 'ព័ត៌មានជើងហោះហើរ',
      'flightNumberHint': 'លេខជើងហោះហើរ (ឧ. QH101)',
      'terminalHint': 'អគារព្រលានយន្តហោះ (ឧ. T1)',
      'departureTime': 'ពេលចេញដំណើរ',
      'arrivalTime': 'ពេលមកដល់',
      'vehicleTypeLabel': 'ប្រភេទយានជំនិះ',
      'sedanLabel': 'រថយន្តសេដាន',
      'upTo4Pax': 'អតិបរមា ៤ អ្នកដំណើរ',
      'suvVanLabel': 'អេសយូវី/វែន',
      'upTo6Pax': 'អតិបរមា ៦ អ្នកដំណើរ',
      'passengersAndLuggageLabel': 'អ្នកដំណើរ និងឥវ៉ាន់',
      'passengersLabel': 'អ្នកដំណើរ',
      'luggageBagsLabel': 'ថង់ឥវ៉ាន់',
      'enterAddressForFareEstimate': 'បញ្ចូលអាសយដ្ឋានរបស់អ្នកដើម្បីឃើញការប៉ាន់ស្មានតម្លៃ',
      'airportSurcharge': 'ថ្លៃបន្ថែម របស់អាកាសយានដ្ឋាន',
      'bookingFee': 'ថ្លៃកក់',
      'distanceFare': 'ថ្លៃតាមចម្ងាយ',
      'timeFare': 'ថ្លៃតាមពេលវេលា',
      'nightSurcharge': 'ថ្លៃបន្ថែមពេលយប់',
      'weekendSurcharge': 'ថ្លៃបន្ថែមចុងសប្តាហ៍',
      'holidaySurcharge': 'ថ្លៃបន្ថែមថ្ងៃបុណ្យ',
      'fareRoundingAdjustment': 'ការកែតម្រូវការបង្គត់',
      'luggageBagsCountLabel': 'ឥវ៉ាន់',
      'fixedPriceNoSurge': 'តម្លៃថេរ · គ្មានតម្លៃកើនឡើង',
      'bookTransferPrefix': 'កក់ការដឹកជញ្ជូន',
      'bookAirportTransfer': 'កក់ការដឹកជញ្ជូន អាកាសយានដ្ឋាន',
      'fillAddressFlightDetailsError': 'សូមបំពេញអាសយដ្ឋាន លេខជើងហោះហើរ និងម៉ោងជើងហោះហើររបស់អ្នក',
      'airportFallback': 'អាកាសយានដ្ឋាន',
      // ── cancellation_policy_screen ──
      'cancellationPolicyTitle': 'គោលការណ៍លុបចោល',
      'feesGoToDriversNote': 'ថ្លៃសេវាទាំងនេះទៅដល់អ្នកបើកបរជាសំណងចំពោះពេលវេលារបស់ពួកគេ',
      'contactSupport': 'ទាក់ទងផ្នែកជំនួយ',
      'beforeDriverAccepts': 'មុនពេលអ្នកបើកបរទទួលយក',
      'freeCancellation': 'លុបចោលដោយឥតគិតថ្លៃ',
      'freeCancelBeforeAcceptDetail': 'អ្នកអាចលុបចោលបានគ្រប់ពេលមុនពេលអ្នកបើកបរទទួលយកការធ្វើដំណើររបស់អ្នកដោយឥតគិតថ្លៃ',
      'afterDriverAccepts': 'បន្ទាប់ពីអ្នកបើកបរទទួលយក',
      'cancelRangeMinutes': '{from}–{to} នាទី',
      'cancelRangeFromMinutes': 'ចាប់ពី {from} នាទី',
      'cancelFeeAmount': 'ថ្លៃសេវា {fee} រៀល',
      'cancelTierFreeDetail': 'ការលុបចោលក្នុងរយៈពេលនេះគឺឥតគិតថ្លៃ',
      'cancelTierFeeDetail': 'ថ្លៃលុបចោល {fee} រៀល នឹងត្រូវគិត ប្រសិនបើអ្នកលុបចោលក្នុងរយៈពេលនេះ',
      'cancellationPolicyLoadFailed': 'មិនអាចផ្ទុកគោលការណ៍លុបចោលបានទេ',
      'afterDriverArrives': 'បន្ទាប់ពីអ្នកបើកបរមកដល់',
      // ── car_rental_screen ──
      'durMonth1': '១ ខែ',
      'durMonth2': '២ ខែ',
      'durMonth3': '៣ ខែ',
      'durMonth6': '៦ ខែ',
      'durYear1': '១ ឆ្នាំ',
      'durYear2': '២ ឆ្នាំ',
      'pickUpLabel': 'ទៅយកខ្លួនឯង',
      'collectCarMyself': 'ខ្ញុំនឹងទៅយកដោយខ្លួនឯង',
      'deliverCarToAddress': 'ដឹកជញ្ជូនមកកាន់អាសយដ្ឋានរបស់ខ្ញុំ',
      'tapToSetPickupLocation': 'ចុចដើម្បីកំណត់ទីតាំងទទួល',
      'tapToSetDeliveryLocation': 'ចុចដើម្បីកំណត់ទីតាំងដឹកជញ្ជូន',
      'setPickupLocationTitle': 'កំណត់ទីតាំងទទួល',
      'setDeliveryLocationTitle': 'កំណត់ទីតាំងដឹកជញ្ជូន',
      'suvLabel': 'អេសយូវី',
      'electricLabel': 'អគ្គិសនី',
      'locationTypeLabel': 'ប្រភេទទីតាំង',
      'rentalDurationTitle': 'រយៈពេលជួល',
      'endsPrefix': 'បញ្ចប់',
      'payInCashOnPickup': 'បង់ជាសាច់ប្រាក់ពេលទទួល',
      'failedToApplyCoupon': 'មិនអាចអនុវត្តគូប៉ុងបានទេ',
      'bookedHashPrefix': 'បានកក់ #',
      'datesLabel': 'កាលបរិច្ឆេទ',
      'dailyRateLabel': 'អត្រាប្រចាំថ្ងៃ',
      'renterLabel': 'អ្នកជួល',
      'selectVehicleBeforeBooking': 'សូមជ្រើសរើសយានជំនិះមុននឹងកក់',
      'setDeliveryLocationError': 'សូមកំណត់ទីតាំងដឹកជញ្ជូន',
      'enterNamePhoneError': 'សូមបញ្ចូលឈ្មោះ និងលេខទូរស័ព្ទរបស់អ្នក',
      'rentalVehicleTitle': 'យានជំនិះជួល',
      'locationLabel': 'ទីតាំង',
      'vehicleForRentLabel': 'យានជំនិះសម្រាប់ជួល',
      'browseAvailableVehicle': 'រកមើលយានជំនិះដែលមាន',
      'tapToViewAllVehicles': 'ចុចដើម្បីមើលយានជំនិះជួលទាំងអស់',
      'rentalPeriodLabel': 'រយៈពេលជួល',
      'daysLabel': 'ថ្ងៃ',
      'endsLabel': 'បញ្ចប់',
      'startDateLabel': 'ថ្ងៃចាប់ផ្តើម',
      'endDateAutoLabel': 'ថ្ងៃបញ្ចប់ (ស្វ័យប្រវត្តិ)',
      'yourInformationLabel': 'ព័ត៌មានរបស់អ្នក',
      'notesOptionalLabel': 'កំណត់ចំណាំ (ស្រេចចិត្ត)',
      'anySpecialRequestsHint': 'សំណើពិសេសណាមួយ…',
      'couponCodeLabel': 'កូដគូប៉ុង',
      'discountAppliedSuffix': 'ការបញ្ចុះតម្លៃត្រូវបានអនុវត្ត',
      'enterCouponCodeHint': 'បញ្ចូលកូដគូប៉ុង',
      'bookingSummaryLabel': 'សង្ខេបការកក់',
      'discountLabel': 'ការបញ្ចុះតម្លៃ',
      'bookNowLabel': 'កក់ឥលូវនេះ',
      'selectAVehicleLabel': 'ជ្រើសរើសយានជំនិះ',
      'rentDashPrefix': 'ជួល —',
      'failedToLoadVehicles': 'មិនអាចផ្ទុកយានជំនិះបានទេ',
      'noVehicleAvailableForRent': 'មិនមានយានជំនិះសម្រាប់ជួលទេ',
      'photosCountSuffix': 'រូបថត',
      'daysCapLabel': 'ថ្ងៃ',
      // ── charging_stations ──
      'favoritesLabel': 'សំណព្វ',
      'fastChargingLabel': 'សាកលឿន',
      'showLess': 'បង្ហាញតិចជាង',
      'myLocationLabel': 'ទីតាំងខ្ញុំ',
      'sortedByDistanceFromLocation': 'តម្រៀបតាមចម្ងាយពីទីតាំងរបស់អ្នក',
      'sortedByDistanceFromPhnomPenh': 'តម្រៀបតាមចម្ងាយពីភ្នំពេញ (ទីតាំងមិនអាចប្រើបាន)',
      'findingYourLocation': 'កំពុងស្វែងរកទីតាំងរបស់អ្នក…',
      'myLocationUnavailable': 'ទីតាំងរបស់ខ្ញុំមិនអាចប្រើបាន',
      'nearbyChargingStationsTitle': 'ស្ថានីយ៍ប្តូរថ្មនៅជិត',
      'availableSuffix': 'នៅទំនេរ',
      // ── edit_profile_screen ──
      'takeAPhoto': 'ថតរូបថ្មី',
      'couldNotUpdatePhotoPrefix': 'មិនអាចផ្លាស់ប្តូររូបភាពបានទេ៖',
      'couldNotUpdatePhotoTryAgain': 'មិនអាចផ្លាស់ប្តូររូបភាពបានទេ សូមព្យាយាមម្តងទៀត',
      'profileUpdatedSuccess': 'ព័ត៌មានប្រវត្តិរូបត្រូវបានធ្វើបច្ចុប្បន្នភាពដោយជោគជ័យ!',
      'tapPhotoToChange': 'ចុចរូបភាពដើម្បីផ្លាស់ប្តូរ',
      'otpRequiredBadge': 'ត្រូវការលេខកូដ OTP',
      'changingPhoneRequiresOtp': 'ការផ្លាស់ប្តូរលេខទូរស័ព្ទរបស់អ្នកតម្រូវឲ្យផ្ទៀងផ្ទាត់ដោយ OTP',
      'enterSixDigitCode': 'សូមបញ្ចូលកូដ ៦ខ្ទង់',
      'verifyPhoneNumberTitle': 'ផ្ទៀងផ្ទាត់លេខទូរស័ព្ទ',
      'codeSentToPrefix': 'កូដ ៦ខ្ទង់ត្រូវបានផ្ញើទៅកាន់',
      'devCodePrefix': 'កូដសម្រាប់អភិវឌ្ឍន៍៖',
      'sendingOtpEllipsis': 'កំពុងផ្ញើ OTP...',
      'expiresInPrefix': 'ផុតកំណត់ក្នុងរយៈពេល',
      'codeExpired': 'កូដបានផុតកំណត់',
      'resendInPrefix': 'ផ្ញើម្តងទៀតក្នុងរយៈពេល',
      'verify': 'ផ្ទៀងផ្ទាត់',
      // ── family_screen ──
      'familyAccountTitle': 'គណនីគ្រួសារ',
      'addMemberTooltip': 'បន្ថែមសមាជិក',
      'createFamilyGroupTitle': 'បង្កើតគ្រុបគ្រួសារ',
      'familyGroupDescription': 'កក់ការធ្វើដំណើរជំនួសសមាជិកគ្រួសារ ពួកគេមិនចាំបាច់មានកម្មវិធីទេ — ត្រូវតែលេខទូរស័ព្ទប៉ុណ្ណោះ',
      'groupNameHint': 'ឈ្មោះក្រុម (ឧ. គ្រួសារសុខហេង)',
      'createGroup': 'បង្កើតគ្រុប',
      'membersLabel': 'សមាជិក',
      'add': 'បន្ថែម',
      'noMembersYetMsg': 'មិនទាន់មានសមាជិកទេ បន្ថែមសមាជិកគ្រួសារដើម្បីកក់ការធ្វើដំណើរឲ្យពួកគេ',
      'membersCountSuffix': 'សមាជិក',
      'fromFamilyGroupQuestionSuffix': 'ចេញពីក្រុមគ្រួសារឬ?',
      'hasAutorideAccountLabel': 'មានគណនី រទេះអេប',
      'bookLabel': 'កក់',
      'addFamilyMemberTitle': 'បន្ថែមសមាជិកគ្រួសារ',
      'fullNameStarHint': 'ឈ្មោះពេញ *',
      'phoneNumberStarHint': 'លេខទូរស័ព្ទ *',
      'relationshipHint': 'ទំនាក់ទំនង (ឧ. ម្តាយ, មិត្តភក្តិ…)',
      'addMemberBtn': 'បន្ថែមសមាជិក',
      'fullNameHint': 'ឈ្មោះពេញ',
      'phoneNumberHint2': 'លេខទូរស័ព្ទ',
      'mother': 'ម្តាយ',
      'father': 'ឪពុក',
      'spouse': 'ប្តី/ប្រពន្ធ',
      'son': 'កូនប្រុស',
      'daughter': 'កូនស្រី',
      'sibling': 'បងប្អូន',
      'friend': 'មិត្តភក្តិ',
      // ── loyalty_screen ──
      'rotehRewardsTitle': 'រង្វាន់ ROTEH',
      'redeemPointsTitle': 'ដោះដូរពិន្ទុ',
      'redeem500ptsQuestion': 'ដោះដូរពិន្ទុ ៥០០ សម្រាប់ការបញ្ចុះតម្លៃ ៥.០០០ ៛ លើការធ្វើដំណើរបន្ទាប់របស់អ្នក?',
      'pts500Redeemed': 'បានដោះដូរពិន្ទុ ៥០០! ការបញ្ចុះតម្លៃត្រូវបានអនុវត្តទៅលើការធ្វើដំណើរបន្ទាប់',
      'redeem500pts': 'ដោះដូរពិន្ទុ ៥០០',
      'rotehPointsLabel': 'ពិន្ទុ ROTEH',
      'ptsSuffix': 'ពិន្ទុ',
      'maxTierReached': 'បានឈានដល់កម្រិតខ្ពស់បំផុត',
      'ptsToPlatinumSuffix': 'ពិន្ទុទៅដល់កម្រិត Platinum',
      'ptsToGoldSuffix': 'ពិន្ទុទៅដល់កម្រិត Gold',
      'ptsToSilverSuffix': 'ពិន្ទុទៅដល់កម្រិត Silver',
      'membershipTiersTitle': 'កម្រិតសមាជិកភាព',
      'currentBadge': 'បច្ចុប្បន្ន',
      'howToEarnTitle': 'របៀបទទួលបានពិន្ទុ',
      'pointsActivityTitle': 'សកម្មភាពពិន្ទុ',
      'bronzeTier': 'Bronze',
      'silverTier': 'Silver',
      'goldTier': 'Gold',
      'platinumTier': 'Platinum',
      'ptsPer1000Spent10': '១០ ពិន្ទុក្នុងរាល់ ១.០០០ ៛ ចំណាយ',
      'birthdayBonus100pts': 'ប្រាក់រង្វាន់ថ្ងៃកំណើត ១០០ ពិន្ទុ',
      'basicSupport': 'ជំនួយមូលដ្ឋាន',
      'ptsPer1000Spent12': '១២ ពិន្ទុក្នុងរាល់ ១.០០០ ៛ ចំណាយ',
      'priorityMatching': 'ការផ្គូផ្គងអាទិភាព',
      'fareDiscount5pct': 'បញ្ចុះតម្លៃ ៥% លើថ្លៃធ្វើដំណើរ',
      'ptsPer1000Spent15': '១៥ ពិន្ទុក្នុងរាល់ ១.០០០ ៛ ចំណាយ',
      'fareDiscount10pct': 'បញ្ចុះតម្លៃ ១០% លើថ្លៃធ្វើដំណើរ',
      'freeCancellation3perMo': 'លុបចោលដោយឥតគិតថ្លៃ ×៣/ខែ',
      'ptsPer1000Spent20': '២០ ពិន្ទុក្នុងរាល់ ១.០០០ ៛ ចំណាយ',
      'fareDiscount15pct': 'បញ្ចុះតម្លៃ ១៥% លើថ្លៃធ្វើដំណើរ',
      'dedicatedSupportLine': 'ខ្សែជំនួយពិសេស',
      'freeCancellationUnlimited': 'លុបចោលដោយឥតគិតថ្លៃគ្មានកំណត់',
      'completeATrip': 'បញ្ចប់ការធ្វើដំណើរ',
      'ptsPer1000Simple10': '១០ ពិន្ទុក្នុងរាល់ ១.០០០ ៛',
      'rateYourDriver': 'វាយតម្លៃអ្នកបើកបររបស់អ្នក',
      'ptsBonus50': 'ប្រាក់រង្វាន់ ៥០ ពិន្ទុ',
      'referAFriend': 'ណែនាំមិត្តភក្តិ',
      'ptsPerReferral500': '៥០០ ពិន្ទុ',
      'pointsFallback': 'ពិន្ទុ',
      // ── my_rentals_screen ──
      'noRentalsFound': 'រកមិនឃើញការជួលទេ',
      'orderHashPrefix': 'ការបញ្ជាទិញ #',
      'rentalHashPrefix': 'ការជួល #',
      'rentalVehicleBadge': 'យានជំនិះជួល',
      'cancelRentalTitle': 'លុបចោលការជួល',
      'cancelRentalConfirmMsg': 'តើអ្នកប្រាកដថាចង់លុបចោលការជួលនេះឬ?',
      'yesCancelBtn': 'បាទ/ចាស លុបចោល',
      'electricVehicleLabel': 'យានជំនិះអគ្គិសនី',
      // ── notifications_screen ──
      'justNow': 'អម្បាញ់មិញ',
      'minAgoSuffix': 'នាទីមុន',
      'hrsAgoSuffix': 'ម៉ោងមុន',
      'daysAgoSuffix': 'ថ្ងៃមុន',
      'markAllRead': 'សម្គាល់ថាបានអានទាំងអស់',
      'noNotificationsYet': 'មិនទាន់មានការជូនដំណឹងទេ',
      'notificationFallback': 'ការជូនដំណឹង',
      // ── payment_methods_screen ──
      'cardsSection': 'កាត',
      'noCardsAddedYet': 'មិនទាន់មានកាតត្រូវបានបន្ថែមទេ',
      'linkedAccountsSection': 'គណនីភ្ជាប់',
      'addMethodLabel': 'បន្ថែមវិធីបង់ប្រាក់',
      'defaultBadge': 'លំនាំដើម',
      'setAsDefaultOption': 'កំណត់ជាលំនាំដើម',
      'removeOption': 'លុប',
      'unlinkOption': 'ផ្តាច់ភ្ជាប់',
      'linkedLabel': 'បានភ្ជាប់',
      'notLinkedLabel': 'មិនទាន់ភ្ជាប់',
      'addPaymentMethodTitle': 'បន្ថែមវិធីបង់ប្រាក់',
      'cardOptionLabel': 'កាត',
      'cardOptionSubtitle': 'VISA, Mastercard, PayPal',
      'alreadyLinked': 'បានភ្ជាប់រួចហើយ',
      'linkYourAbaAccount': 'ភ្ជាប់គណនី ABA របស់អ្នក',
      'linkYourAcledaAccount': 'ភ្ជាប់គណនី ACLEDA របស់អ្នក',
      'cardNumberLabel': 'លេខកាត',
      'expiryDateLabel': 'ថ្ងៃផុតកំណត់',
      'cvvLabel': 'CVV',
      'setAsDefaultSwitch': 'កំណត់ជាលំនាំដើម',
      'addCardBtn': 'បន្ថែមកាត',
      'phoneNumberHintExample': 'ឧ. ០១២ ៣៤៥ ៦៧៨',
      'linkAccountBtn': 'ភ្ជាប់គណនី',
      'linkAbaPayTitle': 'ភ្ជាប់ ABA Pay',
      'linkAcledaPayTitle': 'ភ្ជាប់ ACLEDA Pay',
      'enterValidCardNumber': 'សូមបញ្ចូលលេខកាតត្រឹមត្រូវ',
      'enterExpiryMMYY': 'សូមបញ្ចូលថ្ងៃផុតកំណត់ជា ខែ/ឆ្នាំ (MM/YYYY)',
      'cardExpiredError': 'កាតនេះបានផុតកំណត់',
      'enterValidCvv': 'សូមបញ្ចូល CVV ត្រឹមត្រូវ',
      'expiresPrefix': 'ផុតកំណត់',
      'minOrderPrefix': 'កម្រិតអប្បបរមា',
      'byCodeTab': 'តាមកូដ',
      'byRotehPayTab': 'តាម ROTEH Pay',
      'payWithRotehPay': 'បង់ប្រាក់ដោយ ROTEH Pay',
      'enterAccountPhoneNumber': 'សូមបញ្ចូលលេខទូរស័ព្ទគណនី',
      // ── promo_screen ──
      'promosTabLabel': 'ប្រូម៉ូសិន',
      'storeTabLabel': 'ហាង',
      'myVouchersTabLabel': 'គូប៉ុងរបស់ខ្ញុំ',
      'enterPromoCodeTitle': 'បញ្ចូលកូដប្រូម៉ូសិន',
      'codeHintExample': 'ឧ. ROTEH15',
      'invalidExpiredPromoCode': 'កូដប្រូម៉ូសិនមិនត្រឹមត្រូវ ឬបានផុតកំណត់',
      'couldNotValidateCode': 'មិនអាចផ្ទៀងផ្ទាត់កូដបានទេ សូមព្យាយាមម្តងទៀត',
      'discountAppliedFallback': 'ការបញ្ចុះតម្លៃត្រូវបានអនុវត្ត',
      'offSuffix': 'បញ្ចុះតម្លៃ',
      'promoAppliedDashPrefix': 'ប្រូម៉ូសិន',
      'appliedDashSuffix': 'ត្រូវបានអនុវត្ត —',
      'codeCopiedPrefix': 'កូដ',
      'copiedSuffix': 'បានចម្លង!',
      'availableVouchersTitle': 'គូប៉ុងដែលមាន',
      'noExpiry': 'គ្មានកាលបរិច្ឆេទផុតកំណត់',
      'promo1Title': 'បញ្ចុះតម្លៃ ៥០% លើការធ្វើដំណើរដំបូង',
      'promo1Desc': 'សម្រាប់តែអ្នកប្រើប្រាស់ថ្មីប៉ុណ្ណោះ បញ្ចុះតម្លៃអតិបរមា ៥ដុល្លារ',
      'promo2Title': 'បញ្ចុះតម្លៃ ១៥% លើការធ្វើដំណើរណាមួយ',
      'promo2Desc': 'ប្រើប្រាស់បានគ្រប់ពេល ថ្លៃអប្បបរមា ៣ដុល្លារ',
      'promo3Title': 'បញ្ចុះតម្លៃ ១ដុល្លារ លើការដឹកជញ្ជូន',
      'promo3Desc': 'អាចប្រើបានចំពោះការដឹកជញ្ជូនធម្មតា និងថ្ងៃតែមួយ',
      'promo4Title': 'ស្ថានីយ៍ប្តូរថ្មឥតគិតថ្លៃ',
      'promo4Desc': 'ទទួលបានទិសដៅស្ថានីយ៍កម្រិតខ្ពស់ដោយឥតគិតថ្លៃ',
      'promo5Title': 'បញ្ចុះតម្លៃ ២០% ថ្ងៃចុងសប្តាហ៍',
      'promo5Desc': 'ប្រើប្រាស់បានចាប់ពីថ្ងៃសៅរ៍ដល់អាទិត្យ បញ្ចុះតម្លៃអតិបរមា ៨ដុល្លារ',
      'freeLabel': 'ឥតគិតថ្លៃ',
      // ── qr_payment_screen ──
      'qrPaymentTitle': 'ការទូទាត់តាម QR',
      'myQrTabLabel': 'QR របស់ខ្ញុំ',
      'enterValidAmountKhr': 'សូមបញ្ចូលចំនួនទឹកប្រាក់ត្រឹមត្រូវជារៀល',
      'generateQrToReceive': 'បង្កើត QR ដើម្បីទទួលប្រាក់',
      'enterAmountShareQr': 'បញ្ចូលចំនួនទឹកប្រាក់ ហើយចែករំលែក QR ជាមួយអ្នកបង់ប្រាក់',
      'amountKhrLabel': 'ចំនួនទឹកប្រាក់ (រៀល)',
      'generatingEllipsis': 'កំពុងបង្កើត…',
      'generateQrBtn': 'បង្កើត QR',
      'qrExpired': 'QR បានផុតកំណត់',
      'waitingForPayment': 'កំពុងរង់ចាំការទូទាត់…',
      'qrReferenceCopied': 'បានចម្លងលេខយោង QR',
      'newQrBtn': 'QR ថ្មី',
      'noQrPaymentHistory': 'គ្មានប្រវត្តិការទូទាត់ QR ទេ',
      'paidStatus': 'បានទូទាត់',
      // ── rate_driver_screen ──
      'rateYourTripTitle': 'វាយតម្លៃការធ្វើដំណើររបស់អ្នក',
      'howWasYourTripQuestion': 'តើការធ្វើដំណើររបស់អ្នកយ៉ាងម៉េចដែរ?',
      'tapToRate': 'ចុចដើម្បីវាយតម្លៃ',
      'ratingTerrible': 'អាក្រក់ណាស់',
      'ratingBad': 'អាក្រក់',
      'ratingOkay': 'មធ្យម',
      'ratingGood': 'ល្អ',
      'ratingExcellent': 'ល្អបំផុត!',
      'whatDidYouLoveQuestion': 'តើអ្នកចូលចិត្តអ្វី?',
      'whatWentWrongQuestion': 'តើមានបញ្ហាអ្វីកើតឡើង?',
      'addCommentOptionalHint': 'បន្ថែមមតិយោបល់ (ស្រេចចិត្ត)...',
      'addATipQuestion': 'បន្ថែមទឹកតែ?',
      'noTipLabel': 'គ្មានទឹកតែ',
      'tipFailedPrefix': 'ការផ្តល់ទឹកតែបរាជ័យ៖',
      'submitRatingBtn': 'ដាក់ស្នើការវាយតម្លៃ',
      'thankYouExcl': 'អរគុណ!',
      'feedbackHelpsImprove': 'មតិយោបល់របស់អ្នកជួយពួកយើងកែលម្អបទពិសោធន៍សម្រាប់អ្នកគ្រប់គ្នា',
      'greatDrivingTag': 'បើកបរល្អ',
      'veryFriendlyTag': 'រួសរាយណាស់',
      'cleanCarTag': 'រថយន្តស្អាត',
      'onTimeTag': 'ត្រូវពេលវេលា',
      'safeRideTag': 'ការធ្វើដំណើរមានសុវត្ថិភាព',
      'latePickupTag': 'ការមកទទួលយឺត',
      'rudeTag': 'គ្មានសុជីវធម៌',
      'unsafeDrivingTag': 'បើកបរគ្មានសុវត្ថិភាព',
      'dirtyCarTag': 'រថយន្តកខ្វក់',
      'wrongRouteTag': 'ខុសផ្លូវ',
      // ── referral_screen ──
      'referralTitle': 'ការណែនាំ',
      'copiedExcl': 'បានចម្លង!',
      'shareAndEarn': 'ចែករំលែក និងទទួលបាន',
      'giveFriendsDiscountDesc': 'ផ្តល់ការបញ្ចុះតម្លៃ ១០.០០០ ៛ ដល់មិត្តភក្តិសម្រាប់ការធ្វើដំណើរដំបូងរបស់ពួកគេ\nអ្នកនឹងទទួលបាន ៥០០ ពិន្ទុសម្រាប់ការណែនាំម្នាក់ៗ',
      'yourReferralCode': 'កូដណែនាំរបស់អ្នក',
      'shareWithFriends': 'ចែករំលែកជាមួយមិត្តភក្តិ',
      'friendsReferred': 'មិត្តភក្តិដែលបានណែនាំ',
      'pointsEarnedLabel': 'ពិន្ទុទទួលបាន',
      'friendsWhoJoined': 'មិត្តភក្តិដែលបានចូលរួម',
      'joinedPrefix': 'បានចូលរួម',
      'joinRotehWithCodePrefix': 'ចូលរួម ROTEH ជាមួយកូដរបស់ខ្ញុំ៖',
      'get10000OffFirstRideSuffix': 'ហើយទទួលបានការបញ្ចុះតម្លៃ ១០.០០០ ៛ លើការធ្វើដំណើរដំបូងរបស់អ្នក!',
      'downloadRotehNow': 'ទាញយក ROTEH ឥលូវនេះ',
      // ── safety_screen ──
      'safetyCenterTitle': 'មជ្ឈមណ្ឌលសុវត្ថិភាព',
      'emergencySosLabel': 'SOS បន្ទាន់',
      'holdToActivate': 'សង្កត់រយៈពេល ១ វិនាទីដើម្បីធ្វើឲ្យសកម្ម',
      'fakeCallLabel': 'ការហៅក្លែងក្លាយ',
      'stopSharingLabel': 'បញ្ឈប់ការចែករំលែក',
      'reportLabel': 'រាយការណ៍',
      'emergencyContactsTitle': 'ទំនាក់ទំនងបន្ទាន់',
      'noEmergencyContactsYet': 'មិនទាន់មានទំនាក់ទំនងបន្ទាន់ទេ',
      'safetyResourcesTitle': 'ធនធានសុវត្ថិភាព',
      'emergencyPhoneNumbers': 'បន្ទាន់៖ ១១៧ / ១១៩',
      'reportIncidentLabel': 'រាយការណ៍ឧប្បត្តិហេតុ',
      'safetyGuidelinesLabel': 'គោលការណ៍ណែនាំសុវត្ថិភាព',
      'sosSentToPrefix': '🆘 SOS ត្រូវបានផ្ញើទៅកាន់',
      'contactsSuffix': 'ទំនាក់ទំនង',
      'noActiveRideToShare': 'គ្មានការធ្វើដំណើរសកម្មដើម្បីចែករំលែកទេ',
      'sharingStopped': 'បានបញ្ឈប់ការចែករំលែក',
      'tripLinkSharedTitle': 'តំណភ្ជាប់ការធ្វើដំណើរត្រូវបានចែករំលែក',
      'shareLinkTrackDesc': 'ចែករំលែកតំណភ្ជាប់នេះ ដើម្បីឲ្យអ្នកដទៃអាចតាមដានការធ្វើដំណើររបស់អ្នកតាមពេលវេលាជាក់ស្តែង',
      'sosWillBeSentNoContacts': 'សារ SOS នឹងត្រូវបានផ្ញើភ្លាមៗ មិនទាន់មានទំនាក់ទំនងបន្ទាន់ត្រូវបានបន្ថែមទេ',
      'sosWillBeSentToContactsPrefix': 'SOS នឹងត្រូវបានផ្ញើទៅកាន់',
      'emergencyContactsImmediatelySuffix': 'ទំនាក់ទំនងបន្ទាន់ភ្លាមៗ',
      'harassmentTag': 'ការបំពាន',
      'unsafeDrivingTitleTag': 'បើកបរគ្មានសុវត្ថិភាព',
      'overchargeTag': 'គិតថ្លៃលើស',
      'otherTag': 'ផ្សេងទៀត',
      'describeWhatHappenedHint': 'ពិពណ៌នាអំពីអ្វីដែលបានកើតឡើង…',
      'submitReportBtn': 'ដាក់ស្នើរបាយការណ៍',
      'incidentReportedThanks': 'ឧប្បត្តិហេតុត្រូវបានរាយការណ៍ សូមអរគុណ',
      'addEmergencyContactTitle': 'បន្ថែមទំនាក់ទំនងបន្ទាន់',
      'relationshipHintExample': 'ទំនាក់ទំនង (ឧ. ម្តាយ)',
      'notifyOnSos': 'ជូនដំណឹងពេលមាន SOS',
      'notifyOnTripShare': 'ជូនដំណឹងពេលចែករំលែកការធ្វើដំណើរ',
      'addContactBtn': 'បន្ថែមទំនាក់ទំនង',
      'contactAddedExcl': 'បានបន្ថែមទំនាក់ទំនង!',
      'editContactTitle': 'កែសម្រួលទំនាក់ទំនង',
      'contactUpdatedExcl': 'ទំនាក់ទំនងត្រូវបានធ្វើបច្ចុប្បន្នភាព!',
      'removeContactQuestion': 'លុបទំនាក់ទំនងឬ?',
      'willBeRemovedFromContactsSuffix': 'នឹងត្រូវបានលុបចេញពីទំនាក់ទំនងបន្ទាន់របស់អ្នក',
      'contactRemoved': 'ទំនាក់ទំនងត្រូវបានលុប',
      'sosTagLabel': 'SOS',
      'tripShareTagLabel': 'ចែករំលែកការធ្វើដំណើរ',
      'fakeCallChooseDelayTitle': 'ការហៅក្លែងក្លាយ — ជ្រើសរើសពេលរង់ចាំ',
      'phoneWillRingDesc': 'ទូរស័ព្ទរបស់អ្នកនឹងរោទ៍បន្ទាប់ពីពេលរង់ចាំដែលបានជ្រើសរើស',
      'nowSecLabel': 'ឥលូវនេះ (៥ វិនាទី)',
      'inSecLabel10': 'ក្នុងរយៈពេល ១០ វិនាទី',
      'inSecLabel30': 'ក្នុងរយៈពេល ៣០ វិនាទី',
      'inMinLabel1': 'ក្នុងរយៈពេល ១ នាទី',
      'incomingCallEllipsis': 'ការហៅចូល…',
      'fakeCallInPrefix': 'ការហៅក្លែងក្លាយក្នុងរយៈពេល',
      'secondsSuffix': 'វិនាទី…',
      // ── saved_places_screen ──
      'deletePlaceQuestion': 'លុបទីតាំងនេះឬ?',
      'removePlacePrefix': 'លុប',
      'fromSavedPlacesQuestionSuffix': 'ចេញពីទីតាំងដែលបានរក្សាទុករបស់អ្នកឬ?',
      'removedSuffix': 'ត្រូវបានលុប',
      'addHomeLabel': 'បន្ថែមផ្ទះ',
      'addWorkLabel': 'បន្ថែមកន្លែងធ្វើការ',
      'yourPlacesLabel': 'ទីតាំងរបស់អ្នក',
      'saveHomeWorkDesc': 'រក្សាទុកផ្ទះ ការងារ ឬកន្លែងសំណព្វ\nសម្រាប់ការកក់លឿនជាងមុន',
      'addAPlaceBtn': 'បន្ថែមទីតាំង',
      'editPlaceTitle': 'កែសម្រួលទីតាំង',
      'addPlaceTitle': 'បន្ថែមទីតាំង',
      'labelHintExample': 'ផ្ទះ ការងារ កន្លែងហាត់ប្រាណ…',
      'openingMapEllipsis': 'កំពុងបើកផែនទី…',
      'searchOrDragPinHint': 'ស្វែងរក ឬអូសម្ជុលលើផែនទី',
      'setAsDefaultCheckbox': 'កំណត់ជាលំនាំដើម',
      'labelAndLocationRequired': 'ត្រូវការស្លាក និងទីតាំង',
      'setLocationTitle': 'កំណត់ទីតាំង',
      'labelFieldTitle': 'ស្លាក',
      // ── scheduled_rides_screen ──
      'scheduledRidesTitle': 'ការធ្វើដំណើរដែលបានកំណត់ពេល',
      'pastLabel': 'កន្លងផុតទៅ',
      'inPrefix': 'ក្នុងរយៈពេល',
      'daysLabel2': 'ថ្ងៃ',
      'hrsLabel': 'ម៉ោង',
      'minLabel': 'នាទី',
      'cancelRideTitle': 'លុបចោលការធ្វើដំណើរ',
      'cancelScheduledRideConfirm': 'តើអ្នកប្រាកដថាចង់លុបចោលការធ្វើដំណើរដែលបានកំណត់ពេលនេះឬ?',
      'keepLabel': 'រក្សាទុក',
      'rideCancelledPeriod': 'ការធ្វើដំណើរត្រូវបានលុបចោល',
      'noUpcomingRides': 'គ្មានការធ្វើដំណើរនាពេលខាងមុខទេ',
      'scheduleRideToSeeHere': 'កំណត់ពេលការធ្វើដំណើរដើម្បីមើលវានៅទីនេះ',
      'modifyComingSoon': 'ការកែប្រែនឹងមកដល់ឆាប់ៗនេះ',
      'modifyBtn': 'កែប្រែ',
      'jan': 'មករា', 'feb': 'កុម្ភៈ', 'mar': 'មីនា', 'apr': 'មេសា',
      'may': 'ឧសភា', 'jun': 'មិថុនា', 'jul': 'កក្កដា', 'aug': 'សីហា',
      'sep': 'កញ្ញា', 'oct': 'តុលា', 'nov': 'វិច្ឆិកា', 'dec': 'ធ្នូ',
      // ── subscription_screen ──
      'subscriptionPlansTitle': 'គម្រោងជាវសមាជិកភាព',
      'plansTab': 'គម្រោង',
      'upgradeToPrefix': 'ដំឡើងកម្រិតទៅ',
      'subscribeToPrefix': 'ជាវ',
      'paymentColonPrefix': 'ការទូទាត់៖',
      'upgradeBtn': 'ដំឡើងកម្រិត',
      'subscribeBtn': 'ជាវ',
      'cancelSubscriptionQuestion': 'លុបចោលការជាវសមាជិកភាព?',
      'benefitsContinueDesc': 'អត្ថប្រយោជន៍បន្តរហូតដល់គម្រោងរបស់អ្នកផុតកំណត់ ការបន្តដោយស្វ័យប្រវត្តិនឹងត្រូវបានបិទ',
      'cancelPlanBtn': 'លុបចោលគម្រោង',
      'autoRideWalletLabel': 'កាបូប រទេះអេប',
      'creditDebitCardLabel': 'កាតឥណទាន/ឥណពន្ធ',
      'cardLabel': 'កាត',
      'changePlanLabel': 'ប្តូរគម្រោង',
      'choosePlanLabel': 'ជ្រើសរើសគម្រោង',
      'rideCreditLabel': 'ឥណទានធ្វើដំណើរ',
      'leftSuffix': 'នៅសល់',
      'cancellationsLeftLabel': 'ការលុបចោលនៅសល់',
      'autoRenewLabel': 'បន្តដោយស្វ័យប្រវត្តិ',
      'creditSuffix': 'ឥណទាន',
      'offRidesSuffix': 'បញ្ចុះលើការធ្វើដំណើរ',
      'offDeliverySuffix': 'បញ្ចុះលើការដឹកជញ្ជូន',
      'noSurgeLabel': 'គ្មានតម្លៃកើនឡើង',
      'freeCancellationsPerMonthSuffix': 'ការលុបចោលឥតគិតថ្លៃ / ខែ',
      'bonusLoyaltyPointsSuffix': 'ពិន្ទុភក្តីភាពបន្ថែម',
      'currentPlanBtn': 'គម្រោងបច្ចុប្បន្ន',
      'noBillingHistoryYet': 'មិនទាន់មានប្រវត្តិការទូទាត់ទេ',
      'newSubscriptionLabel': 'ការជាវថ្មី',
      'renewalLabel': 'ការបន្ត',
      'cancellationLabel': 'ការលុបចោល',
      // ── support_screen ──
      'myTicketsTab': 'សំបុត្ររបស់ខ្ញុំ',
      'faqTab': 'សំណួរញឹកញាប់',
      'noSupportTickets': 'គ្មានសំបុត្រជំនួយទេ',
      'tapPlusToCreateTicket': 'ចុច + ដើម្បីបង្កើតសំណើជំនួយថ្មី',
      'openParenPrefix': 'កំពុងបើក',
      'resolvedParenPrefix': 'បានដោះដូរស្រាយ',
      'repliesCountLabel': 'ការឆ្លើយតប',
      'dAgoSuffix': 'ថ្ងៃមុន',
      'hAgoSuffix': 'ម៉ោងមុន',
      'mAgoSuffix': 'នាទីមុន',
      'needHelpTitle': 'ត្រូវការជំនួយ?',
      'cantFindAnswerDesc': 'រកមិនឃើញចម្លើយរបស់អ្នក? បើកសំបុត្រថ្មី',
      'subjectAndMessageRequired': 'ត្រូវការប្រធានបទ និងសារ',
      'newSupportTicketTitle': 'សំបុត្រជំនួយថ្មី',
      'priorityColonLabel': 'អាទិភាព៖',
      'highPriority': 'ខ្ពស់',
      'urgentPriority': 'បន្ទាន់',
      'subjectLabel': 'ប្រធានបទ',
      'describeYourIssueLabel': 'ពិពណ៌នាបញ្ហារបស់អ្នក',
      'submitTicketBtn': 'ដាក់សំបុត្រស្នើជំនួយ',
      'noRepliesYetDesc': 'មិនទាន់មានការឆ្លើយតបទេ យើងនឹងឆ្លើយតបក្នុងរយៈពេល ២៤ម៉ោង',
      'writeAReplyHint': 'សរសេរការឆ្លើយតប…',
      'supportTeamLabel': 'ក្រុមជំនួយ',
      'faq1Q': 'តើខ្ញុំកក់ការធ្វើដំណើរដោយរបៀបណា?',
      'faq1A': 'បើកកម្មវិធី ចុចកក់ការធ្វើដំណើរ កំណត់ទីតាំងទទួល និងទិសដៅ រួចបញ្ជាក់',
      'faq2Q': 'តើខ្ញុំលុបចោលការធ្វើដំណើរដោយរបៀបណា?',
      'faq2A': 'អំឡុងពេលកក់ អ្នកអាចចុចលុបចោលនៅលើអេក្រង់តាមដាន ថ្លៃលុបចោលអាចត្រូវអនុវត្តបន្ទាប់ពីអ្នកបើកបរកំពុងធ្វើដំណើរមកជួប',
      'faq3Q': 'តើការទូទាត់ដំណើរការយ៉ាងណា?',
      'faq3A': 'យើងទទួលសាច់ប្រាក់ និងកាបូបអេឡិចត្រូនិក ជ្រើសរើសវិធីរបស់អ្នកមុនពេលបញ្ជាក់ការកក់',
      'faq4Q': 'តើខ្ញុំរាយការណ៍បញ្ហាដោយរបៀបណា?',
      'faq4A': 'បង្កើតសំបុត្រជំនួយដោយចុចប៊ូតុង + ខាងលើ ក្រុមរបស់យើងនឹងឆ្លើយតបក្នុងរយៈពេល ២៤ម៉ោង',
      'faq5Q': 'តើ រទេះអេប ដំណើរការនៅទីណា?',
      'faq5A': 'បច្ចុប្បន្នមានសេវានៅទូទាំងភ្នំពេញ ប្រទេសកម្ពុជា',
      'faq6Q': 'តើខ្ញុំក្លាយជាអ្នកបើកបរដោយរបៀបណា?',
      'faq6A': 'ចុះឈ្មោះជាមួយតួនាទី "អ្នកបើកបរ" បំពេញការផ្ទៀងផ្ទាត់ រួចចុះឈ្មោះយានជំនិះរបស់អ្នក',
      'faq7Q': 'ចុះបើអ្នកបើកបរមិនមកទេ?',
      'faq7A': 'ប្រើប៊ូតុង SOS ឬទាក់ទងនៅលើអេក្រង់តាមដាន ឬលុបចោល ហើយកក់ម្តងទៀត',
      // ── trip_history_screen ──
      'tripTitle': 'ការធ្វើដំណើរ',
      'spentLabel': 'បានចំណាយ',
      'noTripsFound': 'រកមិនឃើញការធ្វើដំណើរទេ',
      'byDayLabel': 'តាមថ្ងៃ',
      'filterTripsTitle': 'តម្រងការធ្វើដំណើរ',
      'resetLabel': 'កំណត់ឡើងវិញ',
      'applyFiltersBtn': 'អនុវត្តតម្រង',
      'allTripsLabel': 'ការធ្វើដំណើរទាំងអស់',
      'tipSuffix2': 'ធីប',
      'thisTripNoDestinationRebook': 'ការធ្វើដំណើរនេះគ្មានទិសដៅ - កក់ម្តងទៀត ',
      'bookAgainBtn': 'កក់ម្តងទៀត',
      'rateBtn': 'វាយតម្លៃ',
      // ── voucher_screen ──
      'vouchersTitle': 'គូប៉ុង',
      'voucherClaimedCheckMy': 'បានទទួលគូប៉ុង! ពិនិត្យមើលគូប៉ុងរបស់ខ្ញុំ',
      'noVouchersAvailable': 'គ្មានគូប៉ុងទេ',
      'claimBtn': 'ទទួល',
      'noVouchersYet': 'មិនទាន់មានគូប៉ុងទេ',
      'claimFromStoreTab': 'ទទួលពីផ្ទាំងហាង',
      'usedBadge': 'បានប្រើ',
      'usedBadgeCap': 'បានប្រើ',
      'expPrefix': 'ផុតកំណត់',
      'voucherFallback': 'គូប៉ុង',
      // ── business_screen ──
      'tabAccount': 'គណនី',
      'tabMembers': 'សមាជិក',
      'registerABusiness': 'ចុះឈ្មោះអាជីវកម្ម',
      'joinWithInviteCode': 'ចូលរួមជាមួយកូដអញ្ជើញ',
      'joinBusinessAccount': 'ចូលរួមគណនីអាជីវកម្ម',
      'inviteCodeHint': 'កូដអញ្ជើញ (ឧ. ABC12345)',
      'joinBusiness': 'ចូលរួមអាជីវកម្ម',
      'registerBusiness': 'ចុះឈ្មោះអាជីវកម្ម',
      'companyNameRequiredHint': 'ឈ្មោះក្រុមហ៊ុន *',
      'taxIdHint': 'លេខសម្គាល់ពន្ធ / VAT',
      'industryHint': 'វិស័យ',
      'contactPerson': 'អ្នកទំនាក់ទំនង',
      'contactNameRequiredHint': 'ឈ្មោះអ្នកទំនាក់ទំនង *',
      'contactPhoneHint': 'លេខទូរស័ព្ទទំនាក់ទំនង',
      'billingEmailRequiredHint': 'អ៊ីមែលវិក័យប័ត្រ *',
      'billingCycle': 'វដ្តវិក័យប័ត្រ',
      'companyAddressHint': 'អាសយដ្ឋានក្រុមហ៊ុន',
      'taxIdLabel': 'លេខសម្គាល់ពន្ធ',
      'billingEmailLabel': 'អ៊ីមែលវិក័យប័ត្រ',
      'billingCycleLabel': 'វដ្តវិក័យប័ត្រ',
      'contactLabel': 'អ្នកទំនាក់ទំនង',
      'addressLabel': 'អាសយដ្ឋាន',
      'inviteCodeLabel': 'លេខកូដអញ្ជើញ',
      'editAccount': 'កែសម្រួលគណនី',
      'editBusinessAccount': 'កែសម្រួលគណនីអាជីវកម្ម',
      'companyNameHint': 'ឈ្មោះក្រុមហ៊ុន',
      'billingEmailHint': 'អ៊ីមែលវិក័យប័ត្រ',
      'contactNameHint': 'ឈ្មោះអ្នកទំនាក់ទំនង',
      'addressHint': 'អាសយដ្ឋាន',
      'roleMemberAdminHint': 'តួនាទី (សមាជិក / អ្នកគ្រប់គ្រង)',
      'departmentHint': 'នាយកដ្ឋាន',
      'costCenterHint': 'មជ្ឈមណ្ឌលចំណាយ',
      'employeeIdHint': 'លេខសម្គាល់បុគ្គលិក',
      'monthlyLimitKhrHint': 'កម្រិតប្រចាំខែ (រៀល)',
      'businessTripDefault': 'ដំណើរអាជីវកម្ម',
      'weeklyLabel': 'ប្រចាំសប្តាហ៍',
      'monthlyLabel': 'ប្រចាំខែ',
      // ── settings_screen ──
      'settingsTitle': 'ការកំណត់',
      'biometricLogin': 'ចូលដោយប្រើប្រាស់េជីវមាត្រ',
      // ── onboarding_screen ──
      'next': 'បន្ទាប់',
      'getStarted': 'ចាប់ផ្តើម',
      'onboardWelcomeTitle': 'សូមស្វាគមន៍មកកាន់ រទេះអេប',
      'onboardWelcomeSubtitle': 'ការធ្វើដំណើរឆ្លាតវៃរបស់អ្នកនៅកម្ពុជា\nលឿន សុវត្ថិភាព និងតម្លៃសមរម្យ',
      'onboardBookTitle': 'កក់ក្នុងរយៈពេលប៉ុន្មានវិនាទី',
      'onboardBookSubtitle': 'ជ្រើសរើសប្រភេទយានជំនិះរបស់អ្នក — រថយន្ត ម៉ូតូ ឬតុកតុក\nទទួលបានការប៉ាន់ស្មានថ្លៃមុនពេលអ្នកបញ្ជាក់',
      'onboardPaySubtitle': 'បង់ប្រាក់ជាសាច់ប្រាក់ ឬប្រើកាបូបលុយ ROTEH Pay\nផ្ញើប្រាក់ទៅមិត្តភក្តិដោយប្រើកូដ QR',
      'onboardRewardsTitle': 'ទទួលបានរង្វាន់',
      'onboardRewardsSubtitle': 'ប្រមូល ពិន្ទុ របស់ ROTEH រាល់ដំណើរ \nឡើងពីកម្រិតសំរឹទ្ធិ ទៅដល់ ផ្លាទីន រួចនឹងទទួលអត្ថប្រយោជន៍ពិសេស',
      // ── auth_service ──
      'phoneVerificationFailedMsg': 'ការផ្ទៀងផ្ទាត់លេខទូរស័ព្ទបរាជ័យ',
      'couldNotObtainFirebaseToken': 'មិនអាចទទួលបានថូខិន Firebase ID បានទេ',
      // ── marketplace_screen ──
      'browseTab': 'រកមើល',
      'myOrdersTab': 'ការបញ្ជាទិញរបស់ខ្ញុំ',
      'popularListings': 'បញ្ជីពេញនិយម',
      'recentListings': 'បញ្ជីថ្មីៗ',
      'allListingsTitle': 'បញ្ជីទាំងអស់',
      'forSaleLabel': 'សម្រាប់លក់',
      'forRentLabel': 'សម្រាប់ជួល',
      'saleAndRentLabel': 'លក់ & ជួល',
      'listingTypeLabel': 'ប្រភេទបញ្ជី',
      'conditionNewLabel': 'ថ្មី',
      'conditionUsedLabel': 'ប្រើប្រាស់រួច',
      'conditionRefurbishedLabel': 'កែច្នៃឡើងវិញ',
      'conditionRefurbAbbrev': 'កែច្នៃ',
      'viewsCountSuffix': 'ចំនួនមើល',
      'viewsSpecLabel': 'ចំនួនមើល',
      'perDaySpecLabel': 'ក្នុងមួយថ្ងៃ',
      'buyNowLabel': 'ទិញឥលូវនេះ',
      'rentNowLabel': 'ជួលឥលូវនេះ',
      'searchLocationHint': 'ស្វែងរកទីតាំង…',
      'dragMapToSetLocation': 'អូសផែនទីដើម្បីកំណត់ទីតាំង',
      'setPickupHere': 'កំណត់ទីតាំងទទួលទីនេះ',
      'setDropoffHere': 'កំណត់ទីតាំងដាក់ចុះទីនេះ',
      'pickUpShortLabel': 'មកយកដោយខ្លួនឯង',
      'deliverCarToMyAddress': 'ដឹកជញ្ជូនមកកាន់អាសយដ្ឋានរបស់ខ្ញុំ',
      'addItemTitle': 'បន្ថែមទំនិញ',
      'searchListingsHint': 'ស្វែងរកបញ្ជី…',
      'selectRentalDatesError': 'សូមជ្រើសរើសកាលបរិច្ឆេទចាប់ផ្ដើម និងបញ្ចប់ការជួល',
      'walletLabel': 'កាបូបលុយ',
      'onlineLabel': 'លើអនឡាញ',
      'buyItemTitle': 'ទិញទំនិញ',
      'rentItemTitle': 'ជួលទំនិញ',
      'durationLabel': 'រយៈពេល',
      'selectLabel': 'ជ្រើសរើស',
      'anySpecialInstructionsHint': 'សេចក្ដីណែនាំពិសេសផ្សេងៗ…',
      'orderSummaryLabel': 'សេចក្ដីសង្ខេបការបញ្ជាទិញ',
      'vehicleLabel': 'យានជំនិះ',
      'totalSummaryLabel': 'សរុប',
      'confirmRentalLabel': 'បញ្ជាក់ការជួល',
      'selectDatesToContinue': 'ជ្រើសរើសកាលបរិច្ឆេទដើម្បីបន្ត',
      'proceedToCheckout': 'បន្តទៅការទូទាត់',
      'noListingsYetTitle': 'មិនទាន់មានបញ្ជីនៅឡើយទេ',
      'postSomethingToStartSelling': 'ផ្សាយអ្វីមួយដើម្បីចាប់ផ្ដើមលក់',
      'purchaseLabel': 'ការទិញ',
      'titleIsRequiredError': 'ត្រូវការចំណងជើង',
      'priceMustBeNumberError': 'តម្លៃត្រូវតែជាលេខ',
      'enterValidPricePrefix': 'សូមបញ្ចូលតម្លៃឱ្យបានត្រឹមត្រូវ',
      'updatedExclaim': 'បានធ្វើបច្ចុប្បន្នភាព!',
      'postedExclaim': 'បានផ្សាយ!',
      'egIphone14Pro': 'ឧ. iPhone 14 Pro',
      'egRemovableCanopy': 'ឧ. ដំបូលអាចដោះដូរចេញបាន',
      'egBkk1PhnomPenh': 'ឧ. បឹងកេងកង ទី១, ភ្នំពេញ',
      'saleTypeLabel': 'ប្រភេទលក់',
      'bothTypeLabel': 'ទាំងពីរ',
      'draftStatusLabel': 'សេចក្តីព្រាង',
      'pausedStatusLabel': 'ផ្អាក',
      'soldStatusLabel': 'លក់ហើយ',
      'postListingBtn': 'បញ្ជីផ្សាយ',
      'buyingTab': 'ការទិញ',
    },
    'zh': {
      'appName': 'ROTEH',
      'tagline': '超级应用',
      'copyright': 'រទេះអេប © 2026 — 版权所有',
      'whoAreYou': '您是谁?',
      'selectRole': '选择您的角色以继续',
      'passenger': '乘客',
      'passengerSub': '预订乘车, 送货等服务\n购买或租赁您的车辆',
      'driver': '司机',
      'driverSub': '接受行程请求, 管理\n快递业务 & 赚钱',
      'home': 'រទេះ',
      'charging': '换电',
      'chat': '聊天',
      'profile': '个人资料',
      'earnings': '收入',
      'dashboard': '仪表板',
      'bookRide': '预订行程',
      'bookRideSub': '立即或预约',
      'delivery': '送货',
      'deliverySub': '快速发送包裹',
      'marketplace': '市场',
      'marketplaceSub': '购买或租用车辆',
      'evStations': '电动汽车辆换电站',
      'evStationsSub': '查找附近换电站',
      'safety': '安全',
      'payment': '支付',
      'support': '支持',
      'recentTrips': '最近的行程',
      'seeAll': '查看全部',
      'services': '服务',
      'quickActions': '快速行动',
      'whereAreYouGoing': '您今天想去哪里？',
      'bookNow': '立即预订',
      'scheduleRide': '预约行程',
      'scheduleForLater': '稍后预订',
      'sendNow': '立即发送',
      'evChargingStations': '电动车辆换电站',
      'buy': '买',
      'rent': '租',
      'trackTrip': '追踪行程',
      'driverOnTheWay': '司机正在赶来',
      'tripInProgress': '行程进行中',
      'arrived': '司机已到达!',
      'paySecurely': '安全支付',
      'emergencySOS': '紧急求助',
      'selectLanguage': '选择语言',
      'language': '语言',
      'goodMorning': '早上好,',
      'hello': '你好',
      'welcome': '欢迎!',
      'online': '上线',
      'offline': '您离线',
      'driverDashboard': '司机仪表板',
      'messages': '消息 & 支持',
      'paymentSuccessful': '支付成功!',
      'signOut': '登出',
      'paymentMethods': '付款方式',
      'safetySettings': '安全设置',
      'tripHistory': '行程历史',
      'notifications': '通知',
      'helpSupport': '帮助 & 支持',
      'bankPayouts': '银行提现',
      'documents': '文件',
      'navigate': '导航',
      'available': '可用的',
      'connectionErrorRetry': '无法连接服务器。请检查网络连接后重试。',
      'sortBy': '排序',
      'sortNewest': '最新',
      'sortOldest': '最早',
      'sortPriceHigh': '价格：从高到低',
      'sortPriceLow': '价格：从低到高',
      'searchRentalsHint': '搜索租赁…',
      'rentalBookedSuccess': '租赁预订成功！',
      'rentalHeaderSubtitle': '填写信息以预订租赁车辆',
      'drvTopUpMsg': '您的钱包余额不足，无法上线。请至少充值 {amount} 后继续。',
      'drvShortBy': '还差 {amount}',
      'drvKmAway': '距离 {km} 公里',
      'drvEndsInHm': '{h}小时{m}分钟后结束',
      'drvEndsInMin': '{m} 分钟后结束',
      'drvTripsCount': '{n} 趟',
      'drvSurgeInside': '{x}× 高峰区 — 您在区域内！',
      'drvSurgeNearby': '附近 {x}× 高峰 — {zone}',
      'drvZone': '区域',
      'drvInactive': '未激活',
      'drvPeakExtra': '高峰时段每趟额外 {amount}',
      'drvPeakProgress': '今日已完成 {done}/{target} 趟高峰时段行程',
      'drvStreakCount': '连续 {n} 次五星好评！',
      'drvStreakRemaining': '再获 {n} 次五星 = 赚取 {amount} 奖励',
      'drvStreakUnlocked': '连续奖励已解锁 — {amount}！',
      'drvPassengerNo': '乘客 #{id}',
      'drvSenderNo': '寄件人 #{id}',
      'drvSecondsShort': '{n} 秒',
      'drvFloors': '楼层：取件 {from} → 送达 {to}',
      'drvElevator': '电梯：{v}',
      'drvHelpers': '{n} 名帮手 — {type}',
      'drvHeavyCarry': '重物搬运',
      'drvNormalCarry': '普通搬运',
      'drvWithdrawConfirm': '将全部余额提现至 {bank}？\n此请求将提交管理员审核。',
      'drvWithdrawSubmitted': '✅ 已提交 {amount} 的提现申请 — 等待管理员审核',
      'drvMinWithdrawal': '最低提现金额：{amount}',
      'drvWithdrawTo': '💸  提现 {amount} 至 {bank}',
      'drvTodaysTransactions': '今日交易',
      'drvTotalCount': '共 {n} 条',
      'drvBalanceShort': '余额：{amount}',
      'seatsCount': '{n} 个座位',
      'seatsOne': '1 个座位',
      'senderNameHint': '寄件人姓名',
      'senderPhoneHint': '寄件人电话',
      'recipientNameHint': '收件人姓名',
      'recipientPhoneHint': '收件人电话',
      'floorsPickupDropoff': '取件：{from}  •  送达：{to}',
      'packageAmountHint': '包裹价值（៛，可选）',
      'packageAmount': '包裹金额',
      'deliveryFee': '配送费',
      'serviceFee': '服务费',
      'pickup': '取件',
      'completedAt': '完成时间',
      'completionTime': '完成用时',
      'deliveryCompleted': '配送已完成',
      'deliveryReceipt': '配送收据',
      'deliverySummary': '配送摘要',
      'viewDeliverySummary': '查看配送摘要',
      'feePaidBy': '费用支付方',
      'paidBySender': '由寄件人支付',
      'paidByRecipient': '由收件人支付',
      'guestOtpReason': '请验证您的电话号码以提交此订单。',
      'confirmOtpTitle': '确认验证码',
      'otpSentToYourPhone': '我们已向您的手机发送 6 位验证码',
      'didntReceiveCode': '没有收到验证码？',
      'resendShort': '重新发送',
      'guestPhoneStarHint': '电话号码 *（例如 012 345 678）',
      'guestFullNameRequired': '请输入您的全名。',
      'guestPhoneInvalid': '请输入有效的电话号码（8–16 位数字）。',
      'guestPhoneNotVerified': '请使用短信验证码验证您的电话号码。',
      'guestOtpNote': '我们将发送短信验证码以验证此号码。',
      'regJoinTitle': '加入 ROTEH',
      'regTagline': '柬埔寨快速、安全的出行',
      'regIWantTo': '我想要',
      'regRideAsPassenger': '作为乘客出行',
      'regDriveAndEarn': '驾驶赚钱',
      'regOwner': '车主',
      'regSelectCity': '选择您的城市',
      'regCityRequired': '请选择城市',
      'regNameRequired': '请输入姓名',
      'regEmailRequired': '请输入邮箱',
      'regEmailInvalid': '请输入有效的邮箱',
      'regPhoneOptional': '电话（可选）',
      'regPasswordMin': '至少 8 个字符',
      'regPasswordMismatch': '两次输入的密码不一致',
      'regReferralOptional': '推荐码（可选）',
      'regRegisterUpload': '注册并上传证件',
      'cityPhnomPenh': '金边',
      'citySiemReap': '暹粒',
      'citySihanoukville': '西哈努克',
      'cityBattambang': '马德望',
      'cityKampongCham': '磅湛',
      'cityKampot': '贡布',
      'cityKep': '白马',
      'cityPoipet': '波贝',
      'chatsTab': '聊天',
      'noConversationsYet': '暂无对话',
      'driverMessagesHint': '与司机的消息将显示在这里',
      'rotehSupport': 'ROTEH 客服',
      'chatWithOurTeam': '与我们的团队聊天',
      'noMessagesSayHello': '暂无消息，打个招呼吧！',
      'typeAMessageHint': '输入消息...',
      'howCanWeHelp': '我们能帮您什么？',
      'searchForHelp': '搜索帮助...',
      'quickHelp': '快速帮助',
      'qhDriverLate': '我的司机迟到了',
      'qhOvercharged': '我被多收费了',
      'qhLostItem': '物品遗失在车内',
      'qhSafetyIssue': '报告安全问题',
      'qhCancelTrip': '取消我的行程',
      'support247': '24/7 客服',
      'openTicketReplyHere': '提交工单，我们的团队会在这里回复',
      'chatNow': '立即聊天',
      'supportRepliesSoon': '打个招呼吧！我们的团队通常会在几分钟内回复。',
      'uploadFromGallery': '从相册上传',
      'couldNotSendPhoto': '无法发送照片：{error}',
      'couldNotLoadMessages': '无法加载消息：{error}',
      'missedRequestsTitle': '未接请求',
      'missedTab': '未接',
      'declinedTab': '已拒绝',
      'reasonMissed': '未及时响应',
      'reasonDeclined': '您已拒绝',
      'outcomeOpen': '仍可接单',
      'outcomeTaken': '已被其他司机接单',
      'outcomeCancelled': '已取消',
      'noMissedRequests': '没有未接请求',
      'missedRequestsHint': '您拒绝或未及时响应的请求会显示在这里。',
      'trRemove': '移除',
      'trSwitch': '切换',
      'trAccount': '账户',
      'trBack': '返回',
      'trSave': '保存',
      'trDelete': '删除',
      'trEdit': '编辑',
      'trApprove': '批准',
      'trReject': '拒绝',
      'trApproved': '已批准',
      'trRejected': '已拒绝',
      'trPending': '待处理',
      'trActive': '启用',
      'trInactive': '停用',
      'trTitle': '标题',
      'trRefresh': '刷新',
      'trSignOut': '退出登录',
      'trUnknown': '未知',
      'trSearch': '搜索',
      'trMap': '地图',
      'trView': '查看',
      'trNow': '现在',
      'trJustNow': '刚刚',
      'trMinutesAgo': '{n} 分钟前',
      'trHoursAgo': '{n} 小时前',
      'trDaysAgo': '{n} 天前',
      'trMinAgoLong': '{n} 分钟前',
      'trHrsAgoLong': '{n} 小时前',
      'trDaysAgoLong': '{n} 天前',
      'trTodayAt': '今天 {time}',
      'trPerDay': '/天',
      'trTryAgain': '重试',
      'trProcessing': '处理中…',
      'trCustomerNo': '客户 #{id}',
      'trDriverNo': '司机 #{id}',
      'trRideNo': '行程 #{id}',
      'trStopN': '停靠点 {n}',
      'trStopWithAddress': '停靠点 {n}：{address}',
      'trStopDestination': '停靠点 {n} — 目的地',
      'trStopDistance': '停靠点 {n} · {km} 公里',
      'trDistanceKm': '距离（{km} 公里）',
      'trPromoWithCode': '优惠（{code}）',
      'trYouEarned': '您赚取了 {amount}',
      'trEtaMin': '预计 {n} 分钟',
      'trFromPlace': '从：{place}',
      'trToPlace': '到：{place}',
      'trFareKhr': '车费：{amount} ៛',
      'trCar': '汽车',
      'trBike': '摩托车',
      'trTukTuk': '嘟嘟车',
      'trVan': '面包车',
      'trHome': '家',
      'trWork': '公司',
      'trCash': '现金',
      'trWalletTopUp': '钱包充值',
      'trTripEarning': '行程收入',
      'trPlatformFee': '平台费',
      'trBonusCredit': '奖励金',
      'trTripPayment': '行程付款',
      'trRefund': '退款',
      'trGoogleNotConfigured': '此应用未配置 Google 登录。请联系客服。',
      'trAdminRole': '管理员',
      'trEnterOtp': '输入验证码',
      'trPhoneLogin': '手机号登录',
      'trCodeSentTo': '验证码已发送至 {phone}',
      'trWeSendSmsCode': '我们将通过短信发送一次性验证码',
      'trResendCodeIn': '{n} 秒后重新发送',
      'trThisAccount': '此账户',
      'trRemoveAccount': '移除账户',
      'trUnlinkConfirm': '要从您的账户中解除关联 {name} 吗？',
      'trSwitchAccount': '切换账户',
      'trLinkAccount': '关联账户',
      'trNoLinkedAccounts': '没有已关联的账户',
      'trLinkAnotherAccount': '关联其他账户以便在它们之间切换。',
      'trLabelOptionalWork': '标签（可选，例如“工作”）',
      'trNewCodeSent': '新验证码已发送',
      'trVerifyPhone': '验证手机号',
      'trEnterVerificationCode': '输入验证码',
      'trDidntReceiveCode': '没有收到验证码？',
      'trResendInSeconds': '{n} 秒后重新发送',
      'trNoTasksNow': '目前没有{label}任务',
      'trSosFailedCall': 'SOS 发送失败。请直接拨打紧急服务电话。',
      'trNoDestinationMeteredFare': '此行程未设置目的地——请输入计价车费以完成行程。',
      'trCouldntAutoCalc': '无法自动计算建议车费：',
      'trFromKmTravelled': '基于 {km} 公里',
      'trUser': '用户',
      'trCreditName': '为 {name} 充值',
      'trAmountKhr': '金额（瑞尔）',
      'trNoteOptional': '备注（可选）',
      'trCredit': '充值',
      'trCreditApplied': '已充值。',
      'trDeleteUser': '删除用户',
      'trPermanentlyDelete': '永久删除 {name}？',
      'trUsers': '用户',
      'trSearchNameEmail': '按姓名/邮箱搜索…',
      'trAllRoles': '所有角色',
      'trNoUsersFound': '未找到用户。',
      'trCreditWallet': '钱包充值',
      'trNotifications': '通知',
      'trMarkAllRead': '全部标为已读',
      'trNoNotificationsYet': '暂无通知',
      'trCarRental': '租车',
      'trMarketplaceOrder': '商城订单',
      'trManageOnWebAdmin': '请在网页管理后台确认或管理此订单。',
      'trTransactions': '交易',
      'trDebit': '支出',
      'trTopUp': '充值',
      'trWithdraw': '提现',
      'trNoTransactions': '没有交易。',
      'trDriverApproved': '司机已批准',
      'trDriverRejected': '司机已拒绝',
      'trDriverApplications': '司机申请',
      'trNoPendingApplications': '没有待处理的申请',
      'trRejectDriver': '拒绝司机',
      'trProvideReasonOptional': '提供原因（可选）：',
      'trEgDocsUnclear': '例如：证件不清晰、身份证过期…',
      'trReviewDocs': '审核证件',
      'trNationalIdPassport': '身份证/护照',
      'trDriverLicense': '驾驶证',
      'trVehicleRegistration': '车辆登记证',
      'trSelfieWithId': '手持证件自拍',
      'trVehicleInsurance': '车辆保险',
      'trOtherDocument': '其他证件',
      'trRejectDocument': '拒绝证件',
      'trReasonImageBlurry': '原因（例如：图片太模糊）',
      'trApproveDriver': '批准司机',
      'trServiceZoneOptional': '服务区域（可选）：',
      'trEgZoneA': '例如：金边 A 区',
      'trConfirmApprove': '确认批准',
      'trDriverApprovedExcl': '司机已批准！',
      'trDocuments': '证件',
      'trNoDocumentsYet': '尚未上传证件。',
      'trNoteWith': '备注：{note}',
      'trViewDocument': '查看证件',
      'trPricingSaved': '价格设置已保存。',
      'trPricingSettings': '价格设置',
      'trSaveSettings': '保存设置',
      'trDeleteBanner': '删除横幅',
      'trRemoveBannerQ': '删除此横幅？',
      'trBanners': '横幅',
      'trNoBannersYet': '暂无横幅。',
      'trUntitled': '无标题',
      'trNewBanner': '新建横幅',
      'trEditBanner': '编辑横幅',
      'trSubtitleDescription': '副标题/描述',
      'trImageUrlOptional': '图片链接（可选）',
      'trSaveBanner': '保存横幅',
      'trSupportTickets': '客服工单',
      'trOpen': '待处理',
      'trInProgress': '处理中',
      'trResolved': '已解决',
      'trClosed': '已关闭',
      'trNoTicketsFound': '未找到工单。',
      'trNoSubject': '无主题',
      'trTicketNo': '工单 #{id}',
      'trMarkOpen': '标为待处理',
      'trMarkInProgress': '标为处理中',
      'trMarkResolved': '标为已解决',
      'trMarkClosed': '标为已关闭',
      'trTypeReply': '输入回复…',
      'trTopUpApproved': '充值已批准，已入账钱包。',
      'trRejectTopUp': '拒绝充值',
      'trReasonColon': '原因：',
      'trEnterReason': '输入原因',
      'trRejectedDot': '已拒绝。',
      'trTopUpRequests': '充值申请',
      'trNoTopUpRequests': '没有充值申请。',
      'trCancelRide': '取消行程',
      'trReasonForCancellation': '取消原因：',
      'trEgPolicyViolation': '例如：违反政策',
      'trRides': '行程',
      'trNoRidesFound': '未找到行程。',
      'trApproveWithdrawal': '批准提现',
      'trAddNoteOptional': '添加备注（可选）：',
      'trEgTransferredAba': '例如：已通过 ABA 转账',
      'trApprovedDot': '已批准。',
      'trRejectWithdrawal': '拒绝提现',
      'trReasonRequired': '原因（必填）：',
      'trEgInvalidAccount': '例如：账号无效',
      'trWithdrawals': '提现',
      'trNoWithdrawalsFound': '未找到提现记录。',
      'trSafetyIncidents': '安全事件',
      'trCrash': '碰撞',
      'trUserReport': '用户举报',
      'trNoSafetyIncidents': '没有安全事件。',
      'trDeliveries': '配送',
      'trNoDeliveriesFound': '未找到配送。',
      'trAdminDashboard': '管理后台',
      'trRevenue7Days': '收入（7天）',
      'trSurgePromoControl': '高峰与优惠管理',
      'trSurge': '高峰',
      'trPromos': '优惠',
      'trThisZone': '此区域',
      'trDeleteSurgeZone': '删除高峰区域',
      'trDeleteNamedQ': '删除“{name}”？',
      'trNewZone': '新建区域',
      'trNoSurgeZones': '尚未配置高峰区域。',
      'trNewSurgeZone': '新建高峰区域',
      'trEditSurgeZone': '编辑高峰区域',
      'trZoneName': '区域名称',
      'trEgCityCentre': '例如：市中心',
      'trDescriptionOptional': '描述（可选）',
      'trEgHighDemand': '例如：高需求区域',
      'trMultiplierX': '倍数：×{x}',
      'trCreateZone': '创建区域',
      'trSaveChanges': '保存更改',
      'trDeletePromo': '删除优惠',
      'trNewPromo': '新建优惠',
      'trNoPromoCodes': '没有优惠码。',
      'trAmountOff': '减 {amount}',
      'trUsesLeft': '剩余 {n} 次',
      'trExpShort': '到期 {date}',
      'trCodeDiscountRequired': '必须填写优惠码和折扣金额。',
      'trEditPromoCode': '编辑优惠码',
      'trNewPromoCode': '新建优惠码',
      'trPromoCode': '优惠码',
      'trDiscountKhr': '折扣（瑞尔）',
      'trMaxUsesHint': '最多使用次数（留空 = 不限）',
      'trExpiresAtHint': '到期日期（YYYY-MM-DD）',
      'trCreatePromo': '创建优惠',
      'trDeleteFareRule': '删除计价规则',
      'trThisVehicle': '此车型',
      'trFareManagement': '车费管理',
      'trAddRule': '添加规则',
      'trNoFareRules': '尚未配置计价规则。',
      'trBaseFare': '起步价',
      'trPerKm': '每公里',
      'trMinimum': '最低',
      'trFillFareFields': '请用有效数字填写所有车费字段。',
      'trEditFareRule': '编辑计价规则',
      'trNewFareRule': '新建计价规则',
      'trBaseFareKhr': '起步价（瑞尔）',
      'trPerKmRateKhr': '每公里价格（瑞尔）',
      'trMinimumFareKhr': '最低车费（瑞尔）',
      'trCreateRule': '创建规则',
      'trDestination': '目的地',
      'trFindingDriver': '正在寻找司机…',
      'trDriverOnTheWay': '司机正在路上',
      'trDriverEnRoutePickup': '司机正前往上车点',
      'trTripInProgress': '行程进行中',
      'trTripCompleted': '行程已完成',
      'trTripCancelled': '行程已取消',
      'trLiveTrip': 'ROTEH — 实时行程',
      'trMovingService': '搬家服务',
      'trWaitingDriverGps': '正在等待司机定位…',
      'trPageAutoUpdates': '此页面每 8 秒自动更新。',
      'trTripNotFound': '未找到行程',
      'trLookingForDriver': '正在寻找司机...',
      'trDriverAssigned': '已分配司机',
      'trDriverArrivedPickup': '司机已到达取件点',
      'trLoadingItems': '正在装货...',
      'trOnWayToDestination': '正前往目的地',
      'trMovingCompletedExcl': '搬家已完成！',
      'trProcessingDots': '处理中...',
      'trPackagePickedUp': '已取件',
      'trOnWayToRecipient': '正送往收件人',
      'trDeliveredExcl': '已送达！',
      'trPackageDelivery': '包裹配送',
      'trTrackMy': '追踪我的{service}',
      'trTrackMyLive': '实时追踪我的{title}',
      'trMovingCompleted': '搬家已完成',
      'trDeliveryCompletedTitle': '配送已完成',
      'trMoving': '搬家',
      'trRecipientLine': '收件人：{name}',
      'trDriverLine': '司机：{name}',
      'trShareMovingTracking': '分享搬家追踪',
      'trShareDeliveryTracking': '分享配送追踪',
      'trPendingFirstRide': '等待首次乘车',
      'trSedan': '轿车',
      'trUpTo4Pax': '最多 4 人',
      'trSuvVan': 'SUV/面包车',
      'trUpTo6Pax': '最多 6 人',
      'trDriverArrivingPickup': '{name} 即将到达您的上车点。',
      'trDriverWaitingAt': '{name} 正在 {place} 等候',
      'trSosSentToContacts': '🆘 已向 {n} 位联系人发送 SOS',
      'trChatWithSupport': '联系客服',
      'trPaidBySender': '寄件人付款',
      'trPaidByRecipient': '收件人付款',
      'trScheduleWithFare': '预约 — {fare}',
      'trConfirmWithFare': '确认 — {fare}',
      'trAddedToWallet': '{amount} 已存入您的钱包。',
      'trRecipientPhoneNumber': '收款人手机号',
      'trConfirmAndPay': '确认并支付',
      'trNewRideRequest': '🚗 新的乘车请求',
      'trNewRequest': '新请求',
      'trSubscribed': '订阅成功！',
      'trPlanUpgraded': '套餐已升级！',
      'trSubscriptionCancelled': '订阅已取消。',
      'trTransferred': '已转账。',
      'trSearchLocation': '搜索位置…',
      'trFindingAddress': '正在查找地址…',
      'trMoveMapToSet': '移动地图以设置位置',
      'trConfirmLocation': '确认位置',
      'trTapOpenGoogleMaps': '点击打开 Google 地图',
      'trOpenInMaps': '在地图中打开',
      'trSearchAddressHint': '搜索地址、地点或地标…',
      'trUseMyLocation': '使用我的当前位置',
      'trDetectedViaGps': '通过 GPS 定位',
      'trTypeToSearchPlace': '输入以搜索地点',
      'trNoResultsFor': '没有找到“{q}”的结果',
      'trMoveTheMapToSet': '移动地图以设置位置',
      'trUseThisLocation': '使用此位置',
      'trPromotions': '优惠活动',
      'trSlowConnection': '网络连接较慢？',
      'trSwipeToRefresh': '下拉并松开以刷新',
      'trPurchases': '购买',
      'trRentals': '租赁',
      'trPaymentsCancels': '付款与取消',
      'trPerMinuteRateKhr': '每分钟价格（瑞尔）',
      'trCancelFeeAfterArrival': '到达后取消费',
      'trWaitingFreeMinutes': '免费等候分钟数',
      'trWaitingFeePerMinuteKhr': '每分钟等候费（瑞尔）',
      'trNightSurchargePct': '夜间附加费（%）',
      'trPlatformCommissionPct': '平台佣金（%）',
      'trStepOrder': '下单',
      'trStepDriverAssigned': '已分配\n司机',
      'trStepPickedUp': '已取件',
      'trStepOnTheWay': '运送\n途中',
      'trStepDelivered': '已送达',
      'trStepAccepted': '已接单',
      'trStepArrived': '已到达',
      'trStepLoading': '装货中',
      'trStepInTransit': '运输中',
      'trStepDone': '完成',
      'trGoogleCancelled': 'Google 登录已取消。',
      'trEnterEmailPassword': '请输入邮箱和密码。',
      'trCannotReachServer': '无法连接服务器。',
      'trEnterYourPhone': '请输入您的手机号。',
      'trDevModeCode': '开发模式——未发送真实短信。您的验证码是 {code}',
      'trActiveCount': '进行中（{n}）',
      'trCompletedCount': '已完成（{n}）',
      'trTitleRequired': '标题为必填项。',
      'trZoneNameRequired': '区域名称为必填项。',
      'trDeletePromoCodeQ': '删除优惠码“{code}”？',
      'trBaseFareLower': '起步价',
      'trTimeMin': '时长（{n} 分钟）',
      'trNoFee': '免手续费',
      'trInstant': '即时到账',
      'trSurgeActiveArea': '您所在区域正在实行 {x}× 高峰定价',
      'trSurgeHighDemand': '{x}× 高峰定价——您所在区域需求较高',
      'trNoListingMatchesFilter': '没有符合该筛选的商品——显示您原来的选择。',
      'trPaymentSuccessful': '✅ 支付成功',
      'trPaidVia': '已通过 {method} 支付 {amount}',
      'trSetLocation': '设置位置',
      'trNetworkErrorCheck': '网络错误——请检查网络连接',
      'trEnableBiometric': '为 ROTEH 启用生物识别登录',
      'trSignInToRoteh': '登录 ROTEH',
      'deleteAccountLabel': '删除账户',
      'deleteAccountTitle': '删除您的账户？',
      'deleteAccountMessage': '此操作将永久删除您的姓名、邮箱、手机号、已保存地点和紧急联系人，并在所有设备上退出登录。行程和付款记录会因会计原因保留，但不再与您关联。此操作无法撤销。',
      'deleteAccountConfirm': '永久删除',
      'deleteAccountDone': '您的账户已删除。',
      'trCouldNotCompleteTrip': '无法完成行程——请检查网络后重试。',
      'trSurchargesLine': '附加费与最低车费',
      'trMeterSoFar': '目前里程',
      'pkExportReport': '导出报表',
      'pkExportPdf': 'PDF',
      'pkExportPdfSub': '汇总、图表和包裹清单——便于打印或发送',
      'pkExportExcel': 'Excel',
      'pkExportExcelSub': '所有包裹，含收件人姓名和地址',
      'pkStatusCompleted': '已完成',
      'pkStatusFailed': '未送达',
      'pkStatusReturned': '已退回店铺',
      'pkReasonCannotContact': '无法联系收件人',
      'pkReasonRefused': '收件人拒收',
      'pkReasonWrongAddress': '地址错误',
      'pkReasonPostponed': '收件人要求改期',
      'pkReasonOther': '其他原因',
      'pkReturningToShop': '司机正在将其送回您的店铺',
      'pkReports': '报表',
      'pkReportsSub': '日报、周报、月报',
      'pkDay': '日',
      'pkWeek': '周',
      'pkMonth': '月',
      'pkTotalPackages': '包裹总数',
      'pkSuccessRate': '成功率',
      'pkInProgress': '进行中',
      'pkDeliveryFees': '运费合计',
      'pkCodCollected': '已代收货款',
      'pkAvgTime': '平均配送时间',
      'pkMinutes': '{n} 分钟',
      'pkFailureReasons': '未送达原因',
      'pkNoData': '该时段没有包裹',
      'pkToday': '今天',
      'pkThisWeek': '本周',
      'pkThisMonth': '本月',
      'pkByHour': '按小时统计',
      'pkByDay': '按天统计',
      'pkTodaySummary': '今日：完成 {done} · 退回 {back} · 进行中 {open}',
      'drvCantDeliver': '无法送达',
      'drvCantDeliverTitle': '为什么无法送达？',
      'drvFailNote': '备注（可选）',
      'drvReportFail': '上报并退回店铺',
      'drvReturningTitle': '将包裹送回店铺',
      'drvReturnedToShop': '已送回店铺',
      'drvDeliveredAfterAll': '已联系上收件人——标记送达',
      'drvReturnDone': '包裹已送回店铺',
      'pkPartnerServices': '伙伴服务',
      'pkCreatePackage': '创建包裹',
      'pkCreatePackageSub': 'ROTEH 上门取件配送',
      'pkMyPackages': '我的包裹',
      'pkMyPackagesSub': '查看全部包裹',
      'pkTrackPackage': '追踪包裹',
      'pkTrackPackageSub': '配送中的包裹',
      'pkHistory': '寄件记录',
      'pkHistorySub': '已送达与已取消',
      'pkActiveCount': '{n} 进行中',
      'pkTodayCount': '今日 {n}',
      'pkCodPending': '待收货款',
      'pkBecomePartner': '成为 ROTEH 伙伴',
      'pkBecomePartnerSub': '寄送包裹——ROTEH 上门取件并送达您的客户',
      'pkPartnerAccount': 'ROTEH 伙伴',
      'pkPendingTitle': '注册审核中',
      'pkPendingBody': 'ROTEH 正在审核您的伙伴注册，通过后会通知您。',
      'pkRejectedTitle': '注册未通过',
      'pkSuspendedTitle': '伙伴账户已暂停',
      'pkSuspendedBody': '请联系 ROTEH 客服。',
      'pkResubmit': '修改并重新提交',
      'pkRegisterTitle': '注册成为伙伴',
      'pkRegisterIntro': '使用同一账户。ROTEH 审核通过后，即可在此创建和追踪包裹，并照常叫车。',
      'pkBusinessName': '店铺/商家名称',
      'pkBusinessType': '商家类型',
      'pkContactName': '联系人（可选）',
      'pkBusinessPhone': '商家电话',
      'pkPickupAddress': '常用取件地址',
      'pkSubmit': '提交注册',
      'pkRequired': '请填写此项',
      'pkTypeOnlineShop': '网店',
      'pkTypeRetail': '零售店',
      'pkTypeRestaurant': '餐饮',
      'pkTypeOther': '其他',
      'pkSender': '寄件人',
      'pkReceiver': '收件人',
      'pkName': '姓名',
      'pkPhone': '电话号码',
      'pkPickupLocation': '取件地点',
      'pkDeliveryLocation': '送货地点',
      'pkChooseOnMap': '点击在地图上选择',
      'pkPackage': '包裹',
      'pkPackageType': '包裹类型',
      'pkDescription': '描述（内装物品）',
      'pkWeight': '重量（公斤，可选）',
      'pkSize': '尺寸',
      'pkPhoto': '包裹照片（可选）',
      'pkAddPhoto': '添加照片',
      'pkCamera': '相机',
      'pkGallery': '相册',
      'pkService': '配送速度',
      'pkNormal': '普通',
      'pkExpress': '加急',
      'pkPayment': '付款',
      'pkWhoPays': '谁支付运费？',
      'pkPartnerPays': '我付',
      'pkReceiverPays': '收件人付（现金）',
      'pkCodAmount': '向收件人代收货款（៛）',
      'pkCodHint': '无需代收请留空',
      'pkReference': '您的订单号（可选）',
      'pkNotes': '给司机的备注（可选）',
      'pkDeliveryFee': '运费',
      'pkSubmitPackage': '创建包裹',
      'pkChooseLocations': '请在地图上选择取件和送货地点',
      'pkCreatedTitle': '包裹已创建',
      'pkCreatedBody': '{code} 等待 ROTEH 确认，司机出发时会通知您。',
      'pkStatusPending': '待确认',
      'pkStatusConfirmed': '已确认',
      'pkStatusDriverAssigned': '已分配司机',
      'pkStatusPickedUp': '已取件',
      'pkStatusInTransit': '运输中',
      'pkStatusDelivered': '已送达',
      'pkStatusCancelled': '已取消',
      'pkTabActive': '进行中',
      'pkTabHistory': '记录',
      'pkTabAll': '全部',
      'pkSearchHint': '搜索单号、收件人或电话',
      'pkEmptyActive': '没有进行中的包裹',
      'pkEmptyHistory': '暂无已送达或已取消的包裹',
      'pkEmptyAll': '暂无包裹',
      'pkDetailTitle': '包裹详情',
      'pkTimeline': '物流跟踪',
      'pkDriver': '司机',
      'pkCall': '致电',
      'pkLiveMap': '实时地图',
      'pkShareLink': '分享追踪链接',
      'pkShareText': '追踪您的 ROTEH 包裹 {code}：{url}',
      'pkCancelPackage': '取消包裹',
      'pkCancelConfirm': '确定取消此包裹？此操作无法撤销。',
      'pkCancelReason': '原因（可选）',
      'pkKeep': '保留',
      'pkQrTitle': '包裹二维码',
      'pkQrHint': '贴在包裹上——司机取件和送达时扫描。',
      'pkProofPhoto': '送达凭证',
      'pkWaitingConfirm': '等待 ROTEH 确认',
      'pkFindingDriver': 'ROTEH 正在寻找司机',
      'pkPaymentByReceiver': '收件人付',
      'pkPaymentByPartner': '您付',
      'pkCod': '代收',
      'pkSizeSmall': '小',
      'pkSizeMedium': '中',
      'pkSizeLarge': '大',
      'pkSizeXL': '特大',
      'pkTypeDocument': '文件',
      'pkTypeParcel': '普通包裹',
      'pkTypeFood': '食品',
      'pkTypeClothing': '服装',
      'pkTypeElectronics': '电子产品',
      'pkTypeFragile': '易碎品',
      'pkPayMethod': '支付方式',
      'pkPayCash': '现金付给司机',
      'pkPayWallet': 'ROTEH Pay',
      'pkPayAba': 'ABA / KHQR',
      'pkCreated': '创建时间',
      'paywayOrderPaidBody': '已收到您支付的 {amount}，谢谢！',
      'paywayNotAvailable': 'ABA 付款暂不可用，您可稍后在此订单中付款。',
      'paywayPayNow': '使用 ABA / KHQR 付款',
      'paywayUnpaid': '尚未付款',
      'paywayPaidLabel': '已付款',
      'paywayTitle': 'ABA / KHQR 付款',
      'paywayScanHint': '使用 ABA Mobile、ACLEDA 或任意 KHQR 银行应用扫码。',
      'paywayWaiting': '等待付款',
      'paywayExpired': '二维码已过期，请重试。',
      'paywayFailed': '付款未完成。',
      'paywayOpenAba': '打开 ABA Mobile',
      'paywayIPaid': '我已付款——立即查询',
      'paywayRef': '参考号',
      'paywayPaidTitle': '已收到付款',
      'paywayPaidBody': '{amount} 已存入您的 ROTEH Pay 钱包。',
      'helmetConfidence': '置信度：{value}',
      'helmetCheckFailed': '无法检测照片，请重试。',
      'txStatusPending': '待处理',
      'txStatusProcessing': '处理中',
      'txStatusFailed': '失败',
      'txStatusRejected': '已拒绝',
      'txFilterIncome': '收入',
      'txFilterDeductions': '支出',
      'txNoneForFilter': '暂无交易。',
      'txWithdrawalPending': '提现（等待审核）',
      'txWithdrawal': '提现',
      'txWithdrawalReturned': '提现被拒绝——已退回',
      'txTransferIn': '收到转账',
      'txTransferOut': '转出',
      'txTipIn': '收到小费',
      'txTipOut': '小费',
      'txSalary': '工资',
      'txDeliveryPayment': '配送付款',
      'txCancellationFee': '取消费',
      'txAdminCredit': '客服充值',
      'txReferralReward': '推荐奖励',
      'txCompanyShare': '公司分成',
      'txLoyaltyRedemption': '积分兑换',
      'topUpPendingTitle': '充值等待审核',
      'topUpPendingStatus': '等待审核',
      'topUpPendingBlocked': '您已有一笔充值在等待审核，请等待审核完成。',
      'bankTransfer': '银行转账',
      'drvLowBalanceOfflineTitle': '已提现 — 您已下线',
      'drvLowBalanceOfflineMsg': '您的钱包余额为 {balance}，低于上线接单所需的 {min}。请充值后再接单。',
      'drvTripCancelledTitle': '行程已取消',
      'drvRequestNoLongerAvailable': '此请求已不可用——已被取消或由其他司机接单。',
      'drvSenderCancelledDelivery': '客户取消了该配送请求。',
      'trCancelledStatus': '已取消',
      'trDeliveryCancelledTitle': '配送已取消',
      'trMovingCancelledTitle': '搬家已取消',
      'trCancelledByDriver': '司机取消了此订单。',
      'trCancelledByAdmin': '客服团队取消了此订单。',
      'trCancelledByYou': '您取消了此订单。',
      'trCancelledGeneric': '此订单已取消。',
      'trCancelReason': '原因：{reason}',
      'trGoBack': '返回',
      'drvGreeting': '你好，{name}！',
      'drvFindingRides': '正在寻找新行程…',
      'drvTodayStats': '今日统计',
      'drvTodayEarnings': '今日收入',
      'drvWalletBalance': '钱包余额',
      'drvAcceptRides': '接单',
      'drvRideSub': '乘客',
      'drvDeliverySub': '包裹与外卖',
      'drvRentalSub': '出租车辆',
      'drvNoRecentTrips': '暂无行程——上线开始赚钱。',
      'drvHelp': '帮助',
      'trRecipientLine2': '收件人：{name}',
      'trForName': '收件人：{name}',
      'trClassicTukTuk': '经典嘟嘟车',
      'trStdPremiumVan': '标准、高级和面包车',
      'goodAfternoon': '下午好,',
      'goodEvening': '晚上好,',
      'busy': '繁忙',
      'full': '满的',
      'chooseRide': '选择车辆',
      'promoCode': '添加优惠码',
      'scheduleDelivery': '安排配送',
      'packageDetails': '包装详情',
      'packageSize': '包裹尺寸',
      'sendAnything': '随时随地\n发送任何东西!',
      'avgDelivery': '平均配送时间: 25分钟',
      'incomingRequest': '收到请求',
      'acceptRide': '接受行程',
      'decline': '拒绝',
      'todayPerformance': '今日表现',
      'recentTripsDriver': '最近行程',
      'dailyBreakdown': '每日明细',
      'withdrawEarnings': '提取收入',
      'evCarsAvailable': '电动车\n现已上线!',
      'evCarsSubtitle': '在您附近租用或购买 电动车辆',
      'explore': '搜寻车辆',
      'completed': '已完成',
      'eta': '预计到达时间',
      'min': '分钟',
      'km': '公里',
      'activeRideInProgress': '行程进行中',
      'noRecentTrips': '暂无最近行程',
      'searchProductsHint': '搜索商品…',
      'filter': '筛选',
      'listingsAvailable': '个可售商品',
      'findBestDeal': '寻找最优惠的价格',
      'browseAll': '全部',
      'rentalVehicle': '租赁车辆',
      'tryAgain': '重试',
      'results': '个结果',
      'noListingsFound': '未找到商品',
      'tryDifferentFilters': '请尝试其他筛选条件',
      'salePrice': '售价',
      'rentPerDay': '租金 / 天',
      'qty': '数量',
      'verifiedSeller': '已认证卖家',
      'editListing': '编辑商品',
      'fillRequiredFields': '请填写所有必填信息',
      'shopAsGuest': '以访客身份购物',
      'continueAsGuest': '以访客身份继续',
      'welcomeBack': "欢迎回来",
      'signInSubtitle': "登录以管理您的订单、行程和配送。",
      'noAccountYet': "还没有账户？",
      'signInWithBiometrics': "使用生物识别登录",
      'signInAs': "登录为",
      'secureSignInNote': "您的信息已加密并安全保存。",
      'welcomeTagline': '购买  •  租赁  •  配送  •  搬家',
      'welcomeTitle': '欢迎使用 ROTEH APP',
      'welcomeSubtitle': '购买或租赁商品，送货上门——无需注册账户。',
      'orContinueWith': '或使用以下方式继续',
      'continueWithPhone': '使用手机号继续',
      'continueWithGoogle': '使用 Google 继续',
      'secureCheckoutNote': '安全结账  •  下单时验证手机号',
      'continueAsGuestSub': '无需账户即可购买或租赁商品',
      'guestShoppingNotice': '您正在以访客身份购物，订单保存在此手机上。',
      'orderPlaced': '订单已提交！',
      'purchaseRequestSent': '您的购买请求已发送给卖家。',
      'done': '完成',
      'purchaseProduct': '购买商品',
      'couponCode': '优惠券代码',
      'phoneNumber': '电话号码',
      'confirmInformation': '确认信息',
      'verifyAddressesNote': '请在继续之前核实所有地址和联系方式。'
          '订单提交后卖家将收到通知。',
      'purchaseNow': '立即购买',
      'findingAddress': '正在查找地址…',
      'locationType': '位置类型',
      'rentalDuration': '租赁期限',
      'orderPlacedSuccess': '订单已成功提交！',
      'paymentMethod': '付款方式',
      'startDate': '开始日期',
      'endDateAuto': '结束日期（自动）',
      'selectStartDate': '选择开始日期',
      'discountApplied': '已应用折扣',
      'apply': '应用',
      'total': '总计',
      'deleteListing': '删除此商品？',
      'willBePermanentlyRemoved': '将被永久删除。',
      'cancel': '取消',
      'delete': '删除',
      'postAListing': '发布商品',
      'noOrdersYet': '暂无订单',
      'order': '订单',
      'left': '剩余',
      'savedPlaces': '已保存地点',
      'noSavedPlacesYet': '暂无已保存地点。',
      'promoCodeTitle': '优惠码',
      'browseVouchers': '浏览可用优惠券 →',
      'cambodia': '柬埔寨',
      'mapLabel': '地图',
      'noResultsFound': '未找到结果',
      'addAStop': '添加途经点',
      'whereTo': '去哪里？',
      'now': '现在',
      'confirmBooking': '确认预订',
      'noDestinationNeeded': '无需目的地 — 当面告诉司机',
      'whereToTitle': '去哪里？',
      'noSavedPlaces': '暂无已保存地点',
      'confirmDestination': '确认目的地',
      'whereToOptional': '去哪里？（可选）',
      'chooseRideTitle': '选择车型',
      'scrollUpForMore': '向上滑动查看更多车型',
      'discountSuffix': '折扣',
      'noDestinationSelected': '尚未选择目的地',
      'selectDestination': '选择目的地',
      'deliveryAndMoving': '快递与搬家',
      'moveWithEase': '轻松搬家，\n一切交给我们！',
      'professionalMovingService': '专业搬家服务',
      'scheduleMovingDate': '安排搬家日期',
      'selectLocationsForFare': '选择取件和送达地点以查看预估费用',
      'calculatingFare': '正在计算费用…',
      'yes': '是',
      'no': '否',
      'helpersNeeded': '需要帮手',
      'personsForCarrying': '1–4 人协助搬运',
      'fareEstimate': '费用预估',
      'totalEstimate': '预估总费用',
      'finalPriceConfirmed': '最终价格将在预订后确认',
      'change': '更改',
      'confirmLocation': '确认位置',
      'confirmDeliveryBooking': '确认快递预订',
      'noCancel': '否，取消',
      'yesSendNow': '是，立即发送',
      'confirmMovingBooking': '确认搬家预订',
      'estimatedFare': '预估费用',
      'yesBookNow': '是，立即预订',
      'couldNotFetchEstimate': '无法获取预估费用',
      'rideCancelled': '行程已取消',
      'ok': '好的',
      'stop': '停靠点',
      'dropoff': '下车',
      'safetyCentre': '安全中心',
      'fare': '车费',
      'sendSOSQuestion': '🆘 发送求救信号？',
      'sendSOS': '发送求救信号',
      'sosFailed': '求救信号发送失败',
      'driverPhoneNotAvailable': '司机电话暂时不可用。',
      'cannotDialPrefix': '无法拨打',
      'onThisDevice': '此设备不支持拨号。',
      'couldNotGenerateShareLink': '无法生成分享链接',
      'linkCopied': '链接已复制到剪贴板',
      'shareTrip': '分享行程',
      'friendsCanTrack': '亲友可以实时追踪您的行程',
      'driverLabel': '司机',
      'copyLink': '复制链接',
      'shareVia': '分享至...',
      'stopSharingLocation': '停止分享位置',
      'cancelRide': '取消行程',
      'keepRide': '继续行程',
      'businessAccount': '企业账户',
      'noBusinessAccount': '暂无企业账户',
      'registerOrJoinBusiness': '注册您的公司或加入现有企业账户。',
      'enterInviteCode': '输入公司管理员提供给您的邀请码。',
      'fillSampleData': '填充示例数据',
      'leaveBusinessQuestion': '退出企业账户？',
      'loseBusinessAccess': '您将无法再使用企业功能。',
      'leave': '退出',
      'edit': '编辑',
      'active': '活跃',
      'removeMemberQuestion': '移除该成员？',
      'remove': '移除',
      'noMembersYet': '暂无成员。',
      'noBusinessTripsYet': '暂无企业行程。',
      'refresh': 'Refresh',
      'retry': '重试',
      'businessRegistered': '企业账户注册成功！',
      'shareInviteCodeNote': '将此邀请码分享给您的员工以便他们加入。',
      'inviteCodeCopied': '邀请码已复制！',
      'copyCode': '复制邀请码',
      'member': '成员',
      'removeMemberPrefix': '移除',
      'thisMember': '该成员',
      'fromBusinessAccountSuffix': '退出企业账户？',
      'refLabel': '参考号',
      'promotions': '促销活动',
      'editProfile': '编辑个人资料',
      'rotehPay': 'ROTEH Pay',
      'qrPayment': '扫码支付',
      'promosVouchers': '优惠与代金券',
      'scheduledRides': '预约行程',
      'subscriptionPlans': '订阅计划',
      'rotehRewards': 'ROTEH 奖励',
      'referEarn': '推荐赚奖励',
      'myRentals': '我的租赁',
      'switchToDriverMode': '切换到司机模式',
      'settings': '设置',
      'missions': '任务',
      'myEarnings': '我的收入',
      'topUpWallet': '钱包充值',
      'helmetCheck': '头盔检查',
      'switchToPassengerMode': '切换到乘客模式',
      'darkMode': '深色模式',
      'rideLabel': '行程',
      'rental': '租赁',
      'accepted': '已接单',
      'hoursOnline': '在线时长',
      'acceptanceRate': '接单率',
      'verified': '已认证',
      'trips': '行程',
      'bonuses': '奖金',
      'fees': '费用',
      'topUps': '充值',
      'heavyItems': '⚠ 重物',
      'packing': '📦 打包',
      'management': '管理',
      'users': '用户',
      'drivers': '司机',
      'ridesAdmin': '行程',
      'deliveriesAdmin': '快递',
      'withdrawalsAdmin': '提现',
      'supportAdmin': '客服',
      'transactionsAdmin': '交易记录',
      'fareRules': '计价规则',
      'surgeZones': '高峰区域',
      'pricingAdmin': '定价',
      'bannersAdmin': '横幅广告',
      'safetyAdmin': '安全',
      'passengersStat': '乘客',
      'driversTotal': '司机总数',
      'onlineDrivers': '在线司机',
      'pendingDrivers': '待审核司机',
      'ridesToday': '今日行程',
      'activeRides': '进行中的行程',
      'deliveriesToday': '今日快递',
      'revenueToday': '今日收入',
      'revenueWeek': '本周收入',
      'growth': '增长率',
      'openTickets': '待处理工单',
      'safetyIncidents': '安全事件',
      'driverApprovalsSuffix': '司机审核',
      'ticketsSuffix': '工单',
      'serviceModes': '服务模式',
      'overview': '概览',
      'pendingActionsSuffix': '项待处理事项',
      'clearAll': '清除全部',
      'size': '尺寸',
      'vehicleType': '车辆类型',
      'color': '颜色',
      'options': '选项',
      'accessories': '配件',
      'addAccessory': '添加配件',
      'optional': '可选',
      'optionalAddOns': '买家可选择的附加配件',
      'nameEn': '名称 (英语)',
      'nameKm': '名称 (高棉语, 可选)',
      'priceUsd': '价格 (美元 \$)',
      'rentPerDayUsd': '每日租金 (美元 \$)',
      'whatAreYouListing': '您要发布什么?',
      'vehicleOption': '车辆 (嘟嘟车、货车等)',
      'accessoryOther': '配件 / 其他',
      'photos': '照片',
      'upTo5': '最多5张',
      'productInfo': '商品信息',
      'productTitle': '标题',
      'describeProduct': '描述您的商品…',
      'type': '类型',
      'condition': '成色',
      'pricing': '定价',
      'quantity': '数量',
      'areaDistrictOptional': '区域 / 地区 (可选)',
      'status': '状态',
      'findingMatch': '正在匹配…',
      'totalSummary': '费用汇总',
      'addAnotherItem': '添加其他商品',
      'addItem': '添加商品',
      'searchListings': '搜索商品…',
      'noOtherListingsFound': '未找到其他商品',
      'pickUp': '自取',
      'collectMyself': '我将自行提货',
      'deliverToAddress': '配送至我的地址',
      'tapToSetDelivery': '点击设置配送地址',
      'paidFull': '全额支付',
      'payFullAmountNow': '立即支付全额',
      'book30': '预付 30%',
      'pay30Deposit': '支付30%定金 — 尾款送达时付清',
      'cod': '货到付款 (COD)',
      'cashOnDelivery': '送达时现金支付',
      'payWithCash': '使用现金支付',
      'inAppWalletBalance': '应用内钱包余额',
      'abaMobileBanking': 'ABA 手机银行',
      'wingMobileWallet': 'Wing 电子钱包',
      'otherOnline': '其他在线支付',
      'otherOnlinePayment': '其他在线支付方式',
      'enterCouponCodeOptional': '输入优惠码 (可选)',
      'enterCouponCode': '输入优惠码',
      'noListingsYet': '暂无在售商品',
      'postSomethingToSell': '发布商品开始出售',
      'duration': '时长',
      'specialInstructions': '任何特殊要求…',
      'seller': '卖家',
      'specifications': '规格参数',
      'pickupLocation': '提货地点',
      'all': '全部',
      'category': '类别',
      'location': '位置',
      'description': '描述',
      'paymentType': '付款方式',
      'cash': '现金',
      'sender': '发件人',
      'recipient': '收件人',
      'moving': '搬家',
      'topUpRequired': '需要充值',
      'topUpNow': '立即充值',
      'lookingForRideRequests': '正在寻找行程请求',
      'deliveryModeActive': '配送模式已激活',
      'incomingRideRequest': '收到行程请求',
      'incomingDeliveryRequest': '收到配送请求',
      'incomingRentalRequest': '收到租赁请求',
      'acceptDelivery': '接受配送',
      'acceptRental': '接受租赁',
      'searchChargingStation': '搜索换电站、位置...',
      'nearbyChargingStations': '附近的换电站',
      'noChargingStationsFound': '未找到换电站。',
      'createAccount': '创建账户',
      'joinRoteh': '加入 ROTEH',
      'fastSafeRides': '在柬埔寨快速、安全的出行',
      'iWantTo': '我想',
      'rideAsPassenger': '作为乘客出行',
      'driveAndEarn': '驾驶并赚钱',
      'driverType': '司机类型',
      'fullName': '全名',
      'email': '电子邮箱',
      'enterEmail': '输入您的电子邮箱',
      'password': '密码',
      'enterPassword': '输入您的密码',
      'confirmPassword': '确认密码',
      'phoneOptional': '电话 (可选)',
      'referralCodeOptional': '推荐码 (可选)',
      'alreadyHaveAccount': '已有账户? ',
      'signIn': '登录',
      'demoAccounts': '演示账户',
      'sendOtp': '发送验证码',
      'verifyAndSignIn': '验证并登录',
      'resendOtp': '重新发送验证码',
      'family': '家庭',
      'wallet': '钱包',
      'rewards': '奖励',
      'refer': '推荐',
      // ── Delivery / moving summary screens ──
      'phone': '电话',
      'package': '包裹',
      'movingCompleted': '搬运已完成！',
      'deliveryDetails': '配送详情',
      'movingDetails': '搬运详情',
      'orderInfo': '订单信息',
      'jobInfo': '任务信息',
      'paymentSummary': '支付摘要',
      'movingFee': '搬运费',
      'paidBy': '付款人',
      'youRated': '您的评分',
      'backToHome': '返回首页',
      'backToDashboard': '返回仪表板',
      'updatingReceipt': '正在更新收据…',
      'updatingSummary': '正在更新摘要…',
      'couldNotRefresh': '无法刷新。显示已保存的详情。',
      'platformFee': '平台费',
      'netDriverFee': '司机净收入',
      'driverFee': '司机费用',
      'beforePlatformFee': '扣除平台费前',
      'collectFromRecipient': '向收件人收取',
      'collectPackageAmount': '收取包裹金额',
      'packageDeliveredSuccessfully': '包裹已成功送达。',
      'movingJobDone': '干得好 — 搬运任务已完成。',
      'onlinePay': '在线支付',

      // ── Trip receipt ──
      'tripComplete': '行程完成',
      'ride': '乘车',
      'fareBreakdown': '费用明细',
      'baseFare': '起步价',
      'distanceFee': '里程费',
      'surgeFee': '高峰附加费',
      'promoDiscount': '优惠折扣',
      'tripDetails': '行程详情',
      'dateAndTime': '日期与时间',
      'distance': '距离',
      'yourDriver': '您的司机',
      'yourRating': '您的评分',
      'shareReceipt': '分享收据',
      'tripReceipt': '行程收据',
      'minShort': '分钟',
      'from': '从',
      'to': '到',
      'date': '日期',
      'surge': '高峰',
      'promo': '优惠',
      'rotehWallet': 'ROTEH 钱包',
      // ── Payment screen ──
      'chooseHowYouWantTo': '选择您的支付方式',
      'confirmAndPay': '确认并支付',
      'haveAPromoCode': '有优惠码吗',
      'payDriverDirectly': '直接支付给司机',
      'serviceFee2': '服务费',
      'totalToPay': '应付总额',
      'tripSummary': '行程摘要',
      'wingMobileWallet2': 'Wing 移动钱包',
      'wingMoney': 'Wing Money',
      'yourWalletBalance': '您的钱包余额',
      // ── Payment screen ──
      'payingWith': '支付方式',
      // ── Wallet screen ──
      'amountKhrMin1000': '金额（瑞尔 最低 1,000)',
      'balanceUpdated': '余额已更新',
      'checkLater': '稍后查看',
      'close': '关闭',
      'confirmTopUp': '确认充值',
      'customAmountKhr': '自定义金额（瑞尔)',
      'enterRecipientPhoneNumber': '输入收件人电话号码',
      'history': '历史记录',
      'loading': '加载中...',
      'minimumTopUpAmountIs': '最低充值金额为 1,000 瑞尔',
      'minimumTransferAmountIs1': '最低转账金额为 1,000 瑞尔',
      'noTransactionsYet': '暂无交易',
      'recentTransactions': '最近交易',
      'reload': '充值',
      'send': '发送',
      'sendMoney': '转账',
      'sentSuccessfully': '发送成功',
      'tapToRetry': '点击重试',
      'topUp': '充值',
      'topUpRotehPay': '充值 ROTEH Pay',
      'topUpStatus': '充值状态',
      'topUpApproved': '充值已批准！',
      'topUpRejected': '充值被拒绝',
      'viewAll': '查看全部',
      'waitingForAdminApproval': '等待管理员批准…',
      // ── passenger_home screen ──
      'n128Trips': '(128 次行程)',
      // ── delivery_tracking_screen screen ──
      'areYouSureYouWant': '您确定要取消此配送吗?',
      'cancelOrder': '取消订单',
      'cancelOrder2': '取消订单?',
      'chatDriver': '联系司机',
      'completedAt2': '完成时间: ',
      'copy': '复制',
      'couldNotLoadDelivery': '无法加载配送信息',
      'deliveryFee2': '配送费: ',
      'howWasYourDeliveryExperience': '您的配送体验如何?',
      'keepOrder': '保留订单',
      'leaveACommentOptional': '留下评论（可选)',
      'packageAmount2': '包裹金额: ',
      'rateDelivery': '评价配送',
      'recipientsAndFriendsCanTrack': '收件人和朋友可以实时追踪进度',
      'service': '服务',
      'shareLink': '分享链接',
      'skip': '跳过',
      'stopSharingTracking': '停止分享追踪',
      'submit': '提交',
      'summary': '摘要',
      'trackingLinkCopiedToClipboard': '追踪链接已复制到 clipboard',
      'trackingLinkDeactivated': '追踪链接已停用',
      'viewSummary': '查看摘要',
      // ── trip_tracking_screen screen ──
      'anSosAlertWillBe': 'SOS 警报将立即发送给您所有的紧急联系人.',
      'call': '呼叫',
      'destination': '目的地',
      'locatingYourDriver': '正在定位您的司机…',
      'driverArrived': '✅ 司机已到达!',
      'driverFound': '🛺 找到司机了!',
      'yourDriverIsAlmostHere': '🛺 您的司机即将到达',
      // ── ride_booking screen ──
      'airport': '机场',
      'chooseOnMap': '在地图上选择',
      'home2': '家',
      'office': '办公室',
      'pickupLocation2': '上车地点',
      'recent': '最近',
      'rideRequested': '已请求乘车!',
      'saved': 'Saved',
      'searchPickupLocation': '搜索上车地点',
      'setLocationLater': '稍后设置位置',
      'suggestions': '建议',
      'eGSave10': '例如 SAVE10',
      'pickup2': '📍 上车',
      // ── delivery_screen screen ──
      'n1Bedroom': '1 卧室',
      'n10KgAndAbove': '10 公斤及以上',
      'n2Bedrooms': '2 卧室',
      'n210Kg': '2 – 10 公斤',
      'n3Bedrooms': '3+ 卧室',
      'baseFee': '基础费',
      'bike': '摩托车',
      'buildingHasAWorkingElevator': '大楼有可用电梯',
      'car': '汽车',
      'cashOnDeliveryCod': '货到付款',
      'commercialOfficeMoving': '商业/办公室搬迁',
      'deliveryVehicle': '配送车辆',
      'dropoffFloor': '送达楼层',
      'elevator': '电梯',
      'express': '快递',
      'fasterDeliveryAtHigherFee': '更快配送，费用更高',
      'floorFee': '楼层费',
      'floors': '楼层',
      'fridgeSofaBedWardrobe': '冰箱、沙发、床、衣柜',
      'hasElevator': '有电梯',
      'hasHeavyItems': '有重物',
      'helperFee': '搬运工费',
      'helpers': '搬运工',
      'home3': '家',
      'homeMove': '家庭搬迁',
      'informationOfMover': '搬运工信息',
      'large': '大',
      'largeHomeOrVilla': '大型住宅或别墅',
      'largerApartment': '较大的公寓',
      'manualCarryUpDownStairs': '需要人工搬运上下楼梯',
      'medium': '中',
      'mediumApartment': '中型公寓',
      'moveType': '搬迁类型',
      'needsStairsCarry': '需要楼梯搬运',
      'normal': '普通',
      'notes': '备注',
      'officeMove': '办公室搬迁',
      'packingService': '打包服务',
      'payFromWalletBalance': '从钱包余额支付',
      'paymentBy': '付款方式',
      'paysUpfront': '预付',
      'pickupFloor': '取件楼层',
      'priorityMovingService': '优先搬迁服务',
      'privateHome': '私人住宅',
      'propertySize': '物业面积',
      'recipPh': '收件人电话',
      'relocateHomeOffice': '搬迁家庭/办公室',
      'residentialMoving': '住宅搬迁',
      'scheduled': '已预约',
      'searchLocation': '搜索位置…',
      'sendPackages': '寄送包裹',
      'senderPh': '发件人电话',
      'serviceOption': '服务选项',
      'small': '小',
      'smallSpace': '小空间',
      'standardDeliverySpeed': '标准配送速度',
      'standardMovingService': '标准搬迁服务',
      'studio1Room': '单间/1 房',
      'tukTuk': '嘟嘟车',
      'upTo100KgAffordable': '最高 100 公斤 • 价格实惠',
      'upTo2Kg': '最高 2 公斤',
      'upTo20KgFastest': '最高 20 公斤 • 最快',
      'upTo200KgComfortable': '最高 200 公斤 • 舒适',
      'weBoxAndWrapYour': '我们为您的物品装箱打包',
      'wingMobilePayment': 'Wing Moblie 支付',
      'buildingInfo': '🏢 大楼信息',
      'serviceOptions': '🧍 服务选项',
      // ── Trip tracking messages ──
      'arrivingNow': '即将到达',
      'cancel2000Fee': '取消（2,000 ៛ 费用)',
      'cannotCancelARideIn': '无法取消进行中的行程',
      'changedMyMind': '改变主意',
      'driverAssignedConnecting': '已分配司机— 正在连接...',
      'driverHasArrivedA2': '司机已到达 — 需支付 2,000 ៛ 费用',
      'driverHasArrived': '司机已到达！',
      'driverIsTakingTooLong': '司机耗时过长',
      'emergencyCameUp': '有紧急情况',
      'findingDriver': '正在寻找司机...',
      'findingYourDriver': '正在寻找您的司机...',
      'foundAnotherRide': '找到其他行程',
      'iMOnMyWay': '我在路上了!\n',
      'lookingForANearbyDriver': '正在寻找附近的司机…',
      'myRotehTrip': '我的 ROTEH 行程',
      'noDriverWasAvailableFor': '此行程无可用司机。请尝试重新预订。',
      'other': '其他',
      'pleaseCheckYourBelongingsBefore': '下车前请检查您的随身物品',
      'pleaseTellUsWhyYou': '请告诉我们您取消的原因',
      'share': '分享',
      'sharing': '分享中',
      'thisRideCannotBeCancelled': '此行程无法取消',
      'thisRideWasCancelled': '此行程已取消',
      'trackMyRotehTripLive': '实时追踪我的 ROTEH 行程 🛺\n',
      'trackMyRideLive': '实时追踪我的行程',
      'tripInProgress2': '行程进行中',
      'wrongPickupLocation': '上车地点错误',
      'yourDriverIsOnThe': '您的司机正在路上',
      'yourDriverIsOnThe2': '您的司机正在来接您的路上',
      'sosAlertSent': '🆘 SOS 警报已发送',
      'youReAlmostAtYour': '🔔 您即将到达目的地',
      // ── ride_booking messages ──
      'abaPay': 'ABA Pay',
      'acleda': 'ACLEDA',
      'aeonMallSenSok': 'Aeon Mall Sen Sok',
      'bike2': '自行车',
      'carPremium': '高级轿车',
      'carStandard': '标准轿车',
      'confirmDestination2': '确认目的地',
      'confirmDestinations': '确认目的地',
      'detectingLocation': '正在检测位置…',
      'dragMapToSetDestination': '拖动地图设置目的地',
      'invalidOrExpiredCode': '代码无效或已过期',
      'locationPermissionDenied': '位置权限被拒绝',
      'lookingForADriver': '正在寻找司机…',
      'meteredFare': '打表计费',
      'motorcycle': '摩托车',
      'nightMarketRiverside': '夜市(河畔)',
      'phnomPenhInternationalAirport': '德乔国际机场（KTI）',
      'pickupLocation3': '上车地点',
      'royalPalace': '皇宫',
      'sharedRide': '拼车',
      'tapMapToSetPickup': '点击地图设置上车点',
      'tellDriverOnArrival': '到达时告知司机',
      'toulTomPongMarket': 'Toul Tom Pong 市场',
      'tukTuk2': '嘟嘟车',
      'tukTuk3': '嘟嘟车',
      'vanXl': '面包车 / XL',
      // ── delivery_screen messages ──
      'bookMoving': '预订搬迁',
      'deliveryAddress': '配送地址',
      'dragMapToSelectLocation': '拖动地图选择位置',
      'fromAndToAddressesAre': '需要填写起始和目的地址',
      'movingCrew': '搬迁团队',
      'movingFromFullAddress': '搬迁起始（完整地址）',
      'movingToFullAddress': '搬迁目的地（完整地址）',
      'noStairsCarry': '否（楼梯搬运）',
      'noDescription': '无描述',
      'notesOptional': '备注（可选）',
      'packageDescriptionOptional': '包裹描述（可选）',
      'pickupAddress': '取件地址',
      'pickupAndDeliveryAddressAre': '需要填写取件和配送地址',
      'scheduleDelivery2': '预约配送',
      'scheduleMoving': '预约搬迁',
      // ── Ride booking categories ──
      'carShort': '汽车',
      // ── Driver earnings screen ──
      'avgTrip': '平均/行程',
      'breakdown': '明细',
      'deliveries': '配送',
      'last30Days': '过去 30 天',
      'noEarningsHistoryYet': '暂无收入记录',
      'rides': '行程',
      'totalEarnings': '总收入',
      // ── Driver earnings messages ──
      'breakdownIsOnlyAvailableFor': '明细仅适用于每周/每月',
      'noEarningsInThisPeriod': '此期间无收入',
      'thisMonth': '本月',
      'thisWeek': '本周',
      'today': '今天',
      // ── Weekday abbreviations ──
      'mon': '周一',
      'tue': '周二',
      'wed': '周三',
      'thu': '周四',
      'fri': '周五',
      'sat': '周六',
      'sun': '周日',
      // ── Driver home screen ──
      'stairsCarry': ' 楼梯搬运',
      'n1204Trips': ' · 1,204 次行程',
      'n1204Trips2': '(1,204 次行程)',
      'n3Of5PeakHour': '今日已完成 5 次高峰时段行程中的 3 次',
      'n4Consecutive5StarRatings': '连续 4 次 5 星评分！',
      'n5StarStreak': '5 星连胜 🔥',
      'accountHolderName': '账户持有人姓名',
      'accountNumber': '账号',
      'active69Pm': '活跃时间 下午 6-9 点',
      'availableBalance': '可用余额',
      'bank': '银行',
      'confirmWithdrawal': '确认提现',
      'instantWithdrawal': '即时提现',
      'loadMore': '加载更多',
      'peakHourBonus': '高峰时段奖励',
      'rentalModeActive': '租赁模式已激活',
      'rentalRequestAccepted': '租赁请求已接受',
      'requestCancelled': '请求已取消',
      'resume': '恢复',
      'reviewedByAdminBeforeFunds': '资金发送前由管理员审核',
      'selectBank': '选择银行',
      'showAll': '显示全部',
      'tapToOpenTheMap': '点击打开地图查看目的地',
      'waitingForDeliveryOrdersIn': '正在等待您所在区域的配送订单',
      'waiting': '等待中...',
      'yesWithdraw': '是，提现',
      'youHaveAWithdrawalRequest': '您有一个提现请求等待管理员批准',
      'youLlBeNotifiedWhen': '当附近有乘客需要乘车时，您会收到通知',
      'yourVehicleIsListedFor': '您的车辆已登记为按小时租赁',
      'earnedToday': '今日收入',
      // ── Driver home messages ──
      'abaBank': 'ABA 银行',
      'acledaBank': 'ACLEDA 银行',
      'canadiaBank': '加华银行',
      'completeYourTripToReceive': '完成行程以接收新请求',
      'deliveryInProgress': '配送进行中',
      'headThereForHigherEarnings': '前往该处获取更高收入',
      'highDemandInYourArea': '您所在区域需求高',
      'movingInProgress': '搬迁进行中',
      'noBalanceToWithdraw': '无可提现余额',
      'noDestinationPassengerWillTell': '无目的地 — 乘客会告知您',
      'noTransactionsToday': '今日无交易',
      'pleaseEnterYourAccountNumber': '请输入您的账号和持有人姓名',
      'rideInProgress': '行程进行中',
      'thePassengerCancelledThatRide': '乘客取消了该行程请求',
      'toggleOnlineToAcceptRides': '切换上线以接受行程',
      'transactionHistory': '交易记录',
      'waitingForRequests': '等待请求中...',
      'withdrawalPendingApproval': '提现等待批准',
      'withdrawalsUnavailable': '提现不可用',
      'urgent': '⚡ 紧急',
      'offline2': '⭕ 离线',
      'newRequest': '🆕 新请求',
      'newDelivery': '📦 新配送',
      'newRental': '🚚 新租赁',
      'newMoving': '🚚 新搬迁',
      'busyOnATrip': '🟡 忙碌 — 行程中',
      'onlineReady': '🟢 在线 — 就绪',
      // ── helmet_check_screen ──
      'chooseFromGallery': '从图库选择',
      'gallery': '图库',
      'pleaseWearAHelmetBefore': '开始行程前请佩戴头盔。',
      'retake': '重拍',
      'takePhoto': '拍照',
      'tapToUploadPhoto': '点击上传照片',
      'uploadAPhotoToVerify': '上传照片以验证头盔是否正确佩戴',
      // ── helmet_check_screen messages ──
      'checkHelmet': '检查头盔',
      'checking': '检查中…',
      'helmetDetected': '检测到头盔！',
      'noHelmetDetected': '未检测到头盔 !',
      // ── driver_withdrawal_screen ──
      'amountKhr': '金额（瑞尔）',
      'bankNameOptional': '银行名称（可选）',
      'confirm': '确认',
      'noWithdrawalHistory': '无提现记录',
      'pleaseMakeSureTheseDetails': '请确保这些信息正确无误。提交后无法撤销。',
      'requestWithdrawal': '申请提现',
      'withdrawalRequestSubmitted': '提现请求已提交！',
      // ── driver_withdrawal_screen messages ──
      'accountName': '账户名称',
      'amount': '金额',
      'enterAValidAmount': '请输入有效金额',
      'enterAccountHolderName': '请输入账户持有人姓名',
      'enterAccountNumber': '请输入账号',
      'fullNameAsOnAccount': '账户上的全名',
      'method': '方式',
      'wing': 'Wing',
      'withdraw': '提现',
      'eGAbaAcledaWing': 'e.g. ABA, ACLEDA, Wing…',
      // ── driver_vehicle_screen ──
      'colorOptional': '颜色（可选）',
      'imagesUploaded': '图片已上传',
      'licensePlate': '车牌号',
      'make': '品牌',
      'model': '型号',
      'myVehicles': '我的车辆',
      'noVehiclesRegistered': '未注册车辆',
      'registerVehicle': '注册车辆',
      'registerYourVehicleToStart': '注册您的车辆以开始接受行程',
      'year': '年份',
      // ── driver_vehicle_screen messages ──
      'editVehicle': '编辑车辆',
      'honda': 'Honda',
      'makeModelAndPlateAre': '需要品牌、型号和车牌号',
      'motorbike': '摩托车',
      'saveChanges': '保存更改',
      'truck': '卡车',
      'vehicle': '车辆',
      'wave': 'Wave',
      // ── driver_trip_summary_screen ──
      'confirmed': '已确认',
      'fareSummary': '费用摘要',
      'paymentMethod2': '支付方式',
      'paymentReceived': '已收到付款',
      'totalFare': '总车费',
      'tripCompleted': '行程已完成！',
      // ── driver_trip_summary_screen messages ──
      'bike3': '自行车',
      'noDestinationToldInPerson': '无目的地 — 当面告知',
      'tukTuk4': '嘟嘟车',
      // ── driver_missions_screen ──
      'acceptAJobFromThe': '从主屏幕接受任务以在此处查看。',
      'avgFare': '平均车费',
      'earned': '已赚取',
      'noRidesYet': '暂无行程',
      'tapToRefreshForLatest': '点击刷新最新状态',
      'thisOrderWasCancelled': '此订单已取消',
      // ── driver_missions_screen messages ──
      'accepted2': '已接受',
      'arrived2': '已到达',
      'cancelled': '已取消',
      'delivery2': '配送',
      'done2': '完成',
      'delivered': '配送',
      'failedToLoadDeliveries': '加载配送失败',
      'failedToLoadMovings': '加载搬迁失败',
      'failedToLoadRideHistory': '加载行程记录失败',
      'inProgress': '进行中',
      'inTransit': '运输中',
      'loading2': '加载中',
      'moving2': '搬迁',
      'pickedUp': '已取件',
      // ── driver_history_screen ──
      'noMoreTrips': '没有更多行程',
      'noTripsYet': '暂无行程',
      'trip': '行程',
      'yourCompletedTripsWillAppear': '您完成的行程将显示在此处',
      // ── driver_history_screen messages ──
      'cancelled2': '已取消',
      'unknown': '未知',
      'yesterday': '昨天',
      // ── driver_document_upload_screen ──
      'optionalDocuments': '可选文件',
      'required': '必填',
      'requiredDocuments': '必需文件',
      'submitForReview': '提交审核',
      'uploadDocuments': '上传文件',
      'uploaded': '已上传',
      'yourDocumentsWillBeReviewed': '您的文件将在 1–2 个工作日内审核',
      // ── driver_document_upload_screen messages ──
      'driverLicense': '驾驶执照',
      'nationalIdPassport': '身份证/护照',
      'optionalTapToUpload': '可选— 点击上传',
      'otherDocument': '其他文件',
      'ready': '就绪！',
      'selfieWithId': '与身份证的自拍',
      'tapToUpload': '点击上传',
      'vehicleInsurance': '车辆保险',
      'vehicleRegistration': '车辆登记',
      // ── Driver vehicle types ──
      'van': '面包车',
      // ── Document upload ──
      'requiredDocumentsUploadedSuffix': '必需文件已上传',
      // ── Driver approval pending screen ──
      'applicationStatus': '申请状态',
      'pleaseReviewTheFeedbackOn': '请查看上方文件的反馈，然后重新提交更正后的照片。如需帮助请联系客服。',
      'reUploadDocuments': '重新上传文件',
      'refreshStatus': '刷新状态',
      'weLlNotifyYouOnce': '文件审核完成后我们会通知您。通常需要 1–2 个工作日。',
      'whatToDoNext': '下一步做什么',
      // ── Driver approval status ──
      'documentReviewResults': '文件审核结果',
      'documentStatus': '文件状态',
      'approvedExcl': '已批准！',
      'youCanNowGoOnline': '您现在可以上线接受行程了。',
      'applicationRejected': '申请被拒绝',
      'pleaseReviewDocsResubmit': '请检查您的文件并重新提交。',
      'underReview': '审核中',
      'ourTeamIsReviewing': '我们的团队正在审核您的申请。',
      'city': '城市',
      'serviceZone': '服务区域',
      'approvedStatus': '已批准',
      'rejectedStatus': '已拒绝',
      'pendingStatus': '待处理',
      // ── Driver delivery active screen ──
      'toUpdateProgressContinueFrom': '要更新进度，请从活动任务屏幕继续',
      'you': '您',
      // ── Driver delivery active screen ──
      'movingFrom': '搬迁起始',
      'movingTo': '搬迁目的地',
      'arriving': '即将到达',
      'arrivedAtLocation': '已到达地点',
      'loadingComplete': '装载完成',
      'markAsDelivered': '标记为已送达',
      'arrivedAtPickup': '已到达取件点',
      'packagePickedUp': '包裹已取件',
      'headingToPickupLocation': '前往取件地点',
      'atLocationLoadingItems': '在位置— 装载物品',
      'inTransitToNewLocation': '运往新地点',
      'movingCompleteExcl': '搬迁完成！',
      'headingToSender': '前往发件人',
      'atPickupCollectPackage': '在取件点— 收取包裹',
      'onTheWayToRecipient': '前往收件人',
      'deliveredExcl': '已送达！',
      'heading': '前往',
      'atLocation': '在位置',
      'atPickup': '在取件点',
      'youArrivedAtPickupLocation': '您已到达取件地点',
      'packagePickedUpHeadingToDropoff': '包裹已取件— 前往送达点 ',
      'arrivedAtMovingLocationStartLoading': '已到达搬迁地点— 开始装载',
      'loadingCompleteHeadingToNewLocation': '装载完成— 前往新地点',
      'minAway': '分钟路程',
      'senderNumberPrefix': '发件人 #',
      // ── Driver active trip screen ──
      'amountToCollect': '应收金额',
      'arrivedAtStop': '已到达站点',
      'callNow': '立即呼叫',
      'completeTrip': '完成行程',
      'emergencySos': '紧急 SOS',
      'enable': '启用',
      'enterFinalFare': '输入最终车费',
      'locationPermissionDeniedLiveTracking': '位置权限被拒绝 — 实时追踪和车费 ',
      'sos': 'SOS',
      'sendSos': '发送SOS',
      'thisTripHadNoDestination': '此行程未设置目的地— 以下是计算出的摘要。',
      'thisWillAlertEmergencyServices': '这将提醒紧急服务并通知 AutoRide 运营团队您的位置。',
      'tripCompleted2': '行程已完成',
      'kmH': '公里/小时',
      'sosSentHelpIsOn': '🚨 SOS 已发送！救援正在路上。',
      // ── Driver active trip screen ──
      'passengerNumberPrefix': '乘客 #',
      'noDestinationAskPassenger': '无目的地— 询问乘客',
      'bike4': '自行车',
      'tukTuk5': '嘟嘟车',
      'continueStraight': '继续直行',
      'youHaveArrivedAt': '您已到达',
      'noActiveRide': '无活动行程',
      'headingToPickup2': '前往上车点',
      'waitingAtPickup': '在上车点等待',
      'arrivedAtPickupBtn': '✅ 已到达上车点',
      'passengerOnBoardStartTrip': '🚗 乘客已上车— 开始行程',
      'backToDashboardBtn': '🏠 返回仪表板',


      'enterAValidAmount2': '请输入有效金额',
      'metered': '打表',
      'youEarnedPrefix': '您赚取了',
      'calculatedDistancePrefix': '计算距离',
      'looksWrongFartherThanTrip': '看起来不对— 这比柬埔寨境内任何行程都远。',
      'noFareReturnedForServiceType': '该服务类型未返回车费',
      'fareCalculationFailedPrefix': '车费计算失败：',
      'unknownError': '未知错误',
      'tripHadNoDestinationSuggested': '此行程未设置目的地。以下建议车费是根据。',
      'fromDistanceTravelledAdjust': '行驶距离计算的— 如有需要请调整',
      // ── Driver active trip screen 2 ──
      'tripInProgressCap': '行程进行中',
      'completeTripBtn': '🏁  完成行程',
      // ── accessibility_screen ──
      'accessibilityTitle': '无障碍功能',
      'save': '保存',
      'accessibilitySettingsSaved': '无障碍设置已保存。',
      'saveSettings': '保存设置',
      'visualSection': '视觉',
      'audioAndSpeechSection': '音频与语音',
      'interactionSection': '交互',
      'largeText': '大号文字',
      'largeTextSubtitle': '增大应用内全局字体大小',
      'highContrast': '高对比度',
      'highContrastSubtitle': '使用更强烈的颜色提升可视性',
      'reduceMotion': '减少动画',
      'reduceMotionSubtitle': '减少动画与过渡效果',
      'screenReaderSupport': '屏幕阅读器支持',
      'screenReaderSupportSubtitle': '为辅助技术优化标签',
      'hapticFeedback': '触觉反馈',
      'hapticFeedbackSubtitle': '在关键操作时震动提示',
      'largeTouchTargets': '大号触控区域',
      'largeTouchTargetsSubtitle': '更大的按钮与点击区域',
      'wheelchairAccessibleVehicles': '轮椅无障碍车辆',
      'wheelchairAccessibleVehiclesSubtitle': '仅显示无障碍车辆选项',
      // ── airport_trip_screen ──
      'airportTransferTitle': '机场接送',
      'toAirportTab': '前往机场',
      'fromAirportTab': '从机场出发',
      'freeWaitBannerMessage': '包含60分钟免费等待——我们会追踪您的航班并自动调整接机时间。',
      'dropoffAirportLabel': '目的地机场',
      'pickupAirportLabel': '出发机场',
      'pickupAddressLabel': '上车地址',
      'dropoffAddressLabel': '下车地址',
      'enterHomeHotelAddressHint': '输入您的家庭/酒店地址',
      'enterDestinationAddressHint': '输入您的目的地地址',
      'flightDetailsLabel': '航班信息',
      'flightNumberHint': '航班号 (例如 QH101)',
      'terminalHint': '航站楼 (例如 T1)',
      'departureTime': '出发时间',
      'arrivalTime': '到达时间',
      'vehicleTypeLabel': '车辆类型',
      'sedanLabel': '轿车',
      'upTo4Pax': '最多4人',
      'suvVanLabel': 'SUV/面包车',
      'upTo6Pax': '最多6人',
      'passengersAndLuggageLabel': '乘客与行李',
      'passengersLabel': '乘客',
      'luggageBagsLabel': '行李件数',
      'enterAddressForFareEstimate': '输入您的地址以查看预估费用。',
      'airportSurcharge': '机场附加费',
      'bookingFee': '预订费',
      'distanceFare': '里程费',
      'timeFare': '时长费',
      'nightSurcharge': '夜间附加费',
      'weekendSurcharge': '周末附加费',
      'holidaySurcharge': '节假日附加费',
      'fareRoundingAdjustment': '四舍五入调整',
      'luggageBagsCountLabel': '行李',
      'fixedPriceNoSurge': '固定价格 · 无浮动加价',
      'bookTransferPrefix': '预订接送 ·',
      'bookAirportTransfer': '预订机场接送',
      'fillAddressFlightDetailsError': '请填写您的地址、航班号和航班时间。',
      'airportFallback': '机场',
      // ── cancellation_policy_screen ──
      'cancellationPolicyTitle': '取消政策',
      'feesGoToDriversNote': '费用将支付给司机，作为对其时间的补偿。',
      'contactSupport': '联系客服',
      'beforeDriverAccepts': '司机接单前',
      'freeCancellation': '免费取消',
      'freeCancelBeforeAcceptDetail': '在司机接单前，您可以随时免费取消。',
      'afterDriverAccepts': '司机接单后',
      'cancelRangeMinutes': '{from}–{to}分钟',
      'cancelRangeFromMinutes': '{from}分钟及以上',
      'cancelFeeAmount': '{fee}瑞尔 费用',
      'cancelTierFreeDetail': '在此期间取消是免费的。',
      'cancelTierFeeDetail': '如果您在此期间取消，将收取{fee}瑞尔的取消费。',
      'cancellationPolicyLoadFailed': '无法加载取消政策。',
      'afterDriverArrives': '司机到达后',
      // ── car_rental_screen ──
      'durMonth1': '一个月',
      'durMonth2': '二个月',
      'durMonth3': '三个月',
      'durMonth6': '六个月',
      'durYear1': '一年',
      'durYear2': '两年',
      'pickUpLabel': '自取',
      'collectCarMyself': '我将自行取车',
      'deliverCarToAddress': '将车送到我的地址',
      'tapToSetPickupLocation': '点击设置取车地点',
      'tapToSetDeliveryLocation': '点击设置送车地点',
      'setPickupLocationTitle': '设置取车地点',
      'setDeliveryLocationTitle': '设置送车地点',
      'suvLabel': 'SUV',
      'electricLabel': '电动车',
      'locationTypeLabel': '地点类型',
      'rentalDurationTitle': '租期',
      'endsPrefix': '结束于',
      'payInCashOnPickup': '取车时现金支付',
      'failedToApplyCoupon': '优惠券应用失败。',
      'bookedHashPrefix': '已预订 #',
      'datesLabel': '日期',
      'dailyRateLabel': '每日租金',
      'renterLabel': '租车人',
      'selectVehicleBeforeBooking': '请先选择车辆再预订。',
      'setDeliveryLocationError': '请设置送车地点。',
      'enterNamePhoneError': '请输入您的姓名和电话号码。',
      'rentalVehicleTitle': '租车',
      'locationLabel': '地点',
      'vehicleForRentLabel': '可租车辆',
      'browseAvailableVehicle': '浏览可租车辆',
      'tapToViewAllVehicles': '点击查看所有可租车辆',
      'rentalPeriodLabel': '租期',
      'daysLabel': '天',
      'endsLabel': '结束于',
      'startDateLabel': '开始日期',
      'endDateAutoLabel': '结束日期 (自动)',
      'yourInformationLabel': '您的信息',
      'notesOptionalLabel': '备注 (可选)',
      'anySpecialRequestsHint': '任何特殊要求…',
      'couponCodeLabel': '优惠券代码',
      'discountAppliedSuffix': '折扣已应用',
      'enterCouponCodeHint': '输入优惠券代码',
      'bookingSummaryLabel': '预订摘要',
      'discountLabel': '折扣',
      'bookNowLabel': '立即预订',
      'selectAVehicleLabel': '选择车辆',
      'rentDashPrefix': '租用 —',
      'failedToLoadVehicles': '加载车辆失败',
      'noVehicleAvailableForRent': '暂无可租车辆。',
      'photosCountSuffix': '张照片',
      'daysCapLabel': '天数',
      // ── charging_stations ──
      'favoritesLabel': '收藏',
      'fastChargingLabel': '快速充电',
      'showLess': '收起',
      'myLocationLabel': '我的位置',
      'sortedByDistanceFromLocation': '按距您的位置排序',
      'sortedByDistanceFromPhnomPenh': '按距金边的距离排序 (位置不可用)',
      'findingYourLocation': '正在查找您的位置…',
      'myLocationUnavailable': '我的位置不可用',
      'nearbyChargingStationsTitle': '附近的充电站',
      'availableSuffix': '可用',
      // ── edit_profile_screen ──
      'takeAPhoto': '拍照',
      'couldNotUpdatePhotoPrefix': '无法更新照片：',
      'couldNotUpdatePhotoTryAgain': '无法更新照片，请重试。',
      'profileUpdatedSuccess': '个人资料更新成功！',
      'tapPhotoToChange': '点击照片以更换',
      'otpRequiredBadge': '需要验证码',
      'changingPhoneRequiresOtp': '更改您的电话号码需要通过验证码验证。',
      'enterSixDigitCode': '请输入6位验证码。',
      'verifyPhoneNumberTitle': '验证电话号码',
      'codeSentToPrefix': '6位验证码已发送至',
      'devCodePrefix': '开发验证码：',
      'sendingOtpEllipsis': '正在发送验证码...',
      'expiresInPrefix': '将在以下时间后过期',
      'codeExpired': '验证码已过期',
      'resendInPrefix': '将在以下时间后重新发送',
      'verify': '验证',
      // ── family_screen ──
      'familyAccountTitle': '家庭账户',
      'addMemberTooltip': '添加成员',
      'createFamilyGroupTitle': '创建家庭群组',
      'familyGroupDescription': '为家庭成员预订出行。他们不需要安装应用——只需一个电话号码。',
      'groupNameHint': '群组名称 (例如 Sokkheng 家庭)',
      'createGroup': '创建群组',
      'membersLabel': '成员',
      'add': '添加',
      'noMembersYetMsg': '暂无成员。添加家庭成员即可为他们预订出行。',
      'membersCountSuffix': '位成员',
      'fromFamilyGroupQuestionSuffix': '从家庭群组中移除吗？',
      'hasAutorideAccountLabel': '拥有 ROTEH APP 账户',
      'bookLabel': '预订',
      'addFamilyMemberTitle': '添加家庭成员',
      'fullNameStarHint': '姓名 *',
      'phoneNumberStarHint': '电话号码 *',
      'relationshipHint': '关系 (例如 母亲、朋友…)',
      'addMemberBtn': '添加成员',
      'fullNameHint': '姓名',
      'phoneNumberHint2': '电话号码',
      'mother': '母亲',
      'father': '父亲',
      'spouse': '配偶',
      'son': '儿子',
      'daughter': '女儿',
      'sibling': '兄弟姐妹',
      'friend': '朋友',
      // ── loyalty_screen ──
      'rotehRewardsTitle': 'ROTEH 奖励',
      'redeemPointsTitle': '兑换积分',
      'redeem500ptsQuestion': '用500积分兑换下次行程5,000瑞尔折扣？',
      'pts500Redeemed': '已兑换500积分！折扣已应用于下次行程。',
      'redeem500pts': '兑换500积分',
      'rotehPointsLabel': 'ROTEH 积分',
      'ptsSuffix': '积分',
      'maxTierReached': '已达到最高等级',
      'ptsToPlatinumSuffix': '积分即可升至 Platinum级',
      'ptsToGoldSuffix': '积分即可升至Gold级',
      'ptsToSilverSuffix': '积分即可升至Silver级',
      'membershipTiersTitle': '会员等级',
      'currentBadge': '当前',
      'howToEarnTitle': '如何赚取积分',
      'pointsActivityTitle': '积分活动',
      'bronzeTier': 'Bronze',
      'silverTier': 'Silver',
      'goldTier': 'Gold',
      'platinumTier': 'Platinum',
      'ptsPer1000Spent10': '每消费1,000瑞尔获得10积分',
      'birthdayBonus100pts': '生日奖励100积分',
      'basicSupport': '基础客服支持',
      'ptsPer1000Spent12': '每消费1,000瑞尔获得12积分',
      'priorityMatching': '优先匹配',
      'fareDiscount5pct': '车费折扣5%',
      'ptsPer1000Spent15': '每消费1,000瑞尔获得15积分',
      'fareDiscount10pct': '车费折扣10%',
      'freeCancellation3perMo': '每月3次免费取消',
      'ptsPer1000Spent20': '每消费1,000瑞尔获得20积分',
      'fareDiscount15pct': '车费折扣15%',
      'dedicatedSupportLine': '专属客服热线',
      'freeCancellationUnlimited': '无限次免费取消',
      'completeATrip': '完成一次行程',
      'ptsPer1000Simple10': '每1,000瑞尔10积分',
      'rateYourDriver': '为司机评分',
      'ptsBonus50': '奖励50积分',
      'referAFriend': '邀请好友',
      'ptsPerReferral500': '每次推荐500积分',
      'pointsFallback': '积分',
      // ── my_rentals_screen ──
      'noRentalsFound': '未找到租赁记录',
      'orderHashPrefix': '订单 #',
      'rentalHashPrefix': '租赁 #',
      'rentalVehicleBadge': '租赁车辆',
      'cancelRentalTitle': '取消租赁',
      'cancelRentalConfirmMsg': '您确定要取消此租赁吗？',
      'yesCancelBtn': '是，取消',
      'electricVehicleLabel': '电动车',
      // ── notifications_screen ──
      'justNow': '刚刚',
      'minAgoSuffix': '分钟前',
      'hrsAgoSuffix': '小时前',
      'daysAgoSuffix': '天前',
      'markAllRead': '全部标为已读',
      'noNotificationsYet': '暂无通知',
      'notificationFallback': '通知',
      // ── payment_methods_screen ──
      'cardsSection': '银行卡',
      'noCardsAddedYet': '尚未添加银行卡',
      'linkedAccountsSection': '关联账户',
      'addMethodLabel': '添加支付方式',
      'defaultBadge': '默认',
      'setAsDefaultOption': '设为默认',
      'removeOption': '删除',
      'unlinkOption': '取消关联',
      'linkedLabel': '已关联',
      'notLinkedLabel': '未关联',
      'addPaymentMethodTitle': '添加支付方式',
      'cardOptionLabel': '银行卡',
      'cardOptionSubtitle': 'VISA、万事达卡、PayPal',
      'alreadyLinked': '已关联',
      'linkYourAbaAccount': '关联您的ABA账户',
      'linkYourAcledaAccount': '关联您的ACLEDA账户',
      'cardNumberLabel': '卡号',
      'expiryDateLabel': '有效期',
      'cvvLabel': 'CVV',
      'setAsDefaultSwitch': '设为默认',
      'addCardBtn': '添加银行卡',
      'phoneNumberHintExample': '例如 012 345 678',
      'linkAccountBtn': '关联账户',
      'linkAbaPayTitle': '关联ABA Pay',
      'linkAcledaPayTitle': '关联ACLEDA Pay',
      'enterValidCardNumber': '请输入有效的卡号',
      'enterExpiryMMYY': '请输入有效期，格式为MM/YY',
      'cardExpiredError': '此卡已过期',
      'enterValidCvv': '请输入有效的CVV',
      'expiresPrefix': '有效期至',
      'minOrderPrefix': '最低订单',
      'byCodeTab': '按代码',
      'byRotehPayTab': '按 ROTEH Pay',
      'payWithRotehPay': '使用 ROTEH Pay 支付',
      'enterAccountPhoneNumber': '请输入账户电话号码',
      // ── promo_screen ──
      'promosTabLabel': '优惠',
      'storeTabLabel': '商店',
      'myVouchersTabLabel': '我的代金券',
      'enterPromoCodeTitle': '输入优惠码',
      'codeHintExample': '例如 ROTEH15',
      'invalidExpiredPromoCode': '优惠码无效或已过期。',
      'couldNotValidateCode': '无法验证代码，请重试。',
      'discountAppliedFallback': '折扣已应用',
      'offSuffix': '折扣',
      'promoAppliedDashPrefix': '优惠',
      'appliedDashSuffix': '已应用 —',
      'codeCopiedPrefix': '代码',
      'copiedSuffix': '已复制！',
      'availableVouchersTitle': '可用代金券',
      'noExpiry': '无过期日期',
      'promo1Title': '首次乘车5折优惠',
      'promo1Desc': '仅限新用户使用。最高优惠5美元。',
      'promo2Title': '任意行程85折优惠',
      'promo2Desc': '随时可用。最低车费3.00美元。',
      'promo3Title': '配送优惠1美元',
      'promo3Desc': '适用于标准配送和当日达配送。',
      'promo4Title': '免费EV充电站地图',
      'promo4Desc': '免费获取高级充电站路线导航。',
      'promo5Title': '周末8折优惠',
      'promo5Desc': '周六至周日可用。最高优惠8美元。',
      'freeLabel': '免费',
      // ── qr_payment_screen ──
      'qrPaymentTitle': '二维码支付',
      'myQrTabLabel': '我的二维码',
      'enterValidAmountKhr': '请输入有效的瑞尔金额。',
      'generateQrToReceive': '生成收款二维码',
      'enterAmountShareQr': '输入金额并与付款人分享二维码。',
      'amountKhrLabel': '金额 (瑞尔)',
      'generatingEllipsis': '正在生成…',
      'generateQrBtn': '生成二维码',
      'qrExpired': '二维码已过期',
      'waitingForPayment': '等待付款…',
      'qrReferenceCopied': '二维码参考编号已复制',
      'newQrBtn': '新二维码',
      'noQrPaymentHistory': '暂无二维码支付记录',
      'paidStatus': '已支付',
      // ── rate_driver_screen ──
      'rateYourTripTitle': '为行程评分',
      'howWasYourTripQuestion': '您的行程体验如何？',
      'tapToRate': '点击评分',
      'ratingTerrible': '很差',
      'ratingBad': '较差',
      'ratingOkay': '一般',
      'ratingGood': '不错',
      'ratingExcellent': '非常好！',
      'whatDidYouLoveQuestion': '您喜欢哪些方面？',
      'whatWentWrongQuestion': '哪里出了问题？',
      'addCommentOptionalHint': '添加评论 (可选)...',
      'addATipQuestion': '添加小费？',
      'noTipLabel': '不给小费',
      'tipFailedPrefix': '小费支付失败：',
      'submitRatingBtn': '提交评分',
      'thankYouExcl': '谢谢！',
      'feedbackHelpsImprove': '您的反馈帮助我们为所有人改善体验。',
      'greatDrivingTag': '驾驶技术好',
      'veryFriendlyTag': '非常友好',
      'cleanCarTag': '车内整洁',
      'onTimeTag': '准时',
      'safeRideTag': '行程安全',
      'latePickupTag': '接客迟到',
      'rudeTag': '态度不佳',
      'unsafeDrivingTag': '驾驶不安全',
      'dirtyCarTag': '车内不干净',
      'wrongRouteTag': '路线错误',
      // ── referral_screen ──
      'referralTitle': '推荐',
      'copiedExcl': '已复制！',
      'shareAndEarn': '分享赚积分',
      'giveFriendsDiscountDesc': '为好友首次乘车提供10,000瑞尔优惠。\n每次推荐您可获得500积分。',
      'yourReferralCode': '您的推荐码',
      'shareWithFriends': '与好友分享',
      'friendsReferred': '已推荐好友',
      'pointsEarnedLabel': '已获积分',
      'friendsWhoJoined': '已加入的好友',
      'joinedPrefix': '加入于',
      'joinRotehWithCodePrefix': '使用我的邀请码加入ROTEH：',
      'get10000OffFirstRideSuffix': '首次乘车可享10,000瑞尔优惠！',
      'downloadRotehNow': '立即下载ROTEH。',
      // ── safety_screen ──
      'safetyCenterTitle': '安全中心',
      'emergencySosLabel': '紧急SOS',
      'holdToActivate': '长按1秒以激活',
      'fakeCallLabel': '虚拟来电',
      'stopSharingLabel': '停止分享',
      'reportLabel': '举报',
      'emergencyContactsTitle': '紧急联系人',
      'noEmergencyContactsYet': '暂无紧急联系人',
      'safetyResourcesTitle': '安全资源',
      'emergencyPhoneNumbers': '紧急电话：117 / 119',
      'reportIncidentLabel': '举报事件',
      'safetyGuidelinesLabel': '安全指南',
      'sosSentToPrefix': '🆘 SOS已发送给',
      'contactsSuffix': '位联系人',
      'noActiveRideToShare': '没有正在进行的行程可分享',
      'sharingStopped': '已停止分享',
      'tripLinkSharedTitle': '行程链接已分享',
      'shareLinkTrackDesc': '分享此链接，让他人可以实时追踪您的行程。',
      'sosWillBeSentNoContacts': 'SOS警报将立即发送。您尚未添加紧急联系人。',
      'sosWillBeSentToContactsPrefix': 'SOS将立即发送给',
      'emergencyContactsImmediatelySuffix': '位紧急联系人',
      'harassmentTag': '骚扰',
      'unsafeDrivingTitleTag': '驾驶不安全',
      'overchargeTag': '乱收费',
      'otherTag': '其他',
      'describeWhatHappenedHint': '描述发生的情况…',
      'submitReportBtn': '提交举报',
      'incidentReportedThanks': '事件已举报，谢谢您。',
      'addEmergencyContactTitle': '添加紧急联系人',
      'relationshipHintExample': '关系 (例如 妈妈)',
      'notifyOnSos': 'SOS时通知',
      'notifyOnTripShare': '分享行程时通知',
      'addContactBtn': '添加联系人',
      'contactAddedExcl': '联系人已添加！',
      'editContactTitle': '编辑联系人',
      'contactUpdatedExcl': '联系人已更新！',
      'removeContactQuestion': '移除联系人？',
      'willBeRemovedFromContactsSuffix': '将从您的紧急联系人中移除。',
      'contactRemoved': '联系人已移除',
      'sosTagLabel': 'SOS',
      'tripShareTagLabel': '行程分享',
      'fakeCallChooseDelayTitle': '虚拟来电 — 选择延迟时间',
      'phoneWillRingDesc': '您的手机将在所选延迟后响起。',
      'nowSecLabel': '立即 (5秒)',
      'inSecLabel10': '10秒后',
      'inSecLabel30': '30秒后',
      'inMinLabel1': '1分钟后',
      'incomingCallEllipsis': '来电中…',
      'fakeCallInPrefix': '虚拟来电将在',
      'secondsSuffix': '秒后…',
      // ── saved_places_screen ──
      'deletePlaceQuestion': '删除地点？',
      'removePlacePrefix': '移除',
      'fromSavedPlacesQuestionSuffix': '从您保存的地点中吗？',
      'removedSuffix': '已移除',
      'addHomeLabel': '添加家',
      'addWorkLabel': '添加公司',
      'yourPlacesLabel': '您的地点',
      'saveHomeWorkDesc': '保存家、公司或常用地点\n以便更快预订。',
      'addAPlaceBtn': '添加地点',
      'editPlaceTitle': '编辑地点',
      'addPlaceTitle': '添加地点',
      'labelHintExample': '家、公司、健身房…',
      'openingMapEllipsis': '正在打开地图…',
      'searchOrDragPinHint': '搜索或在地图上拖动图钉',
      'setAsDefaultCheckbox': '设为默认',
      'labelAndLocationRequired': '标签和位置为必填项',
      'setLocationTitle': '设置位置',
      'labelFieldTitle': '标签',
      // ── scheduled_rides_screen ──
      'scheduledRidesTitle': '预约行程',
      'pastLabel': '已过期',
      'inPrefix': '还有',
      'daysLabel2': '天',
      'hrsLabel': '小时',
      'minLabel': '分钟',
      'cancelRideTitle': '取消行程',
      'cancelScheduledRideConfirm': '您确定要取消此预约行程吗？',
      'keepLabel': '保留',
      'rideCancelledPeriod': '行程已取消',
      'noUpcomingRides': '暂无即将到来的行程',
      'scheduleRideToSeeHere': '预约行程后将显示在此处',
      'modifyComingSoon': '修改功能即将推出。',
      'modifyBtn': '修改',
      'jan': '一月', 'feb': '二月', 'mar': '三月', 'apr': '四月',
      'may': '五月', 'jun': '六月', 'jul': '七月', 'aug': '八月',
      'sep': '九月', 'oct': '十月', 'nov': '十一月', 'dec': '十二月',
      // ── subscription_screen ──
      'subscriptionPlansTitle': '订阅套餐',
      'plansTab': '套餐',
      'upgradeToPrefix': '升级至',
      'subscribeToPrefix': '订阅',
      'paymentColonPrefix': '支付方式：',
      'upgradeBtn': '升级',
      'subscribeBtn': '订阅',
      'cancelSubscriptionQuestion': '取消订阅？',
      'benefitsContinueDesc': '权益将持续到套餐到期。自动续费将被关闭。',
      'cancelPlanBtn': '取消套餐',
      'autoRideWalletLabel': 'ROTEH APP 钱包',
      'creditDebitCardLabel': '信用卡/借记卡',
      'cardLabel': '银行卡',
      'changePlanLabel': '更改套餐',
      'choosePlanLabel': '选择套餐',
      'rideCreditLabel': '乘车额度',
      'leftSuffix': '剩余',
      'cancellationsLeftLabel': '剩余取消次数',
      'autoRenewLabel': '自动续费',
      'creditSuffix': '额度',
      'offRidesSuffix': '乘车折扣',
      'offDeliverySuffix': '配送折扣',
      'noSurgeLabel': '无浮动加价',
      'freeCancellationsPerMonthSuffix': '每月免费取消次数',
      'bonusLoyaltyPointsSuffix': '额外积分奖励',
      'currentPlanBtn': '当前套餐',
      'noBillingHistoryYet': '暂无账单记录。',
      'newSubscriptionLabel': '新订阅',
      'renewalLabel': '续费',
      'cancellationLabel': '取消',
      // ── support_screen ──
      'myTicketsTab': '我的工单',
      'faqTab': '常见问题',
      'noSupportTickets': '暂无支持工单',
      'tapPlusToCreateTicket': '点击+创建新的支持请求。',
      'openParenPrefix': '进行',
      'resolvedParenPrefix': '已解决',
      'repliesCountLabel': '条回复',
      'dAgoSuffix': '天前',
      'hAgoSuffix': '小时前',
      'mAgoSuffix': '分钟前',
      'needHelpTitle': '需要帮助？',
      'cantFindAnswerDesc': '找不到答案？开一个工单。',
      'subjectAndMessageRequired': '主题和消息为必填项',
      'newSupportTicketTitle': '新建支持工单',
      'priorityColonLabel': '优先级：',
      'highPriority': '高',
      'urgentPriority': '紧急',
      'subjectLabel': '主题',
      'describeYourIssueLabel': '描述您的问题',
      'submitTicketBtn': '提交工单',
      'noRepliesYetDesc': '暂无回复。我们将在24小时内回复。',
      'writeAReplyHint': '写回复…',
      'supportTeamLabel': '支持团队',
      'faq1Q': '如何预订行程？',
      'faq1A': '打开应用，点击预订行程，设置上车点和目的地，然后确认。',
      'faq2Q': '如何取消行程？',
      'faq2A': '预订过程中您可以在追踪页面点击取消。司机出发后取消可能需要收取取消费。',
      'faq3Q': '支付方式如何运作？',
      'faq3A': '我们接受现金和钱包支付。请在确认预订前选择您的支付方式。',
      'faq4Q': '如何举报问题？',
      'faq4A': '点击上方的+按钮创建支持工单。我们的团队将在24小时内回复。',
      'faq5Q': 'ROTEH APP 在哪些地区运营？',
      'faq5A': '目前在柬埔寨金边地区提供服务。',
      'faq6Q': '如何成为司机？',
      'faq6A': '以"司机"角色注册，完成身份验证，然后注册您的车辆。',
      'faq7Q': '如果司机没有出现怎么办？',
      'faq7A': '使用追踪页面上的SOS或联系按钮，或取消并重新预订。',
      // ── trip_history_screen ──
      'tripTitle': '行程',
      'spentLabel': '消费',
      'noTripsFound': '未找到行程',
      'byDayLabel': '按日期',
      'filterTripsTitle': '筛选行程',
      'resetLabel': '重置',
      'applyFiltersBtn': '应用筛选',
      'allTripsLabel': '所有行程',
      'tipSuffix2': '小费',
      'thisTripNoDestinationRebook': '此行程没有目的地可重新预订。',
      'bookAgainBtn': '再次预订',
      'rateBtn': '评分',
      // ── voucher_screen ──
      'vouchersTitle': '代金券',
      'voucherClaimedCheckMy': '代金券领取成功！请查看我的代金券。',
      'noVouchersAvailable': '暂无可用代金券',
      'claimBtn': '领取',
      'noVouchersYet': '暂无代金券',
      'claimFromStoreTab': '从商店标签页领取',
      'usedBadge': '已使用',
      'usedBadgeCap': '已使用',
      'expPrefix': '有效期至',
      'voucherFallback': '代金券',
      // ── business_screen ──
      'tabAccount': '账户',
      'tabMembers': '成员',
      'registerABusiness': '注册企业',
      'joinWithInviteCode': '使用邀请码加入',
      'joinBusinessAccount': '加入企业账户',
      'inviteCodeHint': '邀请码(例如 ABC12345)',
      'joinBusiness': '加入企业',
      'registerBusiness': '注册企业',
      'companyNameRequiredHint': '公司名称 *',
      'taxIdHint': '税号 / 增值税号',
      'industryHint': '行业',
      'contactPerson': '联系人',
      'contactNameRequiredHint': '联系人姓名 *',
      'contactPhoneHint': '联系电话',
      'billingEmailRequiredHint': '账单邮箱 *',
      'billingCycle': '账单周期',
      'companyAddressHint': '公司地址',
      'taxIdLabel': '税号',
      'billingEmailLabel': '账单邮箱',
      'billingCycleLabel': '账单周期',
      'contactLabel': '联系人',
      'addressLabel': '地址',
      'inviteCodeLabel': '邀请码',
      'editAccount': '编辑账户',
      'editBusinessAccount': '编辑企业账户',
      'companyNameHint': '公司名称',
      'billingEmailHint': '账单邮箱',
      'contactNameHint': '联系人姓名',
      'addressHint': '地址',
      'roleMemberAdminHint': '角色(成员 / 管理员)',
      'departmentHint': '部门',
      'costCenterHint': '成本中心',
      'employeeIdHint': '员工编号',
      'monthlyLimitKhrHint': '每月限额(瑞尔)',
      'businessTripDefault': '商务出行',
      'weeklyLabel': '每周',
      'monthlyLabel': '每月',
      // ── settings_screen ──
      'settingsTitle': '设置',
      'biometricLogin': '生物识别登录',
      // ── onboarding_screen ──
      'next': '下一步',
      'getStarted': '开始使用',
      'onboardWelcomeTitle': '欢迎使用 ROTEH',
      'onboardWelcomeSubtitle': '您在柬埔寨的智能出行伙伴。\n快速、安全、实惠的出行触手可及。',
      'onboardBookTitle': '几秒钟内完成预订',
      'onboardBookSubtitle': '选择您的车型 — 汽车、摩托车或嘟嘟车。\n确认前获取车费估算。',
      'onboardPaySubtitle': '使用现金或 ROTEH Pay 钱包支付。\n通过二维码向好友转账。',
      'onboardRewardsTitle': '赚取奖励',
      'onboardRewardsSubtitle': '每次行程都能获得 ROTEH 积分。\n从青铜升级到白金，解锁专属福利。',
      // ── auth_service ──
      'phoneVerificationFailedMsg': '手机验证失败。',
      'couldNotObtainFirebaseToken': '无法获取 Firebase ID 令牌。',
      // ── marketplace_screen ──
      'browseTab': '浏览',
      'myOrdersTab': '我的订单',
      'popularListings': '热门商品',
      'recentListings': '最新商品',
      'allListingsTitle': '所有商品',
      'forSaleLabel': '出售',
      'forRentLabel': '出租',
      'saleAndRentLabel': '出售兼出租',
      'listingTypeLabel': '商品类型',
      'conditionNewLabel': '全新',
      'conditionUsedLabel': '二手',
      'conditionRefurbishedLabel': '翻新',
      'conditionRefurbAbbrev': '翻新',
      'viewsCountSuffix': '次浏览',
      'viewsSpecLabel': '浏览次数',
      'perDaySpecLabel': '每天',
      'buyNowLabel': '立即购买',
      'rentNowLabel': '立即租用',
      'searchLocationHint': '搜索位置…',
      'dragMapToSetLocation': '拖动地图设置位置',
      'setPickupHere': '设为取件地点',
      'setDropoffHere': '设为送达地点',
      'pickUpShortLabel': '自取',
      'deliverCarToMyAddress': '将车送到我的地址',
      'addItemTitle': '添加商品',
      'searchListingsHint': '搜索商品…',
      'selectRentalDatesError': '请选择租赁开始和结束日期。',
      'walletLabel': '钱包',
      'onlineLabel': '在线支付',
      'buyItemTitle': '购买商品',
      'rentItemTitle': '租用商品',
      'durationLabel': '时长',
      'selectLabel': '选择',
      'anySpecialInstructionsHint': '任何特别说明…',
      'orderSummaryLabel': '订单摘要',
      'vehicleLabel': '车辆',
      'totalSummaryLabel': '总计',
      'confirmRentalLabel': '确认租赁',
      'selectDatesToContinue': '选择日期以继续',
      'proceedToCheckout': '前往结账',
      'noListingsYetTitle': '暂无商品',
      'postSomethingToStartSelling': '发布商品开始销售',
      'purchaseLabel': '购买',
      'titleIsRequiredError': '标题为必填项。',
      'priceMustBeNumberError': '价格必须为数字。',
      'enterValidPricePrefix': '请输入有效价格：',
      'updatedExclaim': '已更新！',
      'postedExclaim': '已发布！',
      'egIphone14Pro': '例如 iPhone 14 Pro',
      'egRemovableCanopy': '例如 可拆卸车篷',
      'egBkk1PhnomPenh': '例如 金边 BKK1',
      'saleTypeLabel': '出售',
      'bothTypeLabel': '两者皆可',
      'draftStatusLabel': '草稿',
      'pausedStatusLabel': '已暂停',
      'soldStatusLabel': '已售出',
      'postListingBtn': '发布商品',
      'buyingTab': '购买中',
    },
  };

  String tr(String key) {
    final lang = locale.languageCode;
    return _t[lang]?[key] ?? _t['en']?[key] ?? key;
  }

  String get appName => tr('appName');
  String get tagline => tr('tagline');
  String get copyright => tr('copyright');
  String get whoAreYou => tr('whoAreYou');
  String get selectRole => tr('selectRole');
  String get passenger => tr('passenger');
  String get passengerSub => tr('passengerSub');
  String get driver => tr('driver');
  String get driverSub => tr('driverSub');
  String get home => tr('home');
  String get charging => tr('charging');
  String get chat => tr('chat');
  String get profile => tr('profile');
  String get earnings => tr('earnings');
  String get dashboard => tr('dashboard');
  String get bookRide => tr('bookRide');
  String get bookRideSub => tr('bookRideSub');
  String get delivery => tr('delivery');
  String get deliverySub => tr('deliverySub');
  String get marketplace => tr('marketplace');
  String get marketplaceSub => tr('marketplaceSub');
  String get evStations => tr('evStations');
  String get evStationsSub => tr('evStationsSub');
  String get safety => tr('safety');
  String get payment => tr('payment');
  String get support => tr('support');
  String get recentTrips => tr('recentTrips');
  String get seeAll => tr('seeAll');
  String get services => tr('services');
  String get quickActions => tr('quickActions');
  String get whereAreYouGoing => tr('whereAreYouGoing');
  String get bookNow => tr('bookNow');
  String get scheduleRide => tr('scheduleRide');
  String get scheduleForLater => tr('scheduleForLater');
  String get sendNow => tr('sendNow');
  String get evChargingStations => tr('evChargingStations');
  String get buy => tr('buy');
  String get rent => tr('rent');
  String get trackTrip => tr('trackTrip');
  String get driverOnTheWay => tr('driverOnTheWay');
  String get tripInProgress => tr('tripInProgress');
  String get arrived => tr('arrived');
  String get paySecurely => tr('paySecurely');
  String get emergencySOS => tr('emergencySOS');
  String get selectLanguage => tr('selectLanguage');
  String get language => tr('language');
  String get goodMorning => tr('goodMorning');
  String get goodAfternoon => tr('goodAfternoon');
  String get goodEvening => tr('goodEvening');
  String get hello       => tr('hello');
  String get welcome     => tr('welcome');
  String get online => tr('online');
  String get offline => tr('offline');
  String get driverDashboard => tr('driverDashboard');
  String get messages => tr('messages');
  String get paymentSuccessful => tr('paymentSuccessful');
  String get signOut => tr('signOut');
  String get paymentMethods => tr('paymentMethods');
  String get safetySettings => tr('safetySettings');
  String get tripHistory => tr('tripHistory');
  String get notifications => tr('notifications');
  String get helpSupport => tr('helpSupport');
  String get bankPayouts => tr('bankPayouts');
  String get documents => tr('documents');
  String get navigate => tr('navigate');
  String get available => tr('available');
  String get connectionErrorRetry => tr('connectionErrorRetry');
  String get sortBy => tr('sortBy');
  String get sortNewest => tr('sortNewest');
  String get sortOldest => tr('sortOldest');
  String get sortPriceHigh => tr('sortPriceHigh');
  String get sortPriceLow => tr('sortPriceLow');
  String get searchRentalsHint => tr('searchRentalsHint');
  String get rentalBookedSuccess => tr('rentalBookedSuccess');
  String get rentalHeaderSubtitle => tr('rentalHeaderSubtitle');

  // Fills {name} placeholders in a translated template.
  String _fill(String key, Map<String, Object?> args) {
    var out = tr(key);
    args.forEach((k, v) => out = out.replaceAll('{$k}', '$v'));
    return out;
  }

  String drvTopUpMsg(String amount) => _fill('drvTopUpMsg', {'amount': amount});
  String drvShortBy(String amount) => _fill('drvShortBy', {'amount': amount});
  String drvKmAway(String km) => _fill('drvKmAway', {'km': km});
  String drvEndsInHm(int h, int m) => _fill('drvEndsInHm', {'h': h, 'm': m});
  String drvEndsInMin(int m) => _fill('drvEndsInMin', {'m': m});
  String drvTripsCount(int n) => _fill('drvTripsCount', {'n': n});
  String drvSurgeInside(String x) => _fill('drvSurgeInside', {'x': x});
  String drvSurgeNearby(String x, String zone) => _fill('drvSurgeNearby', {'x': x, 'zone': zone});
  String get drvZone => tr('drvZone');
  String get drvInactive => tr('drvInactive');
  String drvPeakExtra(String amount) => _fill('drvPeakExtra', {'amount': amount});
  String drvPeakProgress(int done, int target) => _fill('drvPeakProgress', {'done': done, 'target': target});
  String drvStreakCount(int n) => _fill('drvStreakCount', {'n': n});
  String drvStreakRemaining(int n, String amount) => _fill('drvStreakRemaining', {'n': n, 'amount': amount});
  String drvStreakUnlocked(String amount) => _fill('drvStreakUnlocked', {'amount': amount});
  String drvPassengerNo(Object id) => _fill('drvPassengerNo', {'id': id});
  String drvSenderNo(Object id) => _fill('drvSenderNo', {'id': id});
  String drvSecondsShort(int n) => _fill('drvSecondsShort', {'n': n});
  String drvFloors(Object from, Object to) => _fill('drvFloors', {'from': from, 'to': to});
  String drvElevator(String v) => _fill('drvElevator', {'v': v});
  String drvHelpers(Object n, String type) => _fill('drvHelpers', {'n': n, 'type': type});
  String get drvHeavyCarry => tr('drvHeavyCarry');
  String get drvNormalCarry => tr('drvNormalCarry');
  String drvWithdrawConfirm(String bank) => _fill('drvWithdrawConfirm', {'bank': bank});
  String drvWithdrawSubmitted(String amount) => _fill('drvWithdrawSubmitted', {'amount': amount});
  String drvMinWithdrawal(String amount) => _fill('drvMinWithdrawal', {'amount': amount});
  String drvWithdrawTo(String amount, String bank) => _fill('drvWithdrawTo', {'amount': amount, 'bank': bank});
  String get drvTodaysTransactions => tr('drvTodaysTransactions');
  String drvTotalCount(int n) => _fill('drvTotalCount', {'n': n});
  String drvBalanceShort(String amount) => _fill('drvBalanceShort', {'amount': amount});
  String seatsLabel(int n) => n == 1 ? tr('seatsOne') : _fill('seatsCount', {'n': n});
  String get senderNameHint => tr('senderNameHint');
  String get senderPhoneHint => tr('senderPhoneHint');
  String get recipientNameHint => tr('recipientNameHint');
  String get recipientPhoneHint => tr('recipientPhoneHint');
  String get guestOtpReason => tr('guestOtpReason');
  String get confirmOtpTitle => tr('confirmOtpTitle');
  String get otpSentToYourPhone => tr('otpSentToYourPhone');
  String get didntReceiveCode => tr('didntReceiveCode');
  String get resendShort => tr('resendShort');
  String get guestPhoneStarHint => tr('guestPhoneStarHint');
  String get guestFullNameRequired => tr('guestFullNameRequired');
  String get guestPhoneInvalid => tr('guestPhoneInvalid');
  String get guestPhoneNotVerified => tr('guestPhoneNotVerified');
  String get guestOtpNote => tr('guestOtpNote');
  String get regJoinTitle => tr('regJoinTitle');
  String get regTagline => tr('regTagline');
  String get regIWantTo => tr('regIWantTo');
  String get regRideAsPassenger => tr('regRideAsPassenger');
  String get regDriveAndEarn => tr('regDriveAndEarn');
  String get regOwner => tr('regOwner');
  String get regSelectCity => tr('regSelectCity');
  String get regCityRequired => tr('regCityRequired');
  String get regNameRequired => tr('regNameRequired');
  String get regEmailRequired => tr('regEmailRequired');
  String get regEmailInvalid => tr('regEmailInvalid');
  String get regPhoneOptional => tr('regPhoneOptional');
  String get regPasswordMin => tr('regPasswordMin');
  String get regPasswordMismatch => tr('regPasswordMismatch');
  String get regReferralOptional => tr('regReferralOptional');
  String get regRegisterUpload => tr('regRegisterUpload');
  String get cityPhnomPenh => tr('cityPhnomPenh');
  String get citySiemReap => tr('citySiemReap');
  String get citySihanoukville => tr('citySihanoukville');
  String get cityBattambang => tr('cityBattambang');
  String get cityKampongCham => tr('cityKampongCham');
  String get cityKampot => tr('cityKampot');
  String get cityKep => tr('cityKep');
  String get cityPoipet => tr('cityPoipet');
  String get chatsTab => tr('chatsTab');
  String get noConversationsYet => tr('noConversationsYet');
  String get driverMessagesHint => tr('driverMessagesHint');
  String get rotehSupport => tr('rotehSupport');
  String get chatWithOurTeam => tr('chatWithOurTeam');
  String get noMessagesSayHello => tr('noMessagesSayHello');
  String get typeAMessageHint => tr('typeAMessageHint');
  String get howCanWeHelp => tr('howCanWeHelp');
  String get searchForHelp => tr('searchForHelp');
  String get quickHelp => tr('quickHelp');
  String get qhDriverLate => tr('qhDriverLate');
  String get qhOvercharged => tr('qhOvercharged');
  String get qhLostItem => tr('qhLostItem');
  String get qhSafetyIssue => tr('qhSafetyIssue');
  String get qhCancelTrip => tr('qhCancelTrip');
  String get support247 => tr('support247');
  String get openTicketReplyHere => tr('openTicketReplyHere');
  String get chatNow => tr('chatNow');
  String get supportRepliesSoon => tr('supportRepliesSoon');
  String get uploadFromGallery => tr('uploadFromGallery');
  String couldNotSendPhoto(Object error) => _fill('couldNotSendPhoto', {'error': error});
  String couldNotLoadMessages(Object error) => _fill('couldNotLoadMessages', {'error': error});
  String get missedRequestsTitle => tr('missedRequestsTitle');
  String get missedTab => tr('missedTab');
  String get declinedTab => tr('declinedTab');
  String get reasonMissed => tr('reasonMissed');
  String get reasonDeclined => tr('reasonDeclined');
  String get outcomeOpen => tr('outcomeOpen');
  String get outcomeTaken => tr('outcomeTaken');
  String get outcomeCancelled => tr('outcomeCancelled');
  String get noMissedRequests => tr('noMissedRequests');
  String get missedRequestsHint => tr('missedRequestsHint');
  String get trRemove => tr('trRemove');
  String get trSwitch => tr('trSwitch');
  String get trAccount => tr('trAccount');
  String get trBack => tr('trBack');
  String get trSave => tr('trSave');
  String get trDelete => tr('trDelete');
  String get trEdit => tr('trEdit');
  String get trApprove => tr('trApprove');
  String get trReject => tr('trReject');
  String get trApproved => tr('trApproved');
  String get trRejected => tr('trRejected');
  String get trPending => tr('trPending');
  String get trActive => tr('trActive');
  String get trInactive => tr('trInactive');
  String get trTitle => tr('trTitle');
  String get trRefresh => tr('trRefresh');
  String get trSignOut => tr('trSignOut');
  String get trUnknown => tr('trUnknown');
  String get trSearch => tr('trSearch');
  String get trMap => tr('trMap');
  String get trView => tr('trView');
  String get trNow => tr('trNow');
  String get trJustNow => tr('trJustNow');
  String trMinutesAgo(Object? n) => _fill('trMinutesAgo', {'n': n});
  String trHoursAgo(Object? n) => _fill('trHoursAgo', {'n': n});
  String trDaysAgo(Object? n) => _fill('trDaysAgo', {'n': n});
  String trMinAgoLong(Object? n) => _fill('trMinAgoLong', {'n': n});
  String trHrsAgoLong(Object? n) => _fill('trHrsAgoLong', {'n': n});
  String trDaysAgoLong(Object? n) => _fill('trDaysAgoLong', {'n': n});
  String trTodayAt(Object? time) => _fill('trTodayAt', {'time': time});
  String get trPerDay => tr('trPerDay');
  String get trTryAgain => tr('trTryAgain');
  String get trProcessing => tr('trProcessing');
  String trCustomerNo(Object? id) => _fill('trCustomerNo', {'id': id});
  String trDriverNo(Object? id) => _fill('trDriverNo', {'id': id});
  String trRideNo(Object? id) => _fill('trRideNo', {'id': id});
  String trStopN(Object? n) => _fill('trStopN', {'n': n});
  String trStopWithAddress(Object? n, Object? address) => _fill('trStopWithAddress', {'n': n, 'address': address});
  String trStopDestination(Object? n) => _fill('trStopDestination', {'n': n});
  String trStopDistance(Object? n, Object? km) => _fill('trStopDistance', {'n': n, 'km': km});
  String trDistanceKm(Object? km) => _fill('trDistanceKm', {'km': km});
  String trPromoWithCode(Object? code) => _fill('trPromoWithCode', {'code': code});
  String trYouEarned(Object? amount) => _fill('trYouEarned', {'amount': amount});
  String trEtaMin(Object? n) => _fill('trEtaMin', {'n': n});
  String trFromPlace(Object? place) => _fill('trFromPlace', {'place': place});
  String trToPlace(Object? place) => _fill('trToPlace', {'place': place});
  String trFareKhr(Object? amount) => _fill('trFareKhr', {'amount': amount});
  String get trCar => tr('trCar');
  String get trBike => tr('trBike');
  String get trTukTuk => tr('trTukTuk');
  String get trVan => tr('trVan');
  String get trHome => tr('trHome');
  String get trWork => tr('trWork');
  String get trCash => tr('trCash');
  String get trWalletTopUp => tr('trWalletTopUp');
  String get trTripEarning => tr('trTripEarning');
  String get trPlatformFee => tr('trPlatformFee');
  String get trBonusCredit => tr('trBonusCredit');
  String get trTripPayment => tr('trTripPayment');
  String get trRefund => tr('trRefund');
  String get trGoogleNotConfigured => tr('trGoogleNotConfigured');
  String get trAdminRole => tr('trAdminRole');
  String get trEnterOtp => tr('trEnterOtp');
  String get trPhoneLogin => tr('trPhoneLogin');
  String trCodeSentTo(Object? phone) => _fill('trCodeSentTo', {'phone': phone});
  String get trWeSendSmsCode => tr('trWeSendSmsCode');
  String trResendCodeIn(Object? n) => _fill('trResendCodeIn', {'n': n});
  String get trThisAccount => tr('trThisAccount');
  String get trRemoveAccount => tr('trRemoveAccount');
  String trUnlinkConfirm(Object? name) => _fill('trUnlinkConfirm', {'name': name});
  String get trSwitchAccount => tr('trSwitchAccount');
  String get trLinkAccount => tr('trLinkAccount');
  String get trNoLinkedAccounts => tr('trNoLinkedAccounts');
  String get trLinkAnotherAccount => tr('trLinkAnotherAccount');
  String get trLabelOptionalWork => tr('trLabelOptionalWork');
  String get trNewCodeSent => tr('trNewCodeSent');
  String get trVerifyPhone => tr('trVerifyPhone');
  String get trEnterVerificationCode => tr('trEnterVerificationCode');
  String get trDidntReceiveCode => tr('trDidntReceiveCode');
  String trResendInSeconds(Object? n) => _fill('trResendInSeconds', {'n': n});
  String trNoTasksNow(Object? label) => _fill('trNoTasksNow', {'label': label});
  String get trSosFailedCall => tr('trSosFailedCall');
  String get trNoDestinationMeteredFare => tr('trNoDestinationMeteredFare');
  String get trCouldntAutoCalc => tr('trCouldntAutoCalc');
  String trFromKmTravelled(Object? km) => _fill('trFromKmTravelled', {'km': km});
  String get trUser => tr('trUser');
  String trCreditName(Object? name) => _fill('trCreditName', {'name': name});
  String get trAmountKhr => tr('trAmountKhr');
  String get trNoteOptional => tr('trNoteOptional');
  String get trCredit => tr('trCredit');
  String get trCreditApplied => tr('trCreditApplied');
  String get trDeleteUser => tr('trDeleteUser');
  String trPermanentlyDelete(Object? name) => _fill('trPermanentlyDelete', {'name': name});
  String get trUsers => tr('trUsers');
  String get trSearchNameEmail => tr('trSearchNameEmail');
  String get trAllRoles => tr('trAllRoles');
  String get trNoUsersFound => tr('trNoUsersFound');
  String get trCreditWallet => tr('trCreditWallet');
  String get trNotifications => tr('trNotifications');
  String get trMarkAllRead => tr('trMarkAllRead');
  String get trNoNotificationsYet => tr('trNoNotificationsYet');
  String get trCarRental => tr('trCarRental');
  String get trMarketplaceOrder => tr('trMarketplaceOrder');
  String get trManageOnWebAdmin => tr('trManageOnWebAdmin');
  String get trTransactions => tr('trTransactions');
  String get trDebit => tr('trDebit');
  String get trTopUp => tr('trTopUp');
  String get trWithdraw => tr('trWithdraw');
  String get trNoTransactions => tr('trNoTransactions');
  String get trDriverApproved => tr('trDriverApproved');
  String get trDriverRejected => tr('trDriverRejected');
  String get trDriverApplications => tr('trDriverApplications');
  String get trNoPendingApplications => tr('trNoPendingApplications');
  String get trRejectDriver => tr('trRejectDriver');
  String get trProvideReasonOptional => tr('trProvideReasonOptional');
  String get trEgDocsUnclear => tr('trEgDocsUnclear');
  String get trReviewDocs => tr('trReviewDocs');
  String get trNationalIdPassport => tr('trNationalIdPassport');
  String get trDriverLicense => tr('trDriverLicense');
  String get trVehicleRegistration => tr('trVehicleRegistration');
  String get trSelfieWithId => tr('trSelfieWithId');
  String get trVehicleInsurance => tr('trVehicleInsurance');
  String get trOtherDocument => tr('trOtherDocument');
  String get trRejectDocument => tr('trRejectDocument');
  String get trReasonImageBlurry => tr('trReasonImageBlurry');
  String get trApproveDriver => tr('trApproveDriver');
  String get trServiceZoneOptional => tr('trServiceZoneOptional');
  String get trEgZoneA => tr('trEgZoneA');
  String get trConfirmApprove => tr('trConfirmApprove');
  String get trDriverApprovedExcl => tr('trDriverApprovedExcl');
  String get trDocuments => tr('trDocuments');
  String get trNoDocumentsYet => tr('trNoDocumentsYet');
  String trNoteWith(Object? note) => _fill('trNoteWith', {'note': note});
  String get trViewDocument => tr('trViewDocument');
  String get trPricingSaved => tr('trPricingSaved');
  String get trPricingSettings => tr('trPricingSettings');
  String get trSaveSettings => tr('trSaveSettings');
  String get trDeleteBanner => tr('trDeleteBanner');
  String get trRemoveBannerQ => tr('trRemoveBannerQ');
  String get trBanners => tr('trBanners');
  String get trNoBannersYet => tr('trNoBannersYet');
  String get trUntitled => tr('trUntitled');
  String get trNewBanner => tr('trNewBanner');
  String get trEditBanner => tr('trEditBanner');
  String get trSubtitleDescription => tr('trSubtitleDescription');
  String get trImageUrlOptional => tr('trImageUrlOptional');
  String get trSaveBanner => tr('trSaveBanner');
  String get trSupportTickets => tr('trSupportTickets');
  String get trOpen => tr('trOpen');
  String get trInProgress => tr('trInProgress');
  String get trResolved => tr('trResolved');
  String get trClosed => tr('trClosed');
  String get trNoTicketsFound => tr('trNoTicketsFound');
  String get trNoSubject => tr('trNoSubject');
  String trTicketNo(Object? id) => _fill('trTicketNo', {'id': id});
  String get trMarkOpen => tr('trMarkOpen');
  String get trMarkInProgress => tr('trMarkInProgress');
  String get trMarkResolved => tr('trMarkResolved');
  String get trMarkClosed => tr('trMarkClosed');
  String get trTypeReply => tr('trTypeReply');
  String get trTopUpApproved => tr('trTopUpApproved');
  String get trRejectTopUp => tr('trRejectTopUp');
  String get trReasonColon => tr('trReasonColon');
  String get trEnterReason => tr('trEnterReason');
  String get trRejectedDot => tr('trRejectedDot');
  String get trTopUpRequests => tr('trTopUpRequests');
  String get trNoTopUpRequests => tr('trNoTopUpRequests');
  String get trCancelRide => tr('trCancelRide');
  String get trReasonForCancellation => tr('trReasonForCancellation');
  String get trEgPolicyViolation => tr('trEgPolicyViolation');
  String get trRides => tr('trRides');
  String get trNoRidesFound => tr('trNoRidesFound');
  String get trApproveWithdrawal => tr('trApproveWithdrawal');
  String get trAddNoteOptional => tr('trAddNoteOptional');
  String get trEgTransferredAba => tr('trEgTransferredAba');
  String get trApprovedDot => tr('trApprovedDot');
  String get trRejectWithdrawal => tr('trRejectWithdrawal');
  String get trReasonRequired => tr('trReasonRequired');
  String get trEgInvalidAccount => tr('trEgInvalidAccount');
  String get trWithdrawals => tr('trWithdrawals');
  String get trNoWithdrawalsFound => tr('trNoWithdrawalsFound');
  String get trSafetyIncidents => tr('trSafetyIncidents');
  String get trCrash => tr('trCrash');
  String get trUserReport => tr('trUserReport');
  String get trNoSafetyIncidents => tr('trNoSafetyIncidents');
  String get trDeliveries => tr('trDeliveries');
  String get trNoDeliveriesFound => tr('trNoDeliveriesFound');
  String get trAdminDashboard => tr('trAdminDashboard');
  String get trRevenue7Days => tr('trRevenue7Days');
  String get trSurgePromoControl => tr('trSurgePromoControl');
  String get trSurge => tr('trSurge');
  String get trPromos => tr('trPromos');
  String get trThisZone => tr('trThisZone');
  String get trDeleteSurgeZone => tr('trDeleteSurgeZone');
  String trDeleteNamedQ(Object? name) => _fill('trDeleteNamedQ', {'name': name});
  String get trNewZone => tr('trNewZone');
  String get trNoSurgeZones => tr('trNoSurgeZones');
  String get trNewSurgeZone => tr('trNewSurgeZone');
  String get trEditSurgeZone => tr('trEditSurgeZone');
  String get trZoneName => tr('trZoneName');
  String get trEgCityCentre => tr('trEgCityCentre');
  String get trDescriptionOptional => tr('trDescriptionOptional');
  String get trEgHighDemand => tr('trEgHighDemand');
  String trMultiplierX(Object? x) => _fill('trMultiplierX', {'x': x});
  String get trCreateZone => tr('trCreateZone');
  String get trSaveChanges => tr('trSaveChanges');
  String get trDeletePromo => tr('trDeletePromo');
  String get trNewPromo => tr('trNewPromo');
  String get trNoPromoCodes => tr('trNoPromoCodes');
  String trAmountOff(Object? amount) => _fill('trAmountOff', {'amount': amount});
  String trUsesLeft(Object? n) => _fill('trUsesLeft', {'n': n});
  String trExpShort(Object? date) => _fill('trExpShort', {'date': date});
  String get trCodeDiscountRequired => tr('trCodeDiscountRequired');
  String get trEditPromoCode => tr('trEditPromoCode');
  String get trNewPromoCode => tr('trNewPromoCode');
  String get trPromoCode => tr('trPromoCode');
  String get trDiscountKhr => tr('trDiscountKhr');
  String get trMaxUsesHint => tr('trMaxUsesHint');
  String get trExpiresAtHint => tr('trExpiresAtHint');
  String get trCreatePromo => tr('trCreatePromo');
  String get trDeleteFareRule => tr('trDeleteFareRule');
  String get trThisVehicle => tr('trThisVehicle');
  String get trFareManagement => tr('trFareManagement');
  String get trAddRule => tr('trAddRule');
  String get trNoFareRules => tr('trNoFareRules');
  String get trBaseFare => tr('trBaseFare');
  String get trPerKm => tr('trPerKm');
  String get trMinimum => tr('trMinimum');
  String get trFillFareFields => tr('trFillFareFields');
  String get trEditFareRule => tr('trEditFareRule');
  String get trNewFareRule => tr('trNewFareRule');
  String get trBaseFareKhr => tr('trBaseFareKhr');
  String get trPerKmRateKhr => tr('trPerKmRateKhr');
  String get trMinimumFareKhr => tr('trMinimumFareKhr');
  String get trCreateRule => tr('trCreateRule');
  String get trDestination => tr('trDestination');
  String get trFindingDriver => tr('trFindingDriver');
  String get trDriverOnTheWay => tr('trDriverOnTheWay');
  String get trDriverEnRoutePickup => tr('trDriverEnRoutePickup');
  String get trTripInProgress => tr('trTripInProgress');
  String get trTripCompleted => tr('trTripCompleted');
  String get trTripCancelled => tr('trTripCancelled');
  String get trLiveTrip => tr('trLiveTrip');
  String get trMovingService => tr('trMovingService');
  String get trWaitingDriverGps => tr('trWaitingDriverGps');
  String get trPageAutoUpdates => tr('trPageAutoUpdates');
  String get trTripNotFound => tr('trTripNotFound');
  String get trLookingForDriver => tr('trLookingForDriver');
  String get trDriverAssigned => tr('trDriverAssigned');
  String get trDriverArrivedPickup => tr('trDriverArrivedPickup');
  String get trLoadingItems => tr('trLoadingItems');
  String get trOnWayToDestination => tr('trOnWayToDestination');
  String get trMovingCompletedExcl => tr('trMovingCompletedExcl');
  String get trProcessingDots => tr('trProcessingDots');
  String get trPackagePickedUp => tr('trPackagePickedUp');
  String get trOnWayToRecipient => tr('trOnWayToRecipient');
  String get trDeliveredExcl => tr('trDeliveredExcl');
  String get trPackageDelivery => tr('trPackageDelivery');
  String trTrackMy(Object? service) => _fill('trTrackMy', {'service': service});
  String trTrackMyLive(Object? title) => _fill('trTrackMyLive', {'title': title});
  String get trMovingCompleted => tr('trMovingCompleted');
  String get trDeliveryCompletedTitle => tr('trDeliveryCompletedTitle');
  String get trMoving => tr('trMoving');
  String trRecipientLine(Object? name) => _fill('trRecipientLine', {'name': name});
  String trDriverLine(Object? name) => _fill('trDriverLine', {'name': name});
  String get trShareMovingTracking => tr('trShareMovingTracking');
  String get trShareDeliveryTracking => tr('trShareDeliveryTracking');
  String get trPendingFirstRide => tr('trPendingFirstRide');
  String get trSedan => tr('trSedan');
  String get trUpTo4Pax => tr('trUpTo4Pax');
  String get trSuvVan => tr('trSuvVan');
  String get trUpTo6Pax => tr('trUpTo6Pax');
  String trDriverArrivingPickup(Object? name) => _fill('trDriverArrivingPickup', {'name': name});
  String trDriverWaitingAt(Object? name, Object? place) => _fill('trDriverWaitingAt', {'name': name, 'place': place});
  String trSosSentToContacts(Object? n) => _fill('trSosSentToContacts', {'n': n});
  String get trChatWithSupport => tr('trChatWithSupport');
  String get trPaidBySender => tr('trPaidBySender');
  String get trPaidByRecipient => tr('trPaidByRecipient');
  String trScheduleWithFare(Object? fare) => _fill('trScheduleWithFare', {'fare': fare});
  String trConfirmWithFare(Object? fare) => _fill('trConfirmWithFare', {'fare': fare});
  String trAddedToWallet(Object? amount) => _fill('trAddedToWallet', {'amount': amount});
  String get trRecipientPhoneNumber => tr('trRecipientPhoneNumber');
  String get trConfirmAndPay => tr('trConfirmAndPay');
  String get trNewRideRequest => tr('trNewRideRequest');
  String get trNewRequest => tr('trNewRequest');
  String get trSubscribed => tr('trSubscribed');
  String get trPlanUpgraded => tr('trPlanUpgraded');
  String get trSubscriptionCancelled => tr('trSubscriptionCancelled');
  String get trTransferred => tr('trTransferred');
  String get trSearchLocation => tr('trSearchLocation');
  String get trFindingAddress => tr('trFindingAddress');
  String get trMoveMapToSet => tr('trMoveMapToSet');
  String get trConfirmLocation => tr('trConfirmLocation');
  String get trTapOpenGoogleMaps => tr('trTapOpenGoogleMaps');
  String get trOpenInMaps => tr('trOpenInMaps');
  String get trSearchAddressHint => tr('trSearchAddressHint');
  String get trUseMyLocation => tr('trUseMyLocation');
  String get trDetectedViaGps => tr('trDetectedViaGps');
  String get trTypeToSearchPlace => tr('trTypeToSearchPlace');
  String trNoResultsFor(Object? q) => _fill('trNoResultsFor', {'q': q});
  String get trMoveTheMapToSet => tr('trMoveTheMapToSet');
  String get trUseThisLocation => tr('trUseThisLocation');
  String get trPromotions => tr('trPromotions');
  String get trSlowConnection => tr('trSlowConnection');
  String get trSwipeToRefresh => tr('trSwipeToRefresh');
  String get trPurchases => tr('trPurchases');
  String get trRentals => tr('trRentals');
  String get trPaymentsCancels => tr('trPaymentsCancels');
  String get trPerMinuteRateKhr => tr('trPerMinuteRateKhr');
  String get trCancelFeeAfterArrival => tr('trCancelFeeAfterArrival');
  String get trWaitingFreeMinutes => tr('trWaitingFreeMinutes');
  String get trWaitingFeePerMinuteKhr => tr('trWaitingFeePerMinuteKhr');
  String get trNightSurchargePct => tr('trNightSurchargePct');
  String get trPlatformCommissionPct => tr('trPlatformCommissionPct');
  String get trStepOrder => tr('trStepOrder');
  String get trStepDriverAssigned => tr('trStepDriverAssigned');
  String get trStepPickedUp => tr('trStepPickedUp');
  String get trStepOnTheWay => tr('trStepOnTheWay');
  String get trStepDelivered => tr('trStepDelivered');
  String get trStepAccepted => tr('trStepAccepted');
  String get trStepArrived => tr('trStepArrived');
  String get trStepLoading => tr('trStepLoading');
  String get trStepInTransit => tr('trStepInTransit');
  String get trStepDone => tr('trStepDone');
  String get trGoogleCancelled => tr('trGoogleCancelled');
  String get trEnterEmailPassword => tr('trEnterEmailPassword');
  String get trCannotReachServer => tr('trCannotReachServer');
  String get trEnterYourPhone => tr('trEnterYourPhone');
  String trDevModeCode(Object? code) => _fill('trDevModeCode', {'code': code});
  String trActiveCount(Object? n) => _fill('trActiveCount', {'n': n});
  String trCompletedCount(Object? n) => _fill('trCompletedCount', {'n': n});
  String get trTitleRequired => tr('trTitleRequired');
  String get trZoneNameRequired => tr('trZoneNameRequired');
  String trDeletePromoCodeQ(Object? code) => _fill('trDeletePromoCodeQ', {'code': code});
  String get trBaseFareLower => tr('trBaseFareLower');
  String trTimeMin(Object? n) => _fill('trTimeMin', {'n': n});
  String get trNoFee => tr('trNoFee');
  String get trInstant => tr('trInstant');
  String trSurgeActiveArea(Object? x) => _fill('trSurgeActiveArea', {'x': x});
  String trSurgeHighDemand(Object? x) => _fill('trSurgeHighDemand', {'x': x});
  String get trNoListingMatchesFilter => tr('trNoListingMatchesFilter');
  String get trPaymentSuccessful => tr('trPaymentSuccessful');
  String trPaidVia(Object? amount, Object? method) => _fill('trPaidVia', {'amount': amount, 'method': method});
  String get trSetLocation => tr('trSetLocation');
  String get trNetworkErrorCheck => tr('trNetworkErrorCheck');
  String get trEnableBiometric => tr('trEnableBiometric');
  String get trSignInToRoteh => tr('trSignInToRoteh');
  String get deleteAccountLabel => tr('deleteAccountLabel');
  String get deleteAccountTitle => tr('deleteAccountTitle');
  String get deleteAccountMessage => tr('deleteAccountMessage');
  String get deleteAccountConfirm => tr('deleteAccountConfirm');
  String get deleteAccountDone => tr('deleteAccountDone');
  String get trCouldNotCompleteTrip => tr('trCouldNotCompleteTrip');
  String get trSurchargesLine => tr('trSurchargesLine');
  String get trMeterSoFar => tr('trMeterSoFar');
  String get pkExportReport => tr('pkExportReport');
  String get pkExportPdf => tr('pkExportPdf');
  String get pkExportPdfSub => tr('pkExportPdfSub');
  String get pkExportExcel => tr('pkExportExcel');
  String get pkExportExcelSub => tr('pkExportExcelSub');
  String get pkStatusCompleted => tr('pkStatusCompleted');
  String get pkStatusFailed => tr('pkStatusFailed');
  String get pkStatusReturned => tr('pkStatusReturned');
  String get pkReasonCannotContact => tr('pkReasonCannotContact');
  String get pkReasonRefused => tr('pkReasonRefused');
  String get pkReasonWrongAddress => tr('pkReasonWrongAddress');
  String get pkReasonPostponed => tr('pkReasonPostponed');
  String get pkReasonOther => tr('pkReasonOther');
  String get pkReturningToShop => tr('pkReturningToShop');
  String get pkReports => tr('pkReports');
  String get pkReportsSub => tr('pkReportsSub');
  String get pkDay => tr('pkDay');
  String get pkWeek => tr('pkWeek');
  String get pkMonth => tr('pkMonth');
  String get pkTotalPackages => tr('pkTotalPackages');
  String get pkSuccessRate => tr('pkSuccessRate');
  String get pkInProgress => tr('pkInProgress');
  String get pkDeliveryFees => tr('pkDeliveryFees');
  String get pkCodCollected => tr('pkCodCollected');
  String get pkAvgTime => tr('pkAvgTime');
  String pkMinutes(int n) => _fill('pkMinutes', {'n': '$n'});
  String get pkFailureReasons => tr('pkFailureReasons');
  String get pkNoData => tr('pkNoData');
  String get pkToday => tr('pkToday');
  String get pkThisWeek => tr('pkThisWeek');
  String get pkThisMonth => tr('pkThisMonth');
  String get pkByHour => tr('pkByHour');
  String get pkByDay => tr('pkByDay');
  String pkTodaySummary(int done, int back, int open) => _fill('pkTodaySummary', {'done': '$done', 'back': '$back', 'open': '$open'});
  String get drvCantDeliver => tr('drvCantDeliver');
  String get drvCantDeliverTitle => tr('drvCantDeliverTitle');
  String get drvFailNote => tr('drvFailNote');
  String get drvReportFail => tr('drvReportFail');
  String get drvReturningTitle => tr('drvReturningTitle');
  String get drvReturnedToShop => tr('drvReturnedToShop');
  String get drvDeliveredAfterAll => tr('drvDeliveredAfterAll');
  String get drvReturnDone => tr('drvReturnDone');
  String get pkPartnerServices => tr('pkPartnerServices');
  String get pkCreatePackage => tr('pkCreatePackage');
  String get pkCreatePackageSub => tr('pkCreatePackageSub');
  String get pkMyPackages => tr('pkMyPackages');
  String get pkMyPackagesSub => tr('pkMyPackagesSub');
  String get pkTrackPackage => tr('pkTrackPackage');
  String get pkTrackPackageSub => tr('pkTrackPackageSub');
  String get pkHistory => tr('pkHistory');
  String get pkHistorySub => tr('pkHistorySub');
  String pkActiveCount(int n) => _fill('pkActiveCount', {'n': '$n'});
  String pkTodayCount(int n) => _fill('pkTodayCount', {'n': '$n'});
  String get pkCodPending => tr('pkCodPending');
  String get pkBecomePartner => tr('pkBecomePartner');
  String get pkBecomePartnerSub => tr('pkBecomePartnerSub');
  String get pkPartnerAccount => tr('pkPartnerAccount');
  String get pkPendingTitle => tr('pkPendingTitle');
  String get pkPendingBody => tr('pkPendingBody');
  String get pkRejectedTitle => tr('pkRejectedTitle');
  String get pkSuspendedTitle => tr('pkSuspendedTitle');
  String get pkSuspendedBody => tr('pkSuspendedBody');
  String get pkResubmit => tr('pkResubmit');
  String get pkRegisterTitle => tr('pkRegisterTitle');
  String get pkRegisterIntro => tr('pkRegisterIntro');
  String get pkBusinessName => tr('pkBusinessName');
  String get pkBusinessType => tr('pkBusinessType');
  String get pkContactName => tr('pkContactName');
  String get pkBusinessPhone => tr('pkBusinessPhone');
  String get pkPickupAddress => tr('pkPickupAddress');
  String get pkSubmit => tr('pkSubmit');
  String get pkRequired => tr('pkRequired');
  String get pkTypeOnlineShop => tr('pkTypeOnlineShop');
  String get pkTypeRetail => tr('pkTypeRetail');
  String get pkTypeRestaurant => tr('pkTypeRestaurant');
  String get pkTypeOther => tr('pkTypeOther');
  String get pkSender => tr('pkSender');
  String get pkReceiver => tr('pkReceiver');
  String get pkName => tr('pkName');
  String get pkPhone => tr('pkPhone');
  String get pkPickupLocation => tr('pkPickupLocation');
  String get pkDeliveryLocation => tr('pkDeliveryLocation');
  String get pkChooseOnMap => tr('pkChooseOnMap');
  String get pkPackage => tr('pkPackage');
  String get pkPackageType => tr('pkPackageType');
  String get pkDescription => tr('pkDescription');
  String get pkWeight => tr('pkWeight');
  String get pkSize => tr('pkSize');
  String get pkPhoto => tr('pkPhoto');
  String get pkAddPhoto => tr('pkAddPhoto');
  String get pkCamera => tr('pkCamera');
  String get pkGallery => tr('pkGallery');
  String get pkService => tr('pkService');
  String get pkNormal => tr('pkNormal');
  String get pkExpress => tr('pkExpress');
  String get pkPayment => tr('pkPayment');
  String get pkWhoPays => tr('pkWhoPays');
  String get pkPartnerPays => tr('pkPartnerPays');
  String get pkReceiverPays => tr('pkReceiverPays');
  String get pkCodAmount => tr('pkCodAmount');
  String get pkCodHint => tr('pkCodHint');
  String get pkReference => tr('pkReference');
  String get pkNotes => tr('pkNotes');
  String get pkDeliveryFee => tr('pkDeliveryFee');
  String get pkSubmitPackage => tr('pkSubmitPackage');
  String get pkChooseLocations => tr('pkChooseLocations');
  String get pkCreatedTitle => tr('pkCreatedTitle');
  String pkCreatedBody(String code) => _fill('pkCreatedBody', {'code': code});
  String get pkStatusPending => tr('pkStatusPending');
  String get pkStatusConfirmed => tr('pkStatusConfirmed');
  String get pkStatusDriverAssigned => tr('pkStatusDriverAssigned');
  String get pkStatusPickedUp => tr('pkStatusPickedUp');
  String get pkStatusInTransit => tr('pkStatusInTransit');
  String get pkStatusDelivered => tr('pkStatusDelivered');
  String get pkStatusCancelled => tr('pkStatusCancelled');
  String get pkTabActive => tr('pkTabActive');
  String get pkTabHistory => tr('pkTabHistory');
  String get pkTabAll => tr('pkTabAll');
  String get pkSearchHint => tr('pkSearchHint');
  String get pkEmptyActive => tr('pkEmptyActive');
  String get pkEmptyHistory => tr('pkEmptyHistory');
  String get pkEmptyAll => tr('pkEmptyAll');
  String get pkDetailTitle => tr('pkDetailTitle');
  String get pkTimeline => tr('pkTimeline');
  String get pkDriver => tr('pkDriver');
  String get pkCall => tr('pkCall');
  String get pkLiveMap => tr('pkLiveMap');
  String get pkShareLink => tr('pkShareLink');
  String pkShareText(String code, String url) => _fill('pkShareText', {'code': code, 'url': url});
  String get pkCancelPackage => tr('pkCancelPackage');
  String get pkCancelConfirm => tr('pkCancelConfirm');
  String get pkCancelReason => tr('pkCancelReason');
  String get pkKeep => tr('pkKeep');
  String get pkQrTitle => tr('pkQrTitle');
  String get pkQrHint => tr('pkQrHint');
  String get pkProofPhoto => tr('pkProofPhoto');
  String get pkWaitingConfirm => tr('pkWaitingConfirm');
  String get pkFindingDriver => tr('pkFindingDriver');
  String get pkPaymentByReceiver => tr('pkPaymentByReceiver');
  String get pkPaymentByPartner => tr('pkPaymentByPartner');
  String get pkCod => tr('pkCod');
  String get pkSizeSmall => tr('pkSizeSmall');
  String get pkSizeMedium => tr('pkSizeMedium');
  String get pkSizeLarge => tr('pkSizeLarge');
  String get pkSizeXL => tr('pkSizeXL');
  String get pkTypeDocument => tr('pkTypeDocument');
  String get pkTypeParcel => tr('pkTypeParcel');
  String get pkTypeFood => tr('pkTypeFood');
  String get pkTypeClothing => tr('pkTypeClothing');
  String get pkTypeElectronics => tr('pkTypeElectronics');
  String get pkTypeFragile => tr('pkTypeFragile');
  String get pkPayMethod => tr('pkPayMethod');
  String get pkPayCash => tr('pkPayCash');
  String get pkPayWallet => tr('pkPayWallet');
  String get pkPayAba => tr('pkPayAba');
  String get pkCreated => tr('pkCreated');
  String paywayOrderPaidBody(String amount) => _fill('paywayOrderPaidBody', {'amount': amount});
  String get paywayNotAvailable => tr('paywayNotAvailable');
  String get paywayPayNow => tr('paywayPayNow');
  String get paywayUnpaid => tr('paywayUnpaid');
  String get paywayPaidLabel => tr('paywayPaidLabel');
  String get paywayTitle => tr('paywayTitle');
  String get paywayScanHint => tr('paywayScanHint');
  String get paywayWaiting => tr('paywayWaiting');
  String get paywayExpired => tr('paywayExpired');
  String get paywayFailed => tr('paywayFailed');
  String get paywayOpenAba => tr('paywayOpenAba');
  String get paywayIPaid => tr('paywayIPaid');
  String get paywayRef => tr('paywayRef');
  String get paywayPaidTitle => tr('paywayPaidTitle');
  String paywayPaidBody(String amount) => _fill('paywayPaidBody', {'amount': amount});
  String helmetConfidence(String value) => _fill('helmetConfidence', {'value': value});
  String get helmetCheckFailed => tr('helmetCheckFailed');
  String get txStatusPending => tr('txStatusPending');
  String get txStatusProcessing => tr('txStatusProcessing');
  String get txStatusFailed => tr('txStatusFailed');
  String get txStatusRejected => tr('txStatusRejected');
  String get txFilterIncome => tr('txFilterIncome');
  String get txFilterDeductions => tr('txFilterDeductions');
  String get txNoneForFilter => tr('txNoneForFilter');
  String get txWithdrawalPending => tr('txWithdrawalPending');
  String get txWithdrawal => tr('txWithdrawal');
  String get txWithdrawalReturned => tr('txWithdrawalReturned');
  String get txTransferIn => tr('txTransferIn');
  String get txTransferOut => tr('txTransferOut');
  String get txTipIn => tr('txTipIn');
  String get txTipOut => tr('txTipOut');
  String get txSalary => tr('txSalary');
  String get txDeliveryPayment => tr('txDeliveryPayment');
  String get txCancellationFee => tr('txCancellationFee');
  String get txAdminCredit => tr('txAdminCredit');
  String get txReferralReward => tr('txReferralReward');
  String get txCompanyShare => tr('txCompanyShare');
  String get txLoyaltyRedemption => tr('txLoyaltyRedemption');
  String get topUpPendingTitle => tr('topUpPendingTitle');
  String get topUpPendingStatus => tr('topUpPendingStatus');
  String get topUpPendingBlocked => tr('topUpPendingBlocked');
  String get bankTransfer => tr('bankTransfer');
  String get drvLowBalanceOfflineTitle => tr('drvLowBalanceOfflineTitle');
  String drvLowBalanceOfflineMsg(String balance, String min) =>
      _fill('drvLowBalanceOfflineMsg', {'balance': balance, 'min': min});
  String get drvTripCancelledTitle => tr('drvTripCancelledTitle');
  String get drvRequestNoLongerAvailable => tr('drvRequestNoLongerAvailable');
  String get drvSenderCancelledDelivery => tr('drvSenderCancelledDelivery');
  String get trCancelledStatus => tr('trCancelledStatus');
  String get trDeliveryCancelledTitle => tr('trDeliveryCancelledTitle');
  String get trMovingCancelledTitle => tr('trMovingCancelledTitle');
  String get trCancelledByDriver => tr('trCancelledByDriver');
  String get trCancelledByAdmin => tr('trCancelledByAdmin');
  String get trCancelledByYou => tr('trCancelledByYou');
  String get trCancelledGeneric => tr('trCancelledGeneric');
  String trCancelReason(String reason) => _fill('trCancelReason', {'reason': reason});
  String get trGoBack => tr('trGoBack');
  String drvGreeting(String name) => _fill('drvGreeting', {'name': name});
  String get drvFindingRides => tr('drvFindingRides');
  String get drvTodayStats => tr('drvTodayStats');
  String get drvTodayEarnings => tr('drvTodayEarnings');
  String get drvWalletBalance => tr('drvWalletBalance');
  String get drvAcceptRides => tr('drvAcceptRides');
  String get drvRideSub => tr('drvRideSub');
  String get drvDeliverySub => tr('drvDeliverySub');
  String get drvRentalSub => tr('drvRentalSub');
  String get drvNoRecentTrips => tr('drvNoRecentTrips');
  String get drvHelp => tr('drvHelp');
  String trRecipientLine2(Object? name) => _fill('trRecipientLine2', {'name': name});
  String trForName(Object? name) => _fill('trForName', {'name': name});
  String get trClassicTukTuk => tr('trClassicTukTuk');
  String get trStdPremiumVan => tr('trStdPremiumVan');
  /// Display name for a city stored by its English name (register screen).
  String cityName(String english) => switch (english) {
    'Phnom Penh'    => cityPhnomPenh,
    'Siem Reap'     => citySiemReap,
    'Sihanoukville' => citySihanoukville,
    'Battambang'    => cityBattambang,
    'Kampong Cham'  => cityKampongCham,
    'Kampot'        => cityKampot,
    'Kep'           => cityKep,
    'Poipet'        => cityPoipet,
    _               => english,
  };
  String floorsPickupDropoff(Object from, Object to) =>
      _fill('floorsPickupDropoff', {'from': from, 'to': to});
  String get busy => tr('busy');
  String get full => tr('full');
  String get chooseRide => tr('chooseRide');
  String get promoCode => tr('promoCode');
  String get scheduleDelivery => tr('scheduleDelivery');
  String get packageDetails => tr('packageDetails');
  String get packageSize => tr('packageSize');
  String get packageAmount => tr('packageAmount');
  String get packageAmountHint => tr('packageAmountHint');
  String get deliveryFee => tr('deliveryFee');
  String get deliveryCompleted => tr('deliveryCompleted');
  String get completedAt => tr('completedAt');
  String get completionTime => tr('completionTime');
  String get deliverySummary => tr('deliverySummary');
  String get viewDeliverySummary => tr('viewDeliverySummary');
  String get feePaidBy => tr('feePaidBy');
  String get paidBySender => tr('paidBySender');
  String get paidByRecipient => tr('paidByRecipient');
  String get serviceFee => tr('serviceFee');
  String get deliveryReceipt => tr('deliveryReceipt');
  String get sendAnything => tr('sendAnything');
  String get avgDelivery => tr('avgDelivery');
  String get incomingRequest => tr('incomingRequest');
  String get acceptRide => tr('acceptRide');
  String get decline => tr('decline');
  String get todayPerformance => tr('todayPerformance');
  String get recentTripsDriver => tr('recentTripsDriver');
  String get dailyBreakdown => tr('dailyBreakdown');
  String get withdrawEarnings => tr('withdrawEarnings');
  String get evCarsAvailable => tr('evCarsAvailable');
  String get evCarsSubtitle => tr('evCarsSubtitle');
  String get explore => tr('explore');
  String get completed => tr('completed');
  String get eta => tr('eta');
  String get min => tr('min');
  String get km => tr('km');
  String get activeRideInProgress => tr('activeRideInProgress');
  String get noRecentTrips => tr('noRecentTrips');
  String get searchProductsHint => tr('searchProductsHint');
  String get filter => tr('filter');
  String get listingsAvailable => tr('listingsAvailable');
  String get findBestDeal => tr('findBestDeal');
  String get browseAll => tr('browseAll');
  String get rentalVehicle => tr('rentalVehicle');
  String get tryAgain => tr('tryAgain');
  String get results => tr('results');
  String get noListingsFound => tr('noListingsFound');
  String get tryDifferentFilters => tr('tryDifferentFilters');
  String get salePrice => tr('salePrice');
  String get rentPerDay => tr('rentPerDay');
  String get qty => tr('qty');
  String get verifiedSeller => tr('verifiedSeller');
  String get editListing => tr('editListing');
  String get fillRequiredFields => tr('fillRequiredFields');
  String get shopAsGuest => tr('shopAsGuest');
  String get continueAsGuest => tr('continueAsGuest');
  String get welcomeBack => tr('welcomeBack');
  String get signInSubtitle => tr('signInSubtitle');
  String get noAccountYet => tr('noAccountYet');
  String get signInWithBiometrics => tr('signInWithBiometrics');
  String get signInAs => tr('signInAs');
  String get secureSignInNote => tr('secureSignInNote');
  String get welcomeTagline => tr('welcomeTagline');
  String get welcomeTitle => tr('welcomeTitle');
  String get welcomeSubtitle => tr('welcomeSubtitle');
  String get orContinueWith => tr('orContinueWith');
  String get continueWithPhone => tr('continueWithPhone');
  String get continueWithGoogle => tr('continueWithGoogle');
  String get secureCheckoutNote => tr('secureCheckoutNote');
  String get continueAsGuestSub => tr('continueAsGuestSub');
  String get guestShoppingNotice => tr('guestShoppingNotice');
  String get orderPlaced => tr('orderPlaced');
  String get purchaseRequestSent => tr('purchaseRequestSent');
  String get done => tr('done');
  String get purchaseProduct => tr('purchaseProduct');
  String get couponCode => tr('couponCode');
  String get phoneNumber => tr('phoneNumber');
  String get confirmInformation => tr('confirmInformation');
  String get verifyAddressesNote => tr('verifyAddressesNote');
  String get purchaseNow => tr('purchaseNow');
  String get findingAddress => tr('findingAddress');
  String get locationType => tr('locationType');
  String get rentalDuration => tr('rentalDuration');
  String get orderPlacedSuccess => tr('orderPlacedSuccess');
  String get paymentMethod => tr('paymentMethod');
  String get startDate => tr('startDate');
  String get endDateAuto => tr('endDateAuto');
  String get selectStartDate => tr('selectStartDate');
  String get discountApplied => tr('discountApplied');
  String get apply => tr('apply');
  String get total => tr('total');
  String get deleteListing => tr('deleteListing');
  String get willBePermanentlyRemoved => tr('willBePermanentlyRemoved');
  String get cancel => tr('cancel');
  String get delete => tr('delete');
  String get postAListing => tr('postAListing');
  String get noOrdersYet => tr('noOrdersYet');
  String get order => tr('order');
  String get left => tr('left');
  String get savedPlaces => tr('savedPlaces');
  String get noSavedPlacesYet => tr('noSavedPlacesYet');
  String get promoCodeTitle => tr('promoCodeTitle');
  String get browseVouchers => tr('browseVouchers');
  String get cambodia => tr('cambodia');
  String get mapLabel => tr('mapLabel');
  String get noResultsFound => tr('noResultsFound');
  String get addAStop => tr('addAStop');
  String get whereTo => tr('whereTo');
  String get now => tr('now');
  String get confirmBooking => tr('confirmBooking');
  String get noDestinationNeeded => tr('noDestinationNeeded');
  String get whereToTitle => tr('whereToTitle');
  String get noSavedPlaces => tr('noSavedPlaces');
  String get confirmDestination => tr('confirmDestination');
  String get whereToOptional => tr('whereToOptional');
  String get chooseRideTitle => tr('chooseRideTitle');
  String get scrollUpForMore => tr('scrollUpForMore');
  String get discountSuffix => tr('discountSuffix');
  String get noDestinationSelected => tr('noDestinationSelected');
  String get selectDestination => tr('selectDestination');
  String get deliveryAndMoving => tr('deliveryAndMoving');
  String get moveWithEase => tr('moveWithEase');
  String get professionalMovingService => tr('professionalMovingService');
  String get scheduleMovingDate => tr('scheduleMovingDate');
  String get selectLocationsForFare => tr('selectLocationsForFare');
  String get calculatingFare => tr('calculatingFare');
  String get yes => tr('yes');
  String get no => tr('no');
  String get helpersNeeded => tr('helpersNeeded');
  String get personsForCarrying => tr('personsForCarrying');
  String get fareEstimate => tr('fareEstimate');
  String get totalEstimate => tr('totalEstimate');
  String get finalPriceConfirmed => tr('finalPriceConfirmed');
  String get change => tr('change');
  String get confirmLocation => tr('confirmLocation');
  String get confirmDeliveryBooking => tr('confirmDeliveryBooking');
  String get noCancel => tr('noCancel');
  String get yesSendNow => tr('yesSendNow');
  String get confirmMovingBooking => tr('confirmMovingBooking');
  String get estimatedFare => tr('estimatedFare');
  String get yesBookNow => tr('yesBookNow');
  String get couldNotFetchEstimate => tr('couldNotFetchEstimate');
  String get rideCancelled => tr('rideCancelled');
  String get ok => tr('ok');
  String get stop => tr('stop');
  String get dropoff => tr('dropoff');
  String get safetyCentre => tr('safetyCentre');
  String get fare => tr('fare');
  String get sendSOSQuestion => tr('sendSOSQuestion');
  String get sendSOS => tr('sendSOS');
  String get sosFailed => tr('sosFailed');
  String get driverPhoneNotAvailable => tr('driverPhoneNotAvailable');
  String get cannotDialPrefix => tr('cannotDialPrefix');
  String get onThisDevice => tr('onThisDevice');
  String get couldNotGenerateShareLink => tr('couldNotGenerateShareLink');
  String get linkCopied => tr('linkCopied');
  String get shareTrip => tr('shareTrip');
  String get friendsCanTrack => tr('friendsCanTrack');
  String get driverLabel => tr('driverLabel');
  String get copyLink => tr('copyLink');
  String get shareVia => tr('shareVia');
  String get stopSharingLocation => tr('stopSharingLocation');
  String get cancelRide => tr('cancelRide');
  String get keepRide => tr('keepRide');
  String get businessAccount => tr('businessAccount');
  String get noBusinessAccount => tr('noBusinessAccount');
  String get registerOrJoinBusiness => tr('registerOrJoinBusiness');
  String get enterInviteCode => tr('enterInviteCode');
  String get fillSampleData => tr('fillSampleData');
  String get leaveBusinessQuestion => tr('leaveBusinessQuestion');
  String get loseBusinessAccess => tr('loseBusinessAccess');
  String get leave => tr('leave');
  String get edit => tr('edit');
  String get active => tr('active');
  String get removeMemberQuestion => tr('removeMemberQuestion');
  String get remove => tr('remove');
  String get noMembersYet => tr('noMembersYet');
  String get noBusinessTripsYet => tr('noBusinessTripsYet');
  String get refresh => tr('refresh');
  String get retry => tr('retry');
  String get businessRegistered => tr('businessRegistered');
  String get shareInviteCodeNote => tr('shareInviteCodeNote');
  String get inviteCodeCopied => tr('inviteCodeCopied');
  String get copyCode => tr('copyCode');
  String get member => tr('member');
  String get removeMemberPrefix => tr('removeMemberPrefix');
  String get thisMember => tr('thisMember');
  String get fromBusinessAccountSuffix => tr('fromBusinessAccountSuffix');
  String get refLabel => tr('refLabel');
  String get promotions => tr('promotions');
  String get editProfile => tr('editProfile');
  String get rotehPay => tr('rotehPay');
  String get qrPayment => tr('qrPayment');
  String get promosVouchers => tr('promosVouchers');
  String get scheduledRides => tr('scheduledRides');
  String get subscriptionPlans => tr('subscriptionPlans');
  String get rotehRewards => tr('rotehRewards');
  String get referEarn => tr('referEarn');
  String get myRentals => tr('myRentals');
  String get switchToDriverMode => tr('switchToDriverMode');
  String get settings => tr('settings');
  String get missions => tr('missions');
  String get myEarnings => tr('myEarnings');
  String get topUpWallet => tr('topUpWallet');
  String get helmetCheck => tr('helmetCheck');
  String get switchToPassengerMode => tr('switchToPassengerMode');
  String get darkMode => tr('darkMode');
  String get rideLabel => tr('rideLabel');
  String get rental => tr('rental');
  String get accepted => tr('accepted');
  String get hoursOnline => tr('hoursOnline');
  String get acceptanceRate => tr('acceptanceRate');
  String get verified => tr('verified');
  String get trips => tr('trips');
  String get bonuses => tr('bonuses');
  String get fees => tr('fees');
  String get topUps => tr('topUps');
  String get heavyItems => tr('heavyItems');
  String get packing => tr('packing');
  String get management => tr('management');
  String get users => tr('users');
  String get drivers => tr('drivers');
  String get ridesAdmin => tr('ridesAdmin');
  String get deliveriesAdmin => tr('deliveriesAdmin');
  String get withdrawalsAdmin => tr('withdrawalsAdmin');
  String get supportAdmin => tr('supportAdmin');
  String get transactionsAdmin => tr('transactionsAdmin');
  String get fareRules => tr('fareRules');
  String get surgeZones => tr('surgeZones');
  String get pricingAdmin => tr('pricingAdmin');
  String get bannersAdmin => tr('bannersAdmin');
  String get safetyAdmin => tr('safetyAdmin');
  String get passengersStat => tr('passengersStat');
  String get driversTotal => tr('driversTotal');
  String get onlineDrivers => tr('onlineDrivers');
  String get pendingDrivers => tr('pendingDrivers');
  String get ridesToday => tr('ridesToday');
  String get activeRides => tr('activeRides');
  String get deliveriesToday => tr('deliveriesToday');
  String get revenueToday => tr('revenueToday');
  String get revenueWeek => tr('revenueWeek');
  String get growth => tr('growth');
  String get openTickets => tr('openTickets');
  String get safetyIncidents => tr('safetyIncidents');
  String get driverApprovalsSuffix => tr('driverApprovalsSuffix');
  String get ticketsSuffix => tr('ticketsSuffix');
  String get serviceModes => tr('serviceModes');
  String get overview => tr('overview');
  String get pendingActionsSuffix => tr('pendingActionsSuffix');
  String get clearAll => tr('clearAll');
  String get size => tr('size');
  String get vehicleType => tr('vehicleType');
  String get color => tr('color');
  String get options => tr('options');
  String get accessories => tr('accessories');
  String get addAccessory => tr('addAccessory');
  String get optional => tr('optional');
  String get optionalAddOns => tr('optionalAddOns');
  String get nameEn => tr('nameEn');
  String get nameKm => tr('nameKm');
  String get priceUsd => tr('priceUsd');
  String get rentPerDayUsd => tr('rentPerDayUsd');
  String get whatAreYouListing => tr('whatAreYouListing');
  String get vehicleOption => tr('vehicleOption');
  String get accessoryOther => tr('accessoryOther');
  String get photos => tr('photos');
  String get upTo5 => tr('upTo5');
  String get productInfo => tr('productInfo');
  String get productTitle => tr('productTitle');
  String get describeProduct => tr('describeProduct');
  String get type => tr('type');
  String get condition => tr('condition');
  String get pricing => tr('pricing');
  String get quantity => tr('quantity');
  String get areaDistrictOptional => tr('areaDistrictOptional');
  String get status => tr('status');
  String get findingMatch => tr('findingMatch');
  String get totalSummary => tr('totalSummary');
  String get addAnotherItem => tr('addAnotherItem');
  String get addItem => tr('addItem');
  String get searchListings => tr('searchListings');
  String get noOtherListingsFound => tr('noOtherListingsFound');
  String get pickUp => tr('pickUp');
  String get collectMyself => tr('collectMyself');
  String get deliverToAddress => tr('deliverToAddress');
  String get tapToSetDelivery => tr('tapToSetDelivery');
  String get paidFull => tr('paidFull');
  String get payFullAmountNow => tr('payFullAmountNow');
  String get book30 => tr('book30');
  String get pay30Deposit => tr('pay30Deposit');
  String get cod => tr('cod');
  String get cashOnDelivery => tr('cashOnDelivery');
  String get payWithCash => tr('payWithCash');
  String get inAppWalletBalance => tr('inAppWalletBalance');
  String get abaMobileBanking => tr('abaMobileBanking');
  String get wingMobileWallet => tr('wingMobileWallet');
  String get otherOnline => tr('otherOnline');
  String get otherOnlinePayment => tr('otherOnlinePayment');
  String get enterCouponCodeOptional => tr('enterCouponCodeOptional');
  String get enterCouponCode => tr('enterCouponCode');
  String get noListingsYet => tr('noListingsYet');
  String get postSomethingToSell => tr('postSomethingToSell');
  String get duration => tr('duration');
  String get specialInstructions => tr('specialInstructions');
  String get seller => tr('seller');
  String get specifications => tr('specifications');
  String get pickupLocation => tr('pickupLocation');
  String get all => tr('all');
  String get category => tr('category');
  String get location => tr('location');
  String get description => tr('description');
  String get paymentType => tr('paymentType');
  String get cash => tr('cash');
  String get sender => tr('sender');
  String get recipient => tr('recipient');
  String get moving => tr('moving');
  String get topUpRequired => tr('topUpRequired');
  String get topUpNow => tr('topUpNow');
  String get lookingForRideRequests => tr('lookingForRideRequests');
  String get deliveryModeActive => tr('deliveryModeActive');
  String get incomingRideRequest => tr('incomingRideRequest');
  String get incomingDeliveryRequest => tr('incomingDeliveryRequest');
  String get incomingRentalRequest => tr('incomingRentalRequest');
  String get acceptDelivery => tr('acceptDelivery');
  String get acceptRental => tr('acceptRental');
  String get searchChargingStation => tr('searchChargingStation');
  String get nearbyChargingStations => tr('nearbyChargingStations');
  String get noChargingStationsFound => tr('noChargingStationsFound');
  String get createAccount => tr('createAccount');
  String get joinRoteh => tr('joinRoteh');
  String get fastSafeRides => tr('fastSafeRides');
  String get iWantTo => tr('iWantTo');
  String get rideAsPassenger => tr('rideAsPassenger');
  String get driveAndEarn => tr('driveAndEarn');
  String get driverType => tr('driverType');
  String get fullName => tr('fullName');
  String get email => tr('email');
  String get enterEmail => tr('enterEmail');
  String get password => tr('password');
  String get enterPassword => tr('enterPassword');
  String get confirmPassword => tr('confirmPassword');
  String get phoneOptional => tr('phoneOptional');
  String get referralCodeOptional => tr('referralCodeOptional');
  String get alreadyHaveAccount => tr('alreadyHaveAccount');
  String get signIn => tr('signIn');
  String get demoAccounts => tr('demoAccounts');
  String get sendOtp => tr('sendOtp');
  String get verifyAndSignIn => tr('verifyAndSignIn');
  String get resendOtp => tr('resendOtp');
  String get family => tr('family');
  String get wallet => tr('wallet');
  String get rewards => tr('rewards');
  String get refer => tr('refer');

  // ── Delivery / moving summary screens ──
  String get pickup => tr('pickup');
  String get phone => tr('phone');
  String get package => tr('package');
  String get movingCompleted => tr('movingCompleted');
  String get deliveryDetails => tr('deliveryDetails');
  String get movingDetails => tr('movingDetails');
  String get orderInfo => tr('orderInfo');
  String get jobInfo => tr('jobInfo');
  String get paymentSummary => tr('paymentSummary');
  String get movingFee => tr('movingFee');
  String get paidBy => tr('paidBy');
  String get youRated => tr('youRated');
  String get backToHome => tr('backToHome');
  String get backToDashboard => tr('backToDashboard');
  String get updatingReceipt => tr('updatingReceipt');
  String get updatingSummary => tr('updatingSummary');
  String get couldNotRefresh => tr('couldNotRefresh');
  String get platformFee => tr('platformFee');
  String get netDriverFee => tr('netDriverFee');
  String get driverFee => tr('driverFee');
  String get beforePlatformFee => tr('beforePlatformFee');
  String get collectFromRecipient => tr('collectFromRecipient');
  String get collectPackageAmount => tr('collectPackageAmount');
  String get packageDeliveredSuccessfully => tr('packageDeliveredSuccessfully');
  String get movingJobDone => tr('movingJobDone');
  String get onlinePay => tr('onlinePay');
  // ── Trip receipt ──
  String get tripComplete => tr('tripComplete');
  String get ride => tr('ride');
  String get fareBreakdown => tr('fareBreakdown');
  String get baseFare => tr('baseFare');
  String get distanceFee => tr('distanceFee');
  String get surgeFee => tr('surgeFee');
  String get promoDiscount => tr('promoDiscount');
  String get tripDetails => tr('tripDetails');
  String get dateAndTime => tr('dateAndTime');
  String get distance => tr('distance');
  String get yourDriver => tr('yourDriver');
  String get yourRating => tr('yourRating');
  String get shareReceipt => tr('shareReceipt');
  String get tripReceipt => tr('tripReceipt');
  String get minShort => tr('minShort');
  String get from => tr('from');
  String get to => tr('to');
  String get date => tr('date');
  String get surge => tr('surge');
  String get promo => tr('promo');
  String get rotehWallet => tr('rotehWallet');
  // ── Payment screen ──
  String get chooseHowYouWantTo => tr('chooseHowYouWantTo');
  String get confirmAndPay => tr('confirmAndPay');
  String get haveAPromoCode => tr('haveAPromoCode');
  String get payDriverDirectly => tr('payDriverDirectly');
  String get serviceFee2 => tr('serviceFee2');
  String get totalToPay => tr('totalToPay');
  String get tripSummary => tr('tripSummary');
  String get wingMobileWallet2 => tr('wingMobileWallet2');
  String get wingMoney => tr('wingMoney');
  String get yourWalletBalance => tr('yourWalletBalance');
  // ── Payment screen ──
  String get payingWith => tr('payingWith');
  // ── Wallet screen ──
  String get amountKhrMin1000 => tr('amountKhrMin1000');
  String get balanceUpdated => tr('balanceUpdated');
  String get checkLater => tr('checkLater');
  String get close => tr('close');
  String get confirmTopUp => tr('confirmTopUp');
  String get customAmountKhr => tr('customAmountKhr');
  String get enterRecipientPhoneNumber => tr('enterRecipientPhoneNumber');
  String get history => tr('history');
  String get loading => tr('loading');
  String get minimumTopUpAmountIs => tr('minimumTopUpAmountIs');
  String get minimumTransferAmountIs1 => tr('minimumTransferAmountIs1');
  String get noTransactionsYet => tr('noTransactionsYet');
  String get recentTransactions => tr('recentTransactions');
  String get reload => tr('reload');
  String get send => tr('send');
  String get sendMoney => tr('sendMoney');
  String get sentSuccessfully => tr('sentSuccessfully');
  String get tapToRetry => tr('tapToRetry');
  String get topUp => tr('topUp');
  String get topUpRotehPay => tr('topUpRotehPay');
  String get topUpStatus => tr('topUpStatus');
  String get topUpApproved => tr('topUpApproved');
  String get topUpRejected => tr('topUpRejected');
  String get viewAll => tr('viewAll');
  String get waitingForAdminApproval => tr('waitingForAdminApproval');
  // ── passenger_home screen ──
  String get n128Trips => tr('n128Trips');
  // ── delivery_tracking_screen screen ──
  String get areYouSureYouWant => tr('areYouSureYouWant');
  String get cancelOrder => tr('cancelOrder');
  String get cancelOrder2 => tr('cancelOrder2');
  String get chatDriver => tr('chatDriver');
  String get completedAt2 => tr('completedAt2');
  String get copy => tr('copy');
  String get couldNotLoadDelivery => tr('couldNotLoadDelivery');
  String get deliveryFee2 => tr('deliveryFee2');
  String get howWasYourDeliveryExperience => tr('howWasYourDeliveryExperience');
  String get keepOrder => tr('keepOrder');
  String get leaveACommentOptional => tr('leaveACommentOptional');
  String get packageAmount2 => tr('packageAmount2');
  String get rateDelivery => tr('rateDelivery');
  String get recipientsAndFriendsCanTrack => tr('recipientsAndFriendsCanTrack');
  String get service => tr('service');
  String get shareLink => tr('shareLink');
  String get skip => tr('skip');
  String get stopSharingTracking => tr('stopSharingTracking');
  String get submit => tr('submit');
  String get summary => tr('summary');
  String get trackingLinkCopiedToClipboard => tr('trackingLinkCopiedToClipboard');
  String get trackingLinkDeactivated => tr('trackingLinkDeactivated');
  String get viewSummary => tr('viewSummary');
  // ── trip_tracking_screen screen ──
  String get anSosAlertWillBe => tr('anSosAlertWillBe');
  String get call => tr('call');
  String get destination => tr('destination');
  String get locatingYourDriver => tr('locatingYourDriver');
  String get driverArrived => tr('driverArrived');
  String get driverFound => tr('driverFound');
  String get yourDriverIsAlmostHere => tr('yourDriverIsAlmostHere');
  // ── ride_booking screen ──
  String get airport => tr('airport');
  String get chooseOnMap => tr('chooseOnMap');
  String get home2 => tr('home2');
  String get office => tr('office');
  String get pickupLocation2 => tr('pickupLocation2');
  String get recent => tr('recent');
  String get rideRequested => tr('rideRequested');
  String get saved => tr('saved');
  String get searchPickupLocation => tr('searchPickupLocation');
  String get setLocationLater => tr('setLocationLater');
  String get suggestions => tr('suggestions');
  String get eGSave10 => tr('eGSave10');
  String get pickup2 => tr('pickup2');
  // ── delivery_screen screen ──
  String get n1Bedroom => tr('n1Bedroom');
  String get n10KgAndAbove => tr('n10KgAndAbove');
  String get n2Bedrooms => tr('n2Bedrooms');
  String get n210Kg => tr('n210Kg');
  String get n3Bedrooms => tr('n3Bedrooms');
  String get baseFee => tr('baseFee');
  String get bike => tr('bike');
  String get buildingHasAWorkingElevator => tr('buildingHasAWorkingElevator');
  String get car => tr('car');
  String get cashOnDeliveryCod => tr('cashOnDeliveryCod');
  String get commercialOfficeMoving => tr('commercialOfficeMoving');
  String get deliveryVehicle => tr('deliveryVehicle');
  String get dropoffFloor => tr('dropoffFloor');
  String get elevator => tr('elevator');
  String get express => tr('express');
  String get fasterDeliveryAtHigherFee => tr('fasterDeliveryAtHigherFee');
  String get floorFee => tr('floorFee');
  String get floors => tr('floors');
  String get fridgeSofaBedWardrobe => tr('fridgeSofaBedWardrobe');
  String get hasElevator => tr('hasElevator');
  String get hasHeavyItems => tr('hasHeavyItems');
  String get helperFee => tr('helperFee');
  String get helpers => tr('helpers');
  String get home3 => tr('home3');
  String get homeMove => tr('homeMove');
  String get informationOfMover => tr('informationOfMover');
  String get large => tr('large');
  String get largeHomeOrVilla => tr('largeHomeOrVilla');
  String get largerApartment => tr('largerApartment');
  String get manualCarryUpDownStairs => tr('manualCarryUpDownStairs');
  String get medium => tr('medium');
  String get mediumApartment => tr('mediumApartment');
  String get moveType => tr('moveType');
  String get needsStairsCarry => tr('needsStairsCarry');
  String get normal => tr('normal');
  String get notes => tr('notes');
  String get officeMove => tr('officeMove');
  String get packingService => tr('packingService');
  String get payFromWalletBalance => tr('payFromWalletBalance');
  String get paymentBy => tr('paymentBy');
  String get paysUpfront => tr('paysUpfront');
  String get pickupFloor => tr('pickupFloor');
  String get priorityMovingService => tr('priorityMovingService');
  String get privateHome => tr('privateHome');
  String get propertySize => tr('propertySize');
  String get recipPh => tr('recipPh');
  String get relocateHomeOffice => tr('relocateHomeOffice');
  String get residentialMoving => tr('residentialMoving');
  String get scheduled => tr('scheduled');
  String get searchLocation => tr('searchLocation');
  String get sendPackages => tr('sendPackages');
  String get senderPh => tr('senderPh');
  String get serviceOption => tr('serviceOption');
  String get small => tr('small');
  String get smallSpace => tr('smallSpace');
  String get standardDeliverySpeed => tr('standardDeliverySpeed');
  String get standardMovingService => tr('standardMovingService');
  String get studio1Room => tr('studio1Room');
  String get tukTuk => tr('tukTuk');
  String get upTo100KgAffordable => tr('upTo100KgAffordable');
  String get upTo2Kg => tr('upTo2Kg');
  String get upTo20KgFastest => tr('upTo20KgFastest');
  String get upTo200KgComfortable => tr('upTo200KgComfortable');
  String get weBoxAndWrapYour => tr('weBoxAndWrapYour');
  String get wingMobilePayment => tr('wingMobilePayment');
  String get buildingInfo => tr('buildingInfo');
  String get serviceOptions => tr('serviceOptions');
  // ── Trip tracking messages ──
  String get arrivingNow => tr('arrivingNow');
  String get cancel2000Fee => tr('cancel2000Fee');
  String get cannotCancelARideIn => tr('cannotCancelARideIn');
  String get changedMyMind => tr('changedMyMind');
  String get driverAssignedConnecting => tr('driverAssignedConnecting');
  String get driverHasArrivedA2 => tr('driverHasArrivedA2');
  String get driverHasArrived => tr('driverHasArrived');
  String get driverIsTakingTooLong => tr('driverIsTakingTooLong');
  String get emergencyCameUp => tr('emergencyCameUp');
  String get findingDriver => tr('findingDriver');
  String get findingYourDriver => tr('findingYourDriver');
  String get foundAnotherRide => tr('foundAnotherRide');
  String get iMOnMyWay => tr('iMOnMyWay');
  String get lookingForANearbyDriver => tr('lookingForANearbyDriver');
  String get myRotehTrip => tr('myRotehTrip');
  String get noDriverWasAvailableFor => tr('noDriverWasAvailableFor');
  String get other => tr('other');
  String get pleaseCheckYourBelongingsBefore => tr('pleaseCheckYourBelongingsBefore');
  String get pleaseTellUsWhyYou => tr('pleaseTellUsWhyYou');
  String get share => tr('share');
  String get sharing => tr('sharing');
  String get thisRideCannotBeCancelled => tr('thisRideCannotBeCancelled');
  String get thisRideWasCancelled => tr('thisRideWasCancelled');
  String get trackMyRotehTripLive => tr('trackMyRotehTripLive');
  String get trackMyRideLive => tr('trackMyRideLive');
  String get tripInProgress2 => tr('tripInProgress2');
  String get wrongPickupLocation => tr('wrongPickupLocation');
  String get yourDriverIsOnThe => tr('yourDriverIsOnThe');
  String get yourDriverIsOnThe2 => tr('yourDriverIsOnThe2');
  String get sosAlertSent => tr('sosAlertSent');
  String get youReAlmostAtYour => tr('youReAlmostAtYour');
  // ── ride_booking messages ──
  String get abaPay => tr('abaPay');
  String get acleda => tr('acleda');
  String get aeonMallSenSok => tr('aeonMallSenSok');
  String get bike2 => tr('bike2');
  String get carPremium => tr('carPremium');
  String get carStandard => tr('carStandard');
  String get confirmDestination2 => tr('confirmDestination2');
  String get confirmDestinations => tr('confirmDestinations');
  String get detectingLocation => tr('detectingLocation');
  String get dragMapToSetDestination => tr('dragMapToSetDestination');
  String get invalidOrExpiredCode => tr('invalidOrExpiredCode');
  String get locationPermissionDenied => tr('locationPermissionDenied');
  String get lookingForADriver => tr('lookingForADriver');
  String get meteredFare => tr('meteredFare');
  String get motorcycle => tr('motorcycle');
  String get nightMarketRiverside => tr('nightMarketRiverside');
  String get phnomPenhInternationalAirport => tr('phnomPenhInternationalAirport');
  String get pickupLocation3 => tr('pickupLocation3');
  String get royalPalace => tr('royalPalace');
  String get sharedRide => tr('sharedRide');
  String get tapMapToSetPickup => tr('tapMapToSetPickup');
  String get tellDriverOnArrival => tr('tellDriverOnArrival');
  String get toulTomPongMarket => tr('toulTomPongMarket');
  String get tukTuk2 => tr('tukTuk2');
  String get tukTuk3 => tr('tukTuk3');
  String get vanXl => tr('vanXl');
  // ── delivery_screen messages ──
  String get bookMoving => tr('bookMoving');
  String get deliveryAddress => tr('deliveryAddress');
  String get dragMapToSelectLocation => tr('dragMapToSelectLocation');
  String get fromAndToAddressesAre => tr('fromAndToAddressesAre');
  String get movingCrew => tr('movingCrew');
  String get movingFromFullAddress => tr('movingFromFullAddress');
  String get movingToFullAddress => tr('movingToFullAddress');
  String get noStairsCarry => tr('noStairsCarry');
  String get noDescription => tr('noDescription');
  String get notesOptional => tr('notesOptional');
  String get packageDescriptionOptional => tr('packageDescriptionOptional');
  String get pickupAddress => tr('pickupAddress');
  String get pickupAndDeliveryAddressAre => tr('pickupAndDeliveryAddressAre');
  String get scheduleDelivery2 => tr('scheduleDelivery2');
  String get scheduleMoving => tr('scheduleMoving');
  // ── Ride booking categories ──
  String get carShort => tr('carShort');
  // ── Driver earnings screen ──
  String get avgTrip => tr('avgTrip');
  String get breakdown => tr('breakdown');
  String get deliveries => tr('deliveries');
  String get last30Days => tr('last30Days');
  String get noEarningsHistoryYet => tr('noEarningsHistoryYet');
  String get rides => tr('rides');
  String get totalEarnings => tr('totalEarnings');
  // ── Driver earnings messages ──
  String get breakdownIsOnlyAvailableFor => tr('breakdownIsOnlyAvailableFor');
  String get noEarningsInThisPeriod => tr('noEarningsInThisPeriod');
  String get thisMonth => tr('thisMonth');
  String get thisWeek => tr('thisWeek');
  String get today => tr('today');
  // ── Weekday abbreviations ──
  String get mon => tr('mon');
  String get tue => tr('tue');
  String get wed => tr('wed');
  String get thu => tr('thu');
  String get fri => tr('fri');
  String get sat => tr('sat');
  String get sun => tr('sun');
  // ── Driver home screen ──
  String get stairsCarry => tr('stairsCarry');
  String get n1204Trips => tr('n1204Trips');
  String get n1204Trips2 => tr('n1204Trips2');
  String get n3Of5PeakHour => tr('n3Of5PeakHour');
  String get n4Consecutive5StarRatings => tr('n4Consecutive5StarRatings');
  String get n5StarStreak => tr('n5StarStreak');
  String get accountHolderName => tr('accountHolderName');
  String get accountNumber => tr('accountNumber');
  String get active69Pm => tr('active69Pm');
  String get availableBalance => tr('availableBalance');
  String get bank => tr('bank');
  String get confirmWithdrawal => tr('confirmWithdrawal');
  String get instantWithdrawal => tr('instantWithdrawal');
  String get loadMore => tr('loadMore');
  String get peakHourBonus => tr('peakHourBonus');
  String get rentalModeActive => tr('rentalModeActive');
  String get rentalRequestAccepted => tr('rentalRequestAccepted');
  String get requestCancelled => tr('requestCancelled');
  String get resume => tr('resume');
  String get reviewedByAdminBeforeFunds => tr('reviewedByAdminBeforeFunds');
  String get selectBank => tr('selectBank');
  String get showAll => tr('showAll');
  String get tapToOpenTheMap => tr('tapToOpenTheMap');
  String get waitingForDeliveryOrdersIn => tr('waitingForDeliveryOrdersIn');
  String get waiting => tr('waiting');
  String get yesWithdraw => tr('yesWithdraw');
  String get youHaveAWithdrawalRequest => tr('youHaveAWithdrawalRequest');
  String get youLlBeNotifiedWhen => tr('youLlBeNotifiedWhen');
  String get yourVehicleIsListedFor => tr('yourVehicleIsListedFor');
  String get earnedToday => tr('earnedToday');
  // ── Driver home messages ──
  String get abaBank => tr('abaBank');
  String get acledaBank => tr('acledaBank');
  String get canadiaBank => tr('canadiaBank');
  String get completeYourTripToReceive => tr('completeYourTripToReceive');
  String get deliveryInProgress => tr('deliveryInProgress');
  String get headThereForHigherEarnings => tr('headThereForHigherEarnings');
  String get highDemandInYourArea => tr('highDemandInYourArea');
  String get movingInProgress => tr('movingInProgress');
  String get noBalanceToWithdraw => tr('noBalanceToWithdraw');
  String get noDestinationPassengerWillTell => tr('noDestinationPassengerWillTell');
  String get noTransactionsToday => tr('noTransactionsToday');
  String get pleaseEnterYourAccountNumber => tr('pleaseEnterYourAccountNumber');
  String get rideInProgress => tr('rideInProgress');
  String get thePassengerCancelledThatRide => tr('thePassengerCancelledThatRide');
  String get toggleOnlineToAcceptRides => tr('toggleOnlineToAcceptRides');
  String get transactionHistory => tr('transactionHistory');
  String get waitingForRequests => tr('waitingForRequests');
  String get withdrawalPendingApproval => tr('withdrawalPendingApproval');
  String get withdrawalsUnavailable => tr('withdrawalsUnavailable');
  String get urgent => tr('urgent');
  String get offline2 => tr('offline2');
  String get newRequest => tr('newRequest');
  String get newDelivery => tr('newDelivery');
  String get newRental => tr('newRental');
  String get newMoving => tr('newMoving');
  String get busyOnATrip => tr('busyOnATrip');
  String get onlineReady => tr('onlineReady');
  // ── helmet_check_screen ──
  String get chooseFromGallery => tr('chooseFromGallery');
  String get gallery => tr('gallery');
  String get pleaseWearAHelmetBefore => tr('pleaseWearAHelmetBefore');
  String get retake => tr('retake');
  String get takePhoto => tr('takePhoto');
  String get tapToUploadPhoto => tr('tapToUploadPhoto');
  String get uploadAPhotoToVerify => tr('uploadAPhotoToVerify');
  // ── helmet_check_screen messages ──
  String get checkHelmet => tr('checkHelmet');
  String get checking => tr('checking');
  String get helmetDetected => tr('helmetDetected');
  String get noHelmetDetected => tr('noHelmetDetected');
  // ── driver_withdrawal_screen ──
  String get amountKhr => tr('amountKhr');
  String get bankNameOptional => tr('bankNameOptional');
  String get confirm => tr('confirm');
  String get noWithdrawalHistory => tr('noWithdrawalHistory');
  String get pleaseMakeSureTheseDetails => tr('pleaseMakeSureTheseDetails');
  String get requestWithdrawal => tr('requestWithdrawal');
  String get withdrawalRequestSubmitted => tr('withdrawalRequestSubmitted');
  // ── driver_withdrawal_screen messages ──
  String get accountName => tr('accountName');
  String get amount => tr('amount');
  String get enterAValidAmount => tr('enterAValidAmount');
  String get enterAccountHolderName => tr('enterAccountHolderName');
  String get enterAccountNumber => tr('enterAccountNumber');
  String get fullNameAsOnAccount => tr('fullNameAsOnAccount');
  String get method => tr('method');
  String get wing => tr('wing');
  String get withdraw => tr('withdraw');
  String get eGAbaAcledaWing => tr('eGAbaAcledaWing');
  // ── driver_vehicle_screen ──
  String get colorOptional => tr('colorOptional');
  String get imagesUploaded => tr('imagesUploaded');
  String get licensePlate => tr('licensePlate');
  String get make => tr('make');
  String get model => tr('model');
  String get myVehicles => tr('myVehicles');
  String get noVehiclesRegistered => tr('noVehiclesRegistered');
  String get registerVehicle => tr('registerVehicle');
  String get registerYourVehicleToStart => tr('registerYourVehicleToStart');
  String get year => tr('year');
  // ── driver_vehicle_screen messages ──
  String get editVehicle => tr('editVehicle');
  String get honda => tr('honda');
  String get makeModelAndPlateAre => tr('makeModelAndPlateAre');
  String get motorbike => tr('motorbike');
  String get saveChanges => tr('saveChanges');
  String get truck => tr('truck');
  String get vehicle => tr('vehicle');
  String get wave => tr('wave');
  // ── driver_trip_summary_screen ──
  String get confirmed => tr('confirmed');
  String get fareSummary => tr('fareSummary');
  String get paymentMethod2 => tr('paymentMethod2');
  String get paymentReceived => tr('paymentReceived');
  String get totalFare => tr('totalFare');
  String get tripCompleted => tr('tripCompleted');
  // ── driver_trip_summary_screen messages ──
  String get bike3 => tr('bike3');
  String get noDestinationToldInPerson => tr('noDestinationToldInPerson');
  String get tukTuk4 => tr('tukTuk4');
  // ── driver_missions_screen ──
  String get acceptAJobFromThe => tr('acceptAJobFromThe');
  String get avgFare => tr('avgFare');
  String get earned => tr('earned');
  String get noRidesYet => tr('noRidesYet');
  String get tapToRefreshForLatest => tr('tapToRefreshForLatest');
  String get thisOrderWasCancelled => tr('thisOrderWasCancelled');
  // ── driver_missions_screen messages ──
  String get accepted2 => tr('accepted2');
  String get arrived2 => tr('arrived2');
  String get cancelled => tr('cancelled');
  String get delivery2 => tr('delivery2');
  String get done2 => tr('done2');
  String get delivered => tr('delivered');
  String get failedToLoadDeliveries => tr('failedToLoadDeliveries');
  String get failedToLoadMovings => tr('failedToLoadMovings');
  String get failedToLoadRideHistory => tr('failedToLoadRideHistory');
  String get inProgress => tr('inProgress');
  String get inTransit => tr('inTransit');
  String get loading2 => tr('loading2');
  String get moving2 => tr('moving2');
  String get pickedUp => tr('pickedUp');
  // ── driver_history_screen ──
  String get noMoreTrips => tr('noMoreTrips');
  String get noTripsYet => tr('noTripsYet');
  String get trip => tr('trip');
  String get yourCompletedTripsWillAppear => tr('yourCompletedTripsWillAppear');
  // ── driver_history_screen messages ──
  String get cancelled2 => tr('cancelled2');
  String get unknown => tr('unknown');
  String get yesterday => tr('yesterday');
  // ── driver_document_upload_screen ──
  String get optionalDocuments => tr('optionalDocuments');
  String get required => tr('required');
  String get requiredDocuments => tr('requiredDocuments');
  String get submitForReview => tr('submitForReview');
  String get uploadDocuments => tr('uploadDocuments');
  String get uploaded => tr('uploaded');
  String get yourDocumentsWillBeReviewed => tr('yourDocumentsWillBeReviewed');
  // ── driver_document_upload_screen messages ──
  String get driverLicense => tr('driverLicense');
  String get nationalIdPassport => tr('nationalIdPassport');
  String get optionalTapToUpload => tr('optionalTapToUpload');
  String get otherDocument => tr('otherDocument');
  String get ready => tr('ready');
  String get selfieWithId => tr('selfieWithId');
  String get tapToUpload => tr('tapToUpload');
  String get vehicleInsurance => tr('vehicleInsurance');
  String get vehicleRegistration => tr('vehicleRegistration');
  // ── Driver vehicle types ──
  String get van => tr('van');
  // ── Document upload ──
  String get requiredDocumentsUploadedSuffix => tr('requiredDocumentsUploadedSuffix');
  // ── Driver approval pending screen ──
  String get applicationStatus => tr('applicationStatus');
  String get pleaseReviewTheFeedbackOn => tr('pleaseReviewTheFeedbackOn');
  String get reUploadDocuments => tr('reUploadDocuments');
  String get refreshStatus => tr('refreshStatus');
  String get weLlNotifyYouOnce => tr('weLlNotifyYouOnce');
  String get whatToDoNext => tr('whatToDoNext');
  // ── Driver approval status ──
  String get documentReviewResults => tr('documentReviewResults');
  String get documentStatus => tr('documentStatus');
  String get approvedExcl => tr('approvedExcl');
  String get youCanNowGoOnline => tr('youCanNowGoOnline');
  String get applicationRejected => tr('applicationRejected');
  String get pleaseReviewDocsResubmit => tr('pleaseReviewDocsResubmit');
  String get underReview => tr('underReview');
  String get ourTeamIsReviewing => tr('ourTeamIsReviewing');
  String get city => tr('city');
  String get serviceZone => tr('serviceZone');
  String get approvedStatus => tr('approvedStatus');
  String get rejectedStatus => tr('rejectedStatus');
  String get pendingStatus => tr('pendingStatus');
  // ── Driver delivery active screen ──
  String get toUpdateProgressContinueFrom => tr('toUpdateProgressContinueFrom');
  String get you => tr('you');
  // ── Driver delivery active screen ──
  String get movingFrom => tr('movingFrom');
  String get movingTo => tr('movingTo');
  String get arriving => tr('arriving');
  String get arrivedAtLocation => tr('arrivedAtLocation');
  String get loadingComplete => tr('loadingComplete');
  String get markAsDelivered => tr('markAsDelivered');
  String get arrivedAtPickup => tr('arrivedAtPickup');
  String get packagePickedUp => tr('packagePickedUp');
  String get headingToPickupLocation => tr('headingToPickupLocation');
  String get atLocationLoadingItems => tr('atLocationLoadingItems');
  String get inTransitToNewLocation => tr('inTransitToNewLocation');
  String get movingCompleteExcl => tr('movingCompleteExcl');
  String get headingToSender => tr('headingToSender');
  String get atPickupCollectPackage => tr('atPickupCollectPackage');
  String get onTheWayToRecipient => tr('onTheWayToRecipient');
  String get deliveredExcl => tr('deliveredExcl');
  String get heading => tr('heading');
  String get atLocation => tr('atLocation');
  String get atPickup => tr('atPickup');
  String get youArrivedAtPickupLocation => tr('youArrivedAtPickupLocation');
  String get packagePickedUpHeadingToDropoff => tr('packagePickedUpHeadingToDropoff');
  String get arrivedAtMovingLocationStartLoading => tr('arrivedAtMovingLocationStartLoading');
  String get loadingCompleteHeadingToNewLocation => tr('loadingCompleteHeadingToNewLocation');
  String get minAway => tr('minAway');
  String get senderNumberPrefix => tr('senderNumberPrefix');
  // ── Driver active trip screen ──
  String get amountToCollect => tr('amountToCollect');
  String get arrivedAtStop => tr('arrivedAtStop');
  String get callNow => tr('callNow');
  String get completeTrip => tr('completeTrip');
  String get emergencySos => tr('emergencySos');
  String get enable => tr('enable');
  String get enterFinalFare => tr('enterFinalFare');
  String get locationPermissionDeniedLiveTracking => tr('locationPermissionDeniedLiveTracking');
  String get sos => tr('sos');
  String get sendSos => tr('sendSos');
  String get thisTripHadNoDestination => tr('thisTripHadNoDestination');
  String get thisWillAlertEmergencyServices => tr('thisWillAlertEmergencyServices');
  String get tripCompleted2 => tr('tripCompleted2');
  String get kmH => tr('kmH');
  String get sosSentHelpIsOn => tr('sosSentHelpIsOn');
  // ── Driver active trip screen ──
  String get passengerNumberPrefix => tr('passengerNumberPrefix');
  String get noDestinationAskPassenger => tr('noDestinationAskPassenger');
  String get bike4 => tr('bike4');
  String get tukTuk5 => tr('tukTuk5');
  String get continueStraight => tr('continueStraight');
  String get youHaveArrivedAt => tr('youHaveArrivedAt');
  String get noActiveRide => tr('noActiveRide');
  String get headingToPickup2 => tr('headingToPickup2');
  String get waitingAtPickup => tr('waitingAtPickup');
  String get arrivedAtPickupBtn => tr('arrivedAtPickupBtn');
  String get passengerOnBoardStartTrip => tr('passengerOnBoardStartTrip');
  String get backToDashboardBtn => tr('backToDashboardBtn');
  String get enterAValidAmount2 => tr('enterAValidAmount2');
  String get metered => tr('metered');
  String get youEarnedPrefix => tr('youEarnedPrefix');
  String get calculatedDistancePrefix => tr('calculatedDistancePrefix');
  String get looksWrongFartherThanTrip => tr('looksWrongFartherThanTrip');
  String get noFareReturnedForServiceType => tr('noFareReturnedForServiceType');
  String get fareCalculationFailedPrefix => tr('fareCalculationFailedPrefix');
  String get unknownError => tr('unknownError');
  String get tripHadNoDestinationSuggested => tr('tripHadNoDestinationSuggested');
  String get fromDistanceTravelledAdjust => tr('fromDistanceTravelledAdjust');
  // ── Driver active trip screen 2 ──
  String get tripInProgressCap => tr('tripInProgressCap');
  String get completeTripBtn => tr('completeTripBtn');
  // ── accessibility_screen ──
  String get accessibilityTitle => tr('accessibilityTitle');
  String get save => tr('save');
  String get accessibilitySettingsSaved => tr('accessibilitySettingsSaved');
  String get saveSettings => tr('saveSettings');
  String get visualSection => tr('visualSection');
  String get audioAndSpeechSection => tr('audioAndSpeechSection');
  String get interactionSection => tr('interactionSection');
  String get largeText => tr('largeText');
  String get largeTextSubtitle => tr('largeTextSubtitle');
  String get highContrast => tr('highContrast');
  String get highContrastSubtitle => tr('highContrastSubtitle');
  String get reduceMotion => tr('reduceMotion');
  String get reduceMotionSubtitle => tr('reduceMotionSubtitle');
  String get screenReaderSupport => tr('screenReaderSupport');
  String get screenReaderSupportSubtitle => tr('screenReaderSupportSubtitle');
  String get hapticFeedback => tr('hapticFeedback');
  String get hapticFeedbackSubtitle => tr('hapticFeedbackSubtitle');
  String get largeTouchTargets => tr('largeTouchTargets');
  String get largeTouchTargetsSubtitle => tr('largeTouchTargetsSubtitle');
  String get wheelchairAccessibleVehicles => tr('wheelchairAccessibleVehicles');
  String get wheelchairAccessibleVehiclesSubtitle => tr('wheelchairAccessibleVehiclesSubtitle');
  // ── airport_trip_screen ──
  String get airportTransferTitle => tr('airportTransferTitle');
  String get toAirportTab => tr('toAirportTab');
  String get fromAirportTab => tr('fromAirportTab');
  String get freeWaitBannerMessage => tr('freeWaitBannerMessage');
  String get dropoffAirportLabel => tr('dropoffAirportLabel');
  String get pickupAirportLabel => tr('pickupAirportLabel');
  String get pickupAddressLabel => tr('pickupAddressLabel');
  String get dropoffAddressLabel => tr('dropoffAddressLabel');
  String get enterHomeHotelAddressHint => tr('enterHomeHotelAddressHint');
  String get enterDestinationAddressHint => tr('enterDestinationAddressHint');
  String get flightDetailsLabel => tr('flightDetailsLabel');
  String get flightNumberHint => tr('flightNumberHint');
  String get terminalHint => tr('terminalHint');
  String get departureTime => tr('departureTime');
  String get arrivalTime => tr('arrivalTime');
  String get vehicleTypeLabel => tr('vehicleTypeLabel');
  String get sedanLabel => tr('sedanLabel');
  String get upTo4Pax => tr('upTo4Pax');
  String get suvVanLabel => tr('suvVanLabel');
  String get upTo6Pax => tr('upTo6Pax');
  String get passengersAndLuggageLabel => tr('passengersAndLuggageLabel');
  String get passengersLabel => tr('passengersLabel');
  String get luggageBagsLabel => tr('luggageBagsLabel');
  String get enterAddressForFareEstimate => tr('enterAddressForFareEstimate');
  String get airportSurcharge => tr('airportSurcharge');
  String get bookingFee => tr('bookingFee');
  String get distanceFare => tr('distanceFare');
  String get timeFare => tr('timeFare');
  String get nightSurcharge => tr('nightSurcharge');
  String get weekendSurcharge => tr('weekendSurcharge');
  String get holidaySurcharge => tr('holidaySurcharge');
  String get fareRoundingAdjustment => tr('fareRoundingAdjustment');
  String get luggageBagsCountLabel => tr('luggageBagsCountLabel');
  String get fixedPriceNoSurge => tr('fixedPriceNoSurge');
  String get bookTransferPrefix => tr('bookTransferPrefix');
  String get bookAirportTransfer => tr('bookAirportTransfer');
  String get fillAddressFlightDetailsError => tr('fillAddressFlightDetailsError');
  String get airportFallback => tr('airportFallback');
  // ── cancellation_policy_screen ──
  String get cancellationPolicyTitle => tr('cancellationPolicyTitle');
  String get feesGoToDriversNote => tr('feesGoToDriversNote');
  String get contactSupport => tr('contactSupport');
  String get beforeDriverAccepts => tr('beforeDriverAccepts');
  String get freeCancellation => tr('freeCancellation');
  String get freeCancelBeforeAcceptDetail => tr('freeCancelBeforeAcceptDetail');
  String get afterDriverAccepts => tr('afterDriverAccepts');
  String cancelRangeMinutes(int from, int to) =>
      tr('cancelRangeMinutes').replaceAll('{from}', '$from').replaceAll('{to}', '$to');
  String cancelRangeFromMinutes(int from) => tr('cancelRangeFromMinutes').replaceAll('{from}', '$from');
  String cancelFeeAmount(String fee) => tr('cancelFeeAmount').replaceAll('{fee}', fee);
  String get cancelTierFreeDetail => tr('cancelTierFreeDetail');
  String cancelTierFeeDetail(String fee) => tr('cancelTierFeeDetail').replaceAll('{fee}', fee);
  String get cancellationPolicyLoadFailed => tr('cancellationPolicyLoadFailed');
  String get afterDriverArrives => tr('afterDriverArrives');
  // ── car_rental_screen ──
  String get durMonth1 => tr('durMonth1');
  String get durMonth2 => tr('durMonth2');
  String get durMonth3 => tr('durMonth3');
  String get durMonth6 => tr('durMonth6');
  String get durYear1 => tr('durYear1');
  String get durYear2 => tr('durYear2');
  String get pickUpLabel => tr('pickUpLabel');
  String get collectCarMyself => tr('collectCarMyself');
  String get deliverCarToAddress => tr('deliverCarToAddress');
  String get tapToSetPickupLocation => tr('tapToSetPickupLocation');
  String get tapToSetDeliveryLocation => tr('tapToSetDeliveryLocation');
  String get setPickupLocationTitle => tr('setPickupLocationTitle');
  String get setDeliveryLocationTitle => tr('setDeliveryLocationTitle');
  String get suvLabel => tr('suvLabel');
  String get electricLabel => tr('electricLabel');
  String get locationTypeLabel => tr('locationTypeLabel');
  String get rentalDurationTitle => tr('rentalDurationTitle');
  String get endsPrefix => tr('endsPrefix');
  String get payInCashOnPickup => tr('payInCashOnPickup');
  String get failedToApplyCoupon => tr('failedToApplyCoupon');
  String get bookedHashPrefix => tr('bookedHashPrefix');
  String get datesLabel => tr('datesLabel');
  String get dailyRateLabel => tr('dailyRateLabel');
  String get renterLabel => tr('renterLabel');
  String get selectVehicleBeforeBooking => tr('selectVehicleBeforeBooking');
  String get setDeliveryLocationError => tr('setDeliveryLocationError');
  String get enterNamePhoneError => tr('enterNamePhoneError');
  String get rentalVehicleTitle => tr('rentalVehicleTitle');
  String get locationLabel => tr('locationLabel');
  String get vehicleForRentLabel => tr('vehicleForRentLabel');
  String get browseAvailableVehicle => tr('browseAvailableVehicle');
  String get tapToViewAllVehicles => tr('tapToViewAllVehicles');
  String get rentalPeriodLabel => tr('rentalPeriodLabel');
  String get daysLabel => tr('daysLabel');
  String get endsLabel => tr('endsLabel');
  String get startDateLabel => tr('startDateLabel');
  String get endDateAutoLabel => tr('endDateAutoLabel');
  String get yourInformationLabel => tr('yourInformationLabel');
  String get notesOptionalLabel => tr('notesOptionalLabel');
  String get anySpecialRequestsHint => tr('anySpecialRequestsHint');
  String get couponCodeLabel => tr('couponCodeLabel');
  String get discountAppliedSuffix => tr('discountAppliedSuffix');
  String get enterCouponCodeHint => tr('enterCouponCodeHint');
  String get bookingSummaryLabel => tr('bookingSummaryLabel');
  String get discountLabel => tr('discountLabel');
  String get bookNowLabel => tr('bookNowLabel');
  String get selectAVehicleLabel => tr('selectAVehicleLabel');
  String get rentDashPrefix => tr('rentDashPrefix');
  String get failedToLoadVehicles => tr('failedToLoadVehicles');
  String get noVehicleAvailableForRent => tr('noVehicleAvailableForRent');
  String get photosCountSuffix => tr('photosCountSuffix');
  String get daysCapLabel => tr('daysCapLabel');
  // ── charging_stations ──
  String get favoritesLabel => tr('favoritesLabel');
  String get fastChargingLabel => tr('fastChargingLabel');
  String get showLess => tr('showLess');
  String get myLocationLabel => tr('myLocationLabel');
  String get sortedByDistanceFromLocation => tr('sortedByDistanceFromLocation');
  String get sortedByDistanceFromPhnomPenh => tr('sortedByDistanceFromPhnomPenh');
  String get findingYourLocation => tr('findingYourLocation');
  String get myLocationUnavailable => tr('myLocationUnavailable');
  String get nearbyChargingStationsTitle => tr('nearbyChargingStationsTitle');
  String get availableSuffix => tr('availableSuffix');
  // ── edit_profile_screen ──
  String get takeAPhoto => tr('takeAPhoto');
  String get couldNotUpdatePhotoPrefix => tr('couldNotUpdatePhotoPrefix');
  String get couldNotUpdatePhotoTryAgain => tr('couldNotUpdatePhotoTryAgain');
  String get profileUpdatedSuccess => tr('profileUpdatedSuccess');
  String get tapPhotoToChange => tr('tapPhotoToChange');
  String get otpRequiredBadge => tr('otpRequiredBadge');
  String get changingPhoneRequiresOtp => tr('changingPhoneRequiresOtp');
  String get enterSixDigitCode => tr('enterSixDigitCode');
  String get verifyPhoneNumberTitle => tr('verifyPhoneNumberTitle');
  String get codeSentToPrefix => tr('codeSentToPrefix');
  String get devCodePrefix => tr('devCodePrefix');
  String get sendingOtpEllipsis => tr('sendingOtpEllipsis');
  String get expiresInPrefix => tr('expiresInPrefix');
  String get codeExpired => tr('codeExpired');
  String get resendInPrefix => tr('resendInPrefix');
  String get verify => tr('verify');
  // ── family_screen ──
  String get familyAccountTitle => tr('familyAccountTitle');
  String get addMemberTooltip => tr('addMemberTooltip');
  String get createFamilyGroupTitle => tr('createFamilyGroupTitle');
  String get familyGroupDescription => tr('familyGroupDescription');
  String get groupNameHint => tr('groupNameHint');
  String get createGroup => tr('createGroup');
  String get membersLabel => tr('membersLabel');
  String get add => tr('add');
  String get noMembersYetMsg => tr('noMembersYetMsg');
  String get membersCountSuffix => tr('membersCountSuffix');
  String get fromFamilyGroupQuestionSuffix => tr('fromFamilyGroupQuestionSuffix');
  String get hasAutorideAccountLabel => tr('hasAutorideAccountLabel');
  String get bookLabel => tr('bookLabel');
  String get addFamilyMemberTitle => tr('addFamilyMemberTitle');
  String get fullNameStarHint => tr('fullNameStarHint');
  String get phoneNumberStarHint => tr('phoneNumberStarHint');
  String get relationshipHint => tr('relationshipHint');
  String get addMemberBtn => tr('addMemberBtn');
  String get fullNameHint => tr('fullNameHint');
  String get phoneNumberHint2 => tr('phoneNumberHint2');
  String get mother => tr('mother');
  String get father => tr('father');
  String get spouse => tr('spouse');
  String get son => tr('son');
  String get daughter => tr('daughter');
  String get sibling => tr('sibling');
  String get friend => tr('friend');
  // ── loyalty_screen ──
  String get rotehRewardsTitle => tr('rotehRewardsTitle');
  String get redeemPointsTitle => tr('redeemPointsTitle');
  String get redeem500ptsQuestion => tr('redeem500ptsQuestion');
  String get pts500Redeemed => tr('pts500Redeemed');
  String get redeem500pts => tr('redeem500pts');
  String get rotehPointsLabel => tr('rotehPointsLabel');
  String get ptsSuffix => tr('ptsSuffix');
  String get maxTierReached => tr('maxTierReached');
  String get ptsToPlatinumSuffix => tr('ptsToPlatinumSuffix');
  String get ptsToGoldSuffix => tr('ptsToGoldSuffix');
  String get ptsToSilverSuffix => tr('ptsToSilverSuffix');
  String get membershipTiersTitle => tr('membershipTiersTitle');
  String get currentBadge => tr('currentBadge');
  String get howToEarnTitle => tr('howToEarnTitle');
  String get pointsActivityTitle => tr('pointsActivityTitle');
  String get bronzeTier => tr('bronzeTier');
  String get silverTier => tr('silverTier');
  String get goldTier => tr('goldTier');
  String get platinumTier => tr('platinumTier');
  String get ptsPer1000Spent10 => tr('ptsPer1000Spent10');
  String get birthdayBonus100pts => tr('birthdayBonus100pts');
  String get basicSupport => tr('basicSupport');
  String get ptsPer1000Spent12 => tr('ptsPer1000Spent12');
  String get priorityMatching => tr('priorityMatching');
  String get fareDiscount5pct => tr('fareDiscount5pct');
  String get ptsPer1000Spent15 => tr('ptsPer1000Spent15');
  String get fareDiscount10pct => tr('fareDiscount10pct');
  String get freeCancellation3perMo => tr('freeCancellation3perMo');
  String get ptsPer1000Spent20 => tr('ptsPer1000Spent20');
  String get fareDiscount15pct => tr('fareDiscount15pct');
  String get dedicatedSupportLine => tr('dedicatedSupportLine');
  String get freeCancellationUnlimited => tr('freeCancellationUnlimited');
  String get completeATrip => tr('completeATrip');
  String get ptsPer1000Simple10 => tr('ptsPer1000Simple10');
  String get rateYourDriver => tr('rateYourDriver');
  String get ptsBonus50 => tr('ptsBonus50');
  String get referAFriend => tr('referAFriend');
  String get ptsPerReferral500 => tr('ptsPerReferral500');
  String get pointsFallback => tr('pointsFallback');
  // ── my_rentals_screen ──
  String get noRentalsFound => tr('noRentalsFound');
  String get orderHashPrefix => tr('orderHashPrefix');
  String get rentalHashPrefix => tr('rentalHashPrefix');
  String get rentalVehicleBadge => tr('rentalVehicleBadge');
  String get cancelRentalTitle => tr('cancelRentalTitle');
  String get cancelRentalConfirmMsg => tr('cancelRentalConfirmMsg');
  String get yesCancelBtn => tr('yesCancelBtn');
  String get electricVehicleLabel => tr('electricVehicleLabel');
  // ── notifications_screen ──
  String get justNow => tr('justNow');
  String get minAgoSuffix => tr('minAgoSuffix');
  String get hrsAgoSuffix => tr('hrsAgoSuffix');
  String get daysAgoSuffix => tr('daysAgoSuffix');
  String get markAllRead => tr('markAllRead');
  String get noNotificationsYet => tr('noNotificationsYet');
  String get notificationFallback => tr('notificationFallback');
  // ── payment_methods_screen ──
  String get cardsSection => tr('cardsSection');
  String get noCardsAddedYet => tr('noCardsAddedYet');
  String get linkedAccountsSection => tr('linkedAccountsSection');
  String get addMethodLabel => tr('addMethodLabel');
  String get defaultBadge => tr('defaultBadge');
  String get setAsDefaultOption => tr('setAsDefaultOption');
  String get removeOption => tr('removeOption');
  String get unlinkOption => tr('unlinkOption');
  String get linkedLabel => tr('linkedLabel');
  String get notLinkedLabel => tr('notLinkedLabel');
  String get addPaymentMethodTitle => tr('addPaymentMethodTitle');
  String get cardOptionLabel => tr('cardOptionLabel');
  String get cardOptionSubtitle => tr('cardOptionSubtitle');
  String get alreadyLinked => tr('alreadyLinked');
  String get linkYourAbaAccount => tr('linkYourAbaAccount');
  String get linkYourAcledaAccount => tr('linkYourAcledaAccount');
  String get cardNumberLabel => tr('cardNumberLabel');
  String get expiryDateLabel => tr('expiryDateLabel');
  String get cvvLabel => tr('cvvLabel');
  String get setAsDefaultSwitch => tr('setAsDefaultSwitch');
  String get addCardBtn => tr('addCardBtn');
  String get phoneNumberHintExample => tr('phoneNumberHintExample');
  String get linkAccountBtn => tr('linkAccountBtn');
  String get linkAbaPayTitle => tr('linkAbaPayTitle');
  String get linkAcledaPayTitle => tr('linkAcledaPayTitle');
  String get enterValidCardNumber => tr('enterValidCardNumber');
  String get enterExpiryMMYY => tr('enterExpiryMMYY');
  String get cardExpiredError => tr('cardExpiredError');
  String get enterValidCvv => tr('enterValidCvv');
  String get expiresPrefix => tr('expiresPrefix');
  String get minOrderPrefix => tr('minOrderPrefix');
  String get byCodeTab => tr('byCodeTab');
  String get byRotehPayTab => tr('byRotehPayTab');
  String get payWithRotehPay => tr('payWithRotehPay');
  String get enterAccountPhoneNumber => tr('enterAccountPhoneNumber');
  // ── promo_screen ──
  String get promosTabLabel => tr('promosTabLabel');
  String get storeTabLabel => tr('storeTabLabel');
  String get myVouchersTabLabel => tr('myVouchersTabLabel');
  String get enterPromoCodeTitle => tr('enterPromoCodeTitle');
  String get codeHintExample => tr('codeHintExample');
  String get invalidExpiredPromoCode => tr('invalidExpiredPromoCode');
  String get couldNotValidateCode => tr('couldNotValidateCode');
  String get discountAppliedFallback => tr('discountAppliedFallback');
  String get offSuffix => tr('offSuffix');
  String get promoAppliedDashPrefix => tr('promoAppliedDashPrefix');
  String get appliedDashSuffix => tr('appliedDashSuffix');
  String get codeCopiedPrefix => tr('codeCopiedPrefix');
  String get copiedSuffix => tr('copiedSuffix');
  String get availableVouchersTitle => tr('availableVouchersTitle');
  String get noExpiry => tr('noExpiry');
  String get promo1Title => tr('promo1Title');
  String get promo1Desc => tr('promo1Desc');
  String get promo2Title => tr('promo2Title');
  String get promo2Desc => tr('promo2Desc');
  String get promo3Title => tr('promo3Title');
  String get promo3Desc => tr('promo3Desc');
  String get promo4Title => tr('promo4Title');
  String get promo4Desc => tr('promo4Desc');
  String get promo5Title => tr('promo5Title');
  String get promo5Desc => tr('promo5Desc');
  String get freeLabel => tr('freeLabel');
  // ── qr_payment_screen ──
  String get qrPaymentTitle => tr('qrPaymentTitle');
  String get myQrTabLabel => tr('myQrTabLabel');
  String get enterValidAmountKhr => tr('enterValidAmountKhr');
  String get generateQrToReceive => tr('generateQrToReceive');
  String get enterAmountShareQr => tr('enterAmountShareQr');
  String get amountKhrLabel => tr('amountKhrLabel');
  String get generatingEllipsis => tr('generatingEllipsis');
  String get generateQrBtn => tr('generateQrBtn');
  String get qrExpired => tr('qrExpired');
  String get waitingForPayment => tr('waitingForPayment');
  String get qrReferenceCopied => tr('qrReferenceCopied');
  String get newQrBtn => tr('newQrBtn');
  String get noQrPaymentHistory => tr('noQrPaymentHistory');
  String get paidStatus => tr('paidStatus');
  // ── rate_driver_screen ──
  String get rateYourTripTitle => tr('rateYourTripTitle');
  String get howWasYourTripQuestion => tr('howWasYourTripQuestion');
  String get tapToRate => tr('tapToRate');
  String get ratingTerrible => tr('ratingTerrible');
  String get ratingBad => tr('ratingBad');
  String get ratingOkay => tr('ratingOkay');
  String get ratingGood => tr('ratingGood');
  String get ratingExcellent => tr('ratingExcellent');
  String get whatDidYouLoveQuestion => tr('whatDidYouLoveQuestion');
  String get whatWentWrongQuestion => tr('whatWentWrongQuestion');
  String get addCommentOptionalHint => tr('addCommentOptionalHint');
  String get addATipQuestion => tr('addATipQuestion');
  String get noTipLabel => tr('noTipLabel');
  String get tipFailedPrefix => tr('tipFailedPrefix');
  String get submitRatingBtn => tr('submitRatingBtn');
  String get thankYouExcl => tr('thankYouExcl');
  String get feedbackHelpsImprove => tr('feedbackHelpsImprove');
  String get greatDrivingTag => tr('greatDrivingTag');
  String get veryFriendlyTag => tr('veryFriendlyTag');
  String get cleanCarTag => tr('cleanCarTag');
  String get onTimeTag => tr('onTimeTag');
  String get safeRideTag => tr('safeRideTag');
  String get latePickupTag => tr('latePickupTag');
  String get rudeTag => tr('rudeTag');
  String get unsafeDrivingTag => tr('unsafeDrivingTag');
  String get dirtyCarTag => tr('dirtyCarTag');
  String get wrongRouteTag => tr('wrongRouteTag');
  // ── referral_screen ──
  String get referralTitle => tr('referralTitle');
  String get copiedExcl => tr('copiedExcl');
  String get shareAndEarn => tr('shareAndEarn');
  String get giveFriendsDiscountDesc => tr('giveFriendsDiscountDesc');
  String get yourReferralCode => tr('yourReferralCode');
  String get shareWithFriends => tr('shareWithFriends');
  String get friendsReferred => tr('friendsReferred');
  String get pointsEarnedLabel => tr('pointsEarnedLabel');
  String get friendsWhoJoined => tr('friendsWhoJoined');
  String get joinedPrefix => tr('joinedPrefix');
  String get joinRotehWithCodePrefix => tr('joinRotehWithCodePrefix');
  String get get10000OffFirstRideSuffix => tr('get10000OffFirstRideSuffix');
  String get downloadRotehNow => tr('downloadRotehNow');
  // ── safety_screen ──
  String get safetyCenterTitle => tr('safetyCenterTitle');
  String get emergencySosLabel => tr('emergencySosLabel');
  String get holdToActivate => tr('holdToActivate');
  String get fakeCallLabel => tr('fakeCallLabel');
  String get stopSharingLabel => tr('stopSharingLabel');
  String get reportLabel => tr('reportLabel');
  String get emergencyContactsTitle => tr('emergencyContactsTitle');
  String get noEmergencyContactsYet => tr('noEmergencyContactsYet');
  String get safetyResourcesTitle => tr('safetyResourcesTitle');
  String get emergencyPhoneNumbers => tr('emergencyPhoneNumbers');
  String get reportIncidentLabel => tr('reportIncidentLabel');
  String get safetyGuidelinesLabel => tr('safetyGuidelinesLabel');
  String get sosSentToPrefix => tr('sosSentToPrefix');
  String get contactsSuffix => tr('contactsSuffix');
  String get noActiveRideToShare => tr('noActiveRideToShare');
  String get sharingStopped => tr('sharingStopped');
  String get tripLinkSharedTitle => tr('tripLinkSharedTitle');
  String get shareLinkTrackDesc => tr('shareLinkTrackDesc');
  String get sosWillBeSentNoContacts => tr('sosWillBeSentNoContacts');
  String get sosWillBeSentToContactsPrefix => tr('sosWillBeSentToContactsPrefix');
  String get emergencyContactsImmediatelySuffix => tr('emergencyContactsImmediatelySuffix');
  String get harassmentTag => tr('harassmentTag');
  String get unsafeDrivingTitleTag => tr('unsafeDrivingTitleTag');
  String get overchargeTag => tr('overchargeTag');
  String get otherTag => tr('otherTag');
  String get describeWhatHappenedHint => tr('describeWhatHappenedHint');
  String get submitReportBtn => tr('submitReportBtn');
  String get incidentReportedThanks => tr('incidentReportedThanks');
  String get addEmergencyContactTitle => tr('addEmergencyContactTitle');
  String get relationshipHintExample => tr('relationshipHintExample');
  String get notifyOnSos => tr('notifyOnSos');
  String get notifyOnTripShare => tr('notifyOnTripShare');
  String get addContactBtn => tr('addContactBtn');
  String get contactAddedExcl => tr('contactAddedExcl');
  String get editContactTitle => tr('editContactTitle');
  String get contactUpdatedExcl => tr('contactUpdatedExcl');
  String get removeContactQuestion => tr('removeContactQuestion');
  String get willBeRemovedFromContactsSuffix => tr('willBeRemovedFromContactsSuffix');
  String get contactRemoved => tr('contactRemoved');
  String get sosTagLabel => tr('sosTagLabel');
  String get tripShareTagLabel => tr('tripShareTagLabel');
  String get fakeCallChooseDelayTitle => tr('fakeCallChooseDelayTitle');
  String get phoneWillRingDesc => tr('phoneWillRingDesc');
  String get nowSecLabel => tr('nowSecLabel');
  String get inSecLabel10 => tr('inSecLabel10');
  String get inSecLabel30 => tr('inSecLabel30');
  String get inMinLabel1 => tr('inMinLabel1');
  String get incomingCallEllipsis => tr('incomingCallEllipsis');
  String get fakeCallInPrefix => tr('fakeCallInPrefix');
  String get secondsSuffix => tr('secondsSuffix');
  // ── saved_places_screen ──
  String get deletePlaceQuestion => tr('deletePlaceQuestion');
  String get removePlacePrefix => tr('removePlacePrefix');
  String get fromSavedPlacesQuestionSuffix => tr('fromSavedPlacesQuestionSuffix');
  String get removedSuffix => tr('removedSuffix');
  String get addHomeLabel => tr('addHomeLabel');
  String get addWorkLabel => tr('addWorkLabel');
  String get yourPlacesLabel => tr('yourPlacesLabel');
  String get saveHomeWorkDesc => tr('saveHomeWorkDesc');
  String get addAPlaceBtn => tr('addAPlaceBtn');
  String get editPlaceTitle => tr('editPlaceTitle');
  String get addPlaceTitle => tr('addPlaceTitle');
  String get labelHintExample => tr('labelHintExample');
  String get openingMapEllipsis => tr('openingMapEllipsis');
  String get searchOrDragPinHint => tr('searchOrDragPinHint');
  String get setAsDefaultCheckbox => tr('setAsDefaultCheckbox');
  String get labelAndLocationRequired => tr('labelAndLocationRequired');
  String get setLocationTitle => tr('setLocationTitle');
  String get labelFieldTitle => tr('labelFieldTitle');
  // ── scheduled_rides_screen ──
  String get scheduledRidesTitle => tr('scheduledRidesTitle');
  String get pastLabel => tr('pastLabel');
  String get inPrefix => tr('inPrefix');
  String get daysLabel2 => tr('daysLabel2');
  String get hrsLabel => tr('hrsLabel');
  String get minLabel => tr('minLabel');
  String get cancelRideTitle => tr('cancelRideTitle');
  String get cancelScheduledRideConfirm => tr('cancelScheduledRideConfirm');
  String get keepLabel => tr('keepLabel');
  String get rideCancelledPeriod => tr('rideCancelledPeriod');
  String get noUpcomingRides => tr('noUpcomingRides');
  String get scheduleRideToSeeHere => tr('scheduleRideToSeeHere');
  String get modifyComingSoon => tr('modifyComingSoon');
  String get modifyBtn => tr('modifyBtn');
  String get jan => tr('jan');
  String get feb => tr('feb');
  String get mar => tr('mar');
  String get apr => tr('apr');
  String get may => tr('may');
  String get jun => tr('jun');
  String get jul => tr('jul');
  String get aug => tr('aug');
  String get sep => tr('sep');
  String get oct => tr('oct');
  String get nov => tr('nov');
  String get dec => tr('dec');
  // ── subscription_screen ──
  String get subscriptionPlansTitle => tr('subscriptionPlansTitle');
  String get plansTab => tr('plansTab');
  String get upgradeToPrefix => tr('upgradeToPrefix');
  String get subscribeToPrefix => tr('subscribeToPrefix');
  String get paymentColonPrefix => tr('paymentColonPrefix');
  String get upgradeBtn => tr('upgradeBtn');
  String get subscribeBtn => tr('subscribeBtn');
  String get cancelSubscriptionQuestion => tr('cancelSubscriptionQuestion');
  String get benefitsContinueDesc => tr('benefitsContinueDesc');
  String get cancelPlanBtn => tr('cancelPlanBtn');
  String get autoRideWalletLabel => tr('autoRideWalletLabel');
  String get creditDebitCardLabel => tr('creditDebitCardLabel');
  String get cardLabel => tr('cardLabel');
  String get changePlanLabel => tr('changePlanLabel');
  String get choosePlanLabel => tr('choosePlanLabel');
  String get rideCreditLabel => tr('rideCreditLabel');
  String get leftSuffix => tr('leftSuffix');
  String get cancellationsLeftLabel => tr('cancellationsLeftLabel');
  String get autoRenewLabel => tr('autoRenewLabel');
  String get creditSuffix => tr('creditSuffix');
  String get offRidesSuffix => tr('offRidesSuffix');
  String get offDeliverySuffix => tr('offDeliverySuffix');
  String get noSurgeLabel => tr('noSurgeLabel');
  String get freeCancellationsPerMonthSuffix => tr('freeCancellationsPerMonthSuffix');
  String get bonusLoyaltyPointsSuffix => tr('bonusLoyaltyPointsSuffix');
  String get currentPlanBtn => tr('currentPlanBtn');
  String get noBillingHistoryYet => tr('noBillingHistoryYet');
  String get newSubscriptionLabel => tr('newSubscriptionLabel');
  String get renewalLabel => tr('renewalLabel');
  String get cancellationLabel => tr('cancellationLabel');
  // ── support_screen ──
  String get myTicketsTab => tr('myTicketsTab');
  String get faqTab => tr('faqTab');
  String get noSupportTickets => tr('noSupportTickets');
  String get tapPlusToCreateTicket => tr('tapPlusToCreateTicket');
  String get openParenPrefix => tr('openParenPrefix');
  String get resolvedParenPrefix => tr('resolvedParenPrefix');
  String get repliesCountLabel => tr('repliesCountLabel');
  String get dAgoSuffix => tr('dAgoSuffix');
  String get hAgoSuffix => tr('hAgoSuffix');
  String get mAgoSuffix => tr('mAgoSuffix');
  String get needHelpTitle => tr('needHelpTitle');
  String get cantFindAnswerDesc => tr('cantFindAnswerDesc');
  String get subjectAndMessageRequired => tr('subjectAndMessageRequired');
  String get newSupportTicketTitle => tr('newSupportTicketTitle');
  String get priorityColonLabel => tr('priorityColonLabel');
  String get highPriority => tr('highPriority');
  String get urgentPriority => tr('urgentPriority');
  String get subjectLabel => tr('subjectLabel');
  String get describeYourIssueLabel => tr('describeYourIssueLabel');
  String get submitTicketBtn => tr('submitTicketBtn');
  String get noRepliesYetDesc => tr('noRepliesYetDesc');
  String get writeAReplyHint => tr('writeAReplyHint');
  String get supportTeamLabel => tr('supportTeamLabel');
  String get faq1Q => tr('faq1Q');
  String get faq1A => tr('faq1A');
  String get faq2Q => tr('faq2Q');
  String get faq2A => tr('faq2A');
  String get faq3Q => tr('faq3Q');
  String get faq3A => tr('faq3A');
  String get faq4Q => tr('faq4Q');
  String get faq4A => tr('faq4A');
  String get faq5Q => tr('faq5Q');
  String get faq5A => tr('faq5A');
  String get faq6Q => tr('faq6Q');
  String get faq6A => tr('faq6A');
  String get faq7Q => tr('faq7Q');
  String get faq7A => tr('faq7A');
  // ── trip_history_screen ──
  String get tripTitle => tr('tripTitle');
  String get spentLabel => tr('spentLabel');
  String get noTripsFound => tr('noTripsFound');
  String get byDayLabel => tr('byDayLabel');
  String get filterTripsTitle => tr('filterTripsTitle');
  String get resetLabel => tr('resetLabel');
  String get applyFiltersBtn => tr('applyFiltersBtn');
  String get allTripsLabel => tr('allTripsLabel');
  String get tipSuffix2 => tr('tipSuffix2');
  String get thisTripNoDestinationRebook => tr('thisTripNoDestinationRebook');
  String get bookAgainBtn => tr('bookAgainBtn');
  String get rateBtn => tr('rateBtn');
  // ── voucher_screen ──
  String get vouchersTitle => tr('vouchersTitle');
  String get voucherClaimedCheckMy => tr('voucherClaimedCheckMy');
  String get noVouchersAvailable => tr('noVouchersAvailable');
  String get claimBtn => tr('claimBtn');
  String get noVouchersYet => tr('noVouchersYet');
  String get claimFromStoreTab => tr('claimFromStoreTab');
  String get usedBadge => tr('usedBadge');
  String get usedBadgeCap => tr('usedBadgeCap');
  String get expPrefix => tr('expPrefix');
  String get voucherFallback => tr('voucherFallback');
  // ── business_screen ──
  String get tabAccount => tr('tabAccount');
  String get tabMembers => tr('tabMembers');
  String get registerABusiness => tr('registerABusiness');
  String get joinWithInviteCode => tr('joinWithInviteCode');
  String get joinBusinessAccount => tr('joinBusinessAccount');
  String get inviteCodeHint => tr('inviteCodeHint');
  String get joinBusiness => tr('joinBusiness');
  String get registerBusiness => tr('registerBusiness');
  String get companyNameRequiredHint => tr('companyNameRequiredHint');
  String get taxIdHint => tr('taxIdHint');
  String get industryHint => tr('industryHint');
  String get contactPerson => tr('contactPerson');
  String get contactNameRequiredHint => tr('contactNameRequiredHint');
  String get contactPhoneHint => tr('contactPhoneHint');
  String get billingEmailRequiredHint => tr('billingEmailRequiredHint');
  String get billingCycle => tr('billingCycle');
  String get companyAddressHint => tr('companyAddressHint');
  String get taxIdLabel => tr('taxIdLabel');
  String get billingEmailLabel => tr('billingEmailLabel');
  String get billingCycleLabel => tr('billingCycleLabel');
  String get contactLabel => tr('contactLabel');
  String get addressLabel => tr('addressLabel');
  String get inviteCodeLabel => tr('inviteCodeLabel');
  String get editAccount => tr('editAccount');
  String get editBusinessAccount => tr('editBusinessAccount');
  String get companyNameHint => tr('companyNameHint');
  String get billingEmailHint => tr('billingEmailHint');
  String get contactNameHint => tr('contactNameHint');
  String get addressHint => tr('addressHint');
  String get roleMemberAdminHint => tr('roleMemberAdminHint');
  String get departmentHint => tr('departmentHint');
  String get costCenterHint => tr('costCenterHint');
  String get employeeIdHint => tr('employeeIdHint');
  String get monthlyLimitKhrHint => tr('monthlyLimitKhrHint');
  String get businessTripDefault => tr('businessTripDefault');
  String get weeklyLabel => tr('weeklyLabel');
  String get monthlyLabel => tr('monthlyLabel');
  // ── settings_screen ──
  String get settingsTitle => tr('settingsTitle');
  String get biometricLogin => tr('biometricLogin');
  // ── onboarding_screen ──
  String get next => tr('next');
  String get getStarted => tr('getStarted');
  String get onboardWelcomeTitle => tr('onboardWelcomeTitle');
  String get onboardWelcomeSubtitle => tr('onboardWelcomeSubtitle');
  String get onboardBookTitle => tr('onboardBookTitle');
  String get onboardBookSubtitle => tr('onboardBookSubtitle');
  String get onboardPaySubtitle => tr('onboardPaySubtitle');
  String get onboardRewardsTitle => tr('onboardRewardsTitle');
  String get onboardRewardsSubtitle => tr('onboardRewardsSubtitle');
  // ── auth_service ──
  String get phoneVerificationFailedMsg => tr('phoneVerificationFailedMsg');
  String get couldNotObtainFirebaseToken => tr('couldNotObtainFirebaseToken');
  // ── marketplace_screen ──
  String get browseTab => tr('browseTab');
  String get myOrdersTab => tr('myOrdersTab');
  String get popularListings => tr('popularListings');
  String get recentListings => tr('recentListings');
  String get allListingsTitle => tr('allListingsTitle');
  String get forSaleLabel => tr('forSaleLabel');
  String get forRentLabel => tr('forRentLabel');
  String get saleAndRentLabel => tr('saleAndRentLabel');
  String get listingTypeLabel => tr('listingTypeLabel');
  String get conditionNewLabel => tr('conditionNewLabel');
  String get conditionUsedLabel => tr('conditionUsedLabel');
  String get conditionRefurbishedLabel => tr('conditionRefurbishedLabel');
  String get conditionRefurbAbbrev => tr('conditionRefurbAbbrev');
  String get viewsCountSuffix => tr('viewsCountSuffix');
  String get viewsSpecLabel => tr('viewsSpecLabel');
  String get perDaySpecLabel => tr('perDaySpecLabel');
  String get buyNowLabel => tr('buyNowLabel');
  String get rentNowLabel => tr('rentNowLabel');
  String get searchLocationHint => tr('searchLocationHint');
  String get dragMapToSetLocation => tr('dragMapToSetLocation');
  String get setPickupHere => tr('setPickupHere');
  String get setDropoffHere => tr('setDropoffHere');
  String get pickUpShortLabel => tr('pickUpShortLabel');
  String get deliverCarToMyAddress => tr('deliverCarToMyAddress');
  String get addItemTitle => tr('addItemTitle');
  String get searchListingsHint => tr('searchListingsHint');
  String get selectRentalDatesError => tr('selectRentalDatesError');
  String get walletLabel => tr('walletLabel');
  String get onlineLabel => tr('onlineLabel');
  String get buyItemTitle => tr('buyItemTitle');
  String get rentItemTitle => tr('rentItemTitle');
  String get durationLabel => tr('durationLabel');
  String get selectLabel => tr('selectLabel');
  String get anySpecialInstructionsHint => tr('anySpecialInstructionsHint');
  String get orderSummaryLabel => tr('orderSummaryLabel');
  String get vehicleLabel => tr('vehicleLabel');
  String get totalSummaryLabel => tr('totalSummaryLabel');
  String get confirmRentalLabel => tr('confirmRentalLabel');
  String get selectDatesToContinue => tr('selectDatesToContinue');
  String get proceedToCheckout => tr('proceedToCheckout');
  String get noListingsYetTitle => tr('noListingsYetTitle');
  String get postSomethingToStartSelling => tr('postSomethingToStartSelling');
  String get purchaseLabel => tr('purchaseLabel');
  String get titleIsRequiredError => tr('titleIsRequiredError');
  String get priceMustBeNumberError => tr('priceMustBeNumberError');
  String get enterValidPricePrefix => tr('enterValidPricePrefix');
  String get updatedExclaim => tr('updatedExclaim');
  String get postedExclaim => tr('postedExclaim');
  String get egIphone14Pro => tr('egIphone14Pro');
  String get egRemovableCanopy => tr('egRemovableCanopy');
  String get egBkk1PhnomPenh => tr('egBkk1PhnomPenh');
  String get saleTypeLabel => tr('saleTypeLabel');
  String get bothTypeLabel => tr('bothTypeLabel');
  String get draftStatusLabel => tr('draftStatusLabel');
  String get pausedStatusLabel => tr('pausedStatusLabel');
  String get soldStatusLabel => tr('soldStatusLabel');
  String get postListingBtn => tr('postListingBtn');
  String get buyingTab => tr('buyingTab');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'km', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
