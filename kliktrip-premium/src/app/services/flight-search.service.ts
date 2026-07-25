import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { map, catchError } from 'rxjs/operators';
import { FlightResult, FlightSearchResponse, AirportOption } from '../models/flight.model';
import { environment } from '../../environments/environment';

/** Database lokal bandara — sumber utama autocomplete, tidak bergantung API eksternal */
const LOCAL_AIRPORTS: AirportOption[] = [
  // ── Indonesia ──────────────────────────────────────────────────────────────
  { code:'CGK', name:'Soekarno-Hatta Intl',              city:'Jakarta',          country:'Indonesia',    displayName:'Soekarno-Hatta Intl (CGK)' },
  { code:'HLP', name:'Halim Perdanakusuma',               city:'Jakarta',          country:'Indonesia',    displayName:'Halim Perdanakusuma (HLP)' },
  { code:'SUB', name:'Juanda Intl',                       city:'Surabaya',         country:'Indonesia',    displayName:'Juanda Intl (SUB)' },
  { code:'DPS', name:'Ngurah Rai Intl (Bali)',             city:'Denpasar - Bali',  country:'Indonesia',    displayName:'Ngurah Rai Intl - Bali (DPS)' },
  { code:'UPG', name:'Sultan Hasanuddin Intl',            city:'Makassar',         country:'Indonesia',    displayName:'Sultan Hasanuddin Intl (UPG)' },
  { code:'MDC', name:'Sam Ratulangi Intl',                city:'Manado',           country:'Indonesia',    displayName:'Sam Ratulangi Intl (MDC)' },
  { code:'KNO', name:'Kualanamu Intl',                    city:'Medan',            country:'Indonesia',    displayName:'Kualanamu Intl (KNO)' },
  { code:'BPN', name:'Sultan Aji Muhammad Sulaiman',      city:'Balikpapan',       country:'Indonesia',    displayName:'Sultan Aji Muhammad Sulaiman (BPN)' },
  { code:'PLM', name:'Sultan Mahmud Badaruddin II',       city:'Palembang',        country:'Indonesia',    displayName:'Sultan Mahmud Badaruddin II (PLM)' },
  { code:'JOG', name:'Yogyakarta Intl (YIA)',             city:'Yogyakarta',       country:'Indonesia',    displayName:'Yogyakarta Intl (JOG)' },
  { code:'SRG', name:'Ahmad Yani Intl',                   city:'Semarang',         country:'Indonesia',    displayName:'Ahmad Yani Intl (SRG)' },
  { code:'PNK', name:'Supadio Intl',                      city:'Pontianak',        country:'Indonesia',    displayName:'Supadio Intl (PNK)' },
  { code:'BDJ', name:'Syamsudin Noor Intl',               city:'Banjarmasin',      country:'Indonesia',    displayName:'Syamsudin Noor Intl (BDJ)' },
  { code:'BTH', name:'Hang Nadim Intl',                   city:'Batam',            country:'Indonesia',    displayName:'Hang Nadim Intl (BTH)' },
  { code:'BTJ', name:'Sultan Iskandar Muda Intl',         city:'Banda Aceh',       country:'Indonesia',    displayName:'Sultan Iskandar Muda Intl (BTJ)' },
  { code:'PDG', name:'Minangkabau Intl',                  city:'Padang',           country:'Indonesia',    displayName:'Minangkabau Intl (PDG)' },
  { code:'MES', name:'Soewondo',                          city:'Medan',            country:'Indonesia',    displayName:'Soewondo (MES)' },
  { code:'DJJ', name:'Sentani Intl',                      city:'Jayapura',         country:'Indonesia',    displayName:'Sentani Intl (DJJ)' },
  { code:'AMQ', name:'Pattimura Intl',                    city:'Ambon',            country:'Indonesia',    displayName:'Pattimura Intl (AMQ)' },
  { code:'KDI', name:'Haluoleo Intl',                     city:'Kendari',          country:'Indonesia',    displayName:'Haluoleo Intl (KDI)' },
  { code:'PLW', name:'Mutiara SIS Al-Jufrie',             city:'Palu',             country:'Indonesia',    displayName:'Mutiara SIS Al-Jufrie (PLW)' },
  { code:'LOP', name:'Lombok Intl',                       city:'Lombok',           country:'Indonesia',    displayName:'Lombok Intl (LOP)' },
  { code:'TIM', name:'Moses Kilangin Intl',               city:'Timika',           country:'Indonesia',    displayName:'Moses Kilangin Intl (TIM)' },
  { code:'SOC', name:'Adisumarmo Intl',                   city:'Solo',             country:'Indonesia',    displayName:'Adisumarmo Intl (SOC)' },
  { code:'SRI', name:'Temindung',                         city:'Samarinda',        country:'Indonesia',    displayName:'Temindung (SRI)' },
  { code:'KOE', name:'El Tari Intl',                      city:'Kupang',           country:'Indonesia',    displayName:'El Tari Intl (KOE)' },
  { code:'MOF', name:'Frans Sales Lega',                  city:'Maumere',          country:'Indonesia',    displayName:'Frans Sales Lega (MOF)' },
  { code:'TKG', name:'Raden Inten II Intl',               city:'Bandar Lampung',   country:'Indonesia',    displayName:'Raden Inten II Intl (TKG)' },
  { code:'PGK', name:'Depati Amir',                       city:'Pangkal Pinang',   country:'Indonesia',    displayName:'Depati Amir (PGK)' },
  { code:'TJQ', name:'H.A.S. Hanandjoeddin',              city:'Tanjung Pandan',   country:'Indonesia',    displayName:'H.A.S. Hanandjoeddin (TJQ)' },
  { code:'GNS', name:'Binaka',                            city:'Gunungsitoli',     country:'Indonesia',    displayName:'Binaka (GNS)' },
  { code:'BKS', name:'Fatmawati Soekarno',                city:'Bengkulu',         country:'Indonesia',    displayName:'Fatmawati Soekarno (BKS)' },
  { code:'MLG', name:'Abdul Rachman Saleh',               city:'Malang',           country:'Indonesia',    displayName:'Abdul Rachman Saleh (MLG)' },
  { code:'TRK', name:'Juwata Intl',                       city:'Tarakan',          country:'Indonesia',    displayName:'Juwata Intl (TRK)' },
  { code:'TTE', name:'Sultan Babullah Intl',              city:'Ternate',          country:'Indonesia',    displayName:'Sultan Babullah Intl (TTE)' },
  { code:'LUW', name:'Syukuran Aminuddin Amir',           city:'Luwuk',            country:'Indonesia',    displayName:'Syukuran Aminuddin Amir (LUW)' },
  { code:'MKQ', name:'Mopah Intl',                        city:'Merauke',          country:'Indonesia',    displayName:'Mopah Intl (MKQ)' },
  { code:'BIK', name:'Frans Kaisiepo Intl',               city:'Biak',             country:'Indonesia',    displayName:'Frans Kaisiepo Intl (BIK)' },
  { code:'FKQ', name:'Fakfak Torea',                      city:'Fakfak',           country:'Indonesia',    displayName:'Fakfak Torea (FKQ)' },
  { code:'NBX', name:'Nabire',                            city:'Nabire',           country:'Indonesia',    displayName:'Nabire (NBX)' },
  { code:'LBJ', name:'Komodo Intl',                       city:'Labuan Bajo',      country:'Indonesia',    displayName:'Komodo Intl (LBJ)' },
  { code:'WMX', name:'Wamena',                            city:'Wamena',           country:'Indonesia',    displayName:'Wamena (WMX)' },
  // ── ASEAN ──────────────────────────────────────────────────────────────────
  { code:'SIN', name:'Changi Intl',                       city:'Singapura',        country:'Singapura',    displayName:'Changi Intl (SIN)' },
  { code:'KUL', name:'Kuala Lumpur Intl (KLIA)',          city:'Kuala Lumpur',     country:'Malaysia',     displayName:'Kuala Lumpur Intl (KUL)' },
  { code:'SZB', name:'Sultan Abdul Aziz Shah',            city:'Kuala Lumpur',     country:'Malaysia',     displayName:'Sultan Abdul Aziz Shah (SZB)' },
  { code:'BKK', name:'Suvarnabhumi Intl',                 city:'Bangkok',          country:'Thailand',     displayName:'Suvarnabhumi Intl (BKK)' },
  { code:'DMK', name:'Don Mueang Intl',                   city:'Bangkok',          country:'Thailand',     displayName:'Don Mueang Intl (DMK)' },
  { code:'HDY', name:'Hat Yai Intl',                      city:'Hat Yai',          country:'Thailand',     displayName:'Hat Yai Intl (HDY)' },
  { code:'CNX', name:'Chiang Mai Intl',                   city:'Chiang Mai',       country:'Thailand',     displayName:'Chiang Mai Intl (CNX)' },
  { code:'HKT', name:'Phuket Intl',                       city:'Phuket',           country:'Thailand',     displayName:'Phuket Intl (HKT)' },
  { code:'MNL', name:'Ninoy Aquino Intl',                 city:'Manila',           country:'Filipina',     displayName:'Ninoy Aquino Intl (MNL)' },
  { code:'CEB', name:'Mactan-Cebu Intl',                  city:'Cebu',             country:'Filipina',     displayName:'Mactan-Cebu Intl (CEB)' },
  { code:'SGN', name:'Tan Son Nhat Intl',                 city:'Ho Chi Minh City', country:'Vietnam',      displayName:'Tan Son Nhat Intl (SGN)' },
  { code:'HAN', name:'Noi Bai Intl',                      city:'Hanoi',            country:'Vietnam',      displayName:'Noi Bai Intl (HAN)' },
  { code:'DAD', name:'Da Nang Intl',                      city:'Da Nang',          country:'Vietnam',      displayName:'Da Nang Intl (DAD)' },
  { code:'RGN', name:'Yangon Intl',                       city:'Yangon',           country:'Myanmar',      displayName:'Yangon Intl (RGN)' },
  { code:'PNH', name:'Phnom Penh Intl',                   city:'Phnom Penh',       country:'Kamboja',      displayName:'Phnom Penh Intl (PNH)' },
  { code:'VTE', name:'Wattay Intl',                       city:'Vientiane',        country:'Laos',         displayName:'Wattay Intl (VTE)' },
  { code:'BWN', name:'Brunei Intl',                       city:'Bandar Seri Begawan', country:'Brunei',    displayName:'Brunei Intl (BWN)' },
  // ── Asia Selatan ───────────────────────────────────────────────────────────
  { code:'DEL', name:'Indira Gandhi Intl',                city:'New Delhi',        country:'India',        displayName:'Indira Gandhi Intl (DEL)' },
  { code:'BOM', name:'Chhatrapati Shivaji Maharaj Intl',  city:'Mumbai',           country:'India',        displayName:'Chhatrapati Shivaji Maharaj Intl (BOM)' },
  { code:'MAA', name:'Chennai Intl',                      city:'Chennai',          country:'India',        displayName:'Chennai Intl (MAA)' },
  { code:'BLR', name:'Kempegowda Intl',                   city:'Bangalore',        country:'India',        displayName:'Kempegowda Intl (BLR)' },
  { code:'HYD', name:'Rajiv Gandhi Intl',                 city:'Hyderabad',        country:'India',        displayName:'Rajiv Gandhi Intl (HYD)' },
  { code:'CCU', name:'Netaji Subhas Chandra Bose Intl',   city:'Kolkata',          country:'India',        displayName:'Netaji Subhas Chandra Bose Intl (CCU)' },
  { code:'COK', name:'Cochin Intl',                       city:'Kochi',            country:'India',        displayName:'Cochin Intl (COK)' },
  { code:'CMB', name:'Bandaranaike Intl',                 city:'Colombo',          country:'Sri Lanka',    displayName:'Bandaranaike Intl (CMB)' },
  { code:'DAC', name:'Hazrat Shahjalal Intl',             city:'Dhaka',            country:'Bangladesh',   displayName:'Hazrat Shahjalal Intl (DAC)' },
  { code:'KTM', name:'Tribhuvan Intl',                    city:'Kathmandu',        country:'Nepal',        displayName:'Tribhuvan Intl (KTM)' },
  // ── Asia Timur ─────────────────────────────────────────────────────────────
  { code:'HKG', name:'Hong Kong Intl',                    city:'Hong Kong',        country:'Hong Kong',    displayName:'Hong Kong Intl (HKG)' },
  { code:'NRT', name:'Narita Intl',                       city:'Tokyo',            country:'Jepang',       displayName:'Narita Intl (NRT)' },
  { code:'HND', name:'Haneda Intl',                       city:'Tokyo',            country:'Jepang',       displayName:'Haneda Intl (HND)' },
  { code:'KIX', name:'Kansai Intl',                       city:'Osaka',            country:'Jepang',       displayName:'Kansai Intl (KIX)' },
  { code:'ITM', name:'Itami',                             city:'Osaka',            country:'Jepang',       displayName:'Itami (ITM)' },
  { code:'NGO', name:'Chubu Centrair Intl',               city:'Nagoya',           country:'Jepang',       displayName:'Chubu Centrair Intl (NGO)' },
  { code:'CTS', name:'New Chitose',                       city:'Sapporo',          country:'Jepang',       displayName:'New Chitose (CTS)' },
  { code:'ICN', name:'Incheon Intl',                      city:'Seoul',            country:'Korea Selatan', displayName:'Incheon Intl (ICN)' },
  { code:'GMP', name:'Gimpo Intl',                        city:'Seoul',            country:'Korea Selatan', displayName:'Gimpo Intl (GMP)' },
  { code:'PEK', name:'Beijing Capital Intl',              city:'Beijing',          country:'Tiongkok',     displayName:'Beijing Capital Intl (PEK)' },
  { code:'PKX', name:'Beijing Daxing Intl',               city:'Beijing',          country:'Tiongkok',     displayName:'Beijing Daxing Intl (PKX)' },
  { code:'PVG', name:'Pudong Intl',                       city:'Shanghai',         country:'Tiongkok',     displayName:'Pudong Intl (PVG)' },
  { code:'SHA', name:'Hongqiao Intl',                     city:'Shanghai',         country:'Tiongkok',     displayName:'Hongqiao Intl (SHA)' },
  { code:'CAN', name:'Baiyun Intl',                       city:'Guangzhou',        country:'Tiongkok',     displayName:'Baiyun Intl (CAN)' },
  { code:'SZX', name:"Bao'an Intl",                       city:'Shenzhen',         country:'Tiongkok',     displayName:"Bao'an Intl (SZX)" },
  { code:'CTU', name:'Tianfu Intl',                       city:'Chengdu',          country:'Tiongkok',     displayName:'Tianfu Intl (CTU)' },
  { code:'XIY', name:'Xianyang Intl',                     city:"Xi'an",            country:'Tiongkok',     displayName:"Xianyang Intl (XIY)" },
  { code:'WUH', name:'Tianhe Intl',                       city:'Wuhan',            country:'Tiongkok',     displayName:'Tianhe Intl (WUH)' },
  { code:'KMG', name:'Changshui Intl',                    city:'Kunming',          country:'Tiongkok',     displayName:'Changshui Intl (KMG)' },
  { code:'TPE', name:'Taoyuan Intl',                      city:'Taipei',           country:'Taiwan',       displayName:'Taoyuan Intl (TPE)' },
  { code:'TSA', name:'Songshan',                          city:'Taipei',           country:'Taiwan',       displayName:'Songshan (TSA)' },
  { code:'MFM', name:'Macau Intl',                        city:'Macau',            country:'Macau',        displayName:'Macau Intl (MFM)' },
  // ── Timur Tengah ───────────────────────────────────────────────────────────
  { code:'DXB', name:'Dubai Intl',                        city:'Dubai',            country:'UAE',          displayName:'Dubai Intl (DXB)' },
  { code:'AUH', name:'Abu Dhabi Intl',                    city:'Abu Dhabi',        country:'UAE',          displayName:'Abu Dhabi Intl (AUH)' },
  { code:'SHJ', name:'Sharjah Intl',                      city:'Sharjah',          country:'UAE',          displayName:'Sharjah Intl (SHJ)' },
  { code:'DOH', name:'Hamad Intl',                        city:'Doha',             country:'Qatar',        displayName:'Hamad Intl (DOH)' },
  { code:'BAH', name:'Bahrain Intl',                      city:'Manama',           country:'Bahrain',      displayName:'Bahrain Intl (BAH)' },
  { code:'KWI', name:'Kuwait Intl',                       city:'Kuwait City',      country:'Kuwait',       displayName:'Kuwait Intl (KWI)' },
  { code:'MCT', name:'Muscat Intl',                       city:'Muscat',           country:'Oman',         displayName:'Muscat Intl (MCT)' },
  { code:'RUH', name:'King Khalid Intl',                  city:'Riyadh',           country:'Arab Saudi',   displayName:'King Khalid Intl (RUH)' },
  { code:'JED', name:'King Abdulaziz Intl',               city:'Jeddah',           country:'Arab Saudi',   displayName:'King Abdulaziz Intl (JED)' },
  { code:'MED', name:'Prince Mohammad Bin Abdulaziz',     city:'Madinah',          country:'Arab Saudi',   displayName:'Prince Mohammad Bin Abdulaziz (MED)' },
  { code:'AMM', name:'Queen Alia Intl',                   city:'Amman',            country:'Yordania',     displayName:'Queen Alia Intl (AMM)' },
  { code:'BEY', name:'Rafic Hariri Intl',                 city:'Beirut',           country:'Lebanon',      displayName:'Rafic Hariri Intl (BEY)' },
  { code:'CAI', name:'Cairo Intl',                        city:'Kairo',            country:'Mesir',        displayName:'Cairo Intl (CAI)' },
  // ── Turki ──────────────────────────────────────────────────────────────────
  { code:'IST', name:'Istanbul Airport',                  city:'Istanbul',         country:'Turki',        displayName:'Istanbul Airport (IST)' },
  { code:'SAW', name:'Istanbul Sabiha Gökçen',            city:'Istanbul',         country:'Turki',        displayName:'Istanbul Sabiha Gökçen (SAW)' },
  { code:'AYT', name:'Antalya Intl',                      city:'Antalya',          country:'Turki',        displayName:'Antalya Intl (AYT)' },
  { code:'ADB', name:'Izmir Adnan Menderes Intl',         city:'Izmir',            country:'Turki',        displayName:'Izmir Adnan Menderes Intl (ADB)' },
  // ── Eropa ──────────────────────────────────────────────────────────────────
  { code:'LHR', name:'Heathrow',                          city:'London',           country:'Inggris',      displayName:'Heathrow (LHR)' },
  { code:'LGW', name:'Gatwick',                           city:'London',           country:'Inggris',      displayName:'Gatwick (LGW)' },
  { code:'STN', name:'Stansted',                          city:'London',           country:'Inggris',      displayName:'Stansted (STN)' },
  { code:'CDG', name:'Charles de Gaulle',                 city:'Paris',            country:'Prancis',      displayName:'Charles de Gaulle (CDG)' },
  { code:'ORY', name:'Orly',                              city:'Paris',            country:'Prancis',      displayName:'Orly (ORY)' },
  { code:'AMS', name:'Schiphol',                          city:'Amsterdam',        country:'Belanda',      displayName:'Schiphol (AMS)' },
  { code:'FRA', name:'Frankfurt Intl',                    city:'Frankfurt',        country:'Jerman',       displayName:'Frankfurt Intl (FRA)' },
  { code:'MUC', name:'Munich Intl',                       city:'Munich',           country:'Jerman',       displayName:'Munich Intl (MUC)' },
  { code:'ZRH', name:'Zürich Intl',                       city:'Zürich',           country:'Swiss',        displayName:'Zürich Intl (ZRH)' },
  { code:'VIE', name:'Vienna Intl',                       city:'Vienna',           country:'Austria',      displayName:'Vienna Intl (VIE)' },
  { code:'BRU', name:'Brussels Intl',                     city:'Brussels',         country:'Belgia',       displayName:'Brussels Intl (BRU)' },
  { code:'FCO', name:'Leonardo da Vinci Intl',            city:'Roma',             country:'Italia',       displayName:'Leonardo da Vinci Intl (FCO)' },
  { code:'MXP', name:'Malpensa Intl',                     city:'Milan',            country:'Italia',       displayName:'Malpensa Intl (MXP)' },
  { code:'MAD', name:'Barajas Intl',                      city:'Madrid',           country:'Spanyol',      displayName:'Barajas Intl (MAD)' },
  { code:'BCN', name:'Barcelona–El Prat',                 city:'Barcelona',        country:'Spanyol',      displayName:'Barcelona–El Prat (BCN)' },
  { code:'LIS', name:'Humberto Delgado Intl',             city:'Lisbon',           country:'Portugal',     displayName:'Humberto Delgado Intl (LIS)' },
  { code:'ARN', name:'Stockholm Arlanda',                 city:'Stockholm',        country:'Swedia',       displayName:'Stockholm Arlanda (ARN)' },
  { code:'CPH', name:'Copenhagen Intl',                   city:'Kopenhagen',       country:'Denmark',      displayName:'Copenhagen Intl (CPH)' },
  { code:'OSL', name:'Oslo Gardermoen Intl',              city:'Oslo',             country:'Norwegia',     displayName:'Oslo Gardermoen Intl (OSL)' },
  { code:'HEL', name:'Helsinki-Vantaa Intl',              city:'Helsinki',         country:'Finlandia',    displayName:'Helsinki-Vantaa Intl (HEL)' },
  { code:'DUB', name:'Dublin Intl',                       city:'Dublin',           country:'Irlandia',     displayName:'Dublin Intl (DUB)' },
  { code:'ATH', name:'Eleftherios Venizelos Intl',        city:'Athena',           country:'Yunani',       displayName:'Eleftherios Venizelos Intl (ATH)' },
  { code:'WAW', name:'Chopin Intl',                       city:'Warsawa',          country:'Polandia',     displayName:'Chopin Intl (WAW)' },
  { code:'PRG', name:'Václav Havel Intl',                 city:'Praha',            country:'Ceko',         displayName:'Václav Havel Intl (PRG)' },
  { code:'BUD', name:'Budapest Ferenc Liszt Intl',        city:'Budapest',         country:'Hungaria',     displayName:'Budapest Ferenc Liszt Intl (BUD)' },
  { code:'SVO', name:'Sheremetyevo Intl',                 city:'Moskow',           country:'Rusia',        displayName:'Sheremetyevo Intl (SVO)' },
  { code:'DME', name:'Domodedovo Intl',                   city:'Moskow',           country:'Rusia',        displayName:'Domodedovo Intl (DME)' },
  // ── Afrika ─────────────────────────────────────────────────────────────────
  { code:'JNB', name:'O.R. Tambo Intl',                   city:'Johannesburg',     country:'Afrika Selatan', displayName:'O.R. Tambo Intl (JNB)' },
  { code:'CPT', name:'Cape Town Intl',                    city:'Cape Town',        country:'Afrika Selatan', displayName:'Cape Town Intl (CPT)' },
  { code:'NBO', name:'Jomo Kenyatta Intl',                city:'Nairobi',          country:'Kenya',        displayName:'Jomo Kenyatta Intl (NBO)' },
  { code:'ADD', name:'Addis Ababa Bole Intl',             city:'Addis Ababa',      country:'Ethiopia',     displayName:'Addis Ababa Bole Intl (ADD)' },
  { code:'LOS', name:'Murtala Muhammed Intl',             city:'Lagos',            country:'Nigeria',      displayName:'Murtala Muhammed Intl (LOS)' },
  { code:'CMN', name:'Mohammed V Intl',                   city:'Casablanca',       country:'Maroko',       displayName:'Mohammed V Intl (CMN)' },
  // ── Australia & Pasifik ────────────────────────────────────────────────────
  { code:'SYD', name:'Kingsford Smith Intl',              city:'Sydney',           country:'Australia',    displayName:'Kingsford Smith Intl (SYD)' },
  { code:'MEL', name:'Melbourne Tullamarine Intl',        city:'Melbourne',        country:'Australia',    displayName:'Melbourne Tullamarine Intl (MEL)' },
  { code:'BNE', name:'Brisbane Intl',                     city:'Brisbane',         country:'Australia',    displayName:'Brisbane Intl (BNE)' },
  { code:'PER', name:'Perth Intl',                        city:'Perth',            country:'Australia',    displayName:'Perth Intl (PER)' },
  { code:'ADL', name:'Adelaide Intl',                     city:'Adelaide',         country:'Australia',    displayName:'Adelaide Intl (ADL)' },
  { code:'DRW', name:'Darwin Intl',                       city:'Darwin',           country:'Australia',    displayName:'Darwin Intl (DRW)' },
  { code:'AKL', name:'Auckland Intl',                     city:'Auckland',         country:'Selandia Baru', displayName:'Auckland Intl (AKL)' },
  { code:'CHC', name:'Christchurch Intl',                 city:'Christchurch',     country:'Selandia Baru', displayName:'Christchurch Intl (CHC)' },
  { code:'NAN', name:'Nadi Intl',                         city:'Nadi',             country:'Fiji',         displayName:'Nadi Intl (NAN)' },
  { code:'GUM', name:'A.B. Won Pat Intl',                 city:'Guam',             country:'Guam',         displayName:'A.B. Won Pat Intl (GUM)' },
  // ── Amerika Utara ──────────────────────────────────────────────────────────
  { code:'JFK', name:'John F. Kennedy Intl',              city:'New York',         country:'Amerika Serikat', displayName:'John F. Kennedy Intl (JFK)' },
  { code:'EWR', name:'Newark Liberty Intl',               city:'New York',         country:'Amerika Serikat', displayName:'Newark Liberty Intl (EWR)' },
  { code:'LGA', name:'LaGuardia',                         city:'New York',         country:'Amerika Serikat', displayName:'LaGuardia (LGA)' },
  { code:'LAX', name:'Los Angeles Intl',                  city:'Los Angeles',      country:'Amerika Serikat', displayName:'Los Angeles Intl (LAX)' },
  { code:'SFO', name:'San Francisco Intl',                city:'San Francisco',    country:'Amerika Serikat', displayName:'San Francisco Intl (SFO)' },
  { code:'ORD', name:"O'Hare Intl",                       city:'Chicago',          country:'Amerika Serikat', displayName:"O'Hare Intl (ORD)" },
  { code:'ATL', name:'Hartsfield-Jackson Intl',           city:'Atlanta',          country:'Amerika Serikat', displayName:'Hartsfield-Jackson Intl (ATL)' },
  { code:'DFW', name:'Dallas/Fort Worth Intl',            city:'Dallas',           country:'Amerika Serikat', displayName:'Dallas/Fort Worth Intl (DFW)' },
  { code:'DEN', name:'Denver Intl',                       city:'Denver',           country:'Amerika Serikat', displayName:'Denver Intl (DEN)' },
  { code:'SEA', name:'Seattle-Tacoma Intl',               city:'Seattle',          country:'Amerika Serikat', displayName:'Seattle-Tacoma Intl (SEA)' },
  { code:'MIA', name:'Miami Intl',                        city:'Miami',            country:'Amerika Serikat', displayName:'Miami Intl (MIA)' },
  { code:'BOS', name:'Logan Intl',                        city:'Boston',           country:'Amerika Serikat', displayName:'Logan Intl (BOS)' },
  { code:'IAD', name:'Dulles Intl',                       city:'Washington D.C.',  country:'Amerika Serikat', displayName:'Dulles Intl (IAD)' },
  { code:'DCA', name:'Ronald Reagan Washington Natl',     city:'Washington D.C.',  country:'Amerika Serikat', displayName:'Ronald Reagan Washington Natl (DCA)' },
  { code:'LAS', name:'Harry Reid Intl',                   city:'Las Vegas',        country:'Amerika Serikat', displayName:'Harry Reid Intl (LAS)' },
  { code:'HNL', name:'Daniel K. Inouye Intl',             city:'Honolulu',         country:'Amerika Serikat', displayName:'Daniel K. Inouye Intl (HNL)' },
  { code:'YYZ', name:'Toronto Pearson Intl',              city:'Toronto',          country:'Kanada',       displayName:'Toronto Pearson Intl (YYZ)' },
  { code:'YVR', name:'Vancouver Intl',                    city:'Vancouver',        country:'Kanada',       displayName:'Vancouver Intl (YVR)' },
  { code:'YUL', name:'Montréal-Trudeau Intl',             city:'Montréal',         country:'Kanada',       displayName:'Montréal-Trudeau Intl (YUL)' },
  { code:'MEX', name:'Benito Juárez Intl',                city:'Mexico City',      country:'Meksiko',      displayName:'Benito Juárez Intl (MEX)' },
  // ── Amerika Selatan ────────────────────────────────────────────────────────
  { code:'GRU', name:'São Paulo/Guarulhos Intl',          city:'São Paulo',        country:'Brasil',       displayName:'São Paulo/Guarulhos Intl (GRU)' },
  { code:'EZE', name:'Ministro Pistarini Intl',           city:'Buenos Aires',     country:'Argentina',    displayName:'Ministro Pistarini Intl (EZE)' },
  { code:'BOG', name:'El Dorado Intl',                    city:'Bogota',           country:'Kolombia',     displayName:'El Dorado Intl (BOG)' },
  { code:'LIM', name:'Jorge Chávez Intl',                 city:'Lima',             country:'Peru',         displayName:'Jorge Chávez Intl (LIM)' },
  { code:'SCL', name:'Arturo Merino Benítez Intl',        city:'Santiago',         country:'Chili',        displayName:'Arturo Merino Benítez Intl (SCL)' },
];

