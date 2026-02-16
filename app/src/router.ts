// Hash-based router via Preact Signals (PRD 8)
import { signal, computed } from '@preact/signals';

export type Route =
  | 'home'
  | 'program'
  | 'history'
  | 'profile'
  | 'session'
  | 'onboarding';

const ROUTES: Record<string, Route> = {
  '': 'home',
  home: 'home',
  program: 'program',
  history: 'history',
  profile: 'profile',
  session: 'session',
  onboarding: 'onboarding',
};

export const route = signal<Route>('home');
export const routeParams = signal<Record<string, string>>({});

export const isTabRoute = computed(() => {
  const r = route.value;
  return r === 'home' || r === 'program' || r === 'history' || r === 'profile';
});

function parseHash(): { route: Route; params: Record<string, string> } {
  const hash = window.location.hash.replace('#/', '').replace('#', '');
  const parts = hash.split('/');
  const routeName = parts[0] || 'home';
  const params: Record<string, string> = {};

  // Parse remaining parts as params
  for (let i = 1; i < parts.length; i += 2) {
    if (parts[i] && parts[i + 1]) {
      params[parts[i]] = parts[i + 1];
    }
  }

  // Validate route
  const knownRoute = routeName in ROUTES;
  if (!knownRoute) {
    return { route: 'home', params: {} };
  }

  return { route: ROUTES[routeName], params };
}

function onHashChange() {
  const { route: r, params } = parseHash();
  route.value = r;
  routeParams.value = params;
}

export function navigate(path: Route, params?: Record<string, string>) {
  let hash = `#/${path}`;
  if (params) {
    const paramParts = Object.entries(params).map(([k, v]) => `${k}/${v}`);
    if (paramParts.length) hash += '/' + paramParts.join('/');
  }
  window.location.hash = hash;
}

export function initRouter() {
  window.addEventListener('hashchange', onHashChange);
  onHashChange(); // Read initial hash
}
