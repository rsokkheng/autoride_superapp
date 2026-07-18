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
      'tagline': 'ROTEH App',
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
      'evCarsSubtitle': 'Rent or buy electric\nvehicles near you',
      'explore': 'Explore',
      'completed': 'Completed',
      'eta': 'ETA',
      'min': 'min',
      'km': 'km',
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
      'evCarsSubtitle': 'ជួល ឬ ទិញរថយន្តអគ្គីសនី\nនៅជិតអ្នក',
      'explore': 'ស្វែងរកយានជំនិះ',
      'completed': 'បានបញ្ចប់',
      'eta': 'ពេលវេលាប៉ាន់ស្មាន',
      'min': 'នាទី',
      'km': 'គ.ម',
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
      'evCarsSubtitle': '在您附近租用或购买\n电动车辆',
      'explore': '探索',
      'completed': '已完成',
      'eta': '预计到达',
      'min': '分钟',
      'km': '公里',
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