@Injectable({ providedIn: 'root' })
export class FlightSearchService {
  private http = inject(HttpClient);
  private base = environment.apiUrl;

  /**
   * Panggil endpoint pencarian. Backend akan pilih Duffel dulu, fallback ke Travelpayouts.
   * Return legacy shape (FlightResult[]) supaya komponen lama tetap kompatibel.
   * Untuk info bookable/redirect_link gunakan {@link searchFlightsFull}.
   */
  searchFlights(params: {
    origin: string;
    destination: string;
    departure_date: string;
    return_date?: string;
    adults: number;
    children?: number;
    infants?: number;
    seat_class?: string;
  }): Observable<FlightResult[]> {
    return this.searchFlightsFull(params).pipe(map(res => res.data));
  }

  /**
   * Versi lengkap: kembalikan envelope {source, bookable, data, redirect_link}
   * sehingga komponen bisa memilih tombol "Booking Sekarang" vs "Lihat & Beli".
   */
  searchFlightsFull(params: {
    origin: string;
    destination: string;
    departure_date: string;
    return_date?: string;
    adults: number;
    children?: number;
    infants?: number;
    seat_class?: string;
  }): Observable<FlightSearchResponse> {
    let httpParams = new HttpParams()
      .set('origin', params.origin)
      .set('destination', params.destination)
      .set('departure_date', params.departure_date)
      .set('adults', params.adults);

    if (params.return_date) httpParams = httpParams.set('return_date', params.return_date);
    if (params.children)    httpParams = httpParams.set('children', params.children);
    if (params.infants)     httpParams = httpParams.set('infants', params.infants);
    if (params.seat_class)  httpParams = httpParams.set('seat_class', params.seat_class);

    return this.http.get<FlightSearchResponse>(
      `${this.base}/flights/search`,
      { params: httpParams }
    );
  }

