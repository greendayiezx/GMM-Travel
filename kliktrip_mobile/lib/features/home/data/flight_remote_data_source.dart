import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

class FlightSearchParams {
  const FlightSearchParams({
    required this.origin,
    required this.destination,
    required this.departureDate,
    this.returnDate,
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
  });

  final String origin;
  final String destination;
  final String departureDate;
  final String? returnDate;
  final int adults;
  final int children;
  final int infants;

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'origin': origin,
      'destination': destination,
      'departure_date': departureDate,
      'adults': adults.toString(),
    };
    if (returnDate != null && returnDate!.isNotEmpty) {
      params['return_date'] = returnDate!;
    }
    if (children > 0) params['children'] = children.toString();
    if (infants > 0) params['infants'] = infants.toString();
    return params;
  }
}

class FlightSegment {
  const FlightSegment({
    required this.origin,
    required this.destination,
    this.departingAt,
    this.arrivingAt,
    required this.flightNumber,
    required this.airline,
  });

  final String origin;
  final String destination;
  final String? departingAt;
  final String? arrivingAt;
  final String flightNumber;
  final String airline;

  factory FlightSegment.fromJson(Map<String, dynamic> json) {
    return FlightSegment(
      origin: json['origin']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      departingAt: json['departing_at']?.toString(),
      arrivingAt: json['arriving_at']?.toString(),
      flightNumber: json['flight_number']?.toString() ?? '',
      airline: json['airline']?.toString() ?? '',
    );
  }
}

class FlightResult {
  const FlightResult({
    required this.id,
    required this.airline,
    required this.flightNumber,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.transitCount,
    required this.price,
    required this.currency,
    required this.bookingClass,
    this.bookable = false,
    this.segments = const [],
  });

  final String id;
  final String airline;
  final String flightNumber;
  final String origin;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final int transitCount;
  final double price;
  final String currency;
  final String bookingClass;
  final bool bookable;
  final List<FlightSegment> segments;

