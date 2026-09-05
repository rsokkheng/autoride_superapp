import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
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
      'pickup': 'Pickup',
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
      'reload': 'Reload',
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
      'completedAt2': 'Completed At (ម៉ោងបញ្ចប់): ',
      'copy': 'Copy',
      'couldNotLoadDelivery': 'Could not load delivery',
      'deliveryFee2': 'Delivery Fee (តម្លៃសេវាដឹក): ',
      'howWasYourDeliveryExperience': 'How was your delivery experience?',
      'keepOrder': 'Keep Order',
      'leaveACommentOptional': 'Leave a comment (optional)',
      'packageAmount2': 'Package Amount (តម្លៃទំនិញ): ',
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
      'driverFound': '🚗 Driver found!',
      'yourDriverIsAlmostHere': '🚗 Your driver is almost here',
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
      'pickup2': '📍 Pickup',
      // ── delivery_screen screen ──
      'n1Bedroom': '1 Bedroom',
      'n10KgAndAbove': '10 kg and above',
      'n2Bedrooms': '2 Bedrooms',
      'n210Kg': '2 – 10 kg',
      'n3Bedrooms': '3+ Bedrooms',
      'baseFee': 'Base fee',
      'bike': 'Bike —ម៉ូតូ',
      'buildingHasAWorkingElevator': 'Building has a working elevator',
      'car': 'Car — ឡាន',
      'cashOnDeliveryCod': 'Cash on delivery (COD)',
      'commercialOfficeMoving': 'Commercial / office moving',
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
      'recipPh': 'Recip. Ph.',
      'relocateHomeOffice': 'Relocate home/office',
      'residentialMoving': 'Residential moving',
      'scheduled': 'Scheduled',
      'searchLocation': 'Search location…',
      'sendPackages': 'Send packages',
      'senderPh': 'Sender Ph.',
      'serviceOption': 'Service Option',
      'small': 'Small',
      'smallSpace': 'Small space',
      'standardDeliverySpeed': 'Standard delivery speed',
      'standardMovingService': 'Standard moving service',
      'studio1Room': 'Studio / 1 Room',
      'tukTuk': 'Tuk Tuk — តុកតុក',
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
      'cancel2000Fee': 'Cancel (2,000 ៛ fee)',
      'cannotCancelARideIn': 'Cannot cancel a ride in progress.',
      'changedMyMind': 'Changed my mind',
      'driverAssignedConnecting': 'Driver assigned — connecting...',
      'driverHasArrivedA2': 'Driver has arrived — a 2,000 ៛ fee applies.',
      'driverHasArrived': 'Driver has arrived!',
      'driverIsTakingTooLong': 'Driver is taking too long',
      'emergencyCameUp': 'Emergency came up',
      'findingDriver': 'Finding driver...',
      'findingYourDriver': 'Finding your driver...',
      'foundAnotherRide': 'Found another ride',
      'iMOnMyWay': 'I\'m on my way!\n',
      'lookingForANearbyDriver': 'Looking for a nearby driver…',
      'myRotehTrip': 'My ROTEH Trip',
      'noDriverWasAvailableFor': 'No driver was available for this ride. Please try booking again.',
      'other': 'Other',
      'pleaseCheckYourBelongingsBefore': 'Please check your belongings before getting off the Tuk Tuk.',
      'pleaseTellUsWhyYou': 'Please tell us why you\'re cancelling.',
      'share': 'Share',
      'sharing': 'Sharing',
      'thisRideCannotBeCancelled': 'This ride cannot be cancelled.',
      'thisRideWasCancelled': 'This ride was cancelled.',
      'trackMyRotehTripLive': 'Track my ROTEH trip live 🚗\n',
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
      'phnomPenhInternationalAirport': 'Phnom Penh International Airport',
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
      'newRental': '🚗 NEW RENTAL',
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
      'thisWillAlertEmergencyServices': 'This will alert emergency services and notify AutoRide operations team with your location.',
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
      'passengerOnBoardStartTrip': '🚗  Passenger On Board — Start Trip',
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
      'afterDriverAccepts0to2': 'After driver accepts (0–2 min)',
      'gracePeriodDetail': 'You have a 2-minute grace period after the driver accepts to cancel for free.',
      'afterDriverAccepts2to5': 'After driver accepts (2–5 min)',
      'fee2000Riel': '2,000 ៛ fee',
      'smallCancelFeeDetail': 'A small cancellation fee applies if you cancel 2–5 minutes after the driver accepts.',
      'afterDriverAccepts5plus': 'After driver accepts (5+ min)',
      'fee5000Riel': '5,000 ៛ fee',
      'higherFeeDetail': 'If you cancel more than 5 minutes after acceptance, a higher fee applies.',
      'afterDriverArrives': 'After driver arrives',
      'fee10000Riel': '10,000 ៛ fee',
      'highestFeeDetail': 'Cancelling after the driver arrives at your pickup location incurs the highest fee.',
      // ── car_rental_screen ──
      'durMonth1': '1 Month',
      'durMonth2': '2 Months',
      'durMonth3': '3 Months',
      'durMonth6': '6 Months',
      'durYear1': '1 Year',
      'durYear2': '2 Years',
      'pickUpLabel': 'Pick Up',
      'collectCarMyself': "I'll collect the car myself",
      'deliverCarToAddress': 'Deliver the car to my address',
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
      'hasAutorideAccountLabel': 'Has AutoRide account',
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
      'autoRideWalletLabel': 'AutoRide Wallet',
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
      'faq5Q': 'Where does AutoRide operate?',
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
      'bookRideSub': 'ឥឡូវ ឬ កក់ទុកមុន',
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
      'bookNow': 'កក់ឥឡូវ',
      'scheduleRide': 'កក់ទុកមុន',
      'scheduleForLater': 'កក់ទុកសម្រាប់ពេលក្រោយ',
      'sendNow': 'ផ្ញើឥឡូវ',
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
      'busy': 'រវល់',
      'full': 'ពេញ',
      'chooseRide': 'ជ្រើសរើសការធ្វើដំណើររបស់អ្នក',
      'promoCode': 'បន្ថែមលេខកូដផ្សព្វផ្សាយ',
      'scheduleDelivery': 'កំណត់ពេលដឹក',
      'packageDetails': 'ព័ត៌មានលំអិតអំពីកញ្ចប់',
      'packageSize': 'ទំហំកញ្ចប់',
      'sendAnything': 'ផ្ញើ\nទៅណាក៏បាន!',
      'avgDelivery': 'ការដឹកជញ្ជូនជាមធ្យម: ២៥ នាទី',
      'incomingRequest': 'ការស្នើសុំចូល',
      'acceptRide': 'ទទួលដឹក',
      'decline': 'បដិសេធ',
      'todayPerformance': 'ការដឹកថ្ងៃនេះ',
      'recentTripsDriver': 'ដំណើរថ្មីៗ',
      'dailyBreakdown': 'ការបែងចែកប្រចាំថ្ងៃ',
      'withdrawEarnings': 'ដកប្រាក់ចំណូល',
      'evCarsAvailable': 'យានជំនិះអគ្គិសនី\nមានឥឡូវ!',
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
      'orderPlaced': 'បញ្ជាទិញជោគជ័យ!',
      'purchaseRequestSent': 'សំណើទិញរបស់អ្នកត្រូវបានបញ្ជូន',
      'done': 'រួចរាល់',
      'purchaseProduct': 'ទិញផលិតផល',
      'couponCode': 'កូដបញ្ចុះតម្លៃ',
      'phoneNumber': 'លេខទូរស័ព្ទ',
      'confirmInformation': 'បញ្ជាក់ព័ត៌មាន',
      'verifyAddressesNote': 'សូមផ្ទៀងផ្ទាត់អាសយដ្ឋាន និងព័ត៌មានទំនាក់ទំនងទាំងអស់មុននឹង'
          'បន្ត។ អ្នកលក់នឹងទទួលបានការជូនដំណឹងនៅពេលការបញ្ជាទិញរបស់អ្នកបានបញ្ជូន។',
      'purchaseNow': 'ទិញឥឡូវនេះ',
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
      'now': 'ឥឡូវនេះ',
      'confirmBooking': 'បញ្ជាក់ការកក់',
      'noDestinationNeeded': 'មិនចាំបាច់មានទីតាំង — សូមប្រាប់អ្នកបើកបរដោយផ្ទាល់',
      'whereToTitle': 'ទៅណា?',
      'noSavedPlaces': 'គ្មានទីតាំងដែលបានរក្សាទុក',
      'confirmDestination': 'បញ្ជាក់ទីតាំងទៅ',
      'whereToOptional': 'ទៅណា? (មិនតម្រូវ)',
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
      'yesSendNow': 'បាទ, ផ្ញើឥឡូវនេះ',
      'confirmMovingBooking': 'បញ្ជាក់ការកក់ដឹកជញ្ជូនរើផ្ទះ',
      'estimatedFare': 'តម្លៃប៉ាន់ស្មាន',
      'yesBookNow': 'បាទ, កក់ឥឡូវនេះ',
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
      'driverPhoneNotAvailable': 'លេខទូរស័ព្ទអ្នកបើកបរមិនទាន់មានទេ។',
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
      'registerOrJoinBusiness': 'ចុះឈ្មោះក្រុមហ៊ុនរបស់អ្នក ឬចូលរួមគណនីអាជីវកម្មដែលមានស្រាប់។',
      'enterInviteCode': 'បញ្ចូលកូដអញ្ជើញដែលអ្នកគ្រប់គ្រងក្រុមហ៊ុនរបស់អ្នកបានផ្ដល់ឲ្យ។',
      'fillSampleData': 'បំពេញទិន្នន័យគំរូ',
      'leaveBusinessQuestion': 'ចាកចេញពីអាជីវកម្ម?',
      'loseBusinessAccess': 'អ្នកនឹងលែងអាចប្រើមុខងារអាជីវកម្ម',
      'leave': 'ចាកចេញ',
      'edit': 'កែសម្រួល',
      'active': 'សកម្ម',
      'removeMemberQuestion': 'លុបសមាជិកនេះ?',
      'remove': 'លុប',
      'noMembersYet': 'មិនទាន់មានសមាជិកទេ។',
      'noBusinessTripsYet': 'មិនទាន់មានដំណើរអាជីវកម្មទេ។',
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
      'withdrawalsAdmin': 'ការដកប្រាក់',
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
      'openTickets': 'សំណើមិនទាន់ដោះស្រាយ',
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
      'payFullAmountNow': 'ទូទាត់ប្រាក់ពេញឥឡូវនេះ',
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
      'moving': 'ដឹកជញ្ជូនផ្លាស់ប្តូរទីលំនៅ',
      'topUpRequired': 'តម្រូវឱ្យបញ្ចូលប្រាក់',
      'topUpNow': 'បញ្ចូលប្រាក់ឥឡូវនេះ',
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
      'wallet': 'កាបូបអេឡិចត្រូនិច',
      'rewards': 'រង្វាន់',
      'refer': 'ណែនាំ',
      // ── Delivery / moving summary screens ──
      'pickup': 'ទីតាំងយក',
      'phone': 'លេខទូរស័ព្ទ',
      'package': 'ទំនិញ',
      'movingCompleted': 'ការផ្លាស់ទីបានបញ្ចប់!',
      'deliveryDetails': 'ព័ត៌មានលម្អិតការដឹកជញ្ជូន',
      'movingDetails': 'ព័ត៌មានលម្អិតការផ្លាស់ទី',
      'orderInfo': 'ព័ត៌មានការបញ្ជាទិញ',
      'jobInfo': 'ព័ត៌មានការងារ',
      'paymentSummary': 'សេចក្តីសង្ខេបការទូទាត់',
      'movingFee': 'តម្លៃសេវាផ្លាស់ទី',
      'paidBy': 'បង់ដោយ',
      'youRated': 'អ្នកបានផ្តល់ចំណាត់ថ្នាក់',
      'backToHome': 'ត្រឡប់ទៅទំព័រដើម',
      'backToDashboard': 'ត្រឡប់ទៅផ្ទាំងគ្រប់គ្រង',
      'updatingReceipt': 'កំពុងធ្វើបច្ចុប្បន្នភាពបង្កាន់ដៃ…',
      'updatingSummary': 'កំពុងធ្វើបច្ចុប្បន្នភាពសង្ខេប…',
      'couldNotRefresh': 'មិនអាចធ្វើបច្ចុប្បន្នភាពបាន។ កំពុងបង្ហាញព័ត៌មានដែលបានរក្សាទុក។',
      'platformFee': 'ថ្លៃវេទិកា',
      'netDriverFee': 'ចំណូលសុទ្ធអ្នកបញ្ជូន',
      'driverFee': 'ថ្លៃអ្នកបញ្ជូន',
      'beforePlatformFee': 'មុនកាត់ថ្លៃវេទិកា',
      'collectFromRecipient': 'ប្រមូលពីអ្នកទទួល',
      'collectPackageAmount': 'ប្រមូលតម្លៃទំនិញ',
      'packageDeliveredSuccessfully': 'ទំនិញត្រូវបានដឹកជញ្ជូនដោយជោគជ័យ។',
      'movingJobDone': 'ល្អមែន — ការងារផ្លាស់ទីបានបញ្ចប់។',
      'onlinePay': 'បង់តាមអនឡាញ',

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
      'reload': 'Reload',
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
      'completedAt2': 'Completed At (ម៉ោងបញ្ចប់): ',
      'copy': 'Copy',
      'couldNotLoadDelivery': 'Could not load delivery',
      'deliveryFee2': 'Delivery Fee (តម្លៃសេវាដឹក): ',
      'howWasYourDeliveryExperience': 'How was your delivery experience?',
      'keepOrder': 'Keep Order',
      'leaveACommentOptional': 'Leave a comment (optional)',
      'packageAmount2': 'Package Amount (តម្លៃទំនិញ): ',
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
      'driverFound': '🚗 Driver found!',
      'yourDriverIsAlmostHere': '🚗 Your driver is almost here',
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
      'pickup2': '📍 Pickup',
      // ── delivery_screen screen ──
      'n1Bedroom': '1 Bedroom',
      'n10KgAndAbove': '10 kg and above',
      'n2Bedrooms': '2 Bedrooms',
      'n210Kg': '2 – 10 kg',
      'n3Bedrooms': '3+ Bedrooms',
      'baseFee': 'Base fee',
      'bike': 'Bike —ម៉ូតូ',
      'buildingHasAWorkingElevator': 'Building has a working elevator',
      'car': 'Car — ឡាន',
      'cashOnDeliveryCod': 'Cash on delivery (COD)',
      'commercialOfficeMoving': 'Commercial / office moving',
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
      'recipPh': 'Recip. Ph.',
      'relocateHomeOffice': 'Relocate home/office',
      'residentialMoving': 'Residential moving',
      'scheduled': 'Scheduled',
      'searchLocation': 'Search location…',
      'sendPackages': 'Send packages',
      'senderPh': 'Sender Ph.',
      'serviceOption': 'Service Option',
      'small': 'Small',
      'smallSpace': 'Small space',
      'standardDeliverySpeed': 'Standard delivery speed',
      'standardMovingService': 'Standard moving service',
      'studio1Room': 'Studio / 1 Room',
      'tukTuk': 'Tuk Tuk — តុកតុក',
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
      'cancel2000Fee': 'Cancel (2,000 ៛ fee)',
      'cannotCancelARideIn': 'Cannot cancel a ride in progress.',
      'changedMyMind': 'Changed my mind',
      'driverAssignedConnecting': 'Driver assigned — connecting...',
      'driverHasArrivedA2': 'Driver has arrived — a 2,000 ៛ fee applies.',
      'driverHasArrived': 'Driver has arrived!',
      'driverIsTakingTooLong': 'Driver is taking too long',
      'emergencyCameUp': 'Emergency came up',
      'findingDriver': 'Finding driver...',
      'findingYourDriver': 'Finding your driver...',
      'foundAnotherRide': 'Found another ride',
      'iMOnMyWay': 'I\'m on my way!\n',
      'lookingForANearbyDriver': 'Looking for a nearby driver…',
      'myRotehTrip': 'My ROTEH Trip',
      'noDriverWasAvailableFor': 'No driver was available for this ride. Please try booking again.',
      'other': 'Other',
      'pleaseCheckYourBelongingsBefore': 'Please check your belongings before getting off the Tuk Tuk.',
      'pleaseTellUsWhyYou': 'Please tell us why you\'re cancelling.',
      'share': 'Share',
      'sharing': 'Sharing',
      'thisRideCannotBeCancelled': 'This ride cannot be cancelled.',
      'thisRideWasCancelled': 'This ride was cancelled.',
      'trackMyRotehTripLive': 'Track my ROTEH trip live 🚗\n',
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
      'phnomPenhInternationalAirport': 'Phnom Penh International Airport',
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
      'newRental': '🚗 NEW RENTAL',
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
      'thisWillAlertEmergencyServices': 'This will alert emergency services and notify AutoRide operations team with your location.',
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
      'passengerOnBoardStartTrip': '🚗  Passenger On Board — Start Trip',
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
      'accessibilityTitle': 'ភាពងាយស្រួលប្រើប្រាស់',
      'save': 'រក្សាទុក',
      'accessibilitySettingsSaved': 'បានរក្សាទុកការកំណត់ភាពងាយស្រួលប្រើប្រាស់។',
      'saveSettings': 'រក្សាទុកការកំណត់',
      'visualSection': 'ចក្ខុវិស័យ',
      'audioAndSpeechSection': 'សំឡេង និងការនិយាយ',
      'interactionSection': 'អន្តរកម្ម',
      'largeText': 'អក្សរធំ',
      'largeTextSubtitle': 'បង្កើនទំហំអក្សរនៅទូទាំងកម្មវិធី',
      'highContrast': 'កម្រិតពណ៌ខ្ពស់',
      'highContrastSubtitle': 'បង្កើនភាពមើលឃើញច្បាស់ជាមួយពណ៌ខ្លាំង',
      'reduceMotion': 'កាត់បន្ថយចលនា',
      'reduceMotionSubtitle': 'កាត់បន្ថយចលនា និងបែបផែនផ្លាស់ប្តូរ',
      'screenReaderSupport': 'ការគាំទ្រកម្មវិធីអានអេក្រង់',
      'screenReaderSupportSubtitle': 'កែសម្រួលស្លាកសម្រាប់បច្ចេកវិទ្យាជំនួយ',
      'hapticFeedback': 'ការឆ្លើយតបញ័រ',
      'hapticFeedbackSubtitle': 'ញ័រនៅពេលមានអន្តរកម្មសំខាន់ៗ',
      'largeTouchTargets': 'ចំណុចប៉ះទំហំធំ',
      'largeTouchTargetsSubtitle': 'ប៊ូតុង និងតំបន់ប៉ះទំហំធំជាង',
      'wheelchairAccessibleVehicles': 'យានជំនិះសម្រាប់រទេះរុញ',
      'wheelchairAccessibleVehiclesSubtitle': 'បង្ហាញតែជម្រើសយានជំនិះងាយស្រួលប្រើប្រាស់',
      // ── airport_trip_screen ──
      'airportTransferTitle': 'ដឹកជញ្ជូនអាកាសយានដ្ឋាន',
      'toAirportTab': 'ទៅអាកាសយានដ្ឋាន',
      'fromAirportTab': 'ពីអាកាសយានដ្ឋាន',
      'freeWaitBannerMessage': 'រួមបញ្ចូលការរង់ចាំឥតគិតថ្លៃ ៦០ នាទី — យើងតាមដានជើងហោះហើររបស់អ្នក ហើយកែសម្រួលការមកទទួលដោយស្វ័យប្រវត្តិ។',
      'dropoffAirportLabel': 'អាកាសយានដ្ឋានចុះ',
      'pickupAirportLabel': 'អាកាសយានដ្ឋានទទួល',
      'pickupAddressLabel': 'អាសយដ្ឋានទទួល',
      'dropoffAddressLabel': 'អាសយដ្ឋានចុះ',
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
      'suvVanLabel': 'អេសយូវី/វ៉ាន់',
      'upTo6Pax': 'អតិបរមា ៦ អ្នកដំណើរ',
      'passengersAndLuggageLabel': 'អ្នកដំណើរ និងឥវ៉ាន់',
      'passengersLabel': 'អ្នកដំណើរ',
      'luggageBagsLabel': 'ថង់ឥវ៉ាន់',
      'enterAddressForFareEstimate': 'បញ្ចូលអាសយដ្ឋានរបស់អ្នកដើម្បីមើលការប៉ាន់ស្មានតម្លៃ។',
      'airportSurcharge': 'ថ្លៃបន្ថែមអាកាសយានដ្ឋាន',
      'luggageBagsCountLabel': 'ឥវ៉ាន់',
      'fixedPriceNoSurge': 'តម្លៃថេរ · គ្មានតម្លៃកើនឡើង',
      'bookTransferPrefix': 'កក់ការដឹកជញ្ជូន ·',
      'bookAirportTransfer': 'កក់ការដឹកជញ្ជូនអាកាសយានដ្ឋាន',
      'fillAddressFlightDetailsError': 'សូមបំពេញអាសយដ្ឋាន លេខជើងហោះហើរ និងម៉ោងជើងហោះហើររបស់អ្នក។',
      'airportFallback': 'អាកាសយានដ្ឋាន',
      // ── cancellation_policy_screen ──
      'cancellationPolicyTitle': 'គោលការណ៍លុបចោល',
      'feesGoToDriversNote': 'ថ្លៃសេវាទាំងនេះទៅដល់អ្នកបើកបររបស់ជាសំណងចំពោះពេលវេលារបស់ពួកគេ។',
      'contactSupport': 'ទាក់ទងផ្នែកជំនួយ',
      'beforeDriverAccepts': 'មុនពេលអ្នកបើកបរទទួលយក',
      'freeCancellation': 'លុបចោលដោយឥតគិតថ្លៃ',
      'freeCancelBeforeAcceptDetail': 'អ្នកអាចលុបចោលបានគ្រប់ពេលមុនពេលអ្នកបើកបរទទួលយកការធ្វើដំណើររបស់អ្នកដោយឥតគិតថ្លៃ។',
      'afterDriverAccepts0to2': 'បន្ទាប់ពីអ្នកបើកបរទទួលយក (០–២ នាទី)',
      'gracePeriodDetail': 'អ្នកមានរយៈពេល ២ នាទីបន្ទាប់ពីអ្នកបើកបរទទួលយកដើម្បីលុបចោលដោយឥតគិតថ្លៃ។',
      'afterDriverAccepts2to5': 'បន្ទាប់ពីអ្នកបើកបរទទួលយក (២–៥ នាទី)',
      'fee2000Riel': 'ថ្លៃសេវា ២.០០០ រៀល',
      'smallCancelFeeDetail': 'ថ្លៃលុបចោលតូចមួយត្រូវបានគិតប្រសិនបើអ្នកលុបចោលក្នុងរយៈពេល ២–៥ នាទីបន្ទាប់ពីអ្នកបើកបរទទួលយក។',
      'afterDriverAccepts5plus': 'បន្ទាប់ពីអ្នកបើកបរទទួលយក (លើសពី ៥ នាទី)',
      'fee5000Riel': 'ថ្លៃសេវា ៥.០០០ រៀល',
      'higherFeeDetail': 'ប្រសិនបើអ្នកលុបចោលលើសពី ៥ នាទីបន្ទាប់ពីទទួលយក ថ្លៃខ្ពស់ជាងនេះនឹងត្រូវអនុវត្ត។',
      'afterDriverArrives': 'បន្ទាប់ពីអ្នកបើកបរមកដល់',
      'fee10000Riel': 'ថ្លៃសេវា ១០.០០០ រៀល',
      'highestFeeDetail': 'ការលុបចោលបន្ទាប់ពីអ្នកបើកបរមកដល់ទីតាំងទទួលរបស់អ្នកនឹងធ្វើឲ្យអ្នកត្រូវបង់ថ្លៃខ្ពស់បំផុត។',
      // ── car_rental_screen ──
      'durMonth1': '១ ខែ',
      'durMonth2': '២ ខែ',
      'durMonth3': '៣ ខែ',
      'durMonth6': '៦ ខែ',
      'durYear1': '១ ឆ្នាំ',
      'durYear2': '២ ឆ្នាំ',
      'pickUpLabel': 'ទទួលដោយខ្លួនឯង',
      'collectCarMyself': 'ខ្ញុំនឹងទៅយករថយន្តដោយខ្លួនឯង',
      'deliverCarToAddress': 'ដឹកជញ្ជូនរថយន្តមកកាន់អាសយដ្ឋានរបស់ខ្ញុំ',
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
      'failedToApplyCoupon': 'មិនអាចអនុវត្តគូប៉ុងបានទេ។',
      'bookedHashPrefix': 'បានកក់ #',
      'datesLabel': 'កាលបរិច្ឆេទ',
      'dailyRateLabel': 'អត្រាប្រចាំថ្ងៃ',
      'renterLabel': 'អ្នកជួល',
      'selectVehicleBeforeBooking': 'សូមជ្រើសរើសយានជំនិះមុននឹងកក់។',
      'setDeliveryLocationError': 'សូមកំណត់ទីតាំងដឹកជញ្ជូន។',
      'enterNamePhoneError': 'សូមបញ្ចូលឈ្មោះ និងលេខទូរស័ព្ទរបស់អ្នក។',
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
      'bookingSummaryLabel': 'សេចក្តីសង្ខេបការកក់',
      'discountLabel': 'ការបញ្ចុះតម្លៃ',
      'bookNowLabel': 'កក់ឥឡូវនេះ',
      'selectAVehicleLabel': 'ជ្រើសរើសយានជំនិះ',
      'rentDashPrefix': 'ជួល —',
      'failedToLoadVehicles': 'មិនអាចផ្ទុកយានជំនិះបានទេ',
      'noVehicleAvailableForRent': 'មិនមានយានជំនិះសម្រាប់ជួលទេ។',
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
      'nearbyChargingStationsTitle': 'ស្ថានីយ៍សាកបំពងនៅជិត',
      'availableSuffix': 'នៅទំនេរ',
      // ── edit_profile_screen ──
      'takeAPhoto': 'ថតរូបថ្មី',
      'couldNotUpdatePhotoPrefix': 'មិនអាចផ្លាស់ប្តូររូបភាពបានទេ៖',
      'couldNotUpdatePhotoTryAgain': 'មិនអាចផ្លាស់ប្តូររូបភាពបានទេ។ សូមព្យាយាមម្តងទៀត។',
      'profileUpdatedSuccess': 'ព័ត៌មានប្រវត្តិរូបត្រូវបានធ្វើបច្ចុប្បន្នភាពដោយជោគជ័យ!',
      'tapPhotoToChange': 'ចុចរូបភាពដើម្បីផ្លាស់ប្តូរ',
      'otpRequiredBadge': 'ត្រូវការលេខកូដ OTP',
      'changingPhoneRequiresOtp': 'ការផ្លាស់ប្តូរលេខទូរស័ព្ទរបស់អ្នកតម្រូវឲ្យផ្ទៀងផ្ទាត់ដោយ OTP។',
      'enterSixDigitCode': 'សូមបញ្ចូលកូដ ៦ខ្ទង់។',
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
      'createFamilyGroupTitle': 'បង្កើតក្រុមគ្រួសារ',
      'familyGroupDescription': 'កក់ការធ្វើដំណើរជំនួសសមាជិកគ្រួសារ។ ពួកគេមិនចាំបាច់មានកម្មវិធីទេ — គ្រាន់តែលេខទូរស័ព្ទប៉ុណ្ណោះ។',
      'groupNameHint': 'ឈ្មោះក្រុម (ឧ. គ្រួសារសុខហេង)',
      'createGroup': 'បង្កើតក្រុម',
      'membersLabel': 'សមាជិក',
      'add': 'បន្ថែម',
      'noMembersYetMsg': 'មិនទាន់មានសមាជិកទេ។ បន្ថែមសមាជិកគ្រួសារដើម្បីកក់ការធ្វើដំណើរឲ្យពួកគេ។',
      'membersCountSuffix': 'សមាជិក',
      'fromFamilyGroupQuestionSuffix': 'ចេញពីក្រុមគ្រួសារឬ?',
      'hasAutorideAccountLabel': 'មានគណនី AutoRide',
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
      'redeemPointsTitle': 'ដោះពិន្ទុ',
      'redeem500ptsQuestion': 'ដោះពិន្ទុ ៥០០ សម្រាប់ការបញ្ចុះតម្លៃ ៥.០០០ ៛ លើការធ្វើដំណើរបន្ទាប់របស់អ្នក?',
      'pts500Redeemed': 'បានដោះពិន្ទុ ៥០០! ការបញ្ចុះតម្លៃត្រូវបានអនុវត្តទៅលើការធ្វើដំណើរបន្ទាប់។',
      'redeem500pts': 'ដោះពិន្ទុ ៥០០',
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
      'ptsPerReferral500': '៥០០ ពិន្ទុក្នុងមួយការណែនាំ',
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
      'enterExpiryMMYY': 'សូមបញ្ចូលថ្ងៃផុតកំណត់ជា MM/YY',
      'cardExpiredError': 'កាតនេះបានផុតកំណត់',
      'enterValidCvv': 'សូមបញ្ចូល CVV ត្រឹមត្រូវ',
      'expiresPrefix': 'ផុតកំណត់',
      'minOrderPrefix': 'កម្រិតអប្បបរមា',
      'enterAccountPhoneNumber': 'សូមបញ្ចូលលេខទូរស័ព្ទគណនី',
      // ── promo_screen ──
      'promosTabLabel': 'ប្រូម៉ូសិន',
      'storeTabLabel': 'ហាង',
      'myVouchersTabLabel': 'គូប៉ុងរបស់ខ្ញុំ',
      'enterPromoCodeTitle': 'បញ្ចូលកូដប្រូម៉ូសិន',
      'codeHintExample': 'ឧ. ROTEH15',
      'invalidExpiredPromoCode': 'កូដប្រូម៉ូសិនមិនត្រឹមត្រូវ ឬបានផុតកំណត់។',
      'couldNotValidateCode': 'មិនអាចផ្ទៀងផ្ទាត់កូដបានទេ។ សូមព្យាយាមម្តងទៀត។',
      'discountAppliedFallback': 'ការបញ្ចុះតម្លៃត្រូវបានអនុវត្ត',
      'offSuffix': 'បញ្ចុះតម្លៃ',
      'promoAppliedDashPrefix': 'ប្រូម៉ូសិន',
      'appliedDashSuffix': 'ត្រូវបានអនុវត្ត —',
      'codeCopiedPrefix': 'កូដ',
      'copiedSuffix': 'បានចម្លង!',
      'availableVouchersTitle': 'គូប៉ុងដែលមាន',
      'noExpiry': 'គ្មានកាលបរិច្ឆេទផុតកំណត់',
      'promo1Title': 'បញ្ចុះតម្លៃ ៥០% លើការធ្វើដំណើរដំបូង',
      'promo1Desc': 'សម្រាប់តែអ្នកប្រើប្រាស់ថ្មីប៉ុណ្ណោះ។ បញ្ចុះតម្លៃអតិបរមា ៥ដុល្លារ។',
      'promo2Title': 'បញ្ចុះតម្លៃ ១៥% លើការធ្វើដំណើរណាមួយ',
      'promo2Desc': 'ប្រើប្រាស់បានគ្រប់ពេល។ ថ្លៃអប្បបរមា ៣ដុល្លារ។',
      'promo3Title': 'បញ្ចុះតម្លៃ ១ដុល្លារ លើការដឹកជញ្ជូន',
      'promo3Desc': 'អាចប្រើបានចំពោះការដឹកជញ្ជូនធម្មតា និងថ្ងៃតែមួយ។',
      'promo4Title': 'ផែនទីស្ថានីយ៍សាកបំពងឥតគិតថ្លៃ',
      'promo4Desc': 'ទទួលបានទិសដៅស្ថានីយ៍កម្រិតខ្ពស់ដោយឥតគិតថ្លៃ។',
      'promo5Title': 'បញ្ចុះតម្លៃ ២០% ថ្ងៃចុងសប្តាហ៍',
      'promo5Desc': 'ប្រើប្រាស់បានចាប់ពីថ្ងៃសៅរ៍ដល់អាទិត្យ។ បញ្ចុះតម្លៃអតិបរមា ៨ដុល្លារ។',
      'freeLabel': 'ឥតគិតថ្លៃ',
      // ── qr_payment_screen ──
      'qrPaymentTitle': 'ការទូទាត់តាម QR',
      'myQrTabLabel': 'QR របស់ខ្ញុំ',
      'enterValidAmountKhr': 'សូមបញ្ចូលចំនួនទឹកប្រាក់ត្រឹមត្រូវជារៀល។',
      'generateQrToReceive': 'បង្កើត QR ដើម្បីទទួលប្រាក់',
      'enterAmountShareQr': 'បញ្ចូលចំនួនទឹកប្រាក់ ហើយចែករំលែក QR ជាមួយអ្នកបង់ប្រាក់។',
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
      'feedbackHelpsImprove': 'មតិយោបល់របស់អ្នកជួយពួកយើងកែលម្អបទពិសោធន៍សម្រាប់អ្នកគ្រប់គ្នា។',
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
      'giveFriendsDiscountDesc': 'ផ្តល់ការបញ្ចុះតម្លៃ ១០.០០០ ៛ ដល់មិត្តភក្តិសម្រាប់ការធ្វើដំណើរដំបូងរបស់ពួកគេ។\nអ្នកនឹងទទួលបាន ៥០០ ពិន្ទុសម្រាប់ការណែនាំម្នាក់ៗ។',
      'yourReferralCode': 'កូដណែនាំរបស់អ្នក',
      'shareWithFriends': 'ចែករំលែកជាមួយមិត្តភក្តិ',
      'friendsReferred': 'មិត្តភក្តិដែលបានណែនាំ',
      'pointsEarnedLabel': 'ពិន្ទុទទួលបាន',
      'friendsWhoJoined': 'មិត្តភក្តិដែលបានចូលរួម',
      'joinedPrefix': 'បានចូលរួម',
      'joinRotehWithCodePrefix': 'ចូលរួម ROTEH ជាមួយកូដរបស់ខ្ញុំ៖',
      'get10000OffFirstRideSuffix': 'ហើយទទួលបានការបញ្ចុះតម្លៃ ១០.០០០ ៛ លើការធ្វើដំណើរដំបូងរបស់អ្នក!',
      'downloadRotehNow': 'ទាញយក ROTEH ឥឡូវនេះ។',
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
      'shareLinkTrackDesc': 'ចែករំលែកតំណភ្ជាប់នេះ ដើម្បីឲ្យអ្នកដទៃអាចតាមដានការធ្វើដំណើររបស់អ្នកតាមពេលវេលាជាក់ស្តែង។',
      'sosWillBeSentNoContacts': 'សារ SOS នឹងត្រូវបានផ្ញើភ្លាមៗ។ មិនទាន់មានទំនាក់ទំនងបន្ទាន់ត្រូវបានបន្ថែមទេ។',
      'sosWillBeSentToContactsPrefix': 'SOS នឹងត្រូវបានផ្ញើទៅកាន់',
      'emergencyContactsImmediatelySuffix': 'ទំនាក់ទំនងបន្ទាន់ភ្លាមៗ។',
      'harassmentTag': 'ការយាយី',
      'unsafeDrivingTitleTag': 'បើកបរគ្មានសុវត្ថិភាព',
      'overchargeTag': 'គិតថ្លៃលើស',
      'otherTag': 'ផ្សេងទៀត',
      'describeWhatHappenedHint': 'ពិពណ៌នាអំពីអ្វីដែលបានកើតឡើង…',
      'submitReportBtn': 'ដាក់ស្នើរបាយការណ៍',
      'incidentReportedThanks': 'ឧប្បត្តិហេតុត្រូវបានរាយការណ៍។ សូមអរគុណ។',
      'addEmergencyContactTitle': 'បន្ថែមទំនាក់ទំនងបន្ទាន់',
      'relationshipHintExample': 'ទំនាក់ទំនង (ឧ. ម្តាយ)',
      'notifyOnSos': 'ជូនដំណឹងពេលមាន SOS',
      'notifyOnTripShare': 'ជូនដំណឹងពេលចែករំលែកការធ្វើដំណើរ',
      'addContactBtn': 'បន្ថែមទំនាក់ទំនង',
      'contactAddedExcl': 'បានបន្ថែមទំនាក់ទំនង!',
      'editContactTitle': 'កែសម្រួលទំនាក់ទំនង',
      'contactUpdatedExcl': 'ទំនាក់ទំនងត្រូវបានធ្វើបច្ចុប្បន្នភាព!',
      'removeContactQuestion': 'លុបទំនាក់ទំនងឬ?',
      'willBeRemovedFromContactsSuffix': 'នឹងត្រូវបានលុបចេញពីទំនាក់ទំនងបន្ទាន់របស់អ្នក។',
      'contactRemoved': 'ទំនាក់ទំនងត្រូវបានលុប',
      'sosTagLabel': 'SOS',
      'tripShareTagLabel': 'ចែករំលែកការធ្វើដំណើរ',
      'fakeCallChooseDelayTitle': 'ការហៅក្លែងក្លាយ — ជ្រើសរើសពេលរង់ចាំ',
      'phoneWillRingDesc': 'ទូរស័ព្ទរបស់អ្នកនឹងរោទ៍បន្ទាប់ពីពេលរង់ចាំដែលបានជ្រើសរើស។',
      'nowSecLabel': 'ឥឡូវនេះ (៥ វិនាទី)',
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
      'saveHomeWorkDesc': 'រក្សាទុកផ្ទះ ការងារ ឬកន្លែងសំណព្វ\nសម្រាប់ការកក់លឿនជាងមុន។',
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
      'rideCancelledPeriod': 'ការធ្វើដំណើរត្រូវបានលុបចោល។',
      'noUpcomingRides': 'គ្មានការធ្វើដំណើរនាពេលខាងមុខទេ',
      'scheduleRideToSeeHere': 'កំណត់ពេលការធ្វើដំណើរដើម្បីមើលវានៅទីនេះ។',
      'modifyComingSoon': 'ការកែប្រែនឹងមកដល់ឆាប់ៗនេះ។',
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
      'benefitsContinueDesc': 'អត្ថប្រយោជន៍បន្តរហូតដល់គម្រោងរបស់អ្នកផុតកំណត់។ ការបន្តដោយស្វ័យប្រវត្តិនឹងត្រូវបានបិទ។',
      'cancelPlanBtn': 'លុបចោលគម្រោង',
      'autoRideWalletLabel': 'កាបូប AutoRide',
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
      'noBillingHistoryYet': 'មិនទាន់មានប្រវត្តិការទូទាត់ទេ។',
      'newSubscriptionLabel': 'ការជាវថ្មី',
      'renewalLabel': 'ការបន្ត',
      'cancellationLabel': 'ការលុបចោល',
      // ── support_screen ──
      'myTicketsTab': 'សំបុត្ររបស់ខ្ញុំ',
      'faqTab': 'សំណួរញឹកញាប់',
      'noSupportTickets': 'គ្មានសំបុត្រជំនួយទេ',
      'tapPlusToCreateTicket': 'ចុច + ដើម្បីបង្កើតសំណើជំនួយថ្មី។',
      'openParenPrefix': 'កំពុងបើក',
      'resolvedParenPrefix': 'បានដោះស្រាយ',
      'repliesCountLabel': 'ការឆ្លើយតប',
      'dAgoSuffix': 'ថ្ងៃមុន',
      'hAgoSuffix': 'ម៉ោងមុន',
      'mAgoSuffix': 'នាទីមុន',
      'needHelpTitle': 'ត្រូវការជំនួយ?',
      'cantFindAnswerDesc': 'រកមិនឃើញចម្លើយរបស់អ្នក? បើកសំបុត្រថ្មី។',
      'subjectAndMessageRequired': 'ត្រូវការប្រធានបទ និងសារ',
      'newSupportTicketTitle': 'សំបុត្រជំនួយថ្មី',
      'priorityColonLabel': 'អាទិភាព៖',
      'highPriority': 'ខ្ពស់',
      'urgentPriority': 'បន្ទាន់',
      'subjectLabel': 'ប្រធានបទ',
      'describeYourIssueLabel': 'ពិពណ៌នាបញ្ហារបស់អ្នក',
      'submitTicketBtn': 'ដាក់ស្នើសំបុត្រ',
      'noRepliesYetDesc': 'មិនទាន់មានការឆ្លើយតបទេ។ យើងនឹងឆ្លើយតបក្នុងរយៈពេល ២៤ម៉ោង។',
      'writeAReplyHint': 'សរសេរការឆ្លើយតប…',
      'supportTeamLabel': 'ក្រុមជំនួយ',
      'faq1Q': 'តើខ្ញុំកក់ការធ្វើដំណើរដោយរបៀបណា?',
      'faq1A': 'បើកកម្មវិធី ចុចកក់ការធ្វើដំណើរ កំណត់ទីតាំងទទួល និងទិសដៅ រួចបញ្ជាក់។',
      'faq2Q': 'តើខ្ញុំលុបចោលការធ្វើដំណើរដោយរបៀបណា?',
      'faq2A': 'អំឡុងពេលកក់ អ្នកអាចចុចលុបចោលនៅលើអេក្រង់តាមដាន។ ថ្លៃលុបចោលអាចត្រូវអនុវត្តបន្ទាប់ពីអ្នកបើកបរកំពុងធ្វើដំណើរមកជួប។',
      'faq3Q': 'តើការទូទាត់ដំណើរការយ៉ាងណា?',
      'faq3A': 'យើងទទួលសាច់ប្រាក់ និងកាបូបអេឡិចត្រូនិក។ ជ្រើសរើសវិធីរបស់អ្នកមុនពេលបញ្ជាក់ការកក់។',
      'faq4Q': 'តើខ្ញុំរាយការណ៍បញ្ហាដោយរបៀបណា?',
      'faq4A': 'បង្កើតសំបុត្រជំនួយដោយចុចប៊ូតុង + ខាងលើ។ ក្រុមរបស់យើងឆ្លើយតបក្នុងរយៈពេល ២៤ម៉ោង។',
      'faq5Q': 'តើ AutoRide ដំណើរការនៅទីណា?',
      'faq5A': 'បច្ចុប្បន្នមានសេវានៅទូទាំងភ្នំពេញ ប្រទេសកម្ពុជា។',
      'faq6Q': 'តើខ្ញុំក្លាយជាអ្នកបើកបរដោយរបៀបណា?',
      'faq6A': 'ចុះឈ្មោះជាមួយតួនាទី "អ្នកបើកបរ" បំពេញការផ្ទៀងផ្ទាត់ រួចចុះឈ្មោះយានជំនិះរបស់អ្នក។',
      'faq7Q': 'ចុះបើអ្នកបើកបរមិនមកទេ?',
      'faq7A': 'ប្រើប៊ូតុង SOS ឬទាក់ទងនៅលើអេក្រង់តាមដាន ឬលុបចោល ហើយកក់ម្តងទៀត។',
      // ── trip_history_screen ──
      'tripTitle': 'ការធ្វើដំណើរ',
      'spentLabel': 'បានចំណាយ',
      'noTripsFound': 'រកមិនឃើញការធ្វើដំណើរទេ',
      'byDayLabel': 'តាមថ្ងៃ',
      'filterTripsTitle': 'តម្រងការធ្វើដំណើរ',
      'resetLabel': 'កំណត់ឡើងវិញ',
      'applyFiltersBtn': 'អនុវត្តតម្រង',
      'allTripsLabel': 'ការធ្វើដំណើរទាំងអស់',
      'tipSuffix2': 'ទឹកតែ',
      'thisTripNoDestinationRebook': 'ការធ្វើដំណើរនេះគ្មានទិសដៅដើម្បីកក់ម្តងទៀត។',
      'bookAgainBtn': 'កក់ម្តងទៀត',
      'rateBtn': 'វាយតម្លៃ',
      // ── voucher_screen ──
      'vouchersTitle': 'គូប៉ុង',
      'voucherClaimedCheckMy': 'បានទទួលគូប៉ុង! ពិនិត្យមើលគូប៉ុងរបស់ខ្ញុំ។',
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
      'contactPerson': 'អ្នកទាក់ទង',
      'contactNameRequiredHint': 'ឈ្មោះអ្នកទាក់ទង *',
      'contactPhoneHint': 'លេខទូរស័ព្ទទាក់ទង',
      'billingEmailRequiredHint': 'អ៊ីមែលវិក័យប័ត្រ *',
      'billingCycle': 'វដ្តវិក័យប័ត្រ',
      'companyAddressHint': 'អាសយដ្ឋានក្រុមហ៊ុន',
      'taxIdLabel': 'លេខសម្គាល់ពន្ធ',
      'billingEmailLabel': 'អ៊ីមែលវិក័យប័ត្រ',
      'billingCycleLabel': 'វដ្តវិក័យប័ត្រ',
      'contactLabel': 'អ្នកទាក់ទង',
      'addressLabel': 'អាសយដ្ឋាន',
      'inviteCodeLabel': 'កូដអញ្ជើញ',
      'editAccount': 'កែសម្រួលគណនី',
      'editBusinessAccount': 'កែសម្រួលគណនីអាជីវកម្ម',
      'companyNameHint': 'ឈ្មោះក្រុមហ៊ុន',
      'billingEmailHint': 'អ៊ីមែលវិក័យប័ត្រ',
      'contactNameHint': 'ឈ្មោះអ្នកទាក់ទង',
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
      'biometricLogin': 'ចូលដោយប្រើម្រាមដៃ',
      // ── onboarding_screen ──
      'next': 'បន្ទាប់',
      'getStarted': 'ចាប់ផ្តើម',
      'onboardWelcomeTitle': 'សូមស្វាគមន៍មកកាន់ ROTEH',
      'onboardWelcomeSubtitle': 'សម្ព័ន្ធធិការធ្វើដំណើរឆ្លាតវៃរបស់អ្នកនៅកម្ពុជា។\nលឿន សុវត្ថិភាព និងតម្លៃសមរម្យនៅចុងម្រាមដៃរបស់អ្នក។',
      'onboardBookTitle': 'កក់ក្នុងរយៈពេលប៉ុន្មានវិនាទី',
      'onboardBookSubtitle': 'ជ្រើសរើសប្រភេទយានជំនិះរបស់អ្នក — រថយន្ត ម៉ូតូ ឬតុកតុក។\nទទួលបានការប៉ាន់ស្មានថ្លៃមុនពេលអ្នកបញ្ជាក់។',
      'onboardPaySubtitle': 'បង់ប្រាក់ជាសាច់ប្រាក់ ឬប្រើកាបូបលុយ ROTEH Pay។\nផ្ញើប្រាក់ទៅមិត្តភក្តិដោយប្រើកូដ QR។',
      'onboardRewardsTitle': 'ទទួលបានរង្វាន់',
      'onboardRewardsSubtitle': 'ប្រមូល ROTEH Points ក្នុងរាល់ដំណើរ។\nឡើងពីកម្រិតសំរឹទ្ធិទៅដល់ផ្លាទីន និងដោះសោអត្ថប្រយោជន៍ពិសេស។',
      // ── auth_service ──
      'phoneVerificationFailedMsg': 'ការផ្ទៀងផ្ទាត់លេខទូរស័ព្ទបានបរាជ័យ។',
      'couldNotObtainFirebaseToken': 'មិនអាចទទួលបានថូខិន Firebase ID បានទេ។',
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
      'buyNowLabel': 'ទិញឥឡូវនេះ',
      'rentNowLabel': 'ជួលឥឡូវនេះ',
      'searchLocationHint': 'ស្វែងរកទីតាំង…',
      'dragMapToSetLocation': 'អូសផែនទីដើម្បីកំណត់ទីតាំង',
      'setPickupHere': 'កំណត់ទីតាំងទទួលទីនេះ',
      'setDropoffHere': 'កំណត់ទីតាំងទុកទីនេះ',
      'pickUpShortLabel': 'មកយកដោយខ្លួនឯង',
      'deliverCarToMyAddress': 'ដឹកជញ្ជូនរថយន្តមកកាន់អាសយដ្ឋានរបស់ខ្ញុំ',
      'addItemTitle': 'បន្ថែមទំនិញ',
      'searchListingsHint': 'ស្វែងរកបញ្ជី…',
      'selectRentalDatesError': 'សូមជ្រើសរើសកាលបរិច្ឆេទចាប់ផ្ដើម និងបញ្ចប់ការជួល។',
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
      'titleIsRequiredError': 'ត្រូវការចំណងជើង។',
      'priceMustBeNumberError': 'តម្លៃត្រូវតែជាលេខ។',
      'enterValidPricePrefix': 'សូមបញ្ចូលតម្លៃត្រឹមត្រូវសម្រាប់',
      'updatedExclaim': 'បានធ្វើបច្ចុប្បន្នភាព!',
      'postedExclaim': 'បានផ្សាយ!',
      'egIphone14Pro': 'ឧ. iPhone 14 Pro',
      'egRemovableCanopy': 'ឧ. ដំបូលអាចដោះបាន',
      'egBkk1PhnomPenh': 'ឧ. BKK1, ភ្នំពេញ',
      'saleTypeLabel': 'លក់',
      'bothTypeLabel': 'ទាំងពីរ',
      'draftStatusLabel': 'ព្រាង',
      'pausedStatusLabel': 'ផ្អាក',
      'soldStatusLabel': 'លក់ហើយ',
      'postListingBtn': 'ផ្សាយបញ្ជី',
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
      'pickup': '取货地点',
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
      'reload': 'Reload',
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
      'completedAt2': 'Completed At (ម៉ោងបញ្ចប់): ',
      'copy': 'Copy',
      'couldNotLoadDelivery': 'Could not load delivery',
      'deliveryFee2': 'Delivery Fee (តម្លៃសេវាដឹក): ',
      'howWasYourDeliveryExperience': 'How was your delivery experience?',
      'keepOrder': 'Keep Order',
      'leaveACommentOptional': 'Leave a comment (optional)',
      'packageAmount2': 'Package Amount (តម្លៃទំនិញ): ',
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
      'driverFound': '🚗 Driver found!',
      'yourDriverIsAlmostHere': '🚗 Your driver is almost here',
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
      'pickup2': '📍 Pickup',
      // ── delivery_screen screen ──
      'n1Bedroom': '1 Bedroom',
      'n10KgAndAbove': '10 kg and above',
      'n2Bedrooms': '2 Bedrooms',
      'n210Kg': '2 – 10 kg',
      'n3Bedrooms': '3+ Bedrooms',
      'baseFee': 'Base fee',
      'bike': 'Bike —ម៉ូតូ',
      'buildingHasAWorkingElevator': 'Building has a working elevator',
      'car': 'Car — ឡាន',
      'cashOnDeliveryCod': 'Cash on delivery (COD)',
      'commercialOfficeMoving': 'Commercial / office moving',
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
      'recipPh': 'Recip. Ph.',
      'relocateHomeOffice': 'Relocate home/office',
      'residentialMoving': 'Residential moving',
      'scheduled': 'Scheduled',
      'searchLocation': 'Search location…',
      'sendPackages': 'Send packages',
      'senderPh': 'Sender Ph.',
      'serviceOption': 'Service Option',
      'small': 'Small',
      'smallSpace': 'Small space',
      'standardDeliverySpeed': 'Standard delivery speed',
      'standardMovingService': 'Standard moving service',
      'studio1Room': 'Studio / 1 Room',
      'tukTuk': 'Tuk Tuk — តុកតុក',
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
      'cancel2000Fee': 'Cancel (2,000 ៛ fee)',
      'cannotCancelARideIn': 'Cannot cancel a ride in progress.',
      'changedMyMind': 'Changed my mind',
      'driverAssignedConnecting': 'Driver assigned — connecting...',
      'driverHasArrivedA2': 'Driver has arrived — a 2,000 ៛ fee applies.',
      'driverHasArrived': 'Driver has arrived!',
      'driverIsTakingTooLong': 'Driver is taking too long',
      'emergencyCameUp': 'Emergency came up',
      'findingDriver': 'Finding driver...',
      'findingYourDriver': 'Finding your driver...',
      'foundAnotherRide': 'Found another ride',
      'iMOnMyWay': 'I\'m on my way!\n',
      'lookingForANearbyDriver': 'Looking for a nearby driver…',
      'myRotehTrip': 'My ROTEH Trip',
      'noDriverWasAvailableFor': 'No driver was available for this ride. Please try booking again.',
      'other': 'Other',
      'pleaseCheckYourBelongingsBefore': 'Please check your belongings before getting off the Tuk Tuk.',
      'pleaseTellUsWhyYou': 'Please tell us why you\'re cancelling.',
      'share': 'Share',
      'sharing': 'Sharing',
      'thisRideCannotBeCancelled': 'This ride cannot be cancelled.',
      'thisRideWasCancelled': 'This ride was cancelled.',
      'trackMyRotehTripLive': 'Track my ROTEH trip live 🚗\n',
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
      'phnomPenhInternationalAirport': 'Phnom Penh International Airport',
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
      'newRental': '🚗 NEW RENTAL',
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
      'thisWillAlertEmergencyServices': 'This will alert emergency services and notify AutoRide operations team with your location.',
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
      'passengerOnBoardStartTrip': '🚗  Passenger On Board — Start Trip',
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
      'afterDriverAccepts0to2': '司机接单后 (0–2分钟)',
      'gracePeriodDetail': '司机接单后有2分钟的免费取消宽限期。',
      'afterDriverAccepts2to5': '司机接单后 (2–5分钟)',
      'fee2000Riel': '2,000瑞尔 费用',
      'smallCancelFeeDetail': '如果您在司机接单后2–5分钟内取消，将收取少量取消费。',
      'afterDriverAccepts5plus': '司机接单后 (超过5分钟)',
      'fee5000Riel': '5,000瑞尔 费用',
      'higherFeeDetail': '如果您在接单超过5分钟后取消，将收取更高的费用。',
      'afterDriverArrives': '司机到达后',
      'fee10000Riel': '10,000瑞尔 费用',
      'highestFeeDetail': '在司机到达您的上车地点后取消将产生最高费用。',
      // ── car_rental_screen ──
      'durMonth1': '1个月',
      'durMonth2': '2个月',
      'durMonth3': '3个月',
      'durMonth6': '6个月',
      'durYear1': '1年',
      'durYear2': '2年',
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
      'hasAutorideAccountLabel': '拥有AutoRide账户',
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
      'ptsToPlatinumSuffix': '积分即可升至白金级',
      'ptsToGoldSuffix': '积分即可升至黄金级',
      'ptsToSilverSuffix': '积分即可升至白银级',
      'membershipTiersTitle': '会员等级',
      'currentBadge': '当前',
      'howToEarnTitle': '如何赚取积分',
      'pointsActivityTitle': '积分活动',
      'bronzeTier': '青铜',
      'silverTier': '白银',
      'goldTier': '黄金',
      'platinumTier': '白金',
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
      'emergencyContactsImmediatelySuffix': '位紧急联系人。',
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
      'rideCancelledPeriod': '行程已取消。',
      'noUpcomingRides': '暂无即将到来的行程',
      'scheduleRideToSeeHere': '预约行程后将显示在此处。',
      'modifyComingSoon': '修改功能即将推出。',
      'modifyBtn': '修改',
      'jan': '1月', 'feb': '2月', 'mar': '3月', 'apr': '4月',
      'may': '5月', 'jun': '6月', 'jul': '7月', 'aug': '8月',
      'sep': '9月', 'oct': '10月', 'nov': '11月', 'dec': '12月',
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
      'autoRideWalletLabel': 'AutoRide钱包',
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
      'openParenPrefix': '进行中',
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
      'faq5Q': 'AutoRide在哪些地区运营？',
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
  String get bankTransfer => tr('bankTransfer');
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
  String get afterDriverAccepts0to2 => tr('afterDriverAccepts0to2');
  String get gracePeriodDetail => tr('gracePeriodDetail');
  String get afterDriverAccepts2to5 => tr('afterDriverAccepts2to5');
  String get fee2000Riel => tr('fee2000Riel');
  String get smallCancelFeeDetail => tr('smallCancelFeeDetail');
  String get afterDriverAccepts5plus => tr('afterDriverAccepts5plus');
  String get fee5000Riel => tr('fee5000Riel');
  String get higherFeeDetail => tr('higherFeeDetail');
  String get afterDriverArrives => tr('afterDriverArrives');
  String get fee10000Riel => tr('fee10000Riel');
  String get highestFeeDetail => tr('highestFeeDetail');
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
