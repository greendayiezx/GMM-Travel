<?php

namespace App\Http\Controllers;

use App\Models\FlightBooking;
use App\Models\FlightTicketFile;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

class StaffController extends Controller
{
    /**
     * Middleware ringan: cek X-Staff-Key header.
     * Key disimpan di .env sebagai STAFF_PANEL_KEY.
     *
     * Perbandingan memakai hash_equals() untuk mencegah timing attack, dan
     * setiap kegagalan dicatat (IP + waktu) untuk deteksi brute-force.
     */
    private function authorize(Request $request): bool
    {
        $key      = config('services.staff.panel_key', '');
        $provided = (string) $request->header('X-Staff-Key', '');

        $ok = !empty($key) && hash_equals($key, $provided);

        if (!$ok) {
            Log::warning('Percobaan akses staff panel gagal', [
                'ip'    => $request->ip(),
                'path'  => $request->path(),
                'agent' => $request->userAgent(),
                'time'  => now()->toDateTimeString(),
            ]);
        }

        return $ok;
    }

    /** Antrian booking yang perlu diproses (PAID + PROCESSING_ISSUANCE). */
    public function queue(Request $request)
    {
        if (!$this->authorize($request)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $bookings = FlightBooking::with(['flightPassengers', 'flightTicketFiles'])
            ->whereIn('status', ['PAID', 'PROCESSING_ISSUANCE'])
            ->orderBy('updated_at', 'asc')
            ->get()
            ->map(fn($b) => $this->formatBooking($b));

        return response()->json(['data' => $bookings]);
    }

    /** Semua booking untuk riwayat (semua status). */
    public function all(Request $request)
    {
        if (!$this->authorize($request)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $bookings = FlightBooking::with(['flightPassengers', 'flightTicketFiles'])
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json([
            'data' => collect($bookings->items())->map(fn($b) => $this->formatBooking($b)),
            'meta' => [
                'current_page' => $bookings->currentPage(),
                'last_page'    => $bookings->lastPage(),
                'total'        => $bookings->total(),
            ],
        ]);
    }

    /** Tandai mulai dikerjakan → PROCESSING_ISSUANCE. */
    public function startProcessing(Request $request, string $code)
    {
        if (!$this->authorize($request)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $booking = FlightBooking::where('booking_code', $code)->firstOrFail();

        if ($booking->status !== 'PAID') {
            return response()->json(['message' => 'Status tidak valid untuk tindakan ini.'], 422);
        }

        $booking->status = 'PROCESSING_ISSUANCE';
        $booking->save();

        return response()->json(['success' => true, 'status' => $booking->status]);
    }

    /** Upload e-tiket PDF + tandai ISSUED. */
    public function uploadTicket(Request $request, string $code)
    {
        if (!$this->authorize($request)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $request->validate([
            'ticket' => ['required', 'file', 'mimes:pdf', 'max:10240'],
        ]);

        $booking = FlightBooking::where('booking_code', $code)->firstOrFail();

        if (!in_array($booking->status, ['PAID', 'PROCESSING_ISSUANCE'])) {
            return response()->json(['message' => 'Status tidak valid untuk upload tiket.'], 422);
        }

        $file = $request->file('ticket');
        $path = $file->store("flight_tickets/{$code}", 'public');

        FlightTicketFile::create([
            'flight_booking_id' => $booking->id,
            'file_path'         => $path,
            'original_name'     => $file->getClientOriginalName(),
            'uploaded_by'       => null,
        ]);

        $booking->status = 'ISSUED';
        $booking->save();

        return response()->json([
            'success'    => true,
            'status'     => $booking->status,
            'ticket_url' => asset('storage/' . $path),
        ]);
    }

    /** Tandai gagal → FAILED_ISSUANCE. */
    public function markFailed(Request $request, string $code)
    {
        if (!$this->authorize($request)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $request->validate([
            'reason' => ['required', 'string', 'max:500'],
        ]);

        $booking = FlightBooking::where('booking_code', $code)->firstOrFail();

        if (!in_array($booking->status, ['PAID', 'PROCESSING_ISSUANCE'])) {
            return response()->json(['message' => 'Status tidak valid.'], 422);
        }

        $booking->status = 'FAILED_ISSUANCE';
        $booking->save();

        return response()->json(['success' => true, 'status' => $booking->status]);
    }

    private function formatBooking(FlightBooking $b): array
    {
        $ticketUrl = null;
        if ($b->flightTicketFiles->isNotEmpty()) {
            $ticketUrl = asset('storage/' . $b->flightTicketFiles->first()->file_path);
        }

        return [
            'booking_code'  => $b->booking_code,
            'status'        => $b->status,
            'total_amount'  => $b->total_amount,
            'flight_data'   => $b->flight_data,
            'passengers'    => $b->flightPassengers->map(fn($p) => [
                'full_name'      => $p->full_name,
                'title'          => $p->title,
                'date_of_birth'  => $p->date_of_birth?->format('Y-m-d'),
                'id_type'        => $p->id_type,
                'id_number'      => $p->id_number,
                'phone'          => $p->phone,
                'email'          => $p->email,
                'passenger_type' => $p->passenger_type,
            ]),
            'ticket_url'    => $ticketUrl,
            'created_at'    => $b->created_at?->toIso8601String(),
        ];
    }
}
