// noinspection JSUnusedGlobalSymbols

import { useUser } from 'src/context/UserContext';

export default function SubscriptionScreen() {
    const { tier, setTier } = useUser();

    return (
        <div style={{ padding: '2rem' }}>
            <h2>🔒 Subscription Settings</h2>
            <p>Current Tier: <strong>{tier.toUpperCase()}</strong></p>

            <h3>Change Tier (Mock)</h3>
            <button onClick={() => setTier('free')}>Free</button>{' '}
            <button onClick={() => setTier('plus')}>Plus</button>{' '}
            <button onClick={() => setTier('pro')}>Pro</button>

            <p style={{ marginTop: '1rem' }}>
                In the full version, this screen will link to Stripe Checkout or your backend billing portal.
            </p>
        </div>
    );
}