  factory FlightResult.fromJson(Map<String, dynamic> json) {
    final segmentsData = json['segments'];
    final segmentList = segmentsData is List
        ? segmentsData
            .whereType<Map>()
            .map((s) => FlightSegment.fromJson(Map<String, dynamic>.from(s)))
            .toList()
        : <FlightSegment>[];

    return FlightResult(
      id: json['id']?.toString() ?? '',
      airline: json['airline']?.toString() ?? '',
      flightNumber: json['flightNumber']?.toString() ?? '',
      origin: json['origin']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      departureTime: json['departureTime']?.toString() ?? '',
      arrivalTime: json['arrivalTime']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      transitCount: _asInt(json['transitCount']),
      price: _asDouble(json['price']),
      currency: json['currency']?.toString() ?? 'IDR',
      bookingClass: json['bookingClass']?.toString() ?? 'Economy',
      bookable: json['bookable'] == true,
      segments: segmentList,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class FlightSearchResponse {
  const FlightSearchResponse({
    required this.source,
    required this.bookable,
    required this.data,
    this.datePrices = const {},
    this.redirectLink,
  });

  final String source;
  final bool bookable;
  final List<FlightResult> data;
  final Map<String, double> datePrices;
  final String? redirectLink;

  factory FlightSearchResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'];
    final flights = dataList is List
        ? dataList
            .whereType<Map>()
            .map((f) => FlightResult.fromJson(Map<String, dynamic>.from(f)))
            .toList()
        : <FlightResult>[];

    final rawPrices = json['date_prices'];
    final datePrices = <String, double>{};
    if (rawPrices is Map) {
      for (final entry in rawPrices.entries) {
        final key = entry.key?.toString() ?? '';
        final val = entry.value;
        datePrices[key] = val is num
            ? val.toDouble()
            : double.tryParse(val?.toString() ?? '') ?? 0;
      }
    }

    return FlightSearchResponse(
      source: json['source']?.toString() ?? 'travelpayouts',
      bookable: json['bookable'] == true,
      data: flights,
      datePrices: datePrices,
      redirectLink: json['redirect_link']?.toString(),
    );
  }
}

class AirportOption {
  const AirportOption({
    required this.code,
    required this.name,
    required this.city,
    required this.country,
    required this.displayName,
  });

  final String code;
  final String name;
  final String city;
  final String country;
  final String displayName;

  factory AirportOption.fromJson(Map<String, dynamic> json) {
    return AirportOption(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
    );
  }
}

// ── Database lokal bandara — sumber utama autocomplete ──
// Disalin dari kliktrip-premium agar offline first & tidak bergantung API
const _localAirports = <AirportOption>[
  // ── Indonesia ──
  AirportOption(
      code: 'CGK',
      name: 'Soekarno-Hatta Intl',
      city: 'Jakarta',
      country: 'Indonesia',
      displayName: 'Soekarno-Hatta Intl (CGK)'),
  AirportOption(
      code: 'HLP',
      name: 'Halim Perdanakusuma',
      city: 'Jakarta',
      country: 'Indonesia',
      displayName: 'Halim Perdanakusuma (HLP)'),
  AirportOption(
      code: 'SUB',
      name: 'Juanda Intl',
      city: 'Surabaya',
      country: 'Indonesia',
      displayName: 'Juanda Intl (SUB)'),
  AirportOption(
      code: 'DPS',
      name: 'Ngurah Rai Intl (Bali)',
      city: 'Denpasar - Bali',
      country: 'Indonesia',
      displayName: 'Ngurah Rai Intl - Bali (DPS)'),
  AirportOption(
      code: 'UPG',
      name: 'Sultan Hasanuddin Intl',
      city: 'Makassar',
      country: 'Indonesia',
      displayName: 'Sultan Hasanuddin Intl (UPG)'),
  AirportOption(
      code: 'MDC',
      name: 'Sam Ratulangi Intl',
      city: 'Manado',
      country: 'Indonesia',
      displayName: 'Sam Ratulangi Intl (MDC)'),
  AirportOption(
      code: 'KNO',
      name: 'Kualanamu Intl',
      city: 'Medan',
      country: 'Indonesia',
      displayName: 'Kualanamu Intl (KNO)'),
  AirportOption(
      code: 'BPN',
      name: 'Sultan Aji Muhammad Sulaiman',
      city: 'Balikpapan',
      country: 'Indonesia',
      displayName: 'Sultan Aji Muhammad Sulaiman (BPN)'),
  AirportOption(
      code: 'PLM',
      name: 'Sultan Mahmud Badaruddin II',
      city: 'Palembang',
      country: 'Indonesia',
      displayName: 'Sultan Mahmud Badaruddin II (PLM)'),
  AirportOption(
      code: 'JOG',
      name: 'Yogyakarta Intl (YIA)',
      city: 'Yogyakarta',
      country: 'Indonesia',
      displayName: 'Yogyakarta Intl (JOG)'),
  AirportOption(
      code: 'SRG',
      name: 'Ahmad Yani Intl',
      city: 'Semarang',
      country: 'Indonesia',
      displayName: 'Ahmad Yani Intl (SRG)'),
  AirportOption(
      code: 'PNK',
      name: 'Supadio Intl',
      city: 'Pontianak',
      country: 'Indonesia',
      displayName: 'Supadio Intl (PNK)'),
  AirportOption(
      code: 'BDJ',
      name: 'Syamsudin Noor Intl',
      city: 'Banjarmasin',
      country: 'Indonesia',
      displayName: 'Syamsudin Noor Intl (BDJ)'),
  AirportOption(
      code: 'BTH',
      name: 'Hang Nadim Intl',
      city: 'Batam',
      country: 'Indonesia',
      displayName: 'Hang Nadim Intl (BTH)'),
  AirportOption(
      code: 'BTJ',
      name: 'Sultan Iskandar Muda Intl',
      city: 'Banda Aceh',
      country: 'Indonesia',
      displayName: 'Sultan Iskandar Muda Intl (BTJ)'),
  AirportOption(
      code: 'PDG',
      name: 'Minangkabau Intl',
      city: 'Padang',
      country: 'Indonesia',
      displayName: 'Minangkabau Intl (PDG)'),
  AirportOption(
      code: 'MES',
      name: 'Soewondo',
      city: 'Medan',
      country: 'Indonesia',
      displayName: 'Soewondo (MES)'),
  AirportOption(
      code: 'DJJ',
      name: 'Sentani Intl',
      city: 'Jayapura',
      country: 'Indonesia',
      displayName: 'Sentani Intl (DJJ)'),
  AirportOption(
      code: 'AMQ',
      name: 'Pattimura Intl',
      city: 'Ambon',
      country: 'Indonesia',
      displayName: 'Pattimura Intl (AMQ)'),
  AirportOption(
      code: 'KDI',
      name: 'Haluoleo Intl',
      city: 'Kendari',
      country: 'Indonesia',
      displayName: 'Haluoleo Intl (KDI)'),
  AirportOption(
      code: 'PLW',
      name: 'Mutiara SIS Al-Jufrie',
      city: 'Palu',
      country: 'Indonesia',
      displayName: 'Mutiara SIS Al-Jufrie (PLW)'),
  AirportOption(
      code: 'LOP',
      name: 'Lombok Intl',
      city: 'Lombok',
      country: 'Indonesia',
      displayName: 'Lombok Intl (LOP)'),
  AirportOption(
      code: 'TIM',
      name: 'Moses Kilangin Intl',
      city: 'Timika',
      country: 'Indonesia',
      displayName: 'Moses Kilangin Intl (TIM)'),
  AirportOption(
      code: 'SOC',
      name: 'Adisumarmo Intl',
      city: 'Solo',
      country: 'Indonesia',
      displayName: 'Adisumarmo Intl (SOC)'),
  AirportOption(
      code: 'SRI',
      name: 'Temindung',
      city: 'Samarinda',
      country: 'Indonesia',
      displayName: 'Temindung (SRI)'),
  AirportOption(
      code: 'KOE',
      name: 'El Tari Intl',
      city: 'Kupang',
      country: 'Indonesia',
      displayName: 'El Tari Intl (KOE)'),
  AirportOption(
      code: 'MOF',
      name: 'Frans Sales Lega',
      city: 'Maumere',
      country: 'Indonesia',
      displayName: 'Frans Sales Lega (MOF)'),
  AirportOption(
      code: 'TKG',
      name: 'Raden Inten II Intl',
      city: 'Bandar Lampung',
      country: 'Indonesia',
      displayName: 'Raden Inten II Intl (TKG)'),
  AirportOption(
      code: 'PGK',
      name: 'Depati Amir',
      city: 'Pangkal Pinang',
      country: 'Indonesia',
      displayName: 'Depati Amir (PGK)'),
  AirportOption(
      code: 'TJQ',
      name: 'H.A.S. Hanandjoeddin',
      city: 'Tanjung Pandan',
      country: 'Indonesia',
      displayName: 'H.A.S. Hanandjoeddin (TJQ)'),
  AirportOption(
      code: 'GNS',
      name: 'Binaka',
      city: 'Gunungsitoli',
      country: 'Indonesia',
      displayName: 'Binaka (GNS)'),
  AirportOption(
      code: 'BKS',
      name: 'Fatmawati Soekarno',
      city: 'Bengkulu',
      country: 'Indonesia',
      displayName: 'Fatmawati Soekarno (BKS)'),
  AirportOption(
      code: 'MLG',
      name: 'Abdul Rachman Saleh',
      city: 'Malang',
      country: 'Indonesia',
      displayName: 'Abdul Rachman Saleh (MLG)'),
  AirportOption(
      code: 'TRK',
      name: 'Juwata Intl',
      city: 'Tarakan',
      country: 'Indonesia',
      displayName: 'Juwata Intl (TRK)'),
  AirportOption(
      code: 'TTE',
      name: 'Sultan Babullah Intl',
      city: 'Ternate',
      country: 'Indonesia',
      displayName: 'Sultan Babullah Intl (TTE)'),
  AirportOption(
      code: 'LUW',
      name: 'Syukuran Aminuddin Amir',
      city: 'Luwuk',
      country: 'Indonesia',
      displayName: 'Syukuran Aminuddin Amir (LUW)'),
  AirportOption(
      code: 'MKQ',
      name: 'Mopah Intl',
      city: 'Merauke',
      country: 'Indonesia',
      displayName: 'Mopah Intl (MKQ)'),
  AirportOption(
      code: 'BIK',
      name: 'Frans Kaisiepo Intl',
      city: 'Biak',
      country: 'Indonesia',
      displayName: 'Frans Kaisiepo Intl (BIK)'),
  AirportOption(
      code: 'FKQ',
      name: 'Fakfak Torea',
      city: 'Fakfak',
      country: 'Indonesia',
      displayName: 'Fakfak Torea (FKQ)'),
  AirportOption(
      code: 'NBX',
      name: 'Nabire',
      city: 'Nabire',
      country: 'Indonesia',
      displayName: 'Nabire (NBX)'),
  AirportOption(
      code: 'LBJ',
      name: 'Komodo Intl',
      city: 'Labuan Bajo',
      country: 'Indonesia',
      displayName: 'Komodo Intl (LBJ)'),
  AirportOption(
      code: 'WMX',
      name: 'Wamena',
      city: 'Wamena',
      country: 'Indonesia',
      displayName: 'Wamena (WMX)'),
  // ── ASEAN ──
  AirportOption(
      code: 'SIN',
      name: 'Changi Intl',
      city: 'Singapura',
      country: 'Singapura',
      displayName: 'Changi Intl (SIN)'),
  AirportOption(
      code: 'KUL',
      name: 'Kuala Lumpur Intl (KLIA)',
      city: 'Kuala Lumpur',
      country: 'Malaysia',
      displayName: 'Kuala Lumpur Intl (KUL)'),
  AirportOption(
      code: 'SZB',
      name: 'Sultan Abdul Aziz Shah',
      city: 'Kuala Lumpur',
      country: 'Malaysia',
      displayName: 'Sultan Abdul Aziz Shah (SZB)'),
  AirportOption(
      code: 'BKK',
      name: 'Suvarnabhumi Intl',
      city: 'Bangkok',
      country: 'Thailand',
      displayName: 'Suvarnabhumi Intl (BKK)'),
  AirportOption(
      code: 'DMK',
      name: 'Don Mueang Intl',
      city: 'Bangkok',
      country: 'Thailand',
      displayName: 'Don Mueang Intl (DMK)'),
  AirportOption(
      code: 'HDY',
      name: 'Hat Yai Intl',
      city: 'Hat Yai',
      country: 'Thailand',
      displayName: 'Hat Yai Intl (HDY)'),
  AirportOption(
      code: 'CNX',
      name: 'Chiang Mai Intl',
      city: 'Chiang Mai',
      country: 'Thailand',
      displayName: 'Chiang Mai Intl (CNX)'),
  AirportOption(
      code: 'HKT',
      name: 'Phuket Intl',
      city: 'Phuket',
      country: 'Thailand',
      displayName: 'Phuket Intl (HKT)'),
  AirportOption(
      code: 'MNL',
      name: 'Ninoy Aquino Intl',
      city: 'Manila',
      country: 'Filipina',
      displayName: 'Ninoy Aquino Intl (MNL)'),
  AirportOption(
      code: 'CEB',
      name: 'Mactan-Cebu Intl',
      city: 'Cebu',
      country: 'Filipina',
      displayName: 'Mactan-Cebu Intl (CEB)'),
  AirportOption(
      code: 'SGN',
      name: 'Tan Son Nhat Intl',
      city: 'Ho Chi Minh City',
      country: 'Vietnam',
      displayName: 'Tan Son Nhat Intl (SGN)'),
  AirportOption(
      code: 'HAN',
      name: 'Noi Bai Intl',
      city: 'Hanoi',
      country: 'Vietnam',
      displayName: 'Noi Bai Intl (HAN)'),
  AirportOption(
      code: 'DAD',
      name: 'Da Nang Intl',
      city: 'Da Nang',
      country: 'Vietnam',
      displayName: 'Da Nang Intl (DAD)'),
  AirportOption(
      code: 'RGN',
      name: 'Yangon Intl',
      city: 'Yangon',
      country: 'Myanmar',
      displayName: 'Yangon Intl (RGN)'),
  AirportOption(
      code: 'PNH',
      name: 'Phnom Penh Intl',
      city: 'Phnom Penh',
      country: 'Kamboja',
      displayName: 'Phnom Penh Intl (PNH)'),
  AirportOption(
      code: 'VTE',
      name: 'Wattay Intl',
      city: 'Vientiane',
      country: 'Laos',
      displayName: 'Wattay Intl (VTE)'),
  AirportOption(
      code: 'BWN',
      name: 'Brunei Intl',
      city: 'Bandar Seri Begawan',
      country: 'Brunei',
      displayName: 'Brunei Intl (BWN)'),
  // ── Asia Selatan ──
  AirportOption(
      code: 'DEL',
      name: 'Indira Gandhi Intl',
      city: 'New Delhi',
      country: 'India',
      displayName: 'Indira Gandhi Intl (DEL)'),
  AirportOption(
      code: 'BOM',
      name: 'Chhatrapati Shivaji Maharaj Intl',
      city: 'Mumbai',
      country: 'India',
      displayName: 'Chhatrapati Shivaji Maharaj Intl (BOM)'),
  AirportOption(
      code: 'MAA',
      name: 'Chennai Intl',
      city: 'Chennai',
      country: 'India',
      displayName: 'Chennai Intl (MAA)'),
  AirportOption(
      code: 'BLR',
      name: 'Kempegowda Intl',
      city: 'Bangalore',
      country: 'India',
      displayName: 'Kempegowda Intl (BLR)'),
  AirportOption(
      code: 'HYD',
      name: 'Rajiv Gandhi Intl',
      city: 'Hyderabad',
      country: 'India',
      displayName: 'Rajiv Gandhi Intl (HYD)'),
  AirportOption(
      code: 'CCU',
      name: 'Netaji Subhas Chandra Bose Intl',
      city: 'Kolkata',
      country: 'India',
      displayName: 'Netaji Subhas Chandra Bose Intl (CCU)'),
  AirportOption(
      code: 'COK',
      name: 'Cochin Intl',
      city: 'Kochi',
      country: 'India',
      displayName: 'Cochin Intl (COK)'),
  AirportOption(
      code: 'CMB',
      name: 'Bandaranaike Intl',
      city: 'Colombo',
      country: 'Sri Lanka',
      displayName: 'Bandaranaike Intl (CMB)'),
  AirportOption(
      code: 'DAC',
      name: 'Hazrat Shahjalal Intl',
      city: 'Dhaka',
      country: 'Bangladesh',
      displayName: 'Hazrat Shahjalal Intl (DAC)'),
  AirportOption(
      code: 'KTM',
      name: 'Tribhuvan Intl',
      city: 'Kathmandu',
      country: 'Nepal',
      displayName: 'Tribhuvan Intl (KTM)'),
  // ── Asia Timur ──
  AirportOption(
      code: 'HKG',
      name: 'Hong Kong Intl',
      city: 'Hong Kong',
      country: 'Hong Kong',
      displayName: 'Hong Kong Intl (HKG)'),
  AirportOption(
      code: 'NRT',
      name: 'Narita Intl',
      city: 'Tokyo',
      country: 'Jepang',
      displayName: 'Narita Intl (NRT)'),
  AirportOption(
      code: 'HND',
      name: 'Haneda Intl',
      city: 'Tokyo',
      country: 'Jepang',
      displayName: 'Haneda Intl (HND)'),
  AirportOption(
      code: 'KIX',
      name: 'Kansai Intl',
      city: 'Osaka',
      country: 'Jepang',
      displayName: 'Kansai Intl (KIX)'),
  AirportOption(
      code: 'NGO',
      name: 'Chubu Centrair Intl',
      city: 'Nagoya',
      country: 'Jepang',
      displayName: 'Chubu Centrair Intl (NGO)'),
  AirportOption(
      code: 'CTS',
      name: 'New Chitose',
      city: 'Sapporo',
      country: 'Jepang',
      displayName: 'New Chitose (CTS)'),
  AirportOption(
      code: 'ICN',
      name: 'Incheon Intl',
      city: 'Seoul',
      country: 'Korea Selatan',
      displayName: 'Incheon Intl (ICN)'),
  AirportOption(
      code: 'GMP',
      name: 'Gimpo Intl',
      city: 'Seoul',
      country: 'Korea Selatan',
      displayName: 'Gimpo Intl (GMP)'),
  AirportOption(
      code: 'PEK',
      name: 'Beijing Capital Intl',
      city: 'Beijing',
      country: 'Tiongkok',
      displayName: 'Beijing Capital Intl (PEK)'),
  AirportOption(
      code: 'PVG',
      name: 'Pudong Intl',
      city: 'Shanghai',
      country: 'Tiongkok',
      displayName: 'Pudong Intl (PVG)'),
  AirportOption(
      code: 'SHA',
      name: 'Hongqiao Intl',
      city: 'Shanghai',
      country: 'Tiongkok',
      displayName: 'Hongqiao Intl (SHA)'),
  AirportOption(
      code: 'CAN',
      name: 'Baiyun Intl',
      city: 'Guangzhou',
      country: 'Tiongkok',
      displayName: 'Baiyun Intl (CAN)'),
  AirportOption(
      code: 'SZX',
      name: "Bao'an Intl",
      city: 'Shenzhen',
      country: 'Tiongkok',
      displayName: "Bao'an Intl (SZX)"),
  AirportOption(
      code: 'CTU',
      name: 'Tianfu Intl',
      city: 'Chengdu',
      country: 'Tiongkok',
      displayName: 'Tianfu Intl (CTU)'),
  AirportOption(
      code: 'XIY',
      name: 'Xianyang Intl',
      city: "Xi'an",
      country: 'Tiongkok',
      displayName: "Xianyang Intl (XIY)"),
  AirportOption(
      code: 'TPE',
      name: 'Taoyuan Intl',
      city: 'Taipei',
      country: 'Taiwan',
      displayName: 'Taoyuan Intl (TPE)'),
  AirportOption(
      code: 'MFM',
      name: 'Macau Intl',
      city: 'Macau',
      country: 'Macau',
      displayName: 'Macau Intl (MFM)'),
  // ── Timur Tengah ──
  AirportOption(
      code: 'DXB',
      name: 'Dubai Intl',
      city: 'Dubai',
      country: 'UAE',
      displayName: 'Dubai Intl (DXB)'),
  AirportOption(
      code: 'AUH',
      name: 'Abu Dhabi Intl',
      city: 'Abu Dhabi',
      country: 'UAE',
      displayName: 'Abu Dhabi Intl (AUH)'),
  AirportOption(
      code: 'SHJ',
      name: 'Sharjah Intl',
      city: 'Sharjah',
      country: 'UAE',
      displayName: 'Sharjah Intl (SHJ)'),
  AirportOption(
      code: 'DOH',
      name: 'Hamad Intl',
      city: 'Doha',
      country: 'Qatar',
      displayName: 'Hamad Intl (DOH)'),
  AirportOption(
      code: 'RUH',
      name: 'King Khalid Intl',
      city: 'Riyadh',
      country: 'Arab Saudi',
      displayName: 'King Khalid Intl (RUH)'),
  AirportOption(
      code: 'JED',
      name: 'King Abdulaziz Intl',
      city: 'Jeddah',
      country: 'Arab Saudi',
      displayName: 'King Abdulaziz Intl (JED)'),
  AirportOption(
      code: 'MED',
      name: 'Prince Mohammad Bin Abdulaziz',
      city: 'Madinah',
      country: 'Arab Saudi',
      displayName: 'Prince Mohammad Bin Abdulaziz (MED)'),
  AirportOption(
      code: 'CAI',
      name: 'Cairo Intl',
      city: 'Kairo',
      country: 'Mesir',
      displayName: 'Cairo Intl (CAI)'),
  // ── Turki ──
  AirportOption(
      code: 'IST',
      name: 'Istanbul Airport',
      city: 'Istanbul',
      country: 'Turki',
      displayName: 'Istanbul Airport (IST)'),
  AirportOption(
      code: 'SAW',
      name: 'Istanbul Sabiha Gökçen',
      city: 'Istanbul',
      country: 'Turki',
      displayName: 'Istanbul Sabiha Gökçen (SAW)'),
  AirportOption(
      code: 'AYT',
      name: 'Antalya Intl',
      city: 'Antalya',
      country: 'Turki',
      displayName: 'Antalya Intl (AYT)'),
  // ── Eropa ──
  AirportOption(
      code: 'LHR',
      name: 'Heathrow',
      city: 'London',
      country: 'Inggris',
      displayName: 'Heathrow (LHR)'),
  AirportOption(
      code: 'CDG',
      name: 'Charles de Gaulle',
      city: 'Paris',
      country: 'Prancis',
      displayName: 'Charles de Gaulle (CDG)'),
  AirportOption(
      code: 'AMS',
      name: 'Schiphol',
      city: 'Amsterdam',
      country: 'Belanda',
      displayName: 'Schiphol (AMS)'),
  AirportOption(
      code: 'FRA',
      name: 'Frankfurt Intl',
      city: 'Frankfurt',
      country: 'Jerman',
      displayName: 'Frankfurt Intl (FRA)'),
  AirportOption(
      code: 'MUC',
      name: 'Munich Intl',
      city: 'Munich',
      country: 'Jerman',
      displayName: 'Munich Intl (MUC)'),
  AirportOption(
      code: 'FCO',
      name: 'Leonardo da Vinci Intl',
      city: 'Roma',
      country: 'Italia',
      displayName: 'Leonardo da Vinci Intl (FCO)'),
  AirportOption(
      code: 'MAD',
      name: 'Barajas Intl',
      city: 'Madrid',
      country: 'Spanyol',
      displayName: 'Barajas Intl (MAD)'),
  AirportOption(
      code: 'BCN',
      name: 'Barcelona–El Prat',
      city: 'Barcelona',
      country: 'Spanyol',
      displayName: 'Barcelona–El Prat (BCN)'),
  AirportOption(
      code: 'ATH',
      name: 'Eleftherios Venizelos Intl',
      city: 'Athena',
      country: 'Yunani',
      displayName: 'Eleftherios Venizelos Intl (ATH)'),
  AirportOption(
      code: 'ZRH',
      name: 'Zürich Intl',
      city: 'Zürich',
      country: 'Swiss',
      displayName: 'Zürich Intl (ZRH)'),
  AirportOption(
      code: 'VIE',
      name: 'Vienna Intl',
      city: 'Vienna',
      country: 'Austria',
      displayName: 'Vienna Intl (VIE)'),
  // ── Australia & Pasifik ──
  AirportOption(
      code: 'SYD',
      name: 'Kingsford Smith Intl',
      city: 'Sydney',
      country: 'Australia',
      displayName: 'Kingsford Smith Intl (SYD)'),
  AirportOption(
      code: 'MEL',
      name: 'Melbourne Tullamarine Intl',
      city: 'Melbourne',
      country: 'Australia',
      displayName: 'Melbourne Tullamarine Intl (MEL)'),
  AirportOption(
      code: 'BNE',
      name: 'Brisbane Intl',
      city: 'Brisbane',
      country: 'Australia',
      displayName: 'Brisbane Intl (BNE)'),
  AirportOption(
      code: 'PER',
      name: 'Perth Intl',
      city: 'Perth',
      country: 'Australia',
      displayName: 'Perth Intl (PER)'),
  AirportOption(
      code: 'AKL',
      name: 'Auckland Intl',
      city: 'Auckland',
      country: 'Selandia Baru',
      displayName: 'Auckland Intl (AKL)'),
  // ── Amerika Utara ──
  AirportOption(
      code: 'JFK',
      name: 'John F. Kennedy Intl',
      city: 'New York',
      country: 'Amerika Serikat',
      displayName: 'John F. Kennedy Intl (JFK)'),
  AirportOption(
      code: 'LAX',
      name: 'Los Angeles Intl',
      city: 'Los Angeles',
      country: 'Amerika Serikat',
      displayName: 'Los Angeles Intl (LAX)'),
  AirportOption(
      code: 'SFO',
      name: 'San Francisco Intl',
      city: 'San Francisco',
      country: 'Amerika Serikat',
      displayName: 'San Francisco Intl (SFO)'),
  AirportOption(
      code: 'ORD',
      name: "O'Hare Intl",
      city: 'Chicago',
      country: 'Amerika Serikat',
      displayName: "O'Hare Intl (ORD)"),
  AirportOption(
      code: 'DFW',
      name: 'Dallas/Fort Worth Intl',
      city: 'Dallas',
      country: 'Amerika Serikat',
      displayName: 'Dallas/Fort Worth Intl (DFW)'),
  AirportOption(
      code: 'MIA',
      name: 'Miami Intl',
      city: 'Miami',
      country: 'Amerika Serikat',
      displayName: 'Miami Intl (MIA)'),
  AirportOption(
      code: 'LAS',
      name: 'Harry Reid Intl',
      city: 'Las Vegas',
      country: 'Amerika Serikat',
      displayName: 'Harry Reid Intl (LAS)'),
  AirportOption(
      code: 'SEA',
      name: 'Seattle-Tacoma Intl',
      city: 'Seattle',
      country: 'Amerika Serikat',
      displayName: 'Seattle-Tacoma Intl (SEA)'),
  AirportOption(
      code: 'YYZ',
      name: 'Toronto Pearson Intl',
      city: 'Toronto',
      country: 'Kanada',
      displayName: 'Toronto Pearson Intl (YYZ)'),
  AirportOption(
      code: 'MEX',
      name: 'Benito Juárez Intl',
      city: 'Mexico City',
      country: 'Meksiko',
      displayName: 'Benito Juárez Intl (MEX)'),
];

class FlightRemoteDataSource {
  FlightRemoteDataSource({Dio? dio})
      : _dio = dio ?? DioClient.create(connectTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 30)).dio;

  final Dio _dio;

  Future<FlightSearchResponse> searchFlights(FlightSearchParams params) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.flightSearch,
      queryParameters: params.toQueryParameters(),
    );
    final data = response.data;
    if (data is! Map) {
      throw const FormatException(
          'Format data pencarian penerbangan tidak valid.');
    }
    return FlightSearchResponse.fromJson(Map<String, dynamic>.from(data));
  }

  List<AirportOption> getPopularAirports() {
    final popularCodes = {'CGK', 'DPS', 'SUB', 'KNO', 'UPG', 'JOG', 'BPN', 'SIN', 'KUL', 'HKG'};
    return _localAirports
        .where((a) => popularCodes.contains(a.code))
        .toList()
      ..sort((a, b) {
        final aIdx = popularCodes.toList().indexOf(a.code);
        final bIdx = popularCodes.toList().indexOf(b.code);
        return aIdx - bIdx;
      });
  }

  List<AirportOption> getAllAirports() => List.from(_localAirports);

  /// Cari bandara — offline first dari database lokal, fallback ke API
  Future<List<AirportOption>> searchAirports(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return getPopularAirports();

    // 1) Cari di database lokal dulu
    final localMatches = _localAirports
        .where((a) =>
            a.code.toLowerCase().contains(q) ||
            a.name.toLowerCase().contains(q) ||
            a.city.toLowerCase().contains(q) ||
            a.country.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) {
        // Indonesia selalu di atas
        final aID = a.country == 'Indonesia' ? 0 : 1;
        final bID = b.country == 'Indonesia' ? 0 : 1;
        return aID - bID;
      });

    // Ambil max 8 hasil lokal
    final localTop = localMatches.take(8).toList();

    // Jika lokal sudah cukup (≥3 hasil), langsung return tanpa hit API
    if (localTop.length >= 3) {
      return localTop;
    }

    // 2) Fallback ke API /flights/airports untuk melengkapi
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.flightAirports,
        queryParameters: {'q': query},
      );
      final data = response.data;
      if (data is List) {
        final apiResults = data
            .whereType<Map>()
            .map((a) => AirportOption.fromJson(Map<String, dynamic>.from(a)))
            .toList();
        // Gabungkan lokal + API, tanpa duplikat kode
        final existingCodes = localTop.map((a) => a.code).toSet();
        for (final api in apiResults) {
          if (!existingCodes.contains(api.code)) {
            localTop.add(api);
            existingCodes.add(api.code);
          }
        }
      }
    } catch (_) {
      // Abaikan error API, tetap pakai hasil lokal
    }

    return localTop;
  }

  Future<dynamic> searchCalendar({
    required String origin,
    required String destination,
    required String month,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.flightCalendar,
      queryParameters: {
        'origin': origin,
        'destination': destination,
        'month': month
      },
    );
    return response.data;
  }

  Future<dynamic> priceCheck({
    required String origin,
    required String destination,
    required String departureDate,
    String? returnDate,
  }) async {
    final params = <String, dynamic>{
      'origin': origin,
      'destination': destination,
      'departure_date': departureDate
    };
    if (returnDate != null) params['return_date'] = returnDate;
    final response = await _dio.get<dynamic>(ApiEndpoints.flightPriceCheck,
        queryParameters: params);
    return response.data;
  }

  Future<dynamic> priceStrip({
    required String origin,
    required String destination,
    required String departureDate,
    String? returnDate,
  }) async {
    final params = <String, dynamic>{
      'origin': origin,
      'destination': destination,
      'departure_date': departureDate
    };
    if (returnDate != null) params['return_date'] = returnDate;
    final response = await _dio.get<dynamic>(ApiEndpoints.flightPriceStrip,
        queryParameters: params);
    return response.data;
  }
}
