# Skema Loyalitas, Poin & Membership — GMM Global Explore

**Dokumen strategi produk & finansial** untuk sistem loyalitas terintegrasi lintas 3 layanan: **Tiket Pesawat**, **Shuttle Travel**, dan **Tour Wisata**.

> Dokumen ini menggabungkan dua kebutuhan: (a) skema poin & membership umum, dan (b) diferensiasi per produk + strategi cross-selling. Ditujukan untuk diserahkan ke tim developer & finance.

---

## 0. Asumsi Input (SILAKAN KOREKSI)

Angka berikut dipakai sebagai dasar perhitungan. Ganti bila berbeda — seluruh formula tetap berlaku, hanya nilainya menyesuaikan.

| Parameter | Nilai asumsi | Catatan |
|---|---|---|
| Margin bersih Tiket Pesawat | **2%** | dari kisaran 1–3% (ambil tengah, konservatif) |
| Margin bersih Shuttle Travel | **12%** | rute tetap, margin sedang |
| Margin bersih Tour Wisata | **20%** | open trip/private, margin tebal |
| Frekuensi transaksi | **2–3x / tahun / user** | |
| Target audiens | **Milenial hemat & keluarga kelas menengah** | sensitif harga, suka "cashback"/poin |
| Nilai tukar poin | **1 Poin = Rp1** saat ditukar | sederhana & transparan |
| **Guardrail finansial utama** | **Biaya poin ≤ 10% dari margin** per transaksi | prinsip "tidak bakar uang" |

---

## 1. Prinsip Finansial (Guardrail)

Tiga aturan yang mengunci agar program **tidak pernah boncos**:

1. **1 Poin = Rp1** saat ditukar (liabilitas jelas & mudah diaudit).
2. **Biaya penerbitan poin per transaksi ≤ 10% dari margin bersih** produk tersebut.
3. **Poin dihitung dari nominal produk, bukan dari pajak/biaya layanan/poin lain** (hindari poin dari poin).

**Rumus batas aman earning rate:**

> Jika margin = *M* (%), dan 1 poin = Rp1, maka **"Rp X = 1 poin"** aman bila **X ≥ 10 / M**.

Contoh: Tour margin 20% → X ≥ 10/20 = 0,5 → *minimal* Rp0,5 = 1 poin (sangat longgar). Pesawat margin 2% → X ≥ 5 → minimal Rp5 = 1 poin. Kita ambil jauh lebih konservatif dari batas minimum ini (lihat §2).

---

## 2. Skema Perolehan & Penukaran Poin (Earning & Redemption)

### 2.1 Earning Rate Dasar per Produk (Tier Blue / 1x)

Sengaja **dibedakan per produk** agar produk margin tipis (pesawat) tidak menggerus keuntungan, dan produk margin tebal (tour) jadi magnet poin.

| Produk | Margin | **Earning dasar** | Biaya poin (% transaksi) | **% terhadap margin** | Multiplier tier? |
|---|---|---|---|---|---|
| ✈️ Tiket Pesawat | 2% | **Rp2.000 = 1 poin** | 0,05% | **2,5%** | ❌ Tidak (margin terlalu tipis) |
| 🚐 Shuttle Travel | 12% | **Rp200 = 1 poin** | 0,50% | **4,2%** | ✅ Ya |
| 🏝️ Tour Wisata | 20% | **Rp100 = 1 poin** | 1,00% | **5,0%** | ✅ Ya |

**Kenapa pesawat dikecualikan dari multiplier?** Margin 2% tidak punya ruang. Pesawat diposisikan sebagai **produk akuisisi** (menarik user masuk ekosistem), lalu dimonetisasi lewat Shuttle & Tour (lihat §4).

### 2.2 Multiplier Tier (hanya Shuttle & Tour)

| Tier | Multiplier | Biaya poin Shuttle | Biaya poin Tour | Cek guardrail (≤10% margin) |
|---|---|---|---|---|
| Blue | 1,0x | 4,2% | 5,0% | ✅ |
| Silver | 1,25x | 5,2% | 6,3% | ✅ |
| Gold | 1,5x | 6,3% | 7,5% | ✅ |
| Platinum | 2,0x | 8,3% | **10,0%** | ✅ (tepat di batas) |

> Bahkan pada tier tertinggi, biaya poin **tidak pernah melewati 10% margin**. Aman.

