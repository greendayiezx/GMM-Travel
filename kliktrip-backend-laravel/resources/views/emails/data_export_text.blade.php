Halo, {{ $name }}!

Berikut ringkasan data pribadi yang kami simpan di akun Anda, sesuai
permintaan "Unduh Data Saya" dari aplikasi.

PROFIL
Nama            : {{ $data['profile']['name'] }}
Email           : {{ $data['profile']['email'] }}
Telepon         : {{ $data['profile']['phone'] ?? '-' }}
Bergabung sejak : {{ $data['profile']['joined_at'] ?? '-' }}

RINGKASAN AKTIVITAS
Booking Travel/Shuttle : {{ $data['travel_bookings_count'] }}
Booking Wisata         : {{ $data['tour_bookings_count'] }}
Favorit Tersimpan      : {{ $data['favorites_count'] }}

@if(count($data['saved_passengers']))
PENUMPANG TERSIMPAN
@foreach($data['saved_passengers'] as $p)
- {{ $p['full_name'] }} — {{ $p['identity_number'] }}
@endforeach

@endif
@if(count($data['saved_cards']))
KARTU TERSIMPAN (nomor mentah tidak pernah kami simpan)
@foreach($data['saved_cards'] as $c)
- {{ strtoupper($c['card_type'] ?? 'Kartu') }} — {{ $c['masked_card'] }}
@endforeach

@endif
Email ini dikirim karena ada permintaan unduh data dari akun Anda.
Jika ini bukan Anda, segera hubungi support@globalexplore.com.

(c) {{ date('Y') }} GMM Global Explore.
