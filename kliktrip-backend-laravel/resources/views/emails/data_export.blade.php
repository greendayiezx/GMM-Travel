<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Data Pribadi Anda</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Inter', Arial, sans-serif; background: #f0f4f8; color: #1a1a2e; }
    .wrapper { max-width: 600px; margin: 32px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #1E9BF0 0%, #0055ff 100%); padding: 32px; text-align: center; }
    .header-text { font-size: 20px; font-weight: 800; color: #fff; }
    .body { padding: 32px; }
    .greeting { font-size: 18px; font-weight: 700; color: #111; margin-bottom: 12px; }
    .intro { font-size: 14px; color: #555; line-height: 1.6; margin-bottom: 24px; }
    .section-title { font-size: 13px; font-weight: 700; color: #1E9BF0; text-transform: uppercase; letter-spacing: 0.5px; margin: 20px 0 8px; }
    table { width: 100%; border-collapse: collapse; font-size: 13px; }
    td { padding: 6px 0; color: #333; border-bottom: 1px solid #eee; }
    td.label { color: #888; width: 45%; }
    .footer { background: #1a1a2e; padding: 24px 32px; text-align: center; }
    .footer-text { font-size: 12px; color: #888; line-height: 1.6; }
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="header"><div class="header-text">GMM Global Explore</div></div>
    <div class="body">
      <div class="greeting">Halo, {{ $name }}!</div>
      <p class="intro">
        Berikut ringkasan data pribadi yang kami simpan di akun Anda, sesuai
        permintaan "Unduh Data Saya" dari aplikasi.
      </p>

      <div class="section-title">Profil</div>
      <table>
        <tr><td class="label">Nama</td><td>{{ $data['profile']['name'] }}</td></tr>
        <tr><td class="label">Email</td><td>{{ $data['profile']['email'] }}</td></tr>
        <tr><td class="label">Telepon</td><td>{{ $data['profile']['phone'] ?? '-' }}</td></tr>
        <tr><td class="label">Bergabung sejak</td><td>{{ $data['profile']['joined_at'] ?? '-' }}</td></tr>
      </table>

      <div class="section-title">Ringkasan Aktivitas</div>
      <table>
        <tr><td class="label">Booking Travel/Shuttle</td><td>{{ $data['travel_bookings_count'] }}</td></tr>
        <tr><td class="label">Booking Wisata</td><td>{{ $data['tour_bookings_count'] }}</td></tr>
        <tr><td class="label">Favorit Tersimpan</td><td>{{ $data['favorites_count'] }}</td></tr>
      </table>

      @if(count($data['saved_passengers']))
      <div class="section-title">Penumpang Tersimpan</div>
      <table>
        @foreach($data['saved_passengers'] as $p)
        <tr><td colspan="2">{{ $p['full_name'] }} — {{ $p['identity_number'] }}</td></tr>
        @endforeach
      </table>
      @endif

      @if(count($data['saved_cards']))
      <div class="section-title">Kartu Tersimpan (nomor mentah tidak pernah kami simpan)</div>
      <table>
        @foreach($data['saved_cards'] as $c)
        <tr><td colspan="2">{{ strtoupper($c['card_type'] ?? 'Kartu') }} — {{ $c['masked_card'] }}</td></tr>
        @endforeach
      </table>
      @endif
    </div>
    <div class="footer">
      <p class="footer-text">
        Email ini dikirim karena ada permintaan unduh data dari akun Anda.
        Jika ini bukan Anda, segera hubungi support@globalexplore.com.
        <br>(c) {{ date('Y') }} GMM Global Explore.
      </p>
    </div>
  </div>
</body>
</html>
