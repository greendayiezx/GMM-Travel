import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { from, switchMap } from 'rxjs';
import { ClerkService } from '../services/clerk.service';

/**
 * clerkAuthInterceptor
 * --------------------
 * Menyisipkan session token Clerk ke header Authorization untuk setiap
 * request ke backend API kita. Backend (VerifyClerkToken) memakainya untuk
 * memverifikasi identitas user secara kriptografis.
 *
 * Hanya request ke API backend yang diberi token — request ke domain lain
 * (mis. Clerk sendiri, CDN) tidak boleh kebocoran token.
 */
const API_HOSTS = ['localhost:8000', '127.0.0.1:8000'];

export const clerkAuthInterceptor: HttpInterceptorFn = (req, next) => {
  const isApiCall = API_HOSTS.some(host => req.url.includes(host)) || req.url.startsWith('/api');

  if (!isApiCall) {
    return next(req);
  }

  const clerk = inject(ClerkService);

  return from(clerk.getToken()).pipe(
    switchMap(token => {
      const authReq = token
        ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
        : req;
      return next(authReq);
    })
  );
};
