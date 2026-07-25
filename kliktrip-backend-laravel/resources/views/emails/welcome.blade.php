<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Selamat Datang di GMM Global Explore</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Inter', Arial, sans-serif; background: #f0f4f8; color: #1a1a2e; }
    .wrapper { max-width: 600px; margin: 32px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #1E9BF0 0%, #0055ff 100%); padding: 40px 32px; text-align: center; }
    .header-logo { display: inline-flex; align-items: center; gap: 12px; margin-bottom: 16px; }
    .header-logo-text { font-size: 24px; font-weight: 800; color: #fff; letter-spacing: -0.3px; }
    .header-logo-text span { color: #FFD600; }
    .header-tagline { font-size: 13px; color: rgba(255,255,255,0.7); }
    .body { padding: 40px 32px; }
    .greeting { font-size: 22px; font-weight: 700; color: #111; margin-bottom: 12px; }
    .greeting span { color: #1E9BF0; }
    .intro { font-size: 15px; color: #555; line-height: 1.7; margin-bottom: 28px; }
    .feature-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 28px; }
    .feature-card { background: #f5faff; border: 1px solid #ddeeff; border-radius: 10px; padding: 16px; }
    .feature-icon { font-size: 24px; margin-bottom: 8px; }
    .feature-title { font-size: 13px; font-weight: 700; color: #1a1a2e; margin-bottom: 4px; }
    .feature-desc { font-size: 12px; color: #888; line-height: 1.5; }
    .cta-section { text-align: center; margin-bottom: 28px; }
    .cta-btn {
      display: inline-block; padding: 14px 36px;
      background: linear-gradient(135deg, #1E9BF0, #0055ff);
      color: #fff; font-size: 15px; font-weight: 600;
      border-radius: 10px; text-decoration: none;
      box-shadow: 0 4px 16px rgba(30,155,240,0.35);
    }
    .divider { height: 1px; background: #eee; margin: 24px 0; }
    .tip { background: #fffde7; border-left: 4px solid #FFD600; border-radius: 0 8px 8px 0; padding: 14px 16px; margin-bottom: 24px; }
    .tip-label { font-size: 12px; font-weight: 700; color: #b8860b; margin-bottom: 4px; }
    .tip-text { font-size: 13px; color: #555; line-height: 1.5; }
    .footer { background: #1a1a2e; padding: 28px 32px; text-align: center; }
    .footer-logo { font-size: 16px; font-weight: 800; color: #fff; margin-bottom: 8px; }
    .footer-logo span { color: #FFD600; }
    .footer-text { font-size: 12px; color: #888; line-height: 1.6; }
    .footer-links { margin-top: 12px; }
    .footer-links a { color: #1E9BF0; font-size: 12px; text-decoration: none; margin: 0 8px; }
    @media (max-width: 480px) {
      .body { padding: 28px 20px; }
      .feature-grid { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <!-- Header -->
    <div class="header">
      <img src="https://www.globalexplore.web.id/assets/gmm-tour-logo.png"
           alt="GMM Global Explore" width="64" height="64"
           style="display:block; margin:0 auto 14px; border-radius:14px; background:#fff; padding:6px;">
      <div class="header-logo">
        <div class="header-logo-text">GMM Global <span>Explore</span></div>
      </div>
      <div class="header-tagline">Your Trusted Travel Partner</div>
    </div>

    <!-- Body -->
    <div class="body">
      <div class="greeting">
        Halo, <span>{{ $firstName }}</span>! 👋
      </div>
      <p class="intro">
        Selamat datang di <strong>GMM Global Explore</strong>! Akun Anda telah berhasil dibuat.
        Kami senang memiliki Anda sebagai bagian dari komunitas traveler kami.
        Siap menjelajahi dunia bersama kami?
      </p>

      <!-- Feature highlights -->
      <div class="feature-grid">
        <div class="feature-card">
          <div class="feature-icon">✈️</div>
          <div class="feature-title">Tiket Pesawat</div>
          <div class="feature-desc">Cari & pesan tiket penerbangan terbaik dengan harga kompetitif.</div>
        </div>
        <div class="feature-card">
          <div class="feature-icon">🚐</div>
          <div class="feature-title">Travel Shuttle</div>
          <div class="feature-desc">Shuttle nyaman antar kota dengan armada modern dan terpercaya.</div>
        </div>
        <div class="feature-card">
          <div class="feature-icon">🌴</div>
          <div class="feature-title">Paket Tour</div>
          <div class="feature-desc">Paket wisata lengkap ke berbagai destinasi lokal & internasional.</div>
        </div>
        <div class="feature-card">
          <div class="feature-icon">🏨</div>
          <div class="feature-title">Hotel</div>
          <div class="feature-desc">Pilihan penginapan dari budget hingga bintang 5 di seluruh dunia.</div>
        </div>
      </div>

      <!-- CTA -->
      <div class="cta-section">
        <a href="https://globalexplore.web.id" class="cta-btn">
          Mulai Jelajahi Sekarang 🚀
        </a>
      </div>

      <div class="divider"></div>

      <!-- Tip -->
      <div class="tip">
        <div class="tip-label">💡 Tips Pertama</div>
        <div class="tip-text">
          Lengkapi profil Anda untuk pengalaman booking yang lebih cepat! Simpan data penumpang
          dan metode pembayaran favorit Anda agar tidak perlu mengisi ulang setiap kali memesan.
        </div>
      </div>

      <p style="font-size:13px; color:#999; text-align:center;">
        Email ini dikirim karena akun GMM Global Explore baru saja dibuat
        @if($provider === 'google') menggunakan akun Google @else menggunakan email {{ $email }} @endif.
        Jika ini bukan Anda, abaikan email ini.
      </p>
    </div>

    <!-- Footer (mengikuti footer website, background putih) -->
    <div class="footer" style="background:#ffffff; padding:32px 32px 24px; text-align:center; border-top:1px solid #eef1f5;">
      <img src="https://www.globalexplore.web.id/assets/gmm-tour-logo.png"
           alt="GMM Global Explore" width="52" height="52"
           style="display:block; margin:0 auto 12px;">
      <div style="font-size:18px; font-weight:800; color:#1a2b4a; letter-spacing:-0.3px;">
        GMM Global <span style="color:#1E9BF0;">Explore</span>
      </div>
      <div style="font-size:12px; color:#9aa3b2; margin:4px 0 16px;">Your Trusted Travel Partner</div>

      <div style="font-size:12.5px; color:#667085; line-height:1.7; max-width:420px; margin:0 auto 20px;">
        Kami hadir untuk memberikan pengalaman perjalanan terbaik untuk Anda dan keluarga.
        Aman, nyaman, dan terpercaya.
      </div>

      <!-- Kontak (sama seperti website) -->
      <div style="font-size:12.5px; color:#475467; line-height:2; margin-bottom:18px;">
        📍 Jl. Pingkan Matindas No.60, Manado, Sulawesi Utara<br>
        💬 WhatsApp: <a href="https://wa.me/6282293217200" style="color:#1E9BF0; text-decoration:none;">+62 822-9321-7200</a><br>
        ✉️ <a href="mailto:yantisyamn@gmail.com" style="color:#1E9BF0; text-decoration:none;">yantisyamn@gmail.com</a><br>
        🕐 Setiap Hari &middot; 07.00 - 22.00 WITA
      </div>

      <!-- Sosial media -->
      <div style="margin-bottom:18px;">
        <a href="#" style="color:#1E9BF0; text-decoration:none; margin:0 7px; font-size:12px; font-weight:600;">Facebook</a>
        <a href="#" style="color:#1E9BF0; text-decoration:none; margin:0 7px; font-size:12px; font-weight:600;">Instagram</a>
        <a href="#" style="color:#1E9BF0; text-decoration:none; margin:0 7px; font-size:12px; font-weight:600;">TikTok</a>
        <a href="#" style="color:#1E9BF0; text-decoration:none; margin:0 7px; font-size:12px; font-weight:600;">YouTube</a>
      </div>

      <div style="font-size:11.5px; color:#98a2b3; line-height:1.7; border-top:1px solid #eef1f5; padding-top:16px;">
        © {{ date('Y') }} GMM Global Explore. All rights reserved.<br>
        Made with <span style="color:#22c55e;">💚</span> in Indonesia
      </div>
    </div>
    <!-- Aksen gelombang tiga warna (echo dari website) -->
    <div style="height:6px; line-height:6px; font-size:0; background:linear-gradient(90deg,#1E9BF0 0%,#a8eb12 50%,#FFD600 100%);">&nbsp;</div>
  </div>
</body>
</html>