### 2.3 Penukaran (Redemption) & Batas Maksimum (Cap)

Poin ditukar sebagai **potongan langsung saat checkout** (1 poin = Rp1). Karena redemption juga mengurangi margin transaksi berjalan, diberi **cap per produk**:

| Produk | Cap potongan poin per transaksi | Alasan |
|---|---|---|
| ✈️ Tiket Pesawat | **maks. 5%** dari nilai transaksi | lindungi margin 2% (redemption besar bisa bikin rugi) |
| 🚐 Shuttle Travel | **maks. 20%** | margin sedang |
| 🏝️ Tour Wisata | **maks. 30%** | margin tebal, boleh agresif untuk konversi |

**Aturan tambahan redemption:**
- Poin **tidak bisa digabung** dengan kode voucher diskon lain pada transaksi yang sama (anti *stacking*).
- Minimum saldo tukar: **500 poin** (hindari micro-redemption yang membebani ops).
- Poin **tidak bisa untuk membayar pajak/biaya layanan**, hanya harga produk.

### 2.4 Simulasi Matematis (sesuai permintaan)

**Belanja Rp500.000** (tier Blue):

| Produk | Poin didapat | Nilai poin (Rp) | Margin transaksi (Rp) | Biaya poin thd margin |
|---|---|---|---|---|
| Pesawat | 250 | Rp250 | Rp10.000 | 2,5% |
| Shuttle | 2.500 | Rp2.500 | Rp60.000 | 4,2% |
| Tour | 5.000 | Rp5.000 | Rp100.000 | 5,0% |

**Belanja Rp5.000.000** (tier Blue):

| Produk | Poin didapat | Nilai poin (Rp) | Margin transaksi (Rp) | Biaya poin thd margin |
|---|---|---|---|---|
| Pesawat | 2.500 | Rp2.500 | Rp100.000 | 2,5% |
| Shuttle | 25.000 | Rp25.000 | Rp600.000 | 4,2% |
| Tour | 50.000 | Rp50.000 | Rp1.000.000 | 5,0% |

**Skenario ekstrem — Tour Rp5.000.000, member Platinum (2x):** 100.000 poin = Rp100.000 = **10% dari margin Rp1.000.000**. Tepat di guardrail, tetap aman. ✅

---

## 3. Tingkatan Member (Membership Tiers)

Empat tier untuk memberi *sense of progression* (psikologis) tanpa membebani finansial. Kenaikan tier berbasis **total belanja 12 bulan terakhir** (rolling), bukan lifetime — mendorong transaksi berulang.

### 3.1 Syarat Naik Kelas

| Tier | Syarat belanja (12 bln) | Profil user | Estimasi realistis |
|---|---|---|---|
| 🔵 **Blue** | Rp0 (otomatis saat daftar) | user baru | semua user |
| ⚪ **Silver** | **≥ Rp5.000.000** | 1 tour keluarga / beberapa tiket | tercapai ~1–2 transaksi |
| 🟡 **Gold** | **≥ Rp15.000.000** | traveler aktif | 3–4 transaksi/tahun |
| 🟣 **Platinum** | **≥ Rp40.000.000** | heavy user / korporat kecil | segmen premium |

> Ambang dibuat realistis untuk keluarga kelas menengah (2–3 trip/tahun bisa capai Silver–Gold), sekaligus menjaga Platinum tetap eksklusif.

### 3.2 Matriks Keuntungan (Benefit) per Tier

| Benefit | 🔵 Blue | ⚪ Silver | 🟡 Gold | 🟣 Platinum |
|---|---|---|---|---|
| **Multiplier poin** (Shuttle & Tour) | 1,0x | 1,25x | 1,5x | 2,0x |
| **Kupon ulang tahun** | – | Rp25.000 | Rp50.000 | Rp100.000 |
| **Diskon Shuttle otomatis** | – | 5% | 10% | 15% |
| **Gratis pembatalan Tour** | – | – | 1x / tahun (H-3) | Unlimited (H-3) |
| **Perk Pesawat** (bila partner mendukung) | – | – | Priority boarding* | Free seat selection* |
| **Jalur Customer Service** | Standar | Standar | Prioritas | Dedicated agent |
| **Early access** promo & flash sale | – | ✅ | ✅ | ✅ |
| **Free merchandise Tour** | – | – | – | ✅ |
| **Masa kedaluwarsa poin** | 12 bulan | 12 bulan | 15 bulan | 18 bulan |

