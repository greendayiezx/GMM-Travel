import {
  Component, ElementRef, ViewChild,
  AfterViewInit, OnDestroy, HostListener, NgZone, ChangeDetectorRef
} from '@angular/core';
import { NavigationCancel, NavigationEnd, NavigationError, NavigationStart, Event as RouterEvent } from '@angular/router';
import { CommonModule } from '@angular/common';
import { RouterOutlet, RouterLink, Router } from '@angular/router';
import { HeroSectionComponent } from './components/hero-section/hero-section.component';
import { DestinationsSectionComponent, Destination } from './components/destinations-section/destinations-section.component';
import { UspSectionComponent } from './components/usp-section/usp-section.component';
import { FooterSectionComponent } from './components/footer-section/footer-section.component';
import { LoaderOneComponent } from './components/loader-one/loader-one.component';
import { InfinityLoaderComponent } from './components/infinity-loader/infinity-loader.component';
import { FlightCardComponent } from './components/flight-card/flight-card.component';
import { AuthModalComponent } from './components/auth-modal/auth-modal.component';
import { SearchFormService } from './services/search-form.service';
import { BookingService, BookingSchedule } from './services/booking.service';
import { TravelService } from './services/travel.service';
import { ClerkService } from './services/clerk.service';
import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(ScrollTrigger);

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, RouterOutlet, RouterLink, HeroSectionComponent, DestinationsSectionComponent, UspSectionComponent, FooterSectionComponent, LoaderOneComponent, FlightCardComponent, InfinityLoaderComponent, AuthModalComponent],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent implements AfterViewInit, OnDestroy {
  @ViewChild('webglCanvas') canvasRef!: ElementRef<HTMLCanvasElement>;
  @ViewChild('fadeTransisi') fadeTransisi!: ElementRef<HTMLElement>;

  // ── Three.js objects ─────────────────────────────────────────
  private renderer!: THREE.WebGLRenderer;
  private scene!: THREE.Scene;
  private camera!: THREE.PerspectiveCamera;
  private carGroup!: THREE.Group;
  private hiaceModel: THREE.Group | null = null;
  private cloudModels: THREE.Group[] = [];
  private fallbackMesh!: THREE.Mesh;
  private wheels: THREE.Object3D[] = [];

  // ── Animation state ──────────────────────────────────────────
  private animFrameId = 0;
  private clock = new THREE.Clock();
  private isScrolling = false;   // true while ScrollTrigger is driving the car
  private isFlying   = false;    // true after search button takeoff completes
  showTicketResults = false;     // true when ticket options container is shown
  isReturning = false;           // true while the back-to-home transition runs
  hasActiveRoute = false;        // true when router outlet has an active component
  hideMainNav = false;           // true on package-checkout / package-payment routes
  isNavigating = false;          // true while route transition is in progress
  isMobileMenuOpen = false;      // true when mobile hamburger menu is open
  showUserMenu = false;
  authMode: 'signin' | 'signup' | null = null;

  toggleMobileMenu(): void {
    this.isMobileMenuOpen = !this.isMobileMenuOpen;
  }

  // ── Animated Search Placeholder ──
  searchPlaceholder = 'Cari ';
  private placeholderKeywords = [
    'Flight to Surabaya',
    'Wisata di Bunaken',
    'Hotel Murah Bali',
    'Tiket ke Tokyo',
    'Paket Tour Lombok',
    'Umroh Hemat 2026',
    'Sewa Hiace Makassar'
  ];
  private placeholderIndex = 0;
  private placeholderCharIndex = 0;
  private isDeletingPlaceholder = false;
  placeholderTimeoutId: any;
  availableTickets = [
    { airline: 'GMM Travel', flightNumber: 'GMM-400', departureTime: '05:30', price: 0, type: 'EXECUTIVE' },
    { airline: 'GMM Travel', flightNumber: 'GMM-110', departureTime: '09:15', price: 0, type: 'ECONOMY' },
    { airline: 'GMM Travel', flightNumber: 'GMM-6050', departureTime: '12:00', price: 0, type: 'EXECUTIVE' },
    { airline: 'GMM Travel', flightNumber: 'GMM-410', departureTime: '15:40', price: 0, type: 'EXECUTIVE' },
    { airline: 'GMM Travel', flightNumber: 'GMM-320', departureTime: '18:30', price: 0, type: 'ECONOMY' },
    { airline: 'GMM Travel', flightNumber: 'GMM-550', departureTime: '21:00', price: 0, type: 'ECONOMY' }
  ];

  getTicketPrice(ticketType: string): number {
    const state = this.searchFormService.state();
    const dep = this.getCityName(state.departure).toLowerCase();
    const dest = this.getCityName(state.destination).toLowerCase();

    const executiveTariffs: { [key: string]: { [key: string]: number } } = {
      'kotamobagu': { 'manado': 500000, 'gorontalo': 600000, 'makassar': 1200000, 'kendari': 1350000 },
      'manado': { 'kotamobagu': 500000, 'gorontalo': 750000, 'makassar': 1000000, 'kendari': 1500000 },
      'gorontalo': { 'manado': 750000, 'kotamobagu': 600000, 'makassar': 1100000, 'kendari': 1200000 },
      'makassar': { 'manado': 1000000, 'kotamobagu': 1200000, 'gorontalo': 1100000, 'kendari': 900000 },
      'kendari': { 'manado': 1500000, 'kotamobagu': 1350000, 'gorontalo': 1200000, 'makassar': 900000 }
    };

    const economyTariffs: { [key: string]: { [key: string]: number } } = {
      'kotamobagu': { 'manado': 200000, 'gorontalo': 300000, 'makassar': 900000, 'kendari': 1050000 },
      'manado': { 'kotamobagu': 200000, 'gorontalo': 450000, 'makassar': 700000, 'kendari': 1200000 },
      'gorontalo': { 'manado': 450000, 'kotamobagu': 300000, 'makassar': 800000, 'kendari': 900000 },
      'makassar': { 'manado': 700000, 'kotamobagu': 900000, 'gorontalo': 800000, 'kendari': 600000 },
      'kendari': { 'manado': 1200000, 'kotamobagu': 1050000, 'gorontalo': 900000, 'makassar': 600000 }
    };

    if (ticketType === 'EXECUTIVE') {
      return executiveTariffs[dep]?.[dest] || 500000;
    } else {
      return economyTariffs[dep]?.[dest] || 200000;
    }
  }

  getArrivalTime(departureTime: string): string {
    const durationStr = this.getTravelDuration();
    const match = durationStr.match(/(\d+)\s*jam/i);
    const hoursToAdd = match ? parseInt(match[1], 10) : 3;

    const [depHours, depMins] = departureTime.split(':').map(Number);
    const arrHours = (depHours + hoursToAdd) % 24;
    const arrMins = depMins;

    const pad = (num: number) => num.toString().padStart(2, '0');
    return `${pad(arrHours)}:${pad(arrMins)}`;
  }

  private travelRoutesMap: { [key: string]: { [key: string]: { duration: string; desc: string } } } = {
    'kotamobagu': {
      'manado': { duration: '5 jam', desc: 'Jalur Amurang-Ratahan' },
      'gorontalo': { duration: '7 jam', desc: 'Jalur Utara Boroko' },
      'makassar': { duration: '44 jam', desc: 'Lintas Tengah Sulawesi (2 hari)' },
      'kendari': { duration: '40 jam', desc: 'Lintas Timur via Bungku' }
    },
    'manado': {
      'kotamobagu': { duration: '5 jam', desc: 'Jalur Tomohon-Kawangkoan' },
      'gorontalo': { duration: '10 jam', desc: 'Jalur Lintas Pantai Utara' },
      'makassar': { duration: '48 jam', desc: 'Ujung Utara ke Ujung Selatan' },
      'kendari': { duration: '44 jam', desc: 'Jalur Lintas Morowali' }
    },
    'gorontalo': {
      'manado': { duration: '10 jam', desc: 'Jalur Kwandang-Kwandang' },
      'kotamobagu': { duration: '7 jam', desc: 'Jalur Atinggola' },
      'makassar': { duration: '38 jam', desc: 'Jalur Lintas Poso-Palopo' },
      'kendari': { duration: '34 jam', desc: 'Jalur Luwuk-Morowali' }
    },
    'makassar': {
      'manado': { duration: '48 jam', desc: 'Full Trans Sulawesi darat' },
      'kotamobagu': { duration: '44 jam', desc: 'Lintas Toraja-Poso ke Utara' },
      'gorontalo': { duration: '38 jam', desc: 'Jalur Lintas Sulawesi Barat/Tengah' },
      'kendari': { duration: '25 jam', desc: 'Rute darat memutar via Luwu Timur' }
    },
    'kendari': {
      'manado': { duration: '44 jam', desc: 'Sisi timur ke utara' },
      'kotamobagu': { duration: '40 jam', desc: 'Menembus batas Sultra-Sulteng' },
      'gorontalo': { duration: '34 jam', desc: 'Jalur pesisir Teluk Tomini' },
      'makassar': { duration: '25 jam', desc: 'Jalur darat Lintas Selatan' }
    }
  };

  onBookTicket(ticket: any): void {
    const state = this.searchFormService.state();
    const origin = this.getCityName(state.departure) || 'Manado';
    const destination = this.getCityName(state.destination) || 'Kotamobagu';
    const ticketIndex = this.availableTickets.indexOf(ticket);

    const scheduleId = this.travelService.getScheduleId(origin, destination, ticketIndex)
      ?? ticket.flightNumber;

    const schedule: BookingSchedule = {
      id: scheduleId,
      operator: 'GMM Travel',
      tripCode: ticket.flightNumber,
      class: ticket.type as 'EXECUTIVE' | 'ECONOMY',
      origin,
      destination,
      departureTime: ticket.departureTime,
      arrivalTime: this.getArrivalTime(ticket.departureTime),
      duration: this.getTravelDuration(),
      pricePerPax: this.getTicketPrice(ticket.type),
      tag: ticket.type === 'EXECUTIVE' ? 'Layanan Premium' : 'Harga Terbaik',
    };
    this.bookingService.setSchedule(schedule);
    this.router.navigate(['/booking/seat']);
  }

  onFlightDetails(ticket: any) {
    // Dropdown toggle is handled inside the FlightCardComponent itself
  }

  getTravelDuration(): string {
    const state = this.searchFormService.state();
    const dep = this.getCityName(state.departure).toLowerCase();
    const dest = this.getCityName(state.destination).toLowerCase();

    return this.travelRoutesMap[dep]?.[dest]?.duration || '3 Jam 20 Menit';
  }

  getRouteDescription(): string {
    const state = this.searchFormService.state();
    const dep = this.getCityName(state.departure).toLowerCase();
    const dest = this.getCityName(state.destination).toLowerCase();

    return this.travelRoutesMap[dep]?.[dest]?.desc || 'Jalur darat Trans Sulawesi';
  }

  getCityName(fullString: string): string {
    if (!fullString) return '';
    return fullString.split(',')[0].trim();
  }

  // ── Native scroll reset: restores road state at page top ────
  private nativeScrollHandler = (): void => {
    if (window.scrollY > 0) return;
    if (this.showTicketResults) return;
    if (!this.isFlying && !this.isScrolling && !this.showTicketResults) return;
    this.zone.run(() => {
      this.isFlying   = false;
      this.isScrolling = false;
      this.showTicketResults = false;
      // This is the other way out of the sky page, so it must drop the clouds too —
      // animate() no longer force-hides them.
      this.cloudModels.forEach(cloud => { cloud.visible = false; });
      this.cdr.detectChanges(); // FORCE RE-RENDER IMMEDIATELY
      ScrollTrigger.getAll().forEach(t => t.enable());
      // Restore backdrop directly (GSAP selector strings are unreliable here)
      const jalanEl  = document.querySelector<HTMLElement>('#bg-jalan');
      const langitEl = document.querySelector<HTMLElement>('#bg-langit');
      if (jalanEl)  jalanEl.style.opacity  = '1';
      if (langitEl) langitEl.style.opacity = '0';
      this.carGroup.position.set(0.65, -0.48, -17);
      this.carGroup.rotation.set(0, 0, 0);
      this.setCarOpacity(0);
    });
  };

  constructor(
    private zone: NgZone,
    private cdr: ChangeDetectorRef,
    private router: Router,
    public searchFormService: SearchFormService,
    public bookingService: BookingService,
    public travelService: TravelService,
    public clerk: ClerkService
  ) {
    this.travelService.loadSchedules();
    this.clerk.init().catch(e => console.warn('Clerk init failed:', e));

    // Auto-open login modal if redirected by authGuard
    this.router.events.subscribe((ev: RouterEvent) => {
      if (ev instanceof NavigationEnd && ev.url.includes('requireLogin=1')) {
        this.authMode = 'signin';
        this.router.navigate(['/'], { replaceUrl: true });
      }
    });

    this.router.events.subscribe((event: RouterEvent) => {
      if (event instanceof NavigationStart) {
        this.isNavigating = true;
      } else if (
        event instanceof NavigationEnd ||
        event instanceof NavigationCancel ||
        event instanceof NavigationError
      ) {
        setTimeout(() => { this.isNavigating = false; }, 350);
        if (event instanceof NavigationEnd) {
          this.handleRouteChange(event.urlAfterRedirects);
        }
      }
    });
  }

  private startPlaceholderAnimation(): void {
    const currentWord = this.placeholderKeywords[this.placeholderIndex];
    
    if (this.isDeletingPlaceholder) {
      this.searchPlaceholder = 'Cari ' + currentWord.substring(0, this.placeholderCharIndex);
      this.placeholderCharIndex--;
      
      if (this.placeholderCharIndex < 0) {
        this.isDeletingPlaceholder = false;
        this.placeholderIndex = (this.placeholderIndex + 1) % this.placeholderKeywords.length;
        this.placeholderCharIndex = 0;
        this.placeholderTimeoutId = setTimeout(() => this.startPlaceholderAnimation(), 500);
      } else {
        this.placeholderTimeoutId = setTimeout(() => this.startPlaceholderAnimation(), 40);
      }
    } else {
      this.searchPlaceholder = 'Cari ' + currentWord.substring(0, this.placeholderCharIndex);
      this.placeholderCharIndex++;
      
      if (this.placeholderCharIndex > currentWord.length) {
        this.isDeletingPlaceholder = true;
        this.placeholderTimeoutId = setTimeout(() => this.startPlaceholderAnimation(), 2500);
      } else {
        this.placeholderTimeoutId = setTimeout(() => this.startPlaceholderAnimation(), 80);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  ngAfterViewInit(): void {
    const canvas = this.canvasRef.nativeElement;

    // ── Scene & Camera ───────────────────────────────────────
    this.scene  = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 100);
    this.camera.position.set(0, 1.2, 9);

    // ── Renderer ─────────────────────────────────────────────
    this.renderer = new THREE.WebGLRenderer({ canvas, alpha: true, antialias: true });
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.setClearColor(0x000000, 0);
    this.renderer.toneMapping      = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.4;
    canvas.style.pointerEvents = 'none';

    // ── Lighting ─────────────────────────────────────────────
    this.scene.add(new THREE.AmbientLight(0xffffff, 0.8));

    const mainLight = new THREE.DirectionalLight(0xffffff, 2.0);
    mainLight.position.set(5, 10, 5);
    this.scene.add(mainLight);

    const fillLight = new THREE.DirectionalLight(0x8ec5fc, 0.35);
    fillLight.position.set(-3, -2, 4);
    this.scene.add(fillLight);

    const interiorLight = new THREE.PointLight(0xffffff, 1.5, 10);
    interiorLight.position.set(0, 0.5, 0);
    this.scene.add(interiorLight);

    // ── Car group & fallback box ─────────────────────────────
    this.carGroup = new THREE.Group();
    this.scene.add(this.carGroup);

    const fallbackGeo = new THREE.BoxGeometry(2.2, 1.6, 4.8);
    const fallbackMat = new THREE.MeshStandardMaterial({ color: 0x1E9BF0, roughness: 0.4, metalness: 0.8 });
    this.fallbackMesh = new THREE.Mesh(fallbackGeo, fallbackMat);
    this.fallbackMesh.position.y = 0.9;
    this.carGroup.add(this.fallbackMesh);

    const wheelGeo = new THREE.CylinderGeometry(0.4, 0.4, 0.3, 16);
    wheelGeo.rotateZ(Math.PI / 2);
    const wheelMat = new THREE.MeshStandardMaterial({ color: 0x111111, roughness: 0.9 });
    const fallbackWheels: THREE.Mesh[] = [];
    ([[-1.1, 0.4, 1.6], [1.1, 0.4, 1.6], [-1.1, 0.4, -1.6], [1.1, 0.4, -1.6]] as number[][])
      .forEach(([x, y, z]) => {
        const w = new THREE.Mesh(wheelGeo, wheelMat);
        w.position.set(x, y, z);
        this.carGroup.add(w);
        this.wheels.push(w);
        fallbackWheels.push(w);
      });

    // Initial pose: medium distance on road
    this.carGroup.scale.set(0.012, 0.012, 0.012);
    this.carGroup.position.set(0.65, -0.48, -17);
    this.carGroup.rotation.y = 0;

    // ── Load Toyota HiAce GLTF ───────────────────────────────
    const loader = new GLTFLoader();
    loader.load(
      'assets/toyota_hiace_kombi_hq_interior.glb',
      (gltf) => {
        // Remove fallback geometry once real model arrives
        this.carGroup.remove(this.fallbackMesh);
        fallbackWheels.forEach(w => this.carGroup.remove(w));
        fallbackGeo.dispose(); fallbackMat.dispose();
        wheelGeo.dispose();    wheelMat.dispose();
        this.wheels = [];

        this.hiaceModel = gltf.scene;
        this.hiaceModel.position.set(0, -0.5, 0);

        this.hiaceModel.traverse((child: any) => {
          if (!child.isMesh) return;
          const name: string = child.name.toLowerCase();

          // Collect wheels for rotation
          if (name.includes('wheel') || name.includes('roda')) this.wheels.push(child);

          // TRANSPARENCY FIX: body opaque, glass semi-transparent
          const mats: any[] = Array.isArray(child.material) ? child.material : [child.material];
          mats.forEach((mat: any) => {
            if (!mat) return;
            const combined = name + ' ' + (mat.name?.toLowerCase() ?? '');
            if (combined.includes('glass') || combined.includes('kaca')) {
              mat.transparent = true;
              mat.opacity     = 0.3;
            } else {
              mat.transparent = false;
              mat.opacity     = 1.0;
              mat.depthWrite  = true;
            }
          });
        });

        this.carGroup.add(this.hiaceModel);
      },
      undefined,
      (err) => console.warn('GLB not found — using fallback box.', err)
    );

    // ── Load low-poly cloud & scatter clones down both edges ──
    loader.load(
      'assets/low_poly_cloud.glb',
      (gltf) => {
        // The model's own units are unknown, so measure it once and normalise to a
        // real-world width. CLOUD_WIDTH is the only knob to turn for bigger/smaller.
        const CLOUD_WIDTH = 6.0; // world units across — raise for more majestic clouds
        const size = new THREE.Vector3();
        new THREE.Box3().setFromObject(gltf.scene).getSize(size);
        const norm = size.x > 0 ? CLOUD_WIDTH / size.x : 1;

        for (let i = 0; i < 8; i++) {
          const cloud = gltf.scene.clone(true);

          cloud.userData['onLeft'] = i % 2 === 0;
          // How far out toward the screen edge, as a fraction of the visible
          // half-width at this cloud's own depth. 0.70 clears the card grid
          // (which reaches ~0.45); 0.95 stays just inside the frame.
          cloud.userData['edgeFrac'] = 0.70 + Math.random() * 0.25;

          cloud.position.z = -15 + Math.random() * 5;     // -15 .. -10 (safe depth)
          cloud.position.y = -2.0 + Math.random() * 4.0;  // -2.0 .. 2.0
          this.placeCloudOnEdge(cloud);                   // X derived from the frustum

          // Anchor for the bobbing sine wave in animate()
          cloud.userData['initialY'] = cloud.position.y;

          cloud.scale.setScalar(norm * (0.85 + Math.random() * 0.3));
          cloud.rotation.y = Math.random() * Math.PI * 2;

          // Added once, but only rendered on the ticket page
          cloud.visible = false;
          this.scene.add(cloud);
          this.cloudModels.push(cloud);
        }
      },
      undefined,
      (err) => console.warn('low_poly_cloud.glb not found — sky will have no clouds.', err)
    );

    // ── Init subsystems ──────────────────────────────────────
    this.setupScrollTrigger();
    window.addEventListener('scroll', this.nativeScrollHandler, { passive: true });
    this.clock.start();
    this.animate();
    setTimeout(() => this.startPlaceholderAnimation(), 0);
  }

  // ─────────────────────────────────────────────────────────────
  // SCROLL TRIGGER — smooth pick-up from current idle position
  // ─────────────────────────────────────────────────────────────
  private setupScrollTrigger(): void {
    // ── Step A: backgrounds stay on scrub so they blend with scroll distance ──
    const bgTl = gsap.timeline({
      scrollTrigger: {
        trigger: '#content-layer',   // the .relative.z-20 main wrapper
        start:   'top top',
        end:     '+=80%',
        scrub:   1,
        invalidateOnRefresh: true
      }
    });
    bgTl.to('#bg-jalan',  { opacity: 0, ease: 'none' }, 0)
        .to('#bg-pantai', { opacity: 1, ease: 'none' }, 0);

    // ── Step B: DYNAMIC MOMENTUM DRIVING LOGIC ──
    // The car is deliberately NOT on scrub. Scroll DOWN only *starts* the launch;
    // from then on GSAP owns the velocity, so pausing the wheel can never stall it.
    ScrollTrigger.create({
      trigger: '#content-layer',
      start: 'top top',
      end: '+=100%',
      onUpdate: (self) => {
        // Fire once, on the first downward scroll. `isScrolling` doubles as the
        // "already launched" guard — onLeaveBack resets it.
        if (self.direction === 1 && self.progress > 0.02 && !this.isScrolling) {
          this.isScrolling = true;  // stops the idle road loop in animate()
          this.setCarOpacity(1.0);  // clear any leftover fade from the idle loop

          gsap.killTweensOf(this.carGroup.position);
          gsap.to(this.carGroup.position, {
            x: 0.65,
            y: -0.2,
            // Always the FINAL Z — never a scroll-derived target. This is what
            // guarantees the car keeps driving past the camera (z:9) when the
            // user stops scrolling, instead of freezing at the scroll position.
            z: 24.0,
            duration: 0.9,
            ease: 'power2.in',
            overwrite: 'auto',
            onComplete: () => {
              // Park it below the stage so it can never block the Destinations page
              this.setCarOpacity(0.0);
              this.carGroup.position.set(0, -100, 0);
            }
          });
        }
      },
      onLeaveBack: () => {
        // Kill the launch first: scrolling back up mid-flight would otherwise let
        // its onComplete park the car at Y:-100 *after* this reset runs.
        gsap.killTweensOf(this.carGroup.position);

        this.isScrolling = false;  // idle road loop drives the car again
        this.carGroup.position.set(0.65, -0.48, -17);
        this.carGroup.rotation.set(0, 0, 0);
        this.setCarOpacity(1.0);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // "LIHAT PAKET" → GSAP CLOUD WIPE → TICKET PAGE
  // ─────────────────────────────────────────────────────────────
  onSelectDestination(dest: Destination): void {
    this.travelService.setLastSelectedPackage(dest.name);
    // Wipe the screen with the gradient overlay
    const overlay = this.fadeTransisi.nativeElement;
    gsap.killTweensOf(overlay);
    gsap.set(overlay, { display: 'block', opacity: 0 });
    gsap.to(overlay, { opacity: 1, duration: 0.45, ease: 'power2.inOut' });

    // Navigate to detail while screen is covered
    setTimeout(() => {
      this.hasActiveRoute = true;
      this.router.navigate(['/destination', dest.name]);
      ScrollTrigger.getAll().forEach(t => t.disable());
      this.isScrolling = true;
      this.cloudModels.forEach(c => { c.visible = false; });
      this.carGroup.position.set(0, -100, 0);
      this.setCarOpacity(0.0);
    }, 450);

    // Uncover
    gsap.to(overlay, {
      opacity: 0,
      duration: 0.5,
      delay: 1.0,
      ease: 'power2.out',
      onComplete: () => { overlay.style.display = 'none'; }
    });
  }

  scrollToDestinations(event: Event): void {
    event.preventDefault();
    const el = document.getElementById('destinations-section');
    if (el) {
      el.scrollIntoView({ behavior: 'smooth' });
    }
  }

  onNavSearch(query: string): void {
    // Scroll smoothly to the search widget on the homepage
    const el = document.querySelector('.bg-white.rounded-2xl') as HTMLElement;
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'center' });
      // Focus the first input inside the card after scrolling
      setTimeout(() => {
        const input = el.querySelector('input') as HTMLInputElement;
        if (input) input.focus();
      }, 400);
    }
  }

  onRouteActivate(): void {
    const url = this.router.url.split('?')[0];
    if (!url.includes('/booking/flights')) {
      this.hasActiveRoute = true;
    }
  }

  onRouteDeactivate(): void {
    this.hasActiveRoute = false;
    this.isScrolling = false;

    if (this.travelService.isReturningFromDetail) {
      const jumpToCard = () => {
        const pkgName = this.travelService.lastSelectedPackageName;
        if (pkgName) {
          const card = document.getElementById('pkg-card-' + pkgName) ||
                       document.querySelector(`[data-pkg-name="${CSS.escape(pkgName)}"]`);
          if (card) {
            card.scrollIntoView({ behavior: 'instant' as ScrollBehavior, block: 'center' });
            card.classList.add('highlight-selected-card');
            setTimeout(() => card.classList.remove('highlight-selected-card'), 2000);
          } else {
            const el = document.getElementById('destinations-section');
            if (el) el.scrollIntoView({ behavior: 'instant' as ScrollBehavior, block: 'start' });
          }
        } else {
          const el = document.getElementById('destinations-section');
          if (el) el.scrollIntoView({ behavior: 'instant' as ScrollBehavior, block: 'start' });
        }
      };

      jumpToCard();
      setTimeout(jumpToCard, 0);
      setTimeout(() => {
        jumpToCard();
        this.travelService.isReturningFromDetail = false;
      }, 50);
    } else {
      window.scrollTo(0, 0);
    }

    if (this.carGroup) {
      this.carGroup.position.set(0.65, -0.48, -17);
      this.carGroup.rotation.set(0, 0, 0);
      this.setCarOpacity(0.0);
    }
    ScrollTrigger.getAll().forEach(t => t.enable());
    ScrollTrigger.refresh();
  }

  // ─────────────────────────────────────────────────────────────
  // SEARCH BUTTON → CINEMATIC FLYING TRANSITION
  // ─────────────────────────────────────────────────────────────
  onSearchAnimation(): void {
    // Release coordinate locks immediately on click
    ScrollTrigger.getAll().forEach(trigger => trigger.disable());
    gsap.killTweensOf(this.carGroup.position);
    this.isScrolling = true;
    this.isFlying    = false;

    // STEP 1: Car pitches up and zooms aggressively forward past the camera (0.55s)
    gsap.to(this.carGroup.position, {
      x: 0.65,
      y: 2.5,
      z: 16.0,
      duration: 0.55,
      ease: 'power2.in'
    });

    // STEP 2: THE CRASH-OVERLAY SWAP — fires exactly when the car fills the screen.
    // setTimeout is patched by zone.js (we're in-zone from the template click), so
    // Angular runs change detection automatically → the *ngIf swap is 100% reliable.
    setTimeout(() => {
      this.showTicketResults = true;            // remove hero, render the 6 flight cards
      this.router.navigate(['/booking/flights']); // navigate to route
      this.carGroup.position.set(0, -100, 0);   // throw the car out of view
      this.setCarOpacity(0.0);

      // Clouds appear exactly with the sky — the only place they are switched on
      this.cloudModels.forEach(cloud => { cloud.visible = true; });
    }, 550);

    // STEP 3: Pure GSAP background blend — fires at the 0.55s crash moment.
    // Angular no longer binds these opacities, so nothing snaps them mid-fade.
    gsap.to('#bg-jalan',  { opacity: 0, duration: 0.4, ease: 'power1.out', delay: 0.55 });
    gsap.to('#bg-langit', { opacity: 1, duration: 0.5, ease: 'power1.out', delay: 0.55 });
  }

  private handleRouteChange(url: string) {
    const path = url.split('?')[0];
    this.hideMainNav = path.includes('/booking/package-checkout') || path.includes('/booking/package-payment') || path.includes('/login') || path.includes('/register');
    if (path === '/' || path === '') {
      this.hasActiveRoute = false;
      document.body.classList.remove('route-active');
      if (this.showTicketResults) {
        this.resetToHomeState(!this.isReturning);
      }
    } else if (path.includes('/booking/flights')) {
      document.body.classList.remove('route-active');
      if (!this.showTicketResults) {
        this.zone.run(() => {
          this.showTicketResults = true;
          this.isScrolling = true;
          this.isFlying = false;
          this.cloudModels.forEach(cloud => { cloud.visible = true; });
          if (this.carGroup) {
            this.carGroup.position.set(0, -100, 0);
            this.setCarOpacity(0.0);
          }
          gsap.set('#bg-langit', { opacity: 1 });
          gsap.set('#bg-jalan',  { opacity: 0 });
          this.cdr.detectChanges();
        });
      }
    } else {
      this.hasActiveRoute = true;
      document.body.classList.add('route-active');
    }
  }

  private resetToHomeState(animate: boolean): void {
    this.zone.run(() => {
      this.hasActiveRoute    = false;
      document.body.classList.remove('route-active');
      this.showTicketResults = false;
      this.isScrolling       = false;
      this.isFlying          = false;
      this.isReturning       = false;
      
      this.cloudModels.forEach(cloud => { cloud.visible = false; });

      if (this.carGroup) {
        this.carGroup.position.set(0.65, -0.48, -17);
        this.carGroup.rotation.set(0, 0, 0);
        this.setCarOpacity(0.0);
      }

      const duration = animate ? 0.5 : 0;
      gsap.to('#bg-langit', { opacity: 0, duration, overwrite: 'auto' });
      gsap.to('#bg-jalan',  { opacity: 1, duration, overwrite: 'auto' });
      gsap.set('#content-layer', { y: 0, clearProps: 'transform' });

      window.scrollTo(0, 0);
      ScrollTrigger.getAll().forEach(trigger => trigger.enable());
      ScrollTrigger.refresh();
      this.cdr.detectChanges();
    });
  }

  // ─────────────────────────────────────────────────────────────
  // BACK BUTTON → PAGE DIVES DOWN TO THE ROAD (no car involved)
  // ─────────────────────────────────────────────────────────────
  onBackToHomeAnimation(): void {
    this.isReturning = true;
    this.cloudModels.forEach(cloud => { cloud.visible = false; });
    this.isFlying = false;

    this.carGroup.position.set(0, -100, 0);
    this.setCarOpacity(0.0);
    this.isScrolling = true;

    const tl = gsap.timeline({
      onComplete: () => {
        this.zone.run(() => {
          this.router.navigate(['/']);
        });
      }
    });

    tl.to('#content-layer', {
      y: '100vh',
      duration: 0.6,
      ease: 'power2.inOut'
    })
    .to('#bg-langit', { opacity: 0, duration: 0.5 }, '-=0.5')
    .to('#bg-jalan',  { opacity: 1, duration: 0.5 }, '-=0.5');
  }

  // ─────────────────────────────────────────────────────────────
  // RENDER LOOP
  // ─────────────────────────────────────────────────────────────
  private animate(): void {
    this.animFrameId = requestAnimationFrame(() => this.animate());
    const t = this.clock.getElapsedTime();

    // THE ULTIMATE GUARD: If we are on the ticket page, keep car locked at y: -100 and skip all animation logic
    if (this.showTicketResults) {
      this.carGroup.position.set(0, -100, 0);
      this.setCarOpacity(0.0);

      // Clouds hold their Z — they never drift toward the camera, they just
      // bob and sway in place ("awan nya diem tapi bergerak").
      // Visibility is owned by onSearchAnimation()/onBackToHomeAnimation(), not
      // forced here — that per-frame write is what kept them alive during the
      // slide back home.
      this.cloudModels.forEach((cloud, index) => {
        cloud.position.y = cloud.userData['initialY'] + Math.sin(t * 1.2 + index) * 0.15;
        cloud.rotation.y += 0.002;                       // slow breeze turn
        cloud.rotation.z = Math.sin(t * 0.8 + index) * 0.05; // gentle sway
      });

      this.renderer.render(this.scene, this.camera);
      return; // STOP FURTHER CODE EXECUTION IMMEDIATELY
    }

    // Wheels always spin (road + air)
    this.wheels.forEach(w => { w.rotation.x -= 0.08; });

    if (this.isFlying) {
      // ── Flying / sky mode ───────────────────────────────────
      // Gentle aerial turbulence on Y; X and Z locked in sky centre
      this.carGroup.position.y = Math.sin(t * 2.0) * 0.05;
      this.carGroup.position.x = 0.65;
      this.carGroup.position.z = 0;
      this.carGroup.rotation.x = 0;
      this.carGroup.rotation.y = 0;

      // Keep model/fallback anchored inside the group
      if (this.hiaceModel)       this.hiaceModel.position.y    = -0.5;
      else if (this.fallbackMesh) this.fallbackMesh.position.y  = 0.9;

    } else {
      // ── Road / ground mode ──────────────────────────────────

      // Micro road vibration (only while still near the road, Z ≤ 2)
      const vibY = this.carGroup.position.z <= 2 ? Math.sin(t * 20) * 0.005 : 0;
      if (this.hiaceModel)       this.hiaceModel.position.y    = -0.5 + vibY;
      else if (this.fallbackMesh) this.fallbackMesh.position.y  = 0.9  + vibY;

      // IDLE ROAD LOOPING: only when ScrollTrigger is NOT driving the car
      if (!this.isScrolling && !this.isFlying) {
        this.carGroup.position.z += 0.04; // Drive car forward constant
        this.carGroup.position.y = -0.48; // Lock road height

        const currentZ = this.carGroup.position.z;

        if (currentZ < -12) {
          // 1. FADE IN PHASE: When spawning from -17 to -12, scale opacity smoothly from 0 to 1
          const fadeInProgress = (currentZ - (-17)) / (-12 - (-17)); // values from 0.0 to 1.0
          this.setCarOpacity(Math.max(0, Math.min(1, fadeInProgress)));
        } 
        else if (currentZ > 4) {
          // 2. FADE OUT PHASE: When getting too close from 4 to 7, fade out smoothly to 0
          const fadeOutProgress = (7 - currentZ) / (7 - 4); // values from 1.0 down to 0.0
          this.setCarOpacity(Math.max(0, Math.min(1, fadeOutProgress)));
        } 
        else {
          // 3. SOLID PHASE: When in the middle section, lock car body to 100% solid and opaque
          this.setCarOpacity(1.0);
        }

        // 4. RESET POINT: When car passes the screen completely at Z > 7, reset back to far end
        if (currentZ > 7) {
          this.carGroup.position.z = -17;
          this.setCarOpacity(0.0); // FORCE SPAWN FROM TOTAL TRANSPARENT (0) TO PREVENT GLITCH
        }

        // Reset parameter koordinat dasar agar tidak glitch setelah scroll naik lagi
        this.carGroup.position.x = 0.65;
        this.carGroup.rotation.y = 0;
      }
    }

    this.renderer.render(this.scene, this.camera);
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  /**
   * Set body-mesh opacity; correctly toggles transparent/depthWrite flags.
   * Glass/kaca meshes are excluded (handled in loader).
   */
  private setCarOpacity(opacity: number): void {
    const v = Math.max(0, Math.min(1, opacity));
    this.carGroup.traverse((child: any) => {
      if (!child.isMesh) return;
      const name = child.name.toLowerCase();
      const isGlass = name.includes('glass') || name.includes('kaca');
      const mats: any[] = Array.isArray(child.material) ? child.material : [child.material];
      
      mats.forEach((mat: any) => {
        if (!mat) return;
        
        if (v >= 1.0) {
          // --- 1. FULLY VISIBLE STATE (THE ULTIMATE OPAQUE OVERRIDE) ---
          if (isGlass) {
            mat.transparent = true;
            mat.opacity = 0.3;
            mat.depthWrite = true;
          } else {
            mat.transparent = false; // Turn off transparency
            mat.opacity = 1.0;
            
            // CRUCIAL MULTI-MATERIAL OVERRIDES TO DEFEAT GLTF EMBEDDED BLENDING:
            if (mat.transmission !== undefined) mat.transmission = 0; // Kill glass-like transmission on metal body
            if (mat.thickness !== undefined) mat.thickness = 0;
            mat.blending = THREE.NormalBlending;
            mat.alphaTest = 0;
            mat.depthWrite = true;
            mat.depthTest = true;
          }
        } else {
          // --- 2. FADING STATE (SYNCHRONIZED FADE DOWN TO 0) ---
          mat.transparent = true;
          if (isGlass) {
            mat.opacity = v * 0.3;
          } else {
            mat.opacity = v;
          }
        }
        mat.needsUpdate = true; // Force WebGL cache invalidation and re-compile shader
      });
    });
  }

  /** Visible half-width of the camera frustum at a given world Z. */
  private halfWidthAt(z: number): number {
    const dist  = this.camera.position.z - z;
    const halfH = dist * Math.tan((this.camera.fov * Math.PI / 180) / 2);
    return halfH * this.camera.aspect;
  }

  /**
   * Pins a cloud to the screen edge.
   *
   * A fixed world X cannot do this: how far out a cloud *looks* depends on its
   * depth and on the viewport aspect. At z:-15 on a wide screen, x:-6.5 sits only
   * 37% out from centre — squarely behind the cards — while on a narrow screen the
   * same x is off-frame entirely. Deriving X from the frustum fixes both.
   */
  private placeCloudOnEdge(cloud: THREE.Group): void {
    const onLeft = cloud.userData['onLeft'] as boolean;
    const frac   = cloud.userData['edgeFrac'] as number;
    cloud.position.x = (onLeft ? -1 : 1) * this.halfWidthAt(cloud.position.z) * frac;
  }

  @HostListener('window:resize')
  onResize(): void {
    if (!this.camera || !this.renderer) return;
    this.camera.aspect = window.innerWidth / window.innerHeight;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(window.innerWidth, window.innerHeight);

    // Aspect changed → the frustum edge moved, so re-pin every cloud to it
    this.cloudModels.forEach(cloud => this.placeCloudOnEdge(cloud));
  }

  ngOnDestroy(): void {
    if (this.placeholderTimeoutId) {
      clearTimeout(this.placeholderTimeoutId);
    }
    cancelAnimationFrame(this.animFrameId);
    window.removeEventListener('scroll', this.nativeScrollHandler);
    ScrollTrigger.getAll().forEach(t => t.kill());
    this.renderer?.dispose();
  }
}
