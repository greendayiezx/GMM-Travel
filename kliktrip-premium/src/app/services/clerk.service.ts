import { Injectable, NgZone, signal } from '@angular/core';

const PUBLISHABLE_KEY = 'pk_test_ZmlybS1zZWFzbmFpbC03Ny5jbGVyay5hY2NvdW50cy5kZXYk';
const CLERK_CDN = `https://unpkg.com/@clerk/clerk-js@5/dist/clerk.browser.js`;

export interface ClerkUser {
  id: string;
  firstName: string | null;
  lastName: string | null;
  fullName: string | null;
  emailAddress: string | null;
  imageUrl: string;
  initials: string;
}

@Injectable({ providedIn: 'root' })
export class ClerkService {
  private _clerk: any = null;
  private _initPromise: Promise<void> | null = null;

  readonly isLoaded   = signal(false);
  readonly isSignedIn = signal(false);
  readonly user       = signal<ClerkUser | null>(null);

  constructor(private zone: NgZone) {}

  async init(): Promise<void> {
    if (this._initPromise) return this._initPromise;
    this._initPromise = this._doInit();
    return this._initPromise;
  }

  async ensureLoaded(): Promise<void> {
    return this.init();
  }

  private async _doInit(): Promise<void> {
    await this._loadScript(CLERK_CDN, PUBLISHABLE_KEY);

    this._clerk = (window as any).Clerk;
    if (!this._clerk) throw new Error('Clerk script did not set window.Clerk');

    if (typeof this._clerk === 'function') {
      this._clerk = new this._clerk(PUBLISHABLE_KEY);
    }

    await this._clerk.load({
      // API baru Clerk (menggantikan afterSignInUrl/afterSignUpUrl yang deprecated).
      signInFallbackRedirectUrl: '/',
      signUpFallbackRedirectUrl: '/',
    });

    this.zone.run(() => {
      this.isLoaded.set(true);
      this.syncState();
    });

    // Run listener inside Angular zone so signals trigger change detection
    this._clerk.addListener(() => {
      this.zone.run(() => this.syncState());
    });
  }

  private syncState(): void {
    const session = this._clerk?.session;
    this.isSignedIn.set(!!session);
    const u = session?.user;
    if (u) {
      const first = u.firstName ?? '';
      const last  = u.lastName  ?? '';
      const initials = ((first[0] ?? '') + (last[0] ?? '')).toUpperCase() || u.fullName?.[0]?.toUpperCase() || '?';
      this.user.set({
        id: u.id,
        firstName: first || null,
        lastName:  last  || null,
        fullName:  u.fullName  ?? null,
        emailAddress: u.primaryEmailAddress?.emailAddress ?? null,
        imageUrl: u.imageUrl ?? '',
        initials,
      });
    } else {
      this.user.set(null);
    }
  }

  /**
   * Ambil session token Clerk (JWT) untuk dikirim ke backend sebagai
   * Authorization: Bearer <token>. Backend memverifikasi signature-nya
   * (VerifyClerkToken) agar identitas user tidak bisa dipalsukan frontend.
   */
  async getToken(): Promise<string | null> {
    try {
      const session = this._clerk?.session;
      if (!session) return null;
      return await session.getToken();
    } catch {
      return null;
    }
  }

  async signInWithEmailPassword(identifier: string, password: string): Promise<void> {
    const signIn = this._clerk?.client?.signIn;
    if (!signIn) throw new Error('Clerk not ready');
    const result = await signIn.create({ identifier, password });
    if (result.status === 'complete') {
      await this._clerk.setActive({ session: result.createdSessionId });
      this.zone.run(() => this.syncState());
    } else {
      throw new Error('Login tidak lengkap, cek verifikasi email');
    }
  }

  async signInWithGoogle(): Promise<void> {
    await this._oauthRedirect('oauth_google');
  }

  async signInWithOAuth(strategy: string): Promise<void> {
    await this._oauthRedirect(strategy);
  }

  private async _oauthRedirect(strategy: string): Promise<void> {
    const redirectUrl         = window.location.origin + '/sso-callback';
    const redirectUrlComplete = window.location.origin + '/';

    // Clerk v5: via client.signIn
    if (this._clerk?.client?.signIn?.authenticateWithRedirect) {
      await this._clerk.client.signIn.authenticateWithRedirect({ strategy, redirectUrl, redirectUrlComplete });
      return;
    }
    // Clerk v4 fallback
    if (this._clerk?.authenticateWithRedirect) {
      await this._clerk.authenticateWithRedirect({ strategy, redirectUrl, redirectUrlComplete });
      return;
    }
    // Fallback: popup
    this._clerk?.openSignIn();
  }

  /** Handle OAuth redirect callback (call from /sso-callback route) */
  async handleRedirectCallback(): Promise<void> {
    await this._clerk?.handleRedirectCallback();
  }

  /** Create a new sign-up (email/password flow) */
  async createSignUp(params: {
    firstName?: string;
    lastName?: string;
    emailAddress: string;
    password: string;
    phoneNumber?: string;
  }): Promise<any> {
    const signUp = this._clerk?.client?.signUp;
    if (!signUp) throw new Error('Clerk not ready');
    const result = await signUp.create({
      firstName:    params.firstName,
      lastName:     params.lastName,
      emailAddress: params.emailAddress,
      password:     params.password,
    });
    if (result.status === 'complete') {
      await this._clerk.setActive({ session: result.createdSessionId });
      this.zone.run(() => this.syncState());
    }
    return result;
  }

  /** Update a pending sign-up (e.g. after Google OAuth needs extra fields) */
  async updateSignUp(params: {
    firstName?: string;
    lastName?: string;
    phoneNumber?: string;
  }): Promise<any> {
    const signUp = this._clerk?.client?.signUp;
    if (!signUp) throw new Error('Clerk not ready');
    const { phoneNumber, ...updateFields } = params;
    const result = await signUp.update(updateFields);
    if (result.status === 'complete') {
      await this._clerk.setActive({ session: result.createdSessionId });
      this.zone.run(() => this.syncState());
    }
    return result;
  }

  mountSignIn(el: HTMLElement): void  { this._clerk?.mountSignIn(el); }
  mountSignUp(el: HTMLElement): void  { this._clerk?.mountSignUp(el); }

  unmount(el: HTMLElement): void {
    try { this._clerk?.unmountSignIn(el); } catch {}
    try { this._clerk?.unmountSignUp(el); } catch {}
  }

  openSignIn(): void {
    this._clerk?.openSignIn({ appearance: { variables: { colorPrimary: '#2E7DFF', borderRadius: '10px' } } });
  }

  openSignUp(): void {
    this._clerk?.openSignUp({ appearance: { variables: { colorPrimary: '#2E7DFF', borderRadius: '10px' } } });
  }

  openUserProfile(): void { this._clerk?.openUserProfile(); }

  async signOut(): Promise<void> {
    await this._clerk?.signOut();
    this.zone.run(() => this.syncState());
  }

  private _loadScript(src: string, publishableKey?: string): Promise<void> {
    return new Promise((resolve, reject) => {
      if (document.querySelector(`script[src="${src}"]`)) { resolve(); return; }
      const s = document.createElement('script');
      s.src = src;
      s.async = true;
      if (publishableKey) s.setAttribute('data-clerk-publishable-key', publishableKey);
      s.onload  = () => resolve();
      s.onerror = () => reject(new Error(`Failed to load: ${src}`));
      document.head.appendChild(s);
    });
  }
}
