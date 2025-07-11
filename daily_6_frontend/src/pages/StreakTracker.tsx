// noinspection JSUnusedGlobalSymbols

import { useEffect, useState } from 'react';
import { useUser } from '../context/UserContext';

interface Task {
    id: number;
    text: string;
    rank: number;
    completed: boolean;
}

export default function StreakTracker() {
    const [streak, setStreak] = useState(0);
    const [history, setHistory] = useState<Record<string, Task[]>>({});

    useEffect(() => {
        const localStreak = Number(localStorage.getItem('streak') || 0);
        setStreak(localStreak);

        const entries: Record<string, Task[]> = {};
        Object.keys(localStorage).forEach((key) => {
            if (key.startsWith('history_')) {
                const date = key.split('history_')[1];
                const tasks = JSON.parse(localStorage.getItem(key) || '[]');
                entries[date] = tasks;
            }
        });

        const sorted = Object.entries(entries).sort(([a], [b]) =>
            a > b ? -1 : 1
        );
        const sortedObj = Object.fromEntries(sorted);
        setHistory(sortedObj);
    }, []);

    const { tier } = useUser();

    if (tier === 'free') {
        return (
            <div style={{ padding: '2rem' }}>
                <h2>📅 Task History (Premium)</h2>
                <p>This feature is available for <strong>Plus</strong> and <strong>Pro</strong> users only.</p>
                <p>Upgrade in the Subscription tab.</p>
            </div>
        );
    }

    return (
        <div style={{ padding: '2rem' }}>
            <h2>🔥 Current Streak: {streak} day{streak !== 1 ? 's' : ''}</h2>
            <hr />
            <h3>📅 Task History</h3>
            {Object.keys(history).length === 0 ? (
                <p>No history yet.</p>
            ) : (
                Object.entries(history).map(([date, tasks]) => (
                    <div key={date} style={{ marginBottom: '1rem' }}>
                        <strong>{date}</strong>
                        <ul>
                            {tasks.map((t) => (
                                <li key={t.id}>
                                    {t.completed ? '✅' : '❌'} Rank {t.rank}: {t.text}
                                </li>
                            ))}
                        </ul>
                    </div>
                ))
            )}
        </div>
    );
}
