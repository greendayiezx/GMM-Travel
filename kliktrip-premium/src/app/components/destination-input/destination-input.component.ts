import { Component, EventEmitter, Output, Input, HostListener, ElementRef, ViewChild, NgZone, OnDestroy, AfterViewInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { DropdownRegistryService } from '../../services/dropdown-registry.service';

interface Destination {
  name: string;
  country: string;
  emoji: string;
  logo?: string;
  icon?: string;
}

@Component({
  selector: 'app-destination-input',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './destination-input.component.html',
  styleUrl: './destination-input.component.css'
})
export class DestinationInputComponent implements AfterViewInit, OnDestroy {
  @Input() hasError = false;
  @Input() placeholder = 'Mau ke mana?';
  @Input() registryId = 'destination';
  @Output() destinationSelected = new EventEmitter<string>();
  @ViewChild('triggerElement') triggerElementRef!: ElementRef<HTMLElement>;
  @ViewChild('dropdownPortal') dropdownPortalRef!: ElementRef<HTMLElement>;

  private _value = '';

  @Input()
  set value(val: string) {
    this._value = val || '';
    this.query = this._value;
  }

  get value(): string {
    return this._value;
  }

  query = '';
  activeIndex = -1;

  dropdownTop = 0;
  dropdownLeft = 0;
  dropdownWidth = 0;

  private scrollHandler = () => this.updatePosition();
  private resizeHandler = () => this.updatePosition();
  private rafId = 0;

  allDestinations: Destination[] = [
    { name: 'Manado', country: 'Indonesia', emoji: '🐬', icon: 'wave' },
    { name: 'Kotamobagu', country: 'Indonesia', emoji: '⛰️', icon: 'mountain' },
    { name: 'Gorontalo', country: 'Indonesia', emoji: '🐋', icon: 'anchor' },
    { name: 'Makassar', country: 'Indonesia', emoji: '🚢', icon: 'boat' },
    { name: 'Kendari', country: 'Indonesia', emoji: '🌉', icon: 'bridge' },
  ];

  constructor(
    private registry: DropdownRegistryService,
    private elRef: ElementRef,
    private zone: NgZone
  ) {}

  get isOpen(): boolean {
    return this.registry.isActive(this.registryId);
  }

  get filtered(): Destination[] {
    if (!this.query.trim()) return this.allDestinations.slice(0, 5);
    const q = this.query.toLowerCase();
    return this.allDestinations.filter(d =>
      d.name.toLowerCase().includes(q) || d.country.toLowerCase().includes(q)
    ).slice(0, 6);
  }

  onInput() {
    this.open();
    this.activeIndex = -1;
  }

  onFocus() {
    this.open();
  }

  onArrowDown(e: Event) {
    e.preventDefault();
    if (this.activeIndex < this.filtered.length - 1) this.activeIndex++;
  }

  onArrowUp(e: Event) {
    e.preventDefault();
    if (this.activeIndex > 0) this.activeIndex--;
  }

  onEnter(e: Event) {
    if (this.activeIndex >= 0 && this.filtered[this.activeIndex]) {
      e.preventDefault();
      this.select(this.filtered[this.activeIndex]);
    }
  }

  select(dest: Destination) {
    this.query = `${dest.name}, ${dest.country}`;
    this.close();
    this.activeIndex = -1;
    this.destinationSelected.emit(this.query);
  }

  open() {
    this.registry.open(this.registryId);
    this.calcPosition();
    this.addListeners();
  }

  close() {
    this.registry.close(this.registryId);
    this.removeListeners();
  }

  ngAfterViewInit() {
    if (this.dropdownPortalRef) {
      document.body.appendChild(this.dropdownPortalRef.nativeElement);
    }
  }

  private calcPosition() {
    if (!this.triggerElementRef) return;
    const rect = this.triggerElementRef.nativeElement.getBoundingClientRect();
    const left = rect.left;
    const width = Math.max(rect.width, 320);

    // Prevent dropdown from overflowing past the right edge of the screen
    if (left + width > window.innerWidth) {
      this.dropdownLeft = Math.max(8, window.innerWidth - width - 16);
    } else {
      this.dropdownLeft = left;
    }
    this.dropdownWidth = width;

    const dropdownHeight = 310;
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
      const rect = this.triggerElementRef.nativeElement.getBoundingClientRect();
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
    this.registry.close(this.registryId);
    if (this.dropdownPortalRef && this.dropdownPortalRef.nativeElement.parentNode === document.body) {
      document.body.removeChild(this.dropdownPortalRef.nativeElement);
    }
  }
}


