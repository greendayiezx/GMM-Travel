import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Destination } from '../destinations-section/destinations-section.component';

@Component({
  selector: 'app-destination-card',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './destination-card.component.html',
  styleUrl: './destination-card.component.css'
})
export class DestinationCardComponent {
  @Input() dest!: Destination;

  /** Fired by the "Lihat Paket" button; bubbles up to AppComponent. */
  @Output() selectDestination = new EventEmitter<Destination>();

  /** Fallback if external image fails to load */
  onImageError(event: Event): void {
    const img = event.target as HTMLImageElement;
    img.style.display = 'none';
    // The gradient/emoji fallback will show automatically
  }
}
