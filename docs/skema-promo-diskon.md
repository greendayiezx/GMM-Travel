# Skema Promo & Diskon Terintegrasi — GMM Global Explore

**Dokumen strategi promo** untuk 3 layanan: **Tiket Pesawat**, **Shuttle Travel**, **Tour Wisata**. Melanjutkan & konsisten dengan [Skema Loyalitas, Poin & Membership](./skema-loyalitas-poin-membership.md).

> Berisi validasi finansial per promo + aturan cap, anggaran, stacking, dan anti-abuse. Siap diserahkan ke tim developer & finance.

---

## 0. Asumsi & Prinsip Dana Promo

Margin (sama dengan dokumen loyalitas — **silakan koreksi**): **Pesawat 2%**, **Shuttle 12%**, **Tour 20%**.

**Dua sumber dana promo** (setiap promo WAJIB ditandai sumbernya):

| Sumber dana | Definisi | Kontrol |
|---|---|---|
| 🟢 **Margin-funded** (subsidi silang) | Diskon dibiayai dari margin produk lain dalam transaksi/paket yang sama (biasanya Tour/Shuttle mensubsidi Pesawat). | Otomatis positif selama diskon < margin penyubsidi. |
| 🟡 **Marketing-funded** (akuisisi/retensi) | Diskon dibiayai dari **pos anggaran marketing**, bukan margin transaksi. | **Wajib ada budget cap bulanan + tracking ROI/CAC.** |

**Prinsip inti:** promo produk margin tipis (Pesawat) **selalu** dibiayai margin produk tebal (Tour/Shuttle) atau pos marketing berbatas — **tidak pernah** dari kas tanpa cap.

---

## 1. Ringkasan Kelayakan Finansial (Baca Ini Dulu)

Verdict cepat atas semua ide promo. Detail per promo di §2–§5.

| # | Promo | Diskon | Sumber dana | Status | Guardrail wajib |
|---|---|---|---|---|---|
| 1a | Welcome Bundling (Rp50rb Tour + Rp10rb Shuttle) | ±Rp60rb/user | 🟡 Marketing | ✅ Aman | 1x/identitas, min. belanja, budget bulanan |
| 1b | Double Point transaksi pertama | 2x poin | 🟢 Margin | ✅ Aman | first-txn only, cap poin |
| 2a | Tour → Shuttle **50% off** | 50% shuttle | 🟢 Margin (Tour) | ⚠️ Perlu Cap | hanya saat beli Tour, cap harga shuttle |
| 2b | Pesawat → Shuttle Rp15rb off | Rp15rb | 🟢 Margin (Shuttle) | ✅ Aman | shuttle bandara only |
| 2c | Cashback berantai (Shuttle → kupon 10% Tour) | 10% Tour | 🟢 Margin (Tour) | ⚠️ Perlu Cap | cap rupiah, min. Tour, expiry |
| 3a | Flash Sale Tanggal Kembar Tour **s.d. 30%** | s.d. 30% | 🟡 Marketing | 🔴 **Berisiko** | **redesign: kuota terbatas / hanya SKU margin tinggi** |
| 3b | Payday Shuttle (flat discount) | flat Rp | 🟢 Margin (Shuttle) | ⚠️ Perlu Cap | flat ≤ 60% margin shuttle |
| 3c | Early Bird Tour 15% (H-30) | 15% | 🟢 Margin (Tour) | ✅ Aman | H-30, sisa margin 5% |
| 4a | Selasa Khusus Member (Shuttle murah) | 10–15% | 🟢 Margin (Shuttle) | ✅ Aman | tier Silver+, ≤ margin, no stack |
| 4b | Kado Ultah — kupon Pesawat | Rp25–100rb | 🟡 Marketing (dr Tour) | ✅ Aman | 1x/tahun, tier-scaled, budget |

> **🔴 3a adalah satu-satunya yang bisa bikin rugi** apa adanya (30% > margin 20% = margin **negatif**). Wajib di-redesign — lihat §4.

---

## 2. Promo Pengguna Baru (Aktivasi Akun) — 🟡 Marketing-funded

Tujuan: **akuisisi**. Ini biaya CAC, dibayar dari budget marketing, bukan margin.

### 2a. Welcome Bundling
Rp50.000 potongan Tour pertama + voucher Rp10.000 Shuttle (aktif setelah registrasi + KYC dasar).

| Item | Nilai | Validasi |
|---|---|---|
| Potongan Tour | Rp50.000 (min. Tour Rp500.000 → efektif ≤10%) | margin Tour Rp100rb → sisa Rp50rb, **tetap positif** walau CAC |
| Voucher Shuttle | Rp10.000 (min. Shuttle Rp150.000) | margin Shuttle → sisa positif |
| **Total CAC maks/user** | **Rp60.000** | bandingkan dengan LTV (2–3 txn/thn) |

**Guardrail:**
- **1x per identitas** (email + no. HP OTP + fingerprint device/pembayaran).
- Berlaku **hanya transaksi pertama**, expiry **30 hari**.
- **Budget cap bulanan** (mis. Rp X juta) + auto-off saat cap tercapai.
- Voucher **hangus jika transaksi pertama di-refund** (clawback).

