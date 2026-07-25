import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { ClerkService } from '../../services/clerk.service';

type Step = 'choose' | 'email-input' | 'email-password';

@Component({
  selector: 'app-login-page',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './login-page.component.html',
  styleUrl: './login-page.component.css',
})
export class LoginPageComponent implements OnInit {
  step: Step = 'choose';
  loading = false;
  errorMsg = '';
  showPassword = false;

  emailOrPhone = '';
  password = '';

  constructor(public clerk: ClerkService, private router: Router) {}

  async ngOnInit(): Promise<void> {
    await this.clerk.ensureLoaded();
    if (this.clerk.isSignedIn()) {
      this.router.navigate(['/']);
    }
  }

  // ── Social OAuth ─────────────────────────────────────────────
  async loginWithGoogle(): Promise<void> {
    this.loading = true; this.errorMsg = '';
    try { await this.clerk.signInWithGoogle(); }
    catch (e: any) { this.errorMsg = e?.message ?? 'Gagal masuk dengan Google'; this.loading = false; }
  }

  async loginWithSocial(provider: string): Promise<void> {
    this.loading = true; this.errorMsg = '';
    try { await this.clerk.signInWithOAuth(provider); }
    catch (e: any) { this.errorMsg = e?.message ?? 'Gagal masuk'; this.loading = false; }
  }

  // ── Email/Phone step 1 ────────────────────────────────────────
  showEmailInput(): void {
    this.step = 'email-input';
    this.errorMsg = '';
  }

  continueToPassword(): void {
    const val = this.emailOrPhone.trim();
    if (!val) { this.errorMsg = 'Masukkan email atau nomor telepon'; return; }
    this.errorMsg = '';
    this.step = 'email-password';
  }

  // ── Email/Phone step 2 — submit login ────────────────────────
  async submitLogin(): Promise<void> {
    if (!this.password) { this.errorMsg = 'Masukkan password'; return; }
    this.errorMsg = '';
    this.loading = true;
    try {
      await this.clerk.signInWithEmailPassword(this.emailOrPhone.trim(), this.password);
      this.router.navigate(['/']);
    } catch (e: any) {
      this.errorMsg = e?.errors?.[0]?.longMessage ?? e?.message ?? 'Email/password salah';
    } finally {
      this.loading = false;
    }
  }

  // ── Navigation ────────────────────────────────────────────────
  backToChoose(): void  { this.step = 'choose'; this.errorMsg = ''; }
  backToInput(): void   { this.step = 'email-input'; this.errorMsg = ''; this.password = ''; }

  openForgotPassword(): void {
    this.clerk.openSignIn();
  }
}
