export interface FlightSearchParams {
  origin: string;
  destination: string;
  departureDate: string;
  returnDate?: string;
  adults: number;
  children?: number;
  infants?: number;
}

export interface FlightResult {
  id: string;
  airline: string;
  flightNumber: string;
  origin: string;
  destination: string;
  departureTime: string;
  arrivalTime: string;
  duration: string;
  transitCount: number;
  price: number;
  currency: string;
  bookingClass: string;
  /** true = Duffel (bisa langsung booking); false = Travelpayouts (redirect ke partner) */
  bookable?: boolean;
  /** Segment asli dari Duffel — dipakai untuk timeline transit yang akurat */
  segments?: FlightSegment[];
  raw: unknown;
}

export interface FlightSegment {
  origin: string;
  destination: string;
  departing_at: string | null;
  arriving_at: string | null;
  flight_number: string;
  airline: string;
}

export type FlightSource = 'duffel' | 'travelpayouts';

export interface FlightSearchResponse {
  source: FlightSource;
  bookable: boolean;
  data: FlightResult[];
  date_prices?: Record<string, number>;
  redirect_link?: string | null;
}

export interface FlightPassenger {
  title: 'Mr' | 'Mrs' | 'Ms';
  full_name: string;
  date_of_birth: string;
  id_type: 'KTP' | 'Passport';
  id_number: string;
  phone: string;
  email: string;
  passenger_type: 'Adult' | 'Child' | 'Infant';
}

export interface AirportOption {
  code: string;
  name: string;
  city: string;
  country: string;
  displayName: string;
}
