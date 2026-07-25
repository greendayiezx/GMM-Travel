<?php

namespace App\Services;

use App\Repositories\Contracts\TravelBookingRepositoryInterface;
use App\Models\TravelSchedule;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Exception;

class BookingService
{
    protected TravelBookingRepositoryInterface $bookingRepository;

    public function __construct(TravelBookingRepositoryInterface $bookingRepository)
    {
        $this->bookingRepository = $bookingRepository;
    }

    /**
     * Create a new travel booking.
     */
    public function createTravelBooking(string $userId, string $scheduleId, array $passengersData): mixed
    {
        return DB::transaction(function () use ($userId, $scheduleId, $passengersData) {
            $schedule = TravelSchedule::findOrFail($scheduleId);
            $passengerCount = count($passengersData);

            if ($schedule->available_seats < $passengerCount) {
                throw new Exception("Sisa kursi tidak mencukupi untuk pemesanan ini.");
            }

            // Generate unique booking code
            $bookingCode = 'TRV-' . strtoupper(Str::random(10));

            // Calculate total amount
            $totalAmount = $schedule->price * $passengerCount;

            // Create booking
            $booking = $this->bookingRepository->create([
                'user_id' => $userId,
                'travel_schedule_id' => $scheduleId,
                'booking_code' => $bookingCode,
                'total_amount' => $totalAmount,
                'status' => 'PENDING',
            ]);

            // Create passengers & assign seats
            foreach ($passengersData as $passenger) {
                $booking->travelPassengers()->create([
                    'name' => $passenger['name'],
                    'seat_number' => $passenger['seat_number'],
                    'identity_number' => $passenger['identity_number'],
                ]);
            }

            // Deduct available seats
            $schedule->available_seats -= $passengerCount;
            $schedule->save();

            return $booking->load(['travelPassengers', 'travelSchedule.travelRoute']);
        });
    }
}
