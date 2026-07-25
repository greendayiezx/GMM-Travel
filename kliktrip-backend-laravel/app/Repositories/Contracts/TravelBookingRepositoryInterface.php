<?php

namespace App\Repositories\Contracts;

use App\Models\TravelBooking;

interface TravelBookingRepositoryInterface extends BaseRepositoryInterface
{
    public function findByBookingCode(string $code): ?TravelBooking;

    public function getUserBookings(string $userId);
}