  /**
   * Batch fetch harga termurah per-tanggal untuk date strip.
   * Satu HTTP call — backend fetch semua tanggal secara paralel dari TP.
   */
  getPriceStrip(
    origin: string,
    destination: string,
    dateFrom: string,
    dateTo: string,
    seatClass: string = 'Economy'
  ): Observable<Record<string, { price: number; available: boolean }>> {
    return this.http.get<{ data: Record<string, { price: number; available: boolean }> }>(
      `${this.base}/flights/price-strip`,
      { params: { origin, destination, date_from: dateFrom, date_to: dateTo, seat_class: seatClass } }
    ).pipe(
      map(res => res.data ?? {}),
      catchError(() => of({}))
    );
  }

  /** Harga termurah untuk 1 tanggal spesifik — ringan, untuk date strip. */
  getPriceCheck(
    origin: string,
    destination: string,
    date: string,
    seatClass: string = 'Economy'
  ): Observable<{ date: string; price: number }> {
    return this.http.get<{ date: string; price: number }>(
      `${this.base}/flights/price-check`,
      { params: { origin, destination, date, seat_class: seatClass } }
    ).pipe(catchError(() => of({ date, price: 0 })));
  }

  /** Harga termurah per-tanggal untuk satu bulan (date strip). */
  getCalendarPrices(
    origin: string,
    destination: string,
    yearMonth: string,
    seatClass: string = 'Economy'
  ): Observable<Record<string, number>> {
    return this.http.get<{ data: Record<string, number> }>(
      `${this.base}/flights/calendar`,
      { params: { origin, destination, year_month: yearMonth, seat_class: seatClass } }
    ).pipe(
      map(res => res.data ?? {}),
      catchError(() => of({}))
    );
  }

