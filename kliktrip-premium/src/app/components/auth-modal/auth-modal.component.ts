import {
  Component, Input, Output, EventEmitter, OnChanges, SimpleChanges, OnDestroy
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ClerkService } from '../../services/clerk.service';

type AuthStep = 'choose' | 'email-form';

@Component({
  selector: 'app-auth-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './auth-modal.component.html',
  styleUrl: './auth-modal.component.css',
})
export class AuthModalComponent implements OnChanges, OnDestroy {
  @Input() mode: 'signin' | 'signup' | null = null;
  @Output() closed = new EventEmitter<void>();

  step: AuthStep = 'choose';
  emailValue = '';
  loading = false;
  errorMsg = '';

  constructor(public clerk: ClerkService) {}

  get isOpen(): boolean { return this.mode !== null; }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['mode']) {
      if (this.mode) {
        document.body.style.overflow = 'hidden';
        this.step = 'choose';
        this.emailValue = '';
        this.errorMsg = '';
      } else {
        document.body.style.overflow = '';
      }
    }
  }

  ngOnDestroy(): void {
    document.body.style.overflow = '';
  }

  close(): void { this.closed.emit(); }

  switchMode(): void {
    this.mode = this.mode === 'signin' ? 'signup' : 'signin';
    this.step = 'choose';
    this.emailValue = '';
    this.errorMsg = '';
  }

  async loginWithGoogle(): Promise<void> {
    this.loading = true;
    this.errorMsg = '';
    try {
      await this.clerk.ensureLoaded();
      await this.clerk.signInWithGoogle();
    } catch (e: any) {
      this.errorMsg = e?.message ?? 'Gagal masuk dengan Google';
    } finally {
      this.loading = false;
    }
  }

  async loginWithSocial(provider: string): Promise<void> {
    this.loading = true;
    this.errorMsg = '';
    try {
      await this.clerk.ensureLoaded();
      await this.clerk.signInWithOAuth(provider as any);
    } catch (e: any) {
      this.errorMsg = e?.message ?? `Gagal masuk dengan ${provider}`;
    } finally {
      this.loading = false;
    }
  }

  showEmailForm(): void {
    this.step = 'email-form';
    this.emailValue = '';
    this.errorMsg = '';
  }

  backToChoose(): void {
    this.step = 'choose';
    this.errorMsg = '';
  }

  async continueWithEmail(): Promise<void> {
    if (!this.emailValue.trim()) return;
    this.loading = true;
    this.errorMsg = '';
    try {
      await this.clerk.ensureLoaded();
      // Open Clerk's built-in popup pre-filled to email step
      if (this.mode === 'signin') {
        this.clerk.openSignIn();
      } else {
        this.clerk.openSignUp();
      }
      this.close();
    } catch (e: any) {
      this.errorMsg = e?.message ?? 'Terjadi kesalahan';
    } finally {
      this.loading = false;
    }
  }
}
