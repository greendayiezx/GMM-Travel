import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UspCardComponent } from '../usp-card/usp-card.component';
import type { UspIconType, UspVariant } from '../usp-card/usp-card.component';

@Component({
  selector: 'app-usp-section',
  standalone: true,
  imports: [CommonModule, UspCardComponent],
  templateUrl: './usp-section.component.html',
  styleUrl: './usp-section.component.css'
})
export class UspSectionComponent {
  usps: { icon: UspIconType; title: string; description: string; variant: UspVariant; bulletPoints: string[] }[] = [
    {
      icon: 'shield',
      title: 'Jaminan Harga Terbaik',
      description: 'Kami menjamin harga paling kompetitif di pasaran.',
      variant: 'accent',
      bulletPoints: [
        'Price match guarantee — temukan lebih murah, kami ganti selisihnya',
        'Tidak ada biaya tersembunyi atau markup berlebihan',
        'Diskon eksklusif hingga 40% untuk member setia',
      ],
    },
    {
      icon: 'headset',
      title: 'Dukungan 24/7',
      description: 'Tim perjalanan kami hadir kapanpun Anda membutuhkan.',
      variant: 'primary',
      bulletPoints: [
        'Live chat & telepon 24 jam sehari, 7 hari seminggu',
        'Respons rata-rata di bawah 2 menit',
        'Bantuan darurat selama perjalanan di luar negeri',
      ],
    },
    {
      icon: 'lightning',
      title: 'Pemesanan Instan',
      description: 'Konfirmasi tiket dan hotel dalam hitungan detik.',
      variant: 'accent',
      bulletPoints: [
        'Konfirmasi real-time tanpa menunggu approval manual',
        'E-ticket langsung ke email & WhatsApp',
        'Reschedule & refund mudah dalam satu klik',
      ],
    },
    {
      icon: 'star',
      title: 'Kurasi Premium',
      description: 'Setiap paket disaring ketat oleh tim travel expert kami.',
      variant: 'primary',
      bulletPoints: [
        'Diseleksi dari 10.000+ penawaran setiap harinya',
        'Review terverifikasi dari pelanggan nyata',
        'Partner resmi maskapai & hotel bintang lima',
      ],
    },
  ];

  stats = [
    { value: '500+', label: 'Destinasi', sub: 'di seluruh dunia' },
    { value: '50K+', label: 'Pelanggan', sub: 'telah bepergian' },
    { value: '4.9/5', label: 'Rating', sub: 'rata-rata kepuasan' },
    { value: '10T+', label: 'Transaksi', sub: 'diselesaikan' },
  ];
}
