import { useEffect, useState } from 'react';
import { uploadTasks } from '../services/api';

interface Task {
    id: number;
    text: string;
    rank: number;
    completed: boolean;
}

export default function TaskReview() {
    const [tasks, setTasks] = useState<Task[]>([]);

    useEffect(() => {
        const stored = localStorage.getItem('power6_tasks');
        if (stored) {
            setTasks(JSON.parse(stored));
        } else {
            // Optional: Load tasks from backend if no local cache
            fetch(`${import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000'}/tasks/today`)
                .then(res => res.ok ? res.json() : [])
                .then(data => {
                    if (Array.isArray(data) && data.length > 0) {
                        setTasks(data);
                        localStorage.setItem('power6_tasks', JSON.stringify(data));
                    }
                })
                .catch(err => console.error('Failed to fetch tasks from backend:', err));
        }
    }, []);

    const toggleComplete = (id: number) => {
        const updated = tasks.map((task) =>
            task.id === id ? { ...task, completed: !task.completed } : task
        );
        setTasks(updated);
        localStorage.setItem('power6_tasks', JSON.stringify(updated));
    };

    const handleFinalize = async () => {
        const today = new Date().toISOString().split('T')[0];
        localStorage.setItem(`history_${today}`, JSON.stringify(tasks));

        const allCompleted = tasks.length === 6 && tasks.every((t) => t.completed);
        const currentStreak = Number(localStorage.getItem('streak') || 0);
        const lastCompleted = localStorage.getItem('last_completed_day');

        if (allCompleted) {
            const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
            if (lastCompleted === yesterday) {
                localStorage.setItem('streak', String(currentStreak + 1));
            } else {
                localStorage.setItem('streak', '1');
            }
            localStorage.setItem('last_completed_day', today);
        } else {
            localStorage.setItem('streak', '0');
        }

        try {
            await uploadTasks(tasks);
        } catch (err) {
            console.error('Upload failed:', err);
        }

        localStorage.removeItem('power6_tasks');
        setTasks([]);
        alert(allCompleted ? 'Perfect day! Streak updated.' : 'Tasks stored. Incomplete day.');
    };

    return (
        <div style={{ padding: '2rem' }}>
            <h2>Review & Complete Tasks</h2>
            {tasks.length === 0 ? (
                <p>No tasks available. Add tasks on the Task Input screen first.</p>
            ) : (
                <ul>
                    {tasks.map((task) => (
                        <li key={task.id}>
                            <label>
                                <input
                                    type="checkbox"
                                    checked={task.completed}
                                    onChange={() => toggleComplete(task.id)}
                                />
                                Rank {task.rank}: {task.text}
                            </label>
                        </li>
                    ))}
                </ul>
            )}
            {tasks.length > 0 && <button onClick={handleFinalize}>Finalize Review</button>}
        </div>
    );
}