<sub>*Perk pesawat bergantung dukungan maskapai/partner; bila tidak tersedia, ganti dengan voucher bagasi atau prioritas re-issue.</sub>

**Aturan tier:**
- Evaluasi tier **bulanan** berdasarkan belanja 12 bulan ke belakang.
- **Grace period**: bila belanja turun di bawah ambang, tier bertahan **1 periode (30 hari)** sebelum turun — menghindari frustrasi user.
- Naik tier berlaku **instan** setelah ambang tercapai.

---

## 4. Program Promo Cross-Selling (Ekosistem)

**Filosofi:** margin tebal Tour (20%) & Shuttle (12%) **mensubsidi** tipisnya margin Pesawat (2%). Pesawat = pintu masuk, Tour/Shuttle = mesin profit.

### Kempen 1 — "Bundling Bandara" (Pesawat → Shuttle)

Beli tiket pesawat, **tambah shuttle jemputan bandara diskon** dalam 1 checkout.

| Komponen | Harga | Margin normal | Perlakuan promo |
|---|---|---|---|
| Tiket pesawat | Rp1.000.000 | Rp20.000 (2%) | tetap |
| Shuttle (add-on) | Rp250.000 | Rp30.000 (12%) | diskon Rp20.000 → user bayar Rp230.000 |
| **Total ke user** | **Rp1.230.000** | | |

**Logika finansial:** diskon Rp20.000 diambil dari margin shuttle (Rp30.000 → sisa Rp10.000). Tanpa promo, kemungkinan besar user **tidak beli shuttle sama sekali** (cari Grab/keluarga). Jadi ini *incremental revenue*: total profit gabungan **Rp20.000 (pesawat) + Rp10.000 (shuttle) = Rp30.000**, naik 50% dari sekadar jual tiket pesawat.

### Kempen 2 — "Liburan All-in" (Pesawat + Tour + Shuttle)

Paket bundling: pesawat + tour + shuttle → **bonus poin besar** & shuttle gratis.

| Komponen | Harga | Margin |
|---|---|---|
| Pesawat | Rp1.500.000 | Rp30.000 |
| Tour Wisata | Rp3.000.000 | Rp600.000 |
| Shuttle | Rp200.000 | Rp24.000 |
| **Total** | **Rp4.700.000** | **Rp654.000** |

**Benefit ke user:** shuttle **gratis** (di-cover margin tour) + **bonus 2x poin tour** untuk transaksi bundling.
**Biaya program:** shuttle gratis Rp200.000 + poin ekstra tour (60.000 poin = Rp60.000) = **Rp260.000**, diambil dari margin tour Rp600.000 → **sisa profit Rp394.000** (masih ~8,4% dari nilai paket). Aman & menarik.

### Kempen 3 — "Terbang → Jelajah" (retargeting pasca-pesawat)

Setiap user yang beli **tiket pesawat**, dapat **voucher bonus 3x poin Tour** yang berlaku **14 hari** untuk pembelian tour ke kota tujuan.

**Logika:** pesawat margin tipis dijadikan *trigger*. Bila 10% pembeli tiket lanjut beli tour, subsidi 3x poin (biaya ~3% dari tour = 15% margin tour, di atas guardrail normal **tapi** ini biaya akuisisi bertarget & terbatas waktu, di-*budget* dari pos marketing, bukan pos poin reguler). Rekomendasi: **cap anggaran kampanye bulanan** & ukur *conversion uplift*.

> **Prinsip subsidi silang:** poin/diskon produk margin tipis selalu **dibiayai dari margin produk tebal** dalam paket yang sama, atau dari pos marketing terpisah dengan cap anggaran — **tidak pernah** dari kas operasional tanpa batas.

---

## 5. Mekanisme Retensi & Anti-Fraud

### 5.1 Kedaluwarsa Poin (Retensi)

| Aturan | Nilai | Tujuan |
|---|---|---|
| Masa berlaku poin | **12 bulan** sejak diperoleh (rolling), lebih panjang untuk tier atas (15/18 bln) | dorong transaksi ulang sebelum hangus |
| Notifikasi | H-30 & H-7 sebelum hangus (email + push) | *urgency* → repeat purchase |
| Poin hangus | pada akhir bulan jatuh tempo | prediktabilitas liabilitas |

