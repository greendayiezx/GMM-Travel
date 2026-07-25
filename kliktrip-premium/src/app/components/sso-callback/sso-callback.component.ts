import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { ClerkService } from '../../services/clerk.service';
import { LoaderOneComponent } from '../loader-one/loader-one.component';

@Component({
  selector: 'app-sso-callback',
  standalone: true,
  imports: [CommonModule, LoaderOneComponent],
  template: `
    <div class="sso-loading">
      <app-loader-one></app-loader-one>
      <p class="sso-text">Memproses login…</p>
    </div>
  `,
  styles: [`
    .sso-loading {
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 16px;
      background: linear-gradient(135deg, #b8d9f5 0%, #ddeeff 30%, #f5fbff 55%, #fffde0 78%, #eef7d0 100%);
    }
    .sso-text {
      color: #555;
      font-size: 15px;
      font-family: 'Inter', sans-serif;
    }
  `],
})
export class SsoCallbackComponent implements OnInit {
  constructor(private clerk: ClerkService, private router: Router) {}

  async ngOnInit(): Promise<void> {
    try {
      await this.clerk.ensureLoaded();
      await this.clerk.handleRedirectCallback();
    } catch {}
    this.router.navigate(['/']);
  }
}
