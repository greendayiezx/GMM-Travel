import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-infinity-loader',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div role="status" aria-live="polite" class="infinity-loader-wrap" [style.width.px]="size" [style.height.px]="size">
      <svg [attr.width]="size" [attr.height]="size" viewBox="-2 -2 44 44" aria-hidden="true">
        <path class="track" fill="none" stroke-width="4" pathLength="100"
          d="M29.76 18.72 c0 7.28-3.92 13.6-9.84 16.96 c-2.88 1.68-6.24 2.64-9.84 2.64 c-3.6 0-6.88-0.96-9.76-2.64 c0-7.28 3.92-13.52 9.84-16.96 c2.88-1.68 6.24-2.64 9.76-2.64 S26.88 17.04 29.76 18.72 c5.84 3.36 9.76 9.68 9.84 16.96 c-2.88 1.68-6.24 2.64-9.76 2.64 c-3.6 0-6.88-0.96-9.84-2.64 c-5.84-3.36-9.76-9.68-9.76-16.96 c0-7.28 3.92-13.6 9.76-16.96 C25.84 5.12 29.76 11.44 29.76 18.72z"/>
        <path class="dash" fill="none" stroke-width="4"
          stroke-dasharray="15, 85" stroke-dashoffset="0" stroke-linecap="round" pathLength="100"
          [style.stroke]="color"
          d="M29.76 18.72 c0 7.28-3.92 13.6-9.84 16.96 c-2.88 1.68-6.24 2.64-9.84 2.64 c-3.6 0-6.88-0.96-9.76-2.64 c0-7.28 3.92-13.52 9.84-16.96 c2.88-1.68 6.24-2.64 9.76-2.64 S26.88 17.04 29.76 18.72 c5.84 3.36 9.76 9.68 9.84 16.96 c-2.88 1.68-6.24 2.64-9.76 2.64 c-3.6 0-6.88-0.96-9.84-2.64 c-5.84-3.36-9.76-9.68-9.76-16.96 c0-7.28 3.92-13.6 9.76-16.96 C25.84 5.12 29.76 11.44 29.76 18.72z"/>
      </svg>
      <span class="sr-only">Memuat…</span>
    </div>
  `,
  styles: [`
    @keyframes infinity-loader-travel {
      0%   { stroke-dashoffset: 0; }
      100% { stroke-dashoffset: -100; }
    }
    .infinity-loader-wrap {
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .track {
      stroke: rgba(255,255,255,0.25);
    }
    .dash {
      animation: infinity-loader-travel 2s linear infinite;
    }
    .sr-only {
      position: absolute;
      width: 1px; height: 1px;
      padding: 0; margin: -1px;
      overflow: hidden; clip: rect(0,0,0,0);
      white-space: nowrap; border: 0;
    }
  `]
})
export class InfinityLoaderComponent {
  @Input() size = 40;
  @Input() color = '#ffffff';
}
