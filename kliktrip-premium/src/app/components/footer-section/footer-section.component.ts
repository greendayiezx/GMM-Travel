import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-footer-section',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './footer-section.component.html',
  styleUrl: './footer-section.component.css'
})
export class FooterSectionComponent {
  logo = {
    src: 'assets/gmm-tour-logo.png',
    alt: 'GMM Global Explore Logo',
  };

  description = 'Kami hadir untuk memberikan pengalaman perjalanan terbaik untuk Anda dan keluarga. Aman, nyaman, dan terpercaya.';

  trustBadges = [
    { icon: 'shield', label: 'Aman & Terpercaya' },
    { icon: 'headset', label: 'Layanan 24/7' },
    { icon: 'tag', label: 'Harga Terbaik' },
  ];

  quickLinks = [
    { name: 'Beranda', href: '#' },
    { name: 'Travel Reguler', href: '#' },
    { name: 'Paket Tour', href: '#' },
    { name: 'Promo', href: '#' },
    { name: 'Tentang Kami', href: '#' },
    { name: 'Kontak Kami', href: '#' },
    { name: 'FAQ', href: '#' },
  ];

  layananLinks = [
    { name: 'Sewa Hiace', href: '#' },
    { name: 'Antar Jemput', href: '#' },
    { name: 'Private Trip', href: '#' },
    { name: 'Group Trip', href: '#' },
    { name: 'City Tour', href: '#' },
    { name: 'Event & Gathering', href: '#' },
  ];

  infoLinks = [
    { name: 'Syarat & Ketentuan', href: '#' },
    { name: 'Kebijakan Privasi', href: '#' },
    { name: 'Cara Pemesanan', href: '#' },
    { name: 'Pembayaran', href: '#' },
    { name: 'Pembatalan & Refund', href: '#' },
  ];

  newsletterEmail = '';

  contactItems = [
    { icon: 'location', title: 'Alamat', line1: 'Jl. Sam Ratulangi No. 123', line2: 'Makassar, Sulawesi Selatan', link: null },
    { icon: 'whatsapp', title: 'WhatsApp', line1: '+62 812-3456-7890', line2: 'Chat dengan kami', link: 'https://wa.me/6281234567890' },
    { icon: 'email', title: 'Email', line1: 'yantisyamn@gmail.com', line2: 'Kirim email', link: 'mailto:yantisyamn@gmail.com' },
    { icon: 'clock', title: 'Jam Operasional', line1: 'Setiap Hari', line2: '07.00 - 22.00 WITA', link: null },
  ];

  paymentMethods = ['Mandiri', 'BCA', 'BNI', 'BRI', 'OVO', 'DANA'];

  copyright = '© 2026 GMM Global Explore. All rights reserved.';
}
