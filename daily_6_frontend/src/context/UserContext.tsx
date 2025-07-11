import { createContext, useContext, useState, useEffect } from 'react';
import type { ReactNode } from 'react';
import { fetchUserTier } from '../services/api';

type Tier = 'free' | 'plus' | 'pro';

interface UserContextType {
    tier: Tier;
    setTier: (tier: Tier) => void;
}

const UserContext = createContext<UserContextType | undefined>(undefined);

export function UserProvider({ children }: { children: ReactNode }) {
    const stored = (localStorage.getItem('user_tier') as Tier) || 'free';
    const [tier, setTierState] = useState<Tier>(stored);

    useEffect(() => {
        fetchUserTier()
            .then((fetchedTier) => {
                setTierState(fetchedTier);
                localStorage.setItem('user_tier', fetchedTier);
            })
            .catch(() => {
                console.warn('Using local user tier fallback');
            });
    }, []);

    const setTier = (newTier: Tier) => {
        localStorage.setItem('user_tier', newTier);
        setTierState(newTier);
    };

    return (
        <UserContext.Provider value={{ tier, setTier }}>
            {children}
        </UserContext.Provider>
    );
}

export function useUser() {
    const context = useContext(UserContext);
    if (!context) throw new Error('useUser must be used within UserProvider');
    return context;
}
