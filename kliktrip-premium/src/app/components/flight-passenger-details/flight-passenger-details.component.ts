import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { FlightBookingService } from '../../services/flight-booking.service';
import { FlightPassenger } from '../../models/flight.model';

@Component({
  selector: 'app-flight-passenger-details',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './flight-passenger-details.component.html',
  styleUrl: './flight-passenger-details.component.css',
})
export class FlightPassengerDetailsComponent implements OnInit {
  public flightService = inject(FlightBookingService);
  private router       = inject(Router);

  passengers: FlightPassenger[] = [];
  submitted = false;

  ngOnInit(): void {
    const flight = this.flightService.selectedFlight;
    if (!flight) { this.router.navigate(['/flights/search']); return; }

    // Restore previously filled data if navigating back
    if (this.flightService.passengers.length > 0) {
      this.passengers = this.flightService.passengers.map(p => ({ ...p }));
    } else {
      this.passengers = [this.blankPassenger('Adult')];
    }
  }

  private blankPassenger(type: 'Adult' | 'Child' | 'Infant'): FlightPassenger {
    return {
      title: 'Mr',
      full_name: '',
      date_of_birth: '',
      id_type: 'KTP',
      id_number: '',
      phone: '',
      email: '',
      passenger_type: type,
    };
  }

  addPassenger(type: 'Adult' | 'Child' | 'Infant'): void {
    this.passengers.push(this.blankPassenger(type));
  }

  removePassenger(index: number): void {
    if (this.passengers.length > 1) {
      this.passengers.splice(index, 1);
    }
  }

  passengerLabel(index: number): string {
    const p = this.passengers[index];
    const typeLabel = { Adult: 'Dewasa', Child: 'Anak', Infant: 'Bayi' }[p.passenger_type] ?? p.passenger_type;
    return `Penumpang ${index + 1} — ${typeLabel}`;
  }

  sanitizePhone(event: Event, index: number): void {
    const input = event.target as HTMLInputElement;
    input.value = input.value.replace(/[^0-9+\-\s]/g, '');
    this.passengers[index].phone = input.value;
  }

  sanitizeName(event: Event, index: number): void {
    const input = event.target as HTMLInputElement;
    input.value = input.value.replace(/[^a-zA-Z\s]/g, '');
    this.passengers[index].full_name = input.value;
  }

  isEmailValid(email: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }

  isPassengerValid(p: FlightPassenger): boolean {
    return !!p.title &&
           p.full_name.trim().length >= 3 &&
           !!p.date_of_birth &&
           !!p.id_type &&
           p.id_number.trim().length >= 5 &&
           p.phone.trim().length >= 9 &&
           /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(p.email);
  }

  get allValid(): boolean {
    return this.passengers.length > 0 && this.passengers.every(p => this.isPassengerValid(p));
  }

  confirm(): void {
    this.submitted = true;
    if (!this.allValid) return;
    this.flightService.setPassengers(this.passengers.map(p => ({ ...p, full_name: p.full_name.trim() })));
    this.router.navigate(['/flights/payment']);
  }

  goBack(): void {
    this.router.navigate(['/flights/results']);
  }
}
