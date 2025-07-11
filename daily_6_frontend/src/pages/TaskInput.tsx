import { useState } from 'react';

interface Task {
    id: number;
    text: string;
    rank: number;
    completed: boolean;
}

export default function TaskInput() {
    const [tasks, setTasks] = useState<Task[]>([]);
    const [text, setText] = useState('');
    const [rank, setRank] = useState(1);

    const handleAddTask = () => {
        if (!text.trim()) return;
        const newTask: Task = {
            id: Date.now(),
            text,
            rank,
            completed: false,
        };
        const updatedTasks = [...tasks, newTask].slice(0, 6);
        setTasks(updatedTasks);
        localStorage.setItem('power6_tasks', JSON.stringify(updatedTasks));
        setText('');
        setRank(1);
    };

    return (
        <div style={{ padding: '2rem' }}>
            <h2>Enter Up to 6 Tasks for Tomorrow</h2>

            <div style={{ marginBottom: '1rem' }}>
                <input
                    type="text"
                    placeholder="Task description"
                    value={text}
                    onChange={(e) => setText(e.target.value)}
                />
                <select value={rank} onChange={(e) => setRank(Number(e.target.value))}>
                    {[1, 2, 3, 4, 5, 6].map((r) => (
                        <option key={r} value={r}>
                            Rank {r}
                        </option>
                    ))}
                </select>
                <button onClick={handleAddTask}>Add Task</button>
            </div>

            <ul>
                {tasks.map((task) => (
                    <li key={task.id}>
                        Rank {task.rank}: {task.text}
                    </li>
                ))}
            </ul>
        </div>
    );
}
