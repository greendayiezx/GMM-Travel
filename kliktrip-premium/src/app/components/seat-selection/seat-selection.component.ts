import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { BookingService } from '../../services/booking.service';
import { SeatService } from '../../services/seat.service';

interface Seat {
  number: string;
  status: 'available' | 'filled' | 'selected';
  row: number;
  col: number;
}

// Layout tetap minivan 14 kursi
const SEAT_LAYOUT: { num: string; row: number; col: number }[] = [
  { num: '14', row: 0, col: 1 },
  { num: '1',  row: 1, col: 2 },
  { num: '2',  row: 1, col: 3 },
  { num: '3',  row: 1, col: 4 },
  { num: '4',  row: 2, col: 1 },
  { num: '5',  row: 2, col: 3 },
  { num: '6',  row: 2, col: 4 },
  { num: '7',  row: 3, col: 1 },
  { num: '8',  row: 3, col: 3 },
  { num: '9',  row: 3, col: 4 },
  { num: '10', row: 4, col: 1 },
  { num: '11', row: 4, col: 2 },
  { num: '12', row: 4, col: 3 },
  { num: '13', row: 4, col: 4 },
];

@Component({
  selector: 'app-seat-selection',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './seat-selection.component.html',
  styleUrl: './seat-selection.component.css'
})
export class SeatSelectionComponent implements OnInit {

  seats: Seat[] = [];
  selectedSeat: string | null = null;
  isLoading = false;
  loadError = false;

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
    return !!this.selectedSeat && this.fullName.trim().length >= 3 && this.phone.trim().length >= 9;
  }

  constructor(
    public bookingService: BookingService,
    private seatService: SeatService,
    private router: Router
  ) {}

  ngOnInit(): void {
    // Prefill data penumpang jika sudah pernah diisi
    if (this.bookingService.passenger) {
      this.fullName = this.bookingService.passenger.fullName;
      this.phone    = this.bookingService.passenger.phone;
    }

    const scheduleId = this.bookingService.schedule?.id;
    if (scheduleId) {
      this.loadSeats(scheduleId);
    } else {
      // Fallback jika schedule belum ada di service (misalnya direct URL)
      this.buildSeats(new Set());
    }
  }

  private loadSeats(scheduleId: string): void {
    this.isLoading = true;
    this.loadError = false;

    this.seatService.getSeats(scheduleId).subscribe({
      next: (data) => {
        this.isLoading = false;
        this.buildSeats(new Set(data.booked_seats));

        // Pulihkan kursi yang sudah dipilih sebelumnya (misal balik dari payment)
        const prev = this.bookingService.selectedSeat;
        if (prev) {
          const match = this.seats.find(s => s.number === prev);
          if (match && match.status === 'available') {
            match.status     = 'selected';
            this.selectedSeat = prev;
          }
        }
      },
      error: () => {
        this.isLoading = false;
        this.loadError = true;
        // Fallback ke tampilan kosong agar user tahu ada masalah
        this.buildSeats(new Set());
      }
    });
  }

  private buildSeats(bookedSet: Set<string>): void {
    this.seats = SEAT_LAYOUT.map(s => ({
      number: s.num,
      status: bookedSet.has(s.num) ? 'filled' : 'available',
      row:    s.row,
      col:    s.col,
    }));
  }

  retryLoad(): void {
    const scheduleId = this.bookingService.schedule?.id;
    if (scheduleId) this.loadSeats(scheduleId);
  }

  get row0(): Seat[] { return this.seats.filter(s => s.row === 0).sort((a, b) => a.col - b.col); }
  get row1(): Seat[] { return this.seats.filter(s => s.row === 1).sort((a, b) => a.col - b.col); }
  get row2(): Seat[] { return this.seats.filter(s => s.row === 2).sort((a, b) => a.col - b.col); }
  get row3(): Seat[] { return this.seats.filter(s => s.row === 3).sort((a, b) => a.col - b.col); }
  get row4(): Seat[] { return this.seats.filter(s => s.row === 4).sort((a, b) => a.col - b.col); }

  getSeat(num: string): Seat {
    return this.seats.find(s => s.number === num)!;
  }

  selectSeat(seat: Seat): void {
    if (seat.status === 'filled') return;
    if (this.selectedSeat === seat.number) {
      seat.status      = 'available';
      this.selectedSeat = null;
    } else {
      if (this.selectedSeat) {
        const prev = this.seats.find(s => s.number === this.selectedSeat);
        if (prev) prev.status = 'available';
      }
      seat.status      = 'selected';
      this.selectedSeat = seat.number;
    }
  }

  goBack(): void {
    this.router.navigate(['/booking/flights']);
  }

  confirm(): void {
    if (!this.isValid) return;
    this.bookingService.setSeat(this.selectedSeat!);
    this.bookingService.setPassenger({ fullName: this.fullName.trim(), phone: this.phone.trim() });
    this.router.navigate(['/booking/payment']);
  }
}
