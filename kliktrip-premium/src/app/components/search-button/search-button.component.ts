import { Component, EventEmitter, Output } from '@angular/core';
import { CommonModule } from '@angular/common';

interface Ripple {
  x: number;
  y: number;
  id: number;
}

@Component({
  selector: 'app-search-button',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './search-button.component.html',
  styleUrl: './search-button.component.css'
})
export class SearchButtonComponent {
  @Output() searched = new EventEmitter<void>();

  isLoading = false;
  ripples: Ripple[] = [];
  private rippleCounter = 0;

  onClick(event: MouseEvent) {
    const btn = event.currentTarget as HTMLElement;
    const rect = btn.getBoundingClientRect();
    const id = ++this.rippleCounter;
    this.ripples.push({
      x: event.clientX - rect.left,
      y: event.clientY - rect.top,
      id,
    });
    setTimeout(() => {
      this.ripples = this.ripples.filter(r => r.id !== id);
    }, 600);

    this.isLoading = true;
    setTimeout(() => {
      this.isLoading = false;
      this.searched.emit();
    }, 1200);
  }
}
