import {
  Component, EventEmitter, Output, ElementRef, ViewChild, OnDestroy, NgZone, HostListener, AfterViewInit, inject
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { DropdownRegistryService } from '../../services/dropdown-registry.service';
import { SearchFormService } from '../../services/search-form.service';

interface CalendarDay {
  date: Date;
  dayOfMonth: number;
  timestamp: number;
  isCurrentMonth: boolean;
  isToday: boolean;
  isPast: boolean;
  isStart: boolean;
  isEnd: boolean;
  isInRange: boolean;
  isHovered: boolean;
}

@Component({
  selector: 'app-date-range-picker',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './date-range-picker.component.html',
  styleUrl: './date-range-picker.component.css'
})
export class DateRangePickerComponent implements AfterViewInit, OnDestroy {
  @Output() rangeSelected = new EventEmitter<{ start: Date | null; end: Date | null }>();
  @ViewChild('triggerRow') triggerRowRef!: ElementRef<HTMLElement>;
  @ViewChild('dropdownPortal') dropdownPortalRef!: ElementRef<HTMLElement>;

  form = inject(SearchFormService);

  activeField: 'start' | 'end' = 'start';
  hoverDate: Date | null = null;

  get startDate(): Date | null {
    return this.form.state().startDate;
  }
  set startDate(val: Date | null) {
    this.form.patch({ startDate: val });
  }

  get endDate(): Date | null {
    return this.form.state().endDate;
  }
  set endDate(val: Date | null) {
    this.form.patch({ endDate: val });
  }

  calendarTop = 0;
  calendarLeft = 0;
  calendarWidth = 340;

  private scrollHandler = () => this.updatePosition();
  private resizeHandler = () => this.updatePosition();
  private rafId = 0;

  viewMonth: Date = new Date();
  weekdays = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
  months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

  // Cache array kalender — hanya di-rebuild saat state berubah,
  // BUKAN setiap change detection cycle
  calendarDays: CalendarDay[] = [];

  // hostEl = elemen <app-date-range-picker> itu sendiri
  constructor(
    private registry: DropdownRegistryService,
    private zone: NgZone,
    private hostEl: ElementRef
  ) {}

  get isOpen(): boolean {
    return this.registry.isActive('datepicker');
  }

  /**
   * Gunakan document:click (bukan mousedown) agar tidak bentrok
   * dengan timing click event pada tombol tanggal.
   * mousedown terjadi SEBELUM click — jika mousedown memicu
   * change detection → *ngFor rebuild DOM → click target sudah hilang.
   */
  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    if (!this.isOpen) return;
    const target = event.target as HTMLElement;
    const clickedInsideTrigger = this.hostEl.nativeElement.contains(target);
    const clickedInsidePortal = this.dropdownPortalRef?.nativeElement.contains(target);

    if (!clickedInsideTrigger && !clickedInsidePortal) {
      this.zone.run(() => this.close());
    }
  }

  /** trackBy untuk *ngFor agar Angular reuse DOM nodes alih-alih destroy+create */
  trackByDay(_index: number, day: CalendarDay): number {
    return day.timestamp;
  }

  get viewLabel(): string {
    return `${this.months[this.viewMonth.getMonth()]} ${this.viewMonth.getFullYear()}`;
  }

  get startLabel(): string {
    return this.startDate ? this.formatDate(this.startDate) : 'Pilih tanggal';
  }

  get endLabel(): string {
    return this.endDate ? this.formatDate(this.endDate) : 'Pilih tanggal';
  }

  formatDate(d: Date): string {
    return `${d.getDate()} ${this.months[d.getMonth()].slice(0, 3)} ${d.getFullYear()}`;
  }

  /** Rebuild cached calendarDays — dipanggil hanya saat state berubah */
  private rebuildCalendar(): void {
    const today = new Date(); today.setHours(0, 0, 0, 0);
    const year = this.viewMonth.getFullYear();
    const month = this.viewMonth.getMonth();
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const days: CalendarDay[] = [];

    for (let i = 0; i < firstDay.getDay(); i++) {
      days.push(this.buildDay(new Date(year, month, -firstDay.getDay() + i + 1), false, today));
    }
    for (let i = 1; i <= lastDay.getDate(); i++) {
      days.push(this.buildDay(new Date(year, month, i), true, today));
    }
    const remaining = 42 - days.length;
    for (let i = 1; i <= remaining; i++) {
      days.push(this.buildDay(new Date(year, month + 1, i), false, today));
    }
    this.calendarDays = days;
  }

  private buildDay(d: Date, isCurrentMonth: boolean, today: Date): CalendarDay {
    d.setHours(0, 0, 0, 0);
    const ts = d.getTime();
    const effectiveEnd = this.endDate ?? this.hoverDate;
    return {
      date: d,
      dayOfMonth: d.getDate(),
      timestamp: ts,
      isCurrentMonth,
      isToday: ts === today.getTime(),
      isPast: d < today,
      isStart: !!this.startDate && ts === this.startDate.getTime(),
      isEnd: !!this.endDate && ts === this.endDate.getTime(),
      isInRange: !!(this.startDate && effectiveEnd && d > this.startDate && d < effectiveEnd),
      isHovered: !!this.hoverDate && ts === this.hoverDate.getTime(),
    };
  }

  openPicker(field: 'start' | 'end') {
    this.activeField = field;
    this.rebuildCalendar();
    this.calcPosition();
    if (!this.isOpen) {
      this.registry.open('datepicker');
      this.zone.runOutsideAngular(() => {
        window.addEventListener('scroll', this.scrollHandler, { capture: true, passive: true });
        window.addEventListener('resize', this.resizeHandler, { passive: true });
      });
    }
  }

  private readonly CAL_HEIGHT = 390;

  ngAfterViewInit() {
    if (this.dropdownPortalRef) {
      document.body.appendChild(this.dropdownPortalRef.nativeElement);
    }
  }

  private calcPosition() {
    if (!this.triggerRowRef) return;
    const rect = this.triggerRowRef.nativeElement.getBoundingClientRect();
    const left = rect.left;
    const width = Math.min(Math.max(rect.width, 280), 380);

    // Prevent dropdown from overflowing past the right edge of the screen
    if (left + width > window.innerWidth) {
      this.calendarLeft = Math.max(8, window.innerWidth - width - 16);
    } else {
      this.calendarLeft = left;
    }
    this.calendarWidth = width;

    const spaceBelow = window.innerHeight - rect.bottom;
    if (spaceBelow >= this.CAL_HEIGHT) {
      this.calendarTop = rect.bottom + 8;
    } else {
      this.calendarTop = Math.max(8, rect.top - this.CAL_HEIGHT - 8);
    }
  }

  private updatePosition() {
    cancelAnimationFrame(this.rafId);
    this.rafId = requestAnimationFrame(() => {
      if (!this.isOpen) {
        this.removeListeners();
        return;
      }
      const rect = this.triggerRowRef.nativeElement.getBoundingClientRect();
      if (rect.bottom < 0 || rect.top > window.innerHeight) {
        this.zone.run(() => this.close());
      } else {
        this.zone.run(() => this.calcPosition());
      }
    });
  }

  close() {
    this.registry.close('datepicker');
    this.hoverDate = null;
    this.removeListeners();
  }

  private removeListeners() {
    window.removeEventListener('scroll', this.scrollHandler, { capture: true } as any);
    window.removeEventListener('resize', this.resizeHandler);
    cancelAnimationFrame(this.rafId);
  }

  prevMonth() {
    this.viewMonth = new Date(this.viewMonth.getFullYear(), this.viewMonth.getMonth() - 1, 1);
    this.rebuildCalendar();
  }

  nextMonth() {
    this.viewMonth = new Date(this.viewMonth.getFullYear(), this.viewMonth.getMonth() + 1, 1);
    this.rebuildCalendar();
  }

  onDayClick(day: CalendarDay) {
    if (day.isPast) return;

    const isRoundTrip = this.form.state().isRoundTrip;
    if (!isRoundTrip) {
      this.startDate = day.date;
      this.endDate = null;
      this.close();
      this.rangeSelected.emit({ start: this.startDate, end: null });
      return;
    }

    if (this.activeField === 'start' || !this.startDate || day.date <= this.startDate) {
      this.startDate = day.date;
      this.endDate = null;
      this.activeField = 'end';
      this.rebuildCalendar();
    } else {
      this.endDate = day.date;
      this.close();
      this.rangeSelected.emit({ start: this.startDate, end: this.endDate });
    }
  }

  toggleRoundTrip(event: Event) {
    const checked = (event.target as HTMLInputElement).checked;
    this.form.patch({ isRoundTrip: checked });
    if (!checked) {
      this.endDate = null;
      this.rangeSelected.emit({ start: this.startDate, end: null });
    }
  }

  onDayHover(day: CalendarDay) {
    if (!day.isPast && this.startDate && !this.endDate) {
      this.hoverDate = day.date;
      this.rebuildCalendar();
    }
  }

  onMouseLeave() {
    if (this.hoverDate) {
      this.hoverDate = null;
      this.rebuildCalendar();
    }
  }

  ngOnDestroy() {
    this.removeListeners();
    this.registry.close('datepicker');
    if (this.dropdownPortalRef && this.dropdownPortalRef.nativeElement.parentNode === document.body) {
      document.body.removeChild(this.dropdownPortalRef.nativeElement);
    }
  }
}