### 2b. Double Point Transaksi Pertama — 🟢 Margin-funded
Poin 2x untuk transaksi pertama, layanan apa saja.

| Produk | Poin normal | 2x | Biaya thd margin |
|---|---|---|---|
| Pesawat | Rp2.000=1 | Rp1.000=1 | 5% (dari 2,5%) — masih aman |
| Shuttle | Rp200=1 | Rp100=1 | 8,3% |
| Tour | Rp100=1 | Rp50=1 | 10% (tepat batas) |

**Guardrail:** hanya transaksi pertama; **cap maks. 50.000 poin bonus**; poin masuk H+1 setelah masa pembatalan.

---

## 3. Promo Cross-Selling — 🟢 Margin-funded (subsidi silang)

### 2a. Tour → Shuttle 50% off ⚠️
Beli Tour → Shuttle ke meeting point/bandara diskon 50%.

| Komponen | Harga | Margin |
|---|---|---|
| Tour | Rp3.000.000 | Rp600.000 |
| Shuttle (add-on) | Rp250.000 | Rp30.000 |
| Diskon 50% shuttle | –Rp125.000 | subsidi dari margin Tour |
| **Net margin bundle** | | **Rp600rb + Rp30rb – Rp125rb = Rp505.000** ✅ |

**Kenapa perlu cap:** tanpa batas harga shuttle, subsidi 50% bisa membengkak. **Guardrail:**
- Hanya aktif **saat Tour dibeli** (bundling, 1 checkout).
- **Cap harga shuttle** yang dapat 50%: maks. **Rp300.000** (subsidi maks. Rp150.000).
- 1 shuttle diskon per 1 Tour.

### 2b. Pesawat → Shuttle Rp15.000 off — ✅
| Komponen | Margin | Efek |
|---|---|---|
| Shuttle Rp200.000 | Rp24.000 | diskon Rp15.000 → sisa margin Rp9.000 (positif) |

Dibiayai margin **Shuttle** (bukan Pesawat). *Incremental revenue* dari penumpang yang biasanya pakai transport lain. Guardrail: hanya **shuttle rute bandara**, 1x per tiket pesawat.

### 2c. Cashback Berantai (Shuttle → kupon 10% Tour weekend) ⚠️
| Item | Nilai | Validasi |
|---|---|---|
| Kupon 10% Tour | 10% dari harga Tour | margin Tour 20% → sisa 10% (positif) |

**Guardrail:** **cap rupiah** kupon (mis. maks. Rp75.000); min. Tour Rp500.000; **weekend only**; expiry 14 hari; 1 kupon aktif/user.

---

## 4. Promo Berbasis Waktu (Momentum)

### 3a. Flash Sale Tanggal Kembar Tour "s.d. 30%" — 🔴 REDESAIN WAJIB
**Masalah:** diskon 30% pada Tour margin 20% = **margin –10% (rugi)**.

**Rekomendasi redesign (pilih salah satu / kombinasi):**

| Opsi | Mekanisme | Aman? |
|---|---|---|
| **A. Kuota loss-leader** | 30% hanya untuk **jumlah unit terbatas** (mis. 20 seat/hari), sisanya diskon normal. Rugi per unit di-*budget* dari marketing sbg alat akuisisi + FOMO. | ✅ jika kuota & budget dikunci |
| **B. Hanya SKU margin tinggi** | 30% hanya untuk Tour private/premium bermargin **≥40%** (30% → sisa 10%). | ✅ |
| **C. Cap diskon aman** | Untuk Tour standar, **maks. diskon = 15%** ("s.d. 30%" hanya untuk opsi A/B). | ✅ |

**Guardrail final:** slot **jam 12.00–13.00**, kuota harian keras, label "s.d. 30%" dengan *fine print* SKU terpilih, server-side quota lock (cegah oversell).

### 3b. Payday Promo Shuttle (tgl 25–5) — ⚠️
Potongan **flat** tiket shuttle untuk momentum pulang kampung.

**Guardrail:** flat discount **≤ 60% margin shuttle** per rute (mis. Shuttle Rp250rb margin Rp30rb → flat maks. **Rp18.000**). Atur per rute (rute margin tipis → flat lebih kecil). Budget/kuota harian.

### 3c. Early Bird Tour 15% (H-30) — ✅ (Rekomendasi kuat)
15% < margin 20% → sisa **5%** + keuntungan cashflow & okupansi lebih pasti.

**Guardrail:** pemesanan **≥30 hari** sebelum keberangkatan; non-refundable atau refund parsial; tidak digabung promo diskon lain.

---

## 5. Promo Taktis Member (Loyalitas) — selaras §3 dokumen loyalitas

### 4a. Selasa Khusus Member (Shuttle lebih murah) — ✅
Tier **Silver & Gold** dapat harga khusus shuttle tiap Selasa.