> Ekspirasi 12 bulan = sweet spot: cukup lama agar user tidak kesal, cukup pendek agar mendorong transaksi ke-2/ke-3 dalam setahun (sesuai frekuensi 2–3x).

### 5.2 Aturan Anti-Fraud

| Risiko | Aturan mitigasi |
|---|---|
| **Farming poin lewat book-cancel** | Poin **baru masuk H+1 setelah masa pembatalan lewat / perjalanan dinyatakan valid** (bukan saat bayar). |
| **Refund tapi poin sudah dipakai** | **Clawback**: poin ditarik saat refund; bila saldo negatif, redemption berikutnya diblokir sampai lunas. |
| **Akun ganda / bot** | Redemption > Rp100.000 wajib **akun terverifikasi (email + no. HP OTP)**; 1 identitas = 1 akun untuk klaim tier. |
| **Abuse volume** | **Cap perolehan poin: maks. 100.000 poin / akun / hari** & maks. 500.000 poin / akun / bulan. |
| **Self-referral / kolusi** | Poin **non-transferable** antar akun; referral tidak berlaku untuk transaksi yang di-refund. |
| **Manipulasi harga** | Poin dihitung dari **harga produk final tervalidasi server**, bukan angka dari client. |

---

## 6. Ringkasan Parameter untuk Tim Developer

Nilai yang perlu disimpan sebagai **konfigurasi** (jangan hardcode di banyak tempat — taruh di tabel `settings`/config agar mudah diubah tim bisnis):

| Key konfigurasi | Nilai |
|---|---|
| `point.redeem_value_rp` | 1 |
| `point.earn.pesawat_rp_per_point` | 2000 |
| `point.earn.shuttle_rp_per_point` | 200 |
| `point.earn.tour_rp_per_point` | 100 |
| `point.multiplier.blue / silver / gold / platinum` | 1.0 / 1.25 / 1.5 / 2.0 |
| `point.multiplier.applies_to` | ["shuttle", "tour"] |
| `redeem.cap_pct.pesawat / shuttle / tour` | 5 / 20 / 30 |
| `redeem.min_points` | 500 |
| `tier.threshold.silver / gold / platinum` (12 bln) | 5.000.000 / 15.000.000 / 40.000.000 |
| `tier.grace_period_days` | 30 |
| `point.expiry_months.blue / silver / gold / platinum` | 12 / 12 / 15 / 18 |
| `fraud.max_points_per_day / per_month` | 100.000 / 500.000 |
| `point.credit_delay` | "H+1 setelah masa pembatalan" |

### Saran Model Data (ringkas)

| Tabel | Field kunci |
|---|---|
| `loyalty_accounts` | `user_id`, `points_balance`, `tier`, `spend_12m`, `tier_since` |
| `point_transactions` (ledger) | `user_id`, `order_id`, `type` (earn/redeem/expire/clawback), `points`, `expires_at`, `status` |
| `tier_history` | `user_id`, `from_tier`, `to_tier`, `changed_at` |

Endpoint yang perlu ditambah (melengkapi `GET /me/stats` yang sudah ada):
- `GET /me/loyalty` → `{ tier, points_balance, spend_12m, next_tier, next_tier_threshold, progress_pct, points_expiring_soon }`

---

## 7. Catatan Implementasi di Aplikasi Mobile

Kartu **"Loyalty Status"** di halaman profil (`profile_page.dart`) saat ini **masih dummy** (`You're 2 trips away from Platinum`, progress 75%, Gold→Platinum hardcoded). Untuk membuatnya nyata, backend perlu mengekspos `GET /me/loyalty` (di atas). Setelah itu kartu diisi dari:
- `tier` → badge tier,
- `progress_pct` → progress bar,
- `next_tier` & selisih `spend_12m` → teks "Rp X lagi menuju {next_tier}".

Selama endpoint tersebut belum ada, opsi sementara: **sembunyikan kartu** agar tidak menampilkan data palsu.

---

*Dokumen ini adalah kerangka strategi. Sebelum go-live, validasi angka margin aktual & lakukan simulasi P&L 3 bulan pertama untuk kalibrasi earning rate.*
