import { Injectable, signal } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class DropdownRegistryService {
  private activeId = signal<string | null>(null);

  open(id: string): void {
    this.activeId.set(id);
  }

  close(id: string): void {
    if (this.activeId() === id) {
      this.activeId.set(null);
    }
  }

  isActive(id: string): boolean {
    return this.activeId() === id;
  }

  getActiveId(): string | null {
    return this.activeId();
  }

  closeAll(): void {
    this.activeId.set(null);
  }
}
