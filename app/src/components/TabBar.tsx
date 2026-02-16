import { route, navigate, type Route } from '../router';
import { IconHome, IconCalendar, IconClock, IconPerson } from './Icons';

const tabs: { route: Route; label: string; Icon: typeof IconHome }[] = [
  { route: 'home', label: 'Home', Icon: IconHome },
  { route: 'program', label: 'Program', Icon: IconCalendar },
  { route: 'history', label: 'History', Icon: IconClock },
  { route: 'profile', label: 'Profile', Icon: IconPerson },
];

export function TabBar({ hidden }: { hidden: boolean }) {
  return (
    <nav class={`tab-bar${hidden ? ' hidden' : ''}`} role="tablist" aria-label="Main navigation">
      {tabs.map((tab) => {
        const isActive = route.value === tab.route;
        return (
          <button
            key={tab.route}
            class={`tab-bar-item${isActive ? ' active' : ''}`}
            role="tab"
            aria-selected={isActive}
            aria-label={tab.label}
            onClick={() => navigate(tab.route)}
          >
            <tab.Icon filled={isActive} />
            <span>{tab.label}</span>
          </button>
        );
      })}
    </nav>
  );
}