  searchAirports(term: string): Observable<AirportOption[]> {
    const q = term.toLowerCase().trim();
    if (!q) return of([]);

    // 1) Cari di local database dulu — selalu tersedia, tanpa network
    const localMatches = LOCAL_AIRPORTS.filter(a =>
      a.code.toLowerCase().includes(q) ||
      a.name.toLowerCase().includes(q) ||
      a.city.toLowerCase().includes(q) ||
      a.country.toLowerCase().includes(q)
    )
    // Indonesia selalu di atas agar user tidak salah pilih (mis. DPS vs DEN)
    .sort((a, b) => {
      const aID = a.country === 'Indonesia' ? 0 : 1;
      const bID = b.country === 'Indonesia' ? 0 : 1;
      return aID - bID;
    })
    .slice(0, 8);

    // 2) Jika lokal sudah cukup (≥3 hasil), langsung kembalikan tanpa hit API
    if (localMatches.length >= 3) {
      return of(localMatches);
    }

    // 3) Fallback ke Travelpayouts untuk melengkapi hasil (misal typo atau alias nama kota)
    return this.http.get<any[]>('https://autocomplete.travelpayouts.com/places2', {
      params: { term, locale: 'id', 'types[]': 'airport' },
    }).pipe(
      map(items => {
        const existingCodes = new Set(localMatches.map(a => a.code));
        const apiMatches = items
          .filter(i => i.code && !existingCodes.has(i.code))
          .map(i => ({
            code:        i.code as string,
            name:        (i.name ?? '') as string,
            city:        (i.main_airport_name ?? i.city_name ?? '') as string,
            country:     (i.country_name ?? '') as string,
            displayName: `${i.name ?? ''} (${i.code ?? ''})`,
          }))
          .slice(0, 5);
        return [...localMatches, ...apiMatches];
      }),
      catchError(() => of(localMatches)),
    );
  }
}
