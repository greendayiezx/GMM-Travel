import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface SeatAvailability {
  total_seats: number;
  booked_seats: string[];
  available_seats: number;
}

@Injectable({ providedIn: 'root' })
export class SeatService {
  private http = inject(HttpClient);

  getSeats(scheduleId: string): Observable<SeatAvailability> {
    return this.http.get<SeatAvailability>(
      `${environment.apiUrl}/travel-schedules/${scheduleId}/seats`
    );
  }
}
