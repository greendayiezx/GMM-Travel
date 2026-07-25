import { Component, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { BookingService } from '../../services/booking.service';

@Component({
  selector: 'app-passenger-details',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './passenger-details.component.html',
  styleUrl: './passenger-details.component.css'
})
export class PassengerDetailsComponent {
  @Output() next = new EventEmitter<void>();
  @Output() back = new EventEmitter<void>();

  fullName = '';
  phone = '';

  sanitizeFullName(event: Event): void {
    const input = event.target as HTMLInputElement;
    input.value = input.value.replace(/[0-9]/g, '');
    this.fullName = input.value;
  }

  sanitizePhone(event: Event): void {
    const input = event.target as HTMLInputElement;
    input.value = input.value.replace(/[^0-9]/g, '');
    this.phone = input.value;
  }

  get isValid(): boolean {
    return this.fullName.trim().length >= 3 && this.phone.trim().length >= 9;
  }

  constructor(public bookingService: BookingService) {}

  confirm(): void {
    if (!this.isValid) return;
    this.bookingService.setPassenger({ fullName: this.fullName.trim(), phone: this.phone.trim() });
    this.next.emit();
  }
}
