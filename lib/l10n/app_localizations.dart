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
      'copyright': 'ROTEH © 2026 — All rights reserved',
      'whoAreYou': 'Who are you?',
      'selectRole': 'Select your role to continue',
      'passenger': 'Passenger',
      'passengerSub': 'Book rides, order deliveries,\nbuy or rent vehicles',
      'driver': 'Driver',
      'driverSub': 'Accept ride requests, manage\ndeliveries & earn money',
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
      'evCarsAvailable': 'EV Cars Now\nAvailable!',
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
      'personsForCarrying': '0–5 persons for carrying',
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
    },
    'km': {
      'appName': 'រទេះ',
      'tagline': 'រទេះអេប',
      'copyright': 'ROTEH © ២០២៥ — រក្សាសិទ្ធិគ្រប់',
      'whoAreYou': 'អ្នកជានរណា?',
      'selectRole': 'ជ្រើសរើសតួនាទីដើម្បីបន្ត',
      'passenger': 'អ្នកដំណើរ',
      'passengerSub': 'កក់ការធ្វើដំណើរ, ញ៉ាំបញ្ជាដឹក\nទិញ ឬជួលយានយន្ត',
      'driver': 'អ្នកបើកបរ',
      'driverSub': 'ទទួលការស្នើសុំដំណើរ, គ្រប់គ្រង\nការដឹកជញ្ជូន & រកប្រាក់',
      'home': 'រទេះ',
      'charging': 'ប្តូរថ្ម',
      'chat': 'ការសន្ទនា',
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
      'evStationsSub': 'ទីតាំងប្តូរថ្មនៅជិតអ្នក',
      'safety': 'សុវត្ថិភាព',
      'payment': 'ការទូទាត់',
      'support': 'ជំនួយ',
      'recentTrips': 'ដំណើរថ្មីៗ',
      'seeAll': 'មើលទាំងអស់',
      'services': 'ប្រតិបត្តិការណ៍',
      'quickActions': 'សកម្មភាពរហ័ស',
      'whereAreYouGoing': 'ថ្ងៃនេះបងចង់ទៅណាដែរ?',
      'bookNow': 'កក់ឥឡូវ',
      'scheduleRide': 'កំណត់ពេលដំណើរ',
      'scheduleForLater': 'កំណត់ពេលជាក់លាក់',
      'sendNow': 'ផ្ញើឥឡូវ',
      'evChargingStations': 'ស្ថានីយ៍សាកថ្ម EV',
      'buy': 'ទិញ',
      'rent': 'ជួល',
      'trackTrip': 'តាមដានដំណើរ',
      'driverOnTheWay': 'អ្នកបើកបរកំពុងមក',
      'tripInProgress': 'ដំណើរកំពុងដំណើរ',
      'arrived': 'អ្នកបើកបរមកដល់ហើយ!',
      'paySecurely': 'ទូទាត់សុវត្ថិភាព',
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
      'helpSupport': 'ជំនួយ & ជំនួយ',
      'bankPayouts': 'ធនាគារ & ការទូទាត់',
      'documents': 'ឯកសារ',
      'navigate': 'រុករក',
      'available': 'មាន',
      'busy': 'រវល់',
      'full': 'ពេញ',
      'chooseRide': 'ជ្រើសរើសការធ្វើដំណើររបស់អ្នក',
      'promoCode': 'បន្ថែមលេខកូដផ្សព្វផ្សាយ',
      'scheduleDelivery': 'កំណត់ពេលដឹក',
      'packageDetails': 'ព័ត៌មានលំអិតអំពីកញ្ចប់',
      'packageSize': 'ទំហំកញ្ចប់',
      'sendAnything': 'ផ្ញើអ្វីៗ\nទៅណាក៏ដោយ!',
      'avgDelivery': 'ការដឹកជញ្ជូនជាមធ្យម: ២៥ នាទី',
      'incomingRequest': 'ការស្នើសុំចូល',
      'acceptRide': 'ទទួលការធ្វើដំណើរ',
      'decline': 'បដិសេធ',
      'todayPerformance': 'ការអនុវត្តថ្ងៃនេះ',
      'recentTripsDriver': 'ដំណើរថ្មីៗ',
      'dailyBreakdown': 'ការបែងចែកប្រចាំថ្ងៃ',
      'withdrawEarnings': 'ដកប្រាក់ចំណូល',
      'evCarsAvailable': 'រថយន្ត EV\nមានឥឡូវ!',
      'evCarsSubtitle': 'ជួល ឬ ទិញយានជំនិះអគ្គីសនីនៅជិតអ្នក',
      'explore': 'ស្វែងរកយានជំនិះ',
      'completed': 'បានបញ្ចប់',
      'eta': 'ពេលវេលាប៉ាន់ស្មាន',
      'min': 'នាទី',
      'km': 'គ.ម',
      'activeRideInProgress': 'ដំណើរកំពុងបន្ត',
      'noRecentTrips': 'មិនទាន់មានដំណើរថ្មីៗទេ',
      'searchProductsHint': 'ស្វែងរកទំនិញ…',
      'filter': 'តម្រង',
      'listingsAvailable': 'បញ្ជីទំនិញដែលមាន',
      'findBestDeal': 'ស្វែងរកតម្លៃល្អបំផុត',
      'browseAll': 'មើលទាំងអស់',
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
      'fillRequiredFields': 'សូមបំពេញព័ត៌មានទាំងអស់ដែលត្រូវការ',
      'orderPlaced': 'បញ្ជាទិញបានជោគជ័យ!',
      'purchaseRequestSent': 'សំណើទិញរបស់អ្នកត្រូវបានផ្ញើទៅអ្នកលក់។',
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
      'orderPlacedSuccess': 'បញ្ជាទិញបានជោគជ័យ!',
      'paymentMethod': 'វិធីបង់ប្រាក់',
      'startDate': 'ថ្ងៃចាប់ផ្តើម',
      'endDateAuto': 'ថ្ងៃបញ្ចប់ (ស្វ័យប្រវត្តិ)',
      'selectStartDate': 'ជ្រើសរើសថ្ងៃចាប់ផ្តើម',
      'discountApplied': 'បញ្ចុះតម្លៃត្រូវបានអនុវត្ត',
      'apply': 'អនុវត្ត',
      'total': 'សរុប',
      'deleteListing': 'លុបការផ្សាយនេះ?',
      'willBePermanentlyRemoved': 'នឹងត្រូវបានលុបជាអចិន្ត្រៃយ៍។',
      'cancel': 'បោះបង់',
      'delete': 'លុប',
      'postAListing': 'ផ្សាយលក់',
      'noOrdersYet': 'មិនទាន់មានការបញ្ជាទិញទេ',
      'order': 'ការបញ្ជាទិញ',
      'left': 'នៅសល់',
      'savedPlaces': 'ទីតាំងដែលបានរក្សាទុក',
      'noSavedPlacesYet': 'មិនទាន់មានទីតាំងដែលបានរក្សាទុកទេ។',
      'promoCodeTitle': 'កូដប្រូម៉ូសិន',
      'browseVouchers': 'មើលប័ណ្ណបញ្ចុះតម្លៃ →',
      'cambodia': 'កម្ពុជា',
      'mapLabel': 'ផែនទី',
      'noResultsFound': 'រកមិនឃើញលទ្ធផលទេ',
      'addAStop': 'បន្ថែមចំណតឈប់',
      'whereTo': 'ទៅណា?',
      'now': 'ឥឡូវនេះ',
      'confirmBooking': 'បញ្ជាក់ការកក់',
      'noDestinationNeeded': 'មិនចាំបាច់មានទីតាំងទេ — ប្រាប់អ្នកបើកបរដោយផ្ទាល់',
      'whereToTitle': 'ទៅណា?',
      'noSavedPlaces': 'គ្មានទីតាំងដែលបានរក្សាទុក',
      'confirmDestination': 'បញ្ជាក់ទីតាំងទៅ',
      'whereToOptional': 'ទៅណា? (មិនចាំបាច់)',
      'chooseRideTitle': 'ជ្រើសរើសរថយន្ត',
      'scrollUpForMore': 'អូសឡើងលើដើម្បីមើលជម្រើសរថយន្តបន្ថែម',
      'discountSuffix': 'បញ្ចុះតម្លៃ',
      'noDestinationSelected': 'មិនទាន់បានជ្រើសរើសទីតាំងទេ',
      'selectDestination': 'ជ្រើសរើសទីតាំង',
      'deliveryAndMoving': 'ដឹកជញ្ជូន និងដឹកផ្ទុះ',
      'moveWithEase': 'ផ្លាស់ប្តូរដោយងាយស្រួល\nយើងខ្ញុំគ្រប់គ្រងឲ្យអ្នក!',
      'professionalMovingService': 'សេវាកម្មដឹកផ្ទុះជាមួយអ្នកជំនាញ',
      'scheduleMovingDate': 'កំណត់ថ្ងៃដឹកផ្ទុះ',
      'selectLocationsForFare': 'ជ្រើសរើសទីតាំងទទួល និងទីតាំងបញ្ជូនដើម្បីមើលតម្លៃប៉ាន់ស្មាន',
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
      'confirmMovingBooking': 'បញ្ជាក់ការកក់ដឹកផ្ទុះ',
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
      'onThisDevice': 'នៅលើឧបករណ៍នេះបានទេ។',
      'couldNotGenerateShareLink': 'មិនអាចបង្កើតតំណចែករំលែកបានទេ',
      'linkCopied': 'តំណត្រូវបានចម្លងទៅក្ដារតម្បៀតខ្ទាស់',
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
      'loseBusinessAccess': 'អ្នកនឹងលែងអាចប្រើមុខងារអាជីវកម្មទៀតទេ។',
      'leave': 'ចាកចេញ',
      'edit': 'កែសម្រួល',
      'active': 'សកម្ម',
      'removeMemberQuestion': 'លុបសមាជិកនេះ?',
      'remove': 'លុប',
      'noMembersYet': 'មិនទាន់មានសមាជិកទេ។',
      'noBusinessTripsYet': 'មិនទាន់មានដំណើរអាជីវកម្មទេ។',
      'refresh': 'ធ្វើឲ្យស្រស់',
      'retry': 'ព្យាយាមម្តងទៀត',
      'businessRegistered': 'ចុះឈ្មោះអាជីវកម្មបានជោគជ័យ!',
      'shareInviteCodeNote': 'ចែករំលែកកូដអញ្ជើញនេះជាមួយបុគ្គលិករបស់អ្នកដើម្បីឲ្យពួកគេចូលរួម។',
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
      'myRentals': 'ការជួលរបស់ខ្ញុំ',
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
      'surgeZones': 'តំបន់តម្លៃខ្ពស់',
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
      'openTickets': 'សំណើកំពុងបើក',
      'safetyIncidents': 'ករណីសុវត្ថិភាព',
      'driverApprovalsSuffix': 'ការអនុម័តអ្នកបើកបរ',
      'ticketsSuffix': 'សំណើ',
      'serviceModes': 'របៀបសេវាកម្ម',
      'overview': 'ទិដ្ឋភាពទូទៅ',
      'pendingActionsSuffix': 'សកម្មភាពកំពុងរង់ចាំ',
      'clearAll': 'សម្អាតទាំងអស់',
      'size': 'ទំហំ',
      'vehicleType': 'ប្រភេទយានជំនិះ',
      'color': 'ពណ៌',
      'options': 'ជម្រើស',
      'accessories': 'គ្រឿងបន្លាស់',
      'addAccessory': 'បន្ថែមគ្រឿងបន្លាស់',
      'optional': 'ស្រេចចិត្ត',
      'optionalAddOns': 'គ្រឿងបន្លាស់បន្ថែមដែលអ្នកទិញអាចជ្រើសរើស',
      'nameEn': 'ឈ្មោះ (អង់គ្លេស)',
      'nameKm': 'ឈ្មោះ (ខ្មែរ, ស្រេចចិត្ត)',
      'priceUsd': 'តម្លៃ (ដុល្លារ \$)',
      'rentPerDayUsd': 'ថ្លៃជួល / ថ្ងៃ (ដុល្លារ \$)',
      'whatAreYouListing': 'តើអ្នកចង់ដាក់លក់អ្វី?',
      'vehicleOption': 'យានជំនិះ (កង់បី, ឡានដឹក…)',
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
      'areaDistrictOptional': 'តំបន់ / ខណ្ឌ (ស្រេចចិត្ត)',
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
      'enterCouponCodeOptional': 'បញ្ចូលលេខកូដប័ណ្ណបញ្ចុះតម្លៃ (ស្រេចចិត្ត)',
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
      'lookingForRideRequests': 'កំពុងស្វែងរកសំណើដំណើរ',
      'deliveryModeActive': 'ដំណើរការរបៀបដឹកជញ្ជូន',
      'incomingRideRequest': 'សំណើធ្វើដំណើរចូលមក',
      'incomingDeliveryRequest': 'សំណើដឹកជញ្ជូនចូលមក',
      'incomingRentalRequest': 'សំណើជួលចូលមក',
      'acceptDelivery': 'ទទួលការដឹកជញ្ជូន',
      'acceptRental': 'ទទួលការជួល',
      'searchChargingStation': 'ស្វែងរកស្ថានីយ៍សាកថ្ម, ទីតាំង...',
      'nearbyChargingStations': 'ស្ថានីយ៍សាកថ្មនៅជិត',
      'noChargingStationsFound': 'រកមិនឃើញស្ថានីយ៍សាកថ្មទេ',
      'createAccount': 'បង្កើតគណនី',
      'joinRoteh': 'ចូលរួមជាមួយ រទេះ',
      'fastSafeRides': 'ការធ្វើដំណើររហ័ស និងសុវត្ថិភាពនៅកម្ពុជា',
      'iWantTo': 'ខ្ញុំចង់',
      'rideAsPassenger': 'ជិះជាអ្នកដំណើរ',
      'driveAndEarn': 'បើកបរ & រកចំណូល',
      'driverType': 'ប្រភេទអ្នកបើកបរ',
      'fullName': 'ឈ្មោះពេញ',
      'email': 'អ៊ីមែល',
      'enterEmail': 'បញ្ចូលអ៊ីមែលរបស់អ្នក',
      'password': 'ពាក្យសម្ងាត់',
      'enterPassword': 'បញ្ចូលពាក្យសម្ងាត់របស់អ្នក',
      'confirmPassword': 'បញ្ជាក់ពាក្យសម្ងាត់',
      'phoneOptional': 'លេខទូរស័ព្ទ (ស្រេចចិត្ត)',
      'referralCodeOptional': 'លេខកូដណែនាំ (ស្រេចចិត្ត)',
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
    },
    'zh': {
      'appName': 'ROTEH',
      'tagline': '超级应用',
      'copyright': 'ROTEH © 2026 — 版权所有',
      'whoAreYou': '您是谁?',
      'selectRole': '选择您的角色以继续',
      'passenger': '乘客',
      'passengerSub': '预订行程, 订购快递\n购买或租用车辆',
      'driver': '司机',
      'driverSub': '接受行程请求, 管理\n快递业务 & 赚钱',
      'home': '首页',
      'charging': '充电',
      'chat': '聊天',
      'profile': '个人资料',
      'earnings': '收入',
      'dashboard': '仪表板',
      'bookRide': '预订行程',
      'bookRideSub': '立即或预约',
      'delivery': '快递',
      'deliverySub': '快速发送包裹',
      'marketplace': '市场',
      'marketplaceSub': '购买或租用车辆',
      'evStations': '充电站',
      'evStationsSub': '查找附近充电站',
      'safety': '安全',
      'payment': '支付',
      'support': '支持',
      'recentTrips': '最近行程',
      'seeAll': '查看全部',
      'services': '服务',
      'quickActions': '快速操作',
      'whereAreYouGoing': '您要去哪里?',
      'bookNow': '立即预订',
      'scheduleRide': '预约行程',
      'scheduleForLater': '预约晚些时候',
      'sendNow': '立即发送',
      'evChargingStations': '电动车充电站',
      'buy': '购买',
      'rent': '租用',
      'trackTrip': '追踪行程',
      'driverOnTheWay': '司机正在前来',
      'tripInProgress': '行程进行中',
      'arrived': '司机已到达!',
      'paySecurely': '安全支付',
      'emergencySOS': '紧急求助',
      'selectLanguage': '选择语言',
      'language': '语言',
      'goodMorning': '早上好,',
      'hello': '你好',
      'welcome': '欢迎!',
      'online': '在线',
      'offline': '离线',
      'driverDashboard': '司机仪表板',
      'messages': '消息 & 支持',
      'paymentSuccessful': '支付成功!',
      'signOut': '退出登录',
      'paymentMethods': '支付方式',
      'safetySettings': '安全设置',
      'tripHistory': '行程历史',
      'notifications': '通知',
      'helpSupport': '帮助 & 支持',
      'bankPayouts': '银行 & 提款',
      'documents': '文件',
      'navigate': '导航',
      'available': '可用',
      'busy': '繁忙',
      'full': '已满',
      'chooseRide': '选择您的行程',
      'promoCode': '添加优惠码',
      'scheduleDelivery': '预约快递',
      'packageDetails': '包裹详情',
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
      'evCarsSubtitle': '在您附近租用或购买电动车辆',
      'explore': '探索',
      'completed': '已完成',
      'eta': '预计到达',
      'min': '分钟',
      'km': '公里',
      'activeRideInProgress': '行程进行中',
      'noRecentTrips': '暂无最近行程',
      'searchProductsHint': '搜索商品…',
      'filter': '筛选',
      'listingsAvailable': '个商品可供选择',
      'findBestDeal': '寻找最优惠的价格',
      'browseAll': '浏览全部',
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
      'stop': '途经点',
      'dropoff': '目的地',
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
      'keepRide': '保留行程',
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
      'refresh': '刷新',
      'retry': '重试',
      'businessRegistered': '企业账户注册成功！',
      'shareInviteCodeNote': '将此邀请码分享给您的员工以便他们加入。',
      'inviteCodeCopied': '邀请码已复制！',
      'copyCode': '复制邀请码',
      'member': '成员',
      'removeMemberPrefix': '移除',
      'thisMember': '该成员',
      'fromBusinessAccountSuffix': '出企业账户？',
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
      'activeRides': '进行中行程',
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
      'totalSummary': '费用明细',
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
      'searchChargingStation': '搜索充电站、位置...',
      'nearbyChargingStations': '附近的充电站',
      'noChargingStationsFound': '未找到充电站。',
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
