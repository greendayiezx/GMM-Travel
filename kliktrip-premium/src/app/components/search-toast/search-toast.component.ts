import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-search-toast',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './search-toast.component.html',
  styleUrl: './search-toast.component.css'
})
export class SearchToastComponent {
  @Input() type: 'success' | 'error' = 'success';
  @Input() messages: string[] = [];
  @Input() visible = false;
}
