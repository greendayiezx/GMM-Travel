<?php

namespace Database\Factories;

use App\Models\Vehicle;
use Illuminate\Database\Eloquent\Factories\Factory;

class VehicleFactory extends Factory
{
    protected $model = Vehicle::class;

    public function definition(): array
    {
        return [
            'name' => 'Toyota HiAce ' . $this->faker->word(),
            'license_plate' => strtoupper($this->faker->bothify('? #### ??')),
            'type' => 'COMMUTER',
            'capacity' => 15,
            'is_active' => true,
        ];
    }
}
