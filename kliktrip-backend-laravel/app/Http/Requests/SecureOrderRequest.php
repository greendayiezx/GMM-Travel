<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

/**
 * SecureOrderRequest
 * ------------------
 * Contoh Form Request dengan validasi ketat untuk endpoint order.
 *
 * Prinsip keamanan:
 *  - Semua input di-whitelist lewat rules() (allow-list), bukan sekadar
 *    membuang yang jelas berbahaya.
 *  - Tipe & panjang dibatasi tegas → mengurangi permukaan serangan XSS/SQLi.
 *  - Validasi lolos → data dipakai lewat Eloquent (parameter binding), TIDAK
 *    pernah di-concat langsung ke query SQL.
 *  - Pesan error validasi bersifat informatif untuk user, tapi tidak membocorkan
 *    struktur internal database.
 */
class SecureOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Otorisasi kepemilikan order ditangani middleware VerifyOrderHash +
        // VerifyClerkToken. Di sini cukup pastikan user terautentikasi.
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            // UUID/string terbatas — cegah payload aneh masuk ke query.
            'order_id'   => ['required', 'string', 'max:64'],
            'order_hash' => ['required', 'string', 'size:24', 'alpha_num'],

            // Data penumpang: tiap field dibatasi tipe & panjangnya.
            'passengers'                   => ['sometimes', 'array', 'max:20'],
            'passengers.*.name'            => ['required', 'string', 'max:255'],
            'passengers.*.identity_number' => ['required', 'string', 'max:50', 'regex:/^[A-Za-z0-9\-]+$/'],
            'passengers.*.email'           => ['nullable', 'email:rfc', 'max:255'],
            'passengers.*.phone'           => ['nullable', 'string', 'max:20', 'regex:/^[0-9+\-\s]+$/'],

            // Catatan bebas — batasi panjang untuk cegah abuse.
            'notes' => ['nullable', 'string', 'max:1000'],
        ];
    }

    public function messages(): array
    {
        return [
            'order_hash.size'     => 'Tautan tidak valid.',
            'order_hash.alpha_num'=> 'Tautan tidak valid.',
            'passengers.*.identity_number.regex' => 'Nomor identitas hanya boleh huruf, angka, dan tanda hubung.',
            'passengers.*.phone.regex'           => 'Format nomor telepon tidak valid.',
        ];
    }

    /**
     * Kembalikan error validasi sebagai JSON 422 (bukan redirect Blade),
     * karena ini API. Pesan tetap generik untuk field sensitif.
     */
    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(
            response()->json([
                'message' => 'Data yang dikirim tidak valid.',
                'errors'  => $validator->errors(),
            ], 422)
        );
    }
}
