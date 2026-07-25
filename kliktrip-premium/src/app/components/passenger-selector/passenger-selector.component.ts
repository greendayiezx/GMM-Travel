import { Component, OnInit, EventEmitter, Output, HostListener, ElementRef, ViewChild, NgZone, OnDestroy, AfterViewInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DropdownRegistryService } from '../../services/dropdown-registry.service';
import { SearchFormService } from '../../services/search-form.service';

interface PassengerType {
  key: 'adults' | 'children';
  label: string;
  sublabel: string;
  count: number;
  min: number;
  max: number;
}

@Component({
  selector: 'app-passenger-selector',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './passenger-selector.component.html',
  styleUrl: './passenger-selector.component.css'
})
export class PassengerSelectorComponent implements OnInit, AfterViewInit, OnDestroy {
  @Output() passengersChanged = new EventEmitter<number>();
  @ViewChild('triggerButton') triggerButtonRef!: ElementRef<HTMLElement>;
  @ViewChild('dropdownPortal') dropdownPortalRef!: ElementRef<HTMLElement>;

  dropdownTop = 0;
  dropdownLeft = 0;
  dropdownWidth = 0;

  private scrollHandler = () => this.updatePosition();
  private resizeHandler = () => this.updatePosition();
  private rafId = 0;

  types: PassengerType[] = [
    { key: 'adults', label: 'Dewasa', sublabel: '18 tahun ke atas', count: 2, min: 1, max: 10 },
    { key: 'children', label: 'Anak-anak', sublabel: '2–17 tahun', count: 0, min: 0, max: 8 },
  ];

  form = inject(SearchFormService);

  constructor(
    private registry: DropdownRegistryService,
    private elRef: ElementRef,
    private zone: NgZone
  ) {}

  ngOnInit() {
    const s = this.form.state();
    const adultType = this.types.find(t => t.key === 'adults');
    if (adultType) adultType.count = s.adults ?? 2;

    const childType = this.types.find(t => t.key === 'children');
    if (childType) childType.count = s.children ?? 0;
  }

  get isOpen(): boolean {
    return this.registry.isActive('passenger');
  }

  get total(): number {
    return this.types.reduce((s, t) => s + t.count, 0);
  }

  get label(): string {
    const adults = this.types.find(t => t.key === 'adults')!;
    const children = this.types.find(t => t.key === 'children')!;
    if (children.count === 0) return `${adults.count} Dewasa`;
    return `${adults.count} Dewasa, ${children.count} Anak`;
  }

  increase(type: PassengerType) {
    if (type.count < type.max) {
      type.count++;
      this.updateServiceState();
      this.emit();
    }
  }

  decrease(type: PassengerType) {
    if (type.count > type.min) {
      type.count--;
      this.updateServiceState();
      this.emit();
    }
  }

  private updateServiceState() {
    const adults = this.types.find(t => t.key === 'adults')?.count ?? 2;
    const children = this.types.find(t => t.key === 'children')?.count ?? 0;
    this.form.patch({ adults, children });
  }

  private emit() {
    this.passengersChanged.emit(this.total);
  }

  toggle() {
    if (this.isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    this.registry.open('passenger');
    this.calcPosition();
    this.addListeners();
  }

  close() {
    this.registry.close('passenger');
    this.removeListeners();
  }

  ngAfterViewInit() {
    if (this.dropdownPortalRef) {
      document.body.appendChild(this.dropdownPortalRef.nativeElement);
    }
  }

  private calcPosition() {
    if (!this.triggerButtonRef) return;
    const rect = this.triggerButtonRef.nativeElement.getBoundingClientRect();
    const left = rect.left;
    const width = Math.max(rect.width, 320);

    // Prevent dropdown from overflowing past the right edge of the screen
    if (left + width > window.innerWidth) {
      this.dropdownLeft = Math.max(8, window.innerWidth - width - 16);
    } else {
      this.dropdownLeft = left;
    }
    this.dropdownWidth = width;

    const dropdownHeight = 220;
    const spaceBelow = window.innerHeight - rect.bottom;
    if (spaceBelow >= dropdownHeight) {
      this.dropdownTop = rect.bottom + 8;
    } else {
      this.dropdownTop = Math.max(8, rect.top - dropdownHeight - 8);
    }
  }

  private updatePosition() {
    cancelAnimationFrame(this.rafId);
    this.rafId = requestAnimationFrame(() => {
      if (!this.isOpen) {
        this.removeListeners();
        return;
      }
      const rect = this.triggerButtonRef.nativeElement.getBoundingClientRect();
      if (rect.bottom < 0 || rect.top > window.innerHeight) {
        this.zone.run(() => this.close());
      } else {
        this.zone.run(() => this.calcPosition());
      }
    });
  }

  private addListeners() {
    this.zone.runOutsideAngular(() => {
      window.addEventListener('scroll', this.scrollHandler, { capture: true, passive: true });
      window.addEventListener('resize', this.resizeHandler, { passive: true });
    });
  }

  private removeListeners() {
    window.removeEventListener('scroll', this.scrollHandler, { capture: true } as any);
    window.removeEventListener('resize', this.resizeHandler);
    cancelAnimationFrame(this.rafId);
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(e: Event) {
    if (!this.isOpen) return;
    const target = e.target as HTMLElement;
    const clickedInsideTrigger = this.elRef.nativeElement.contains(target);
    const clickedInsidePortal = this.dropdownPortalRef?.nativeElement.contains(target);

    if (!clickedInsideTrigger && !clickedInsidePortal) {
      this.zone.run(() => this.close());
    }
  }

  ngOnDestroy() {
    this.removeListeners();
    this.registry.close('passenger');
    if (this.dropdownPortalRef && this.dropdownPortalRef.nativeElement.parentNode === document.body) {
      document.body.removeChild(this.dropdownPortalRef.nativeElement);
    }
  }
}


