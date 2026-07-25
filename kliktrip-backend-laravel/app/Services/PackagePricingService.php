<?php

namespace App\Services;

use App\Models\PackageCatalog;

/**
 * PackagePricingService
 * ---------------------
 * Menghitung total harga paket DI SERVER, mereplikasi persis logika frontend
 * (initTicketModal + totalTicketPrice). Dipakai untuk memvalidasi `amount`
 * yang dikirim client → cegah price manipulation.
 *
 * Aturan harga (identik dengan frontend):
 *  - Paket berkategori (price_categories): harga tiap tiket = harga kategori
 *    dgn `type` yang cocok. Item "Uang Muka"/"DP" BUKAN tiket (dikecualikan).
 *  - Paket biasa: Adult = base, Child = round(base×0.85), Senior = round(base×0.95).
 */
class PackagePricingService
{
    /** Cari paket berdasarkan nama (key sama dgn frontend). */
    public function find(?string $name): ?PackageCatalog
    {
        if (!$name) return null;
        return PackageCatalog::where('name', $name)->where('active', true)->first();
    }

    /**
     * Hitung total yang SEHARUSNYA dari daftar tiket [{name, qty}].
     * Return integer total, atau null jika ada item yang tidak dikenali
     * (indikasi manipulasi / data tidak konsisten).
     */
    public function computeExpectedTotal(PackageCatalog $pkg, array $items): ?int
    {
        $total = 0;
        foreach ($items as $item) {
            $name = (string) ($item['name'] ?? '');
            $qty  = (int) ($item['qty'] ?? 0);
            if ($qty <= 0) continue;

            $price = $this->priceForTicket($pkg, $name);
            if ($price === null) {
                return null; // nama tiket tidak dikenal → tolak
            }
            $total += $price * $qty;
        }
        return $total;
    }

    /**
     * Harga satu jenis tiket pada paket tertentu.
     * Return null bila nama tiket tidak valid untuk paket ini.
     */
    public function priceForTicket(PackageCatalog $pkg, string $ticketName): ?int
    {
        $categories = $pkg->price_categories;

        if (is_array($categories) && count($categories) > 0) {
            foreach ($categories as $cat) {
                $type = (string) ($cat['type'] ?? '');
                // "Uang Muka"/"DP" bukan tiket yang bisa dipesan.
                $lower = strtolower($type);
                if (str_contains($lower, 'uang muka') || str_contains($lower, 'dp')) {
                    continue;
                }
                if ($type === $ticketName) {
                    return (int) ($cat['price'] ?? 0);
                }
            }
            return null;
        }

        // Paket biasa: Adult/Child/Senior dari base_price.
        $base = (int) $pkg->base_price;
        return match ($ticketName) {
            'Adult'  => $base,
            'Child'  => (int) round($base * 0.85),
            'Senior' => (int) round($base * 0.95),
            default  => null,
        };
    }

    /**
     * Harga tiket termurah untuk paket (floor fallback bila client tidak
     * mengirim rincian tiket). Tidak akan lebih murah dari tiket termurah
     * yang sah → tetap cegah manipulasi ke nominal kecil.
     */
    public function minTicketPrice(PackageCatalog $pkg): int
    {
        $categories = $pkg->price_categories;

        if (is_array($categories) && count($categories) > 0) {
            $prices = [];
            foreach ($categories as $cat) {
                $lower = strtolower((string) ($cat['type'] ?? ''));
                if (str_contains($lower, 'uang muka') || str_contains($lower, 'dp')) {
                    continue;
                }
                $prices[] = (int) ($cat['price'] ?? 0);
            }
            if (!empty($prices)) return min($prices);
        }

        // Paket biasa: termurah = Child (base×0.85).
        return (int) round($pkg->base_price * 0.85);
    }
}
