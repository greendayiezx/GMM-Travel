<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class TourCatalog extends Model
{
    use HasUuid;

    protected $fillable = ['external_id', 'kategori', 'nama_paket', 'payload', 'active'];

    protected $casts = [
        'payload' => 'array',
        'active'  => 'boolean',
    ];

    private const BULAN = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];

    private const BULAN_SINGKAT = [
        'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
        'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES',
    ];

    /**
     * Generate tanggal keberangkatan future (2 tanggal/bulan × N bulan), formatnya
     * cocok dengan parser mobile: key "SEP 2026", value "15 September 2026 (Rp ...)".
     * Di-generate saat request agar selalu future (tak pernah basi).
     *
     * @return array<string, array<int, string>>
     */
    public static function generateDepartures(string $hargaDisplay = '', int $months = 6): array
    {
        $suffix = $hargaDisplay !== '' ? " ($hargaDisplay)" : '';
        $today  = now()->startOfDay();
        $result = [];

        for ($i = 0; $i < $months; $i++) {
            $month    = $today->copy()->startOfMonth()->addMonths($i);
            $monthIdx = (int) $month->format('n') - 1;
            $key      = self::BULAN_SINGKAT[$monthIdx] . ' ' . $month->format('Y');

            foreach ([1, 15] as $day) {
                $date = $month->copy()->day($day);
                if ($date->lt($today)) {
                    continue; // lewati tanggal yang sudah lewat di bulan berjalan
                }
                $result[$key][] = $date->day . ' ' . self::BULAN[$monthIdx] . ' '
                    . $date->format('Y') . $suffix;
            }
        }

        return $result;
    }
}
