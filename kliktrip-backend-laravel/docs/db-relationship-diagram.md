# Database Relationship Diagram - GMM Travel

Below is the entity-relationship diagram for the production-ready database schema of GMM Travel, constructed with Laravel 12 migration relationships.

## Entity Relationship Diagram (Mermaid)

```mermaid
erDiagram
    ROLE ||--o{ USER : "has"
    PROVINCE ||--o{ CITY : "contains"
    CITY ||--o{ TRAVEL_ROUTE : "departure"
    CITY ||--o{ TRAVEL_ROUTE : "arrival"
    
    VEHICLE ||--o{ TRAVEL_SCHEDULE : "allocated_to"
    DRIVER ||--o{ TRAVEL_SCHEDULE : "drives"
    TRAVEL_ROUTE ||--o{ TRAVEL_SCHEDULE : "defines"
    
    TRAVEL_SCHEDULE ||--o{ TRAVEL_BOOKING : "has"
    USER ||--o{ TRAVEL_BOOKING : "makes"
    TRAVEL_BOOKING ||--o{ TRAVEL_PASSENGER : "contains"
    
    TOUR_CATEGORY ||--o{ TOUR_PACKAGE : "classifies"
    TOUR_PACKAGE ||--o{ TOUR_IMAGE : "has"
    TOUR_PACKAGE ||--o{ TOUR_ITINERARY : "details"
    TOUR_PACKAGE ||--o{ TOUR_SCHEDULE : "schedules"
    
    TOUR_SCHEDULE ||--o{ TOUR_BOOKING : "has"
    USER ||--o{ TOUR_BOOKING : "makes"
    TOUR_BOOKING ||--o{ TOUR_PARTICIPANT : "contains"

    USER ||--o{ NOTIFICATION : "receives"
    USER ||--o{ NOTIFICATION_LOG : "logs"

    USER ||--o{ REVIEW : "writes"
    USER ||--o{ FAVORITE : "adds"

    USER ||--o{ ARTICLE : "writes"

    %% Polymorphic Relations
    TRAVEL_BOOKING ||--o| PAYMENT : "payable (polymorphic)"
    TOUR_BOOKING ||--o| PAYMENT : "payable (polymorphic)"
    PAYMENT ||--o{ PAYMENT_LOG : "logs"

    VOUCHER ||--o{ VOUCHER_USAGE : "applies"
    USER ||--o{ VOUCHER_USAGE : "uses"
    TRAVEL_BOOKING ||--o{ VOUCHER_USAGE : "usable (polymorphic)"
    TOUR_BOOKING ||--o{ VOUCHER_USAGE : "usable (polymorphic)"

    TOUR_PACKAGE ||--o{ REVIEW : "reviewable (polymorphic)"
    TRAVEL_ROUTE ||--o{ REVIEW : "reviewable (polymorphic)"

    TOUR_PACKAGE ||--o{ FAVORITE : "favoritable (polymorphic)"
```

## Schema Details

### Master Data Layer
*   **Users & Roles**: Admin, User, and Driver roles are defined. Users use UUID as primary key and relate to roles.
*   **Location**: System uses Provinces and Cities to locate destinations and define travel routes.
*   **Logistics**: Vehicles (like Toyota Hiace Commuter/Premio) and Drivers are managed separately for scheduling.

### Travel Layer (Point-to-Point Booking)
*   **Travel Route**: Links departure city and arrival city with distance and duration details.
*   **Travel Schedule**: Connects a vehicle, route, and driver to a specific departure and arrival time.
*   **Travel Booking**: Standard booking schema with soft deletes, unique booking codes, and list of passengers.

### Tour Layer (Package Tourism)
*   **Tour Package**: Curated trip details with description, meeting point, inclusions/exclusions, terms, and itineraries.
*   **Tour Schedule**: Specific batch departures for a package.
*   **Tour Booking**: Booking records for specific slots with participant lists.

### Payment Layer (Transactions & Promotion)
*   **Payment**: Uses polymorphic `payable` relation to links to both `TravelBooking` and `TourBooking`. Incorporates invoice number, gateway indicators (Midtrans/Xendit), snap tokens, transaction states, and timestamps.
*   **Voucher & VoucherUsage**: Promo logic that tracks usage linked to user and specific bookings polymorphically.
