import { Component, OnInit, OnDestroy, AfterViewChecked, ElementRef, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { TravelService, PackageBookingState } from '../../services/travel.service';
import { ClerkService } from '../../services/clerk.service';

declare global {
  interface Window {
    snap?: {
      pay: (token: string, opts?: { onSuccess?: Function; onPending?: Function; onError?: Function; onClose?: Function }) => void;
    };
  }
}

interface PayMethod {
  id: string;
  label: string;
  category: 'va' | 'card' | 'paylater' | 'ewallet' | 'instant';
  icon: string; // asset path
  extraNote?: string;
}

@Component({
  selector: 'app-package-payment',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './package-payment.component.html',
  styleUrls: ['./package-payment.component.css'],
})
export class PackagePaymentComponent implements OnInit, OnDestroy, AfterViewChecked {
  private router = inject(Router);
  private travel = inject(TravelService);
  private clerk = inject(ClerkService);
  private host = inject(ElementRef<HTMLElement>);

  ngAfterViewChecked(): void {
    // Move any open modal backdrops out of this component's stacking context (which is trapped
    // inside a `z-index: 30` ancestor) so they properly overlay the site navbar.
    const root: HTMLElement = this.host.nativeElement;
    const backdrops = root.querySelectorAll('.pp-modal-backdrop');
    backdrops.forEach(b => {
      if (b.parentElement !== document.body) document.body.appendChild(b);
    });
  }

  booking: PackageBookingState | null = null;
  orderId = '';

  // Countdown 15 minutes
  private endTs = 0;
  private timerHandle: any = null;
  remainH = '00';
  remainM = '15';
  remainS = '00';

  showAllModal = false;
  selectedMethod: PayMethod | null = null;

  usePromo = false;
  usePoin = false;
  showOrderCollapsed = false;

  readonly methods: PayMethod[] = [
    // Featured (list utama)
    { id: 'bni_va',  label: 'BNI Virtual Account',  category: 'va',   icon: 'assets/BNI VA.png' },
    { id: 'bri_va',  label: 'BRI Virtual Account',  category: 'va',   icon: 'assets/BRI VA.jpg' },
    { id: 'cc',      label: 'Pakai Kartu Kredit/Debit', category: 'card', icon: 'assets/banks/mastercard.svg' },
    // Extended (modal)
    { id: 'bca_va',     label: 'BCA Virtual Account',     category: 'va', icon: 'assets/logo_bca.png' },
    { id: 'mandiri_va', label: 'Mandiri Virtual Account', category: 'va', icon: 'assets/logo-mandiri.svg' },
    { id: 'permata_va', label: 'Permata Virtual Account', category: 'va', icon: 'assets/permata va.png' },
    { id: 'bsi_va',     label: 'BSI Virtual Account',     category: 'va', icon: 'assets/BSI%20VA.jpeg' },

    { id: 'blibli_pl', label: 'Blibli Tiket PayLater', category: 'paylater', icon: 'assets/banks/blibli.svg' },
    { id: 'kredivo',   label: 'Kredivo',               category: 'paylater', icon: 'assets/KREDIVO VA.png' },
    { id: 'akulaku',   label: 'Akulaku',               category: 'paylater', icon: 'assets/AKULAKU VA.png' },

    { id: 'dana',      label: 'DANA',      category: 'ewallet', icon: 'assets/DANA VA.webp' },
    { id: 'gopay',     label: 'GoPay',     category: 'ewallet', icon: 'assets/logo-gopay.svg' },
    { id: 'shopeepay', label: 'ShopeePay', category: 'ewallet', icon: 'assets/banks/shopeepay.svg' },

    { id: 'blu',      label: 'blu',      category: 'instant', icon: 'assets/BLU BCA.webp' },
    { id: 'klikbca',  label: 'KlikBCA',  category: 'instant', icon: 'assets/KLIK BCA VA.png' },
    { id: 'qris',     label: 'QRIS (Semua e-Wallet & M-Banking)', category: 'instant', icon: 'assets/logo-qris.svg' },
  ];

  // ── QRIS modal state ─────────────────────────────────────────
  showQrModal = false;
  qrDataUrl: string | null = null;
  qrExpireS = 900; // 15 minutes
  private qrTimer: any = null;
  qrExpireLabel = '15:00';

  featuredList: PayMethod[] = [];

  get featuredMethods(): PayMethod[] {
    if (this.featuredList.length === 0) {
      this.featuredList = this.methods.slice(0, 3);
    }
    if (this.selectedMethod && !this.featuredList.some(m => m.id === this.selectedMethod?.id)) {
      return [...this.featuredList, this.selectedMethod];
    }
    return this.featuredList;
  }

  vaMethods(): PayMethod[] {
    const order = ['bca_va', 'mandiri_va', 'bni_va', 'bri_va', 'permata_va', 'bsi_va'];
    return order.map(id => this.methods.find(m => m.id === id)).filter((m): m is PayMethod => !!m);
  }
  paylaterMethods(): PayMethod[]  { return this.methods.filter(m => m.category === 'paylater'); }
  ewalletMethods(): PayMethod[]   { return this.methods.filter(m => m.category === 'ewallet'); }
  instantMethods(): PayMethod[]   { return this.methods.filter(m => m.category === 'instant'); }

  ngOnInit(): void {
    this.featuredList = this.methods.slice(0, 3);
    this.booking = this.travel.packageBookingData;
    if (!this.booking) {
      this.router.navigate(['/']);
      return;
    }
    this.orderId = this.generateOrderId();
    this.endTs = Date.now() + 15 * 60 * 1000;
    this.tick();
    this.timerHandle = setInterval(() => this.tick(), 1000);
  }

  ngOnDestroy(): void {
    if (this.timerHandle) clearInterval(this.timerHandle);
    if (this.qrTimer) clearInterval(this.qrTimer);
    if (typeof document !== 'undefined') {
      document.body.style.overflow = '';
      document.documentElement.style.overflow = '';
    }
    // Also remove any portaled backdrops left in body
    document.querySelectorAll('body > .pp-modal-backdrop').forEach(el => el.remove());
  }

  private tick(): void {
    let ms = this.endTs - Date.now();
    if (ms < 0) ms = 0;
    const total = Math.floor(ms / 1000);
    const h = Math.floor(total / 3600);
    const m = Math.floor((total % 3600) / 60);
    const s = total % 60;
    this.remainH = String(h).padStart(2, '0');
    this.remainM = String(m).padStart(2, '0');
    this.remainS = String(s).padStart(2, '0');
    if (ms === 0 && this.timerHandle) {
      clearInterval(this.timerHandle);
      this.timerHandle = null;
    }
  }

  private generateOrderId(): string {
    const rand = Math.floor(1_000_000_000 + Math.random() * 8_999_999_999);
    return String(rand);
  }

  selectMethod(m: PayMethod): void {
    this.selectedMethod = m;
    if (!this.featuredList.some(item => item.id === m.id)) {
      this.featuredList.push(m);
    }
    this.showAllModal = false;
    this.updateBodyLock();
  }

  openAll(): void {
    this.showAllModal = true;
    this.updateBodyLock();
  }
  closeAll(): void {
    this.showAllModal = false;
    this.updateBodyLock();
  }

  private scrollLockActive = false;
  private lockedScrollY = 0;

  private preventScroll = (e: Event) => {
    const target = e.target as HTMLElement | null;
    // Allow scrolling INSIDE the modal body
    if (target && (target.closest('.pp-modal') || target.closest('.pp-modal-body') || target.closest('.pp-qr-body'))) {
      return;
    }
    e.preventDefault();
  };

  private preventKeyScroll = (e: KeyboardEvent) => {
    const keys = ['ArrowDown','ArrowUp','PageDown','PageUp','Home','End',' '];
    const target = e.target as HTMLElement | null;
    if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable)) return;
    if (keys.includes(e.key)) e.preventDefault();
  };

  private updateBodyLock(): void {
    const anyOpen = this.showAllModal || this.showQrModal || this.showInstructions;
    if (typeof document === 'undefined') return;

    if (anyOpen && !this.scrollLockActive) {
      this.lockedScrollY = window.scrollY || document.documentElement.scrollTop;
      const scrollBarW = window.innerWidth - document.documentElement.clientWidth;
      document.body.style.position = 'fixed';
      document.body.style.top = `-${this.lockedScrollY}px`;
      document.body.style.left = '0';
      document.body.style.right = '0';
      document.body.style.width = '100%';
      if (scrollBarW > 0) document.body.style.paddingRight = `${scrollBarW}px`;
      document.documentElement.style.overflow = 'hidden';
      window.addEventListener('wheel', this.preventScroll, { passive: false });
      window.addEventListener('touchmove', this.preventScroll, { passive: false });
      window.addEventListener('keydown', this.preventKeyScroll, { passive: false });
      this.scrollLockActive = true;
    } else if (!anyOpen && this.scrollLockActive) {
      document.body.style.position = '';
      document.body.style.top = '';
      document.body.style.left = '';
      document.body.style.right = '';
      document.body.style.width = '';
      document.body.style.paddingRight = '';
      document.documentElement.style.overflow = '';
      window.removeEventListener('wheel', this.preventScroll);
      window.removeEventListener('touchmove', this.preventScroll);
      window.removeEventListener('keydown', this.preventKeyScroll);
      window.scrollTo(0, this.lockedScrollY);
      this.scrollLockActive = false;
    }
  }

  goBack(): void {
    this.router.navigate(['/booking/package-checkout']);
  }

  isProcessingPayment = false;
  paymentError = '';

  // ── Instruction modal state ─────────────────────────────────
  showInstructions = false;
  instrPaymentType: 'va' | 'echannel' | 'qr' | '' = '';
  instrVaNumber = '';
  instrBank = '';
  instrBillKey = '';
  instrBillerCode = '';
  instrQrUrl = '';
  instrExpiredAt = '';
  instrCopied = false;
  instrDisplayLabel = '';
  instrDisplayIcon = '';

  async payNow(): Promise<void> {
    if (!this.selectedMethod || this.isProcessingPayment) return;

    if (this.selectedMethod.id === 'qris') {
      this.openQrisPayment();
      return;
    }

    this.isProcessingPayment = true;
    this.paymentError = '';

    try {
      // Token Clerk wajib dikirim manual di sini karena fetch() tidak lewat
      // HTTP interceptor Angular. Backend (clerk.auth) memverifikasinya.
      const token = await this.clerk.getToken();

      // Kirim rincian tiket (nama + qty) agar backend bisa hitung ulang &
      // memvalidasi total — mencegah manipulasi harga.
      const items = (this.booking?.ticketItems ?? []).map((t: any) => ({
        name: t.name,
        qty: t.qty,
      }));

      const res = await fetch('https://gmm-travel-production.up.railway.app/api/charge', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
        },
        body: JSON.stringify({
          orderId: this.orderId,
          amount: this.booking?.totalPriceNumber ?? 0,
          customerName: this.booking?.contactName ?? 'Customer',
          customerEmail: this.booking?.contactEmail ?? '',
          customerPhone: this.booking?.contactPhone ?? '08000000000',
          packageName: this.booking?.packageName ?? '',
          items,
          paymentMethod: this.selectedMethod.id,
        }),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err?.message ?? `Server error ${res.status}`);
      }

      const data = await res.json();
      this.showPaymentInstructions(data);
    } catch (e: any) {
      this.paymentError = e?.message ?? 'Gagal menghubungi server. Pastikan backend Laravel aktif.';
    } finally {
      this.isProcessingPayment = false;
    }
  }

  private showPaymentInstructions(data: any): void {
    this.instrPaymentType = data.payment_type ?? '';
    const ins = data.instructions ?? {};
    this.instrVaNumber    = ins.va_number    ?? '';
    this.instrBank        = ins.bank         ?? this.selectedMethod?.id ?? '';
    this.instrBillKey     = ins.bill_key     ?? '';
    this.instrBillerCode  = ins.biller_code  ?? '';
    const qrData = ins.qr_string ?? ins.qr_code ?? '';
    this.instrQrUrl = qrData
      ? `https://api.qrserver.com/v1/create-qr-code/?size=240x240&margin=8&data=${encodeURIComponent(qrData)}`
      : '';
    this.instrExpiredAt   = data.expired_at
      ? new Date(data.expired_at).toLocaleString('id-ID', { dateStyle: 'long', timeStyle: 'short' })
      : '';
    this.instrDisplayLabel = this.selectedMethod?.label ?? this.bankLabel(this.instrBank);
    this.instrDisplayIcon  = this.selectedMethod?.icon  ?? this.bankIcon(this.instrBank);
    this.instrCopied = false;
    this.showInstructions = true;
    this.updateBodyLock();
  }

  closeInstructions(): void {
    this.showInstructions = false;
    this.updateBodyLock();
  }

  copyVa(): void {
    const val = this.instrPaymentType === 'echannel' ? this.instrBillKey : this.instrVaNumber;
    navigator.clipboard?.writeText(val).then(() => {
      this.instrCopied = true;
      setTimeout(() => { this.instrCopied = false; }, 2000);
    });
  }

  bankLabel(bank: string): string {
    const map: Record<string,string> = {
      bca: 'BCA', bni: 'BNI', bri: 'BRI', mandiri: 'Mandiri',
      permata: 'Permata', bsi: 'BSI', other: 'Bank Lain',
      bni_va: 'BNI', bri_va: 'BRI', bca_va: 'BCA',
      mandiri_va: 'Mandiri', permata_va: 'Permata', bsi_va: 'BSI',
    };
    return map[bank.toLowerCase()] ?? bank.toUpperCase();
  }

  bankIcon(bank: string): string {
    const map: Record<string,string> = {
      bca: 'assets/logo_bca.png', bni: 'assets/BNI VA.png',
      bri: 'assets/BRI VA.jpg', mandiri: 'assets/logo-mandiri.svg',
      permata: 'assets/permata va.png', bsi: 'assets/BSI VA.jpeg',
      bni_va: 'assets/BNI VA.png', bri_va: 'assets/BRI VA.jpg',
      bca_va: 'assets/logo_bca.png', mandiri_va: 'assets/logo-mandiri.svg',
      permata_va: 'assets/permata va.png', bsi_va: 'assets/BSI VA.jpeg',
    };
    return map[bank.toLowerCase()] ?? 'assets/banks/bca.svg';
  }

  private openQrisPayment(): void {
    // Midtrans QRIS payload (in real flow: fetch qr_string from backend /charge with payment_type=qris)
    // Here we encode an EMV-QR-like payload with order details for demo.
    const amount = this.booking?.totalPriceNumber ?? 0;
    const merchantName = 'GMM GLOBAL EXPLORE';
    // EMVCo-style placeholder payload; a real integration would use qr_string from Midtrans response.
    const payload = [
      '00020101021226',
      '580014ID.CO.QRIS.WWW',
      `0215ID${this.orderId}`,
      '5204581253033605802ID',
      `5913${merchantName}`,
      '6007JAKARTA',
      '61051012061054040',
      `5405${amount}`,
      '6304ABCD',
    ].join('');

    // Use QR image API (self-contained, no npm dep). In production, replace with Midtrans qr_string
    // returned from /charge and render via a client-side QR encoder or backend-rendered image.
    const encoded = encodeURIComponent(payload);
    this.qrDataUrl = `https://api.qrserver.com/v1/create-qr-code/?size=320x320&margin=8&data=${encoded}`;
    this.showQrModal = true;
    this.updateBodyLock();
    this.qrExpireS = 900;
    this.updateQrLabel();
    this.qrTimer = setInterval(() => {
      this.qrExpireS -= 1;
      if (this.qrExpireS <= 0) {
        clearInterval(this.qrTimer);
        this.qrTimer = null;
        this.qrExpireS = 0;
      }
      this.updateQrLabel();
    }, 1000);
  }

  private updateQrLabel(): void {
    const m = Math.floor(this.qrExpireS / 60);
    const s = this.qrExpireS % 60;
    this.qrExpireLabel = `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  }

  closeQrModal(): void {
    this.showQrModal = false;
    this.updateBodyLock();
    if (this.qrTimer) {
      clearInterval(this.qrTimer);
      this.qrTimer = null;
    }
  }

  get totalDisplay(): string {
    return this.booking?.totalPriceFormatted ?? 'IDR 0';
  }

  get pointsEarned(): number {
    const num = this.booking?.totalPriceNumber ?? 0;
    return Math.floor(num * 0.0026); // ~0.26%
  }
}
