import { Component, inject, Output, EventEmitter, ViewChild, ElementRef } from '@angular/core'; // gmm-global
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { DestinationInputComponent } from '../destination-input/destination-input.component';
import { DateRangePickerComponent } from '../date-range-picker/date-range-picker.component';
import { PassengerSelectorComponent } from '../passenger-selector/passenger-selector.component';
import { SearchButtonComponent } from '../search-button/search-button.component';
import { SearchToastComponent } from '../search-toast/search-toast.component';
import { SearchFormService } from '../../services/search-form.service';
import { FlightSearchComponent } from '../flight-search/flight-search.component';

@Component({
  selector: 'app-hero-section',
  standalone: true,
  imports: [CommonModule, FormsModule, DestinationInputComponent, DateRangePickerComponent, PassengerSelectorComponent, SearchButtonComponent, SearchToastComponent, FlightSearchComponent],
  templateUrl: './hero-section.component.html',
  styleUrl: './hero-section.component.css'
})
export class HeroSectionComponent {
  @Output() searchConfirmed = new EventEmitter<void>();
  @ViewChild('tabBarRef') tabBarRef!: ElementRef<HTMLElement>;

  form = inject(SearchFormService);

  activeTab: 'shuttle' | 'flight' = 'flight';

  scrollTabs(direction: 'left' | 'right') {
    if (!this.tabBarRef) return;
    const container = this.tabBarRef.nativeElement;
    const scrollAmount = direction === 'left' ? -160 : 160;
    container.scrollBy({ left: scrollAmount, behavior: 'smooth' });
  }

  toastVisible = false;
  toastType: 'success' | 'error' = 'success';
  toastMessages: string[] = [];

  stats = [
    { value: '500+', label: 'Destinasi Wisata', color: '#EAB308' },
    { value: '50K+', label: 'Pelanggan Puas', color: '#1E9BF0' },
    { value: '4.9★', label: 'Rating Layanan', color: '#EAB308' },
  ];

  scrollToDestinations(event?: Event) {
    event?.preventDefault();
    const el = document.getElementById('destinations-section');
    if (el) {
      el.scrollIntoView({ behavior: 'smooth' });
    }
  }

  navigateToUmrohIbadah(event?: Event) {
    event?.preventDefault();
    const el = document.getElementById('destinations-section');
    if (el) {
      el.scrollIntoView({ behavior: 'smooth' });
    }
    setTimeout(() => {
      window.dispatchEvent(new CustomEvent('selectCategoryFilter', { detail: 'Ibadah' }));
    }, 100);
  }

  onDepartureSelected(value: string) {
    this.form.patch({ departure: value });
  }

  onDestinationSelected(value: string) {
    this.form.patch({ destination: value });
  }

  onRangeSelected(range: { start: Date | null; end: Date | null }) {
    this.form.patch({ startDate: range.start, endDate: range.end });
  }

  onPassengersChanged(total: number) {
    this.form.patch({ adults: total });
  }

  onSearch() {
    this.form.markSubmitted();
    const v = this.form.validation();
    if (!v.valid) {
      this.showToast('error', v.errors);
      return;
    }
    // Trigger the 3D flying animation in the parent
    this.searchConfirmed.emit();
  }

  private showToast(type: 'success' | 'error', messages: string[]) {
    this.toastType = type;
    this.toastMessages = messages;
    this.toastVisible = true;
    setTimeout(() => { this.toastVisible = false; }, 3500);
  }
}
