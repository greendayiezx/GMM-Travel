<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TravelBookingResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'booking_code' => $this->booking_code,
            'total_amount' => (float) $this->total_amount,
            'status' => $this->status,
            'passengers' => $this->relationLoaded('travelPassengers') 
                ? $this->travelPassengers->map(fn($p) => [
                    'id' => $p->id,
                    'name' => $p->name,
                    'seat_number' => $p->seat_number,
                    'identity_number' => $p->identity_number,
                ])
                : [],
            'schedule' => $this->relationLoaded('travelSchedule') 
                ? [
                    'id' => $this->travelSchedule->id,
                    'departure_time' => $this->travelSchedule->departure_time->toIso8601String(),
                    'arrival_time' => $this->travelSchedule->arrival_time->toIso8601String(),
                    'price' => (float) $this->travelSchedule->price,
                    'route' => $this->travelSchedule->relationLoaded('travelRoute') 
                        ? [
                            'departure_city' => $this->travelSchedule->travelRoute->departureCity?->name,
                            'arrival_city' => $this->travelSchedule->travelRoute->arrivalCity?->name,
                            'distance_km' => $this->travelSchedule->travelRoute->distance_km,
                        ]
                        : null,
                ]
                : null,
            'payment' => $this->relationLoaded('payment') && $this->payment 
                ? [
                    'invoice_number' => $this->payment->invoice_number,
                    'snap_token' => $this->payment->snap_token,
                    'total_amount' => (float) $this->payment->total_amount,
                    'status' => $this->payment->status,
                    'paid_at' => $this->payment->paid_at?->toIso8601String(),
                ]
                : null,
            'created_at' => $this->created_at->toIso8601String(),
        ];
    }
}
