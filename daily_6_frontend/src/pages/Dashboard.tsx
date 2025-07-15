import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import { useEffect, useState } from 'react';

export default function Dashboard() {
    const [taskComplete, setTaskComplete] = useState(false);

    useEffect(() => {
        const timeout = setTimeout(() => setTaskComplete(true), 500);
        return () => clearTimeout(timeout);
    }, []);

    return (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {/* Overview Panel */}
            <Card className="col-span-1 md:col-span-2 lg:col-span-1 transition-all duration-500 hover:scale-[1.01] hover:shadow-lg">
                <h2 className="text-xl font-bold mb-2">Streak Progress</h2>
                <p className="text-muted">You're on a 5-day streak! Keep it going!</p>
            </Card>

            {/* Task Summary */}
            <Card
                className={`col-span-1 transition-all duration-700 ${
                    taskComplete ? 'bg-success/20 animate-pulse' : ''
                }`}
            >
                <h2 className="text-xl font-bold mb-2">Task Completion</h2>
                <p className="text-muted">4 of 6 tasks completed today.</p>
            </Card>

            {/* Call to Action */}
            <Card className="col-span-1 md:col-span-2 lg:col-span-1 flex flex-col justify-between transition-all duration-500 hover:scale-[1.01] hover:shadow-lg">
                <div>
                    <h2 className="text-xl font-bold mb-2">Upgrade for Stats</h2>
                    <p className="text-muted mb-4">Unlock full analytics and trends over time.</p>
                </div>
                <Button variant="accent">Go Premium</Button>
            </Card>
        </div>
    );
}
