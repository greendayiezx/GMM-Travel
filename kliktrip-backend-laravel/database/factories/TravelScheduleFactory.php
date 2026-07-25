<?php

namespace Database\Factories;

use App\Models\TravelSchedule;
use App\Models\Vehicle;
use App\Models\TravelRoute;
use App\Models\Driver;
use Illuminate\Database\Eloquent\Factories\Factory;

class TravelScheduleFactory extends Factory
{
    protected $model = TravelSchedule::class;

    public function definition(): array
    {
        $departure = $this->faker->dateTimeBetween('+1 day', '+1 week');
        $arrival = (clone $departure)->modify('+' . rand(2, 6) . ' hours');

        return [
            'vehicle_id' => Vehicle::factory(),
            'travel_route_id' => TravelRoute::factory(),
            'driver_id' => Driver::factory(),
            'departure_time' => $departure,
            'arrival_time' => $arrival,
            'available_seats' => 15,
            'price' => $this->faker->randomFloat(2, 100000, 300000),
            'status' => 'SCHEDULED',
        ];
    }
}
