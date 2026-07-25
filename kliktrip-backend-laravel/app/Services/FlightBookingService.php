<?php

namespace App\Services;

use App\Models\FlightBooking;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class FlightBookingService
{
    public function createFlightBooking(
        ?int $userId,
        array $flightData,
        array $passengersData,
        float $totalAmount
    ): FlightBooking {
        return DB::transaction(function () use ($userId, $flightData, $passengersData, $totalAmount) {
            $bookingCode = 'FLT-' . strtoupper(Str::random(10));

            $booking = FlightBooking::create([
                'user_id'      => $userId,
                'booking_code' => $bookingCode,
                'flight_data'  => $flightData,
                'total_amount' => $totalAmount,
                'status'       => 'PENDING',
            ]);

            foreach ($passengersData as $p) {
                $booking->flightPassengers()->create([
                    'title'          => $p['title'],
                    'full_name'      => $p['full_name'],
                    'date_of_birth'  => $p['date_of_birth'],
                    'id_type'        => $p['id_type'],
                    'id_number'      => $p['id_number'],
                    'phone'          => $p['phone'],
                    'email'          => $p['email'],
                    'passenger_type' => $p['passenger_type'],
                ]);
            }

            return $booking->load('flightPassengers');
        });
    }
}
