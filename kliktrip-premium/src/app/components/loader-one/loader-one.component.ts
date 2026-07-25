import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

/**
 * Three bouncing dots.
 *
 * Angular port of the framer-motion <LoaderOne />. The original's
 * x:[0,10,0] / opacity:[0.5,1,0.5] / scale:[1,1.2,1] over 1s with a
 * 0.2s-per-dot stagger maps exactly onto CSS keyframes, so this needs
 * no animation library.
 */
@Component({
  selector: 'app-loader-one',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="flex items-center justify-center gap-1">
      @for (dot of [0, 1, 2]; track dot) {
        <div class="loader-dot h-3 w-3 rounded-full bg-blue-500"
             [style.animation-delay]="dot * 0.2 + 's'"></div>
      }
    </div>
  `,
  styles: [`
    @keyframes loaderOneBounce {
      0%, 100% { transform: translateX(0)    scale(1);   opacity: 0.5; }
      50%      { transform: translateX(10px) scale(1.2); opacity: 1;   }
    }

    .loader-dot {
      animation: loaderOneBounce 1s ease-in-out infinite;
    }
  `]
})
export class LoaderOneComponent {}
