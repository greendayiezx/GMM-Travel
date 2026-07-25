<?php

namespace Database\Factories;

use App\Models\TravelRoute;
use App\Models\City;
use Illuminate\Database\Eloquent\Factories\Factory;

class TravelRouteFactory extends Factory
{
    protected $model = TravelRoute::class;

    public function definition(): array
    {
        return [
            'departure_city_id' => City::factory(),
            'arrival_city_id' => City::factory(),
            'distance_km' => $this->faker->numberBetween(100, 500),
            'duration_minutes' => $this->faker->numberBetween(120, 360),
        ];
    }
}
