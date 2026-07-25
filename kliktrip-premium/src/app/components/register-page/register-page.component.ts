import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule, Router } from '@angular/router';
import { ClerkService } from '../../services/clerk.service';

type Step = 'choose' | 'email-form' | 'verify-email' | 'complete-google';

@Component({
  selector: 'app-register-page',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './register-page.component.html',
  styleUrl: './register-page.component.css',
})
export class RegisterPageComponent implements OnInit, OnDestroy {
  step: Step = 'choose';
  loading = false;
  errorMsg = '';
  showPassword = false;

  // Form fields
  fullName  = '';
  phone     = '';
  email     = '';
  password  = '';

  // Email verification (OTP 6 digit)
  otp: string[] = ['', '', '', '', '', ''];
  verifying = false;
  resendCooldown = 0;
  private resendTimer: any = null;

  // Phone country
  countryCode = '+62';
  countries = [
    { code: '+62', flag: '🇮🇩', name: 'Indonesia' },
    { code: '+60', flag: '🇲🇾', name: 'Malaysia' },
    { code: '+65', flag: '🇸🇬', name: 'Singapura' },
    { code: '+63', flag: '🇵🇭', name: 'Filipina' },
    { code: '+66', flag: '🇹🇭', name: 'Thailand' },
    { code: '+1',  flag: '🇺🇸', name: 'USA' },
  ];
  showCountryDrop = false;

  constructor(public clerk: ClerkService, private router: Router) {}

  ngOnDestroy(): void {
    clearInterval(this.resendTimer);
  }

  /** Email disamarkan untuk privasi: a***@gmail.com */
  get maskedEmail(): string {
    const e = this.email.trim();
    const at = e.indexOf('@');
    if (at <= 1) return e;
    return e[0] + '***' + e.slice(at);
  }

  async ngOnInit(): Promise<void> {
    await this.clerk.ensureLoaded();
    if (this.clerk.isSignedIn()) {
      this.router.navigate(['/']);
      return;
    }
    // Check if returning from Google OAuth with pending sign-up
    this._checkPendingSignUp();
  }

  private _checkPendingSignUp(): void {
    try {
      const signUp = (this.clerk as any)._clerk?.client?.signUp;
      if (signUp && signUp.status === 'missing_requirements') {
        // Pre-fill from Google data
        this.fullName = [signUp.firstName, signUp.lastName].filter(Boolean).join(' ');
        this.email    = signUp.emailAddress ?? '';
        this.step     = 'complete-google';
      }
    } catch {}
  }

  // ── Google OAuth ─────────────────────────────────────────────
  async registerWithGoogle(): Promise<void> {
    this.loading = true; this.errorMsg = '';
    try { await this.clerk.signInWithGoogle(); }
    catch (e: any) { this.errorMsg = e?.message ?? 'Gagal daftar dengan Google'; this.loading = false; }
  }

  async registerWithSocial(provider: string): Promise<void> {
    this.loading = true; this.errorMsg = '';
    try { await this.clerk.signInWithOAuth(provider); }
    catch (e: any) { this.errorMsg = e?.message ?? 'Gagal daftar'; this.loading = false; }
  }

  // ── Email/Phone form ─────────────────────────────────────────
  showEmailForm(): void {
    this.step = 'email-form';
    this.errorMsg = '';
  }

  backToChoose(): void {
    this.step = 'choose';
    this.errorMsg = '';
  }

  selectCountry(c: { code: string; flag: string; name: string }): void {
    this.countryCode = c.code;
    this.showCountryDrop = false;
  }

  get nameParts(): { first: string; last: string } {
    const parts = this.fullName.trim().split(' ');
    return { first: parts[0] ?? '', last: parts.slice(1).join(' ') };
  }

  async submitEmailForm(): Promise<void> {
    this.errorMsg = '';
    if (!this.fullName.trim()) { this.errorMsg = 'Nama lengkap wajib diisi'; return; }
    if (!this.email.trim())    { this.errorMsg = 'Email wajib diisi'; return; }
    if (!this.password)        { this.errorMsg = 'Password wajib diisi'; return; }
    if (this.password.length < 8) { this.errorMsg = 'Password minimal 8 karakter'; return; }

    this.loading = true;
    try {
      const { first, last } = this.nameParts;
      const signUp = await this.clerk.createSignUp({
        firstName:    first,
        lastName:     last,
        emailAddress: this.email.trim(),
        password:     this.password,
        phoneNumber:  this.phone ? this.countryCode + this.phone : undefined,
      });
      if (signUp?.status === 'complete') {
        this.router.navigate(['/']);
      } else {
        // Clerk mewajibkan verifikasi email → kirim kode 6 digit lalu
        // pindah ke layar verifikasi.
        await this.clerk.prepareEmailVerification();
        this.step = 'verify-email';
        this.startResendCooldown();
        setTimeout(() => this.focusOtp(0), 100);
      }
    } catch (e: any) {
      this.errorMsg = e?.errors?.[0]?.longMessage ?? e?.message ?? 'Gagal membuat akun';
    } finally {
      this.loading = false;
    }
  }

  // ── Verifikasi email (OTP) ───────────────────────────────────
  get otpCode(): string { return this.otp.join(''); }

  /**
   * KUNCI perbaikan: track kotak OTP berdasarkan INDEX, bukan nilai.
   * Tanpa ini, array berisi string kosong duplikat ('') membuat Angular
   * membuat ulang & menggeser elemen DOM saat satu kotak berubah — itulah
   * penyebab digit pertama "loncat" ke kotak kedua dan sulit dihapus.
   */
  trackByIndex(index: number): number { return index; }

