import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

export type UspIconType = 'shield' | 'headset' | 'lightning' | 'star';
export type UspVariant = 'primary' | 'accent';

@Component({
  selector: 'app-usp-card',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './usp-card.component.html',
  styleUrl: './usp-card.component.css'
})
export class UspCardComponent {
  @Input() icon: UspIconType = 'shield';
  @Input() title = '';
  @Input() description = '';
  @Input() variant: UspVariant = 'primary';
  @Input() bulletPoints: string[] = [];

  get accentColor(): string {
    return this.variant === 'accent' ? '#AAEE00' : '#1E9BF0';
  }

  get bulletCheckColor(): string {
    return this.variant === 'accent' ? '#5a9900' : '#1E9BF0';
  }

  get accentBg(): string {
    return this.variant === 'accent' ? 'rgba(170,238,0,0.10)' : 'rgba(30,155,240,0.08)';
  }

  get borderColor(): string {
    return this.variant === 'accent' ? 'rgba(170,238,0,0.35)' : 'rgba(30,155,240,0.20)';
  }
}
