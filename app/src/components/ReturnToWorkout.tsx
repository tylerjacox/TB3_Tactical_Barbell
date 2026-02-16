import { appData } from '../state';
import { navigate, route } from '../router';
import { IconChevronRight } from './Icons';

export function ReturnToWorkout() {
  const session = appData.value.activeSession;
  if (!session || route.value === 'session') return null;

  return (
    <button
      class="return-banner"
      role="alert"
      onClick={() => navigate('session')}
      aria-label={`Workout in progress. Return to workout.`}
    >
      <span>Workout in progress</span>
      <IconChevronRight />
    </button>
  );
}
