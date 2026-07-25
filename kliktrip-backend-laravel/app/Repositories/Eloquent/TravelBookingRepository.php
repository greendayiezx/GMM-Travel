<?php

namespace App\Repositories\Eloquent;

use App\Models\TravelBooking;
use App\Repositories\Contracts\TravelBookingRepositoryInterface;

class TravelBookingRepository extends BaseRepository implements TravelBookingRepositoryInterface
{
    public function __construct(TravelBooking $model)
    {
        parent::__construct($model);
    }

    public function findByBookingCode(string $code): ?TravelBooking
    {
        return $this->model->where('booking_code', $code)->with(['travelSchedule.travelRoute', 'travelPassengers', 'payment'])->first();
    }

    public function getUserBookings(string $userId)
    {
        return $this->model->where('user_id', $userId)->with(['travelSchedule.travelRoute', 'payment'])->get();
    }
}
