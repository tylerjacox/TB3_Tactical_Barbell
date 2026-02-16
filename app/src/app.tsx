import { useEffect } from 'preact/hooks';
import { appData, isLoading, isFirstLaunch } from './state';
import { route, isTabRoute } from './router';
import { authState } from './services/auth';
import { useAuth } from './hooks/useAuth';
import { useSync } from './hooks/useSync';
import { initSync } from './services/sync';
import { getLocalChanges, applyRemoteChanges, loadAppData } from './services/storage';

// Auth screens
import { Login } from './screens/auth/Login';
import { SignUp } from './screens/auth/SignUp';
import { ForgotPassword } from './screens/auth/ForgotPassword';
import { ConfirmEmail } from './screens/auth/ConfirmEmail';

// Main screens
import { Dashboard } from './screens/Dashboard';
import { Program } from './screens/Program';
import { History } from './screens/History';
import { Profile } from './screens/Profile';
import { Session } from './screens/Session';
import { Onboarding } from './screens/Onboarding';

// Components
import { Layout } from './components/Layout';
import { TabBar } from './components/TabBar';
import { ReturnToWorkout } from './components/ReturnToWorkout';
import { LandscapeOverlay } from './components/LandscapeOverlay';
import { useState } from 'preact/hooks';

export function App() {
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const [authScreen, setAuthScreen] = useState<'login' | 'signup' | 'forgot' | 'confirm'>('login');
  const [confirmEmail, setConfirmEmail] = useState('');

  // Init sync with storage callbacks
  useEffect(() => {
    initSync({
      getLocalChanges,
      applyRemoteChanges: async (pull) => {
        await applyRemoteChanges(pull);
        const fresh = await loadAppData();
        appData.value = fresh;
      },
      isWorkoutActive: () => !!appData.value.activeSession,
    });
  }, []);

  // Start sync when authenticated
  useSync();

  // Loading state
  if (isLoading.value || authLoading) {
    return (
      <div class="loading-screen">
        <h1 class="tb3-brand">TB3</h1>
        <div class="spinner" />
      </div>
    );
  }

  // Auth gate
  if (!isAuthenticated) {
    if (authScreen === 'signup') {
      return (
        <SignUp
          onSignUpSuccess={(email) => {
            setConfirmEmail(email);
            setAuthScreen('confirm');
          }}
          onBackToLogin={() => setAuthScreen('login')}
        />
      );
    }
    if (authScreen === 'forgot') {
      return <ForgotPassword onBack={() => setAuthScreen('login')} />;
    }
    if (authScreen === 'confirm') {
      return (
        <ConfirmEmail
          email={confirmEmail}
          onConfirmed={() => setAuthScreen('login')}
          onBack={() => setAuthScreen('login')}
        />
      );
    }
    return (
      <Login
        onForgotPassword={() => setAuthScreen('forgot')}
        onSignUp={() => setAuthScreen('signup')}
      />
    );
  }

  // First launch -> Onboarding
  if (isFirstLaunch.value) {
    return <Onboarding />;
  }

  // Main app
  const showTabBar = isTabRoute.value && !appData.value.activeSession;
  const currentRoute = route.value;

  return (
    <>
      <ReturnToWorkout />
      <Layout>
        {currentRoute === 'home' && <Dashboard />}
        {currentRoute === 'program' && <Program />}
        {currentRoute === 'history' && <History />}
        {currentRoute === 'profile' && <Profile />}
        {currentRoute === 'session' && <Session />}
        {currentRoute === 'onboarding' && <Onboarding />}
      </Layout>
      <TabBar hidden={!showTabBar} />
      <LandscapeOverlay />
    </>
  );
}
