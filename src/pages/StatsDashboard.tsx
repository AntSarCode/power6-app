// noinspection JSUnusedGlobalSymbols

import { useEffect, useState } from 'react';
import { useUser } from '../context/UserContext';

interface Task {
    id: number;
    text: string;
    rank: number;
    completed: boolean;
}

export default function StatsDashboard() {
    const { tier } = useUser();
    const [history, setHistory] = useState<Record<string, Task[]>>({});

    useEffect(() => {
        const entries: Record<string, Task[]> = {};
        Object.keys(localStorage).forEach((key) => {
            if (key.startsWith('history_')) {
                const date = key.split('history_')[1];
                const tasks = JSON.parse(localStorage.getItem(key) || '[]');
                entries[date] = tasks;
            }
        });

        const sorted = Object.entries(entries).sort(([a], [b]) => (a > b ? -1 : 1));
        setHistory(Object.fromEntries(sorted));
    }, []);

    if (tier !== 'pro') {
        return (
            <div style={{ padding: '2rem' }}>
                <h2>📊 Stats Dashboard (Pro only)</h2>
                <p>This feature is only available to <strong>Pro</strong> users.</p>
                <p>Upgrade in the Subscription tab.</p>
            </div>
        );
    }

    // Summarize history
    const completionData = Object.entries(history).map(([date, tasks]) => ({
        date,
        completed: tasks.filter((t) => t.completed).length,
    }));

    const rankCounts: Record<number, number> = {};
    Object.values(history).forEach((tasks) => {
        tasks.forEach((t) => {
            rankCounts[t.rank] = (rankCounts[t.rank] || 0) + 1;
        });
    });

    return (
        <div style={{ padding: '2rem' }}>
            <h2>📊 Stats Dashboard</h2>

            <h3>✅ Task Completion by Date</h3>
            <ul>
                {completionData.map(({ date, completed }) => (
                    <li key={date}>
                        {date}: {completed}/6 tasks completed
                    </li>
                ))}
            </ul>

            <hr />

            <h3>🏆 Task Rank Frequency</h3>
            <ul>
                {[1, 2, 3, 4, 5, 6].map((rank) => (
                    <li key={rank}>
                        Rank {rank}: {rankCounts[rank] || 0} entries
                    </li>
                ))}
            </ul>
        </div>
    );
}
