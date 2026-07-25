import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule, Router } from '@angular/router';
import { ClerkService } from '../../services/clerk.service';

type Step = 'choose' | 'email-form' | 'complete-google';

@Component({
  selector: 'app-register-page',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './register-page.component.html',
  styleUrl: './register-page.component.css',
})
export class RegisterPageComponent implements OnInit {
  step: Step = 'choose';
  loading = false;
  errorMsg = '';
  showPassword = false;

  // Form fields
  fullName  = '';
  phone     = '';
  email     = '';
  password  = '';

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
        // Needs email verification
        this.errorMsg = 'Cek email Anda untuk verifikasi akun.';
      }
    } catch (e: any) {
      this.errorMsg = e?.errors?.[0]?.longMessage ?? e?.message ?? 'Gagal membuat akun';
    } finally {
      this.loading = false;
    }
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
