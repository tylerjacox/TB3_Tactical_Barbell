import type { ComponentChildren } from 'preact';

export function Layout({ children }: { children: ComponentChildren }) {
  return (
    <>
      <a href="#main-content" class="skip-nav">Skip to main content</a>
      <main id="main-content" class="main-content">
        {children}
      </main>
    </>
  );
}
