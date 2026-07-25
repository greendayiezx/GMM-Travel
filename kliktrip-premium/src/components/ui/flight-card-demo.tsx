import { FlightCard } from "@/components/ui/flight-card";

const FlightCardDemo = () => {
  // Sample data with an image URL for the logo
  const flightData = {
    airline: {
      name: "IndiGo",
      // Replaced the SVG component with a placeholder image URL
      logo: "https://static-assets-ct.flixcart.com/ct/assets/resources/images/logos/air-logos/svg_logos/6E.svg",
      flightNumber: "6E-2195",
    },
    departureTime: "12:45",
    arrivalTime: "20:00",
    duration: "7h 15m",
    stops: 1,
    price: 6916,
    currency: "INR",
    offer: "Get ₹968 off with Axis Cards",
    refundableType: "Partial Refundable",
  };

  // Dummy functions for button actions
  const handleBook = () => {
    alert(`Booking flight ${flightData.airline.flightNumber}...`);
  };

  const handleFlightDetails = () => {
    alert(`Showing details for flight ${flightData.airline.flightNumber}...`);
  };

  return (
    <div className="w-full min-h-[350px] flex items-center justify-center bg-background p-4">
      <FlightCard 
        {...flightData}
        onBook={handleBook}
        onFlightDetails={handleFlightDetails}
      />
    </div>
  );
};

export default FlightCardDemo;
