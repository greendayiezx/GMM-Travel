<?php

namespace App\Http\Controllers;

use App\Models\TravelBooking;
use App\Models\TravelSchedule;

class TravelScheduleController extends Controller
{
    // Total kursi minivan (sesuai layout seat map)
    const TOTAL_SEATS = 14;

    public function seats(string $scheduleId)
    {
        // Lempar 404 jika schedule tidak ditemukan
        TravelSchedule::findOrFail($scheduleId);

        // Kumpulkan seat_number dari penumpang pada booking yang masih aktif
        // (PENDING = belum bayar tapi kursi di-hold, PAID = sudah lunas)
        $bookedSeats = TravelBooking::where('travel_schedule_id', $scheduleId)
            ->whereIn('status', ['PENDING', 'PAID'])
            ->with('travelPassengers:travel_booking_id,seat_number')
            ->get()
            ->flatMap(fn($booking) => $booking->travelPassengers->pluck('seat_number'))
            ->filter()
            ->unique()
            ->values()
            ->all();

        return response()->json([
            'total_seats'     => self::TOTAL_SEATS,
            'booked_seats'    => $bookedSeats,
            'available_seats' => self::TOTAL_SEATS - count($bookedSeats),
        ]);
    }
}
