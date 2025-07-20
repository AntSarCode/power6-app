export {}; // ensures this file is treated as a module

declare global {
  interface Window {
    // Example: add custom props to window
    analytics?: any;
  }

  type User = {
    id: number;
    username: string;
    email: string;
    tier: 'free' | 'premium';
  };

  type Nullable<T> = T | null;
}
