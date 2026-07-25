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

  /** Input 1 digit → auto pindah ke kotak berikutnya. */
  onOtpInput(index: number, event: Event): void {
    const input = event.target as HTMLInputElement;
    const val = input.value.replace(/\D/g, '');
    this.otp[index] = val.slice(-1);
    input.value = this.otp[index];
    if (this.otp[index] && index < 5) this.focusOtp(index + 1);
    if (this.otpCode.length === 6) this.submitVerification();
  }

  /** Backspace pada kotak kosong → mundur ke kotak sebelumnya. */
  onOtpKeydown(index: number, event: KeyboardEvent): void {
    if (event.key === 'Backspace' && !this.otp[index] && index > 0) {
      this.focusOtp(index - 1);
    }
  }

  /** Paste kode 6 digit sekaligus. */
  onOtpPaste(event: ClipboardEvent): void {
    event.preventDefault();
    const text = (event.clipboardData?.getData('text') ?? '').replace(/\D/g, '').slice(0, 6);
    for (let i = 0; i < 6; i++) this.otp[i] = text[i] ?? '';
    if (this.otpCode.length === 6) this.submitVerification();
    else this.focusOtp(Math.min(text.length, 5));
  }

  private focusOtp(index: number): void {
    const el = document.getElementById('otp-' + index) as HTMLInputElement | null;
    el?.focus();
    el?.select();
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
      this.otp = ['', '', '', '', '', ''];
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
