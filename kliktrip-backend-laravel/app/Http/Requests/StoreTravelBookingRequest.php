<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreTravelBookingRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'travel_schedule_id' => ['required', 'uuid', 'exists:travel_schedules,id'],
            'passengers' => ['required', 'array', 'min:1'],
            'passengers.*.name' => ['required', 'string', 'max:255'],
            'passengers.*.seat_number' => ['required', 'string', 'max:10'],
            'passengers.*.identity_number' => ['required', 'string', 'max:50'],
        ];
    }

    public function messages(): array
    {
        return [
            'travel_schedule_id.required' => 'Jadwal perjalanan wajib dipilih.',
            'travel_schedule_id.exists' => 'Jadwal perjalanan tidak valid.',
            'passengers.required' => 'Data penumpang wajib diisi.',
            'passengers.*.name.required' => 'Nama penumpang wajib diisi.',
            'passengers.*.seat_number.required' => 'Nomor kursi wajib dipilih.',
            'passengers.*.identity_number.required' => 'Nomor identitas (KTP/Passport) wajib diisi.',
        ];
    }
}
