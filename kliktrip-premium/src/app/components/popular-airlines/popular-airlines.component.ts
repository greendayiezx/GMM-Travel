import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

interface Airline {
  name: string;
  code: string;
  logo: string;
  rating: string;
  description: string;
}

@Component({
  selector: 'app-popular-airlines',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './popular-airlines.component.html',
  styleUrl: './popular-airlines.component.css',
})
export class PopularAirlinesComponent {
  airlines: Airline[] = [
    {
      name: 'Garuda Indonesia',
      code: 'GA',
      logo: 'https://upload.wikimedia.org/wikipedia/id/thumb/2/2c/Garuda_Indonesia_logo.svg/1200px-Garuda_Indonesia_logo.svg.png',
      rating: '4.7',
      description: 'Maskapai nasional Indonesia dengan layanan premium kelas dunia',
    },
    {
      name: 'Lion Air',
      code: 'JT',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1d/Lion_Air_logo.svg/1200px-Lion_Air_logo.svg.png',
      rating: '4.2',
      description: 'Maskapai berbiaya rendah dengan jaringan penerbangan terluas di Indonesia',
    },
    {
      name: 'Batik Air',
      code: 'ID',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Batik_Air_logo.svg/1200px-Batik_Air_logo.svg.png',
      rating: '4.4',
      description: 'Maskapai layanan penuh dengan sentuhan budaya Indonesia',
    },
    {
      name: 'Citilink',
      code: 'QG',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/76/Citilink_logo.svg/1200px-Citilink_logo.svg.png',
      rating: '4.1',
      description: 'Maskapai hemat dengan komitmen tepat waktu dan aman',
    },
    {
      name: 'Singapore Airlines',
      code: 'SQ',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/Singapore_Airlines_Logo.svg/1200px-Singapore_Airlines_Logo.svg.png',
      rating: '4.9',
      description: 'Maskapai terbaik dunia dengan layanan mewah dan inovatif',
    },
    {
      name: 'AirAsia',
      code: 'AK',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/AirAsia_New_Logo.svg/1200px-AirAsia_New_Logo.svg.png',
      rating: '4.3',
      description: 'Maskapai berbiaya rendah terbaik Asia dengan jangkauan luas',
    },
    {
      name: 'Emirates',
      code: 'EK',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Emirates_logo.svg/1200px-Emirates_logo.svg.png',
      rating: '4.8',
      description: 'Maskapai internasional dengan pengalaman penerbangan mewah',
    },
    {
      name: 'Qatar Airways',
      code: 'QR',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/Qatar_Airways_Logo.svg/1200px-Qatar_Airways_Logo.svg.png',
      rating: '4.8',
      description: 'Maskapai terbaik dunia dengan layanan bintang lima',
    },
  ];

  onLogoError(event: Event, airline: Airline) {
    const img = event.target as HTMLImageElement;
    // Fallback: use placeholder with airline initial
    img.style.display = 'none';
    const parent = img.parentElement;
    if (parent) {
      const fallback = document.createElement('span');
      fallback.className = 'pa-logo-fallback';
      fallback.textContent = airline.name.charAt(0);
      parent.appendChild(fallback);
    }
  }
}