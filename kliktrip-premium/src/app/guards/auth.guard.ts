import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { ClerkService } from '../services/clerk.service';

export const authGuard: CanActivateFn = async () => {
  const clerk  = inject(ClerkService);
  const router = inject(Router);
  await clerk.ensureLoaded();
  if (clerk.isSignedIn()) return true;
  // Store intended URL and show sign-in modal via query param
  return router.createUrlTree(['/'], { queryParams: { requireLogin: '1' } });
};
