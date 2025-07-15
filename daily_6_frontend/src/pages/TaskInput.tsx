import { useState } from 'react';
import Button from '../components/ui/Button';
import Card from '../components/ui/Card';
import Input from '../components/ui/Input';

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
        <div className="space-y-6">
            <h2 className="text-2xl font-bold text-primary">Enter Up to 6 Tasks for Tomorrow</h2>

            <Card>
                <div className="space-y-4">
                    <Input
                        value={text}
                        onChange={(e) => setText(e.target.value)}
                        placeholder="Task description"
                    />
                    <select
                        value={rank}
                        onChange={(e) => setRank(Number(e.target.value))}
                        className="w-full p-3 rounded-xl bg-muted text-primary outline-none"
                    >
                        {[1, 2, 3, 4, 5, 6].map((r) => (
                            <option key={r} value={r}>
                                Rank {r}
                            </option>
                        ))}
                    </select>
                    <Button onClick={handleAddTask}>Add Task</Button>
                </div>
            </Card>

            <ul className="space-y-2">
                {tasks.map((task) => (
                    <Card key={task.id}>
                        <p>
                            <span className="font-semibold">Rank {task.rank}:</span> {task.text}
                        </p>
                    </Card>
                ))}
            </ul>
        </div>
    );
}