  /**
   * Input 1 digit → auto pindah ke kotak berikutnya.
   * DOM adalah sumber tampilan (tidak ada binding [value] yang "berkelahi"),
   * model `otp[]` hanya untuk hitung kode & status tombol.
   */
  onOtpInput(index: number, event: Event): void {
    const input = event.target as HTMLInputElement;
    const digits = input.value.replace(/\D/g, '');

    // Jika user paste banyak digit ke satu kotak → sebar ke kotak-kotak.
    if (digits.length > 1) {
      this.fillOtpFrom(index, digits);
      return;
    }

    const digit = digits.slice(-1);
    this.otp[index] = digit;
    input.value = digit;

    if (digit && index < 5) this.focusOtp(index + 1);
    this.maybeAutoSubmit();
  }

  /** Backspace: hapus kotak ini; jika sudah kosong, mundur & hapus kotak sebelumnya. */
  onOtpKeydown(index: number, event: KeyboardEvent): void {
    if (event.key === 'Backspace') {
      if (this.otp[index]) {
        this.otp[index] = '';
        this.setBoxValue(index, '');
      } else if (index > 0) {
        event.preventDefault();
        this.otp[index - 1] = '';
        this.setBoxValue(index - 1, '');
        this.focusOtp(index - 1);
      }
    } else if (event.key === 'ArrowLeft' && index > 0) {
      this.focusOtp(index - 1);
    } else if (event.key === 'ArrowRight' && index < 5) {
      this.focusOtp(index + 1);
    }
  }

  /** Paste kode 6 digit sekaligus. */
  onOtpPaste(event: ClipboardEvent): void {
    event.preventDefault();
    const text = (event.clipboardData?.getData('text') ?? '').replace(/\D/g, '');
    this.fillOtpFrom(0, text);
  }

  /** Isi kotak mulai dari `start` dengan deretan digit. */
  private fillOtpFrom(start: number, digits: string): void {
    let i = start;
    for (const ch of digits) {
      if (i > 5) break;
      this.otp[i] = ch;
      this.setBoxValue(i, ch);
      i++;
    }
    this.focusOtp(Math.min(i, 5));
    this.maybeAutoSubmit();
  }

  private maybeAutoSubmit(): void {
    if (this.otp.every(d => d !== '') && !this.verifying) {
      this.submitVerification();
    }
  }

  private setBoxValue(index: number, val: string): void {
    const el = document.getElementById('otp-' + index) as HTMLInputElement | null;
    if (el) el.value = val;
  }

  private clearOtpBoxes(): void {
    this.otp = ['', '', '', '', '', ''];
    for (let i = 0; i < 6; i++) this.setBoxValue(i, '');
  }

  private focusOtp(index: number): void {
    const el = document.getElementById('otp-' + index) as HTMLInputElement | null;
    el?.focus();
  }

  async submitVerification(): Promise<void> {
    if (this.otpCode.length !== 6 || this.verifying) return;
    this.verifying = true; this.errorMsg = '';
    try {
      const result = await this.clerk.attemptEmailVerification(this.otpCode);
      if (result?.status === 'complete') {
        this.router.navigate(['/']);
      } else {
        this.errorMsg = 'Verifikasi belum selesai. Coba lagi.';
      }
    } catch (e: any) {
      this.errorMsg = e?.errors?.[0]?.longMessage ?? 'Kode salah atau kedaluwarsa. Coba lagi.';
      this.clearOtpBoxes();
      this.focusOtp(0);
    } finally {
      this.verifying = false;
    }
  }

  async resendCode(): Promise<void> {
    if (this.resendCooldown > 0) return;
    this.errorMsg = '';
    try {
      await this.clerk.prepareEmailVerification();
      this.startResendCooldown();
    } catch (e: any) {
      this.errorMsg = e?.errors?.[0]?.longMessage ?? 'Gagal mengirim ulang kode.';
    }
  }

  private startResendCooldown(): void {
    this.resendCooldown = 60;
    clearInterval(this.resendTimer);
    this.resendTimer = setInterval(() => {
      this.resendCooldown--;
      if (this.resendCooldown <= 0) clearInterval(this.resendTimer);
    }, 1000);
  }

  backToEmailForm(): void {
    this.step = 'email-form';
    this.otp = ['', '', '', '', '', ''];
    this.errorMsg = '';
    clearInterval(this.resendTimer);
  }

  /** Kode terisi penuh & tidak sedang memverifikasi. */
  get otpReady(): boolean {
    return this.otp.every(d => d !== '') && !this.verifying;
  }

  // ── Complete Google sign-up ───────────────────────────────────
  async submitGoogleComplete(): Promise<void> {
    this.errorMsg = '';
    if (!this.phone) { this.errorMsg = 'Nomor telepon wajib diisi'; return; }
    this.loading = true;
    try {
      const { first, last } = this.nameParts;
      const signUp = await this.clerk.updateSignUp({
        firstName:   first,
        lastName:    last,
        phoneNumber: this.countryCode + this.phone,
      });
      if (signUp?.status === 'complete') {
        this.router.navigate(['/']);
      }
    } catch (e: any) {
      this.errorMsg = e?.errors?.[0]?.longMessage ?? e?.message ?? 'Gagal menyimpan data';
    } finally {
      this.loading = false;
    }
  }
}