**Guardrail:** diskon **10–15%** (≤ margin 12%… ⚠️ 15% > 12% → gunakan **maks. 10%** untuk shuttle margin tipis, atau flat Rp aman). **Tidak menumpuk** dengan diskon otomatis tier (pilih yang terbesar, bukan dijumlah).

### 4b. Kado Ulang Tahun — kupon Pesawat (disubsidi Tour) — ✅
Kupon potongan **Tiket Pesawat** masuk otomatis di hari ulang tahun member. Karena margin pesawat tak bisa menanggung, biayanya **marketing-funded dari pool margin Tour**.

| Tier | Nilai kupon | Sumber |
|---|---|---|
| Silver | Rp25.000 | pool margin Tour |
| Gold | Rp50.000 | pool margin Tour |
| Platinum | Rp100.000 | pool margin Tour |

**Guardrail:** 1x/tahun/member; expiry 30 hari; min. transaksi pesawat; budget tahunan.

---

## 6. Aturan Global (WAJIB di-enforce server-side)

### 6.1 Stacking (Penumpukan)
| Kombinasi | Boleh? |
|---|---|
| Redemption **Poin** + kode promo diskon | ❌ Tidak (pilih salah satu, ambil yang terbesar) |
| Diskon otomatis tier + 1 kode promo | ❌ Tidak (ambil yang terbesar) |
| Welcome bonus (user baru) + poin 2x transaksi pertama | ✅ Boleh (keduanya akuisisi, sekali seumur akun) |
| Cross-sell bundling + Early Bird | ⚠️ Boleh bila total diskon ≤ margin penyubsidi (validasi server) |

**Aturan umum:** engine promo memilih **kombinasi diskon terbesar yang lolos guardrail margin**, lalu memblokir sisanya. Semua dihitung dari **harga tervalidasi server**, bukan input client.

### 6.2 Anti-Fraud & Abuse
- 1 promo akuisisi / identitas (email + OTP HP + fingerprint device & metode bayar).
- Semua diskon **batal + clawback** bila transaksi di-refund/cancel.
- **Kuota harian** per promo + auto-off saat budget cap tercapai.
- Kupon **non-transferable**, terikat akun, ada `expiry`.
- Blokir pola *self-referral* / kolusi (device/IP/payment sama).

### 6.3 Kalender Momentum (ringkas)
| Waktu | Promo |
|---|---|
| Tanggal kembar (9.9, 10.10, …), 12.00–13.00 | Flash Sale Tour (opsi A/B) |
| Tgl 25 – 5 | Payday Shuttle |
| Setiap Selasa | Member Shuttle |
| H-30 sebelum trip | Early Bird Tour |
| Hari ulang tahun member | Kado Ultah kupon Pesawat |
| Sepanjang waktu (user baru) | Welcome Bundling + Double Point |

---

## 7. Parameter Konfigurasi untuk Developer

Simpan sebagai config (tabel `promo_rules` / `settings`), bukan hardcode:

| Key | Nilai contoh |
|---|---|
| `welcome.tour_discount_rp` / `welcome.shuttle_voucher_rp` | 50000 / 10000 |
| `welcome.min_tour_rp` / `expiry_days` / `per_identity` | 500000 / 30 / 1 |
| `first_txn.point_multiplier` / `cap_points` | 2.0 / 50000 |
| `xsell.tour_to_shuttle_pct` / `cap_shuttle_price_rp` | 50 / 300000 |
| `xsell.flight_to_shuttle_rp` | 15000 |
| `xsell.shuttle_to_tour_coupon_pct` / `cap_rp` / `min_tour_rp` | 10 / 75000 / 500000 |
| `flash.tour_max_pct_standard` / `premium_sku_pct` / `daily_quota` | 15 / 30 / 20 |
| `payday.shuttle_flat_max_pct_of_margin` | 60 |
| `earlybird.tour_pct` / `min_days_before` | 15 / 30 |
| `member.tuesday_shuttle_pct` (Silver/Gold) | 10 |
| `birthday.flight_coupon_rp` (Silver/Gold/Platinum) | 25000/50000/100000 |
| `stacking.allow_points_with_promo` | false |
| `budget.monthly_cap_rp.{promo}` | per promo |

### Saran model data
| Tabel | Field kunci |
|---|---|
| `promos` | `code`, `type`, `funding_source` (margin/marketing), `discount_rule`, `caps`, `eligibility`, `budget_cap`, `starts_at`, `ends_at`, `daily_quota` |
| `promo_redemptions` | `user_id`, `promo_id`, `order_id`, `amount`, `status`, `created_at` |
| `promo_budgets` | `promo_id`, `period`, `cap_rp`, `spent_rp` |

Engine checkout: hitung semua diskon yang eligible → filter yang lolos guardrail margin & stacking → terapkan **satu kombinasi terbesar** → catat ke `promo_redemptions` + kurangi `promo_budgets`.

---

*Sebelum go-live: jalankan simulasi P&L 4–8 minggu pertama untuk kalibrasi flash sale (3a) dan cross-sell (2a/2c), karena itulah tiga promo dengan risiko subsidi terbesar.*
